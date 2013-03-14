local function melee_damage(player_state, skill, monster_stats)
	if skill["type"] ~= "melee" then
		error("Not a valid melee damage skill: " .. skill["name"])
	end

	local s_m_b = nil -- s_m_b = skill_muscle_bonus
	if player_state["class"] == skill["class"] and skill["skill_muscle_bonus"][2] then
		s_m_b = skill["skill_muscle_bonus"][2]
	else
		s_m_b = skill["skill_muscle_bonus"][1]
	end

	local integer_bonus_damage = player_state["int_weapon_damage"]

	local w_t_f = nil -- w_t_f = weapon_type_factor
	if player_state["mainhand_type"] == "unarmed" then
		w_t_f = 0.25
	elseif player_state["mainhand_type"] == "melee" then
		w_t_f = 1
	elseif player_state["mainhand_type"] == "ranged" then
		w_t_f = 0.75
		integer_bonus_damage = integer_bonus_damage + player_state["int_ranged_damage"]
	end

	-- eff_mus = effective muscle
	local eff_mus = math.floor(player_state["buffed_muscle"] * s_m_b * w_t_f)

	-- FIXME if off_diff < 0 and not skill["auto_hit"] then ???
	-- off_diff = offensive difference
	local off_diff = math.max(0, eff_mus - monster_stats["defense"])

	local additional_dmg_tables = {}

	local elementable = {
		cold = player_state["cold_weapon_damage"],
		hot = player_state["hot_weapon_damage"],
		sleaze = player_state["sleaze_weapon_damage"],
		spooky = player_state["spooky_weapon_damage"],
		stench = player_state["stench_weapon_damage"]
	}
	local elemental_dmg = 0
	for element, value in pairs(elementable) do
		elemental_dmg = elemental_dmg + apply_resistance(value, element, monster_stats["element"], 0)
	end
	table.insert(additional_dmg_tables, {elemental_dmg})

	local oh_type = player_state["offhand_type"]
	local oh_pwr = player_state["offhand_power"]
	local dw_dmg = {}
	if oh_type == "melee" or oh_type == "ranged" then
		for dmg = math.ceil(oh_pwr / 10), math.ceil(oh_pwr / 5) do
			table.insert(dw_dmg, apply_resistance(dmg, player_state["phial_form"], monster_stats["element"], monster_stats["physical_resistance"]))
		end
		table.insert(additional_dmg_tables, dw_dmg)
	end

	local hb_dmg = {}
	if skill["name"] == "Headbutt" or (skill["name"]:match("Combo$") and skill["name"]:match("Head")) then
		hb_dmg = headbutt_dmg("current")
		if player_state["phial_form"] ~= "no_element" or monster_stats["physical_resistance"] > 0 then
			for i = 1, #hb_dmg do
				hb_dmg[i] = apply_resistance(hb_dmg[i], player_state["phial_form"], monster_stats["element"], monster_stats["physical_resistance"])
			end
		end
		table.insert(additional_dmg_tables, hb_dmg)
	end

	local kb_dmg = {}
	if skill["name"] == "Kneebutt" or (skill["name"]:match("Combo$") and skill["name"]:match("Knee")) then
		kb_dmg = kneebutt_dmg("current")
		if player_state["phial_form"] ~= "no_element" or monster_stats["physical_resistance"] > 0 then
			for i = 1, #kb_dmg do
				kb_dmg[i] = apply_resistance(kb_dmg[i], player_state["phial_form"], monster_stats["element"], monster_stats["physical_resistance"])
			end
		end
		table.insert(additional_dmg_tables, kb_dmg)
	end

	local sb_dmg = {}
	if skill["name"] == "Shieldbutt" or (skill["name"]:match("Combo$") and skill["name"]:match("Shield")) then
		sb_dmg = shieldbutt_dmg("current")
		if player_state["phial_form"] ~= "no_element" or monster_stats["physical_resistance"] > 0 then
			for i = 1, #sb_dmg do
				sb_dmg[i] = apply_resistance(sb_dmg[i], player_state["phial_form"], monster_stats["element"], monster_stats["physical_resistance"])
			end
		end
		table.insert(additional_dmg_tables, sb_dmg)
	end

	-- TODO local other_dmg = {}
	-- TODO if skill["name"] == "Ravenous Pounce" then
	-- TODO if skill["name"] == "???" then

	local function a_melee_dmg_quantum(x, crit)
		local crit_mult = 1
		if crit then
			crit_mult = player_state["crit_multiplier"]
		end
		local dmg = math.floor(math.max(1, off_diff + integer_bonus_damage
				+ (crit_mult * skill["weapon_dmg_multiplier"] * x))
				* (1 + player_state["percent_weapon_damage"]))
		dmg = apply_resistance(dmg, player_state["phial_form"], monster_stats["element"], monster_stats["physical_resistance"])
		return dmg
	end

	local normal_damages = {}
	local crit_damages = {}
	local mh_pwr = player_state["mainhand_power"]
	for dmg = math.ceil(mh_pwr / 10), math.ceil(mh_pwr / 5) do
		table.insert(normal_damages, a_melee_dmg_quantum(dmg, false))
		table.insert(crit_damages, a_melee_dmg_quantum(dmg, true))
	end

	for i = 1, #additional_dmg_tables do
		--print(skill["name"] .. " propagation " .. i .. " " .. table.concat(additional_dmg_tables[i], ", "))
		normal_damages = propagate(normal_damages, additional_dmg_tables[i])
		crit_damages = propagate(crit_damages, additional_dmg_tables[i])
	end

	-- all_damages doesn't seem very useful right now
	-- TODO replace (or augment?) it with glance_dmg and fumble_dmg
	local all_damages = {}
	for i = 1, #normal_damages do
		table.insert(all_damages, normal_damages[i])
	end
	for i = 1, #crit_damages do
		table.insert(all_damages, crit_damages[i])
	end

	local dmg_odds = wato(normal_damages, crit_damages, player_state["crit_melee_chance"])

	local mean_dmg = avg(dmg_odds)

	local output = {name = skill["name"]}
	output["all_dmg"] = all_damages
	output["normal_dmg"] = normal_damages
	output["crit_dmg"] = crit_damages
	output["dmg_odds"] = dmg_odds
	output["mean_dmg"] = mean_dmg

	return output
end

local function a_spell_dmg_quantum(player_state, skill, monster_stats, x, tuned_element, crit)
	local crit_mult = 1
	if crit then
		crit_mult = 2
	end

	local single_element_damage = {
		cold = player_state["cold_spell_damage"],
		hot = player_state["hot_spell_damage"],
		sleaze = player_state["sleaze_spell_damage"],
		spooky = player_state["spooky_spell_damage"],
		stench = player_state["stench_spell_damage"],
		no_element = 0
	}

	local integer_spell_damage = 0
	if skill["cap_type"] == "Pasta" then
		local which_cap = 1
		if skill["class"] == player_state["class"] then
			which_cap = 2
		end
		integer_spell_damage = single_element_damage[tuned_element] + math.min(player_state["int_spell_damage"], skill["integer_bonus_dmg_cap"][which_cap])
	elseif skill["cap_type"] == "Sauce" then
		local is = 0
		if player_state["intrinsically_spicy"] then
			is = math.min(10, level())
		end
		integer_spell_damage = math.min(skill["integer_bonus_dmg_cap"][1], player_state["int_spell_damage"] + single_element_damage[tuned_element] + is)
	elseif skill["cap_type"] == "NoCap" then
		integer_spell_damage = player_state["int_spell_damage"] + single_element_damage[tuned_element]
		if skill["class"] == 3 and player_state["intrinsically_spicy"] then
			integer_spell_damage = integer_spell_damage + math.min(10, level())
		end
	end

	local myst_dmg = 0
	if skill["myst_boost_cap"] then
		myst_dmg = math.min(skill["myst_boost_cap"], player_state["buffed_myst"] * skill["myst_boost"])
	else
		myst_dmg = math.floor(player_state["buffed_myst"] * skill["myst_boost"])
	end

	local group_multiplier = math.min(skill["max_group_size"], monster_stats["group_size"])

	-- TODO weapon of the pastalord half-tuned/half-physical
	-- TODO test whether the element or group multiplier happens first
	local dmg = apply_resistance(group_multiplier * math.ceil((1 + player_state["percent_spell_damage"]) * ((x + myst_dmg) * crit_mult + integer_spell_damage)), tuned_element, monster_stats["element"], monster_stats["physical_resistance"])
	return dmg
end

local function spell_damage(player_state, skill, monster_stats)
	if skill["type"] ~= "spell" then
		error("Not a valid spell damage skill: " .. skill["name"])
	end

	-- TODO this algorithm really really needs more testing to see if a high dice roll for base_dmg (or a crit) overpowers a small single elemental damage bonus
	local function sauce_tuned_to()
		local avg_base_dmg = math.ceil((skill["base_dmg_min"] + skill["base_dmg_max"]) / 2)
		local hypothetical_cold = a_spell_dmg_quantum(player_state, skill, monster_stats, avg_base_dmg, "cold", false)
		local hypothetical_hot = a_spell_dmg_quantum(player_state, skill, monster_stats, avg_base_dmg, "hot", false)
		local tuned = "cold" -- HACK "cold comes before hot alphabetically" is the only reason
		if player_state["immaculately_seasoned"] then
			if hypothetical_cold > hypothetical_hot then
				tuned = "cold"
			elseif hypothetical_cold < hypothetical_hot then
				tuned = "hot"
			end
		end
		return tuned
	end

	local tuning = {
		cold_tuned = "cold",
		hot_tuned = "hot",
		immaculate = sauce_tuned_to(),
		physical_tuned = "no_element",
		poison_tuned = "no_element",
		spirit_of_something = player_state["spirit_of_what"],
		sleaze_tuned = "sleaze",
		spooky_tuned = "spooky",
		stench_tuned = "stench"
	}

	local spell_tuned_to = tuning[skill["tunable_type"]]

	local normal_damages = {}
	local crit_damages = {}
	for dmg = skill["base_dmg_min"], skill["base_dmg_max"], 1 do
		table.insert(normal_damages, a_spell_dmg_quantum(player_state, skill, monster_stats, dmg, spell_tuned_to, false))
		table.insert(crit_damages, a_spell_dmg_quantum(player_state, skill, monster_stats, dmg, spell_tuned_to, true))
	end

	local all_damages = {}
	for i = 1, #normal_damages do
		table.insert(all_damages, normal_damages[i])
	end
	for i = 1, #crit_damages do
		table.insert(all_damages, crit_damages[i])
	end

	local dmg_odds = wato(normal_damages, crit_damages, player_state["crit_spell_chance"])

	local mean_dmg = avg(dmg_odds)

	local output = {name = skill["name"]}
	output["all_dmg"] = all_damages
	output["normal_dmg"] = normal_damages
	output["crit_dmg"] = crit_damages
	output["dmg_odds"] = dmg_odds
	output["mean_dmg"] = mean_dmg

	return output
end

function jarlsberg_damage(player_state, skill, monster_stats)
	if skill["type"] ~= "jarlsberg" then
		error("Not a valid Jarlsberg skill: " .. skill["name"])
	end

	-- TODO is mp_cost_cap_multiplier ever ~= 10?
	local dmg_cap = skill["mp_cost_cap_multiplier"] * (skill["mp_cost"] + player_state["mp_cost_modifier"])

	local myst_dmg = math.floor(skill["myst_boost"] * player_state["buffed_myst"])

	local skill_element = skill["element"]
	if player_state["phial_form"] ~= "no_element" then
		skill_element = player_state["phial_form"]
	end

	local function a_jarlsberg_dmg_quantum(x, crit)
		local crit_mult = 1
		if crit then
			crit_mult = 2
		end
		local dmg = apply_resistance(crit * math.min(dmg_cap, (1 + player_state["percent_spell_damage"]) * (x + myst_dmg + player_state["int_spell_damage"])), skill_element, monster_stats["element"], monster_stats["physical_resistance"])
		return dmg
	end

	local normal_damages = {}
	local crit_damages = {}
	for dmg = skill["base_dmg_min"], skill["base_dmg_max"], 1 do
		table.insert(normal_damages, a_jarlsberg_dmg_quantum(dmg, false))
		table.insert(crit_damages, a_jarlsberg_dmg_quantum(dmg, true))
	end

	local all_damages = {}
	for i = 1, #normal_damages do
		table.insert(all_damages, normal_damages[i])
	end
	for i = 1, #crit_damages do
		table.insert(all_damages, crit_damages[i])
	end

	local dmg_odds = wato(normal_damages, crit_damages, player_state["crit_spell_chance"])

	local mean_dmg = avg(dmg_odds)

	local output = {name = skill["name"]}
	output["all_dmg"] = all_damages
	output["normal_dmg"] = normal_damages
	output["crit_dmg"] = crit_damages
	output["dmg_odds"] = dmg_odds
	output["mean_dmg"] = mean_dmg

	return output
end

-- TODO how to distinguish monsters that partially resist all spell damage?
-- TODO do any monsters exist that partially resist specific elements?
function apply_resistance(dmg, dmg_element, target_element, target_phys_resist)
	if dmg == 0 then
		return dmg
	elseif dmg_element == "no_element" then
		if target_phys_resist == 100 then
			return math.min(1, dmg)
		elseif target_phys_resist > 0 then
			-- TODO test this for accuracy
			return math.floor(dmg * (100 - target_phys_resist) / 100)
		end
		return dmg
	elseif target_element == "no_element" then
		return dmg
	elseif dmg_element == target_element then
		return 1
	elseif is_strong_against(dmg_element, target_element) then
		return dmg * 2
	else
		return dmg
	end
end

function curdle_damage(player_state, monster_stats)
	local dmg = apply_resistance(15, "stench", monster_stats["element"], 0)

	local output = {name = "Curdle"}
	output["all_dmg"] = {dmg}
	output["normal_dmg"] = {dmg}
	output["crit_dmg"] = {dmg}
	output["dmg_odds"] = {dmg = 1}
	output["mean_dmg"] = dmg

	return output
end

function predict_damage(player_state, skill, monster_stats)
	skill_data = get_skill_data(skill)
	if skill_data["type"] == "spell" then
		return spell_damage(player_state, skill_data, monster_stats)
	elseif skill_data["type"] == "melee" then
		return melee_damage(player_state, skill_data, monster_stats)
	elseif skill_data["type"] == "jarlsberg" then
		return jarlsberg_damage(player_state, skill_data, monster_stats)
	elseif skill_data["type"] == "other" then
		if skill_data["name"] == "Curdle" then
			return curdle_damage(player_state, monster_stats)
		end
	end
end
