add_automator("/basement.php", function()
	local basement_floor = text:match([[<tr><td style="color: white;" align=center bgcolor=blue.-><b>Fernswarthy's Basement, Level ([^<]*)</b></td></tr>]])
	local challenge_type = text:match([[<input class=button type=submit value="([^>]+) %(1%)">]])

	local challenge_summary
	local minreq
	local havereq
	local maxreq
	local reqtype = ""
	local minreqinfo = ""
	local maxreqinfo = ""
	local bad_estimate = false

	local function handle_resist_test(elem1title, elem2title)
		local elem1, elem2 = elem1title:lower(), elem2title:lower()
		local resists = get_resistance_levels()
		local basedmg = 8 + 4.5 * (basement_floor ^ 1.4)
		local mindmg = table_apply_function(estimate_damage { [elem1] = 0.95 * basedmg, [elem2] = 0.95 * basedmg, __resistance_levels = resists }, math.floor)
		local maxdmg = table_apply_function(estimate_damage { [elem1] = 1.05 * basedmg, [elem2] = 1.05 * basedmg, __resistance_levels = resists }, math.ceil)
		local minmarkup = markup_damagetext(mindmg)
		local maxmarkup = markup_damagetext(maxdmg)
		minreq = mindmg[elem1] + mindmg[elem2]
		havereq = hp()
		maxreq = maxdmg[elem1] + maxdmg[elem2]
		minreqinfo = string.format([[ (%s + %s)]], minmarkup[elem1], minmarkup[elem2])
		maxreqinfo = string.format([[ (%s + %s)]], maxmarkup[elem1], maxmarkup[elem2])
		reqtype = " damage"
		challenge_description = elem1title .. " + " .. elem2title .. " Resistance test"
	end

	if basement_floor % 5 == 0 then
		challenge_summary = ""
		text = text:gsub([[<br><form action=basement.php method=post><input type=hidden name=action value="2"><center><input class=button type=submit value="Save the Cardboard ([^<]*)"></form>]], [[ <span style="color: green">{ Mysticality reward. }</span><form action=basement.php method=post><input type=hidden name=action value="2"><center><input class=button type=submit value="Save the Cardboard (1)"></form> <span style="color: green">{ Moxie reward. }</span>]], 1)
		text = text:gsub([[<br><form action=basement.php method=post><input type=hidden name=action value="2"><center><input class=button type=submit value="Take the Blue Pill ([^<]*)"></form>]], [[ <span style="color: green">{ Muscle reward. }</span><form action=basement.php method=post><input type=hidden name=action value="2"><center><input class=button type=submit value="Take the Blue Pill (1)"></form> <span style="color: green">{ Mysticality reward. }</span>]], 1)
		text = text:gsub([[<br><form action=basement.php method=post><input type=hidden name=action value="2"><center><input class=button type=submit value="Leather is Betther ([^<]*)"></form>]], [[ <span style="color: green">{ Moxie reward. }</span><form action=basement.php method=post><input type=hidden name=action value="2"><center><input class=button type=submit value="Leather is Betther (1)"></form> <span style="color: green">{ Muscle reward. }</span>]], 1)
	elseif challenge_type == "Grab the Handles" then
		-- TODO: max here is too low! Added + 10 to max as a workaround
		minreq = math.ceil(1.5865 * (basement_floor ^ 1.4))
		havereq = mp()
		maxreq = math.ceil(10 + 1.7535 * (basement_floor ^ 1.4))
		challenge_description = "MP drain"
	elseif challenge_type == "Run the Gauntlet Gauntlet" then
		-- TODO: max here is too low! Added 0.95 and 1.05 modifiers as a workaround
		bad_estimate = true
		minreq = math.ceil(0.95 * basement_floor ^ 1.4)
		havereq = hp()
		maxreq = math.ceil(1.05 * 10 * (basement_floor ^ 1.4))
		reqtype = " damage"
		challenge_description = "HP drain (incomplete, wide range estimate)"
	elseif challenge_type == "Lift 'em!" or challenge_type == "Push it Real Good" or challenge_type == "Ring that Bell!" then
		minreq = math.ceil(0.9 * (basement_floor ^ 1.4) + 2)
		havereq = buffedmuscle()
		maxreq = math.ceil(1.1 * (basement_floor ^ 1.4) + 2)
		challenge_description = "Muscularity test"
	elseif challenge_type == "Gathering:  The Magic" or challenge_type == "Mop the Floor with the Mops" or challenge_type == "Do away with the 'doo" then
		minreq = math.ceil(0.9 * (basement_floor ^ 1.4) + 2)
		havereq = buffedmysticality()
		maxreq = math.ceil(1.1 * (basement_floor ^ 1.4) + 2)
		challenge_description = "Mysticality test"
	elseif challenge_type == "Don't Wake the Baby" or challenge_type == "Grab a cue" or challenge_type == "Put on the Smooth Moves" then
		minreq = math.ceil(0.9 * (basement_floor ^ 1.4) + 2)
		havereq = buffedmoxie()
		maxreq = math.ceil(1.1 * (basement_floor ^ 1.4) + 2)
		challenge_description = "Moxie test"
	elseif challenge_type == "Evade the Vampsicle" then
		handle_resist_test("Cold", "Spooky")
	elseif challenge_type == "What's a Typewriter, Again?" then
		handle_resist_test("Hot", "Spooky")
	elseif challenge_type == "Pwn the Cone" then
		handle_resist_test("Stench", "Hot")
	elseif challenge_type == "Drink the Drunk's Drink" then
		handle_resist_test("Cold", "Sleaze")
	elseif challenge_type == "Hold your nose and watch your back" then
		handle_resist_test("Stench", "Sleaze")
	elseif challenge_type == "Commence to Pokin'" or challenge_type == "Collapse That Waveform" or string.find(challenge_type, " Down") or challenge_type == "Don't Fear the Ear" or challenge_type == "It's Stone Bashin' Time" or challenge_type == "Toast that Ghost" or challenge_type == "Round " .. basement_floor .. "...  Fight!" then
		challenge_summary = "{ Combat. }"
	end
	if not challenge_summary then
		if havereq < minreq then
			text = text:gsub([[<input class=button type=submit]], [[%0 disabled="disabled"]], 1)
		end
		challenge_summary = string.format([[<div style="color: %s">{ %s }<br>Estimated%s:<br><span style="color: %s">Min: %s%s</span><br><span style="color: %s">Max: %s%s</span></div>]], bad_estimate and "darkorange" or "green", challenge_description, reqtype, (minreq <= havereq) and "green" or "darkorange", minreq, minreqinfo, (maxreq <= havereq) and "green" or "darkorange", maxreq, maxreqinfo)
	end
	if bad_estimate then
		text = text:gsub([[<br><p><a href="fernruin.php">]], [[<center><div style="color: darkorange">]] .. challenge_summary .. [[</div></center><p><a href="fernruin.php">]], 1)
	else
		text = text:gsub([[<br><p><a href="fernruin.php">]], [[<center><div style="color: green">]] .. challenge_summary .. [[</div></center><p><a href="fernruin.php">]], 1)
	end
end)

-- HACK
function basement_level()
	return 42
end
