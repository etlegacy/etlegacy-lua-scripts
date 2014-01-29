-- The NOQ - No Quarter Lua next generation game manager
--
-- A Shrubbot replacement and also kind of new game manager and tracking system based on mysql or sqlite3. 
-- Both are supported and in case of sqlite there is no extra sqlite installation needed. Use with NQ 1.2.9 and later only!
--
-- NQ Lua team 2009-2011 - No warranty :)
 
-- NQ Lua team is:
-- ailmanki
-- BubbaG1
-- Hose
-- IlDuca
-- IRATA [*]
-- Luborg

-- Webpage: http://dev.kernwaffe.de/projects/noq/
-- Wiki: 	http://dev.kernwaffe.de/projects/noq/wiki/
--
-- Please don't do any posts related to this script to the NQ forums

-- Setup:
-- - Make sure all required Lua SQL libs are on server and run properly. 
-- 		For MySQL dbms you need the additional lib in the path.
-- - If you want to use sqlite make sure your server instance has write permissions in fs_homepath. 
--		SQLite will create a file "noquarter.sqlite" at this location.
--
-- - Copy the content of this path to fs_homepath/fs_game/nq/noq
-- - for example /home/<USER>/.etlegacy/legacy/noq (default case if fs_homepath is not set by admin)
-- 
-- - Set lua_modules "noq/noq.lua noq/noq_i.lua"
--   
-- - Make the config your own. There is no need to change code in the NOQ. If you want to see changes use the forum
-- - Restart the server and check if all lua_modules noq_i.lua, noq_c.lua (optional) and noq.lua are registered.
-- - Call /rcon !sqlcreate - Done. Your system is set up - you should remove noq_i.lua from lua_modules now.
--
-- NOQ basic files:
-- noq_i.lua 				- Install script remove after install
-- noq_c.lua 				- Additional tool to enter sql cmds on the ET console
-- noq_config.cfg 			- Stores all data to run & control the NOQ. Make this file your own!
-- noq_commands.cfg 		- Commands definition file - Make this file your own! 
--
-- legacy_mods_names_<NQ_VERSION>.cfg 		- Methods of death enum file - never touch!
-- legacy_mods_<NQ_VERSION>.cfg 		- Methods of death enum file - never touch!
-- legacy_weapons_<NQ_VERSION>.cfg 		- Weapon enum config file - never touch!
-- legacy_weapons_names_<NQ_VERSION>.cfg	- Weapon enum config file - never touch!
--
-- nqconst.lua 				- No Quarter constants
-- legacyconst.lua 			- legacy constants
-- noq_db.lua 				- No Quarter DB functions
--

-- Note: 	
-- Again - you don't have to modyfiy any code in this script. If you disagree contact the dev team.


-- FIXME legacy mod
-- et.G_shrubbot_level(_clientNum) (keep for NQ)

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

-- SCRIPT VARS - don't touch !

-------------------------------------------------------------------------------

-- LUA module version
version 		= "1" -- see version table // FIXME: version is an int ! -> version 		= 1

-- TODO get from 'version' cvar '/' for linux/mac, '\' for win
pathSeparator   = "/"

homepath 		= et.trap_Cvar_Get("fs_homepath") .. pathSeparator
fs_game 		= et.trap_Cvar_Get("fs_game") .. pathSeparator
pbpath 			= homepath .. "pb" .. pathSeparator
noqpath			= "noq" .. pathSeparator
scriptpath 		= homepath .. fs_game .. noqpath  -- full qualified path for the NOQ scripts

-------------------------------------------------------------------------------
-- table functions - don't move down!
-------------------------------------------------------------------------------

-- The table load 
function table.load( sfile )
   -- catch marker for stringtable
   if string.sub( sfile,-3,-1 ) == "--|" then
	  tables,err = loadstring( sfile )
   else
	  tables,err = loadfile( sfile )
   end
   if err then return _,err
   end
   tables = tables()
   for idx = 1,#tables do
	  local tolinkv,tolinki = {},{}
	  for i,v in pairs( tables[idx] ) do
		 if type( v ) == "table" and tables[v[1]] then
			table.insert( tolinkv,{ i,tables[v[1]] } )
		 end
		 if type( i ) == "table" and tables[i[1]] then
			table.insert( tolinki,{ i,tables[i[1]] } )
		 end
	  end
	  -- link values, first due to possible changes of indices
	  for _,v in ipairs( tolinkv ) do
		 tables[idx][v[1]] = v[2]
	  end
	  -- link indices
	  for _,v in ipairs( tolinki ) do
		 tables[idx][v[2]],tables[idx][v[1]] =  tables[idx][v[1]],nil
	  end
   end
   return tables[1]
end


-- table helper
function debug_getInfoFromTable( _table )
	-- table.sort(cvartable)
	debugPrint("log","************************")
	for k,v in pairs(_table) do debugPrint("log",k .. "=" .. v) end
	debugPrint("log","************************")
	-- setn not set so empty
	-- et.G_Print("size:" .. table.getn(cvartable) .. "\n")
end
-- table functions end

-------------------------------------------------------------------------------
-- debugPrint
-- Helper function to print to log
-- target: can be 'cpm','print','logprint'?
-- TODO: extend to be able to print variables recursively out
-- TODO: http://lua-users.org/wiki/SwitchStatement ?
-------------------------------------------------------------------------------
function debugPrint( target, msg )
	if debug ~= 0 then

		local lmsg = "[DBG] " .. msg .. "\n"
		local lcmsg = "^7[DBG] " .. color .. msg .. "\n"
		
		if target == "cpm" then
			et.trap_SendServerCommand( -1 ,"cpm \"" .. lcmsg .. "\"")
		
		-- elseif target == "cpmnow" then
		-- 	et.trap_SendConsoleCommand(et.EXEC_NOW , "cpm \"" .. lcmsg .. "\"" )
		
		elseif target == "print" then
			et.G_Print( lcmsg )
		
		elseif target == "logprint" then
			et.G_LogPrint( lmsg )
		
		-- elseif slot[target] ~= nil then
		end
	end
end

-- at first we need to check for the modversion

modname = et.trap_Cvar_Get( "gamename" ) 
modprefix = ""

if modname == "nq" then
-- TODO: check for version incompatibilities...
--version = et.trap_Cvar_Get( cvarname ) 
	modprefix = "noq"
elseif modname == "legacy" then
	modprefix = "legacy"
end

et.G_LogPrint("Loading NOQ config files from ".. scriptpath.."\n")
noqvartable	= assert(table.load( scriptpath .. "noq_config.cfg"))
-- TODO: check if we can do this in total 2 tables 
meansofdeath 	= assert(table.load( scriptpath .. modprefix .. "_mods.cfg")) -- all MODS 
weapons 	= assert(table.load( scriptpath .. modprefix .. "_weapons.cfg")) -- all weapons
mod		= assert(table.load( scriptpath .. modprefix .. "_mods_names.cfg")) -- mods by name
w		= assert(table.load( scriptpath .. modprefix .. "_weapons_names.cfg")) -- weapons by name
-- end TODO
greetings	= assert(table.load( scriptpath .. "noq_greetings.cfg")) -- all greetings, customize as wished
et.G_LogPrint("NOQ config files loaded.\n")
tkweight	= {} -- TODO: external table

-- Gets varvalue else null
function getConfig ( varname )
	local value = noqvartable[varname]
	
	if value then
	  	return value
	else
		et.G_Print("warning, invalid config value for " .. varname .. "\n")
	  	return "null"
	end
end

-- don't get often used vars from noqvartable ...

databasecheck 	= tonumber((getConfig("useDB")))  		-- Is DB on?
mail 			= tonumber((getConfig("mail"))) 		-- Is Mail on?
recordbots 		= tonumber(getConfig("recordbots")) 	-- don't write session for bots
color 			= getConfig("color")					
commandprefix 	= getConfig("commandprefix")			
debug 			= tonumber(getConfig("debug")) 			-- debug 0/1
-- moved to noq_db.lua
-- debugquerries   = tonumber(getConfig("debugquerries"))
usecommands		= tonumber(getConfig("usecommands"))	-- are commands on?
xprestore 		= tonumber(getConfig("xprestore"))		-- is xprestore on?
pussyfact 		= tonumber(getConfig("pussyfactor"))	
lognames 		= tonumber(getConfig("lognames"))
nextmapVoteTime	= tonumber(getConfig("nextmapVoteSec"))
evenerdist 		= tonumber(getConfig("evenerCheckallSec"))
polldist 		= tonumber(getConfig("polldistance")) -- time in seconds between polls, -1 to disable
maxSelfKills 	= tonumber(getConfig("maxSelfKills")) -- Selfkill restriction: -1 to disable
serverid = et.trap_Cvar_Get( "servid" ) 		  -- Unique Server Identifier
if serverid == "" then	
	serverid 		= getConfig("serverID")   -- Unique Server Identifier
end
irchost			= getConfig("irchost")
ircport 		= tonumber(getConfig("ircport"))

-- disable the !force command hardcoded.
disableforce = false


-- Prints the configuration
debug_getInfoFromTable(noqvartable)

--[[-----------------------------------------------------------------------------
-- DOCU of Datastructurs in this script
--
-- The table slot[clientNum] is created each time someone connects and will store the current client information
-- The current fields are(with default values):
-- 
-- ["team"] = false
--
-- ["id"] = nil
-- ["pkey"] = 0
-- ["conname"] = row.conname
-- ["regname"] = row.regname
-- ["netname"] = row.netname
-- ["isBot"] = 0	
-- ["clan"] = 0
-- ["level"] = 0
-- ["flags"] = ''		
-- ["user"] = 0
-- ["password"] = 0
-- ["email"] = 0
-- ["banreason"] = 0 
-- ["bannedby"] = 0 
-- ["banexpire"] = 0 
-- ["mutedreason"] = 0
-- ["mutedby"] = 0
-- ["muteexpire"] = 0
-- ["warnings"] = 0 	
-- ["suspect"] = 0
-- ["regdate"] = 0
-- ["updatedate"] = 0	
-- ["createdate"] = 0	
-- ["session"] -- last used or in use session see table session.id // was client["id"] before!			
-- ["ip"] = 0	
-- ["valid "] -- not used in script only written into db if player enters for real 
-- ["start"] = 0		
-- ["end"] = 0  -- not used in script only written into db
-- ["axtime"] = 0
-- ["altime"] = 0
-- ["sptime"] = 0
-- ["lctime"] = 0
-- ["sstime"] = 0
-- ["xp0"] = 0
-- ["xp1"] = 0
-- ["xp2"] = 0
-- ["xp3"] = 0
-- ["xp4"] = 0
-- ["xp5"] = 0
-- ["xp6"] = 0
-- ["xptot"] = 0
-- ["acc"] = 0
-- ["kills"] = 0 
-- ["tkills"] = 0 teamkills you did
-- ["tkilled"] = 0 the amount you got teamkilled
-- ["death"] = 0
-- ["uci"] = 0
-- ["inuse"] = false/true
-- Added Fields during ingame session in slot[clientNum]
--
-- slot[clientNum]["victim"] = last victim of clientNum(ID)
-- slot[clientNum]["killwep"] = Name of the weapon last used to kill
-- slot[clientNum]["killer"] = last person who killed clientNum(ID)
-- slot[clientNum]["deadwep"] =  Name of the weapon by wich he was killed last
-- slot[clientNum]["lastTeamChange"] -- in seconds
-- slot[clientNum]["selfkills"] Selfkills you did
--
--]]

-- This is above mentioned table
slot = {}

-- Note: Players are ents 0 - (sv_maxclients-1)
maxclients = tonumber(et.trap_Cvar_Get("sv_maxclients"))-1 	-- add 1 again if used in view

-- We do this for accessing the table with [][] syntax, dirty but it works
for i=0, maxclients, 1 do				
	slot[i] = {}
	slot[i]["inuse"] = false	
end

-- command table, initialised in parseconf
commands = {}

--[[ 
--For testing, the !owned known from ETadmin
commands['cmd'][0]['owned'] = "print ^1Ha^3ha^5ha^3, i owned ^7<PLAYER_LAST_VICTIM_CNAME>^3 with my ^7<PLAYER_LAST_VICTIM_WEAPON>^7!!!"
commands['cmd'][0]['pants'] = "print ^1No^3no^5noooo^7, i was killed by ^3<PLAYER_LAST_KILLER_CNAME>^7 with a ^3<PLAYER_LAST_KILLER_WEAPON>^7!!!"
commands['cmd'][0]['parsecmds'] = "$LUA$ parseconf()"
commands['cmd'][0]['pussyfactor'] = "$LUA$ pussyout(<PART2IDS>)"
commands['cmd'][0]['spectime'] = "$LUA$ time = slot[_clientNum]['sptime']; et.trap_SendServerCommand(et.EXEC_APPEND , 'print \"..time.. \" seconds in spec')"
commands['cmd'][0]['axtime'] = "$LUA$ time = slot[_clientNum]['axtime']; et.trap_SendServerCommand(et.EXEC_APPEND , 'print \"..time.. \" seconds in axis')"
commands['cmd'][0]['altime'] = "$LUA$ time = slot[_clientNum]['altime']; et.trap_SendServerCommand(et.EXEC_APPEND , 'print \"..time.. \" seconds in allies')"
commands['cmd'][0]['noqban'] = "$LUA$ ban(<PART2ID>)" --TODO The BANFUNCTION...
-- ^       ^    ^     ^
-- Array   |    |     |
--        type  |     |
-- 			   Level  |
--                   Part after Prefix
-- Its possible to implement 2 commands with same commandname but different functions for different levels
--
-- commands['help'] incorporates the helptexts for each cmd
-- commands['listing'][lvl] incorporates a listing of all cmds that level can execute, as strings ready to get printed to console
--
--]]

-- current map
map = ""
mapStartTime = 0
--Gamestate 1 ,2 , 3 = End of Map 
gstate = nil

-- for the evener
evener = 0
killcount = 0
lastevener = 0
 
-- Poll restriction
lastpoll = 0

-- vsay disabler
vsaydisabled = false

-- reserved names array
namearray = {}

-- mail setup
if mail == 1 then
	smtp = require("socket.smtp")
end

-- irc relay setup
if irchost ~= "" then
	socket = require("socket")
	client = socket.udp()
end

team = { [0]="CONN","AXIS" , "ALLIES" , "SPECTATOR" }
teamchars = { ['r']="AXIS" , ['b']="ALLIES" , ['s']="SPECTATOR" }
class = { [0]="SOLDIER" , "MEDIC" , "ENGINEER" , "FIELD OPS" , "COVERT OPS" }

-------------------------------------------------------------------------------
-- load DB functions if needed
-------------------------------------------------------------------------------
if databasecheck == 1 then
require(noqpath .. "noq_db")
DBCon:DoConnect()
end

-------------------------------------------------------------------------------
-- ET functions
-------------------------------------------------------------------------------

function et_InitGame( _levelTime, _randomSeed, _restart )
	et.RegisterModname( "NOQ version " .. version .. " " .. et.FindSelf() )
    initNOQ()
	if databasecheck == 1 then
		getDBVersion()
		getresNames()
	end
	mapStartTime = et.trap_Milliseconds()
	if usecommands ~= 0 then
		parseconf() 
	end
	if irchost ~= "" then
		client:setpeername(irchost,ircport)
	end
	
	-- 												|We allow votes not directly at start, lets wait some time
	lastpoll = (et.trap_Milliseconds() / 1000) - 	(polldist / 2)
	
	-- IlDuca: TEST for mail function
	-- sendMail("<mymail@myprovider.com>", "Test smtp", "Questo è un test, speriamo funzioni!!")
end

function et_ClientConnect( _clientNum, _firstTime, _isBot )
	initClient( _clientNum, _firstTime, _isBot )
	
	local ban = checkBan( _clientNum )
	if ban ~= nil then
		return ban
	end
	-- valid client
	slot[_clientNum]["inuse"] = true
	
	-- personal game start message / server greetings	
	if firstTime == 0 or isBot == 1 or getConfig("persgamestartmessage") == "" then 
		return nil
	end
	userInfo = et.trap_GetUserinfo( _clientNum ) 
	et.trap_SendServerCommand(_clientNum, string.format("%s \"%s %s", getConfig("persgamestartmessagelocation") , getConfig("persgamestartmessage") , et.Info_ValueForKey( userInfo, "name" )))
	
	return nil
end

function et_ClientUserinfoChanged( _clientNum )
	if databasecheck == 1 then
		if lognames == 1 then 
			local thisGuid = string.upper( et.Info_ValueForKey( et.trap_GetUserinfo( _clientNum ), "cl_guid" ))
			if string.sub(thisGuid, 1, 7) ~= "OMNIBOT" then
				local thisName = et.Info_ValueForKey( et.trap_GetUserinfo( _clientNum ), "name" )
				DBCon:SetPlayerAlias( thisName, thisGuid )
			end
		end
	end
	
	if namearray ~= nil then
	checkforResName(_clientNum)
	end
	
end

-- This function is called - after the connection is over, so when you first join the game world
--
-- Before r3493 also:
--	- when you change team
--	- when you are spectator and switch from "free look mode" to "follow player mode"
-- IRATA: check et_ClientSpawn()
-- TODO/NOTE: Afaik we only need to check if ClientBegin is called once to keep 1.2.7 compatibility
function et_ClientBegin( _clientNum )
	-- TODO Move this functionality in an own function
	-- Get the player name if its not set
	if slot[_clientNum]["netname"] == false then
		slot[_clientNum]["netname"] = et.gentity_get( _clientNum ,"pers.netname")
		slot[_clientNum]["cleanname"] = et.Q_CleanStr(slot[_clientNum]["netname"])	
	end
	
	-- He first connected - so we set his team.
	slot[_clientNum]["team"] = tonumber(et.gentity_get(_clientNum,"sess.sessionTeam"))
	slot[_clientNum]["lastTeamChange"] = (et.trap_Milliseconds() / 1000) -- Hossa! We needa seconds

	-- greeting functionality after netname is set
	if slot[_clientNum]["ntg"] == true then
		greetClient(_clientNum)
	end
	
	-- Moved the mute check here
	checkMute( _clientNum )
	
	
	if databasecheck == 1 then
		-- If we have db access, then we will create new Playerentry if necessary
		-- TODO check for else case of the above if ... why updating Player XP if client is new ? (slot XP is set in createNewPlayer()
		
		if slot[_clientNum]["new"] == true then
			createNewPlayer ( _clientNum )
			slot[_clientNum]["setxp"] = nil
		else
			-- if we have xprestore, we need to restore now!
			if slot[_clientNum]["setxp"] == true then
				
				-- But only, if xprestore is on!
				if xprestore == 1 then
					updatePlayerXP( _clientNum )
				end
				slot[_clientNum]["setxp"] = nil
			end
		end
		
		checkOffMesg(_clientNum)
	   
	   -- Reserved Name/Clantag support
		if namearray then
			checkforResName(_clientNum)
		end
	   
	end -- end databasecheck
end

-- TODO: What does this do here? 
-- Possible values are :
--	- slot[_clientNum].team == nil -> the player connected and disconnected without join the gameworld = not-valid session
--	- slot[_clientNum].gstate = 0 and gstate = 0 -> we have to update playing time and store all the player infos = valid session
--	- slot[_clientNum].gstate = 1 or 2 and gstate = 1 or 2 -> player connected during warmup and disconnected during warmup = store only start and end time + valid session
--	- slot[_clientNum].gstate = 3 and gstate = 3 -> player connected during intermission and disconnected during intermission = store only start and end time + valid session
--	- slot[_clientNum].gstate = 0 and gstate = 3 -> we have to store all the player infos = valid session

function et_ClientDisconnect( _clientNum )
	if databasecheck == 1 then
		local endtime = timehandle ('N')
		-- TODO : check if this works. Is the output from 'D' option in the needed format for the database?
		local timediff = timehandle('D','N', slot[_clientNum]["start"])
		
		WriteClientDisconnect( _clientNum , endtime, timediff )
	end
	slot[_clientNum] = {}
	slot[_clientNum]["inuse"] = false 
end

-- called for every clientcommand
-- return 1 if intercepted, 0 if passthrough
-- see Table noq_clientcommands for the available cmds
function et_ClientCommand( _clientNum, _command )
	local arg0 = string.lower(et.trap_Argv(0))
	local arg1 = string.lower(et.trap_Argv(1))
	local arg2 = string.lower(et.trap_Argv(2))
	callershrublvl = 1 -- FIXME !!! et.G_shrubbot_level(_clientNum)
	
	debugPrint("print","Got a Clientcommand: ".. arg0)
	
	if vsaydisabled == true and arg0 == "vsay" then
		-- No vsays please.
		et.trap_SendServerCommand( _clientNum, "cp \"^1Global voicechat disabled\"")
		return 1
	end

	if slot[_clientNum]['vsaydisabled'] == true and arg0 == "vsay" then
		-- No vsays please.
		et.trap_SendServerCommand( _clientNum, "cp \"^1Your global voicechats are disabled\"")
		return 1
	end

	-- switch to disable the !commands 
	if usecommands ~= 0 then
	
		if arg0 == "say" then
			if string.sub( arg1, 1,1) == commandprefix then -- this means normal say
				debugPrint("print","Got saycommand: " .. _command)
				local returnvalue = gotCmd( _clientNum, _command , false)
				return returnvalue
				-- return gotCmd( _clientNum, _command , false)
			end
		elseif arg0 == "vsay" then 
			if string.sub( arg2 , 1, 1) == commandprefix then -- this means a !command with vsay
				gotCmd ( _clientNum, _command, true)
			end
		elseif arg0 == "readthefile" then -- read in the commandsfile  
			if et.G_shrubbot_permission( _clientNum, "G" ) == 1 then -- has the right to read the config in.. So he also can read commands
				parseconf()
				et.trap_SendConsoleCommand(et.EXEC_APPEND, "csay " .. _clientNum .. "\"^3Parsed commands.\n\"\n")
				return 1
			end
			et.trap_SendConsoleCommand(et.EXEC_APPEND, "csay " .. _clientNum .. "\"^3Not enough rights to use this command.\n\"\n")
			return 1
		end
		
		
		if et.G_shrubbot_permission( _clientNum, "3" ) == 1 then -- and finally, a silent !command
			if string.sub( arg0 , 1, 1) == commandprefix then
				local returnvalue =  gotCmd ( _clientNum, _command, nil)
				return returnvalue
			end
		end
		 
	end


	if noq_clientcommands == nil then
	--[[
	The Commands used in et_clientcommand.
	use arg0, arg1, arg2 for arguments, callershrublvl as lvl, clientNum for clientNum
	--]]
	noq_clientcommands = {
		
		["noq_alist"] = function(arg0,arg1,arg2,clientNum,callershrublvl)
			if arg1 == "" then
				nPrint(clientNum, "^3Usage: /noq_alist <partofplayername/slotnumber>")
				nPrint(clientNum, "^3noq_alist will print a list of all know aliases for a player")
				return 1
			else
				local whom = getPlayerId(arg1)
				if whom ~= nil then
					listAliases(clientNum, whom)
					return 1
				else
					nPrint(clientNum, "^3No matching player found :/")
				end
			end
		end,
		
		["register"] = function(arg0,arg1,arg2,clientNum,callershrublvl)
			-- register command
			local name = string.gsub(arg1,"\'", "\\\'")
			if arg1 ~= "" and arg2 ~= "" then
				local testreg = DBCon:GetPlayerbyReg(name)
				if testreg ~= nil then
					if testreg['pkey'] == slot[clientNum]['pkey'] then
						slot[clientNum]["user"] = name
						DBCon:DoRegisterUser(name, arg2,slot[clientNum]["pkey"])
						et.trap_SendConsoleCommand(et.EXEC_NOW, "csay " .. clientNum .. "\"^3Successfully reset password\n\"\n")
						return 1
					end
				
				et.trap_SendConsoleCommand(et.EXEC_NOW, "csay " .. clientNum .. "\"^3This nick is already registered\n\"\n")
				return 1
				end
			
				slot[clientNum]["user"] = name
				DBCon:DoRegisterUser(name, arg2,slot[clientNum]["pkey"])
				
				et.trap_SendServerCommand( clientNum, "print \"^3Successfully registered. To reset password just re-register. \n\"" ) 
				return 1		
			else
				
				if slot[clientNum]["user"] ~= "" then
					et.trap_SendServerCommand( clientNum, "print \"^1You are already registered, under the name '".. slot[clientNum]["user"] ..  "'\n\"" ) 	
				end
				et.trap_SendServerCommand( clientNum, "print \"^3Syntax for the register Command: /register username password  \n\"" ) 
				et.trap_SendServerCommand( clientNum, "print \"^3Username is your desired username (for web & offlinemessages)  \n\"" )
				et.trap_SendServerCommand( clientNum, "print \"^3Password will be your password for your webaccess  \n\"" ) 

				return 1
			end
		end,
		
		["callvote"] = function(arg0,arg1,arg2,clientNum,callershrublvl)
		-- Voting restriction
		   
			if polldist ~= -1 then
			-- restriction is enabled	
				milliseconds = et.trap_Milliseconds() 
				seconds = milliseconds / 1000

				-- checks for shrubbot flag "7" -> check shrubbot wiki for explanation 
				if et.G_shrubbot_permission( clientNum, "7" ) == 1 then
					return 0

				-- checks time betw. last vote and this one
				elseif (seconds - lastpoll) < polldist then
					et.trap_SendConsoleCommand (et.EXEC_APPEND , "chat \"".. et.gentity_get(clientNum, "pers.netname") .."^7, please wait ^1".. string.format("%.0f", polldist - (seconds - lastpoll) ) .." ^7seconds for your next poll.\"" )
					return 1
				end
				
				-- handles nextmap vote restriction
				if arg1 == "nextmap" then

					--check the time that the map is running already
					mapTime = et.trap_Milliseconds() - mapStartTime
					
					debugPrint("print","maptime = " .. mapTime)
					debugPrint("print","maptime in seconds = " .. mapTime/1000 )
					debugPrint("print","mapstarttime = " .. mapStartTime)
					debugPrint("print","mapstarttime in seconds = " .. mapStartTime/1000)
					
					--compare to the value that is given in config where nextmap votes are allowed
					if nextmapVoteTime == 0 then
						debugPrint("print","Nextmap vote limiter is disabled!")
						return 0
					elseif mapTime / 1000 > nextmapVoteTime then
						--if not allowed send error msg and return 1	
						et.trap_SendConsoleCommand (et.EXEC_APPEND, "chat \"Nextmap vote is only allowed during the first " .. nextmapVoteTime .." seconds of the map! Current maptime is ".. mapTime/1000 .. " seconds!\"")
						return 1
					end
					
				end
					
				lastpoll = seconds
			end
			-- return !!!
		end ,
		
		["kill"] = function(arg0,arg1,arg2,clientNum,callershrublvl)
			-- /kill restriction
			if maxSelfKills ~= -1 then
				if slot[clientNum]["selfkills"] > maxSelfKills then
					et.trap_SendServerCommand( clientNum, "cp \"^1You don't have any more selfkills left!") 
					et.trap_SendServerCommand( clientNum, "cpm \"^1You don't have any more selfkills left!")
					return 1
				end
				et.trap_SendServerCommand( clientNum, "cp \"^1You have ^2".. (maxSelfKills - slot[clientNum]["selfkills"])  .."^1 selfkills left!")
				et.trap_SendServerCommand( clientNum, "cpm \"^1You have ^2".. (maxSelfKills - slot[clientNum]["selfkills"])  .."^1 selfkills left!")
				return 0
			end
		end,	
		
		["mail"] = function(arg0,arg1,arg2,clientNum,callershrublvl)
			-- check for OfflineMesgs
			checkOffMesg (clientNum)
			return 1
		end,
		
		["om"] = function(arg0,arg1,arg2,clientNum,callershrublvl)
			-- send OfflineMesgs
			sendOffMesg (clientNum,arg1 , et.ConcatArgs( 2 ) )
			return 1
		end,
		
		["rmom"] = function(arg0,arg1,arg2,clientNum,callershrublvl)
			--erase OfflineMesgs
			arg1 = string.gsub(arg1,"\'", "\\\'")
			DBCon:DelOM(arg1, slot[clientNum]['pkey'])
			et.trap_SendConsoleCommand(et.EXEC_NOW, "csay " .. clientNum .. "\"^3Erased MessageID ".. arg1 .."\n\"\n")
			return 1
		end,
		
		["rmmail"] = function(arg0,arg1,arg2,clientNum,callershrublvl)
			--erase all OfflineMesgs
			DBCon:DelMail(slot[clientNum]['pkey'])
			nPrint(clientNum, "^3Cleared your Inbox. ")
			return 1
		end,
			
		["team"] = function(arg0,arg1,arg2,clientNum,callershrublvl)
			-- lock to team
			if slot[clientNum]["locktoTeam"] ~= nil then
				if arg1 ~= slot[clientNum]["locktoTeam"] then
					if slot[clientNum]["lockedTeamTill"] <= (et.trap_Milliseconds() /1000 ) then
						slot[clientNum]["locktoTeam"] = nil
						slot[clientNum]["lockedTeamTill"] = 0
						-- TODO return!
					else
						et.trap_SendServerCommand( clientNum, "cp \"^3You are locked to the ^1"..teamchars[slot[clientNum]["locktoTeam"]].. " ^3team by an admin")
						et.trap_SendServerCommand( clientNum, "chat \"^3You are locked to the ^1"..teamchars[slot[clientNum]["locktoTeam"]].. " ^3team by an admin")
						return 1
					end
				end	
			end
		end,
		
		["mirc"] = function(arg0,arg1,arg2,clientNum,callershrublvl)
			msgtoIRC(clientNum,et.ConcatArgs( 1 ))
			return 1
		end
		
		} -- end for our cmdarray

	end

  if noq_clientcommands[arg0] then
    return(noq_clientcommands[arg0](arg0,arg1,arg2,_clientNum,callershrublvl))
  end
	
end

-- FIXME: this crashes in legacy mod
function et_ShutdownGame( _restart )
	if databasecheck == 1 then
		-- We write only the informations from a session that gone till intermission end
		
		-- gamestate 2 reached once when !restart used - also when map ends regularly..
		-- this gets called ONCE .. and gamestate is not -1.
		--if tonumber(et.trap_Cvar_Get( "gamestate" )) == -1 then

		-- This is when the map ends: we have to close all opened sessions
		-- Cycle between all possible clients
		local endgametime = timehandle('N')
		
		if tonumber(et.trap_Cvar_Get( "gamestate" )) == 0 then
		-- this is the case if the warmup end - thus we dont save a session here.
		else
		-- save only in intermission.		
			for i=0, maxclients, 1 do
				-- TODO: check slot[] if its existingreco
				if et.gentity_get(i,"classname") == "player" then
					-- TODO : check if this works. Is the output from 'D' option in the required format for the database?
					local timediff = timehandle('D',endgametime,slot[i]["start"])
					et.G_LogPrint( "Noq: saved player "..i.." to Database\n" ) 
					WriteClientDisconnect( i , endgametime, timediff )
					slot[i] = nil
				end
			end
		end
		
		--DBCon:DoDisconnect()
	end
		
	-- delete old sessions if set in config
	local deleteSessionsOlderXMonths = tonumber(getConfig("deleteSessionsOlderXMonths"))
	if  deleteSessionsOlderXMonths > 0 then
		DBCon:DoDeleteOldSessions( deleteSessionsOlderXMonths )
	end
end

function et_RunFrame( _levelTime )
	-- TODO: is this what we want? I suppose yes...	
    -- This check works only once, when the intermission start: here we have to close sptime, axtime and altime
	-- For all players in the LUA table "slot"
	if ( gstate == 0 ) and ( tonumber(et.trap_Cvar_Get( "gamestate" )) == 3 ) then
		local now = timehandle()			

		for i=0, maxclients, 1 do
			-- this tests if the playerentity is used! useless to close a entity wich is not in use.
			-- @Luborg: Actually it checks if the ent is a player - this is always the case (ent 0 - maxclients) if they are active
			-- Did you get errors ? Checking slot[i]["team"] should be enough here since the slot table is a mirror of current players
			-- and "team" == -1 means we already closed the team -> slot not in use. closeTeam() should handle the other cases
			-- It's worth to sort this out it's RunFrame ... 
			if et.gentity_get(i,"classname") == "player" then 
				-- @Ilduca note: client["team"] is set to false somewhere in this code
				if slot[i]["team"] ~= -1 then
					closeTeam ( i )
				end
			end
		end

		gstate = tonumber(et.trap_Cvar_Get( "gamestate" ))
		
		-- Added last kill of the round-- this fails when no kills have been done
		if (lastkill ~= nil) then
			execCmd(lastkill, "chat \"^2And the last kill of the round goes to: ^7<COLOR_PLAYER>\"" , {[1]=lastkill,[2]=lastkill,[3]=lastkill})
			et.trap_SendConsoleCommand(et.EXEC_APPEND, "chat \"^2A total of ^7" .. killcount ..  " ^2Persons died by various reasons during this map\"" )
		end
		--TODO: Should we call the save to the DB right here?
	end
end

function et_Obituary( _victim, _killer, _mod )
	debugPrint("cpm", "Victim: ".._victim .. " Killer " .._killer .." MOD: ".. meansofdeath[_mod])
	if _killer == 1022 then
		-- this is for a kill by falling or similar trough the world. Mapmortar etc also.
		
		slot[_victim]["killer"] = _killer
		slot[_victim]["deadwep"] = string.sub(meansofdeath[_mod], 5)
		
		-- update kill vars (victim only)
		
	else -- all non world kills 
		pussyFactCheck( _victim, _killer, _mod )

		slot[_killer]["victim"] = _victim
		slot[_killer]["killwep"] = string.sub(meansofdeath[_mod], 5)

		slot[_victim]["killer"] = _killer
		slot[_victim]["deadwep"] = string.sub(meansofdeath[_mod], 5)
		
		lastkiller = _killer
		
		-- update client vars ...
		
		-- Self kill (restriction)
		if _killer == _victim then
			if _mod == mod["MOD_SUICIDE"] then
				slot[_killer]["selfkills"] = slot[_killer]["selfkills"] + 1 -- what about if they use nades?
			end
			-- TODO: wtf? why not just add 1 to the field? Why call an ETfunction if WE could do it faster?? 
			slot[_victim]["death"] = tonumber(et.gentity_get(_victim,"sess.deaths"))
			-- slot[_victim]["tkills"] = tonumber(et.gentity_get(_clientNum,"sess.team_kills")) -- TODO ????
			-- slot[_victim]["tkilled"] = slot[_victim]["tkilled"] + 1
		else -- _killer <> _victim
			-- we assume client[team] is always updated
			if slot[_killer]["team"] == slot[_victim]["team"] then -- Team kill
				-- TODO: check if death/kills need an update here
				slot[_killer]["tkills"] = slot[_killer]["tkills"] + 1		
				slot[_victim]["tkilled"] = slot[_victim]["tkilled"] + 1			
				
				if not tkweight[_mod] ~= nil then tk = 1 else tk = tkweight[_mod] end
				slot[_killer]["tkpoints"] = slot[_killer]["tkpoints"] + tk
				checkTKPoints(_killer)
			
			else -- cool kill
				slot[_victim]["death"] = tonumber(et.gentity_get(_victim,"sess.deaths"))
				slot[_killer]["kills"] = tonumber(et.gentity_get(_killer,"sess.kills"))		
			
				slot[_victim]["kspree"] = 0
				slot[_killer]["kspree"] = slot[_killer]["kspree"] + 1
				-- force points - adding half of the killspree value
				slot[_killer]["fpoints"] = slot[_killer]["fpoints"] + (slot[_killer]["kspree"] / 2) 
				-- add 1 point for deaths to .. some haven't the luck of many kills
				slot[_victim]["fpoints"] = slot[_victim]["fpoints"] + 1 
				
				
			end
		end
			
	end -- end of 'all not world kills'

	-- uneven teams solution - the evener
	if evenerdist ~= -1 then
		killcount = killcount +1
		seconds = (et.trap_Milliseconds() / 1000)
		if killcount % 2 == 0 and (seconds - lastevener ) >= evenerdist then
			checkBalance( true )
			lastevener = seconds
		end
	end

	-- last kill of the round
	lastkill = _killer
end

-- called for every Servercommand
-- return 1 if intercepted, 0 if passthrough
function et_ConsoleCommand( _command )
	-- debugPrint("cpm", "ConsoleCommand - command: " .. _command )
	
	-- noq cmds ...
	-- TODO: What is this !noq cmd good for in here?
	-- if string.lower(et.trap_Argv(0)) == commandprefix.."noq" then  
	-- 	if (et.trap_Argc() < 2) then 
	--		et.G_Print("#sql is used to access the db with common sql commands.\n") 
	--		et.G_Print("usage: ...")
	--		return 1 
	--	end
	 
	-- noq warn ...
	-- TODO: What is this !warn cmd good for in here?
	-- elseif string.lower(et.trap_Argv(0)) == commandprefix.."warn" then
		-- try first param to cast as int
		-- if int check if slot .. ban
		-- if not try to get player via part of name ...
	
	local arg0 = string.lower(et.trap_Argv(0)) 
	if arg0 == "csay" then
		-- csay - say something to clients console .. usefull for EXEC_APPEND!
		if (et.trap_Argc() >= 3) then 
			_targetid = tonumber(et.trap_Argv(1))
			if slot[_targetid] ~= nil then

				et.trap_SendServerCommand( _targetid,"print \"" .. et.trap_Argv(2) .."\n\"")
			end
		end
	elseif arg0 == "plock" then
	-- plock - lock a player to a team
		if (et.trap_Argc() >= 4) then 
		_targetid = tonumber(et.trap_Argv(1))
		_targetteam = et.trap_Argv(2)
		_locktime = tonumber(et.trap_Argv(3))
		slot[_targetid]["locktoTeam"] = _targetteam
		slot[_targetid]["lockedTeamTill"] = _locktime + (et.trap_Milliseconds() /1000 )
		et.trap_SendServerCommand( -1,"chat \"^7"..slot[_targetid]["netname"].." ^3 is now locked to the ^1"..teamchars[_targetteam].."^3 team\"")
		end
	elseif arg0 == "noq_irc" then
		sendtoIRCRelay(et.ConcatArgs( 1 ))
	elseif  arg0 == "!setlevel"  or arg0 == commandprefix .. "setlevel" then
		-- we need to set the level to be sure db is up-to-date
		if (et.trap_Argc() ~= 3 ) then
			et.G_Print("usage: !setlevel id/name level")
		else
			local plr = getPlayerId(et.trap_Argv(1))
			if plr then
				slot[plr]["lvl"] = tonumber(et.trap_Argv(2))
				savePlayer( plr )
				et.G_Print("NOQ: set " .. slot[plr]['netname'] .. " to level " .. tonumber(et.trap_Argv(2)) .. "\n" )
			else
				et.G_Print("NOQ: No corresponding player found to set level.")
			end
		end
	end
	
	-- add more cmds here ...
end

function et_ClientSpawn( _clientNum, _revived )
	-- TODO: check if this works, works!
	-- _revived == 1 means he was revived
	if _revived ~= 1 then
		updateTeam(_clientNum)
	else
		et.trap_SendServerCommand(et.gentity_get(_clientNum,"pers.lastrevive_client"),"cpm \"^1You revived ^7" .. slot[_clientNum]  .. " \"" );
	end
	
end

-------------------------------------------------------------------------------
-- helper functions
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- initClient
-- Gets DbInfos and checks for Ban and Mute, inits clientfields
-- the very first action  
-------------------------------------------------------------------------------
function initClient ( _clientNum, _FirstTime, _isBot)
	-- note: this script should work w/o db connection
	-- greetings functionality: check if connect (1) or reconnect (2)
	
	--'static' clientfields
	slot[_clientNum]["pkey"] 	= string.upper( et.Info_ValueForKey( et.trap_GetUserinfo( _clientNum ), "cl_guid" ))
	slot[_clientNum]["ip"] 		= et.Info_ValueForKey( et.trap_GetUserinfo( _clientNum ), "ip" )
	local a
	local b
	a, b, slot[_clientNum]["ip"]= string.find(slot[_clientNum]["ip"],"(%d+%.%d+%.%d+%.%d+)")
	slot[_clientNum]["isBot"] 	= _isBot
	slot[_clientNum]["conname"] = et.Info_ValueForKey( et.trap_GetUserinfo( _clientNum ), "name" )
	slot[_clientNum]["level"]	= 1 -- FIXME !!! et.G_shrubbot_level(_clientNum)
	slot[_clientNum]["flags"]	= "" -- TODO
	slot[_clientNum]["start"] 	= timehandle('N') 		-- Get the start connection time

	-- 'dynamic' clientfields
	slot[_clientNum]["team"] 	= false -- set the team on client begin (don't use nil here, as it deletes the index!)
	slot[_clientNum]["axtime"] 	= 0
	slot[_clientNum]["altime"] 	= 0
	slot[_clientNum]["sptime"] 	= 0
	slot[_clientNum]["lctime"] 	= 0
	slot[_clientNum]["acc"] 	= 0
	slot[_clientNum]["kills"] 	= 0
	slot[_clientNum]["tkills"] 	= 0
	slot[_clientNum]["tkpoints"] = 0
	slot[_clientNum]["kspree"] = 0		-- killingspree
	slot[_clientNum]["fpoints"] = 10 	-- forcepoints
	slot[_clientNum]["netname"] = false
	slot[_clientNum]["victim"] 	= -1
	slot[_clientNum]["killwep"] = "nothing"
	slot[_clientNum]["killer"] 	= -1
	slot[_clientNum]["deadwep"] = "nothing"
	slot[_clientNum]["selfkills"]	= 0
	slot[_clientNum]["vsaydisabled"]	= false
	slot[_clientNum]["locktoTeam"] = nil
	slot[_clientNum]["lockedTeamTill"] = 0
	
	
	slot[_clientNum]["death"] 	= 0
	slot[_clientNum]["uci"] 	= 0
	slot[_clientNum]["pf"]		= 0

	-- non db client fields
	slot[_clientNum]["tkilled"] = 0

	
	if _FirstTime == 1 then 
		slot[_clientNum]["ntg"] = true
	else
		slot[_clientNum]["ntg"] = false
	end	
					
	debugPrint("cpm", "LUA: INIT CLIENT" )
	
	if databasecheck == 1 then
		debugPrint("cpm", "LUA: INIT DATABASECHECK EXEC" )
		
		updatePlayerInfo(_clientNum)
		
		slot[_clientNum]["setxp"] = true
		slot[_clientNum]["xpset"] = false
		
		return nil			
	end
	
	debugPrint("cpm", "LUA: INIT CLIENT NO DATABASE INTERACTION" )
	
    return nil
end

-------------------------------------------------------------------------------
-- updatePlayerInfo
-- Updates the Playerinformation out of the Database (IF POSSIBLE!)
-- Also called on connect
-------------------------------------------------------------------------------
function updatePlayerInfo ( _clientNum )
	DBCon:GetPlayerInfo( slot[_clientNum]["pkey"] )
	
	if DBCon.row then
		-- This player is already present in the database
		debugPrint("cpm", "LUA: INIT CLIENT ROW EXISTS")
		-- Start to collect related information for this player id
		-- player
		slot[_clientNum]["id"] = DBCon.row.id
		slot[_clientNum]["regname"] = DBCon.row.regname
		slot[_clientNum]["conname"] = DBCon.row.conname
		--slot[_clientNum]["netname"] = DBCon.row.netname --we don't set netname to a invalid old databaseentry
		slot[_clientNum]["clan"] = DBCon.row.clan	
		slot[_clientNum]["user"] = DBCon.row.user -- only for admin info
		slot[_clientNum]["banreason"] = DBCon.row.banreason
		slot[_clientNum]["bannedby"] = DBCon.row.bannedby
		slot[_clientNum]["banexpire"] = DBCon.row.banexpire
		slot[_clientNum]["mutedreason"] = DBCon.row.mutedreason
		slot[_clientNum]["mutedby"] = DBCon.row.mutedby
		slot[_clientNum]["muteexpire"] = DBCon.row.muteexpire
		slot[_clientNum]["warnings"] = DBCon.row.warnings
		slot[_clientNum]["suspect"] = DBCon.row.suspect
		slot[_clientNum]["regdate"] = DBCon.row.regdate
		slot[_clientNum]["createdate"] = DBCon.row.createdate -- first seen
		slot[_clientNum]["updatedate"] = DBCon.row.updatedate -- last seen
		--slot[_clientNum]["level"] = et.G_shrubbot_level( _clientNum ) 
		--TODO: REAL LEVEL/Who is more important, shrub or database?
		-- IRATA: noq - database;
		-- ailmanki: changed.. if the user is in db we get in from db, else from shrubbot.
		-- luborg: use nq_noq to determine:
		local nq_noq = et.trap_Cvar_Get( "nq_noq" )
		if  nq_noq ~= 1 or nq_noq ~= 2  then
			-- nq_noq is not set, shrub is active - we only save, but dont set.
		else
			slot[_clientNum]["level"] = DBCon.row.level
			-- cmd only available in nq >= 130
			et.G_shrubbot_setlevel(_clientnum, DBCon.row.level)
		end 	
		slot[_clientNum]["flags"] = DBCon.row.flags -- TODO: pump it into game
				
		--Perhaps put into updatePlayerXP
		slot[_clientNum]["xp0"] = DBCon.row.xp0
		slot[_clientNum]["xp1"] = DBCon.row.xp1
		slot[_clientNum]["xp2"] = DBCon.row.xp2
		slot[_clientNum]["xp3"] = DBCon.row.xp3
		slot[_clientNum]["xp4"] = DBCon.row.xp4
		slot[_clientNum]["xp5"] = DBCon.row.xp5
		slot[_clientNum]["xp6"] = DBCon.row.xp6
		slot[_clientNum]["xptot"] = DBCon.row.xptot
			
		debugPrint("cpm", "LUA: INIT CLIENT FROM ROW GOOD" )
	else	
		debugPrint("cpm", "LUA: INIT CLIENT NO ROW -> NEW" )
		-- Since he is new, he isn't banned or muted: let him pass those check
		slot[_clientNum]["banreason"] = ""
		slot[_clientNum]["bannedby"] = ""
		slot[_clientNum]["banexpire"] = "1000-01-01 00:00:00"
		slot[_clientNum]["mutedreason"] = ""
		slot[_clientNum]["mutedby"] = ""
		slot[_clientNum]["muteexpire"] = "1000-01-01 00:00:00"
		
		-- Go to Clientbegin and say he's new
		slot[_clientNum]["new"] = true
	end
end

-------------------------------------------------------------------------------
-- updatePlayerXP
-- Update a players xp from the values in his previously set Xptable
-- just a g_xp_setfunction for all values
-------------------------------------------------------------------------------
function updatePlayerXP( _clientNum )
	
	if tonumber(slot[_clientNum]["xp0"]) < 0 then
		slot[_clientNum]["xp0"] = 0
	end
	if tonumber(slot[_clientNum]["xp1"]) < 0 then
		slot[_clientNum]["xp1"] = 0
	end
	if tonumber(slot[_clientNum]["xp2"]) < 0 then
		slot[_clientNum]["xp2"] = 0
	end
	if tonumber(slot[_clientNum]["xp3"]) < 0 then
		slot[_clientNum]["xp3"] = 0
	end
	if tonumber(slot[_clientNum]["xp4"]) < 0 then
		slot[_clientNum]["xp4"] = 0
	end
	if tonumber(slot[_clientNum]["xp5"]) < 0 then
		slot[_clientNum]["xp5"] = 0
	end
	if tonumber(slot[_clientNum]["xp6"]) < 0 then
		slot[_clientNum]["xp6"] = 0
	end
	
	et.G_XP_Set ( _clientNum , slot[_clientNum]["xp0"], 0, 0 ) -- battle
	et.G_XP_Set ( _clientNum , slot[_clientNum]["xp1"], 1, 0 ) -- engi
	et.G_XP_Set ( _clientNum , slot[_clientNum]["xp2"], 2, 0 ) -- medic
	et.G_XP_Set ( _clientNum , slot[_clientNum]["xp3"], 3, 0 ) -- signals
	et.G_XP_Set ( _clientNum , slot[_clientNum]["xp4"], 4, 0 ) -- light
	et.G_XP_Set ( _clientNum , slot[_clientNum]["xp5"], 5, 0 ) -- heavy
	et.G_XP_Set ( _clientNum , slot[_clientNum]["xp6"], 6, 0 ) -- covert
	slot[_clientNum]["xpset"] = true
end

-------------------------------------------------------------------------------
-- checkBan
-- Check if player is banned and kick him
-- TODO : would be cool to inform admins about bans through mail
-- TODO : add something that tracks a just-unbanned player ( for time bans )
--        in order to warn online admins and maybe the player himself
-- NOTE : do something like checkMute with an own LUA function?
------------------------------------------------------------------------------- 
function checkBan ( _clientNum )
	if slot[_clientNum]["bannedby"] ~= "" then
		if  slot[_clientNum]["banreason"] ~= "" then
			if  slot[_clientNum]["banexpire"] ~= "1000-01-01 00:00:00" then
				-- Check for expired ban
				if timehandle( 'DS', 'N', slot[_clientNum]["banexpire"] ) > 0 then
				    -- The ban is expired: clear the ban fields and continue
				    slot[_clientNum]["bannedby"] = ""
				    slot[_clientNum]["banreason"] = ""
				    slot[_clientNum]["banexpire"] = "1000-01-01 00:00:00"
				    
				    return nil
				end
				return "You are banned by "..slot[_clientNum]["bannedby"].." until "..slot[_clientNum]["banexpire"]..". Reason: "..slot[_clientNum]["banreason"]
			else
				return "You are permanently banned by "..slot[_clientNum]["bannedby"]..". Reason: "..slot[_clientNum]["banreason"]
			end
		else
			if  slot[_clientNum]["banexpire"] ~= "1000-01-01 00:00:00" then
				-- Check for expired ban	
			    if timehandle( 'DS', 'N', slot[_clientNum]["banexpire"] ) > 0 then
				    -- The ban is expired: clear the ban fields and continue
				    slot[_clientNum]["bannedby"] = ""
				    slot[_clientNum]["banexpire"] = "1000-01-01 00:00:00"

				    return nil
				end
				return "You are banned by "..slot[_clientNum]["bannedby"].." until "..slot[_clientNum]["banexpire"]
			else
				return "You are permanently banned by "..slot[_clientNum]["bannedby"]
			end
		end
	end
	
	return nil
end

-------------------------------------------------------------------------------
-- checkMute
-- Called in clientBegin in order to print the warning message to the player
-- The mute is done through ET, calculating the time between NOW and muteexpire
-- and setting the seconds to the game's mute system. Expired check is done with
-- the field mutedby; muteexpire is cleared in the database when clientDisconnect
-- TODO : would be cool to inform admins about mutes through mail
-- TODO : add something that tracks a just-unmuted player ( for time mute )
--        in order to warn online admins and maybe the player himself
-------------------------------------------------------------------------------
function checkMute ( _clientNum )
	if slot[_clientNum]["mutedby"] ~= "" then
		-- Check permanent mute
		if slot[_clientNum]["muteexpire"] == "1000-01-01 00:00:00" then
		    et.MutePlayer( _clientNum, -1, slot[_clientNum]["mutedreason"] )
		    return nil
		end
		local muteseconds = timehandle( 'DS', 'N', slot[_clientNum]["muteexpire"] )
	    -- Check if the mute is still valid
	    if  muteseconds > 0 then
			-- The mute is expired: clear the mute fields and continue
			slot[_clientNum]["mutedby"] = ""
			slot[_clientNum]["mutedreason"] = ""
			slot[_clientNum]["muteexpire"] = ""
		else
		    -- The mute is still valid: mute him!
		    muteseconds = muteseconds * (-1)
		    et.MutePlayer( _clientNum, muteseconds, slot[_clientNum]["mutedreason"] )
		end
	end
	
	return nil
end

-------------------------------------------------------------------------------
-- createNewPlayer
-- Create a new Player: write to Database, set Xp 0
-- maybe could also be used to reset Player, as pkey is unique
-------------------------------------------------------------------------------
function createNewPlayer ( _clientNum )
	local name = string.gsub(slot[_clientNum]["netname"],"\'", "\\\'")
	local conname = string.gsub(slot[_clientNum]["conname"],"\'", "\\\'")
	-- This player is a new one: create a new database entry with our Infos
	DBCon:DoCreateNewPlayer( slot[_clientNum]["pkey"], slot[_clientNum]["isBot"], name, slot[_clientNum]["start"], slot[_clientNum]["start"], conname)
	--[[ Commented out - what did that here?
	slot[_clientNum]["xp0"] = et.gentity_get(_clientNum,"sess.skillpoints",0)
	slot[_clientNum]["xp1"] = et.gentity_get(_clientNum,"sess.skillpoints",1)
	slot[_clientNum]["xp2"] = et.gentity_get(_clientNum,"sess.skillpoints",2)
	slot[_clientNum]["xp3"] = et.gentity_get(_clientNum,"sess.skillpoints",3)
	slot[_clientNum]["xp4"] = et.gentity_get(_clientNum,"sess.skillpoints",4)
	slot[_clientNum]["xp5"] = et.gentity_get(_clientNum,"sess.skillpoints",5)
	slot[_clientNum]["xp6"] = et.gentity_get(_clientNum,"sess.skillpoints",6)
	slot[_clientNum]["xptot"] = slot[_clientNum]["xp0"] + slot[_clientNum]["xp1"] + slot[_clientNum]["xp2"] + slot[_clientNum]["xp3"] + slot[_clientNum]["xp4"] + slot[_clientNum]["xp5"] + slot[_clientNum]["xp6"]
	slot[_clientNum]["suspect"] = 0
	--]]
	
	slot[_clientNum]["new"] = nil
	slot[_clientNum]["xpset"] = true
	
	-- And now we will get all our default values 
	-- but why?
	updatePlayerInfo (_clientNum)
end

-------------------------------------------------------------------------------
-- timehandle
-- Function to handle times
-- TODO : check if the time returned with option 'D' is in the right format we need
-- TODO : actually, 'D' and 'DS' are almost equal: save some lines mergin them!!
-- NOTE ABOUT TIME IN LUA: the function os.difftime works only with arguments passed in seconds, so
--						   before pass anything to that functions we have to convert the date in seconds
--						   with the function os.time, then convert back the result with os.date
-------------------------------------------------------------------------------
function timehandle ( op, time1, time2)
	-- The os.* functions needs a shell to be linked and accessible by the process running LUA
	-- TODO : this check should be moved at script start because os.* functions are really
	-- 		  "popular" so we may use them in other functions too
	if os.execute() == 0 then
		error("This process needs an active shell to be executed.")
	end

	local timed = nil

	if op == 'N' then
		-- N -> return current date ( NOW )
		local timed = os.date("%Y-%m-%d %X")
		if timed then
			return timed
		end
		return nil
	elseif op == 'D' then
	    -- D -> compute time difference time1-time2
	    if time1==nil or time2==nil then
	        error("You must to input 2 arguments to use the 'D' option.")
	    end

	    -- Check if time1 is 'N' ( NOW )
	    if time1 == 'N' then
	    	-- Check if time2 is in the right format
	    	if string.len(time2) == 19 then
	    		timed = os.difftime(os.time(),os.time{year=tonumber(string.sub(time2,1,4)), month=tonumber(string.sub(time2,6,7)), day=tonumber(string.sub(time2,9,10)), hour=tonumber(string.sub(time2,12,13)), min=tonumber(string.sub(time2,15,16)), sec=tonumber(string.sub(time2,18,19))})
			end
	    end
	    -- Check if time1 and time2 are in the right format
	    if string.len(time1) == 19 and string.len(time2) == 19 then
      		timed = os.difftime(os.time{year=tonumber(string.sub(time1,1,4)), month=tonumber(string.sub(time1,6,7)), day=tonumber(string.sub(time1,9,10)), hour=tonumber(string.sub(time1,12,13)), min=tonumber(string.sub(time1,15,16)), sec=tonumber(string.sub(time1,18,19))},os.time{year=tonumber(string.sub(time2,1,4)), month=tonumber(string.sub(time2,6,7)), day=tonumber(string.sub(time2,9,10)), hour=tonumber(string.sub(time2,12,13)), min=tonumber(string.sub(time2,15,16)), sec=tonumber(string.sub(time2,18,19))})
	    end
	elseif op == 'DS' then
	    -- DS -> compute time difference time1-time2 and return result in seconds
	    if time1==nil or time2==nil then
	        error("You must to input 2 arguments to use the 'DS' option.")
	    end

	    -- Check if time1 is 'N' ( NOW )
	    if time1 == 'N' then
	    	-- Check if time2 is in the right format
	    	if string.len(time2) == 19 then
	    		timed = os.difftime(os.time(),os.time{year=tonumber(string.sub(time2,1,4)), month=tonumber(string.sub(time2,6,7)), day=tonumber(string.sub(time2,9,10)), hour=tonumber(string.sub(time2,12,13)), min=tonumber(string.sub(time2,15,16)), sec=tonumber(string.sub(time2,18,19))})
				return timed
			end
	    end
	    -- Check if time1 and time2 are in the right format
	    if string.len(time1) == 19 and string.len(time2) == 19 then
      		timed = os.difftime(os.time{year=tonumber(string.sub(time1,1,4)), month=tonumber(string.sub(time1,6,7)), day=tonumber(string.sub(time1,9,10)), hour=tonumber(string.sub(time1,12,13)), min=tonumber(string.sub(time1,15,16)), sec=tonumber(string.sub(time1,18,19))},os.time{year=tonumber(string.sub(time2,1,4)), month=tonumber(string.sub(time2,6,7)), day=tonumber(string.sub(time2,9,10)), hour=tonumber(string.sub(time2,12,13)), min=tonumber(string.sub(time2,15,16)), sec=tonumber(string.sub(time2,18,19))})
			return timed
		end
	end

 	if timed then
		if timed < 60 then
		    if timed < 10 then
		        return string.format("00:00:0%d",timed)
		    else
	    		return string.format("00:00:%d",timed)
	    	end
	    end

	    local seconds = timed % 60
	    local minutes = (( timed - seconds ) / 60 )

	    if minutes < 60 then
	        if minutes < 10 and seconds < 10 then
	    		return string.format("00:0%d:0%d",minutes,seconds)
	    	elseif minutes < 10 then
	    	    return string.format("00:0%d:%d",minutes,seconds)
			elseif seconds < 10 then
			    return string.format("00:%d:0%d",minutes,seconds)
			else
			    return string.format("00:%d:%d",minutes,seconds)
			end
	    end

	    minutes = minutes % 60
	    local houres = ((( timed - seconds ) / 60 ) - minutes ) / 60

		if minutes < 10 and seconds < 10 then
			return string.format("%d:0%d:0%d",houres,minutes,seconds)
		elseif minutes < 10 then
	    	return string.format("%d:0%d:%d",houres,minutes,seconds)
		elseif seconds < 10 then
			return string.format("%d:%d:0%d",houres,minutes,seconds)
		else
			return string.format("%d:%d:%d",houres,minutes,seconds)
		end
	end

	return nil
end

-------------------------------------------------------------------------------
-- WriteClientDisconnect
-- Dumps Client into Dbase at Disconnect or end of round
-- This function really dumps everything by calling our two helper functions
-------------------------------------------------------------------------------
function WriteClientDisconnect( _clientNum, _now, _timediff )
	if tonumber(et.trap_Cvar_Get( "gamestate" )) ~= 1 then 	-- in warmup no db interaction

		if slot[_clientNum]["team"] == false then
			slot[_clientNum]["uci"] = et.gentity_get( _clientNum ,"sess.uci")
			-- In this case the player never entered the game world, he disconnected during connection time
			
			-- TODO : check if this works. Is the output from 'D' option in the needed format for the database?
			DBCon:SetPlayerSessionWCD( slot[_clientNum]["pkey"], _clientNum, map, slot[_clientNum]["ip"], "0", slot[_clientNum]["start"], timehandle('N'), timehandle('D','N',slot[_clientNum]["start"]), slot[_clientNum]["uci"] )
			
			
			et.G_LogPrint( "Noq: saved player ".._clientNum.." to Database\n" ) 
		else
			-- The player disconnected during a valid game session. We have to close his playing time
			-- If "team" == -1 means we already closed the team time, so we don't have to do it again
			-- This is needed to stop team time at map end, when debriefing starts
			if slot[_clientNum]["team"] ~= -1 then
				closeTeam ( _clientNum )
			end
							
			-- Write to session if player was in game
			saveSession ( _clientNum )
			savePlayer ( _clientNum )
			et.G_LogPrint( "Noq: saved player and session ".._clientNum.." to Database\n" )

		end	
		slot[_clientNum]["ntg"] = false
		
	end
end

-------------------------------------------------------------------------------
-- savePlayer
-- Dumps into player table - NO SESSIONDUMPING
-- call if you changed something important to secure it in database
-- eg Xp, Level, Ban, Mute
-- is also called at every Disconnect
-------------------------------------------------------------------------------
function savePlayer ( _clientNum )
	slot[_clientNum]["ip"] = et.Info_ValueForKey( et.trap_GetUserinfo( _clientNum ), "ip" )
	if slot[_clientNum]["ip"] == "localhost" then
		-- He is a bot, mark it's ip as "localhost"
		slot[_clientNum]["ip"] = "127.0.0.1"
	else
		s,e,slot[_clientNum]["ip"] = string.find(slot[_clientNum]["ip"],"(%d+%.%d+%.%d+%.%d+)")
	end 
	
	if slot[_clientNum]["xpset"] == false and xprestore == 1 then
    	et.G_LogPrint("NOQ: ERROR while setting xp in database: XP not properly restored!\n")
    	return
    end

	-- We also write to player, for our actual data
	-- TODO
	-- slot[_clientNum]["user"] 
	-- slot[_clientNum]["password"] 
	-- slot[_clientNum]["email"] 
	-- slot[_clientNum]["netname"] ????

	local name = string.gsub(slot[_clientNum]["netname"],"\'", "\\\'")

	if slot[_clientNum]["muteexpire"] ~= "1000-01-01 00:00:00" and timehandle( 'DS', 'N', slot[_clientNum]["muteexpire"] ) > 0 then
		slot[_clientNum]["mutedby"] = ""
		slot[_clientNum]["mutedreason"] = ""
		slot[_clientNum]["muteexpire"] = "1000-01-01 00:00:00"
	end
	slot[_clientNum]["xp0"] = et.gentity_get(_clientNum,"sess.skillpoints",0)
	slot[_clientNum]["xp1"] = et.gentity_get(_clientNum,"sess.skillpoints",1)
	slot[_clientNum]["xp2"] = et.gentity_get(_clientNum,"sess.skillpoints",2)
	slot[_clientNum]["xp3"] = et.gentity_get(_clientNum,"sess.skillpoints",3)
	slot[_clientNum]["xp4"] = et.gentity_get(_clientNum,"sess.skillpoints",4)
	slot[_clientNum]["xp5"] = et.gentity_get(_clientNum,"sess.skillpoints",5)
	slot[_clientNum]["xp6"] = et.gentity_get(_clientNum,"sess.skillpoints",6)
	slot[_clientNum]["xptot"] = slot[_clientNum]["xp0"] + slot[_clientNum]["xp1"] + slot[_clientNum]["xp2"] + slot[_clientNum]["xp3"] + slot[_clientNum]["xp4"] + slot[_clientNum]["xp5"] + slot[_clientNum]["xp6"]
	
	DBCon:SetPlayerInfo( slot[_clientNum] )
	
end

-------------------------------------------------------------------------------
-- saveSession
-- Dumps the sessiondata
-- should only be used on session-end to not falsify sessions
-------------------------------------------------------------------------------
function saveSession( _clientNum )
	if recordbots == 0 and slot[_clientNum]["isBot"] == 1 then
		 et.G_LogPrint( "Noq: not saved bot session ".._clientNum.." to Database" )
		return
	end

	-- TODO: fixme sqlite only ?
	-- TODO: think about moving these vars into client structure earlier ...
	slot[_clientNum]["uci"] = et.gentity_get( _clientNum ,"sess.uci")
	slot[_clientNum]["ip"] = et.Info_ValueForKey( et.trap_GetUserinfo( _clientNum ), "ip" )
	
	if slot[_clientNum]["ip"] == "localhost" then
		-- He is a bot, mark it's ip as "localhost"
		slot[_clientNum]["ip"] = "127.0.0.1"
	else
		s,e,slot[_clientNum]["ip"] = string.find(slot[_clientNum]["ip"],"(%d+%.%d+%.%d+%.%d+)")
	end 

	-- If player was ingame, we really should save his XP to!
	-- TODO: think about updating this into client structure at runtime
	-- The final questions is: Do we need the XP stuff at runtime in the client structure ?
	slot[_clientNum]["xp0"] = et.gentity_get(_clientNum,"sess.skillpoints",0)
	slot[_clientNum]["xp1"] = et.gentity_get(_clientNum,"sess.skillpoints",1)
	slot[_clientNum]["xp2"] = et.gentity_get(_clientNum,"sess.skillpoints",2)
	slot[_clientNum]["xp3"] = et.gentity_get(_clientNum,"sess.skillpoints",3)
	slot[_clientNum]["xp4"] = et.gentity_get(_clientNum,"sess.skillpoints",4)
	slot[_clientNum]["xp5"] = et.gentity_get(_clientNum,"sess.skillpoints",5)
	slot[_clientNum]["xp6"] = et.gentity_get(_clientNum,"sess.skillpoints",6)
	slot[_clientNum]["xptot"] = slot[_clientNum]["xp0"] + slot[_clientNum]["xp1"] + slot[_clientNum]["xp2"] + slot[_clientNum]["xp3"] + slot[_clientNum]["xp4"] + slot[_clientNum]["xp5"] + slot[_clientNum]["xp6"]
	
	DBCon:SetPlayerSession( slot[_clientNum], map, _clientNum )
end

-------------------------------------------------------------------------------
-- gotCmd
-- determines and prepares the arguments for our Shrubcmds
-------------------------------------------------------------------------------
function gotCmd( _clientNum, _command, _vsay)
	local argw = {}
	local arg0 = string.lower(et.trap_Argv(0))
	local arg1 = string.lower(et.trap_Argv(1))
	local arg2 = string.lower(et.trap_Argv(2))
	local argcount = et.trap_Argc()  

	local cmd
	-- TODO: we should use level from Lua client model
	local lvl = tonumber(et.G_shrubbot_level( _clientNum ) )
	local realcmd
	silent = false --to check in subfunctions if its a silent cmd
	
	if _vsay == nil then -- silent cmd
		cmd = string.sub(arg0 ,2)
		argw[1] = arg1
		argw[2] = arg2
		argw[3] = et.ConcatArgs( 3 )
		silent = true
	elseif _vsay == false then -- normal say
		cmd = string.sub(arg1 ,2)
		argw[1] = arg2
		argw[2] = et.trap_Argv(3)
		argw[3] = et.ConcatArgs( 4 )
	else  -- its a vsay!
		cmd = string.sub(arg2 ,2)
		argw[1] = et.trap_Argv(3)
		argw[2] = et.trap_Argv(4)
		argw[3] = et.ConcatArgs( 5 )
	end

	-- thats a hack to clearly get the second parameter.
	-- NQ-Gui chat uses cvars to pass the say-content
	if string.find(cmd, " ") ~= nil then
		t = justWords(cmd)
		cmd = t[1]
		table.remove(t ,1 )
		argw = t
		if t[1] == nil then t[1] = "" end
		if t[2] == nil then t[2] = "" end
		if t[3] == nil then t[3] = "" end
		
	end

	-- We search trought the commands-array for a suitable command
	for i=lvl, 0, -1 do
		if commands["cmd"][i][cmd] ~= nil then
			if cmd == 'help' then
				if argw[1] == "" then
					et.trap_SendConsoleCommand(et.EXEC_APPEND, "csay ".. _clientNum .. " \"^FFor NOQ help type !cmdlist.. \"")	
				else
					for i=lvl, 0, -1 do
						if commands["hlp"][i][argw[1]] ~= nil then
							helpCmd( _clientNum, argw[1], i) 
							return 1
						end
					end
				end
			else 
				execCmd(_clientNum, commands["cmd"][i][cmd], argw)
				if _vsay == nil then
					return 1
				end
			end 
			return
		end
	end
end

-------------------------------------------------------------------------------
-- justWords
-- Splits a string into a table on occurence of Whitespaces
-------------------------------------------------------------------------------
function justWords( _str )
	local t = {}
	local function helper(word)	table.insert(t, word) return "" end
	if not _str:gsub("%S+", helper):find"%S" then 	return t end
end

-------------------------------------------------------------------------------
-- helpCmd
-- prints help from custom commands
-- 
-------------------------------------------------------------------------------
function helpCmd(_clientNum , cmd, i, fullmsg)
	-- Colors same as in NQ
	local tc = "^D" -- title color
	local nc = "^Y" -- text color
	local hc = "^R" -- highlight color
	et.trap_SendConsoleCommand(et.EXEC_NOW, "qsay \"".. slot[_clientNum]["netname"] .. "^7: ^2!help " .. cmd .. "\"")	
	et.trap_SendServerCommand( _clientNum,"print \"" .. tc .. "help: " .. nc .. "NOQ help for '" .. hc .. cmd .. nc .. "':\n\"")
	et.trap_SendServerCommand( _clientNum,"print \"" .. tc .. "Function: " .. nc .. commands["hlp"][i][cmd] .. "\n\"")
	et.trap_SendServerCommand( _clientNum,"print \"" .. tc .. "Syntax: " .. hc .. commands["syn"][i][cmd] .. "\n\"")
end
-------------------------------------------------------------------------------
-- execCmd
-- The real work to exec a cmd is done here, all substitutions and the switch for
-- Lua and shellcommands are done here
-------------------------------------------------------------------------------
function execCmd(_clientNum , _cmd, _argw)
	local str = _cmd
	local lastkilled = slot[_clientNum]["victim"]
	local lastkiller = slot[_clientNum]["killer"] 
	
	if lastkilled == 1022 then
		nlastkilled = "World"
	elseif lastkilled == -1 then -- well, fresh player...
		lastkilled = _clientNum
		nlastkilled = "nobody"
	elseif lastkilled == _clientNum then
		nlastkilled = "myself"
	else
		nlastkilled = et.gentity_get(lastkilled, "pers.netname")
	end
	
	if lastkiller == 1022 then 
		nlastkiller = "World"
		if slot[_clientNum]["deadwep"] == 'FALLING' then
			nlastkiller = "\'Newton\'s third law\'"		
		end
	elseif lastkiller == -1 then
		lastkiller = _clientNum
		nlastkiller = "nobody"
	elseif lastkiller == _clientNum then
		nlastkiller = "myself"
	else
		nlastkiller = et.gentity_get(lastkiller, "pers.netname")
	end
	
	local otherplayer = _argw[1]
	
	local assume = false
	otherplayer = getPlayerId(otherplayer)
	if otherplayer == nil then
		otherplayer = _clientNum
		assume = true
	end

	local t = tonumber(et.gentity_get(_clientNum,"sess.sessionTeam"))
	local c = tonumber(et.gentity_get(_clientNum,"sess.latchPlayerType"))
	local str = string.gsub(str, "<CLIENT_ID>", _clientNum)
	local str = string.gsub(str, "<GUID>", slot[_clientNum]["pkey"])
	local str = string.gsub(str, "<COLOR_PLAYER>", slot[_clientNum]["netname"])
	local str = string.gsub(str, "<ADMINLEVEL>", slot[_clientNum]["level"] )
	local str = string.gsub(str, "<PLAYER>", slot[_clientNum]["cleanname"])
	local str = string.gsub(str, "<PLAYER_CLASS>", class[c])
	local str = string.gsub(str, "<PLAYER_TEAM>", team[t])
	local str = string.gsub(str, "<PARAMETER>", table.concat(_argw , " ") )
	local str = string.gsub(str, "<P1>", _argw[1] )
	local str = string.gsub(str, "<P2>", _argw[2] )
	local str = string.gsub(str, "<P3>", _argw[3] )
	local str = string.gsub(str, "<PLAYER_LAST_KILLER_ID>", lastkiller )
	local str = string.gsub(str, "<PLAYER_LAST_KILLER_NAME>", et.Q_CleanStr( nlastkiller ))
	local str = string.gsub(str, "<PLAYER_LAST_KILLER_CNAME>", nlastkiller )
	local str = string.gsub(str, "<PLAYER_LAST_KILLER_WEAPON>", slot[_clientNum]["deadwep"])
	local str = string.gsub(str, "<PLAYER_LAST_VICTIM_ID>", lastkilled )
	local str = string.gsub(str, "<PLAYER_LAST_VICTIM_NAME>", et.Q_CleanStr( nlastkilled ))
	local str = string.gsub(str, "<PLAYER_LAST_VICTIM_CNAME>", nlastkilled )
	local str = string.gsub(str, "<PLAYER_LAST_VICTIM_WEAPON>", slot[_clientNum]["killwep"])
	local str = string.gsub(str, "<SERVID>", serverid )

	--TODO Implement them (Most of them are from Kmod/EtAdmin)
	--  Other possible Variables: <CVAR_XXX> <????>
	-- local str = string.gsub(str, "<PLAYER_LAST_KILL_DISTANCE>", calculate! )
	--local str = string.gsub(str, "<PNAME2ID>", pnameID)
	--local str = string.gsub(str, "<PBPNAME2ID>", PBpnameID)
	--local str = string.gsub(str, "<PB_ID>", PBID)
	--local str = string.gsub(str, "<RANDOM_ID>", randomC) 
	--local str = string.gsub(str, "<RANDOM_CNAME>", randomCName)
	--local str = string.gsub(str, "<RANDOM_NAME>", randomName)
	--local str = string.gsub(str, "<RANDOM_CLASS>", randomClass)
	--local str = string.gsub(str, "<RANDOM_TEAM>", randomTeam)
	--local teamnumber = tonumber(et.gentity_get(PlayerID,"sess.sessionTeam"))
	--local classnumber = tonumber(et.gentity_get(PlayerID,"sess.latchPlayerType"))
		
--		if otherplayer == _clientNum then -- "light security" to not ban or kick yourself (use only ids to ban or kick, then its safe)
	if assume == true then
		str = string.gsub(str, "<PART2PBID>", "65" )
		str = string.gsub(str, "<PART2ID>", "65" ) 
	end
		
	--else
	local t = tonumber(et.gentity_get(otherplayer,"sess.sessionTeam"))
	local c = tonumber(et.gentity_get(otherplayer,"sess.latchPlayerType"))
	str = string.gsub(str, "<PART2_CLASS>", class[c])
	str = string.gsub(str, "<PART2_TEAM>", team[t])
	str = string.gsub(str, "<PART2CNAME>", et.gentity_get(otherplayer, "pers.netname" ))
	str = string.gsub(str, "<PART2ID>", otherplayer )
	str = string.gsub(str, "<PART2PBID>", otherplayer + 1 ) 
	str = string.gsub(str, "<PART2GUID>", et.Info_ValueForKey( et.trap_GetUserinfo( otherplayer ), "cl_guid" ))
	str = string.gsub(str, "<PART2LEVEL>", et.G_shrubbot_level (otherplayer) )
	str = string.gsub(str, "<PART2NAME>", et.Q_CleanStr(et.gentity_get(otherplayer,"pers.netname")))
	str = string.gsub(str, "<PART2IP>", slot[_clientNum]["ip"] )
	
	--added for !afk etc, use when assume is ok 
	 str = string.gsub(str, "<PART2IDS>", otherplayer )
	
	-- This allows execution of lua-code in a normal Command. 
	if string.sub(str, 1,5) == "$LUA$" then
		--et.G_Print(string.sub(str,6))
		local tokall = loadstring(string.sub(str,6))
		tokall()
		return	
	elseif  string.sub(str, 1,5) == "$SHL$" then
	-- This allows Shell commands. WARNING: As long as lua waits for the command to complete, NQ+ET aren't responding to anything, they are HALTED!
	-- Response of the Script is piped into NQ-Console(via print, so no commands)
			execthis = io.popen(string.sub(str,6))
			myreturn = execthis:read("*a")
			execthis:close()
			myreturn = string.gsub(myreturn, "\n","\"\nqsay \"")
			et.trap_SendConsoleCommand(et.EXEC_APPEND, "qsay \" ".. myreturn .. " \"")	
	else
		-- well, at the end we send the command to the console
		et.trap_SendConsoleCommand( et.EXEC_APPEND, "".. str .. "\n " )
		
	end
	
end

-------------------------------------------------------------------------------
-- getPlayerId
-- helper function to compute the clientid matching a part-string or the clientid
-------------------------------------------------------------------------------
function getPlayerId( _name )
    -- if it's nil, return nil
    if (_name == "") or _name == nil then
        return nil
    end

    -- if it's a number, interpret as slot number
    local clientnum = tonumber(_name)
    if clientnum then
        if (clientnum <= maxclients) and tonumber(et.gentity_get(clientnum,"inuse")) == 1 then
            return clientnum
        else
            return nil
        end
    end

	local test = et.ClientNumberFromString( _name ) -- Cool NQ function!
	if test == -1 then
    	return nil
	else
		return test
	end
end

-------------------------------------------------------------------------------
-- parseconf
-- Parses commandos from commandofile function
-------------------------------------------------------------------------------
function parseconf()
	local datei = io.open ( (scriptpath .. "noq_commands.cfg" ) ,"r") 

	-- Shrub uses only 31 Levels. at least wiki says
	commands["cmd"] = {}
	commands["syn"] = {}
	commands["hlp"] = {}
	commands["listing"] = {}
	for i=0, 31, 1 do
		commands["cmd"][i] = {}
		commands["syn"][i] = {}
		commands["hlp"][i] = {}
	end
	
	local nmr = 1
	local nmr2 = 1
	local lasti = nil
	local lastcmd = nil
	for line in datei:lines() do
		local filestr = line
		local testcase = string.find(filestr, "^%s*%#")
		if testcase == nil then
			local testcase = string.find(filestr, "^%s*%w+%s*%=%s*")
			if testcase ~= nil then
				debugPrint("logprint",filestr)
				
				for  helptype, helptext in string.gfind(filestr, "^*%s*(%w+)%s*%=%s*(.*)[^%\n]*") do
					debugPrint("logprint",helptext)
					if helptype == "help" then
						commands["hlp"][lasti][lastcmd] = helptext
					else
						commands["syn"][lasti][lastcmd] = helptext
					end
				end
			else
				for level,comm,commin in string.gfind(filestr, "^*([0-9]*)%s*%-%s*(%w+)%s*%=%s*(.*)[^%\n]*") do
					-- et.G_LogPrint ("Parsing CMD:"..comm .. " Level: "..level.." Content: ".. commin .."\n")	
					i = tonumber(level)
					commands["cmd"][i][comm] = commin
					commands["hlp"][i][comm] = "n/a"
					commands["syn"][i][comm] = "n/a"
				
					nmr = nmr +1
					lasti = i
					lastcmd = comm
				end
			end
		end
		nmr2 = nmr2 +1
	end

	datei:close()
	et.G_LogPrint("NOQ: Parsed " ..nmr .." commands from "..nmr2.." lines. \n")
end

-------------------------------------------------------------------------------
-- Init NOQ function
-------------------------------------------------------------------------------
function initNOQ ()
	-- get all we need at gamestart from game
	gstate = tonumber(et.trap_Cvar_Get( "gamestate" ))
	map = tostring(et.trap_Cvar_Get("mapname"))
end

-------------------------------------------------------------------------------
-- getDBVersion
-- Checks for correct DBVersion
-- Disables DBaccess on wrong version!
-------------------------------------------------------------------------------
function getDBVersion()
	-- Check the database version
	local versiondb = DBCon:GetVersion()
	
	if versiondb == version then
		databasecheck = 1
		et.G_LogPrint("NOQ: Database "..DBCon.dbname.." is up to date. Script version is ".. version .."\n")
	else
		et.G_LogPrint("NOQ: Database "..DBCon.dbname.." is not up to date: DBMS support disabled! Requested version is ".. version .."\n")
		-- We don't need to keep the connection with the database open
		DBCon:DoDisconnect()
	end
end

-------------------------------------------------------------------------------
-- updateTeam
-- set times accordingly when the player changes team
-------------------------------------------------------------------------------
function updateTeam( _clientNum )
	local teamTemp = tonumber(et.gentity_get(_clientNum,"sess.sessionTeam"))
	
	if teamTemp ~= tonumber(slot[_clientNum]["team"]) then -- now we have teamchange!!!
		if debug == 1 then
			if tonumber(slot[_clientNum]["team"]) ~= nil and teamTemp ~= nil then
				debugPrint("cpm","TEAMCHANGE: " .. team[tonumber(slot[_clientNum]["team"])] .. " to " .. team[teamTemp])
			end
		end
		
		closeTeam ( _clientNum )
		-- Now, we change the teamchangetime & team
		slot[_clientNum]["lastTeamChange"] = (et.trap_Milliseconds() / 1000 )
		slot[_clientNum]["team"] = teamTemp
	end
end

-------------------------------------------------------------------------------
-- closeTeam
-- closes a time session for a player
-------------------------------------------------------------------------------
function closeTeam( _clientNum )
	if tonumber(slot[_clientNum]["team"]) == 1 then -- axis
		slot[_clientNum]["axtime"] = slot[_clientNum]["axtime"] +( (et.trap_Milliseconds() / 1000) - slot[_clientNum]["lastTeamChange"]  )
	elseif tonumber(slot[_clientNum]["team"]) == 2 then -- allies
		slot[_clientNum]["altime"] = slot[_clientNum]["altime"] +( (et.trap_Milliseconds() / 1000) - slot[_clientNum]["lastTeamChange"]  )
	elseif tonumber(slot[_clientNum]["team"]) == 3 then -- Spec
		slot[_clientNum]["sptime"] = slot[_clientNum]["sptime"] +( (et.trap_Milliseconds() / 1000) - slot[_clientNum]["lastTeamChange"]  )
	end
		
	-- Set the player team to -1 so we know he cannot to change team anymore
	slot[_clientNum]["team"] = -1
end	

-------------------------------------------------------------------------------
-- mail functions
-------------------------------------------------------------------------------
function sendMail( _to, _subject, _text )
	if mail == 1 then
		-- TODO: clean up
		local mailserv = getConfig("mailserv")
		local mailport = getConfig("mailport")
		local mailfrom = getConfig("mailfrom")
		rcpt = _to
		-- end clean up

		mesgt = {
					headers = 	{
								to = _to,
								subject = _subject
								},
					body = _text
				}


		r, e = smtp.send {
		   from = mailfrom,
		   rcpt = rcpt, 
		   source = smtp.message(mesgt),
		   --user = "",
		   --password = "",
		   server = mailserv,
		   port = mailport
		}

		if (e) then
		   et.G_LogPrint("NOQ: Could not send email: "..e.. "\n")
		end
	else
		et.G_LogPrint("NOQ: Mails disabled.\n")
	end
end

-------------------------------------------------------------------------------
-- checkBalance ( force )
-- Checks for uneven teams and tries to even them
-- force is a boolean controlling if there is only an announcement or a real action is taken.
-- Action is taken if its true.
-------------------------------------------------------------------------------
function checkBalance( _force )
	-- TODO: Do we need extra tables to store this kind of data ?
	local axis = {} -- is this a field required?
	local allies = {} -- is this a field required?
	local numclients = 0

	for i=0, et.trap_Cvar_Get( "sv_maxclients" ) -1, 1 do					
		if slot[i]["inuse"] then
			local team = tonumber(et.gentity_get(i,"sess.sessionTeam"))
			if team == 1 then
				table.insert(axis,i)
			end 
			if team == 2 then
				table.insert(allies,i)
			end
			
			numclients = numclients + 1
		end
	end
    

	local numaxis   = # axis
	local numallies = # allies
	local greaterteam = 3
	local smallerteam = 3
	local gtable = {}
	local teamchar = { "r" , "b" , "s" }

	if numaxis > numallies then
		greaterteam = 1
		smallerteam = 2
		gtable = axis
	end
	if numallies > numaxis then
		greaterteam = 2
		smallerteam = 1
		gtable = allies
	end


	if math.abs(numaxis - numallies) >= 5 then
		evener = evener +1
		if _force == true and evener >= 2  then
			et.trap_SendConsoleCommand( et.EXEC_NOW, "!shuffle " )
			et.trap_SendConsoleCommand( et.EXEC_APPEND, "cpm \"^2EVENER: ^1TEAMS SHUFFLED \" " )
		else
			et.trap_SendConsoleCommand( et.EXEC_APPEND, "cpm \"^1EVEN TEAMS OR SHUFFLE \" " )
		end
		return
	end

	if math.abs(numaxis - numallies) >= 3 then
		evener = evener +1
		if _force == true and evener >= 3  then
			local rand = math.random(# gtable)
			local cmd =  "!put ".. gtable[rand] .." "..teamchar[smallerteam].." \n"  
			--et.G_Print( "CMD: ".. cmd .. "\n") 
			et.trap_SendConsoleCommand( et.EXEC_APPEND, cmd ) 
			et.trap_SendServerCommand(-1 , "chat \"^2EVENER: ^7Thank you, ".. slot[gtable[rand]]["netname"] .." ^7for helping to even the teams. \" ")
		else
			et.trap_SendConsoleCommand( et.EXEC_APPEND, "chat \"^2EVENER: ^1Teams seem unfair, would someone from ^2".. team[greaterteam] .."^1 please switch to ^2"..team[smallerteam].."^1?  \" " )
		end
		
		return
	else
		evener = 0
	end
end

-------------------------------------------------------------------------------
-- greetClient - greets a client after his first clientbegin
-- only call after netname is set!
-------------------------------------------------------------------------------
function greetClient( _clientNum )
	local lvl = tonumber(slot[_clientNum]["level"])
	if greetings[lvl] ~= nil then
		et.trap_SendConsoleCommand(et.EXEC_APPEND, "cpm " .. string.gsub(greetings[lvl], "<COLOR_PLAYER>", slot[_clientNum]["netname"]) .. "\n")
	end
end

-------------------------------------------------------------------------------
-- checkOffMesg - checks for OfflineMessages
-- Player needs to be registered to use OM
-------------------------------------------------------------------------------
function checkOffMesg (_clientNum)
	if slot[_clientNum]["user"] ~= "" then
	-- he is registered
		local OM = DBCon:GetLogTypefor("5", slot[_clientNum]["pkey"])
		
		if OM ~= nil then
			-- he has OMs!!!!!!!!1!!!!
			et.trap_SendServerCommand(_clientNum, "print \"\n^3*** ^1NEW OFFLINEMESSAGES ^3***\"")
			et.trap_SendServerCommand(_clientNum, "cpm \"^3*** ^1NEW OFFLINEMESSAGES ^3***\"")
			et.trap_SendServerCommand(_clientNum, "chat \"^3*** ^1NEW OFFLINEMESSAGES ^3***\"")
			
			--TODO: fix sound  to be only heard by this client.
			local sndin = et.G_SoundIndex( "sound/misc/pm.wav" )
			et.G_Sound( _clientNum, sndin )
			
			for mesnum = 1, #OM, 1 do
				local xml = OM[mesnum].textxml
				local posstart , posend = string.find(xml, "<msg>", 1)
				local msg = string.sub(xml , posstart+5 , (#xml- 12))
				posstart , posend = string.find(xml, "<from>.*</from>", 1)
				local from = string.sub(xml, posstart+6, posend-7)
				
				et.trap_SendServerCommand(_clientNum, "print \"\n^3*** ^1MESSAGE ^R".. mesnum .."^3***\"")
				et.trap_SendServerCommand(_clientNum, "print \"\n^3*** ^YFrom: ^R".. from .." ^YMSGID: ^R".. OM[mesnum].id .." ^3***\"")
				et.trap_SendServerCommand(_clientNum, "print \"\n^3*** ^YDate: ".. OM[mesnum].createdate .." ^3***\"")
				et.trap_SendServerCommand(_clientNum, "print \"\n^3*** ^YMessage: ".. msg .." ^3***\n\"")
			end
			
				et.trap_SendServerCommand(_clientNum, "print \"\n^3*** Erase messages with /rmom MSGID ^3***\n\"")
			
		else
			et.trap_SendConsoleCommand(et.EXEC_NOW, "csay " .. _clientNum .. "\"^3No new offlinemessages\"\n")
		end
	else
		et.trap_SendConsoleCommand(et.EXEC_NOW, "csay " .. _clientNum .. "\"^3To use offlinemessages, please register\"\n")
	end

end

-------------------------------------------------------------------------------
-- sendOffMesg - sends a Offlinemessage
-- Player needs to be registered to use OM
-------------------------------------------------------------------------------
function sendOffMesg (_sender,_receiver, _msg)
	--TODO: Escape function
	_receiver = string.gsub(_receiver,"\'", "\\\'")
	_msg = string.gsub(_msg,"\'", "\\\'")
	
	if slot[_sender]["user"] ~= "" then
		-- he is registered
		
		if _receiver ~= "" and _msg ~= "" then
			
			player = DBCon:GetPlayerbyReg(_receiver)
			if player ~= nil then
				-- Reveiver is existing
				message = "<OfM><from>"..slot[_sender]["user"].."</from><to>".. player["user"] .."</to><figure></figure><msg>".._msg.."</msg></OfM>"
				--                	type	receiver				sender					text
				DBCon:SetLogEntry(	"5",	player['pkey'],			slot[_sender]['pkey'],		message)
				
				et.trap_SendConsoleCommand(et.EXEC_NOW, "csay " .. _sender .. "\"^3 Following message was sent to '".._receiver.."("..player['cleanname']..")'\"\n")
				et.trap_SendConsoleCommand(et.EXEC_NOW, "csay " .. _sender .. "\"^3 '".. _msg .."'\n\"\n")
		
			else
				et.trap_SendConsoleCommand(et.EXEC_NOW, "csay " .. _sender .. "\"^3Nobody registered the name'".. _receiver .."', so i cannot send him a message.\"\n")
			end
		
		else
			et.trap_SendConsoleCommand(et.EXEC_NOW, "csay " .. _sender .. "\"^3Check your syntax: ^R'/om receiver message'.\"\n")
		end
		
	else
		et.trap_SendConsoleCommand(et.EXEC_NOW, "csay " .. _sender .. "\"^3To use Offlinemessages, please register\"\n")
	end

end

-------------------------------------------------------------------------------
-- getresNames
-- get reserved Name patterns from the DB
-------------------------------------------------------------------------------
function getresNames()

		local NMs = DBCon:GetLogTypefor("6", nil, nil)
		
		if NMs ~= nil then
			namearray = {}
			for num = 1, #NMs, 1 do
				namearray[num] = NMs[num].textxml
			end
		else
			namearray = nil
		end
end

-------------------------------------------------------------------------------
-- reserveName
-- add a protected string to the Database
-------------------------------------------------------------------------------
function reserveName(_name)
	if _name ~= nil and _name ~= "" then
		DBCon:SetLogEntry(6, "" , "", _name )
		
		if _otherplayer then
			et.trap_SendConsoleCommand(et.EXEC_APPEND,"qsay \"^3Added ".._name.." to the protected patterns.\"" ) 
			et.G_Print("NOQ: Added '".._name.."' to the protected patterns.\"" )
		else
			et.G_Print("NOQ: Added '".._name.."' to the protected patterns.\"" )
		end
	
	end
end
		
-------------------------------------------------------------------------------
-- checkforResName(clientnum)
-- check if the name is reserved
-------------------------------------------------------------------------------
function checkforResName(_clientNum)
	if not slot[_clientNum]["netname"] then return end 
	local cleanname = string.lower(et.Q_CleanStr(slot[_clientNum]["netname"]))
	for i,v in ipairs(namearray) do
		if string.find( cleanname,v) then
			if string.find(slot[_clientNum]["clan"],v) then
				-- luck you - you are in the clan/have the name reserved for you
				et.G_Print("NOQ: Name for "..slot[_clientNum]["netname"].. " reserved and owned\n")
			else
				-- oops - rename him
				et.trap_SendConsoleCommand(et.EXEC_APPEND, "!rename ".._clientNum.. " ".. string.gsub(cleanname,v, "X") )
				-- TODO: Kick?
				et.trap_SendServerCommand( _clientNum, "chat \"^1Your tag/name is reserved or not allowed.\"")
			end
		end
	end
end					

-------------------------------------------------------------------------------
-- timeLeft
-- Returns rest of time to play
-------------------------------------------------------------------------------
function timeLeft()
	return tonumber(et.trap_Cvar_Get("timelimit"))*1000 - ( et.trap_Milliseconds() - mapStartTime) -- TODO: check this!
end

-------------------------------------------------------------------------------
-- pussyFactCheck
-- adjusts the Pussyfactor after an kill trough et_obituary
-- TODO: Add more cases for ugly teamkills (not only panzer ... knife, poison etc) 
-- cool weapons get a value < 100 lame weapons/activities > 100
-------------------------------------------------------------------------------
function pussyFactCheck( _victim, _killer, _mod )
	if pussyfact == 1 then
		if slot[_killer]["team"] == slot[_victim]["team"] then -- teamkill
			-- here it is teamkill
			-- NOTE: teamkill is not counted as a kill, wich means all added here is even stronger in its weight
			if _mod == mod["MOD_PANZERFAUST"] or _mod == mod["MOD_BAZOOKA"] then
				slot[_killer]["pf"] = slot[_killer]["pf"] + 170
			else
				slot[_killer]["pf"] = slot[_killer]["pf"] + 110
			end
		else -- no teamkill 
			-- TODO sort this by coolness
			if _mod == mod["MOD_KNIFE"] or _mod == mod["MOD_THROWKNIFE"] then
				slot[_killer]["pf"] = slot[_killer]["pf"] + 70
			elseif _mod == mod["MOD_PANZERFAUST"] or _mod == mod["MOD_BAZOOKA"] then
				slot[_killer]["pf"] = slot[_killer]["pf"] + 140
			elseif _mod == mod["MOD_FLAMETHROWER"] then
				slot[_killer]["pf"] = slot[_killer]["pf"] + 115
			elseif _mod == mod["MOD_POISON"] then
				slot[_killer]["pf"] = slot[_killer]["pf"] + 65
			elseif _mod == mod["MOD_GOOMBA"] or _mod == mod["MOD_DYNAMITE"] then
				slot[_killer]["pf"] = slot[_killer]["pf"] + 60
			elseif _mod == mod["MOD_KICKED"] or _mod == mod["MOD_BACKSTAB"] or _mod == mod["MOD_SHOVE"] then
				slot[_killer]["pf"] = slot[_killer]["pf"] + 40
			elseif _mod == mod["MOD_K43_SCOPE"] or _mod == mod["MOD_FG42_SCOPE"] or _mod == mod["MOD_GARAND_SCOPE"] then
				slot[_killer]["pf"] = slot[_killer]["pf"] + 90
			else
				-- if we count 100 up, nothing changes. at least it should 
				slot[_killer]["pf"] = slot[_killer]["pf"] + 100
			end
		end -- teamkill end

	end -- pussy end
end

-------------------------------------------------------------------------------
-- checkTKPoints
-- Check if we need to punish a teamkiller
-------------------------------------------------------------------------------
function checkTKPoints(_clientNum)

	--[[  
			TODO
	--]]

end

-------------------------------------------------------------------------------
-- sendtoIRCRelay
-- Will send a string to our IRC-Relay
-------------------------------------------------------------------------------
function sendtoIRCRelay(_txt)

    local res = client:send(_txt.."\n")

    if not res then
        debugPrint("logprint","send " .. "error")
    else
        debugPrint("logprint","send " .. _txt)
    end

end

-------------------------------------------------------------------------------
-- nPrint(_whom , _what)
-- Will print _what to _whom
-- _whom can be: 	-1  	-	 	Console
-- 					 0 - 64 -		Player(private)
--					 65		- 		Everyone
--					 
-- _what can be:
--					String
--					Array of Strings
--					
-- Note: Please dont use an table of tables - it will fail displaying strange numbers :)
-------------------------------------------------------------------------------
function nPrint(_whom, _what)

local mytype = type(_what)
	if _whom == -1 then
		--console
		if mytype == "string" then
			et.G_LogPrint(_what)
		elseif mytype == "table" then
			for i,v in ipairs(_what) do
			et.G_LogPrint(v)
			end
		end
		
	elseif _whom >= 0 and _whom <= 63 then
		-- player
		if mytype == "table" then
			for i,v in ipairs(_what) do
				et.trap_SendConsoleCommand(et.EXEC_APPEND,"csay ".. _whom .. " \"".. v .."\"\n " ) 
			end
		elseif mytype == "string" then
				et.trap_SendConsoleCommand(et.EXEC_APPEND,"csay ".. _whom .. " \"".. _what .."\"\n " ) 
		end
	else
		--everybody
		if mytype == "string" then
				et.trap_SendConsoleCommand(et.EXEC_APPEND,"qsay \"".. _what .."\"\n " ) 
		elseif mytype == "table" then
			for i,v in ipairs(_what) do
				et.trap_SendConsoleCommand(et.EXEC_APPEND,"qsay \"".. v .."\"\n " ) 
			end
		end
	
	end
end


--***************************************************************************
-- Here start the commands usually called trough the new command-system
-- they shouldn't change internals, they are more informative or helpfull
--***************************************************************************
-- Currently available:
-- printPlyrInfo
-- setLevel
-- addClan
-- cleanSession
-- pussyout
-- checkBalance
-- rm_pbalias
-- teamdamage
-- showmaps
-- listcmds
-- msgtoIRC
-- forAll
-- showTkTable

-------------------------------------------------------------------------------
-- printPlyrInfo(_whom, _about)
-- will print Info about player _about to player _whom
-- mimics !finger command if called from a silent !cmd
-------------------------------------------------------------------------------
function printPlyrInfo(_whom, _about)

	local mit = {}
		
		-- silent cmds dont display the !finger from shrub afterwards....
		if silent then
		table.insert( mit , "^dInfo about: ^r" .. slot[_about]["netname"] .. " ^r/ ^7" .. slot[_about]["cleanname"] .. "^r:" )
		table.insert( mit , "^dSlot:       ^r" .. _about )
		table.insert( mit , "^dAdmin:      ^r" .. slot[_about]["level"] )
		table.insert( mit , "^dGuid:       ^r" .. slot[_about]["pkey"] )
		table.insert( mit , "^dIP:         ^r" .. slot[_about]["ip"] )
		end
		
		table.insert( mit , "^dNOQ Info: " )
		
		if slot[_about]["user"] ~= "" then
		table.insert( mit , "^dUsername:   ^r" .. slot[_about]["user"] )
		end
		
		table.insert( mit , "^dFirst seen: ^r" .. slot[_about]["createdate"])
		table.insert( mit , "^dLast seen:  ^r" .. slot[_about]["updatedate"])
		table.insert( mit , "^dSpree:      ^r" .. slot[_about]["kspree"] )
		
		if slot[_about]["locktoTeam"] ~= nil then
		table.insert( mit , "^dTeamlock:   ^r" .. teamchars[slot[_about]["locktoTeam"]]  )
			if slot[_about]["lockedTeamTill"] ~= 0 then
		table.insert( mit , "^dSecs remain:^r" .. (slot[_about]["lockedTeamTill"] - (et.trap_Milliseconds() /1000 )) )		
			end
		end
		
		if slot[_about]["mutedby"] ~= "" then
		table.insert( mit , "^dMuted by:   ^7" .. slot[_about]["mutedby"])
		table.insert( mit , "^dReason:     ^r" .. slot[_about]["mutereason"])
		table.insert( mit , "^dUntil:	   ^r" .. slot[_about]["muteexpire"])
		end
	
		if slot[_about]["vsaydisabled"] then
		table.insert( mit , "^dHe is not allowed to use vsays")
		end
		
		nPrint(_whom,mit)
		
end

-------------------------------------------------------------------------------
-- setLevel(clientnum, level)
-- changes a players level
-------------------------------------------------------------------------------
function setLevel(_clientNum, _level)
		
		slot[_clientNum]['lvl'] = _level
		savePlayer( _clientNum )
end

-------------------------------------------------------------------------------
-- addClan(clientnum, tag)
-- adds a Clantag
-------------------------------------------------------------------------------
function addClan(_clientNum, _tag)
		slot[_clientNum]['clan'] = slot[_clientNum]['clan'] .. " "  .. _tag
		savePlayer( _clientNum )
		
		if otherplayer then
			et.trap_SendConsoleCommand(et.EXEC_APPEND,"qsay \"^3Added ".._tag.." to the patterns for "..slot[_clientNum]['netname']..".\"" ) 
			et.G_Print("NOQ: Added '".._tag.."' to the patterns for "..et.Q_CleanStr(slot[_clientNum]['netname'])..".\"" )
		else
			et.G_Print("NOQ: Added '".._tag.."' to the patterns for "..et.Q_CleanStr(slot[_clientNum]['netname'])..".\"" )
		end
end


-------------------------------------------------------------------------------
-- cleanSession
-- cleans the sessiontable from values older than X months
-- _arg for first call is amount of months, second call OK to confirm
-------------------------------------------------------------------------------
function cleanSession(_callerID, _arg)
	if arg == "" then
		et.trap_SendServerCommand(_callerID, "print \"\n Argument: first call: months to keep records, second call: OK  \n\"")
		return
	end

	if _arg == "OK" then
		if months ~= nil and months >= 1 and months <= 24 then
			et.trap_SendServerCommand(_callerID, "print \"\n Now erasing all records older than ".. months .." months  \n\"")
			
			DBCon:DoDeleteOldSessions(months)
			
			et.trap_SendServerCommand(_callerID, "print \"\n Erased all records older than ".. months .." months  \n\"")
			et.G_LogPrint( "Noq: Erased data older than "..months.." months from the sessiontable\n" )
			if _callerID ~= -1 then
				et.G_LogPrint( "Noq: Deletion was issued by: "..slot[_callerID]['netname'].. " , GUID:"..slot[_callerID]['pkey'].. " \n" )
			end
				 
		else
			et.trap_SendServerCommand(_callerID, "print \"\n Please at first specify a value between 1 and 24   \n\"")
			et.trap_SendServerCommand(_callerID, "print \"\n Example: <command> 1 erases all sessionrecords older than 1 month\n\"")
			return
		end
	
	elseif tonumber(_arg) >= 1 and tonumber(_arg) <= 24 then
		local months = tonumber(_arg)
		et.trap_SendServerCommand(_callerID, "print \"\n Please confirm the deletion of "..months.." month's data with OK as argument of the same command\n\"")
		
	else
		et.trap_SendServerCommand(_callerID, "print \"\n Please specify a value between 1 and 24  \n\"")
		return
	end

end

-------------------------------------------------------------------------------
-- pussyout
-- Displays the Pussyfactor for Player _ClientNum
-------------------------------------------------------------------------------
--[[
-- Some Documentation for Pussyfactor:
-- For every kill, we add a value to the clients number, and to determine the the Pussyfactor, we 
-- divide that number trough the number of his kills multiplicated with 100.
-- If we add 100 for an mp40/thompsonkill, if makes only those kills , he will stay at pussyfactor 1
-- if we add more or less(as 100) to the number, his pf will rise or decline.
-- 
-- Pussyfactor < 1 		means he made "cool kills" = poison, goomba, knive
-- Pussyfactor = 1 		means he makes normal kills
-- Pussyfactor > 1      means he does uncool kills (Panzerfaust, teamkills, arty?)
--
-- As we add 100 for every normal kill, the pussyfactor approaches 1 after some time with "normal" kills
-- 
--]]
function pussyout( _clientNum )
	local pf = slot[tonumber(_clientNum)]["pf"]
	-- TODO: use client structure slot[tonumber(_clientNum)]["kills"] -- it should be up to date!
	local kills = tonumber(et.gentity_get(_clientNum,"sess.kills"))
	local realpf = 1

	if pf == 0 or kills == 0 then
		et.trap_SendConsoleCommand(et.EXEC_APPEND, "qsay \"^1Do some kills first...\"")
		return
	else
		realpf = string.format("%.1f", ( pf / (100 * kills) ) )
	end

	-- TODO: do we need to number here =
	et.trap_SendConsoleCommand(et.EXEC_APPEND,"qsay \""..slot[tonumber(_clientNum)]["netname"].."^3's pussyfactor is at: ".. realpf ..".Higher is worse. \"" ) 
	et.G_LogPrint("NOQ: PUSSY: "..slot[tonumber(_clientNum)]["netname"].." at ".. realpf .."\n")
end

-------------------------------------------------------------------------------
-- rm_pbalias
-- removes all your aliases from the pbalias.dat
-- thks to hose! (yeah, this is cool!)
-------------------------------------------------------------------------------
function rm_pbalias( _myClient, _hisClient )
	et.trap_SendServerCommand(-1, "print \"function pbalias entered\n\"")
	
	local file_name = "pbalias.dat"
	local inFile = pbpath .. file_name
	local outFile = pbpath .. file_name

	local hisGuid = slot[_hisClient]["pkey"]
	local arg1 = string.lower(hisGuid:sub(25, 32))

	-- all input is evil! check for length!
	et.trap_SendServerCommand(_myClient, "print \"\nSearching for Guid: " .. arg1 .. "\"")
	local file = assert(io.open( inFile , "r"))
	local lineCounter = 0
	local lineTable = {}
	local deletedLines = {}
	local loopcounter = 0

	for line in file:lines() do
		lineCounter = lineCounter + 1
		if arg1 ~= line:sub(25, 32) then
			table.insert(lineTable, line)
		else 
			table.insert(deletedLines, line)
		end
	end

	local inserted = table.maxn(lineTable) 
	local deleted = table.maxn(deletedLines)
	file:close()

	if deleted > 0 then
		-- writing new pbalias.dat
		file = assert(io.open(outFile, "w+"))
		for i, v in ipairs(lineTable) do
			file:write(v .. "\n")
			loopcounter = loopcounter + 1
		end
		file:flush()
		file:close()
	end

	-- some status info printed to stdout
	et.trap_SendServerCommand(_myClient, "print \"\nEntries processed: " .. lineCounter .. "\"")
	et.trap_SendServerCommand(_myClient, "print \"\nEntries deleted: " .. deleted .. "\"")
	et.trap_SendConsoleCommand(et.EXEC_NOW, "pb_sv_restart")
	
	return 1
end

-------------------------------------------------------------------------------
-- teamdamage 
-- Displays information about teamdamage to the caller and a small line for all
-- thks to hose!
-------------------------------------------------------------------------------
function teamdamage( myclient, slotnumber ) -- TODO: change this to (_myclient, _slotnumber) 
	local teamdamage 	= et.gentity_get (slotnumber, "sess.team_damage")		
	local damage 		= et.gentity_get(slotnumber, "sess.damage_given")

	local classnumber 	= et.gentity_get(slotnumber, "sess.playerType")

	-- TODO: use slottable 
	local teamnumber 	= et.gentity_get(slotnumber, "sess.sessionTeam")
	local teamname 		= team[teamnumber]		

	et.trap_SendServerCommand( myclient, "print \" ^7:" .. et.gentity_get(slotnumber, "pers.netname") .. "^w | Slot: ".. slotnumber ..
		"\n" .. 		class[classnumber] .. " | " .. teamname .. " | " .. weapons[et.gentity_get(slotnumber, "sess.latchPlayerWeapon")] .. " | " ..  weapons[et.gentity_get(slotnumber, "sess.latchPlayerWeapon2")] .. 
		"\nkills:        " .. et.gentity_get(slotnumber, "sess.kills") ..   	" | damage:       " .. damage .. 
		"\nteamkills:    " .. et.gentity_get(slotnumber, "sess.team_kills") ..  " | teamdamage:   " .. teamdamage .. "\n\"")

	-- notorische teambleeder ab ins cp!!!
	if teamdamage == 0 then
		et.trap_SendServerCommand( slotnumber, "cp \" ^7You got ^1"..teamdamage.." teamdamage ^7and ^2" .. damage .. " damage given! ^1".. getConfig("teamdamageMessage1") .. "\"") 
	elseif teamdamage < damage/10 then
		et.trap_SendServerCommand( slotnumber, "cp \" ^7You got ^1"..teamdamage.." teamdamage ^7and ^2" .. damage .. " damage given! ^1".. getConfig("teamdamageMessage2").. "\"") 
	elseif teamdamage < damage/5 then
		et.trap_SendServerCommand( slotnumber, "cp \" ^7You got ^1"..teamdamage.." teamdamage ^7and ^2" .. damage .. " damage given! ^1".. getConfig("teamdamageMessage3").. "\"") 
	elseif teamdamage < damage/2 then
		et.trap_SendServerCommand( slotnumber, "cp \" ^7You got ^1"..teamdamage.." teamdamage ^7and ^2" .. damage .. " damage given! ^1".. getConfig("teamdamageMessage4").. "\"") 
	elseif teamdamage < damage then
		et.trap_SendServerCommand( slotnumber, "cp \" ^7You got ^1"..teamdamage.." teamdamage ^7and ^2" .. damage .. " damage given! ^1".. getConfig("teamdamageMessage5").. "\"") 
	else 
		et.trap_SendServerCommand( slotnumber, "cp \" ^7You got ^1"..teamdamage.." teamdamage ^7and ^2" .. damage .. " damage given! ^1".. getConfig("teamdamageMessage6").. "\"") 
	end
end

-------------------------------------------------------------------------------
-- showmaps
-- Reads the camapaign-info in, then compares with current map, then
-- displays all maps and marks the current one
-------------------------------------------------------------------------------
function showmaps()
	local ent = et.trap_Cvar_Get( "campaign_maps" ); -- TODO: create and use global var ? 
	local tat34 = {}
	local sep = ","

	-- helper function
	function split(str, pat)
	   local t = {}  -- NOTE: use {n = 0} in Lua-5.0
	   local fpat = "(.-)" .. pat
	   local last_end = 1
	   local s, e, cap = str:find(fpat, 1)
	   while s do
		  if s ~= 1 or cap ~= "" then
			 table.insert(t,cap)
		  end
		  last_end = e+1
		  s, e, cap = str:find(fpat, last_end)
	   end
	   if last_end <= #str then
		  cap = str:sub(last_end)
		  table.insert(t, cap)
	   end
	   return t
	end

	tat34 = split (ent, sep)
	local ent2 = "^3"

	map = tostring(et.trap_Cvar_Get("mapname"))

	-- helper function
	local function addit( i, v)
		if v == map  then
			ent2 = ent2 .. "^1" .. v .. "^3 <> "
		else
			ent2 = ent2 .. v .. " <> "
		end
	end

	for i,v in ipairs(tat34) do addit(i,v) end

	et.trap_SendConsoleCommand(et.EXEC_APPEND, "chat \"".. ent2 .. "\"")
end

-------------------------------------------------------------------------------
-- listCMDs
-- Returns a list of available Noq CMDs
-------------------------------------------------------------------------------
function listCMDs( _Client ,... )
	local lvl = tonumber(et.G_shrubbot_level( _Client ) )
	local allcmds = "\"^F"
	local yaAR = {}
	
	if commands["listing"][lvl] ~= nil then

	else -- we need to generate the listing first
		local CMDs = {}
		local mxlength = 7
		
		for i=lvl, 0, -1 do
			for index, cmd in pairs(commands["cmd"][i]) do 
				if CMDs.index ~= nil then
				else
				CMDs[index] = index
					if #index > mxlength then
					mxlength = #index
					end
				end
			end	
		end
		
		local formatter = "%- ".. (mxlength + 2) .."s" 
		
		local i = 0
		
		for index, cmd in pairs(CMDs) do
			yaAR[i] = string.format(formatter, index) 
			i = i + 1
		end
		
		et.G_LogPrint("Parsed ".. i .. " commands for lvl " .. lvl .."\n")
		commands["listing"][lvl] = yaAR	
	end
	
	
	yaAR = commands["listing"][lvl]
	number = #yaAR
	
	if arg[1] ~= "" then
		_page = tonumber(arg[1])
	else
		_page = 0
	end
	
	if (_page*20) > number then
		et.trap_SendConsoleCommand(et.EXEC_APPEND, "csay ".._Client.."\" ^FPlease specify a page between ^20 ^Fand ^2" .. string.format("%.0f", ( number / 20 -1) ) )
	end
		
		
	for i=(_page*20), (_page*20 + 20),4 do
		if  number - i < 4  then
			if number %4 == 1 then
				et.trap_SendConsoleCommand(et.EXEC_NOW , "csay ".._Client.."\"^F".. yaAR[i] .. "\"" )
				break
			elseif number %4 == 2 then
				et.trap_SendConsoleCommand(et.EXEC_NOW , "csay ".._Client.."\"^F".. yaAR[i] .. yaAR[i+1] .. "\"")
				break 
			elseif number %4 == 3 then
				et.trap_SendConsoleCommand(et.EXEC_NOW , "csay ".._Client.."\"^F"..yaAR[i] .. yaAR[i+1] .. yaAR[i+2].. "\"" )
				break
			end
		else
			et.trap_SendConsoleCommand(et.EXEC_NOW , "csay ".._Client.."\"^F".. yaAR[i] .. yaAR[i+1] .. yaAR[i+2] .. yaAR[i+3].. "\"") 
		end
	end		
		
	et.trap_SendConsoleCommand(et.EXEC_NOW, "csay ".._Client.."\"^F I parsed " .. number .." commands for you. Access all by adding a page between ^20 ^Fand ^2" .. string.format("%.0f", ( number / 20 -1) ) .. " ^Fto your listingcommand.\"")
	
	-- TODO: FIX LUA-OUPUT IN C. There is some serious shit going on. Let that intact, it prevents strange failures:
	--      Ok, not all failures: try to do !cmdlist at the last page......
	et.trap_SendConsoleCommand(et.EXEC_APPEND, "csay ".. _Client.. "\" \n \"")
	et.trap_SendConsoleCommand(et.EXEC_NOW, "")
end


-------------------------------------------------------------------------------
-- msgtoIRC(player , message)
-- Used in LuaCMDs to send a message from player to IRC
-- Player can be a number or the Playername
-------------------------------------------------------------------------------
function msgtoIRC(_client,_msg)
	 
	 _msg = string.gsub(_msg,'\\', "")
	 
	if type(_client) == "string" then
		-- no direct call, it is string && therefore a name from the !command
		sendtoIRCRelay(_client .. " on " .. serverid .. ": " .. _msg );
		et.trap_SendConsoleCommand(et.EXEC_APPEND, "chat \" ^3Sent your msg to IRC\n\"")
		return
	end
	 	
	if type(_client) == "number" and slot[_client]["user"] ~= "" then
		
		sendtoIRCRelay(slot[_client]["user"] .. " on " .. serverid .. ": " .. _msg );
		et.trap_SendConsoleCommand(et.EXEC_APPEND, "csay ".. _client .. "\" ^1Sent: ^3".._msg.." ^3to IRC\"")
		return
	else
		et.trap_SendConsoleCommand(et.EXEC_APPEND, "csay ".. _client .. "\" ^1You need to be registered to send messages to IRC  \"")
		return
	end
	

	
end

-------------------------------------------------------------------------------
-- forAll(whom, what)
-- will exec a function with parameter clientnum for all specified players
-- whom can be: axis/r, allies/b, specs/s, all
-- what is the function
-------------------------------------------------------------------------------
function forAll(_whom,_what)

	if _whom == "players" or _whom == "all" then  
		_whom = nil
	elseif _whom == 1 or _whom == "r" or _whom == "axis" then
		_whom = 1
	elseif _whom == 2 or _whom == "b" or _whom == "allies" then
		_whom = 2
	elseif _whom == 3 or _whom == "s" or _whom == "specs" then
		_whom = 3
	end

for i=0, maxclients, 1 do					
		if et.gentity_get(i,"classname") == "player" then
			local team = tonumber(et.gentity_get(i,"sess.sessionTeam"))
				if _whom == nil or team == _whom then
					_what(i)
				end
		end
end


end

-------------------------------------------------------------------------------
-- showTkTable -----
-- prints the current TopTen of teamkillers to the caller's console, 
-- sorted by teamkills and teamdamage
-- @author: hose
-------------------------------------------------------------------------------
function showTkTable(_myClient) 
	
	-- tkTable stores the damage stats of all players
	local tkTable = {}
	
	-- building up the teamkiller table
	for i=0, maxclients , 1 do
		if et.gentity_get(i, "inuse") == 1 then
			table.insert(tkTable, getDamageStats(i))
		end
	end --end for loop

	-- sort the table by teamkills and within that by teamdamage
	-- TODO: not sure how to handle a nil object there. i guess it s wrong
	-- 			to return false, but it works (does not work without)
	table.sort(tkTable, 
		function(_tk1, _tk2)
			if _tk1 == nil then 
				return false
			elseif _tk2 == nil then 
				return false
			elseif _tk1["teamkills"] == _tk2["teamkills"] then
				return _tk1["teamdamage"] > _tk2["teamdamage"]
			else 
				return _tk1["teamkills"] > _tk2["teamkills"] 
			end
		end) -- end the sorting function

	-- print the top ten table to the caller's console
	nPrint(_myClient, "Slot|        Name          | Class    | Tks | TD given ")
    loopcount = 0	
	for ind, _tkStats in ipairs(tkTable) do
		
		nPrint(_myClient, "^w" .. string.format("%-4s", _tkStats["srvslot"]) .."|" ..string.format("%-22s", et.Q_CleanStr(_tkStats["name"])) .. "|"  ..string.format("%-10s",  class[_tkStats["class"]]) .. "|" ..string.format("%-5s",  _tkStats["teamkills"]) .. "|" ..string.format("%-10s",  _tkStats["teamdamage"]))

		loopcount = loopcount + 1
		if loopcount >= 10 then 
			break 
		end
	end
end


-------------------------------------------------------------------------------
-- some convenience Functions for !commands or mod-use
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- heal(ClientNum)
-- heal a Player 
-------------------------------------------------------------------------------
function heal(_clientNum)
		et.gentity_set(_clientNum,"health", et.gentity_get(_clientNum,"ps.stats", 4) )
end

-------------------------------------------------------------------------------
-- healthboost(ClientNum)
-- boost a clients HP by 30, even over the maximum
-------------------------------------------------------------------------------
function healthboost(_clientNum)
	-- boost clienthealth +30 - no full heal, but perhaps more than allowed hp :)
	et.gentity_set(_clientNum,"health", et.gentity_get(_clientNum,"health" ) + 30 )
end

-------------------------------------------------------------------------------
-- giveammo(ClientNum)
-- Fill a clients mainweapons with ammo
-------------------------------------------------------------------------------
function giveammo(_clientNum)

	if et.gentity_get(_clientNum,"sess.sessionTeam") == 1 then
	-- axis
	et.gentity_set(_clientNum,"ps.ammo", 2, 64 )  -- luger 16
	et.gentity_set(_clientNum,"ps.ammo", 3, 150 )  -- mp40 60
	et.gentity_set(_clientNum,"ps.ammo", 9, 8 ) --nade 4
	et.gentity_set(_clientNum,"ps.ammo", 36, 64 ) --akimbo luger
	else
	-- allies
	et.gentity_set(_clientNum,"ps.ammo", 35, 64 ) --akimbo colt
	et.gentity_set(_clientNum,"ps.ammo", 4, 8 ) 	--nade 4
	et.gentity_set(_clientNum,"ps.ammo", 7, 64 )	-- colt 16
	et.gentity_set(_clientNum,"ps.ammo", 8, 150 )  -- thompson

	end
	
end


-------------------------------------------------------------------------------
-- force(ClientNum, command, whom/command)
-- Starwars themed gimmicks
-------------------------------------------------------------------------------
function force(_clientNum, _what , _arg2)

	if disableforce  then return end

	if _what == "heal" then
		if FPcheck(_clientNum, 15) then
			heal(_clientNum)
			et.trap_SendConsoleCommand(et.EXEC_APPEND,"chat\""..slot[_clientNum]['netname'].."^3 uses the force to heal himself.\n\"")
		end
	elseif _what == "push" then
		if _arg2 ~= "" and FPcheck(_clientNum, 15) then
			et.trap_SendConsoleCommand(et.EXEC_APPEND,"!fling " .. getPlayerId(_arg2) )
		end
	elseif _what == "ammo" then
		if FPcheck(_clientNum, 15) then
			giveammo(_clientNum)
			et.trap_SendConsoleCommand(et.EXEC_APPEND,"chat\""..slot[_clientNum]['netname'].."^3 uses the force to replenish his ammo.\n\"")
		end
	elseif _what == "boost" then
		if FPcheck(_clientNum, 15) then
			healthboost(_clientNum)
			et.trap_SendConsoleCommand(et.EXEC_APPEND,"chat\""..slot[_clientNum]['netname'].."^3 uses the force to boost his health.\n\"")
		end
	elseif _what == "team" then
		
		if   _arg2 == "heal" or _arg2 == "ammo" or _arg2 == "boost"  then
			if  FPcheck(_clientNum, 50) then
				if _arg2 == "boost" then
					forAll(  tonumber(et.gentity_get(_clientNum,"sess.sessionTeam")) ,  healthboost)
				elseif _arg2 == "ammo" then
					forAll(  tonumber(et.gentity_get(_clientNum,"sess.sessionTeam")) ,  giveammo)
				elseif _arg2 == "heal" then
					forAll(  tonumber(et.gentity_get(_clientNum,"sess.sessionTeam")) ,  heal)
				end	
			et.trap_SendConsoleCommand(et.EXEC_APPEND,"chat\""..slot[_clientNum]['netname'].."^3 uses the force to help his team with a ^2".._arg2..".\n\"")
		end	
		else
			et.trap_SendConsoleCommand(et.EXEC_APPEND,"chat\" ^3 You want to do .. what? heal, ammo, boost or push?  \n\"")
		end
	else
		et.trap_SendConsoleCommand(et.EXEC_APPEND,"chat\" ^3 You want to do .. what? ^4heal^3, ^4ammo^3, ^4boost ^3or ^4push^3?  \n\"")	
	end

end


-------------------------------------------------------------------------------
-- fpcheck(_clientNum, amountneeded )
-- check: Is the force with you?
-------------------------------------------------------------------------------
function FPcheck(_clientNum, _amount)

	if slot[_clientNum]["fpoints"] >= _amount then
		slot[_clientNum]["fpoints"] = slot[_clientNum]["fpoints"] - _amount
		return true
	else
		et.trap_SendConsoleCommand(et.EXEC_APPEND , "chat \" ^2To weak, the force in you is, young padawan .. Yes, hmmm. \n\"")
		return false
	end
end

-------------------------------------------------------------------------------
-- getDamageStats(_clientNum)
-- processes a player's data regarding tk, damage, teamdamage etc
-- helper function for showTkTable()
-- returns a table of several values for the _clientNum to the caller function
-------------------------------------------------------------------------------
function getDamageStats(_clientNum)

	tkStats = {}

	tkStats["name"] = et.gentity_get(_clientNum, "pers.netname")
	tkStats["srvslot"] = _clientNum
--	tkStats["team"] = et.gentity_get(_clientNum, "sess.sessionTeam")
	tkStats["class"] =  et.gentity_get(_clientNum, "sess.playerType")
--	tkStats["kills"] =  et.gentity_get(_clientNum, "sess.kills")
	tkStats["teamkills"] =  et.gentity_get(_clientNum, "sess.team_kills")
	tkStats["teamdamage"] =  et.gentity_get(_clientNum, "sess.team_damage")
--	tkStats["damage"] =  et.gentity_get(_clientNum, "sess.damage_given")

	return tkStats
	
end

-------------------------------------------------------------------------------
-- listAliases(_whom , _from )
-- list _froms aliases to _whom
-------------------------------------------------------------------------------
function listAliases(_whom, _from)
	if slot[_from]["pkey"] == nil then
		nPrint(_whom, "^3Slot not in use? - try the playername.")
		return
	end
	
	local aliases = DBCon:GetPlayerAliases(slot[_from]["pkey"])
	local output = {}
	if aliases ~= nil then
		local nr = 0
		for i, v in pairs(aliases) do -- holy fcking sh*t dont ever use ipairs here :/
		table.insert( output , "^3NOQ: Alias NR" ..string.format("%2i",nr)..": " .. string.format("%22s",et.Q_CleanStr(v)) .. "^7|" .. v )  
		nr = nr + 1
		end
		
		table.insert(output, 1,"^3Player ^7" .. slot[_from]["netname"] .. " ^3has ^7" .. nr .. " ^3different nicks." )
	else
		nPrint( _whom,  "^3Got no aliases recorded - is namelogging on?")
		return
	end
	nPrint(_whom, output)
end

-------------------------------------------------------------------------------
-- Here does End, kthxbye 
-------------------------------------------------------------------------------
