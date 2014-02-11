--[[
	Author: Jan Šimek [Radegast]
	Version 0.1
	License: MIT
	Released on 09.02.2014
	Website: http://www.etlegacy.com
	Mod: intended for the Legacy mod

	Description: lightweight user administration suite
]]--

-- load the config file
dofile "ladm.cfg"

require "core/db"

db_init()

function et_InitGame(levelTime, randomSeed, restart)
	-- name of this module
	et.RegisterModname ( "Lightweight administration suite for the Legacy mod" )
	
	-- init db on game start


end -- et_InitGame

function et_ShutdownGame(restart)
	local cno = 0
	local maxclients = tonumber(et.trap_Cvar_Get("sv_maxclients"))

	-- iterate through clients and save their XP
	while cno < maxclients do
		local cs = et.trap_GetConfigstring(et.CS_PLAYERS + cno)

		if not cs or cs == "" then break end
		
		saveXP(cno)
		cno = cno + 1
	end
	
	-- clean up 
	cur:close() 
	con:close() 
	env:close() 
end -- et_ShutdownGame

-- called when a client enters the game world
function et_ClientBegin(cno)
	local name = et.Info_ValueForKey( et.trap_GetUserinfo( cno ), "name" ) 
	local guid = et.Info_ValueForKey( et.trap_GetUserinfo( cno ), "cl_guid" )
	
	if not validateGUID(cno, guid) then return end

	cur = assert (con:execute(string.format("SELECT * FROM users WHERE guid='%s'", guid)))
	local player = cur:fetch({}, 'a')
	
	if not player then
		-- First time we see this player
		et.trap_SendServerCommand (cno, "cpm \"" .. "Welcome, " .. name .. "^7! You are playing on an XP save server.\n\"")
		cur = assert (con:execute(string.format("INSERT INTO users VALUES ('%s', '%s', '%s', 0, 0, 0, 0, 0, 0, 0)", guid, os.date("%Y-%m-%d %H:%M:%S"), os.date("%Y-%m-%d %H:%M:%S"))))
	else
		et.trap_SendServerCommand (cno, "cpm \"" .. "Welcome back, " .. name .. "^7! Your last connection was on " .. player.last_seen .. "\n\"") -- in db: player.name

		--et.G_Print ("Loading XP from database: " .. player.xp_battlesense .. " | " .. player.xp_engineering .. " | " .. player.xp_medic .. " | " .. player.xp_fieldops .. " | " .. player.xp_lightweapons .. " | " .. player.xp_heavyweapons .. " | " .. player.xp_covertops .. "\n\n")
		
		et.G_XP_Set (cno, player.xp_battlesense, BATTLESENSE, 0) 
		et.G_XP_Set (cno, player.xp_engineering, ENGINEERING, 0) 
		et.G_XP_Set (cno, player.xp_medic, MEDIC, 0) 
		et.G_XP_Set (cno, player.xp_fieldops, FIELDOPS, 0) 
		et.G_XP_Set (cno, player.xp_lightweapons, LIGHTWEAPONS, 0) 
		et.G_XP_Set (cno, player.xp_heavyweapons, HEAVYWEAPONS, 0) 
		et.G_XP_Set (cno, player.xp_covertops, COVERTOPS, 0)
		
		et.G_Print (name .. "'s current XP levels:\n")
		for id, skill in pairs(skills) do 
			et.G_Print ("\t" .. skill .. ": " .. et.gentity_get (cno, "sess.skillpoints", id) .. " XP\n") 
		end
	end
end -- et_ClientBegin

function et_ClientDisconnect(cno)
	saveXP(cno)
end -- et_ClientDisconnect
