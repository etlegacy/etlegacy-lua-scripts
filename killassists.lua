-- killassists.lua by x0rnn, shows kill assist information upon death (who all shot you, how much HP they took and how many HS they made)

hp_announce = true -- announce HP and distance of killer upon dying
hitters = {}
assists = {}
killsteals = {}
assist_weapons = {1,2,3,6,7,8,9,10,11,12,13,14,17,37,38,44,45,46,50,51,53,54,55,56,62,66}
HR_HEAD = 0
HR_ARMS = 1
HR_BODY = 2
HR_LEGS = 3
HR_NONE = -1
HR_TYPES = {HR_HEAD, HR_ARMS, HR_BODY, HR_LEGS}
hitRegionsData = {}

function has_value (tab, val)
	for index, value in ipairs(tab) do
		if value == val then
			return true
		end
	end
	return false
end

function et_InitGame(levelTime, randomSeed, restart)
	et.RegisterModname("killassists.lua "..et.FindSelf())
	sv_maxclients = tonumber(et.trap_Cvar_Get("sv_maxclients"))
	local j = 0
	for j=0,sv_maxclients-1 do
		hitters[j] = {nil, nil, nil, nil}
		assists[j] = 0
		killsteals[j] = 0
	end
end

function getAllHitRegions(clientNum)
	local regions = {}
	for index, hitType in ipairs(HR_TYPES) do
		regions[hitType] = et.gentity_get(clientNum, "pers.playerStats.hitRegions", hitType)
	end       
	return regions
end     

function hitType(clientNum)
	local playerHitRegions = getAllHitRegions(clientNum)
	if hitRegionsData[clientNum] == nil then
		hitRegionsData[clientNum] = playerHitRegions
		return 2
	end
	for index, hitType in ipairs(HR_TYPES) do
		if playerHitRegions[hitType] > hitRegionsData[clientNum][hitType] then
			hitRegionsData[clientNum] = playerHitRegions
			return hitType
		end		
	end
	hitRegionsData[clientNum] = playerHitRegions
	return -1
end

function et_Damage(target, attacker, damage, damageFlags, meansOfDeath)
	if target ~= attacker and attacker ~= 1022 and attacker ~= 1023 then
		if has_value(assist_weapons, meansOfDeath) then
			local hitType = hitType(attacker)
			if hitType == HR_HEAD then
				hitters[target][et.trap_Milliseconds()] = {[1]=attacker, [2]=damage, [3]=1}
			else
				hitters[target][et.trap_Milliseconds()] = {[1]=attacker, [2]=damage, [3]=0}
			end
		end
	end
end

function dist(a, b)
	ax, ay, az = a[1], a[2], a[3]
	bx, by, bz = b[1], b[2], b[3]
	dx = math.abs(bx - ax)
	dy = math.abs(by - ay)
	dz = math.abs(bz - az)
	d = math.sqrt((dx ^ 2) + (dy ^ 2) + (dz ^ 2))
	return math.floor(d) / 39.37
end

function roundNum(num, n)
	local mult = 10^(n or 0)
	return math.floor(num * mult + 0.5) / mult
end

function et_Obituary(victim, killer, mod)
	local v_teamid = et.gentity_get(victim, "sess.sessionTeam")
    local k_teamid = et.gentity_get(killer, "sess.sessionTeam")
	if victim ~= killer and killer ~= 1022 and killer ~= 1023 then
		if has_value(assist_weapons, mod) then
			local names = ""
			local names_cens = ""
			local killer_dmg = 0
			local killer_hs = 0
			local assist_dmg = {}
			local assist_hs = {}
			local ms = et.trap_Milliseconds()
			for m=ms, ms-1500, -1 do
				if hitters[victim][m] then
					if hitters[victim][m][1] == killer then
						killer_dmg = killer_dmg + hitters[victim][m][2]
						killer_hs = killer_hs + hitters[victim][m][3]
					else
						if assist_dmg[hitters[victim][m][1]] == nil then
							assist_dmg[hitters[victim][m][1]] = hitters[victim][m][2]
						else
							assist_dmg[hitters[victim][m][1]] = assist_dmg[hitters[victim][m][1]] + hitters[victim][m][2]
						end
						if assist_hs[hitters[victim][m][1]] == nil then
							assist_hs[hitters[victim][m][1]] = hitters[victim][m][3]
						else
							assist_hs[hitters[victim][m][1]] = assist_hs[hitters[victim][m][1]] + hitters[victim][m][3]
						end
					end
				end
			end
			local keyset={}
			local n=0
			for k,v in pairs(assist_dmg) do
				n=n+1
				keyset[n]=k
			end
			local max = 0
			local max_id = 0
			for j=1,#keyset do
				if v_teamid ~= et.gentity_get(keyset[j], "sess.sessionTeam") then
					assists[keyset[j]] = assists[keyset[j]] + 1
				end
				if assist_dmg[keyset[j]] > killer_dmg then
					if v_teamid ~= et.gentity_get(keyset[j], "sess.sessionTeam") and v_teamid ~= k_teamid then 
						killsteals[killer] = killsteals[killer] + 1
					end
					if assist_dmg[keyset[j]] > max then
						max = assist_dmg[keyset[j]]
						max_id = keyset[j]
					end
				end
				local C
				if et.gentity_get(keyset[j], "sess.sessionTeam") == 1 then
					C = 1
				else
					C = 4
				end
				if names == "" then
					if assist_hs[keyset[j]] == 0 then
						names = et.gentity_get(keyset[j], "pers.netname") .. " ^z(^" .. C .. assist_dmg[keyset[j]] .. "^z)"
						if et.gentity_get(keyset[j], "sess.sessionTeam") ~= k_teamid then
							names_cens = "^" .. C .. "TEAMMATE ^z(^" .. C .. assist_dmg[keyset[j]] .. "^z)"
						else
							names_cens = names
						end
					else
						names = et.gentity_get(keyset[j], "pers.netname") .. " ^z(^" .. C .. assist_dmg[keyset[j]] .. "^z, ^" .. C .. assist_hs[keyset[j]] .. " ^zHS)"
						if et.gentity_get(keyset[j], "sess.sessionTeam") ~= k_teamid then
							names_cens = "^" .. C .. "TEAMMATE ^z(^" .. C .. assist_dmg[keyset[j]] .. "^z, ^" .. C .. assist_hs[keyset[j]] .. " ^zHS)"
						else
							names_cens = names
						end
					end
				else
					if assist_hs[keyset[j]] == 0 then
						names = names .. ", " .. et.gentity_get(keyset[j], "pers.netname") .. " ^z(^" .. C .. assist_dmg[keyset[j]] .. "^z)"
						if et.gentity_get(keyset[j], "sess.sessionTeam") ~= k_teamid then
							names_cens = names_cens .. ", ^" .. C .. "TEAMMATE ^z(^" .. C .. assist_dmg[keyset[j]] .. "^z)"
						else
							names_cens = names_cens .. ", " .. et.gentity_get(keyset[j], "pers.netname") .. " ^z(^" .. C .. assist_dmg[keyset[j]] .. "^z)"
						end
					else
						names = names .. ", " .. et.gentity_get(keyset[j], "pers.netname") .. " ^z(^" .. C .. assist_dmg[keyset[j]] .. "^z, ^" .. C .. assist_hs[keyset[j]] .. " ^zHS)"
						if et.gentity_get(keyset[j], "sess.sessionTeam") ~= k_teamid then
							names_cens = names_cens .. ", ^" .. C .. "TEAMMATE ^z(^" .. C .. assist_dmg[keyset[j]] .. "^z, ^" .. C .. assist_hs[keyset[j]] .. " ^zHS)"
						else
							names_cens = names_cens .. ", " .. et.gentity_get(keyset[j], "pers.netname") .. " ^z(^" .. C .. assist_dmg[keyset[j]] .. "^z, ^" .. C .. assist_hs[keyset[j]] .. " ^zHS)"
						end
					end
				end
			end
			if max > 0 then
				if v_teamid ~= et.gentity_get(max_id, "sess.sessionTeam") and v_teamid ~= k_teamid then 
					et.trap_SendServerCommand(killer, "bp \"^zKill stolen from: " .. et.gentity_get(max_id, "pers.netname") .. "\";")
					et.trap_SendServerCommand(max_id, "bp \"^zKill stolen by: " .. et.gentity_get(killer, "pers.netname") .. "\";")
				end
			else
				if names ~= "" then
					if v_teamid ~= k_teamid then
						et.trap_SendServerCommand(killer, "chat \"^zKill Assists: " .. names_cens .. "\";")
					end
				end
			end
			local C
			if k_teamid == 1 then
				C = 1
			else
				C = 4
			end
			if v_teamid ~= k_teamid then
				if announce_hp == true then
					local posk = et.gentity_get(victim, "ps.origin")
					local posv = et.gentity_get(killer, "ps.origin")
					local killdist = dist(posk, posv)
					local killerhp = et.gentity_get(killer, "health")
					local C2 = 2
					if killerhp <= 50 then
						C2 = 3
					end
					if killerhp <= 20 then
						C2 = 1
					end
					if killerhp <= 0 then
						if names == "" then
							et.trap_SendServerCommand(victim, "cp \"" .. et.gentity_get(killer, "pers.netname") .. " ^zwas dead.\nDamage received last 1.5s: (^" .. C .. killer_dmg .. "^z)\";")
							et.trap_SendServerCommand(victim, "chat \"" .. et.gentity_get(killer, "pers.netname") .. " ^zwas dead. Damage received last 1.5s: (^" .. C .. killer_dmg .. "^z)\";")
						else
							et.trap_SendServerCommand(victim, "cp \"" .. et.gentity_get(killer, "pers.netname") .. " ^zwas dead.\nKill Assists: " .. et.gentity_get(killer, "pers.netname") .. "^z(^" .. C .. killer_dmg .. "^z)\n" .. names .. "\";")
							et.trap_SendServerCommand(victim, "chat \"" .. et.gentity_get(killer, "pers.netname") .. " ^zwas dead. Kill Assists: " .. et.gentity_get(killer, "pers.netname") .. "^z(^" .. C .. killer_dmg .. "^z), " .. names .. "\";")
						end
					else
						if names == "" then
							if killer_hs == 0 then
								et.trap_SendServerCommand(victim, "cp \"" .. et.gentity_get(killer, "pers.netname") .. " ^zhad ^" .. C2 .. killerhp .. " ^zHP left. Distance was ^3" .. math.floor(roundNum(killdist)) .. " ^zm\nDamage received last 1.5s: (^" .. C .. killer_dmg .. "^z)\";")
								et.trap_SendServerCommand(victim, "chat \"" .. et.gentity_get(killer, "pers.netname") .. " ^zhad ^" .. C2 .. killerhp .. " ^zHP left. Distance was ^3" .. math.floor(roundNum(killdist)) .. " ^zm. Damage received last 1.5s: (^" .. C .. killer_dmg .. "^z)\";")
							else
								et.trap_SendServerCommand(victim, "cp \"" .. et.gentity_get(killer, "pers.netname") .. " ^zhad ^" .. C2 .. killerhp .. " ^zHP left. Distance was ^3" .. math.floor(roundNum(killdist)) .. " ^zm\nDamage received last 1.5s: (^" .. C .. killer_dmg .. "^z, ^" .. C .. killer_hs .. " ^zHS)\";")
								et.trap_SendServerCommand(victim, "chat \"" .. et.gentity_get(killer, "pers.netname") .. " ^zhad ^" .. C2 .. killerhp .. " ^zHP left. Distance was ^3" .. math.floor(roundNum(killdist)) .. " ^zm. Damage received last 1.5s: (^" .. C .. killer_dmg .. "^z, ^" .. C .. killer_hs .. " ^zHS)\";")
							end
						else
							if killer_hs == 0 then
								et.trap_SendServerCommand(victim, "cp \"" .. et.gentity_get(killer, "pers.netname") .. " ^zhad ^" .. C2 .. killerhp .. " ^zHP left. Distance was ^3" .. math.floor(roundNum(killdist)) .. " ^zm\nKill Assists: " .. et.gentity_get(killer, "pers.netname") .. " ^z(^" .. C .. killer_dmg .. "^z)\n" .. names .. "\";")
								et.trap_SendServerCommand(victim, "chat \"" .. et.gentity_get(killer, "pers.netname") .. " ^zhad ^" .. C2 .. killerhp .. " ^zHP left. Distance was ^3" .. math.floor(roundNum(killdist)) .. " ^zm. Kill Assists: " .. et.gentity_get(killer, "pers.netname") .. " ^z(^" .. C .. killer_dmg .. "^z), " .. names .. "\";")
							else
								et.trap_SendServerCommand(victim, "cp \"" .. et.gentity_get(killer, "pers.netname") .. " ^zhad ^" .. C2 .. killerhp .. " ^zHP left. Distance was ^3" .. math.floor(roundNum(killdist)) .. " ^zm\nKill Assists: " .. et.gentity_get(killer, "pers.netname") .. " ^z(^" .. C .. killer_dmg .. "^z, ^" .. C .. killer_hs .. " ^zHS)\n" .. names .. "\";")
								et.trap_SendServerCommand(victim, "chat \"" .. et.gentity_get(killer, "pers.netname") .. " ^zhad ^" .. C2 .. killerhp .. " ^zHP left. Distance was ^3" .. math.floor(roundNum(killdist)) .. " ^zm. Kill Assists: " .. et.gentity_get(killer, "pers.netname") .. " ^z(^" .. C .. killer_dmg .. "^z, ^" .. C .. killer_hs .. " ^zHS), " .. names .. "\";")
							end
						end
					end
				else
					if names == "" then
						if killer_hs == 0 then
							et.trap_SendServerCommand(victim, "cp \"^zDamage received last 1.5s: " .. et.gentity_get(killer, "pers.netname") .. "^z(^" .. C .. killer_dmg .. "^z)\";")
							et.trap_SendServerCommand(victim, "chat \"^zDamage received last 1.5s: " .. et.gentity_get(killer, "pers.netname") .. "^z(^" .. C .. killer_dmg .. "^z)\";")
						else
							et.trap_SendServerCommand(victim, "cp \"^zDamage received last 1.5s: " .. et.gentity_get(killer, "pers.netname") .. "^z(^" .. C .. killer_dmg .. "^z, ^" .. C .. killer_hs .. " ^zHS)\";")
							et.trap_SendServerCommand(victim, "chat \"^zDamage received last 1.5s: " .. et.gentity_get(killer, "pers.netname") .. "^z(^" .. C .. killer_dmg .. "^z, ^" .. C .. killer_hs .. " ^zHS)\";")
						end
					else
						if killer_hs == 0 then
							et.trap_SendServerCommand(victim, "cp \"^zKill Assists: " .. et.gentity_get(killer, "pers.netname") .. " ^z(^" .. C .. killer_dmg .. "^z)\n" .. names .. "\";")
							et.trap_SendServerCommand(victim, "chat \"^zKill Assists: " .. et.gentity_get(killer, "pers.netname") .. " ^z(^" .. C .. killer_dmg .. "^z), " .. names .. "\";")
						else
							et.trap_SendServerCommand(victim, "cp \"^zKill Assists: " .. et.gentity_get(killer, "pers.netname") .. " ^z(^" .. C .. killer_dmg .. "^z, ^" .. C .. killer_hs .. " ^zHS)\n" .. names .. "\";")
							et.trap_SendServerCommand(victim, "chat \"^zKill Assists: " .. et.gentity_get(killer, "pers.netname") .. " ^z(^" .. C .. killer_dmg .. "^z, ^" .. C .. killer_hs .. " ^zHS), " .. names .. "\";")
						end
					end
				end
			end
		end
	end
end

function et_ClientSpawn(clientNum, revived, teamChange, restoreHealth)
	hitters[clientNum] = {nil, nil, nil, nil}
	hitRegionsData[clientNum] = getAllHitRegions(clientNum)
end

function et_ClientDisconnect(clientNum)
	hitters[clientNum] = {nil, nil, nil, nil}
	assists[clientNum] = 0
	killsteals[clientNum] = 0
end