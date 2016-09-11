--[[
	Author: [Spyhawk]
	License: ISC
	Website: http://www.etlegacy.com
	Mod: compatible with Legacy mod only

	Description: Skill Rating (aka TrueSkill) data management
	             Use in conjunction with g_skillRating cvar
]]--

--[[
	TODO:
	* 0.1: handle basic rating update functionality
	* 0.2: handle disconnected clients
	* 0.3: handle map bias parameter
	* 0.4: add useful commands
]]--

-- Lua module version
local version = "0.1"

-- load sqlite driver (or mysql..)
local luasql = require "luasql.sqlite3"

local env -- environment object
local con -- database connection
local cur -- cursor

-- check feature
local g_skillRating = tonumber(et.trap_Cvar_Get("g_skillRating"))

--[[
	Functions
]]--

-- database  helper function
-- returns database rows matching sql_statement
function rows(connection, sql_statement)
	local cursor = assert(connection:execute (sql_statement))
	return function ()
		return cursor:fetch()
	end
end

-- con:prepare with bind_names should be used to prevent SQL injections
-- but it isn't currently implemented in LuaSQL
function validateGUID(clientNum, guid)
	-- allow only alphanumeric characters in guid
	if(string.match(guid, "%W")) then
		-- Invalid characters detected. We should probably drop this client
		et.G_Print("^1[Skill Rating]:^7 User with ID " .. clientNum .. " has an invalid GUID: " .. guid .. "\n")
		et.trap_SendServerCommand (clientNum, "cpm \"^2Your Skill Rating won't be saved because you have an invalid GUID!\n\"")
		return false
	end

	return true
end

-- saves SR values of a player with id 'clientNum' into database
function saveSR(clientNum)
	local name = et.Info_ValueForKey(et.trap_GetUserinfo(clientNum), "name")
	local guid = et.Info_ValueForKey(et.trap_GetUserinfo(clientNum), "cl_guid")

	if not validateGUID(clientNum, guid) then return end

	cur = assert(con:execute(string.format("SELECT * FROM users WHERE guid='%s' LIMIT 1", guid)))
	local player = cur:fetch({}, 'a')

	if not player then
		-- should not happen
		et.G_Print("^1[Skill Rating]:^7 User not found in database!\n")
		-- cur:close()
		return
	else
		-- save data
		cur = assert(con:execute(string.format([[UPDATE users SET
			last_seen='%s',
			mu='%s',
			sigma='%s'
			WHERE guid='%s']],
			os.date("%Y-%m-%d %H:%M:%S"),
			et.gentity_get(clientNum, "sess.mu"),
			et.gentity_get(clientNum, "sess.sigma"),
			guid
		)))
	end
	-- cur:close()
end

--[[
	Callbacks
]]--

-- called when game initializes
function et_InitGame(levelTime, randomSeed, restart)
	-- register name of this module
	et.RegisterModname("Skill Rating " .. version)

	-- check status
	if tonumber(et.trap_Cvar_Get("g_skillRating")) < 1 then return end

	-- create environement object
	env = assert(luasql.sqlite3())

	-- connect to database
	con = assert(env:connect("rating.sqlite"))

	-- drop database
	-- cur = assert(con:execute("DROP TABLE users"))

	-- create database
	cur = assert(con:execute[[
		CREATE TABLE IF NOT EXISTS users(
			guid VARCHAR(64),
			last_seen VARCHAR(64),
			mu REAL,
			sigma REAL,
			UNIQUE (guid)
		)
	]])
	--cur:close()
end

-- called when game shuts down
function et_ShutdownGame(restart)
	-- check status
	if g_skillRating < 1 then return end
	-- clean up
	cur:close()
	con:close()
	env:close()
end

-- called every server frame
function et_RunFrame(levelTime)
	-- check status
	if g_skillRating < 1 then return end

	-- check gamestate changes
	gamestate = tonumber(et.trap_Cvar_Get("gamestate"))

	if oldgamestate ~= gamestate then
		oldgamestate = tonumber(et.trap_Cvar_Get("gamestate"))

		-- GS_WARMUP
		-- if gamestate == 1 then
		-- 	et.G_Print("^1[Skill Rating]:^7 GS_WARMUP\n")
		-- end

		-- GS_PLAYING
		-- if gamestate == 0 then
		-- 	et.G_Print("^1[Skill Rating]:^7 GS_PLAYING\n")
		-- end

		-- GS_INTERMISSION
		if gamestate == 3 then
			-- et.G_Print("^1[Skill Rating]:^7 GS_INTERMISSION\n")

			local clientNum = 0
			local maxclients = tonumber(et.trap_Cvar_Get("sv_maxclients"))

			-- iterate through clients
			while clientNum < maxclients do
				local cs = et.trap_GetConfigstring(tonumber(et.CS_PLAYERS) + clientNum)
				-- save new ratings
				if cs ~= nil and cs ~= "" then
					saveSR(clientNum)
				end
				clientNum = clientNum + 1
			end
		end
	end
end

-- called for every ClientConnect
function et_ClientConnect(clientNum, firstTime, isBot)
	-- check status
	if g_skillRating < 1 then return end
end

-- called for every ClientDisconnect
function et_ClientDisconnect(clientNum)
	-- check status
	if g_skillRating < 1 then return end

	local guid = et.Info_ValueForKey(et.trap_GetUserinfo(clientNum), "cl_guid")
	local name = et.Info_ValueForKey(et.trap_GetUserinfo(clientNum), "name")

	if not validateGUID(clientNum, guid) then return end

	cur = assert(con:execute(string.format("SELECT * FROM users WHERE guid='%s' LIMIT 1", guid)))
	local player = cur:fetch({}, 'a')

	if not player then
		-- should not happen
		et.G_Print("^1[Skill Rating]:^7 User not found in database!\n")
		-- cur:close()
		return
	else
		cur = assert(con:execute(string.format([[UPDATE users SET
			last_seen='%s'
			WHERE guid='%s']],
			os.date("%Y-%m-%d %H:%M:%S"),
			guid
		)))
		-- cur:close()
	end
	-- cur:close()
end

-- called for every ClientBegin
function et_ClientBegin(clientNum)
	-- check status
	if g_skillRating < 1 then return end

	local guid = et.Info_ValueForKey(et.trap_GetUserinfo(clientNum), "cl_guid")
	local name = et.Info_ValueForKey(et.trap_GetUserinfo(clientNum), "name")

	if not validateGUID(clientNum, guid) then return end

	cur = assert(con:execute(string.format("SELECT * FROM users WHERE guid='%s'", guid)))
	local player = cur:fetch({}, 'a')

	if not player then
		-- first time this player is seen
		et.trap_SendServerCommand(clientNum, "cpm \"^2[Skill Rating]:^7 Welcome, " .. name .. "^7! You are playing on an Skill Rating enabled server\n\"")

		-- use default values
		cur = assert(con:execute(string.format("INSERT INTO users VALUES ('%s', '%s', '%s', '%s')",
			guid,
			os.date("%Y-%m-%d %H:%M:%S"),
			25,
			25/3
		)))
		-- cur:close()
	else
		-- load current rating
		et.gentity_set(clientNum, "sess.mu", tonumber(player.mu))
		et.gentity_set(clientNum, "sess.sigma", tonumber(player.sigma))
		-- create copy for delta rating
		et.gentity_set(clientNum, "sess.oldmu", tonumber(player.mu))
		et.gentity_set(clientNum, "sess.oldsigma", tonumber(player.sigma))

		et.trap_SendServerCommand(clientNum, string.format("cpm \"^2[Skill Rating]:^7 Welcome back, %s^7! Your rating is ^3%s\n\"",
			name, string.format("%.2f", math.max(player.mu - 3 * player.sigma, 0))
		))
		-- et.trap_SendServerCommand(clientNum, string.format("cpm \"^2[Skill Rating]:^7 Welcome back, %s^7! Your rating is ^3%s ^7(^1%s^7,^4%s^7)\n\"",
		-- 	name,
		-- 	string.format("%.2f", math.max(player.mu - 3 * player.sigma, 0)),
		-- 	string.format("%.2f", player.mu),
		-- 	string.format("%.2f", player.sigma)
		-- ))
	end
	-- cur:close()
end

-- called for every client command
-- return 1 if intercepted, 0 if passthrough
function et_ClientCommand(clientNum, cmd)
	-- check status
	if g_skillRating < 1 then return 0 end

	-- local cmd = et.trap_Argv(0)
	cmd = string.lower(cmd)

	-- display current rating
	if cmd == "!sr" then
		local mu    = et.gentity_get(clientNum, "sess.mu")
		local sigma = et.gentity_get(clientNum, "sess.sigma")

		et.trap_SendServerCommand(clientNum, string.format("cpm \"^2[Skill Rating]:^7 Your rating is ^3%s\n\"",
			string.format("%.2f", math.max(mu - 3 * sigma, 0))
		))
		-- et.trap_SendServerCommand(clientNum, string.format("cpm \"^2[Skill Rating]:^7 Your rating is ^3%s^7 (^1%s^7, ^4%s^7)\n\"",
		-- 	string.format("%.2f", math.max(mu - 3 * sigma, 0)),
		-- 	string.format("%.2f", mu),
		-- 	string.format("%.2f", sigma)
		-- ))
		return 1
	end

	return 0
end

-- called for every console command
-- return 1 if intercepted, 0 if passthrough
function et_ConsoleCommand()
	-- check status
	if g_skillRating < 1 then return 0 end

	local cmd = et.trap_Argv(0)
	cmd = string.lower(cmd)

	-- drop users
	if cmd == "!srdbdrop" then
		-- FIXME: LuaSQL: database table is locked
		cur = assert(con:execute("DROP TABLE users"))
		et.G_Print("^2[Skill Rating]:^7 Dropped users table\n")
		-- cur:close()
		return 1
	end

	-- list all users
	if cmd == "!srdblist" then
		cur = assert(con:execute("SELECT COUNT(*) FROM users"))
		et.G_Print("^2[Skill Rating]:^3 " .. tonumber(cur:fetch(row, 'a')) .. "^7 users in database\n")
		local guid, lastseen, mu, sigma
		for guid, lastseen, mu, sigma in rows(con, "SELECT * FROM users") do
			et.G_Print(string.format("\tGUID %s\tLast seen: %s   mu: ^1%s^:  sigma: ^4%s^:   Rating: ^3%s\n",
				guid,
				lastseen,
				string.format("%.2f", mu),
				string.format("%.2f", sigma),
				string.format("%.2f", math.max(mu - 3 * sigma, 0))
			))
		end
		-- cur:close()
		return 1
	end

	return 0
end