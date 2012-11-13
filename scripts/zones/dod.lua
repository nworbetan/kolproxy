-- Noncombat spoiler text

add_choice_text("Typographical Clutter", { -- choice adventure number: 451
	["The left parenthesis"] = "Get left parenthesis",
	["The lower-case L"] = "Gain or lose meat",
	["The big apostrophe"] = { getitem = "plus sign", good_choice = true },
	["The lower-case E"] = "Gain 15 mysticality",
	["The upper-case Q"] = { text = "Gain Teleportitis", good_choice = true },
})

add_choice_text("Ouch!  You bump into a door!", { -- choice adventure number: 25
	["Buy a magic lamp (50 Meat)"] = { text = "Buy a magic lamp for 50 meat" },
	["Buy what appears to be some sort of cloak (5,000 Meat)"] = { text = "Fight mimic and get a wand for 5k meat", good_choice = true },
	["Leave without buying anything."] = { leave_noturn = true },
})

add_choice_text("The Oracle Will See You Now", { -- choice adventure number: 3
	["Leave the Oracle"] = { leave_noturn = true },
	["Pay for a minor consultation (100 Meat)"] = { getmeat = -100, disabled = true },
	["Pay for a major consultation (1,000 Meat)"] = { text = "Enable reading the plus sign", good_choice = true },
})

-- DoD potions

add_processor("used combat item", function ()
	if item_image == "exclam.gif" then
		local tbl = ascension["zone.dod.potions"] or {}
		effects = {
			["acuity"] = "much smarter",
			["blessing"] = "much more stylish",
			["booze"] = "wino",
			["confusion"] = "confused",
			["detection"] = "blink",
			["healing"] = "better",
			["sleep"] = "yawn",
			["strength"] = "much stronger",
			["teleportation"] = "disappearing",
		}
		print(item_name .. " | " .. text)
		for a, b in pairs(effects) do
			if string.find(text, b) then
				print(item_name .. " = " .. a)
				tbl[item_name] = a
			end
		end
		ascension["zone.dod.potions"] = tbl
	end
end)

add_processor("/inv_use.php", function () -- unidentified/identified text does not get updated
	potion = text:match([[<table><tr><td><center><img src="http://images.kingdomofloathing.com/itemimages/exclam.gif" width=30 height=30><br></center>.-You drink the ([a-z]- potion).]])
	if potion then
		local tbl = ascension["zone.dod.potions"] or {}
		effects = {
			["booze"] = "liquid fire",
			["healing"] = "You gain [0-9]- [^D].-oints",
			["confusion"] = "Confused",
			["detection"] = "Object Detection",
			["sleep"] = "Sleepy",
			["strength"] = "Strength of Ten Ettins",
			["acuity"] = "Strange Mental Acuity",
			["blessing"] = "Izchak's Blessing",
			["teleportation"] = "Teleportitis",
		}
		for a, b in pairs(effects) do
			if string.match(text, b) then
				print(potion .. " = " .. a)
				tbl[potion] = a
			end
		end
		ascension["zone.dod.potions"] = tbl
	end
end)

add_printer("/inventory.php", function ()
	local tbl, _, unknown = get_dod_potion_status()
	for potion in table.values(dod_potion_types) do
		if tbl[potion] then -- KoL javascript destroys <span> tags on inventory page
			value = [[<font style="color: green;">{&nbsp;]] .. tbl[potion] .. [[&nbsp;}</font>]]
		else
			value = [[<font style="color: darkorange;" title="Possibilities: ]] .. table.concat(unknown, ", ") .. [[">{&nbsp;unidentified&nbsp;}</font>]]
		end

		text = text:gsub([[(<b class="ircm">)(.-)(</b>&nbsp;<span>[^<]*</span>)]], function (pre, itemname, post)
			-- Support both inventory images turned on and off
			if itemname:contains(potion) then
				return pre .. itemname .. post .. " " .. value
			else
				return false
			end
		end)
	end
end)

add_printer("/fight.php", function()
	local tbl = get_dod_potion_status()
	for potion in table.values(dod_potion_types) do
		if tbl[potion] then
			value = "{&nbsp;" .. tbl[potion] .. "&nbsp;}"
		else
			value = "{&nbsp;unidentified&nbsp;}"
		end
		text = text:gsub([[(<option picurl=exclam [^>]+>]] .. potion .. [[ %([0-9]+%))(</option>)]], "%1 " .. value .. "%2")
	end
end)

local function can_be_potion(itemname, whicheffect)
	local tbl, unknown_potions, unknown_effects = get_dod_potion_status()
	if tbl[itemname] then
		return tbl[itemname] == whicheffect
	end
	for _, p in ipairs(unknown_potions) do
		if p == itemname then
			for _, e in ipairs(unknown_effects) do
				if e == whicheffect then
					return true
				end
			end
		end
	end
	return false
end

add_ascension_warning("/inv_use.php", function()
	local d = get_item_data_by_id(tonumber(params.whichitem))
	if d then
		if can_be_potion(d.name, "booze") and drunkenness() <= maxsafedrunkenness() and drunkenness() + 3 > maxsafedrunkenness() then
			return "Using this potion could make you overdrunk", "dod potion could make overdrunk"
		end
	end
end)

add_extra_ascension_warning("/inv_use.php", function()
	local d = get_item_data_by_id(tonumber(params.whichitem))
	if d then
		if can_be_potion(d.name, "booze") then
			return "This potion could be booze", "dod potion could be booze"
		end
	end
end)

add_extra_ascension_warning("/inv_use.php", function()
	local d = get_item_data_by_id(tonumber(params.whichitem))
	if d then
		if can_be_potion(d.name, "teleportation") then
			if have_item("soft green echo eyedrop antidote") then
				return "This potion could be teleportation", "dod potion could be teleportation"
			else
				return "This potion could be teleportation and you don't have a soft green echo eyedrop antidote", "dod potion could be teleportation without sgeea"
			end
		end
	end
end)

-- Auto-use plus sign

add_automator("/choice.php", function ()
	if not setting_enabled("automate simple tasks") then return end
	if text:match("That plus sign.*It's actually a book") then
-- 		print("just paid for major consultation!")
		text, url = use_item_noajax("plus sign")()
		-- TODO: Open any boxes too?
	end
end)

-- Warnings for adventuring without enough meat

add_always_zone_check(226, function()
	if meat() < 1000 and have("plus sign") then
		return "A major consultation costs 1000 meat."
	end
end)

add_always_zone_check(39, function()
	if meat() < 5000 then
		return "Fighting the mimic costs 5000 meat."
	end
end)