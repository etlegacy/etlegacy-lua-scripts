--[[
	Author: Jan Šimek [Radegast]
	License: MIT
	Released on 23.11.2013
	Website: http://www.etlegacy.com
	Mod: compatible with Legacy, but might also work with other mods

	Description: this script saves users' experience points into 
	             a database and thus preserves them between connections
]]--

-- Lua module version
local version = "0.2"

-- load sqlite driver (or mysql..)
local luasql = require "luasql.sqlite3"

local env -- environment object
local con -- database connection
local cur -- cursor

-- skill identifiers
local BATTLESENSE 	= 0
local ENGINEERING 	= 1
local MEDIC 		= 2
local FIELDOPS 		= 3
local LIGHTWEAPONS	= 4
local HEAVYWEAPONS	= 5
local COVERTOPS		= 6

local skills = {}
skills[BATTLESENSE]		= "Battlesense"
skills[ENGINEERING]		= "Engineering"
skills[MEDIC]			= "Medic"
skills[FIELDOPS]		= "Field ops"
skills[LIGHTWEAPONS]	= "Light weapons"
skills[HEAVYWEAPONS]	= "Heavy weapons"
skills[COVERTOPS]		= "Covert ops"

-- database  helper function  
-- returns database rows matching sql_statement 
function rows(connection, sql_statement)  
	local cursor =  assert (connection:execute  (sql_statement)) 
	return function () 
		return cursor:fetch() 
	end 
end -- rows

-- con:prepare with bind_names should be used to prevent sql injections
-- but it doesn't work on my version of luasql
function validateGUID(cno, guid)
	-- allow only alphanumeric characters in guid
	if(string.match(guid, "%W")) then
		-- Invalid characters detected. We should probably drop this client
		et.G_Print("^3WARNING: (XP Save) user with ID " .. cno .. " has an invalid GUID: " .. guid .. "\n")
		et.trap_SendServerCommand (cno, "cpm \"" .. "^3Your XP won't be saved because you have an invalid GUID!\n\"")
		return false
	end
	
	return true
end

-- saves XP values of a player with id 'cno' into sqlite database
function saveXP(cno)
	local name = et.Info_ValueForKey( et.trap_GetUserinfo( cno ), "name" )
	local guid = et.Info_ValueForKey( et.trap_GetUserinfo( cno ), "cl_guid" )
	
	if not validateGUID(cno, guid) then return end
	
	cur = assert (con:execute(string.format("SELECT * FROM users WHERE guid='%s' LIMIT 1", guid)))
	local player = cur:fetch({}, 'a')
	
	if not player then
		-- This should not happen	
		et.G_Print ("^1ERROR: (XP Save) user was not found in the database!\n")
		return
	else
		et.trap_SendServerCommand (cno, "cpm \"" .. "^3See you again soon, ^7" .. name .. "\n\"")
		--for id, name in pairs(skills) do et.G_Print (name .. ": " .. et.gentity_get (cno, "sess.skillpoints", id) .. " XP\n") end
		
		cur = assert (con:execute(string.format([[UPDATE users SET 
			last_seen='%s', 
			xp_battlesense='%s',
			xp_engineering='%s', 
			xp_medic='%s', 
			xp_fieldops='%s', 
			xp_lightweapons='%s', 
			xp_heavyweapons='%s', 
			xp_covertops='%s' 
			WHERE guid='%s']], 
			os.date("%Y-%m-%d %H:%M:%S"), 
			et.gentity_get (cno, "sess.skillpoints", BATTLESENSE), 
			et.gentity_get (cno, "sess.skillpoints", ENGINEERING), 
			et.gentity_get (cno, "sess.skillpoints", MEDIC), 
			et.gentity_get (cno, "sess.skillpoints", FIELDOPS), 
			et.gentity_get (cno, "sess.skillpoints", LIGHTWEAPONS), 
			et.gentity_get (cno, "sess.skillpoints", HEAVYWEAPONS), 
			et.gentity_get (cno, "sess.skillpoints", COVERTOPS), 
			guid
		)))
	end
end

-- init db on game start
function et_InitGame(levelTime, randomSeed, restart)
	-- register name of this module
	et.RegisterModname ("XP Save Module " .. version)
	
	-- create environement object
	env = assert (luasql.sqlite3())

	-- connect to database
	con = assert (env:connect("xpsave.sqlite")) 
	
	--cur = assert (con:execute("DROP TABLE users"))
	
	cur = assert (con:execute[[
		CREATE TABLE IF NOT EXISTS users(
			guid VARCHAR(64),
			last_seen VARCHAR(64),

			xp_battlesense REAL,
			xp_engineering REAL,
			xp_medic REAL,
			xp_fieldops REAL,
			xp_lightweapons REAL,
			xp_heavyweapons REAL,
			xp_covertops REAL,	

			UNIQUE (guid)
		)
	]])
	
	cur = assert (con:execute("SELECT COUNT(*) FROM users"))
	
	et.G_Print("XP Save: there are " .. tonumber(cur:fetch(row, 'a')) .. " users in the database\n")
	
	--et.G_Print ("^4List of users in XP Save database:\n")
	--for guid, date in rows (con, "SELECT * FROM users") do
	--	et.G_Print (string.format ("\tGUID %s was last seen on %s\n", guid, date))
	--end
end -- et_InitGame

function et_ShutdownGame(restart)
	local cno = 0
	local maxclients = tonumber(et.trap_Cvar_Get("sv_maxclients"))

	-- iterate through clients and save their XP
	while cno < maxclients do
		local cs = et.trap_GetConfigstring(tonumber(et.CS_PLAYERS) + cno)

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
		et.trap_SendServerCommand (cno, "cpm \"" .. "^3Welcome, ^7" .. name .. "^3! You are playing on an XP save server\n\"")
		cur = assert (con:execute(string.format("INSERT INTO users VALUES ('%s', '%s', 0, 0, 0, 0, 0, 0, 0)", guid, os.date("%Y-%m-%d %H:%M:%S"))))
	else
		et.trap_SendServerCommand (cno, "cpm \"" .. "^3Welcome back, ^7" .. name .. "^3! Your last connection was on " .. player.last_seen .. "\n\"") -- in db: player.name

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
