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
	else
		error("Not a valid equipment slot: " .. slot)
	end
end

function get_weapon_reach(name)
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
	local oh_type = "other"
	if name == nil then
		if get_weapon_reach(get_equipped_item("weapon")) == "unarmed" then
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
		-- TODO does "Critical Hit %" need a helper in estimate_modifier_bonuses() ?
		crit_melee_chance = estimated_bonuses["Critical Hit %"] or 0,
		crit_multiplier = 1, -- HACK yeah, this isn't quite right yet
		mainhand_type = get_weapon_reach(get_equipped_item("weapon")),
		mainhand_power = get_item_power(get_equipped_item("weapon")),
		offhand_type = get_offhand_type(get_equipped_item("offhand")),
		offhand_power = get_item_power(get_equipped_item("offhand")),
		int_spell_damage = estimated_bonuses["Spell Damage"] or 0,
		percent_spell_damage = ((estimated_bonuses["Spell Damage %"] or 0) / 100),
		cold_spell_damage = estimated_bonuses["Damage to cold Spells"] or 0,
		hot_spell_damage = estimated_bonuses["Damage to hot Spells"] or 0,
		sleaze_spell_damage = estimated_bonuses["Damage to sleaze Spells"] or 0,
		spooky_spell_damage = estimated_bonuses["Damage to spooky Spells"] or 0,
		stench_spell_damage = estimated_bonuses["Damage to stench Spells"] or 0,
		-- TODO does "Critical Spell %" need a helper in estimate_modifier_bonuses() ?
		crit_spell_chance = estimated_bonuses["Critical Spell %"] or 0,
		-- HACK FIXME 
		spirit_of_what = no_element,
		immaculately_seasoned = have_skill("Immaculate Seasoning"),
		hero_of_the_half_shell = have_skill("Hero of the Half-Shell"),
		damage_reduction = estimated_bonuses["Damage Reduction"] or 0,
	-- TODO	phialForm :: Element,
		cold_resistance = estimated_bonuses["Cold Resistance"] or 0,
		hot_resistance = estimated_bonuses["Hot Resistance"] or 0,
		sleaze_resistance = estimated_bonuses["Sleaze Resistance"] or 0,
		spooky_resistance = estimated_bonuses["Spooky Resistance"] or 0,
		stench_resistance = estimated_bonuses["Stench Resistance"] or 0}
	return state
end

function get_skill_data(name)
	-- TODO sanity check name
	local skills = datafile("combat-skills")
	return skills[name]
end

function get_monster_data(name)
	-- HACK currently using get_monster_data() as a wrapper for getCurrentMonster()
	--	this is because of lazyness more so than any other reason
	local monster = {}
	if name == "current" then
		local cmd = getCurrentMonster()
		monster = {
			attack = cmd["Stats"]["ModAtk"],
			defense = cmd["Stats"]["ModDef"],
			hp = cmd["Stats"]["ModHP"],
			initiative = 50,
			def_element = "no_element",
			off_element = "no_element",
			group_size = 1,
			phylum = cmd["Stats"]["Phylum"]
		}
	else
		error("get_monster_data() is unfinished for non-current monsters")
	end
	--[[local monster = {
		attack = 100,
		defense = 18,
		hp = 100,
		initiative = 50,
		def_element = "no_element",
		off_element = "no_element",
		group_size = 1,
		phylum = "hobo"
	}]]
	return monster
end

function is_strong_against(elem_a, elem_b)
	local t = {
		sleaze = {
			stench = true,
			hot = true},
		stench = {
			hot = true,
			spooky = true},
		hot = {
			spooky = true,
			cold = true},
		spooky = {
			cold = true,
			sleaze = true},
		cold = {
			sleaze = true,
			stench = true}
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
			cold = true},
		stench = {
			cold = true,
			sleaze = true},
		hot = {
			sleaze = true,
			stench = true},
		spooky = {
			stench = true,
			hot = true},
		cold = {
			hot = true,
			spooky = true}
	}
	if elem_a == "no_element" or elem_b == "no_element" then
		return false
	elseif t[elem_a][elem_b] then
		return true
	end
	return false
end

function estimate_other_weapon_damage_percent()
	if moonsign("Mongoose") then
		return 20
	end
	return 0
end

function estimate_other_spell_damage_percent()
	if moonsign("Wallaby") then
		return 20
	end
	return 0
end

add_printer("/fight.php", function()
	local numbers = melee_damage(get_current_player_state(), get_skill_data("attack"), get_monster_data("current"))
	local strung = "Attack damages: "
	for i, n in ipairs(numbers) do
		local spacer = ", "
		if i == 1 then
			spacer = ""
		end
		strung = strung .. spacer .. n
	end
	text = text:gsub("<div id='fightform' class='hideform'><p><center><table><a name=\"end\">",
			function(x) return x .. strung end)
end)
