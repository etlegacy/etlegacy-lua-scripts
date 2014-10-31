--[[
	Author: Jan Šimek [Radegast]
	Version 0.1
	License: MIT
	Released on 09.02.2014
	Website: http://www.etlegacy.com
	Mod: intended for the Legacy mod

	Description: lightweight user administration suite
]]--

package.path = "./" .. et.trap_Cvar_Get("fs_game") .. "/ladm/?.lua;" .. package.path

-- load the config file
dofile ("./" .. et.trap_Cvar_Get("fs_game") .. "/ladm/ladm.cfg")

require "core/db"
require "core/user"
require "core/commands"

function et_InitGame(levelTime, randomSeed, restart)
	-- name of this module
	et.RegisterModname ( "Lightweight administration suite for the Legacy mod" )
	
	-- init db on game start
	db_init()
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

	local player = getPlayerByGUID(guid)
	
	if not player then
		-- First time we see this player
		et.trap_SendServerCommand (cno, "cpm \"" .. "Welcome, " .. name .. "^7! You are playing on an XP save server.\n\"")
		cur = assert (con:execute(string.format([[
			INSERT INTO %susers VALUES (
				'%s', '%s', '%s', '%s', 0, 0, 0, 0, 0, 0, 0, 0
			)]], dbprefix, guid, name, os.date("%Y-%m-%d %H:%M:%S"), os.date("%Y-%m-%d %H:%M:%S"))))
	else
		et.trap_SendServerCommand (cno, "cpm \"" .. "Welcome back, " .. name .. "^7! Your last connection was on " .. player.last_seen .. "\n\"") -- in db: player.name

		et.G_XP_Set (cno, player.xp_battlesense,  BATTLESENSE,  0) 
		et.G_XP_Set (cno, player.xp_engineering,  ENGINEERING,  0) 
		et.G_XP_Set (cno, player.xp_medic,        MEDIC,        0) 
		et.G_XP_Set (cno, player.xp_fieldops,     FIELDOPS,     0) 
		et.G_XP_Set (cno, player.xp_lightweapons, LIGHTWEAPONS, 0) 
		et.G_XP_Set (cno, player.xp_heavyweapons, HEAVYWEAPONS, 0) 
		et.G_XP_Set (cno, player.xp_covertops,    COVERTOPS,    0)
		
		--et.G_Print (name .. "'s current XP levels:\n")
		--for id, skill in pairs(skills) do 
		--	et.G_Print ("| " .. skill .. ": " .. et.gentity_get (cno, "sess.skillpoints", id) .. " XP |\n")
		--end
	end
end -- et_ClientBegin

function et_ClientDisconnect(cno)
	saveXP(cno)
end -- et_ClientDisconnect

function et_ClientCommand(cno, cmd)
	for cmd_name, cmd_function in pairs(Command) do
		-- string.lower(et.trap_Argv(0))
		if cmd == cmd_name then
			cmd_function(cno, cmd)
			return 1
		end
	end
end -- et_ClientCommand

-- testing
function et_ConsoleCommand(cmd)
	et_ClientCommand(999, cmd)
end -- et_ConsoleCommand