function melee_damage(player_state, skill, monster_stats)
	if skill["type"] ~= "melee" then
		error("Not a valid melee damage skill: " .. skill["name"])
	end

	local mh_pwr = player_state["mainhand_power"]

	local s_m_b = nil -- s_m_b = skill_muscle_bonus
	if player_state["class"] == skill["class"] then
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

	local elementable = {
		cold = player_state["cold_weapon_damage"],
		hot = player_state["hot_weapon_damage"],
		sleaze = player_state["sleaze_weapon_damage"],
		spooky = player_state["spooky_weapon_damage"],
		stench = player_state["stench_weapon_damage"]
	}
	local elemental_dmg = 0
	for e, v in pairs(elementable) do
		if v then
			elemental_dmg = elemental_dmg + element_factor(v, e, monster_stats["element"])
		end
	end

	-- TODO dual wielding, xxx_butt, ravenous pounce, etc
	local additional_dmg = 0

	local function a_melee_dmg_quantum(x, crit)
		local crit_mult = 1
		if crit then
			crit_mult = player_state["crit_multiplier"]
		end
		local dmg = math.floor(math.max(1, off_diff + integer_bonus_damage
				+ (crit_mult * skill["weapon_dmg_multiplier"] * x))
				* (1 + player_state["percent_weapon_damage"]))
				+ elemental_dmg
				+ additional_dmg
		return dmg
	end

	local normal_damages = {skill["name"] .. " damages:"}
	local crit_damages = {skill["name"] .. " crit damages:"}
	for dmg = math.ceil(mh_pwr / 10), math.ceil(mh_pwr / 5), 1 do
		table.insert(normal_damages, a_melee_dmg_quantum(dmg, false))
		table.insert(crit_damages, a_melee_dmg_quantum(dmg, true))
	end
	local damages = {["normal"] = normal_damages, ["crit"] = crit_damages}
	return damages
end

local function a_spell_dmg_quantum(player_state, skill, monster_stats, x, tuned_element, crit)
	local crit_mult = 1
	if crit then
		crit_mult = 2
	end

	local single_element_damage = {
		cold = (player_state["cold_spell_damage"] or 0),
		hot = (player_state["hot_spell_damage"] or 0),
		sleaze = (player_state["sleaze_spell_damage"] or 0),
		spooky = (player_state["spooky_spell_damage"] or 0),
		stench = (player_state["stench_spell_damage"] or 0)
	}

	local integer_spell_damage = 0
	if skill["cap_type"] == "Pasta" then
		local which_cap = 1
		if skill["class"] == player_state["class"] then
			which_cap = 2
		end
		integer_spell_damage = single_element_damage[tuned_element] + math.min(player_state["int_spell_damage"], skill["integer_bonus_dmg_cap"][which_cap])
	elseif skill["cap_type"] == "Sauce" then
		integer_spell_damage = math.min(skill["integer_bonus_dmg_cap"][1], player_state["int_spell_damage"] + single_element_damage[tuned_element])
	elseif skill["cap_type"] == "NoCap" then
		integer_spell_damage = player_state["int_spell_damage"] + single_element_damage[tuned_element]
	end

	local myst_dmg = 0
	if skill["myst_boost_cap"] then
		myst_dmg = math.min(skill["myst_boost_cap"], player_state["buffed_myst"] * skill["myst_boost"])
	else
		myst_dmg = player_state["buffed_myst"] * skill["myst_boost"]
	end

	local group_multiplier = math.min(skill["max_group_size"], monster_stats["group_size"])

	local dmg = group_multiplier * element_factor(math.ceil((1 + player_state["percent_spell_damage"]) * ((x + myst_dmg) * crit_mult + integer_spell_damage)), tuned_element, monster_stats["element"])
	return dmg
end

function spell_damage(player_state, skill, monster_stats)
	if skill["type"] ~= "spell" then
		error("Not a valid spell damage skill: " .. skill["name"])
	end

	-- TODO this algorithm really really needs skill["name"] .. " damages: "d testing to see if a low dice roll for base_dmg overpowers a large single elemental damage bonus
	local function sauce_tuned_to()
		local avg_base_dmg = math.ceil((skill["base_dmg_min"] + skill["base_dmg_max"]) / 2)
		local hypothetical_cold = a_spell_dmg_quantum(player_state, skill, monster_stats, avg_base_dmg, "cold", false)
		local hypothetical_hot = a_spell_dmg_quantum(player_state, skill, monster_stats, avg_base_dmg, "hot", false)
		local tuned = "no_element"
		if have_skill("Immaculate Seasoning") then
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
		spooky_tune = "spooky",
		stench_tuned = "stench"
	}

	local spell_tuned_to = tuning[skill["tunable_type"]]

	local normal_damages = {skill["name"] .. " damages:"}
	local crit_damages = {skill["name"] .. " crit damages:"}
	for dmg = skill["base_dmg_min"], skill["base_dmg_max"], 1 do
		table.insert(normal_damages, a_spell_dmg_quantum(player_state, skill, monster_stats, dmg, spell_tuned_to, false))
		table.insert(crit_damages, a_spell_dmg_quantum(player_state, skill, monster_stats, dmg, spell_tuned_to, true))
	end
	local damages = {["normal"] = normal_damages, ["crit"] = crit_damages}
	return damages
end

function element_factor(dmg, element_a, element_b)
	if element_a == "no_element" or element_b == "no_element" then
		return dmg
	elseif element_a == element_b then
		return 1
	elseif is_strong_against(element_a, element_b) then
		return dmg * 2
	else
		return dmg
	end
end
