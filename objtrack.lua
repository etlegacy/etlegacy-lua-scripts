-- objtrack.lua by x0rnn, tracks and announces who stole, returned or secured objectives
-- preconfigured maps only; support for additional maps needs to be added manually

mapname = ""
goldcarriers = {}
goldcarriers_id = {}
doccarriers = {}
doccarriers_id = {}
objcarriers = {}
objcarriers_id = {}
second_obj = false
firstflag = false
secondflag = false

function et_InitGame(levelTime, randomSeed, restart)
	et.RegisterModname("objtrack.lua "..et.FindSelf())

	mapname = string.lower(et.trap_Cvar_Get("mapname"))
end

function et_Print(text)
	if mapname == "radar" then
		if(string.find(text, "team_CTF_redflag")) then
			local i, j = string.find(text, "%d+")   
	        local id = tonumber(string.sub(text, i, j))
			local team = tonumber(et.gentity_get(id, "sess.sessionTeam"))
			local name = et.gentity_get(id, "pers.netname")
			if team == 2 then
				objcarriers[id] = true
				table.insert(objcarriers_id, id)
				if firstflag == true then
					et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7stole the West Radar Parts!\"\n")
				elseif secondflag == true then
					et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7stole the East Radar Parts!\"\n")
				else
					et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7stole a Radar Part!\"\n")
				end
			elseif team == 1 then
				if firstflag == true then
					et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7returned the West Radar Parts!\"\n")
				elseif secondflag == true then
					et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7returned the East Radar Parts!\"\n")
				else
					et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7returned a Radar Part!\"\n")
				end
			end
		end
		if(string.find(text, "Allies have secured the East")) then
			local x = 1
			for index in pairs(objcarriers_id) do
				if objcarriers[objcarriers_id[x]] == true then
					local redflag = et.gentity_get(objcarriers_id[x], "ps.powerups", 6)
					if redflag == 0 then
						local name = et.gentity_get(objcarriers_id[x], "pers.netname")
						et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7secured the East Radar Parts!\"\n")
						objcarriers[objcarriers_id[x]] = nil
						table.remove(objcarriers_id, x)
					end
				end
				x = x + 1
			end
			firstflag = true
		end
		if(string.find(text, "Allies have secured the West")) then
			local x = 1
			for index in pairs(objcarriers_id) do
				if objcarriers[objcarriers_id[x]] == true then
					local redflag = et.gentity_get(objcarriers_id[x], "ps.powerups", 6)
					if redflag == 0 then
						local name = et.gentity_get(objcarriers_id[x], "pers.netname")
						et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7secured the West Radar Parts!\"\n")
						objcarriers[objcarriers_id[x]] = nil
						table.remove(objcarriers_id, x)
					end
				end
				x = x + 1
			end
			secondflag = true
		end
	end -- end radar

	if mapname == "goldrush" or mapname == "uje_goldrush" then
		if(string.find(text, "team_CTF_redflag")) then
			local i, j = string.find(text, "%d+")   
	        local id = tonumber(string.sub(text, i, j))
			local team = tonumber(et.gentity_get(id, "sess.sessionTeam"))
			local name = et.gentity_get(id, "pers.netname")
			if team == 2 then
				goldcarriers[id] = true
				table.insert(goldcarriers_id, id)
				if #goldcarriers_id == 1 then
					if firstflag == false then
						et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7stole the first Gold Crate!\"\n")
					else
						et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7stole the second Gold Crate!\"\n") 
					end
				elseif #goldcarriers_id == 2 then
					et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7stole the second Gold Crate!\"\n")
				end
			elseif team == 1 then
				if firstflag == true then
					et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7returned the second Gold Crate!\"\n")
				else
					if #goldcarriers_id == 1 then
						et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7returned the second Gold Crate!\"\n")
					else
						et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7returned a Gold Crate!\"\n")
					end
				end
			end
		end
		if(string.find(text, "Allied team has secured the first Gold Crate")) then
			local x = 1
			for index in pairs(goldcarriers_id) do
				if goldcarriers[goldcarriers_id[x]] == true then
					local redflag = et.gentity_get(goldcarriers_id[x], "ps.powerups", 6)
					if redflag == 0 then
						local name = et.gentity_get(goldcarriers_id[x], "pers.netname")
						et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7secured the first Gold Crate!\"\n")
						goldcarriers[goldcarriers_id[x]] = nil
						table.remove(goldcarriers_id, x)
					end
				end
				x = x + 1
			end
			firstflag = true
		end
		if(string.find(text, "Allied team has secured the second Gold Crate")) then
			local name = et.gentity_get(goldcarriers_id[1], "pers.netname")
			et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7secured the second Gold Crate!\"\n")
			goldcarriers[goldcarriers_id[1]] = nil
			table.remove(goldcarriers_id, 1)
		end
	end -- end goldrush

	if (string.find(mapname, "frostbite")) then
		if(string.find(text, "team_CTF_redflag")) then
			local i, j = string.find(text, "%d+")   
	        local id = tonumber(string.sub(text, i, j))
			local team = tonumber(et.gentity_get(id, "sess.sessionTeam"))
			local name = et.gentity_get(id, "pers.netname")
			if team == 2 then
				doccarriers[id] = true
				table.insert(doccarriers_id, id)
				if second_obj == false then
					et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7stole the Supply Documents!\"\n")
				else
					et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7stole the Deciphered Supply Documents!\"\n")
				end
			elseif team == 1 then
				if second_obj == true then
					et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7returned the Deciphered Supply Documents!\"\n")
				else
					et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7returned the Supply Documents!\"\n")
				end
			end
		end
		if(string.find(text, "The Allies have transmitted the Supply")) then
			local name = et.gentity_get(doccarriers_id[1], "pers.netname")
			et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7secured the Supply Documents!\"\n")
			doccarriers[doccarriers_id[1]] = nil
			table.remove(doccarriers_id, 1)
			second_obj = true
		end
		if(string.find(text, "The Allies have transmitted the Deciphered")) then
			local name = et.gentity_get(doccarriers_id[1], "pers.netname")
			et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7secured the Deciphered Supply Documents!\"\n")
			doccarriers[doccarriers_id[1]] = nil
			table.remove(doccarriers_id, 1)
		end
	end -- end frostbite

	if (string.find(mapname, "missile")) then
		if(string.find(text, "team_CTF_redflag")) then
			local i, j = string.find(text, "%d+")   
	        local id = tonumber(string.sub(text, i, j))
			local team = tonumber(et.gentity_get(id, "sess.sessionTeam"))
			local name = et.gentity_get(id, "pers.netname")
			if team == 2 then
				objcarriers[id] = true
				table.insert(objcarriers_id, id)
				if second_obj == false then
					et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7stole the Gate Power Supply!\"\n")
				else
					et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7stole the Rocket Control!\"\n")
				end
			elseif team == 1 then
				if second_obj == true then
					et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7returned the Rocket Control!\"\n")
				else
					et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7returned the Gate Power Supply!\"\n")
				end
			end
		end
		if(string.find(text, "Allies have transported the Power")) then
			local name = et.gentity_get(objcarriers_id[1], "pers.netname")
			et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7secured the Gate Power Supply!\"\n")
			objcarriers[objcarriers_id[1]] = nil
			table.remove(objcarriers_id, 1)
			second_obj = true
		end
		if(string.find(text, "Allies have transported the Rocket")) then
			local name = et.gentity_get(objcarriers_id[1], "pers.netname")
			et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7secured the Rocket Control!\"\n")
			objcarriers[objcarriers_id[1]] = nil
			table.remove(objcarriers_id, 1)
		end
	end -- end missile_b3/b4

	if (string.find(mapname, "sp_delivery")) then
		if(string.find(text, "team_CTF_redflag")) then
			local i, j = string.find(text, "%d+")   
	        local id = tonumber(string.sub(text, i, j))
			local team = tonumber(et.gentity_get(id, "sess.sessionTeam"))
			local name = et.gentity_get(id, "pers.netname")
			if team == 2 then
				goldcarriers[id] = true
				table.insert(goldcarriers_id, id)
				et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7stole a Gold Crate!\"\n")
			elseif team == 1 then
				et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7returned a Gold Crate!\"\n")
			end
		end
		if(string.find(text, "The Allies have secured a gold crate")) then
			local x = 1
			for index in pairs(goldcarriers_id) do
				if goldcarriers[goldcarriers_id[x]] == true then
					local redflag = et.gentity_get(goldcarriers_id[x], "ps.powerups", 6)
					if redflag == 0 then
						local name = et.gentity_get(goldcarriers_id[x], "pers.netname")
						et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7secured a Gold Crate!\"\n")
						goldcarriers[goldcarriers_id[x]] = nil
						table.remove(goldcarriers_id, x)
					end
				end
				x = x + 1
			end
		end
	end -- end sp_delivery_te/etl_sp_delivery

	if mapname == "sw_goldrush_te" then
		if(string.find(text, "team_CTF_redflag")) then
			local i, j = string.find(text, "%d+")   
	        local id = tonumber(string.sub(text, i, j))
			local team = tonumber(et.gentity_get(id, "sess.sessionTeam"))
			local name = et.gentity_get(id, "pers.netname")
			if team == 2 then
				goldcarriers[id] = true
				table.insert(goldcarriers_id, id)
				et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7stole the Gold Bars!\"\n")
			elseif team == 1 then
				et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7returned the Gold Bars!\"\n")
			end
		end
		if(string.find(text, "Allied team is escaping with the Gold")) then
			local name = et.gentity_get(goldcarriers_id[1], "pers.netname")
			et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7secured the Gold Bars!\"\n")
			goldcarriers[goldcarriers_id[1]] = nil
			table.remove(goldcarriers_id, 1)
		end
	end -- end sw_goldrush_te

	if mapname == "bremen_b3" then
		if(string.find(text, "team_CTF_redflag")) then
			local i, j = string.find(text, "%d+")   
	        local id = tonumber(string.sub(text, i, j))
			local team = tonumber(et.gentity_get(id, "sess.sessionTeam"))
			local name = et.gentity_get(id, "pers.netname")
			if team == 2 then
				objcarriers[id] = true
				table.insert(objcarriers_id, id)
				et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7stole the Keycard!\"\n")
			elseif team == 1 then
				et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7returned the Keycard!\"\n")
			end
		end
		if(string.find(text, "The Allies have captured the keycard")) then
			local name = et.gentity_get(objcarriers_id[1], "pers.netname")
			et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7secured the Keycard!\"\n")
			objcarriers[objcarriers_id[1]] = nil
			table.remove(objcarriers_id, 1)
		end
	end -- end bremen_b3

	if (string.find(mapname, "adlernest")) then
		if(string.find(text, "team_CTF_redflag")) then
			local i, j = string.find(text, "%d+")   
	        local id = tonumber(string.sub(text, i, j))
			local team = tonumber(et.gentity_get(id, "sess.sessionTeam"))
			local name = et.gentity_get(id, "pers.netname")
			if team == 2 then
				doccarriers[id] = true
				table.insert(doccarriers_id, id)
				et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7stole the Documents!\"\n")
			elseif team == 1 then
				et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7returned the Documents!\"\n")
			end
		end
		if(string.find(text, "Allied team has transmitted the documents")) then
			local name = et.gentity_get(doccarriers_id[1], "pers.netname")
			et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7secured the Documents!\"\n")
			doccarriers[doccarriers_id[1]] = nil
			table.remove(doccarriers_id, 1)
		end
	end -- end adlernest

	if mapname == "et_beach" then
		if(string.find(text, "team_CTF_redflag")) then
			local i, j = string.find(text, "%d+")   
	        local id = tonumber(string.sub(text, i, j))
			local team = tonumber(et.gentity_get(id, "sess.sessionTeam"))
			local name = et.gentity_get(id, "pers.netname")
			if team == 2 then
				doccarriers[id] = true
				table.insert(doccarriers_id, id)
				et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7stole the War Documents!\"\n")
			elseif team == 1 then
				et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7returned the War Documents!\"\n")
			end
		end
		if(string.find(text, "Allied team transmit the War Documents")) then
			local name = et.gentity_get(doccarriers_id[1], "pers.netname")
			et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7secured the War Documents!\"\n")
			doccarriers[doccarriers_id[1]] = nil
			table.remove(doccarriers_id, 1)
		end
	end -- end et_beach

	if mapname == "venice" then
		if(string.find(text, "team_CTF_redflag")) then
			local i, j = string.find(text, "%d+")   
	        local id = tonumber(string.sub(text, i, j))
			local team = tonumber(et.gentity_get(id, "sess.sessionTeam"))
			local name = et.gentity_get(id, "pers.netname")
			if team == 2 then
				objcarriers[id] = true
				table.insert(objcarriers_id, id)
				et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7stole the Relic!\"\n")
			elseif team == 1 then
				et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7returned the Relic!\"\n")
			end
		end
		if(string.find(text, "Allied team has secured the Relic")) then
			local name = et.gentity_get(objcarriers_id[1], "pers.netname")
			et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7secured the Relic!\"\n")
			objcarriers[objcarriers_id[1]] = nil
			table.remove(objcarriers_id, 1)
		end
	end -- end venice

	if mapname == "library_b3" then
		if(string.find(text, "team_CTF_redflag")) then
			local i, j = string.find(text, "%d+")   
	        local id = tonumber(string.sub(text, i, j))
			local team = tonumber(et.gentity_get(id, "sess.sessionTeam"))
			local name = et.gentity_get(id, "pers.netname")
			if team == 2 then
				doccarriers[id] = true
				table.insert(doccarriers_id, id)
				et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7stole the Secret Documents!\"\n")
			elseif team == 1 then
				et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7returned the Secret Documents!\"\n")
			end
		end
		if(string.find(text, "The Allies have sent the secret docs")) then
			local name = et.gentity_get(doccarriers_id[1], "pers.netname")
			et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7secured the Secret Documents!\"\n")
			doccarriers[doccarriers_id[1]] = nil
			table.remove(doccarriers_id, 1)
		end
	end -- end library_b3

	if mapname == "pirates" then
		if(string.find(text, "team_CTF_redflag")) then
			local i, j = string.find(text, "%d+")   
	        local id = tonumber(string.sub(text, i, j))
			local team = tonumber(et.gentity_get(id, "sess.sessionTeam"))
			local name = et.gentity_get(id, "pers.netname")
			if team == 2 then
				goldcarriers[id] = true
				table.insert(goldcarriers_id, id)
				if #goldcarriers_id == 1 then
					if firstflag == false then
						et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7stole the first Gold Crate!\"\n")
					else
						et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7stole the second Gold Crate!\"\n") 
					end
				elseif #goldcarriers_id == 2 then
					et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7stole the second Gold Crate!\"\n")
				end
			elseif team == 1 then
				if firstflag == true then
					et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7returned the second Gold Crate!\"\n")
				else
					if #goldcarriers_id == 1 then
						et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7returned the second Gold Crate!\"\n")
					else
						et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7returned a Gold Crate!\"\n")
					end
				end
			end
		end
		if(string.find(text, "Allied team has secured the first Gold Crate")) then
			local x = 1
			for index in pairs(goldcarriers_id) do
				if goldcarriers[goldcarriers_id[x]] == true then
					local redflag = et.gentity_get(goldcarriers_id[x], "ps.powerups", 6)
					if redflag == 0 then
						local name = et.gentity_get(goldcarriers_id[x], "pers.netname")
						et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7secured the first Gold Crate!\"\n")
						goldcarriers[goldcarriers_id[x]] = nil
						table.remove(goldcarriers_id, x)
					end
				end
				x = x + 1
			end
			firstflag = true
		end
		if(string.find(text, "Allied team has secured the second Gold Crate")) then
			local name = et.gentity_get(goldcarriers_id[1], "pers.netname")
			et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7secured the second Gold Crate!\"\n")
			goldcarriers[goldcarriers_id[1]] = nil
			table.remove(goldcarriers_id, 1)
		end
	end -- end pirates

	if mapname == "karsiah_te2" then
		if(string.find(text, "team_CTF_redflag")) then
			local i, j = string.find(text, "%d+")   
	        local id = tonumber(string.sub(text, i, j))
			local team = tonumber(et.gentity_get(id, "sess.sessionTeam"))
			local name = et.gentity_get(id, "pers.netname")
			if team == 2 then
				objcarriers[id] = true
				table.insert(objcarriers_id, id)
				if firstflag == true then
					et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7stole the South Documents!\"\n")
				elseif secondflag == true then
					et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7stole the North Documents!\"\n")
				else
					et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7stole a stack of Documents!\"\n")
				end
			elseif team == 1 then
				if firstflag == true then
					et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7returned the South Documents!\"\n")
				elseif secondflag == true then
					et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7returned the North Documents!\"\n")
				else
					et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7returned a stack of Documents\"\n")
				end
			end
		end
		if(string.find(text, "Allies have transmitted the North Documents")) then
			local x = 1
			for index in pairs(objcarriers_id) do
				if objcarriers[objcarriers_id[x]] == true then
					local redflag = et.gentity_get(objcarriers_id[x], "ps.powerups", 6)
					if redflag == 0 then
						local name = et.gentity_get(objcarriers_id[x], "pers.netname")
						et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7secured the North Documents!\"\n")
						objcarriers[objcarriers_id[x]] = nil
						table.remove(objcarriers_id, x)
					end
				end
				x = x + 1
			end
			firstflag = true
		end
		if(string.find(text, "Allies have transmitted the South Documents")) then
			local x = 1
			for index in pairs(objcarriers_id) do
				if objcarriers[objcarriers_id[x]] == true then
					local redflag = et.gentity_get(objcarriers_id[x], "ps.powerups", 6)
					if redflag == 0 then
						local name = et.gentity_get(objcarriers_id[x], "pers.netname")
						et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7secured the South Documents!\"\n")
						objcarriers[objcarriers_id[x]] = nil
						table.remove(objcarriers_id, x)
					end
				end
				x = x + 1
			end
			secondflag = true
		end
	end -- end karsiah_te2

	if mapname == "et_ufo_final" then
		if(string.find(text, "team_CTF_redflag")) then
			local i, j = string.find(text, "%d+")   
	        local id = tonumber(string.sub(text, i, j))
			local team = tonumber(et.gentity_get(id, "sess.sessionTeam"))
			local name = et.gentity_get(id, "pers.netname")
			if team == 2 then
				doccarriers[id] = true
				table.insert(doccarriers_id, id)
				et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7stole the UFO Documents!\"\n")
			elseif team == 1 then
				et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7returned the UFO Documents!\"\n")
			end
		end
		if(string.find(text, "Allies Transmitted the UFO Documents")) then
			local name = et.gentity_get(doccarriers_id[1], "pers.netname")
			et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7secured the UFO Documents!\"\n")
			doccarriers[doccarriers_id[1]] = nil
			table.remove(doccarriers_id, 1)
		end
	end -- end et_ufo_final

	if mapname == "sos_secret_weapon" then
		if(string.find(text, "team_CTF_redflag")) then
			local i, j = string.find(text, "%d+")   
	        local id = tonumber(string.sub(text, i, j))
			local team = tonumber(et.gentity_get(id, "sess.sessionTeam"))
			local name = et.gentity_get(id, "pers.netname")
			if team == 2 then
				objcarriers[id] = true
				table.insert(objcarriers_id, id)
				et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7stole the Secret Weapon!\"\n")
			elseif team == 1 then
				et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7returned the Secret Weapon!\"\n")
			end
		end
		if(string.find(text, "Allied team has secured the secret weapon")) then
			local name = et.gentity_get(objcarriers_id[1], "pers.netname")
			et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7secured the Secret Weapon!\"\n")
			objcarriers[objcarriers_id[1]] = nil
			table.remove(objcarriers_id, 1)
		end
	end -- end sos_secret_weapon

	if mapname == "falkenstein_b3" then
		if(string.find(text, "team_CTF_redflag")) then
			local i, j = string.find(text, "%d+")   
	        local id = tonumber(string.sub(text, i, j))
			local team = tonumber(et.gentity_get(id, "sess.sessionTeam"))
			local name = et.gentity_get(id, "pers.netname")
			if team == 2 then
				objcarriers[id] = true
				table.insert(objcarriers_id, id)
				et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7stole the Prototype!\"\n")
			elseif team == 1 then
				et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7returned the Prototype!\"\n")
			end
		end
		if(string.find(text, "ALLIES ESCAPED WITH THE OBJECTIVE")) then
			local name = et.gentity_get(objcarriers_id[1], "pers.netname")
			et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7secured the Prototype!\"\n")
			objcarriers[objcarriers_id[1]] = nil
			table.remove(objcarriers_id, 1)
		end
	end -- end falkenstein_b3

	if (string.find(mapname, "decay")) then
		if(string.find(text, "team_CTF_redflag")) then
			local i, j = string.find(text, "%d+")   
	        local id = tonumber(string.sub(text, i, j))
			local team = tonumber(et.gentity_get(id, "sess.sessionTeam"))
			local name = et.gentity_get(id, "pers.netname")
			if team == 2 then
				objcarriers[id] = true
				table.insert(objcarriers_id, id)
				if second_obj == false then
					et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7stole the Access Codes!\"\n")
				else
					if firstflag == false then
						et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7stole the first Gold Crate!\"\n")
					else
						et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7stole the second Gold Crate!\"\n")
					end
				end
			elseif team == 1 then
				if second_obj == false then
					et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7returned the Access Codes!\"\n")
				else
					if firstflag == false then
						et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7returned the first Gold Crate!\"\n")
					else
						et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7returned the second Gold Crate!\"\n")
					end
				end
			end
		end
		if(string.find(text, "The Allies have transmitted the Access codes")) then
			local name = et.gentity_get(objcarriers_id[1], "pers.netname")
			et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7secured the Access Codes!\"\n")
			objcarriers[objcarriers_id[1]] = nil
			table.remove(objcarriers_id, 1)
			second_obj = true
		end
		if(string.find(text, "The Allies have secured a gold crate!")) then
			if firstflag == false then
				local name = et.gentity_get(objcarriers_id[1], "pers.netname")
				et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7secured the first Gold Crate!\"\n")
				objcarriers[objcarriers_id[1]] = nil
				table.remove(objcarriers_id, 1)
				firstflag = true
			elseif firstflag == true then
				local name = et.gentity_get(objcarriers_id[1], "pers.netname")
				et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7secured the second Gold Crate!\"\n")
				objcarriers[objcarriers_id[1]] = nil
				table.remove(objcarriers_id, 1)
			end
		end
	end --end decay_b7/decay_sw

	-- decay_b7 alternate script
	--if mapname == "decay_b7" then
		--if(string.find(text, "team_CTF_redflag")) then
			--local i, j = string.find(text, "%d+")   
	        --local id = tonumber(string.sub(text, i, j))
			--local team = tonumber(et.gentity_get(id, "sess.sessionTeam"))
			--local name = et.gentity_get(id, "pers.netname")
			--if team == 2 then
				--objcarriers[id] = true
				--table.insert(objcarriers_id, id)
				--if second_obj == false then
					--et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7stole the Access Codes!\"\n")
				--else
					--if #objcarriers_id == 1 then
						--if firstflag == false then
							--et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7stole the first Gold Crate!\"\n")
						--else
							--et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7stole the second Gold Crate!\"\n") 
						--end
					--elseif #objcarriers_id == 2 then
						--et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7stole the second Gold Crate!\"\n")
					--end
				--end
			--elseif team == 1 then
				--if second_obj == false then
					--et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7returned the Access Codes!\"\n")
				--else
					--if firstflag == true then
						--et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7returned the second Gold Crate!\"\n")
					--else
						--if #objcarriers_id == 1 then
							--et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7returned the second Gold Crate!\"\n")
						--else
							--et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7returned a Gold Crate!\"\n")
						--end
					--end
				--end
			--end
		--end
		--if(string.find(text, "The Allies have transmitted the Access codes")) then
			--local name = et.gentity_get(objcarriers_id[1], "pers.netname")
			--et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7secured the Access Codes!\"\n")
			--objcarriers[objcarriers_id[1]] = nil
			--table.remove(objcarriers_id, 1)
			--second_obj = true
		--end
		--if(string.find(text, "The Allies have secured a gold crate!")) then
			--if firstflag == false then
				--local x = 1
				--for index in pairs(objcarriers_id) do
					--if objcarriers[objcarriers_id[x]] == true then
						--local redflag = et.gentity_get(objcarriers_id[x], "ps.powerups", 6)
						--if redflag == 0 then
							--local name = et.gentity_get(objcarriers_id[x], "pers.netname")
							--et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7secured the first Gold Crate!\"\n")
							--objcarriers[objcarriers_id[x]] = nil
							--table.remove(objcarriers_id, x)
						--end
					--end
					--x = x + 1
				--end
				--firstflag = true
			--elseif firstflag == true then
				--local name = et.gentity_get(objcarriers_id[1], "pers.netname")
				--et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7secured the second Gold Crate!\"\n")
				--objcarriers[objcarriers_id[1]] = nil
				--table.remove(objcarriers_id, 1)
			--end
		--end
	--end -- end decay_b7 alternate script

	if mapname == "te_escape2" then
		if(string.find(text, "team_CTF_redflag")) then
			local i, j = string.find(text, "%d+")   
	        local id = tonumber(string.sub(text, i, j))
			local team = tonumber(et.gentity_get(id, "sess.sessionTeam"))
			local name = et.gentity_get(id, "pers.netname")
			if team == 2 then
				objcarriers[id] = true
				table.insert(objcarriers_id, id)
				et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7stole the ^1Unholy Grail^7!\"\n")
			elseif team == 1 then
				et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7returned the ^1Unholy Grail^7!\"\n")
			end
		end
		if(string.find(text, "The Allied team escaped with the Unholy Grail")) then
			local name = et.gentity_get(objcarriers_id[1], "pers.netname")
			et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7secured the ^1Unholy Grail^7!\"\n")
			objcarriers[objcarriers_id[1]] = nil
			table.remove(objcarriers_id, 1)
		end
	end -- end te_escape2

	if mapname == "radar_phx_b_3" or (string.find(mapname, "radar_truck")) then
		if(string.find(text, "team_CTF_redflag")) then
			local i, j = string.find(text, "%d+")   
	        local id = tonumber(string.sub(text, i, j))
			local team = tonumber(et.gentity_get(id, "sess.sessionTeam"))
			local name = et.gentity_get(id, "pers.netname")
			if team == 2 then
				doccarriers[id] = true
				table.insert(doccarriers_id, id)
				et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7stole the Axis Documents!\"\n")
			elseif team == 1 then
				et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7returned the Axis Documents!\"\n")
			end
		end
		if(string.find(text, "Allies have secured the Documents")) then
			local name = et.gentity_get(doccarriers_id[1], "pers.netname")
			et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7secured the Axis Documents!\"\n")
			doccarriers[doccarriers_id[1]] = nil
			table.remove(doccarriers_id, 1)
		end
	end -- end radar_phx_b_3

	if mapname == "et_village" then
		if(string.find(text, "team_CTF_redflag")) then
			local i, j = string.find(text, "%d+")   
	        local id = tonumber(string.sub(text, i, j))
			local team = tonumber(et.gentity_get(id, "sess.sessionTeam"))
			local name = et.gentity_get(id, "pers.netname")
			if team == 2 then
				goldcarriers[id] = true
				table.insert(goldcarriers_id, id)
				et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7stole the Gold!\"\n")
			elseif team == 1 then
				et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7returned the Gold!\"\n")
			end
		end
		if(string.find(text, "Allied team has escaped with the gold!")) then
			local name = et.gentity_get(goldcarriers_id[1], "pers.netname")
			et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7secured the Gold!\"\n")
			goldcarriers[goldcarriers_id[1]] = nil
			table.remove(goldcarriers_id, 1)
		end
	end -- end et_village

	if mapname == "1944_beach" then
		if(string.find(text, "team_CTF_redflag")) then
			local i, j = string.find(text, "%d+")   
	        local id = tonumber(string.sub(text, i, j))
			local team = tonumber(et.gentity_get(id, "sess.sessionTeam"))
			local name = et.gentity_get(id, "pers.netname")
			if team == 2 then
				doccarriers[id] = true
				table.insert(doccarriers_id, id)
				et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7stole the Axis Documents!\"\n")
			elseif team == 1 then
				et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7returned the Axis Documents!\"\n")
			end
		end
		if(string.find(text, "Allies have transmitted the documents")) then
			local name = et.gentity_get(doccarriers_id[1], "pers.netname")
			et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7secured the Axis Documents!\"\n")
			doccarriers[doccarriers_id[1]] = nil
			table.remove(doccarriers_id, 1)
		end
	end -- end 1944_beach

	if mapname == "et_brewdog" then
		if(string.find(text, "team_CTF_redflag")) then
			local i, j = string.find(text, "%d+")   
	        local id = tonumber(string.sub(text, i, j))
			local team = tonumber(et.gentity_get(id, "sess.sessionTeam"))
			local name = et.gentity_get(id, "pers.netname")
			if team == 2 then
				doccarriers[id] = true
				table.insert(doccarriers_id, id)
				et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7stole the Quiz Answers!\"\n")
			elseif team == 1 then
				et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7returned the Quiz Answers!\"\n")
			end
		end
		if(string.find(text, "Allies have transmitted the Quiz Answers!")) then
			local name = et.gentity_get(doccarriers_id[1], "pers.netname")
			et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7secured the Quiz Answers!\"\n")
			doccarriers[doccarriers_id[1]] = nil
			table.remove(doccarriers_id, 1)
		end
	end -- end et_brewdog

	if (string.find(mapname, "_ice")) then
		if(string.find(text, "team_CTF_blueflag")) then
			local i, j = string.find(text, "%d+")   
	        local id = tonumber(string.sub(text, i, j))
			local team = tonumber(et.gentity_get(id, "sess.sessionTeam"))
			local name = et.gentity_get(id, "pers.netname")
			if team == 1 then
				doccarriers[id] = true
				table.insert(doccarriers_id, id)
				et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7stole the Secret War Documents!\"\n")
			elseif team == 2 then
				et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7returned the Secret War Documents!\"\n")
			end
		end
		if(string.find(text, "The Axis team has transmited the Secret")) then
			local name = et.gentity_get(doccarriers_id[1], "pers.netname")
			et.trap_SendServerCommand(-1, "chat \"" .. name .. " ^7secured the Secret War Documents!\"\n")
			doccarriers[doccarriers_id[1]] = nil
			table.remove(doccarriers_id, 1)
		end
	end -- end et_ice
end

function et_Obituary(victim, killer, mod)
	if mapname == "radar" then
		objcarriers[victim] = nil
		local x = 1
		for index in pairs(objcarriers_id) do
			if objcarriers_id[x] == victim then
				table.remove(objcarriers_id, x)
			end
			x = x + 1
		end
	end
	if mapname == "goldrush" or mapname == "uje_goldrush" then
		goldcarriers[victim] = nil
		local x = 1
		for index in pairs(goldcarriers_id) do
			if goldcarriers_id[x] == victim then
				table.remove(goldcarriers_id, x)
			end
			x = x + 1
		end
	end
	if (string.find(mapname, "frostbite")) then
		doccarriers[victim] = nil
		if doccarriers_id[1] == victim then
			table.remove(doccarriers_id, 1)
		end
	end
	if (string.find(mapname, "missile")) then
		objcarriers[victim] = nil
		if objcarriers_id[1] == victim then
			table.remove(objcarriers_id, 1)
		end
	end
	if (string.find(mapname, "sp_delivery")) then
		goldcarriers[victim] = nil
		local x = 1
		for index in pairs(goldcarriers_id) do
			if goldcarriers_id[x] == victim then
				table.remove(goldcarriers_id, x)
			end
			x = x + 1
		end
	end
	if mapname == "sw_goldrush_te" then
		goldcarriers[victim] = nil
		if goldcarriers_id[1] == victim then
			table.remove(goldcarriers_id, 1)
		end
	end
	if mapname == "bremen_b3" then
		objcarriers[victim] = nil
		if objcarriers_id[1] == victim then
			table.remove(objcarriers_id, 1)
		end
	end
	if (string.find(mapname, "adlernest")) then
		doccarriers[victim] = nil
		if doccarriers_id[1] == victim then
			table.remove(doccarriers_id, 1)
		end
	end
	if mapname == "et_beach" then
		doccarriers[victim] = nil
		if doccarriers_id[1] == victim then
			table.remove(doccarriers_id, 1)
		end
	end
	if mapname == "venice" then
		objcarriers[victim] = nil
		if objcarriers_id[1] == victim then
			table.remove(objcarriers_id, 1)
		end
	end
	if mapname == "library_b3" then
		doccarriers[victim] = nil
		if doccarriers_id[1] == victim then
			table.remove(doccarriers_id, 1)
		end
	end
	if mapname == "pirates" then
		goldcarriers[victim] = nil
		local x = 1
		for index in pairs(goldcarriers_id) do
			if goldcarriers_id[x] == victim then
				table.remove(goldcarriers_id, x)
			end
			x = x + 1
		end
	end
	if mapname == "karsiah_te2" then
		objcarriers[victim] = nil
		local x = 1
		for index in pairs(objcarriers_id) do
			if objcarriers_id[x] == victim then
				table.remove(objcarriers_id, x)
			end
			x = x + 1
		end
	end
	if mapname == "et_ufo_final" then
		doccarriers[victim] = nil
		if doccarriers_id[1] == victim then
			table.remove(doccarriers_id, 1)
		end
	end
	if mapname == "sos_secret_weapon" then
		objcarriers[victim] = nil
		if objcarriers_id[1] == victim then
			table.remove(objcarriers_id, 1)
		end
	end
	if mapname == "falkenstein_b3" then
		objcarriers[victim] = nil
		if objcarriers_id[1] == victim then
			table.remove(objcarriers_id, 1)
		end
	end
	if (string.find(mapname, "decay")) then
		objcarriers[victim] = nil
		if objcarriers_id[1] == victim then
			table.remove(objcarriers_id, 1)
		end
	end

	--decay_b7 alternate script
	--if mapname == "decay_b7" then
		--objcarriers[victim] = nil
		--local x = 1
		--for index in pairs(objcarriers_id) do
			--if objcarriers_id[x] == victim then
				--table.remove(objcarriers_id, x)
			--end
			--x = x + 1
		--end
	--end

	if mapname == "te_escape2" then
		objcarriers[victim] = nil
		if objcarriers_id[1] == victim then
			table.remove(objcarriers_id, 1)
		end
	end
	if mapname == "radar_phx_b_3" or (string.find(mapname, "radar_truck")) then
		doccarriers[victim] = nil
		if doccarriers_id[1] == victim then
			table.remove(doccarriers_id, 1)
		end
	end
	if mapname == "et_village" then
		goldcarriers[victim] = nil
		if goldcarriers_id[1] == victim then
			table.remove(goldcarriers_id, 1)
		end
	end
	if (string.find(mapname, "_ice")) then
		doccarriers[victim] = nil
		if doccarriers_id[1] == victim then
			table.remove(doccarriers_id, 1)
		end
	end
	if mapname == "1944_beach" then
		doccarriers[victim] = nil
		if doccarriers_id[1] == victim then
			table.remove(doccarriers_id, 1)
		end
	end
	if mapname == "et_brewdog" then
		doccarriers[victim] = nil
		if doccarriers_id[1] == victim then
			table.remove(doccarriers_id, 1)
		end
	end
end

function et_ClientDisconnect(i)
	if mapname == "radar" then
		objcarriers[i] = nil
		local x = 1
		for index in pairs(objcarriers_id) do
			if objcarriers_id[x] == i then
				table.remove(objcarriers_id, x)
			end
			x = x + 1
		end
	end
	if mapname == "goldrush" or mapname == "uje_goldrush" then
		goldcarriers[i] = nil
		local x = 1
		for index in pairs(goldcarriers_id) do
			if goldcarriers_id[x] == i then
				table.remove(goldcarriers_id, x)
			end
			x = x + 1
		end
	end
	if (string.find(mapname, "frostbite")) then
		doccarriers[i] = nil
		if doccarriers_id[1] == i then
			table.remove(doccarriers_id, 1)
		end
	end
	if (string.find(mapname, "missile")) then
		objcarriers[i] = nil
		if objcarriers_id[1] == i then
			table.remove(objcarriers_id, 1)
		end
	end
	if (string.find(mapname, "sp_delivery")) then
		goldcarriers[i] = nil
		local x = 1
		for index in pairs(goldcarriers_id) do
			if goldcarriers_id[x] == i then
				table.remove(goldcarriers_id, x)
			end
			x = x + 1
		end
	end
	if mapname == "sw_goldrush_te" then
		goldcarriers[i] = nil
		if goldcarriers_id[1] == i then
			table.remove(goldcarriers_id, 1)
		end
	end
	if mapname == "bremen_b3" then
		objcarriers[i] = nil
		if objcarriers_id[1] == i then
			table.remove(objcarriers_id, 1)
		end
	end
	if (string.find(mapname, "adlernest")) then
		doccarriers[i] = nil
		if doccarriers_id[1] == i then
			table.remove(doccarriers_id, 1)
		end
	end
	if mapname == "et_beach" then
		doccarriers[i] = nil
		if doccarriers_id[1] == i then
			table.remove(doccarriers_id, 1)
		end
	end
	if mapname == "venice" then
		objcarriers[i] = nil
		if objcarriers_id[1] == i then
			table.remove(objcarriers_id, 1)
		end
	end
	if mapname == "library_b3" then
		doccarriers[i] = nil
		if doccarriers_id[1] == i then
			table.remove(doccarriers_id, 1)
		end
	end
	if mapname == "pirates" then
		goldcarriers[i] = nil
		local x = 1
		for index in pairs(goldcarriers_id) do
			if goldcarriers_id[x] == i then
				table.remove(goldcarriers_id, x)
			end
			x = x + 1
		end
	end
	if mapname == "karsiah_te2" then
		objcarriers[i] = nil
		local x = 1
		for index in pairs(objcarriers_id) do
			if objcarriers_id[x] == i then
				table.remove(objcarriers_id, x)
			end
			x = x + 1
		end
	end
	if mapname == "et_ufo_final" then
		doccarriers[i] = nil
		if doccarriers_id[1] == i then
			table.remove(doccarriers_id, 1)
		end
	end
	if mapname == "sos_secret_weapon" then
		objcarriers[i] = nil
		if objcarriers_id[1] == i then
			table.remove(objcarriers_id, 1)
		end
	end
	if mapname == "falkenstein_b3" then
		objcarriers[i] = nil
		if objcarriers_id[1] == i then
			table.remove(objcarriers_id, 1)
		end
	end
	if (string.find(mapname, "decay")) then
		objcarriers[i] = nil
		if objcarriers_id[1] == i then
			table.remove(objcarriers_id, 1)
		end
	end

	-- decay_b7 alternate script
	--if mapname == "decay_b7" then
		--objcarriers[i] = nil
		--local x = 1
		--for index in pairs(objcarriers_id) do
			--if objcarriers_id[x] == i then
				--table.remove(objcarriers_id, x)
			--end
			--x = x + 1
		--end
	--end

	if mapname == "te_escape2" then
		objcarriers[i] = nil
		if objcarriers_id[1] == i then
			table.remove(objcarriers_id, 1)
		end
	end
	if mapname == "radar_phx_b_3" or (string.find(mapname, "radar_truck")) then
		doccarriers[i] = nil
		if doccarriers_id[1] == i then
			table.remove(doccarriers_id, 1)
		end
	end
	if mapname == "et_village" then
		goldcarriers[i] = nil
		if goldcarriers_id[1] == i then
			table.remove(goldcarriers_id, 1)
		end
	end
	if (string.find(mapname, "_ice")) then
		doccarriers[i] = nil
		if doccarriers_id[1] == i then
			table.remove(doccarriers_id, 1)
		end
	end
	if mapname == "1944_beach" then
		doccarriers[i] = nil
		if doccarriers_id[1] == i then
			table.remove(doccarriers_id, 1)
		end
	end
	if mapname == "et_brewdog" then
		doccarriers[i] = nil
		if doccarriers_id[1] == i then
			table.remove(doccarriers_id, 1)
		end
	end
end
