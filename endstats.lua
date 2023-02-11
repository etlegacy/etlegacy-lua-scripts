-- endstats.lua by x0rnn, shows some interesting game statistics at the end of a round (highest light weapon acc, highest hs acc, most dynamites planted, most pistol kills, kill/death stats vs. all opponents, etc.)

killing_sprees = {}
death_sprees = {}
kmulti         = {}
kendofmap      = false
eomap_done = false
eomaptime = 0
gamestate   = -1
topshots = {}
axis_time = {}
allies_time = {}
mkps = {}
weaponstats = {}
endplayers = {}
endplayerscnt = 0
tblcount = 0
vsstats = {}
vsstats_kills = {}
vsstats_deaths = {}
kills = {}
deaths = {}
worst_enemy = {}
easiest_prey = {}
vsstats = {}
vsstats_kills = {}
vsstats_deaths = {}

topshot_names = { [1]="Most damage given", [2]="Most damage received", [3]="Most team damage given", [4]="Most team damage received", [5]="Most teamkills", [6]="Most selfkills", [7]="Most deaths", [8]="Most kills per minute", [9]="Quickest multikill w/ light weapons", [11]="Farthest riflenade kill", [12]="Most light weapon kills", [13]="Most pistol kills", [14]="Most rifle kills", [15]="Most riflenade kills", [16]="Most sniper kills", [17]="Most knife kills", [18]="Most air support kills", [19]="Most mine kills", [20]="Most grenade kills", [21]="Most panzer kills", [22]="Most mortar kills", [23]="Most panzer deaths", [24]="Mortarmagnet", [25]="Most multikills", [26]="Most MG42 kills", [27]="Most MG42 deaths", [28]="Most revives", [29]="Most revived", [30]="Best K/D ratio", [31]="Most dynamites planted", [32]="Most dynamites defused", [33]="Most doublekills", [34]="Longest killing spree", [35]="Longest death spree", [36]="Most objectives stolen", [37]="Most objectives returned" }

function et_InitGame(levelTime, randomSeed, restart)

    et.RegisterModname("endstats.lua "..et.FindSelf())
    sv_maxclients = tonumber(et.trap_Cvar_Get("sv_maxclients"))

    local i = 0
    for i=0, sv_maxclients-1 do
        killing_sprees[i] = 0
        death_sprees[i] = 0
        kmulti[i] = { [1]=0, [2]=0, }
        topshots[i] = { [1]=0, [2]=0, [3]=0, [4]=0, [5]=0, [6]=0, [7]=0, [8]=0, [9]=0, [10]=0, [11]=0, [12]=0, [13]=0, [14]=0, [15]=0, [16]=0, [17]=0, [18]=0, [19]=0, [20]=0, [21]=0, [22]=0, [23]=0, [24]=0, [25]=0, [26]=0, [27]=0, [28]=0 }
        mkps[i] = { [1]=0, [2]=0, [3]=0 }
        axis_time[i] = 0
        allies_time[i] = 0
        kills[i] = 0
        deaths[i] = 0
    end

	local j = 0
	for j=0,sv_maxclients-1 do
		vsstats[j]={[0]=0,[1]=0,[2]=0,[3]=0,[4]=0,[5]=0,[6]=0,[7]=0,[8]=0,[9]=0,[10]=0,[11]=0,[12]=0,[13]=0,[14]=0,[15]=0,[16]=0,[17]=0,[18]=0,[19]=0,[20]=0,[21]=0,[22]=0,[23]=0,[24]=0,[25]=0,[26]=0,[27]=0,[28]=0,[29]=0,[30]=0,[31]=0,[32]=0,[33]=0,[34]=0,[35]=0,[36]=0,[37]=0,[38]=0,[39]=0,[40]=0,[41]=0,[42]=0,[43]=0,[44]=0,[45]=0,[46]=0,[47]=0,[48]=0,[49]=0,[50]=0,[51]=0,[52]=0,[53]=0,[54]=0,[55]=0,[56]=0,[57]=0,[58]=0,[59]=0,[60]=0,[61]=0,[62]=0,[63]=0}
		vsstats_kills[j]={[0]=0,[1]=0,[2]=0,[3]=0,[4]=0,[5]=0,[6]=0,[7]=0,[8]=0,[9]=0,[10]=0,[11]=0,[12]=0,[13]=0,[14]=0,[15]=0,[16]=0,[17]=0,[18]=0,[19]=0,[20]=0,[21]=0,[22]=0,[23]=0,[24]=0,[25]=0,[26]=0,[27]=0,[28]=0,[29]=0,[30]=0,[31]=0,[32]=0,[33]=0,[34]=0,[35]=0,[36]=0,[37]=0,[38]=0,[39]=0,[40]=0,[41]=0,[42]=0,[43]=0,[44]=0,[45]=0,[46]=0,[47]=0,[48]=0,[49]=0,[50]=0,[51]=0,[52]=0,[53]=0,[54]=0,[55]=0,[56]=0,[57]=0,[58]=0,[59]=0,[60]=0,[61]=0,[62]=0,[63]=0}
		vsstats_deaths[j]={[0]=0,[1]=0,[2]=0,[3]=0,[4]=0,[5]=0,[6]=0,[7]=0,[8]=0,[9]=0,[10]=0,[11]=0,[12]=0,[13]=0,[14]=0,[15]=0,[16]=0,[17]=0,[18]=0,[19]=0,[20]=0,[21]=0,[22]=0,[23]=0,[24]=0,[25]=0,[26]=0,[27]=0,[28]=0,[29]=0,[30]=0,[31]=0,[32]=0,[33]=0,[34]=0,[35]=0,[36]=0,[37]=0,[38]=0,[39]=0,[40]=0,[41]=0,[42]=0,[43]=0,[44]=0,[45]=0,[46]=0,[47]=0,[48]=0,[49]=0,[50]=0,[51]=0,[52]=0,[53]=0,[54]=0,[55]=0,[56]=0,[57]=0,[58]=0,[59]=0,[60]=0,[61]=0,[62]=0,[63]=0}
		worst_enemy[j]={[0]=0,[1]=0,[2]=0,[3]=0,[4]=0,[5]=0,[6]=0,[7]=0,[8]=0,[9]=0,[10]=0,[11]=0,[12]=0,[13]=0,[14]=0,[15]=0,[16]=0,[17]=0,[18]=0,[19]=0,[20]=0,[21]=0,[22]=0,[23]=0,[24]=0,[25]=0,[26]=0,[27]=0,[28]=0,[29]=0,[30]=0,[31]=0,[32]=0,[33]=0,[34]=0,[35]=0,[36]=0,[37]=0,[38]=0,[39]=0,[40]=0,[41]=0,[42]=0,[43]=0,[44]=0,[45]=0,[46]=0,[47]=0,[48]=0,[49]=0,[50]=0,[51]=0,[52]=0,[53]=0,[54]=0,[55]=0,[56]=0,[57]=0,[58]=0,[59]=0,[60]=0,[61]=0,[62]=0,[63]=0}
		easiest_prey[j]={[0]=0,[1]=0,[2]=0,[3]=0,[4]=0,[5]=0,[6]=0,[7]=0,[8]=0,[9]=0,[10]=0,[11]=0,[12]=0,[13]=0,[14]=0,[15]=0,[16]=0,[17]=0,[18]=0,[19]=0,[20]=0,[21]=0,[22]=0,[23]=0,[24]=0,[25]=0,[26]=0,[27]=0,[28]=0,[29]=0,[30]=0,[31]=0,[32]=0,[33]=0,[34]=0,[35]=0,[36]=0,[37]=0,[38]=0,[39]=0,[40]=0,[41]=0,[42]=0,[43]=0,[44]=0,[45]=0,[46]=0,[47]=0,[48]=0,[49]=0,[50]=0,[51]=0,[52]=0,[53]=0,[54]=0,[55]=0,[56]=0,[57]=0,[58]=0,[59]=0,[60]=0,[61]=0,[62]=0,[63]=0}
	end 
end

function n2b(number) -- thanks to adawolfa
	local bits = {}

	local i = 1
	while 2 ^ (i + 1) < number do
		i = i + 1
	end

	while i >= 0 do
		if 2 ^ i <= number then
			table.insert(bits, 2 ^ i)
			number = number - 2 ^ i
		end
		i = i - 1
	end

	return bits, #bits
end

local function roundNum(num, n)
	local mult = 10^(n or 0)
	return math.floor(num * mult + 0.5) / mult
end

function getKeysSortedByValue(tbl, sortFunction)
	local keys = {}
	for key in pairs(tbl) do
		table.insert(keys, key)
	end

	table.sort(keys, function(a, b)
		return sortFunction(tbl[a], tbl[b])
	end)
	
	return keys
end

function topshots_f(id)
	local max = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}
	local max_id = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}
	local i = 0
	for i=0, sv_maxclients-1 do
		local team = tonumber(et.gentity_get(i, "sess.sessionTeam"))
		if team == 1 or team == 2 then
			local dg = tonumber(et.gentity_get(i, "sess.damage_given"))
			local dr = tonumber(et.gentity_get(i, "sess.damage_received"))
			local tdg = tonumber(et.gentity_get(i, "sess.team_damage_given"))
			local tdr = tonumber(et.gentity_get(i, "sess.team_damage_received"))
			local tk = tonumber(et.gentity_get(i, "sess.team_kills"))
			local sk = tonumber(et.gentity_get(i, "sess.self_kills"))
			local d = tonumber(et.gentity_get(i, "sess.deaths"))
			local k = tonumber(et.gentity_get(i, "sess.kills"))
			local kd = 0
			if d ~= 0 then
				kd = k/d
			else
				kd = k + 1
			end
			
			-- damage given
			if dg > max[1] then 
				max[1] = dg
				max_id[1] = i
			end
			-- damage received
			if dr > max[2] then 
				max[2] = dr
				max_id[2] = i
			end
			-- team damage given
			if tdg > max[3] then 
				max[3] = tdg
				max_id[3] = i
			end
			-- team damage received
			if tdr > max[4] then 
				max[4] = tdr
				max_id[4] = i
			end
			-- teamkills
			if tk > max[5] then 
				max[5] = tk
				max_id[5] = i
			end
			-- selfkills
			if sk > max[6] then 
				max[6] = sk
				max_id[6] = i
			end
			-- deaths
			if d > max[7] then 
				max[7] = d
				max_id[7] = i
			end
			-- kills per minute
			if team == 1 then
				if k > 10 then
					local kpm = k/(((eomaptime - axis_time[i])/1000)/60)
					if kpm > max[8] then
						max[8] = kpm
						max_id[8] = i
					end
				end
			elseif team == 2 then
				if k > 10 then
					local kpm = k/(((eomaptime - allies_time[i])/1000)/60)
					if kpm > max[8] then
						max[8] = kpm
						max_id[8] = i
					end
				end
			end
			-- quickest lightweapon multikill
			if topshots[i][14] >= max[9] then 
				if topshots[i][14] > max[9] then
					max[9] = topshots[i][14]
					max[10] = topshots[i][15]
					max_id[9] = i
					max_id[10] = i
				elseif topshots[i][14] == max[9] then
					if topshots[i][15] < max[10] then
						max[9] = topshots[i][14]
						max[10] = topshots[i][15]
						max_id[9] = i
						max_id[10] = i
					end
				end
			end
			-- farthest riflegrenade kill
			if topshots[i][16] > max[11] then
				max[11] = topshots[i][16]
				max_id[11] = i
			end
			-- lightweapon kills
			if topshots[i][1] > max[12] then
				max[12] = topshots[i][1]
				max_id[12] = i
			end
			-- pistol kills
			if topshots[i][2] > max[13] then
				max[13] = topshots[i][2]
				max_id[13] = i
			end
			-- rifle kills
			if topshots[i][3] > max[14] then
				max[14] = topshots[i][3]
				max_id[14] = i
			end
			-- riflegrenade kills
			if topshots[i][4] > max[15] then
				max[15] = topshots[i][4]
				max_id[15] = i
			end
			-- sniper kills
			if topshots[i][5] > max[16] then
				max[16] = topshots[i][5]
				max_id[16] = i
			end
			-- knife kills
			if topshots[i][6] > max[17] then
				max[17] = topshots[i][6]
				max_id[17] = i
			end
			-- air support kills
			if topshots[i][7] > max[18] then
				max[18] = topshots[i][7]
				max_id[18] = i
			end
			-- mine kills
			if topshots[i][8] > max[19] then
				max[19] = topshots[i][8]
				max_id[19] = i
			end
			-- grenade kills
			if topshots[i][9] > max[20] then
				max[20] = topshots[i][9]
				max_id[20] = i
			end
			-- panzerfaust kills
			if topshots[i][10] > max[21] then
				max[21] = topshots[i][10]
				max_id[21] = i
			end
			-- mortar kills
			if topshots[i][11] > max[22] then
				max[22] = topshots[i][11]
				max_id[22] = i
			end
			-- panzerfaust deaths
			if topshots[i][12] > max[23] then
				max[23] = topshots[i][12]
				max_id[23] = i
			end
			-- mortar deaths
			if topshots[i][13] > max[24] then
				max[24] = topshots[i][13]
				max_id[24] = i
			end
			-- multikills
			if topshots[i][17] > max[25] then
				max[25] = topshots[i][17]
				max_id[25] = i
			end
			-- mg42 kills
			if topshots[i][18] > max[26] then
				max[26] = topshots[i][18]
				max_id[26] = i
			end
			-- mg42 deaths
			if topshots[i][19] > max[27] then
				max[27] = topshots[i][19]
				max_id[27] = i
			end
			-- most revives
			if topshots[i][20] > max[28] then
				max[28] = topshots[i][20]
				max_id[28] = i
			end
			-- most revived
			if topshots[i][21] > max[29] then
				max[29] = topshots[i][21]
				max_id[29] = i
			end
			-- k/d ratio
			if k > 9 then
				if kd > max[30] then
					max[30] = kd
					max_id[30] = i
				end
			end
			-- most dynamites planted
			if topshots[i][22] > max[31] then
				max[31] = topshots[i][22]
				max_id[31] = i
			end
			-- most dynamites defused
			if topshots[i][23] > max[32] then
				max[32] = topshots[i][23]
				max_id[32] = i
			end
			-- most doublekills
			local dk = topshots[i][24] - topshots[i][17]
			if dk > max[33] then
				max[33] = dk
				max_id[33] = i
			end
			--longest kill spree
			if topshots[i][25] > max[34] then
				max[34] = topshots[i][25]
				max_id[34] = i
			end
			--longest death spree
			if topshots[i][26] > max[35] then
				max[35] = topshots[i][26]
				max_id[35] = i
			end
			--most objectives stolen
			if topshots[i][27] > max[36] then
				max[36] = topshots[i][27]
				max_id[36] = i
			end
			--most objectives returned
			if topshots[i][28] > max[37] then
				max[37] = topshots[i][28]
				max_id[37] = i
			end
		end
	end
	if id == -2 then
		local ws_max = { 0, 0, 0, 0 }
		local ws_max_id = { 0, 0, 0, 0}
		local cnt = 0
		for cnt=0, sv_maxclients-1 do
			if endplayers[cnt] then
				-- highest light weapons accuracy
				if weaponstats[cnt][2] > 100 then
					if (weaponstats[cnt][1]/weaponstats[cnt][2])*100 > ws_max[1] then
						ws_max[1] = (weaponstats[cnt][1]/weaponstats[cnt][2])*100
						ws_max_id[1] = cnt
					end
				end
				-- highest headshot accuracy
				if weaponstats[cnt][1] > 10 and weaponstats[cnt][2] > 100 then
					if (weaponstats[cnt][3]/weaponstats[cnt][1])*100 > ws_max[2] then
						ws_max[2] = (weaponstats[cnt][3]/weaponstats[cnt][1])*100
						ws_max_id[2] = cnt
					end
				end
				-- most headshots
				if weaponstats[cnt][3] > ws_max[3] then
					ws_max[3] = weaponstats[cnt][3]
					ws_max_id[3] = cnt
				end
				-- most bullets fired
				if weaponstats[cnt][2] > ws_max[4] then
					ws_max[4] = weaponstats[cnt][2]
					ws_max_id[4] = cnt
				end
			end
		end
		local j = 1
		local players = {}
		for j=1, 37 do
			if max[j] > 1 then
				if j ~= 10 and j ~= 25 and j ~= 33 then
					if j == 8 then
						--et.trap_SendServerCommand(-1, "chat \"^z" .. topshot_names[j] .. ": " .. et.gentity_get(max_id[j], "pers.netname") .. " ^z- ^1" .. roundNum(max[j], 2) .. "\"\n")
						table.insert(players, {
							topshot_names[j],
							et.gentity_get(max_id[j], "pers.netname"),
							roundNum(max[j], 2)
						})
					elseif j == 9 then
						-- dirty "fix" instead of reordering all indexes lol
						if max[33] > 1 then
							--et.trap_SendServerCommand(-1, "chat \"^z" .. topshot_names[33] .. ": " .. et.gentity_get(max_id[33], "pers.netname") .. " ^z- ^1" .. max[33] .. "\"\n")
							table.insert(players, {
							topshot_names[33],
							et.gentity_get(max_id[33], "pers.netname"),
							max[33]
						})
						end
						--et.trap_SendServerCommand(-1, "chat \"^z" .. topshot_names[25] .. ": " .. et.gentity_get(max_id[25], "pers.netname") .. " ^z- ^1" .. max[25] .. "\"\n")
						--et.trap_SendServerCommand(-1, "chat \"^z" .. topshot_names[j] .. ": " .. et.gentity_get(max_id[j], "pers.netname") .. " ^z- ^1" .. max[j] .. " ^zkills in ^1" .. roundNum(max[10]/1000, 3) .. " ^zseconds\"\n")
						table.insert(players, {
							topshot_names[25],
							et.gentity_get(max_id[25], "pers.netname"),
							max[25]
						})
						table.insert(players, {
							topshot_names[j],
							et.gentity_get(max_id[j], "pers.netname"),
							max[j] .. " ^7kills in " .. roundNum(max[10]/1000, 2) .. "s"
						})
					elseif j == 11 then
						--et.trap_SendServerCommand(-1, "chat \"^z" .. topshot_names[j] .. ": " .. et.gentity_get(max_id[j], "pers.netname") .. " ^z- ^1" .. roundNum(max[j], 2) .. " ^zm\"\n")
						table.insert(players, {
							topshot_names[j],
							et.gentity_get(max_id[j], "pers.netname"),
							roundNum(max[j], 2) .. " ^7m"
						})
					else
						--et.trap_SendServerCommand(-1, "chat \"^z" .. topshot_names[j] .. ": " .. et.gentity_get(max_id[j], "pers.netname") .. " ^z- ^1" .. max[j] .. "\"\n")
						table.insert(players, {
							topshot_names[j],
							et.gentity_get(max_id[j], "pers.netname"),
							max[j]
						})
					end
				end
			end
		end
		local z = 1
		for z = 1, 4 do
			if ws_max[z] > 1 then
				if z == 1 then
					--et.trap_SendServerCommand(-1, "chat \"^zHighest light weapons accuracy: " .. et.gentity_get(ws_max_id[z], "pers.netname") .. " ^z- ^1" .. roundNum(ws_max[z], 2) .. " ^zpercent\"\n")
					table.insert(players, {
						"Highest light weapons accuracy",
						et.gentity_get(ws_max_id[z], "pers.netname"),
						roundNum(ws_max[z], 2) .. " percent"
					})
				elseif z == 2 then
					--et.trap_SendServerCommand(-1, "chat \"^zHighest headshot accuracy: " .. et.gentity_get(ws_max_id[z], "pers.netname") .. " ^z- ^1" .. roundNum(ws_max[z], 2) .. " ^zpercent\"\n")
					table.insert(players, {
						"Highest headshot accuracy",
						et.gentity_get(ws_max_id[z], "pers.netname"),
						roundNum(ws_max[z], 2) .. " percent"
					})
				elseif z == 3 then
					--et.trap_SendServerCommand(-1, "chat \"^zMost headshots: " .. et.gentity_get(ws_max_id[z], "pers.netname") .. " ^z- ^1" .. ws_max[z] .. "\"\n")
					table.insert(players, {
						"Most headshots",
						et.gentity_get(ws_max_id[z], "pers.netname"),
						ws_max[z]
					})
				elseif z == 4 then
					--et.trap_SendServerCommand(-1, "chat \"^zMost bullets fired: " .. et.gentity_get(ws_max_id[z], "pers.netname") .. " ^z- ^1" .. ws_max[z] .. "\"\n")
					table.insert(players, {
						"Most bullets fired",
						et.gentity_get(ws_max_id[z], "pers.netname"),
						ws_max[z]
					})
				end
			end
		end
		send_table(-1, {
			{name = "Award"                 },
			{name = "Player",  align = "right"},
			{name = "Value", align = "right"},
		}, players)
		local p = 0
		for p=0, sv_maxclients-1 do
			local t = tonumber(et.gentity_get(p, "sess.sessionTeam"))
			if t == 1 or t == 2 then
				et.trap_SendServerCommand(p, "cpm \"^zKills: ^1" .. kills[p] .. " ^z- Deaths: ^1" .. deaths[p] .. " ^z- Damage given: ^1" .. tonumber(et.gentity_get(p, "sess.damage_given")) .. "\"\n")
				local top_we = {0, 0}
				local top_ep = {0, 0}
				local e = 0
				for e=0, sv_maxclients-1 do
					if e ~= p then
						local t2 = tonumber(et.gentity_get(e, "sess.sessionTeam"))
						if t2 == 1 or t2 == 2 then
							if t ~= t2 then
								vsstats_f(p, e)
								if worst_enemy[p][e] > top_we[1] then
									top_we[1] = worst_enemy[p][e]
									top_we[2] = e
								end
								if easiest_prey[p][e] > top_ep[1] then
									top_ep[1] = easiest_prey[p][e]
									top_ep[2] = e
								end
							end
						end
					end
				end
				local sortedKeys = getKeysSortedByValue(vsstats_kills[p], function(a, b) return a > b end)
				local players2 = {}
				for _, key in ipairs(sortedKeys) do
					if not (vsstats_kills[p][key] == 0 and vsstats_deaths[p][key] == 0) then
						local t3 = tonumber(et.gentity_get(key, "sess.sessionTeam"))
						if t3 == 1 or t3 == 2 then
							if t ~= t3 then
								--et.trap_SendServerCommand(p, "chat \"" .. et.gentity_get(key, "pers.netname") .. "^7: ^3Kills: ^7" .. vsstats_kills[p][key] .. " ^3Deaths: ^7" .. vsstats_deaths[p][key] .. "\"")
								table.insert(players2, {
									et.gentity_get(key, "pers.netname"),
									vsstats_kills[p][key],
									vsstats_deaths[p][key]
								})
							end
						end
					end
				end
				send_table(p, {
					{name = "Player"                 },
					{name = "Kills",  align = "right"},
					{name = "Deaths", align = "right"},
				}, players2)

				if top_ep[1] > 3 then
					et.trap_SendServerCommand(p, "cpm \"^zEasiest prey: " .. et.gentity_get(top_ep[2], "pers.netname") .. "^z- Kills: ^1" .. top_ep[1] .. "\"\n")
				end
				if top_we[1] > 3 then
					et.trap_SendServerCommand(p, "cpm \"^zWorst enemy: " .. et.gentity_get(top_we[2], "pers.netname") .. "^z- Deaths: ^1" .. top_we[1] .. "\"\n")
				end
			end
		end
	end
end

function vsstats_f(id, id2)
	local ratio = 0
	if vsstats[id2][id] == 0 then
		ratio = vsstats[id][id2]
	else
		if vsstats[id][id2] == 0 then
			ratio = -vsstats[id2][id]
		else
			ratio = roundNum(vsstats[id][id2]/vsstats[id2][id], 2)
		end
	end
	if not (vsstats[id][id2] == 0 and vsstats[id2][id] == 0) then
		vsstats_kills[id][id2] = vsstats[id][id2]
		vsstats_deaths[id][id2] = vsstats[id2][id]
	end
end

function et_Print(text)
	if gamestate == 0 then
		if string.find(text, "Medic_Revive") then
			local junk1,junk2,medic,zombie = string.find(text, "^Medic_Revive:%s+(%d+)%s+(%d+)")
			topshots[tonumber(medic)][20] = topshots[tonumber(medic)][20] + 1
			topshots[tonumber(zombie)][21] = topshots[tonumber(zombie)][21] + 1
		end
		if string.find(text, "Dynamite_Plant") then
   	     local i, j = string.find(text, "%d+")   
	        local id = tonumber(string.sub(text, i, j))
			topshots[id][22] = topshots[id][22] + 1
	    end
		if string.find(text, "Dynamite_Diffuse") then
	   	 local i, j = string.find(text, "%d+")   
		    local id = tonumber(string.sub(text, i, j))
			topshots[id][23] = topshots[id][23] + 1
	    end
		if string.find(text, "team_CTF_redflag") or string.find(text, "team_CTF_blueflag") then
   	     local i, j = string.find(text, "%d+")   
	        local id = tonumber(string.sub(text, i, j))
			if string.find(text, "team_CTF_redflag") then
				local team = tonumber(et.gentity_get(id, "sess.sessionTeam"))
				if team == 2 then
					topshots[id][27] = topshots[id][27] + 1
				elseif team == 1 then
					topshots[id][28] = topshots[id][28] + 1
				end
			elseif string.find(text, "team_CTF_blueflag") then
				local team = tonumber(et.gentity_get(id, "sess.sessionTeam"))
				if team == 1 then
					topshots[id][27] = topshots[id][27] + 1
				elseif team == 2 then
					topshots[id][28] = topshots[id][28] + 1
				end
			end
	    end 
	end

    if kendofmap and string.find(text, "^WeaponStats: ") == 1 then
		if endplayerscnt < tblcount then
			for id, m, bla in string.gmatch(text, "WeaponStats: ([%d]+) [%d]+ ([%d]+) ([^\n]+)") do
				if endplayers[tonumber(id)] then
					if weaponstats[tonumber(id)] == nil then
						endplayerscnt = endplayerscnt + 1
						if tonumber(m)~=0 and tonumber(m)~=1 and tonumber(m)~=2 and tonumber(m)~=4 and tonumber(m)~=8 and tonumber(m)~=16 and tonumber(m)~=32  and tonumber(m)~=64 and tonumber(m)~=128 and tonumber(m)~=256 and tonumber(m)~=512 and tonumber(m)~=1024 and tonumber(m)~=2048 and tonumber(m)~=4096 and tonumber(m)~=8192 and tonumber(m)~=16384 and tonumber(m)~=32768 and tonumber(m)~=65536 and tonumber(m)~=131072 and tonumber(m)~=262144 and tonumber(m)~=524288 and tonumber(m)~=1048576 and tonumber(m)~=2097152 then
							bits, bits_len = n2b(tonumber(m))
							local j = 1
							local knife = false
							local w = 0
							for j = 1,bits_len do
								if bits[j] == 1 or bits[j] == 2 or bits[j] == 4 or bits[j] == 8 or bits[j] == 16 or bits[j] == 32 then
									if bits[j] == 1 then
										knife = true
									else
										w = w + 1
									end
								end
							end
							if w ~= 0 then
								if knife == true then
									if w == 1 then
										for hits, shots, hs in string.gmatch(bla, "[%d]+ [%d]+ [%d]+ [%d]+ [%d]+ ([%d]+) ([%d]+) [%d]+ [%d]+ ([%d]+) [^\n]+") do
											weaponstats[tonumber(id)] = { [1]=tonumber(hits), [2]=tonumber(shots), [3]=tonumber(hs) }
										end
									elseif w == 2 then
										for hits1,shots1,hs1,hits2,shots2,hs2 in string.gmatch(bla, "[%d]+ [%d]+ [%d]+ [%d]+ [%d]+ ([%d]+) ([%d]+) [%d]+ [%d]+ ([%d]+) ([%d]+) ([%d]+) [%d]+ [%d]+ ([%d]+) [^\n]+") do
											weaponstats[tonumber(id)] = { [1]=tonumber(hits1)+tonumber(hits2), [2]=tonumber(shots1)+tonumber(shots2), [3]=tonumber(hs1)+tonumber(hs2) }
										end
									elseif w == 3 then
										for hits1,shots1,hs1,hits2,shots2,hs2,hits3,shots3,hs3 in string.gmatch(bla, "[%d]+ [%d]+ [%d]+ [%d]+ [%d]+ ([%d]+) ([%d]+) [%d]+ [%d]+ ([%d]+) ([%d]+) ([%d]+) [%d]+ [%d]+ ([%d]+) ([%d]+) ([%d]+) [%d]+ [%d]+ ([%d]+) [^\n]+") do
											weaponstats[tonumber(id)] = { [1]=tonumber(hits1)+tonumber(hits2)+tonumber(hits3), [2]=tonumber(shots1)+tonumber(shots2)+tonumber(shots3), [3]=tonumber(hs1)+tonumber(hs2)+tonumber(hs3) }
										end
									elseif w == 4 then
										for hits1,shots1,hs1,hits2,shots2,hs2,hits3,shots3,hs3,hits4,shots4,hs4 in string.gmatch(bla, "[%d]+ [%d]+ [%d]+ [%d]+ [%d]+ ([%d]+) ([%d]+) [%d]+ [%d]+ ([%d]+) ([%d]+) ([%d]+) [%d]+ [%d]+ ([%d]+) ([%d]+) ([%d]+) [%d]+ [%d]+ ([%d]+) ([%d]+) ([%d]+) [%d]+ [%d]+ ([%d]+) [^\n]+") do
											weaponstats[tonumber(id)] = { [1]=tonumber(hits1)+tonumber(hits2)+tonumber(hits3)+tonumber(hits4), [2]=tonumber(shots1)+tonumber(shots2)+tonumber(shots3)+tonumber(shots4), [3]=tonumber(hs1)+tonumber(hs2)+tonumber(hs3)+tonumber(hs4) }
										end
									elseif w == 5 then
										for hits1,shots1,hs1,hits2,shots2,hs2,hits3,shots3,hs3,hits4,shots4,hs4,hits5,shots5,hs5 in string.gmatch(bla, "[%d]+ [%d]+ [%d]+ [%d]+ [%d]+ ([%d]+) ([%d]+) [%d]+ [%d]+ ([%d]+) ([%d]+) ([%d]+) [%d]+ [%d]+ ([%d]+) ([%d]+) ([%d]+) [%d]+ [%d]+ ([%d]+) ([%d]+) ([%d]+) [%d]+ [%d]+ ([%d]+) ([%d]+) ([%d]+) [%d]+ [%d]+ ([%d]+) [^\n]+") do
											weaponstats[tonumber(id)] = { [1]=tonumber(hits1)+tonumber(hits2)+tonumber(hits3)+tonumber(hits4)+tonumber(hits5), [2]=tonumber(shots1)+tonumber(shots2)+tonumber(shots3)+tonumber(shots4)+tonumber(shots5), [3]=tonumber(hs1)+tonumber(hs2)+tonumber(hs3)+tonumber(hs4)+tonumber(hs5) }
										end
									end
								else
									if w == 1 then
										for hits, shots, hs in string.gmatch(bla, "([%d]+) ([%d]+) [%d]+ [%d]+ ([%d]+) [^\n]+") do
											weaponstats[tonumber(id)] = { [1]=tonumber(hits), [2]=tonumber(shots), [3]=tonumber(hs) }
										end
									elseif w == 2 then
										for hits1,shots1,hs1,hits2,shots2,hs2 in string.gmatch(bla, "([%d]+) ([%d]+) [%d]+ [%d]+ ([%d]+) ([%d]+) ([%d]+) [%d]+ [%d]+ ([%d]+) [^\n]+") do
											weaponstats[tonumber(id)] = { [1]=tonumber(hits1)+tonumber(hits2), [2]=tonumber(shots1)+tonumber(shots2), [3]=tonumber(hs1)+tonumber(hs2) }
										end
									elseif w == 3 then
										for hits1,shots1,hs1,hits2,shots2,hs2,hits3,shots3,hs3 in string.gmatch(bla, "([%d]+) ([%d]+) [%d]+ [%d]+ ([%d]+) ([%d]+) ([%d]+) [%d]+ [%d]+ ([%d]+) ([%d]+) ([%d]+) [%d]+ [%d]+ ([%d]+) [^\n]+") do
											weaponstats[tonumber(id)] = { [1]=tonumber(hits1)+tonumber(hits2)+tonumber(hits3), [2]=tonumber(shots1)+tonumber(shots2)+tonumber(shots3), [3]=tonumber(hs1)+tonumber(hs2)+tonumber(hs3) }
										end
									elseif w == 4 then
										for hits1,shots1,hs1,hits2,shots2,hs2,hits3,shots3,hs3,hits4,shots4,hs4 in string.gmatch(bla, "([%d]+) ([%d]+) [%d]+ [%d]+ ([%d]+) ([%d]+) ([%d]+) [%d]+ [%d]+ ([%d]+) ([%d]+) ([%d]+) [%d]+ [%d]+ ([%d]+) ([%d]+) ([%d]+) [%d]+ [%d]+ ([%d]+) [^\n]+") do
											weaponstats[tonumber(id)] = { [1]=tonumber(hits1)+tonumber(hits2)+tonumber(hits3)+tonumber(hits4), [2]=tonumber(shots1)+tonumber(shots2)+tonumber(shots3)+tonumber(shots4), [3]=tonumber(hs1)+tonumber(hs2)+tonumber(hs3)+tonumber(hs4) }
										end
									elseif w == 5 then
										for hits1,shots1,hs1,hits2,shots2,hs2,hits3,shots3,hs3,hits4,shots4,hs4,hits5,shots5,hs5 in string.gmatch(bla, "([%d]+) ([%d]+) [%d]+ [%d]+ ([%d]+) ([%d]+) ([%d]+) [%d]+ [%d]+ ([%d]+) ([%d]+) ([%d]+) [%d]+ [%d]+ ([%d]+) ([%d]+) ([%d]+) [%d]+ [%d]+ ([%d]+) ([%d]+) ([%d]+) [%d]+ [%d]+ ([%d]+) [^\n]+") do
											weaponstats[tonumber(id)] = { [1]=tonumber(hits1)+tonumber(hits2)+tonumber(hits3)+tonumber(hits4)+tonumber(hits5), [2]=tonumber(shots1)+tonumber(shots2)+tonumber(shots3)+tonumber(shots4)+tonumber(shots5), [3]=tonumber(hs1)+tonumber(hs2)+tonumber(hs3)+tonumber(hs4)+tonumber(hs5) }
										end
									end
								end
							else
								weaponstats[tonumber(id)] = { [1]=0, [2]=0, [3]=0 }
							end
						else
							if tonumber(m) == 2 or tonumber(m) == 4 or tonumber(m) == 8 or tonumber(m) == 16 or tonumber(m) == 32 then
								for hits, shots, hs in string.gmatch(bla, "([%d]+) ([%d]+) [%d]+ [%d]+ ([%d]+) [^\n]+") do
									weaponstats[tonumber(id)] = { [1]=tonumber(hits), [2]=tonumber(shots), [3]=tonumber(hs) }
								end
							else
								weaponstats[tonumber(id)] = { [1]=0, [2]=0, [3]=0 }
							end
						end
					end
				end
			end
			if endplayerscnt == tblcount then
				eomap_done = true
				eomaptime = et.trap_Milliseconds() + 1000
			end
		end
        return(nil)
    end

    if text == "Exit: Timelimit hit.\n" or text == "Exit: Wolf EndRound.\n" then
    	local x = 0
	    for x=0,sv_maxclients-1 do
			local team = tonumber(et.gentity_get(x, "sess.sessionTeam"))
			if team == 1 or team == 2 then
				endplayers[x] = true
			end
		end
		for _ in pairs(endplayers) do
			tblcount = tblcount + 1
		end
        kendofmap = true
        for i = 0, sv_maxclients-1 do
            if killing_sprees[i] > 0 then
                checkKSpreeEnd(i)
            end
        end
        return(nil)
    end
end

function checkMultiKill (id, mod)
    local lvltime = et.trap_Milliseconds()
    if (lvltime - kmulti[id][1]) < 3000 then
        kmulti[id][2] = kmulti[id][2] + 1
        if mod==7 or mod==8 or mod==9 or mod==10 or mod==58 or mod==59 then
        	mkps[id][1] = mkps[id][1] + 1
        	if mkps[id][2] == 0 then
   	     	mkps[id][2] = lvltime
    		else
    			mkps[id][3] = et.trap_Milliseconds()
			end
        	if mkps[id][1] >= 3 then
	        	if mkps[id][1] >= topshots[id][14] then
	    	    	if mkps[id][1] > topshots[id][14] then
   	     			topshots[id][14] = mkps[id][1]
    					topshots[id][15] = mkps[id][3] - mkps[id][2]
    	    		elseif mkps[id][1] == topshots[id][14] then
    					if (mkps[id][3] - mkps[id][2]) < topshots[id][15] then
    						topshots[id][15] = mkps[id][3] - mkps[id][2]
    					end
     	   		end
     	   	end
     		end
        end

		if kmulti[id][2] == 2 then
			topshots[id][24] = topshots[id][24] + 1
        elseif kmulti[id][2] == 3 then
            topshots[id][17] = topshots[id][17] + 1
        elseif kmulti[id][2] == 6 then
            topshots[id][17] = topshots[id][17] + 1
        end
    else
        kmulti[id][2] = 1
        mkps[id][1] = 1
        mkps[id][2] = 0
        mkps[id][3] = 0
    end
    kmulti[id][1] = lvltime
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

function et_Obituary(victim, killer, mod)
    if gamestate == 0 then
        local v_teamid = et.gentity_get(victim, "sess.sessionTeam")
        local k_teamid = et.gentity_get(killer, "sess.sessionTeam")
        if (victim == killer) then -- suicide

            if mod == 33 or mod == 59 then
                    checkKSpreeEnd(victim)
                    if mod == 33 then
                	    death_sprees[victim] = death_sprees[victim] + 1
                    end
            end

            killing_sprees[victim] = 0
            if mod == 33 then
				deaths[victim] = deaths[victim] + 1
			end

        elseif (v_teamid == k_teamid) then -- team kill

            checkKSpreeEnd(victim)
            killing_sprees[victim] = 0
            --death_sprees[victim] = death_sprees[victim] + 1

        else -- nomal kill
            if killer ~= 1022 and killer ~= 1023 then -- no world / unknown kills

                killing_sprees[killer] = killing_sprees[killer] + 1
                death_sprees[victim] = death_sprees[victim] + 1

				vsstats[killer][victim] = vsstats[killer][victim] + 1
                kills[killer] = kills[killer] + 1
                deaths[victim] = deaths[victim] + 1
                worst_enemy[victim][killer] = worst_enemy[victim][killer] + 1
                easiest_prey[killer][victim] = easiest_prey[killer][victim] + 1 
                local posk = et.gentity_get(victim, "ps.origin")
			    local posv = et.gentity_get(killer, "ps.origin")
                local killdist = dist(posk, posv)

                checkMultiKill(killer, mod)

                checkKSpreeEnd(victim)
                checkDSpreeEnd(killer)

				-- most lightweapons kills
				if mod==6 or mod==7 or mod==8 or mod==9 or mod==10 or mod==12 or mod==45 or mod==53 or mod==54 or mod==55 or mod==56 then
					-- most pistol kills
					if mod==6 or mod==7 or mod==12 or mod==45 or mod==53 or mod==54 or mod==55 or mod==56 then
						topshots[killer][2] = topshots[killer][2] + 1
					end
					topshots[killer][1] = topshots[killer][1] + 1
				end
				-- most rifle kills
				if mod == 11 or mod == 50 or mod == 37 or mod == 38 then
					topshots[killer][3] = topshots[killer][3] + 1
				end
				-- most riflegrenade kills + farthest riflegrenade kill
				if mod == 39 or mod == 40 then
					topshots[killer][4] = topshots[killer][4] + 1
					if killdist > topshots[killer][16] then
						topshots[killer][16] = killdist
					end
				end
				-- most sniper kills
				if mod == 46 or mod == 51 then
					topshots[killer][5] = topshots[killer][5] + 1
				end
				-- most knife kills
				if mod == 5 or mod == 65 then
					topshots[killer][6] = topshots[killer][6] + 1
				end
				-- most air support kills
				if mod == 23 or mod == 26 then
					topshots[killer][7] = topshots[killer][7] + 1
				end
				-- most mine kills
				if mod == 41 then
					topshots[killer][8] = topshots[killer][8] + 1
				end
				-- most grenade kills
				if mod == 16 or mod == 18 then
					topshots[killer][9] = topshots[killer][9] + 1
				end
				-- most panzer kills/deaths
				if mod == 15 or mod == 64 then
					topshots[killer][10] = topshots[killer][10] + 1
					topshots[victim][12] = topshots[victim][12] + 1
				end
				-- most mortar kills/deaths
				if mod == 52 or mod == 63 then
					topshots[killer][11] = topshots[killer][11] + 1
					topshots[victim][13] = topshots[victim][13] + 1
				end
				-- most mg42 kills/deaths
				if mod == 1 or mod == 2 or mod == 3 or mod == 44 or mod == 62 then
					topshots[killer][18] = topshots[killer][18] + 1
					topshots[victim][19] = topshots[victim][19] + 1
				end
            else
                checkKSpreeEnd(victim)
                if killer ~= 1022 then
					death_sprees[victim] = death_sprees[victim] + 1
                end
            end
            killing_sprees[victim] = 0
            death_sprees[killer] = 0
        end
    end -- gamestate
end

function checkKSpreeEnd(id)
        if killing_sprees[id] >= 3 then
   	     if killing_sprees[id] > topshots[id][25] then
  	      	topshots[id][25] = killing_sprees[id]
	        end
        end
end

function checkDSpreeEnd(id)
        if death_sprees[id] >= 3 then
   	     if death_sprees[id] > topshots[id][26] then
  	      	topshots[id][26] = death_sprees[id]
	        end
        end
end

function et_RunFrame(levelTime)
    if math.fmod(levelTime, 500) ~= 0 then return end

    local ltm = et.trap_Milliseconds()
	if eomap_done then
	    if eomaptime < ltm then
		    eomap_done = false
			topshots_f(-2)
	    end
	end
end

function et_ClientBegin(id)
    local team = tonumber(et.gentity_get(id, "sess.sessionTeam"))
    if team == 1 then
    	axis_time[id] = et.trap_Milliseconds()
    elseif team == 2 then
    	allies_time[id] = et.trap_Milliseconds()
    end
end

function et_ClientSpawn(id, revived)
	killing_sprees[id] = 0
	if revived ~= 1 then
		local team = tonumber(et.gentity_get(id, "sess.sessionTeam"))
		if team == 1 and axis_time[id] == 0 then
			axis_time[id] = et.trap_Milliseconds()
		elseif team == 2 and allies_time[id] == 0 then
			allies_time[id] = et.trap_Milliseconds()
		elseif team == 3 then
			axis_time[id] = 0
			allies_time[id] = 0
		end
	end
end

function et_ClientDisconnect(id)
    killing_sprees[id] = 0
    death_sprees[id] = 0
    topshots[id] = { [1]=0, [2]=0, [3]=0, [4]=0, [5]=0, [6]=0, [7]=0, [8]=0, [9]=0, [10]=0, [11]=0, [12]=0, [13]=0, [14]=0, [15]=0, [16]=0, [17]=0, [18]=0, [19]=0, [20]=0, [21]=0, [22]=0, [23]=0, [24]=0, [25]=0, [26]=0, [27]=0, [28]=0 }
    axis_time[id] = 0
    allies_time[id] = 0
    mkps[id] = { [1]=0, [2]=0, [3]=0 }
    vsstats[id]={[0]=0,[1]=0,[2]=0,[3]=0,[4]=0,[5]=0,[6]=0,[7]=0,[8]=0,[9]=0,[10]=0,[11]=0,[12]=0,[13]=0,[14]=0,[15]=0,[16]=0,[17]=0,[18]=0,[19]=0,[20]=0,[21]=0,[22]=0,[23]=0,[24]=0,[25]=0,[26]=0,[27]=0,[28]=0,[29]=0,[30]=0,[31]=0,[32]=0,[33]=0,[34]=0,[35]=0,[36]=0,[37]=0,[38]=0,[39]=0,[40]=0,[41]=0,[42]=0,[43]=0,[44]=0,[45]=0,[46]=0,[47]=0,[48]=0,[49]=0,[50]=0,[51]=0,[52]=0,[53]=0,[54]=0,[55]=0,[56]=0,[57]=0,[58]=0,[59]=0,[60]=0,[61]=0,[62]=0,[63]=0}
    vsstats_kills[id]={[0]=0,[1]=0,[2]=0,[3]=0,[4]=0,[5]=0,[6]=0,[7]=0,[8]=0,[9]=0,[10]=0,[11]=0,[12]=0,[13]=0,[14]=0,[15]=0,[16]=0,[17]=0,[18]=0,[19]=0,[20]=0,[21]=0,[22]=0,[23]=0,[24]=0,[25]=0,[26]=0,[27]=0,[28]=0,[29]=0,[30]=0,[31]=0,[32]=0,[33]=0,[34]=0,[35]=0,[36]=0,[37]=0,[38]=0,[39]=0,[40]=0,[41]=0,[42]=0,[43]=0,[44]=0,[45]=0,[46]=0,[47]=0,[48]=0,[49]=0,[50]=0,[51]=0,[52]=0,[53]=0,[54]=0,[55]=0,[56]=0,[57]=0,[58]=0,[59]=0,[60]=0,[61]=0,[62]=0,[63]=0}
    vsstats_deaths[id]={[0]=0,[1]=0,[2]=0,[3]=0,[4]=0,[5]=0,[6]=0,[7]=0,[8]=0,[9]=0,[10]=0,[11]=0,[12]=0,[13]=0,[14]=0,[15]=0,[16]=0,[17]=0,[18]=0,[19]=0,[20]=0,[21]=0,[22]=0,[23]=0,[24]=0,[25]=0,[26]=0,[27]=0,[28]=0,[29]=0,[30]=0,[31]=0,[32]=0,[33]=0,[34]=0,[35]=0,[36]=0,[37]=0,[38]=0,[39]=0,[40]=0,[41]=0,[42]=0,[43]=0,[44]=0,[45]=0,[46]=0,[47]=0,[48]=0,[49]=0,[50]=0,[51]=0,[52]=0,[53]=0,[54]=0,[55]=0,[56]=0,[57]=0,[58]=0,[59]=0,[60]=0,[61]=0,[62]=0,[63]=0}
    worst_enemy[id]={[0]=0,[1]=0,[2]=0,[3]=0,[4]=0,[5]=0,[6]=0,[7]=0,[8]=0,[9]=0,[10]=0,[11]=0,[12]=0,[13]=0,[14]=0,[15]=0,[16]=0,[17]=0,[18]=0,[19]=0,[20]=0,[21]=0,[22]=0,[23]=0,[24]=0,[25]=0,[26]=0,[27]=0,[28]=0,[29]=0,[30]=0,[31]=0,[32]=0,[33]=0,[34]=0,[35]=0,[36]=0,[37]=0,[38]=0,[39]=0,[40]=0,[41]=0,[42]=0,[43]=0,[44]=0,[45]=0,[46]=0,[47]=0,[48]=0,[49]=0,[50]=0,[51]=0,[52]=0,[53]=0,[54]=0,[55]=0,[56]=0,[57]=0,[58]=0,[59]=0,[60]=0,[61]=0,[62]=0,[63]=0}
    easiest_prey[id]={[0]=0,[1]=0,[2]=0,[3]=0,[4]=0,[5]=0,[6]=0,[7]=0,[8]=0,[9]=0,[10]=0,[11]=0,[12]=0,[13]=0,[14]=0,[15]=0,[16]=0,[17]=0,[18]=0,[19]=0,[20]=0,[21]=0,[22]=0,[23]=0,[24]=0,[25]=0,[26]=0,[27]=0,[28]=0,[29]=0,[30]=0,[31]=0,[32]=0,[33]=0,[34]=0,[35]=0,[36]=0,[37]=0,[38]=0,[39]=0,[40]=0,[41]=0,[42]=0,[43]=0,[44]=0,[45]=0,[46]=0,[47]=0,[48]=0,[49]=0,[50]=0,[51]=0,[52]=0,[53]=0,[54]=0,[55]=0,[56]=0,[57]=0,[58]=0,[59]=0,[60]=0,[61]=0,[62]=0,[63]=0}
	kills[id] = 0
    deaths[id] = 0
    local j = 0
	for j=0,sv_maxclients-1 do
		vsstats[j][id] = 0
		worst_enemy[j][id] = 0
		easiest_prey[j][id] = 0
		vsstats_kills[j][id] = 0
		vsstats_deaths[j][id] = 0
	end
end

--- Sends a nice table to a client.
-- @param id        client slot
-- @param columns   {name = "column header title", align = "right/left/ommit"}, ...
-- @param rows      { { x0, x1, ...} { ... } ... }
-- @param separator print separators between rows?
function send_table(id, columns, rows, separator)

    local lens = {}

    --table.foreach(columns, function(index, column)
        --lens[index] = string.len(et.Q_CleanStr(column.name))
    --end)

	for index, column in pairs(columns) do
		lens[index] = string.len(et.Q_CleanStr(column.name))
	end

    --table.foreach(rows, function(_, row)
    for _, row in pairs(rows) do
        
        --table.foreach(row, function(index, value)
        for index, value in pairs(row) do
            
            local len = string.len(et.Q_CleanStr(value))
            
            if lens[index] < len then
                lens[index] = len
            end

        --end)
        end

    --end)
    end

    local width = 1

    --table.foreach(lens, function(_, len)
        --width = width + len + 3 -- 3 = padding around the value and cell separator
    --end)
    for _, len in pairs(lens) do
		width = width + len + 3 -- 3 = padding around the value and cell separator
	end

    -- Header separator
    et.trap_SendServerCommand(id, "chat \"^7" .. string.rep('-', width) .. "\"")
    et.G_LogPrint("Endstats: " .. string.rep('-', width) .. "\"\n")

    -- Column names
    local row = "^7|"

    --table.foreach(columns, function(index, column)
        --row = row .. " " .. column.name .. string.rep(' ', lens[index] - string.len(et.Q_CleanStr(column.name))) .. " |"
    --end)
    for index, column in pairs(columns) do
		row = row .. " " .. column.name .. string.rep(' ', lens[index] - string.len(et.Q_CleanStr(column.name))) .. " |"
	end
    et.trap_SendServerCommand(id, "chat \"" .. row .. "\"")
    et.G_LogPrint("Endstats: " .. row .. "\"\n")

    if #rows > 0 then

        -- Data separator
        et.trap_SendServerCommand(id, "chat \"^7" .. string.rep('-', width) .. "\"")
        et.G_LogPrint("Endstats: " .. string.rep('-', width) .. "\"\n")

        -- Rows
        --table.foreach(rows, function(_, r)
        for _, r in pairs(rows) do

            local row = "^7|"

            --table.foreach(r, function(index, value)
            for index, value in pairs(r) do
                if columns[index].align == "right" then
                    row = row .. " " .. string.rep(' ', lens[index] - string.len(et.Q_CleanStr(value))) .. value .. " ^7|"
                else
                    row = row .. " " .. value .. string.rep(' ', lens[index] - string.len(et.Q_CleanStr(value))) .. " ^7|"
                end
            --end)
            end

            et.trap_SendServerCommand(id, "chat \"" .. row .. "\"")                      -- values
            et.G_LogPrint("Endstats: " .. row .. "\"\n")

            if separator then
                et.trap_SendServerCommand(id, "chat \"^7" .. string.rep('-', width) .. "\"") -- separator
                et.G_LogPrint("Endstats: " .. string.rep('-', width) .. "\"\n")
            end

        --end)
        end

    end

    -- Bottom line
    if not separator then
        et.trap_SendServerCommand(id, "chat \"^7" .. string.rep('-', width) .. "\"")
        et.G_LogPrint("Endstats: " .. string.rep('-', width) .. "\"\n")
    end

end
