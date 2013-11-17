--[[
	Author: Jan Šimek [Radegast]
	Version 0.1
	License: MIT
	Released on 17.11.2013
	Website: http://www.etlegacy.com

	Description: this script saves users' experience points into 
	             a database and thus preserves them between connections
]]--

-- load sqlite driver (or mysql..)
luasql = require "luasql.sqlite3"

local env -- environment object
local con -- database connection
local cur -- cursor

local skills = {}
skills[0] = "Battlesense"
skills[1] = "Engineering"
skills[2] = "Medic"
skills[3] = "Field ops"
skills[4] = "Light weapons"
skills[5] = "Heavy weapons"
skills[6] = "Covert ops"

-- database  helper function  
-- returns database rows matching sql_statement 
function rows(connection, sql_statement)  
	local cursor =  assert (connection:execute  (sql_statement)) 
	return function () 
		return cursor:fetch() 
	end 
end -- rows

-- init db on game start
function et_InitGame(levelTime, randomSeed, restart)
	-- name of this module
	et.RegisterModname ( "XP Save player database" )
	
	-- create environement object
	env = assert ( luasql.sqlite3() )

	-- connect to database
	con = assert ( env:connect( "xpsave.sqlite" ) ) 
	
	--cur = assert (con:execute( "DROP TABLE users" ))
	
	cur = assert ( con:execute[[
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
end -- et_InitGame

function et_ShutdownGame(restart) 
	-- clean up 
	cur:close() 
	con:close() 
	env:close() 
end -- et_ShutdownGame

-- called when a client enters the game world
function et_ClientBegin(cno)
	name = et.Info_ValueForKey( et.trap_GetUserinfo( cno ), "name" ) 
	guid = et.Info_ValueForKey( et.trap_GetUserinfo( cno ), "cl_guid" )
	
	cur = assert (con:execute(string.format("SELECT * FROM users WHERE guid='%s'", guid)))
	player = cur:fetch({}, 'a')
	
	if not player then
		-- First time we see this player
		et.trap_SendServerCommand (cno, "cpm \"" .. "Welcome, " .. name .. "!\n\"")
		cur = assert (con:execute(string.format("INSERT INTO users VALUES ('%s', '%s', 0, 0, 0, 0, 0, 0, 0)", guid, os.date("%Y-%m-%d %H:%M:%S"))))
	else
		et.trap_SendServerCommand (cno, "cpm \"" .. "Welcome back, " .. name .. "! Your last connection was on " .. player.last_seen .. "\n\"") -- in db: player.name

		--et.G_Print ("Loading XP from database: " .. player.xp_battlesense .. " | " .. player.xp_engineering .. " | " .. player.xp_medic .. " | " .. player.xp_fieldops .. " | " .. player.xp_lightweapons .. " | " .. player.xp_heavyweapons .. " | " .. player.xp_covertops .. "\n\n")

		et.G_XP_Set (cno, player.xp_battlesense, 0, 0) 
		et.G_XP_Set (cno, player.xp_engineering, 1, 0) 
		et.G_XP_Set (cno, player.xp_medic, 2, 0) 
		et.G_XP_Set (cno, player.xp_fieldops, 3, 0) 
		et.G_XP_Set (cno, player.xp_lightweapons, 4, 0) 
		et.G_XP_Set (cno, player.xp_heavyweapons, 5, 0) 
		et.G_XP_Set (cno, player.xp_covertops, 6, 0)
		
		et.G_Print (name .. "'s current XP levels:\n")
		for id, skill in pairs(skills) do 
			et.G_Print ("\t" .. skill .. ": " .. et.gentity_get (cno, "sess.skillpoints", id) .. " XP\n") 
		end
	end

	--et.G_Print ("^4List of users in database:\n")
	--for name, guid, date in rows (con, "SELECT * FROM users") do
	--	et.G_Print (string.format ("\t%s with guid %s last seen on %s\n", name, guid, date))
	--end
end -- et_ClientBegin

function et_ClientDisconnect(cno)
	name = et.Info_ValueForKey( et.trap_GetUserinfo( cno ), "name" )
	guid = et.Info_ValueForKey( et.trap_GetUserinfo( cno ), "cl_guid" )
	
	cur = assert (con:execute(string.format("SELECT * FROM users WHERE guid='%s' LIMIT 1", guid)))
	player = cur:fetch({}, 'a')
	
	if not player then
		-- This should not happen	
		et.G_Print ("^1ERROR: (XP Save) user was not found in the database!\n")
		return
	else
		et.trap_SendServerCommand (cno, "cpm \"" .. "See you again soon, " .. name .. "\n\"")
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
			et.gentity_get (cno, "sess.skillpoints", 0), 
			et.gentity_get (cno, "sess.skillpoints", 1), 
			et.gentity_get (cno, "sess.skillpoints", 2), 
			et.gentity_get (cno, "sess.skillpoints", 3), 
			et.gentity_get (cno, "sess.skillpoints", 4), 
			et.gentity_get (cno, "sess.skillpoints", 5), 
			et.gentity_get (cno, "sess.skillpoints", 6), 
			guid
		)))
	end
end -- et_ClientDisconnect
