-- starting war in frat house

add_choice_text("Catching Some Zetas", { -- choice adventure number: 143
	["Take the bombs and wreak some havoc"] = "Gain 50 muscle",
	["Keep the bombs to use later"] = "Get 6-7 sake bombers",
	["Wake up the pledge and throw down"] = "Fight a war pledge",
})

add_choice_text("Fratacombs", { -- choice adventure number: 145, 146
	["Wander this way"] = "Gain 50 muscle",
	["Wander that way"] = "Get 2 assorted items",
	["Wander the other way"] = "Do nothing (not in the right costume)",
	["Screw this, head to the roof"] = { text = "Start the war", good_choice = true },
})

add_choice_text("One Less Room Than In That Movie", { -- choice adventure number: 144
	["Supply Room"] = "Gain 50 sarcasm",
	["Munitions Dump"] = "Get 2-5 beer bombs",
	["Officers' Lounge"] = "Fight a drill sergeant",
})

-- starting war in hippy camp

add_choice_text("The Thin Tie-Dyed Line", {
	["The Munitions Yurt"] = "Get 2-5 water pipe bombs",
	["The Rations Yurt"] = "Gain 50 moxie",
	["The Barracks Yurt"] = "Fight a war hippy drill sergeant",
})

add_choice_text("Bait and Switch", {
	["Take the bait and go wreak havoc"] = "Gain 50 muscle",
	["Gaffle some bait for later"] = "Get 2-5 handfuls of ferret bait",
	["Wake the cadet up and fight him"] = "Fight a war hippy (space) cadet",
})

add_choice_text("Blockin' Out the Scenery", {
	["The Chill-Out Yurt"] = "Gain 50 mysticality",
	["The Rations Yurt"] = "Get some various items",
	["The Lookout Tower"] = { text = "Start the war", good_choice = true },
})

-- arena

add_processor("used combat item", function()
	if item_name == "rock band flyers" or item_name == "jam band flyers" then
		fight["item.flyers.advertised"] = "yes"
	end
end)

add_printer("/bigisland.php", function()
	if text:contains("You roll up to the amphitheater and see that Radioactive Child has already taken the stage.") then
		local annotate = {
			["Try to get into the music"] = "Get +10%% all attributes buff (20 turns)",
			["Bust a move"] = "Get +40%% meat buff (20 turns)",
			["Pick a fight"] = "Get +50%% initiative buff (20 turns)",
		}
		for from, to in pairs(annotate) do
			text = text:gsub("<input type=submit class=button value=\""..from.."\">", "%0<br>" .. to)
		end
	end
end)

add_printer("/postwarisland.php", function()
	if text:contains("You roll up to the amphitheater and see that Radioactive Child has already taken the stage.") then
		local annotate = {
			["Try to get into the music"] = "Get +10%% all attributes buff (20 turns)",
			["Bust a move"] = "Get +40%% meat buff (20 turns)",
			["Pick a fight"] = "Get +50%% initiative buff (20 turns)",
		}
		for from, to in pairs(annotate) do
			text = text:gsub("<input type=submit class=button value=\""..from.."\">", "%0<br>" .. to)
		end
	end
end)

-- gremlins

add_always_adventure_warning(function(zoneid)
	local z = tonumber(zoneid)
	if z and z >= 182 and z <= 185 then
		if not have("molybdenum magnet") then
			return "You need a molybdenum magnet for the gremlins.", "molybdenum magnet for gremlins"
		end
	end
end)

local gremlins = {
	["a batwinged gremlin"] = "molybdenum hammer",
	["an erudite gremlin"] = "molybdenum crescent wrench",
	["a spider gremlin"] = "molybdenum pliers",
	["a vegetable gremlin"] = "molybdenum screwdriver",
}

add_processor("/fight.php", function()
	if gremlins[monster_name] then
		failures = {
			"a bombing run",
			"random junk",
			"fibula",
			"picks a",
		}
		for x in table.values(failures) do
			if text:contains(x) then
				fight["gremlin.has tool"] = "no"
			end
		end
		if text:contains("whips out a") then
			fight["gremlin.has tool"] = "yes"
			for x in text:gmatch("var onturn = ([0-9]+);") do
				fight["gremlin.tool round"] = tonumber(x)
			end
		end
	end
end)

add_printer("/fight.php", function()
	if gremlins[monster_name] and fight["gremlin.has tool"] == "yes" then
		local fightround = nil
		for x in text:gmatch("var onturn = ([0-9]+);") do
			fightround = tonumber(x)
		end
		if fightround and fightround == tonumber(fight["gremlin.tool round"]) then
			text = text:gsub("<body>", [[<body style="background-color: lightgreen">]])
			local link, desc
			if not have_item("molybdenum magnet") then
				link = nil
			elseif text:contains("<select name=whichitem2>") and have_item("jam band flyers") then
				link = make_href("/fight.php", { action = "useitem", whichitem = get_itemid("jam band flyers"), whichitem2 = get_itemid("molybdenum magnet"), pwd = session.pwd })
				desc = "Use jam band flyers + molybdenum magnet"
			elseif text:contains("<select name=whichitem2>") and have_item("rock band flyers") then
				link = make_href("/fight.php", { action = "useitem", whichitem = get_itemid("rock band flyers"), whichitem2 = get_itemid("molybdenum magnet"), pwd = session.pwd })
				desc = "Use rock band flyers + molybdenum magnet"
			else
				link = make_href("/fight.php", { action = "useitem", whichitem = get_itemid("molybdenum magnet"), pwd = session.pwd })
				desc = "Use molybdenum magnet"
			end
			if link then
				text = text:gsub("(>[^<>]-whips out a.-)(</td>)", [[%1 <a href="]]..link..[[" style="color: green">{ ]] .. desc .. [[ }</a>%2]])
			end
		end
	end
end)

-- beach

add_ascension_zone_check(136, function()
	if not buff("Hippy Stench") then
		if have("reodorant") or have("handful of pine needles") then
			return "You probably want Hippy Stench for the beach."
		end
	end
end)

add_printer("/bigisland.php", function ()
	if params.place == "nunnery" then
		if text:contains("Our Lady of Perpetual Indecision") then
			local meat = tonumber(ascension["zone.island.nun meat"]) or 0
			if meat < 100000 then
				text = text:gsub([[<tr><td height=4></td></tr>]], [[%0<tr><td><center style="color: green">{ Recovered ]] .. format_integer(meat) .. [[ meat for the nuns. }</td></tr>%0]], 1)
			end
		end
	end
end)


-- nuns

add_ascension_adventure_warning(function(zoneid)
	if zoneid == 126 then
		if not buff("Polka of Plenty") then
			if have_skill("The Polka of Plenty") then
				return "You probably want Polka of Plenty for the nuns.", "polka of plenty for nuns"
			end
		end
		if not buff("Greedy Resolve") and have("resolution: be wealthier") then
			return "You probably want to use resolution: be wealthier for the nuns.", "greedy resolve for nuns"
		end
	end
end)

-- farm

add_choice_text("Cornered!", { -- choice adventure number: 147
	["Grab the pitchfork and wave it around"] = { text = "Move ducks to The Granary (higher meat drop)" },
	["Bang on the cowbell"] = { text = "Move ducks to The Bog (stench)" },
	["Make a fence out of the barbed wire"] = { text = "Move ducks to The Pond (cold, shortcut)", good_choice = true },
})

add_choice_text("Cornered Again!", { -- choice adventure number: 148
	["Knock over the lantern"] = { text = "Move ducks to The Back 40 (hot, shortcut)", good_choice = true },
	["Try to catch them in the beartrap"] = { text = "Move ducks to The Family Plot (spooky)" },
})

add_choice_text("How Many Corners Does this Stupid Barn Have!?", { -- choice adventure number: 149
	["Grab the shotgun and start firing"] = { text = "Move ducks to The Shady Thicket (drop booze)" },
	["Dump out the drum"] = { text = "Move ducks to The Other Back 40 (sleaze, shortcut)", good_choice = true },
})

add_processor("used combat item", function()
	if item_name == "PADL Phone" and text:contains("You punch a few buttons on the phone") then
		set_ascension_turn_counter("PADL Phone", 10)
	end
end)

add_processor("used combat item", function()
	if item_name == "communications windchimes" and text:contains("You bang out a series of chimes") then
		set_ascension_turn_counter("Chimes", 10)
	end
end)

add_processor("/fight.php", function()
	local nungained = tonumber(text:match("<!%-%-WINWINWIN%-%->.-<tr><td align=center valign=center><img src=\"http://images.kingdomofloathing.com/itemimages/meat.gif\" width=30 height=30></td><td valign=center>You gain ([0-9]+) Meat</td></tr>.-approaches you and takes the Meat..-Thank you for recovering this Meat")) -- TODO-future: re-do regex a bit?
	if nungained then
		increase_ascension_counter("zone.island.nun meat", nungained)
	elseif text:contains("dirty thieving brigand") then
		if text:contains("<!--WINWINWIN-->") or text:contains("You win the fight!") then
			error "Appeared to win a brigand fight, but didn't detect any meat drop."
		end
	end
end)

add_printer("/fight.php", function ()
	text = text:gsub("(<!%-%-WINWINWIN%-%->.-<tr><td align=center valign=center><img src=\"http://images.kingdomofloathing.com/itemimages/meat.gif\" width=30 height=30></td><td valign=center>)(You gain [0-9]+ Meat)(</td></tr>.-approaches you and takes the Meat..-Thank you for recovering this Meat)", function (pre, nunmsg, post) -- TODO-future: re-do regex a bit?
		return pre .. nunmsg .. "<br><span style=\"color: green;\">{ Recovered " .. format_integer(get_ascension_counter("zone.island.nun meat")) .. " meat. }</span>" .. post
	end)
end)

add_processor("/postwarisland.php", function()
	if text:contains("The Sisters give you an invigorating massage.") then
		increase_daily_counter("zone.island.nun massage")
	end
end)

add_printer("/postwarisland.php", function()
	if text:contains("The Sisters give you an invigorating massage.") then
		text = text:gsub("(The Sisters give you an invigorating massage.)", [[<span style="color: green">%1</span> { ]]..get_daily_counter("zone.island.nun massage")..[[ / 3 times today. }]])
	end
end)

-- battlefield

function increase_battlefield_kill_counter(side, amount)
	local killrange = ascension["battlefield.kills." .. side] or {}
	if not killrange.min then
		killrange.min = tonumber(ascension["battlefield.kills." .. side .. ".min"]) or 0
	end
	if not killrange.max then
		killrange.max = tonumber(ascension["battlefield.kills." .. side .. ".max"]) or 0
	end
	local min_add = 0
	local max_add = amount
	if amount > 1 then -- Got a message, so the kill definitely counts
		min_add = amount
	end
	killrange.min = math.min(1000, killrange.min + min_add)
	killrange.max = math.min(1000, killrange.max + max_add)
	ascension["battlefield.kills." .. side] = killrange
end

add_processor("/fight.php", function()
	frat_kills = {
		[ [[You see one of your frat brothers take out an M.C. Escher drawing]] ] = 1,
		[ [[You see a hippy loading his didgeridooka, but before he can fire it,]] ] = 1,
		[ [[hippy take one bite too many from a big plate of brownies, then curl up to take a nap.]] ] = 1,
		[ [[You see a hippy a few paces away suddenly realize that he's violating his deeply held pacifist beliefs,]] ] = 1,
		[ [[You look over and see a fellow frat brother garotting a hippy shaman with the hippy's own dreadlocks.]] ] = 1,
		[ [[You glance over and see one of your frat brothers hosing down a hippy with soapy water.]] ] = 1,
		[ [[You glance out over the battlefield and see a hippy from the F.R.O.G. division get the hiccups]] ] = 1,
		[ [[sneeze midway through making a bomb, inadvertently turning himself]] ] = 1,
		[ [[You see a frat boy hose down a hippy Airborne Commander with sugar water.]] ] = 1,
		[ [[You see one of your frat brothers paddling a hippy who seems to be enjoying it.]] ] = 1,
		[ [[As the hippy falls, you see a hippy a few yards away clutch his chest and fall over, too.]] ] = 1,

		[ [[You see a War Frat Grill Sergeant hose down three hippies with]] ] = 3,
		[ [[As you finish your fight, you see a nearby Wartender mixing up a cocktail of vodka and pain for a trio of charging hippies.]] ] = 3,
		[ [[You see one of your frat brothers douse a trio of nearby hippies in cheap aftershave.]] ] = 3,
		[ [[You see one of your frat brothers line up three hippies for simultaneous paddling.]] ] = 3,
		[ [[Some mercenaries drive up, shove three hippies into their bitchin' meat car,]] ] = 3,
		[ [[As you deliver the finishing blow, you see a frat boy lob a sake bomb into a trio of nearby hippies.]] ] = 3,

		[ [[You see one of your Beer Bongadier frat brothers use a complicated beer bong to spray cheap, skunky beer on a whole squad of hippies at once.]] ] = 7,
		[ [[You glance over and see one of the Roaring Drunks from the 151st Division overturning a mobile sweat lodge in a berserker rage.]] ] = 7,
		[ [[You see one of your frat brothers punch an F.R.O.G. in the solar plexus, then aim the subsequent exhale]] ] = 7,
		[ [[You see a Grillmaster flinging hot kabobs as fast as he can make them.]] ] = 7,

		[ [[A streaking frat boy runs past a nearby funk of hippies.]] ] = 15,
		[ [[You see one of the Fortunate 500 call in an air strike.]] ] = 15,
		[ [[You look over and see a platoon of frat boys round up a funk of hippies and take them prisoner.]] ] = 15,
		[ [[You see a kegtank and a mobile sweat lodge facing off in the distance.]] ] = 15,

		[ [[You see an entire regiment of hippies throw down their arms]] ] = 31,
		[ [[You see a squadron of police cars drive up,]] ] = 31,
		[ [[You see a kegtank rumble through the battlefield,]] ] = 31,

		[ [[You see the a couple of frat boys attaching big, long planks of wood to either side of a kegtank.]] ] = 63,
		[ [[Several SWAT vans of police in full riot gear pull up, and one of them informs the hippies through a megaphone]] ] = 63,
		[ [[You see a couple of frat boys stick a fuse into a huge wooden barrel, light the fuse, and roll it down the hill]] ] = 63,
	}

	hippy_kills = {
		[ [[You look over and see a fellow hippy warrior using his dreadlocks to garotte a frat warrior.]] ] = 1,
		[ [[You see a Green Gourmet give a frat boy a plate of herbal brownies.]] ] = 1,
		[ [[Elsewhere on the battlefield, you see a fellow hippy grab a frat warrior's paddle]] ] = 1,
		[ [[You see a Grill Sergeant pour too much lighter fluid on his grill]] ] = 1,
		[ [[You see a Fire Spinner blow a gout of flame onto a Grill Sergeant's grill]] ] = 1,
		[ [[Nearby, you see one of your sister hippies explaining the rules of Ultimate Frisbee]] ] = 1,
		[ [[You see a member of the frat boy's 151st division pour himself a stiff drink,]] ] = 1,
		[ [[You glance over your shoulder and see a squadron of winged ferrets descend on a frat warrior,]] ] = 1,
		[ [[You see a hippy shaman casting a Marxist spell over a member]] ] = 1,
		[ [[You see a frat boy warrior pound a beer, smash the can against his forehead,]] ] = 1,
		[ [[You see an F.R.O.G. crunch a bulb of garlic in his teeth and breathe all over]] ] = 1,

		[ [[vines sprout from a War Hippy Shaman's dreads and entangle three attacking frat boy warriors.]] ] = 3,
		[ [[Nearby, you see an Elite Fire Spinner take down three frat boys]] ] = 3,
		[ [[You look over and see three ridiculously drunk members of the 151st Division]] ] = 3,
		[ [[You see a member of the Fortunate 500 take a phone call, hear him holler something about a stock market crash,]] ] = 3,
		[ [[Over the next hill, you see three frat boys abruptly vanish into a cloud of green smoke.]] ] = 3,
		[ [[You hear excited chittering overhead, and look up to see a squadron of winged ferrets]] ] = 3,

		[ [[Nearby, a War Hippy Elder Shaman nods almost imperceptibly.]] ] = 7,
		[ [[You leap out of the way of a runaway Mobile Sweat Lodge, then watch it run over]] ] = 7,
		[ [[A few yards away, one of the Jerry's Riggers hippies detonates a bomb underneath a Grill Sergeant's grill.]] ] = 7,
		[ [[You look over and see one of Jerry's Riggers placing land mines he made out of paperclips,]] ] = 7,

		[ [[You turn to see a nearby War Hippy Elder Shaman making a series of complex hand gestures.]] ] = 15,
		[ [[You see a platoon of charging frat boys get mowed down by a hippy.]] ] = 15,
		[ [[You look over and see a funk of hippies round up a bunch of frat boys to take as prisoners of war.]] ] = 15,
		[ [[Nearby, a platoon of frat boys is rocking a mobile sweat lodge back and forth, trying to tip it over.]] ] = 15,

		[ [[A mobile sweat lodge rumbles into a regiment of frat boys and the hippies inside open all of its vents simultaneously.]] ] = 31,
		[ [[You see a squadron of police cars drive up, and a squad of policemen arrest an entire regiment of frat boys.]] ] = 31,
		[ [[You see a regiment of frat boys decide they're tired of drinking non-alcoholic beer and tired of not hitting on chicks,]] ] = 31,

		[ [[You see an airborne commander trying out a new strategy: she mixes a tiny bottle of rum she found on one of the frat boy casualties]] ] = 63,
		[ [[You see a couple of hippies rigging a mobile sweat lodge with a public address system.]] ] = 63,
		[ [[You see an elder hippy shaman close her eyes, clench her fists, and start to chant.]] ] = 63,
	}

	if text:contains("<!--WINWINWIN-->") then
		if text:match([[<a href="adventure.php%?snarfblat=[0-9]+">Adventure Again %(The Battlefield %(Frat Uniform%)%)</a>]]) then
			amount = 1
			for msg, kills in pairs(frat_kills) do
				if text:contains(msg) then
					amount = amount + kills
				end
			end
			increase_battlefield_kill_counter("frat boy", amount)
			session["debug.just added frat kills"] = amount
		end
		if text:match([[<a href="adventure.php%?snarfblat=[0-9]+">Adventure Again %(The Battlefield %(Hippy Uniform%)%)</a>]]) then
			amount = 1
			for msg, kills in pairs(hippy_kills) do
				if text:contains(msg) then
					amount = amount + kills
				end
			end
			increase_battlefield_kill_counter("hippy", amount)
			session["debug.just added hippy kills"] = amount
		end
	end
end)

add_printer("/fight.php", function()
	if text:match([[<a href="adventure.php%?snarfblat=[0-9]+">Adventure Again %(The Battlefield %(Frat Uniform%)%)</a>]]) then
		killrange = ascension["battlefield.kills.frat boy"] or {}
		min_value = killrange.min or tonumber(ascension["battlefield.kills.frat boy.min"]) or 0
		max_value = killrange.max or tonumber(ascension["battlefield.kills.frat boy.max"]) or 0
		if min_value == max_value then
			printstr = min_value .. " hippies killed"
		else
			printstr = min_value .. "-" .. max_value .. " hippies killed"
		end
		text = text:gsub("You win the fight!<!%-%-WINWINWIN%-%->", "%0 <span style=\"color: green\">{ " .. printstr .. ". }</span>")
	end
	if text:match([[<a href="adventure.php%?snarfblat=[0-9]+">Adventure Again %(The Battlefield %(Hippy Uniform%)%)</a>]]) then
		killrange = ascension["battlefield.kills.hippy"] or {}
		min_value = killrange.min or tonumber(ascension["battlefield.kills.hippy.min"]) or 0
		max_value = killrange.max or tonumber(ascension["battlefield.kills.hippy.max"]) or 0
		if min_value == max_value then
			printstr = min_value .. " frat boys killed"
		else
			printstr = min_value .. "-" .. max_value .. " frat boys killed"
		end
		text = text:gsub("You win the fight!<!%-%-WINWINWIN%-%->", "%0 <span style=\"color: green\">{ " .. printstr .. ". }</span>")
	end
end)

add_itemdrop_counter("barrel of gunpowder", function(c)
	return "{ " .. c .. " of 5 found. }"
end)