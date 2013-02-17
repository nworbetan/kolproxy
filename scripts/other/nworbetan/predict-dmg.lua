function melee_damage(player_state, skill, monster_stats)
	if skill["type"] ~= "melee" then
		error("Not a valid melee damage skill: " .. skill["type"])
	end

	local mh_pwr = player_state["mainhand_power"]

	local s_m_b = nil -- s_m_b = skill_muscle_bonus
	if player_state["class"] == skill["class"] then
		s_m_b = skill["skill_muscle_bonus"][2]
	else
		s_m_b = skill["skill_muscle_bonus"][1]
	end

	local w_t_f = nil -- w_t_f = weapon_type_factor
	if player_state["mainhand_type"] == "unarmed" then
		w_t_f = 0.25
	elseif player_state["mainhand_type"] == "melee" then
		w_t_f = 1
	elseif player_state["mainhand_type"] == "ranged" then
		w_t_f = 0.75
	end

	-- eff_mus = effective muscle
	local eff_mus = math.floor(player_state["buffed_muscle"] * s_m_b * w_t_f)

	-- FIXME if off_diff < 0 and not skill["auto_hit"] then ???
	-- off_diff = offensive difference
	local off_diff = eff_mus - monster_stats["defense"]

	local elementable = {
		cold = player_state["cold_weapon_damage"],
		hot = player_state["hot_weapon_damage"],
		sleaze = player_state["sleaze_weapon_damage"],
		spooky = player_state["spooky_weapon_damage"],
		stench = player_state["stench_weapon_damage"]
	}
	local elemental_dmg = 0
	for e, v in pairs(elementable) do
		if is_weak_to(monster_stats["def_element"], e) then
			elemental_dmg = elemental_dmg + 2 * v
-- 			print(monster_stats["def_element"] .. " is weak to " .. e .. ": adding " .. (2 * v))
		elseif monster_stats["def_element"] == e and v > 0 then
			elemental_dmg = elemental_dmg + 1
-- 			print(monster_stats["def_element"] .. " is " .. e .. ": adding 1 instead of " .. v)
		else
			elemental_dmg = elemental_dmg + v
-- 			print("adding " .. v .. " " .. e)
		end
	end

	-- TODO dual wielding, xxx_butt, ravenous pounce, etc
	local additional_dmg = 0

	local function a_melee_dmg_quantum(x)
		local dmg = math.floor(math.max(1, off_diff + player_state["int_weapon_damage"]
				+ (player_state["crit_multiplier"] * skill["weapon_dmg_multiplier"] * x))
				* (1 + player_state["percent_weapon_damage"]))
				+ elemental_dmg
				+ additional_dmg
		return dmg
	end

	local damages = {}
	for dmg = math.ceil(mh_pwr / 10), math.ceil(mh_pwr / 5), 1 do
		table.insert(damages, a_melee_dmg_quantum(dmg))
	end
	return damages
end

function spell_damage(player_state, skill, monster_stats)
	if skill["type"] ~= "spell" then
		error("Not a valid spell damage skill: " .. skill["type"])
	end

	-- TODO this algorithm really really need testing to see if a low dice roll for base_dmg overpowers a large single elemental damage bonus
	local function sauce_tuned_to()
		avg_base_dmg = math.ceil((skill["base_dmg_min"] + skill["base_dmg_max"]) / 2)
		hypothetical_cold = a_spell_dmg_quantum(avg_base_dmg, cold)
		hypothetical_hot = a_spell_dmg_quantum(avg_base_dmg, hot)

		local tuned = nil
		if not have_skill("Immaculate Seasoning") then
			tuned = no_element
		elseif hypothetical_cold > hypothetical_hot then
			tuned = cold
		elseif hypothetical_cold < hypothetical_hot then
			tuned = hot
		else
			tuned = no_element
		end
		return tuned
	end

	local tuning = {
		cold_tuned = cold,
		hot_tuned = hot,
		immaculate = sauce_tuned_to(),
		physical_tuned = no_element,
		poison_tuned = no_element,
		spirit_of_something = player_state["spirit_of_what"],
		sleaze_tuned = sleaze,
		spooky_tune = spooky,
		stench_tuned = stench
	}

	local spell_tuned_to = tuning[skill["tunable_type"]]

	local function a_spell_dmg_quantum(x, tuned_element)
		return x
	end

	local damages = {}
	for dmg = skill["base_dmg_min"], skill["base_dmg_max"], 1 do
		table.insert(damages, a_spell_dmg_quantum(dmg))
	end
	return damages
end
