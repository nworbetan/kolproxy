function array_contains_value(array, value)
	local found = false
	for i = 1, #array do
		if array[i] == value then
			found = true
			break
		end
	end
	return found
end

function table_has_key(table, key)
	return table[key] ~= nil
end

function get_equipped_item(slot)
	local valid_slots = {"hat", "container", "weapon", "offhand", "pants", "acc1", "acc2", "acc3", "familiarequip"}
	if array_contains_value(valid_slots, slot) then
		return equipment()[slot]
	end
	error("Not a valid equipment slot: " .. slot)
end

function get_weapon_reach(name)
	if name == "current" then
		name = get_equipped_item("weapon")
	end
	local wep_type = "unarmed"
	if name ~= nil then
		wep_type = maybe_get_itemdata(name)["weapon_reach"]
	end
	return wep_type
end

function get_item_power(name)
	local power = 0
	if name ~= nil then
		power = maybe_get_itemdata(name)["power"]
	end
	return power
end

function get_offhand_type(name)
	if name == "current" then
		name = get_equipped_item("offhand")
	end
	local oh_type = "other"
	if name == nil then
		-- differentiating between an unarmed and empty offhand may be
		-- overkill, idk, but it was possible to do, so I did it
		if get_weapon_reach("current") == "unarmed" then
			oh_type = "unarmed"
		else
			oh_type = "empty"
		end
	elseif maybe_get_itemdata(name)["is_shield"] then
		oh_type = "shield"
	elseif maybe_get_itemdata(name)["weapon_reach"] ~= nil then
		oh_type = maybe_get_itemdata(name)["weapon_reach"]
	end
	return oh_type
end

function get_crit_multiplier()
	if have_skill("Legendary Luck") then
		return 4
	end
	return 2
end

function get_fumble_chance()
	buffs = buffslist()
	if buffs["Clumsy"] or buffs["QWOPPed Up"] then
		return 1
	end
	-- HACK base chance needs spading
	-- also, should this be handled in estimate_modifier_bonuses()?
	return 0.05
end

function get_pasta_tuning()
	if have_intrinsic("Spirit of Cayenne") then
		return "hot"
	elseif have_intrinsic("Spirit of Peppermint") then
		return "cold"
	elseif have_intrinsic("Spirit of Garlic") then
		return "stench"
	elseif have_intrinsic("Spirit of Wormwood") then
		return "spooky"
	elseif have_intrinsic("Spirit of Bacon Grease") then
		return "sleaze"
	end
	return "no_element"
end

function get_phial_form()
	buffs = buffslist()
	if buffs["Coldform"] then
		return "cold"
	elseif buffs["Hotform"] then
		return "hot"
	elseif buffs["Sleazeform"] then
		return "sleaze"
	elseif buffs["Spookyform"] then
		return "spooky"
	elseif buffs["Stenchform"] then
		return "stench"
	end
	return "no_element"
end

function get_current_player_state()
	local estimated_bonuses = estimate_modifier_bonuses()
	local state = {
		class = classid(),
		buffed_muscle = buffedmuscle(),
		buffed_myst = buffedmysticality(),
		buffed_moxie = buffedmoxie(),
		initiative = estimated_bonuses["Combat Initiative"] or 0,
		monster_level_adjustment = estimated_bonuses["Monster Level"] or 0,
		int_weapon_damage = estimated_bonuses["Weapon Damage"] or 0,
		percent_weapon_damage = ((estimated_bonuses["Weapon Damage %"] or 0) / 100),
		int_ranged_damage = estimated_bonuses["Ranged Damage"] or 0,
		cold_weapon_damage = estimated_bonuses["Cold Damage"] or 0,
		hot_weapon_damage = estimated_bonuses["Hot Damage"] or 0,
		sleaze_weapon_damage = estimated_bonuses["Sleaze Damage"] or 0,
		spooky_weapon_damage = estimated_bonuses["Spooky Damage"] or 0,
		stench_weapon_damage = estimated_bonuses["Stench Damage"] or 0,
		-- TODO does "Critical Hit %" need a helper in estimate_modifier_bonuses() instead of this +9?
		crit_melee_chance = (((estimated_bonuses["Critical Hit %"] or 0) + 9) / 100),
		crit_multiplier = get_crit_multiplier(),
		fumble_chance = get_fumble_chance(),
		mainhand_type = get_weapon_reach("current"),
		mainhand_power = get_item_power(get_equipped_item("weapon")),
		offhand_type = get_offhand_type("current"),
		offhand_power = get_item_power(get_equipped_item("offhand")),
		int_spell_damage = estimated_bonuses["Spell Damage"] or 0,
		percent_spell_damage = ((estimated_bonuses["Spell Damage %"] or 0) / 100),
		cold_spell_damage = estimated_bonuses["Damage to cold Spells"] or 0,
		hot_spell_damage = estimated_bonuses["Damage to hot Spells"] or 0,
		sleaze_spell_damage = estimated_bonuses["Damage to sleaze Spells"] or 0,
		spooky_spell_damage = estimated_bonuses["Damage to spooky Spells"] or 0,
		stench_spell_damage = estimated_bonuses["Damage to stench Spells"] or 0,
		-- TODO does "Critical Spell %" need a helper in estimate_modifier_bonuses() instead of this +9?
		crit_spell_chance = (((estimated_bonuses["Critical Spell %"] or 0) + 9) / 100),
		spirit_of_what = get_pasta_tuning(),
		intrinsically_spicy = have_skill("Intrinsic Spiciness"),
		immaculately_seasoned = have_skill("Immaculate Seasoning"),
		mp_cost_modifier = estimated_bonuses["Mana Cost"],
		hero_of_the_half_shell = have_skill("Hero of the Half-Shell"),
		damage_reduction = estimated_bonuses["Damage Reduction"] or 0,
		phial_form = get_phial_form(),
		cold_resistance = estimated_bonuses["Cold Resistance"] or 0,
		hot_resistance = estimated_bonuses["Hot Resistance"] or 0,
		sleaze_resistance = estimated_bonuses["Sleaze Resistance"] or 0,
		spooky_resistance = estimated_bonuses["Spooky Resistance"] or 0,
		stench_resistance = estimated_bonuses["Stench Resistance"] or 0
	}
	return state
end

function get_skill_data(name)
	local skills = datafile("combat-skills")
	if not skills[name] then
		error("unknown or invalid combat skill: " .. name)
	end
	return skills[name]
end

function get_monster_data(name)
	local monster = {}
	if name == "current" then
		-- TODO if currently_fighting() then
		local cmd = getCurrentFightMonster()
		monster = {
			attack = cmd["Stats"]["ModAtk"],
			defense = cmd["Stats"]["ModDef"],
			hp = cmd["Stats"]["ModHP"],
			-- HACK does the wiki have accurate init numbers?
			initiative = 50,
			element = cmd["Stats"]["Element"] or "no_element",
			-- HACK can we get group size added to monsters.txt?
			group_size = 1,
			phylum = cmd["Stats"]["Phylum"],
			physical_resistance = cmd["Stats"]["Phys"] or 0
		}
	else
		-- TODO sanity check name?
		local mdc = buildCurrentFightMonsterDataCache(name, "")
		monster = {
			attack = mdc["Stats"]["Atk"],
			defense = mdc["Stats"]["Def"],
			hp = mdc["Stats"]["HP"],
			-- HACK does the wiki have accurate init numbers?
			initiative = 50,
			element = mdc["Stats"]["Element"] or "no_element",
			-- HACK can we get group size added to monsters.txt?
			group_size = 1,
			phylum = mdc["Stats"]["Phylum"],
			physical_resistance = mdc["Stats"]["Phys"] or 0
		}
	end
	return monster
end

function is_strong_against(elem_a, elem_b)
	local t = {
		sleaze = {
			stench = true,
			hot = true
		},
		stench = {
			hot = true,
			spooky = true
		},
		hot = {
			spooky = true,
			cold = true
		},
		spooky = {
			cold = true,
			sleaze = true
		},
		cold = {
			sleaze = true,
			stench = true
		}
	}
	if elem_a == "no_element" or elem_b == "no_element" then
		return false
	elseif t[elem_a][elem_b] then
		return true
	end
	return false
end

function is_weak_to(elem_a, elem_b)
	local t = {
		sleaze = {
			spooky = true,
			cold = true
		},
		stench = {
			cold = true,
			sleaze = true
		},
		hot = {
			sleaze = true,
			stench = true
		},
		spooky = {
			stench = true,
			hot = true
		},
		cold = {
			hot = true,
			spooky = true
		}
	}
	if elem_a == "no_element" or elem_b == "no_element" then
		return false
	elseif t[elem_a][elem_b] then
		return true
	end
	return false
end

function estimate_other_weapon_damage()
	local w_d = 0
	if get_weapon_reach("current") == "unarmed" then
		if have_skill("Master of the Surprising Fist") then
			w_d = w_d + 10
		end
		if have_intrinsic("Kung Fu Fighting") then
			w_d = w_d + 3 * level()
		end
	end
	return w_d
end

function estimate_other_weapon_damage_percent()
	if moonsign("Mongoose") then
		return 20
	end
	return 0
end

function estimate_other_spell_damage()
	if get_pasta_tuning() ~= "no_element" then
		return 10
	end
	return 0
end

function estimate_other_spell_damage_percent()
	if moonsign("Wallaby") then
		return 20
	end
	return 0
end

function estimate_other_ranged_damage()
	if have_skill("Disco Fever") and get_weapon_reach("current") == "ranged" then
		return math.min(15, level())
	end
	return 0
end

function estimate_other_spooky_damage()
	if have_intrinsic("A Little Bit Frightening") then
		return 3 * level()
	end
	return 0
end

-- FIXME can_use_skill() needs a *lot* of work still >_<
function can_use_skill(skill, mid_fight)
	local skill_data = get_skill_data(skill)
	if skill == "Attack" then
		if classid() == 14 then
			return false
		end
		return true
	end

	-- TODO maybe move have_skill() checks to the data file?
	--	or maybe that would be retarded?
	if not have_skill(skill) and not skill:match("Combo$") then
		return false
	elseif skill:match("Combo$") then
		if classid() ~= 2 then
			return false
		elseif skill:match("Head") and not have_skill("Headbutt") then
			return false
		elseif skill:match("Knee") and not have_skill("Kneebutt") then
			return false
		elseif skill:match("Shield") and not have_skill("Shieldbutt") then
			return false
		end
	end

	local cost = skill_data["mp_cost"]
	if skill_data["is_trivial_skill"] and classid() == skill_data["class"] then
		cost = 0
	end

	-- TODO hmm, technically, mp restoring *is* allowed during combat...
	if mid_fight and mp() < cost then
		return false
	end

	local condition = "return " .. (skill_data["use_condition"] or "true")
	--print("condition: " .. condition)
	return setfenv(loadstring(condition), getfenv())()
end

-- NOTE everything from this point down is very ad-hoc and probably is not
--	going to be a permanent part of anything at all

function propagate(from_a, from_b)
	local to = {}
	for _, fa in ipairs(from_a) do
		for _, fb in ipairs(from_b) do
			table.insert(to, (fa + fb))
		end
	end
	return to
end

function show_all_damages(monster)
	local skd = datafile("combat-skills")
	local plst = get_current_player_state()
	local mnst = get_monster_data(monster)
	local bigstring = ""
	for skill, _ in pairs(skd) do
		if can_use_skill(skill, true) then
			local numbers = predict_damage(plst, skill, mnst)
			local norm = numbers["name"] .. " norm: " .. table.concat(numbers["normal_dmg"], ", ")
			local crit = numbers["name"] .. " crit: " .. table.concat(numbers["crit_dmg"], ", ")
			bigstring = bigstring .. norm .. "<br>" .. crit .. "<br>"
		end
	end
	return bigstring
end

function show_all_odds(monster)
	local skd = datafile("combat-skills")
	local plst = get_current_player_state()
	local mnst = get_monster_data(monster)
	local bigstring = ""
	for skill, _ in pairs(skd) do
		if can_use_skill(skill, true) then
			local numbers = predict_damage(plst, skill, mnst)
			local odds = {}
			-- TODO sort by k and/or v
			for k, v in pairs(numbers["dmg_odds"]) do
				table.insert(odds, "(" .. k .. ": " .. v .. ")")
			end
			bigstring = bigstring .. numbers["name"] .. ": " .. table.concat(odds, ", ") .. "<br>"
		end
	end
	return bigstring
end

function show_all_averages(monster)
	local skd = datafile("combat-skills")
	local plst = get_current_player_state()
	local mnst = get_monster_data(monster)
	local bigstring = ""
	for skill, _ in pairs(skd) do
		if can_use_skill(skill, true) then
			local numbers = predict_damage(plst, skill, mnst)
			bigstring = bigstring .. numbers["name"] .. ": " .. numbers["mean_dmg"] .. "<br>"
		end
	end
	return bigstring
end

--[[add_printer("/fight.php", function()
	text = text:gsub("<div id='fightform' class='hideform'><p><center><table><a name=\"end\">",
			function(x) return x .. show_all_damages("current") end)
end)]]

-- TODO apparently lots of turtle helmets have "special" damages?
-- and odd numbered powers get an extra +1 max dmg... sometimes? always? what?
-- http://kol.coldfront.net/thekolwiki/index.php/Headbutt
function headbutt_dmg(helm)
	if helm == "current" then
		helm = get_equipped_item("hat")
	end
	local dmg = {}
	local p = get_item_power(helm)
	if have_skill("Tao of the Terrapin") then
		p = 2 * p
	end
	for x = math.ceil(p / 10), math.ceil(p / 5) do
		table.insert(dmg, x)
	end
	return dmg
end

-- TODO I think this is actually ready for testing, with a (very small but)
--	greater than zero chance of being correct
function kneebutt_dmg(pants)
	if pants == "current" then
		pants = get_equipped_item("pants")
	end
	local dmg = {}
	local p = get_item_power(pants)
	if have_skill("Tao of the Terrapin") then
		p = 2 * p
	end
	for x = math.ceil(p / 10), math.ceil(p / 5) do
		table.insert(dmg, x)
	end
	return dmg
end

-- the item powers returned by get_item_power() differ from the dmg numbers
-- listed on http://kol.coldfront.net/thekolwiki/index.php/Shieldbutt
-- TODO figure out exactly how wrong the wiki is, then fix it >_<
function shieldbutt_dmg(shield)
	if shield == "current" then
		shield = get_equipped_item("offhand")
	end
	local dmg = {}
	local p = get_item_power(shield)
	for x = math.ceil(p / 10), math.ceil(p / 5) do
		if shield == "polyalloy shield" then
			x = x + 17
		elseif shield == "spiky turtle shield" then
			x = x * 2
		end
		table.insert(dmg, x)
	end
	return dmg
end

function wato(in_norm, in_crit, crit_chance)
	local out_tab = {}
	-- TODO something like: norm_weight = (1 - fumble_chance - glance_chance - crit_chance) / #in_norm
	local norm_weight = (1 - crit_chance) / #in_norm
	local crit_weight = crit_chance / #in_crit
	for _, x in ipairs(in_norm) do
		out_tab[x] = (out_tab[x] or 0) + norm_weight
	end
	for _, x in ipairs(in_crit) do
		out_tab[x] = (out_tab[x] or 0) + crit_weight
	end
	return out_tab
end

function avg(tab)
	local avg = 0
	for value, weight in pairs(tab) do
		avg = avg + (value * weight)
	end
	return avg
end

