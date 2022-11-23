-- x0rnn: added dynamite "sudden death" mode
-- modified Quake 3 sudden death sound: https://github.com/x0rnn/etpro/blob/master/lua/sudden_death.wav

---------------------------------
------- Dynamite counter --------
-------  By Necromancer  --------
-------    5/04/2009     --------
------- www.usef-et.org  --------
---------------------------------

SHOW = 0
-- 0 means disable timer
-- 1 means only the team that planted the dyno
-- 2 means everyone

-- This script can be freely used and modified as long as the original author\s are mentioned (and their homepage: www.usef-et.org)

mapname = ""
gametype = 0
mapstarted = false
paused = false
mapstart_time = 0
paused_time = 0
unpaused_time = 0
stuck_time = 0
intervals = {[1]=0, [2]=0}
sudden_death = false
first_obj = false
sw_flag = false

-- Constans
COLOR = {}
COLOR.PLACE = '^8'
COLOR.TEXT = '^w'
COLOR.TIME = '^8' -- this constat is changing in the print_message() function
 
CHAT = "chat" 
POPUP = "legacy"

timer = {}

OLD = os.time()

function et_InitGame(levelTime, randomSeed, restart)
    et.RegisterModname("suddendeath.lua" .. et.FindSelf())
	mapname = string.lower(et.trap_Cvar_Get("mapname"))
	gametype = tonumber(et.trap_Cvar_Get("g_gametype"))
	if tonumber(et.trap_Cvar_Get("g_currentRound")) == 1 then
		sw_flag = true
	end
end

function et_RunFrame( levelTime )
	current = os.time()
	for dyno, temp in pairs(timer) do
		if timer[dyno]["time"] - current >= 0 then
			for key,temp in pairs(timer[dyno]) do
				if type(key) == "number" then
					if timer[dyno]["time"] - current == key then
						send_print(timer,dyno,key)
						timer[dyno][key] = nil	
						--et.G_LogPrint("dynamite key deleted: " .. dyno .." key: " .. key .. "\n")
					end
				end
			end

		else
			--et.G_LogPrint("dynamite out: " .. dyno .. "\n")
			place_destroyed(timer[dyno]["place"])
			--timer[dyno] = nil
		end
	end

	if math.fmod(levelTime, 1000) == 0 then
		local gamestate = tonumber(et.trap_Cvar_Get("gamestate"))
		if gamestate == 0 then
			if mapstarted == false then
				mapstart_time = et.trap_Milliseconds()
				mapstarted = true
			else
				if paused == true then
					local cs = et.trap_GetConfigstring(11)
					if intervals[1] == 0 then
						intervals[1] = cs
					elseif intervals[1] ~= 0 then
						if intervals[2] == 0 then
							intervals[2] = cs
						elseif intervals[2] ~= 0 then
							intervals[1] = intervals[2]
							intervals[2] = cs
							if intervals[1] == intervals[2] then
								paused = false
								unpaused_time = et.trap_Milliseconds() - 1000
								stuck_time = unpaused_time - paused_time + stuck_time
								intervals[1] = 0
								intervals[2] = 0
							end
						end
					end
				end
			end
		end
	end
end

function et_ConsoleCommand()
	local arg = et.trap_Argv(1)
	if arg == "pause" then
		paused = true
		paused_time = et.trap_Milliseconds()
	end
	if arg == "unpause" then
		paused = false
		unpaused_time = et.trap_Milliseconds()
		stuck_time = unpaused_time - paused_time + stuck_time + 10000
	end
	return(0)
end

function place_destroyed(place) -- removes any dynamties that were planted on this objective
	for dynamite, temp in pairs(timer) do
		if timer[dynamite]["place"] == place then
			timer[dynamite] = nil
		end
	end
end

function send_print(timer,dyno,ttime)
	if SHOW == 0 then return end
	if SHOW == 1 then
		for player=0, tonumber(et.trap_Cvar_Get("sv_maxclients"))-1, 1 do
			if et.gentity_get(player,"sess.sessionTeam") == timer[dyno]["team"] then
				print_message(player, ttime, timer[dyno]["place"])
			end
		end
	else
		print_message(-1, ttime, timer[dyno]["place"])
	end
end

function print_message(slot, ttime, place)
	if ttime > 3 then
		COLOR.TIME = '^8'
	else
		COLOR.TIME = '^1'
	end

	if ttime == -1 then
		et.trap_SendServerCommand( slot , string.format('%s \"%s"\n',CHAT, COLOR.TEXT .. "Dynamite planted at " .. COLOR.PLACE .. place))
	elseif ttime == -2 then
		et.trap_SendServerCommand( slot , string.format('%s \"%s"\n',CHAT, COLOR.TEXT .. "Dynamite defused at " .. COLOR.PLACE .. place))
	elseif ttime > 0 then
		et.trap_SendServerCommand( slot , string.format('%s \"%s"\n',CHAT, COLOR.TEXT .. "Dynamite at " .. COLOR.PLACE .. place .. COLOR.TEXT .. " exploding in " .. COLOR.TIME ..ttime .. COLOR.TEXT .. " seconds!"))
	end
end

function et_Print( text )
	--legacy popup: axis planted "the Old City MG Nest"
	start,stop = string.find(text, POPUP .. " popup:",1,true) -- check that its not any player print, trying to manipulate the dyno counter
	if start and stop then
		start,stop,team,plant = string.find(text, POPUP .. " popup: (%S+) planted \"([^%\"]*)\"")
		if start and stop then -- dynamite planted
			if team == "axis" then team = 1 
			else team = 2 end
			index = #timer+1
			timer[index] = {}
			timer[index]["team"] = team
			timer[index]["place"] = plant
			timer[index]["time"] = os.time() +30

			timer[index][20] = true
			timer[index][10] = true
			timer[index][5] = true
			timer[index][3] = true
			timer[index][2] = true
			timer[index][1] = true
			timer[index][0] = true

			print_message(-1, -1, timer[index]["place"])
			--et.G_LogPrint("dynamite set: " .. index .. "\n")

			if gametype ~= 3 or (gametype == 3 and sw_flag == false) then
				if mapname == "battery" or mapname == "sw_battery" or mapname == "fueldump" or mapname == "braundorf_b4" or mapname == "mp_sub_rc1" then
					if plant == "the Gun Controls" or plant == "the Fuel Dump" or plant == "the bunker controls" or plant == "the Axis Submarine" then
						local timelimit = et.trap_Cvar_Get("timelimit") * 1000 * 60 - 2000 --counts 2 seconds more for some reason...
						local timeleft
						timeleft = timelimit - ((et.trap_Milliseconds() - stuck_time) - mapstart_time)
						if timeleft < 30000 then
							sudden_death = true
							et.G_LogPrint("LUA event: " .. mapname .. " Dynamite sudden death activated!\n")
							et.trap_SendServerCommand(-1, "chat \"^1Sudden Death mode is activated! Defuse the dynamite or lose!\"")
							et.trap_Cvar_Set("timelimit", et.trap_Cvar_Get("timelimit") + 0.5)
							et.G_globalSound("sound/misc/sudden_death.wav")
							for j=0, tonumber(et.trap_Cvar_Get("sv_maxclients"))-1 do
								local team = tonumber(et.gentity_get(j, "sess.sessionTeam"))
								if team == 2 then
									if et.gentity_get(j,"sess.PlayerType") == 2 then
										local health = tonumber(et.gentity_get(j, "health"))
										if health > 0 then
											et.gentity_set(j, "ps.ammoclip", 15, 0)
											et.trap_SendServerCommand(j, "chat \"^1Sudden Death mode is activated! Can't plant additional dynamites!\"")
										end
									end
								end
							end
						end
					end
				end
				if mapname == "sw_oasis_b3" or mapname == "oasis" or mapname == "tc_base" or mapname == "erdenberg_t2" then
					if first_obj == true then
						if plant == "the South PAK 75mm Gun" or plant == "the North PAK 75mm Gun" or plant == "the South Anti-Tank Gun" or plant == "the North Anti-Tank Gun" or plant == "the West Flak88" or plant == "the East Flak88" or plant == "the South Radar [02]" or plant == "the North Radar [01]" then
							local timelimit = et.trap_Cvar_Get("timelimit") * 1000 * 60 - 2000 --counts 2 seconds more for some reason...
							local timeleft
							timeleft = timelimit - ((et.trap_Milliseconds() - stuck_time) - mapstart_time)
							if timeleft < 30000 then
								sudden_death = true
								et.G_LogPrint("LUA event: " .. mapname .. " Dynamite sudden death activated!\n")
								et.trap_SendServerCommand(-1, "chat \"^1Sudden Death mode is activated! Defuse the dynamite or lose!\"")
								et.trap_Cvar_Set("timelimit", et.trap_Cvar_Get("timelimit") + 0.5)
								et.G_globalSound("sound/misc/sudden_death.wav")
								for j=0, tonumber(et.trap_Cvar_Get("sv_maxclients"))-1 do
									local team = tonumber(et.gentity_get(j, "sess.sessionTeam"))
									if team == 2 then
										if et.gentity_get(j,"sess.PlayerType") == 2 then
											local health = tonumber(et.gentity_get(j, "health"))
											if health > 0 then
												et.gentity_set(j, "ps.ammoclip", 15, 0)
												et.trap_SendServerCommand(j, "chat \"^1Sudden Death mode is activated! Can't plant additional dynamites!\"")
											end
										end
									end
								end
							end
						end
					end
				end
			end
		end

		start,stop,team,plant = string.find(text, POPUP .. " popup: (%S+) defused \"([^%\"]*)\"")
		if start and stop then -- dynamite defused
			if team == "axis" then team = 1 
			else team = 2 end

			if gametype ~= 3 or (gametype == 3 and sw_flag == false) then
				if mapname == "battery" or mapname == "sw_battery" or mapname == "fueldump" or mapname == "braundorf_b4" or mapname == "mp_sub_rc1" then
					if plant == "the Gun Controls" or plant == "the Fuel Dump" or plant == "the bunker controls" or plant == "the Axis Submarine" then
						if sudden_death == true then
							local timelimit = et.trap_Cvar_Get("timelimit") * 1000 * 60 - 2000 --counts 2 seconds more for some reason...
							local timeleft
							timeleft = timelimit - ((et.trap_Milliseconds() - stuck_time) - mapstart_time)
							if timeleft - 30000 > 3750 then
								local t = ((timeleft - 30000) / 1000) / 60
								et.trap_Cvar_Set("timelimit", et.trap_Cvar_Get("timelimit") - t)
							else
								et.trap_Cvar_Set("timelimit", 0.0001)
								et.G_LogPrint("LUA event: " .. mapname .. " Dynamite sudden death, Axis defused!\n")
							end
						end
					end
				end
				if mapname == "sw_oasis_b3" or mapname == "oasis" or mapname == "tc_base" or mapname == "erdenberg_t2" then
					if plant == "the South PAK 75mm Gun" or plant == "the North PAK 75mm Gun" or plant == "the South Anti-Tank Gun" or plant == "the North Anti-Tank Gun" or plant == "the West Flak88" or plant == "the East Flak88" or plant == "the South Radar [02]" or plant == "the North Radar [01]" then
						if sudden_death == true then
							local timelimit = et.trap_Cvar_Get("timelimit") * 1000 * 60 - 2000 --counts 2 seconds more for some reason...
							local timeleft
							timeleft = timelimit - ((et.trap_Milliseconds() - stuck_time) - mapstart_time)
							if timeleft - 30000 > 3750 then
								local t = ((timeleft - 30000) / 1000) / 60
								et.trap_Cvar_Set("timelimit", et.trap_Cvar_Get("timelimit") - t)
							else
								et.trap_Cvar_Set("timelimit", 0.0001)
								et.G_LogPrint("LUA event: " .. mapname .. " Dynamite sudden death, Axis defused!\n")
							end
						end
					end
				end
			end

			for index,temp in pairs(timer) do
				if timer[index]["place"] == plant then
					print_message(-1, -2, timer[index]["place"])
					timer[index] = nil
					--et.G_LogPrint("dynamite removed: " .. index .. "\n")
					return
				end
			end
		end
	end
	--legacy announce: "Allied team has destroyed the South Anti-Tank Gun!"
	start2,stop2 = string.find(text, POPUP .. " announce:",1,true) -- check that its not any player print, trying to manipulate the dyno counter
	if start2 and stop2 then
		start2,stop2,plant = string.find(text, POPUP .. " announce: \"([^%\"]*)\"")
		if start2 and stop2 then -- dynamite planted
			if gametype ~= 3 or (gametype == 3 and sw_flag == false) then
				if mapname == "oasis" or mapname == "sw_oasis_b3" then
					if plant == "Allied team has destroyed the South Anti-Tank Gun!" or plant == "Allied team has destroyed the North Anti-Tank Gun!" then
						if first_obj == false then
							first_obj = true
						else
							et.G_LogPrint("LUA event: " .. mapname .. " Dynamite sudden death, Allies win!\n")
						end
					end
				elseif mapname == "erdenberg_t2" then
					if plant == "The West Flak88 has been destroyed!" or plant == "The East Flak88 has been destroyed!" then
						if first_obj == false then
							first_obj = true
						else
							et.G_LogPrint("LUA event: " .. mapname .. " Dynamite sudden death, Allies win!\n")
						end
					end
				elseif mapname == "tc_base" then
					if plant == "Allied team has disabled the South Radar!" or plant == "Allied team has disabled the North Radar!" then
						if first_obj == false then
							first_obj = true
						else
							et.G_LogPrint("LUA event: " .. mapname .. " Dynamite sudden death, Allies win!\n")
						end
					end
				end
			end
		end
	end
end

function et_ClientSpawn(id, revived)
	if revived ~= 1 then
		if sudden_death == true then
			local team = et.gentity_get(id, "sess.sessionTeam")
			if team == 2 then
				if et.gentity_get(id,"sess.PlayerType") == 2 then
					et.gentity_set(id,"ps.ammoclip", 15, 0)
				end
			end
		end
	end
end
