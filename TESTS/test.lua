--[[
	Test script for LUA functions

// Callbacks
void G_LuaHook_InitGame(int levelTime, int randomSeed, int restart);
void G_LuaHook_ShutdownGame(int restart);
void G_LuaHook_RunFrame(int levelTime);
qboolean G_LuaHook_ClientConnect(int clientNum, qboolean firstTime, qboolean isBot, char *reason);
void G_LuaHook_ClientDisconnect(int clientNum);
void G_LuaHook_ClientBegin(int clientNum);
void G_LuaHook_ClientUserinfoChanged(int clientNum);
void G_LuaHook_ClientSpawn(int clientNum, qboolean revived, qboolean teamChange, qboolean restoreHealth);
qboolean G_LuaHook_ClientCommand(int clientNum, char *command);
qboolean G_LuaHook_ConsoleCommand(char *command);
qboolean G_LuaHook_UpgradeSkill(int cno, skillType_t skill);
qboolean G_LuaHook_SetPlayerSkill( int cno, skillType_t skill );
void G_LuaHook_Print( char *text );
qboolean G_LuaHook_Obituary( int victim, int killer, int meansOfDeath );

TODO:
Check the vars

--]]

---------------------------------------------------------------------------------------------
-- options of this lua
---------------------------------------------------------------------------------------------

color = "^5" 

-- Debug 0/1
debug = 1
debugRunFrame = 1 -- (popcorn!)
debugPrint = 0 
---------------------------------------------------------------------------------------------

-- test some of the supported lua functions
function test_lua_functions()
    et.G_Print(color .. "*************** FUNCTIONS *****************\n")
    
    et.G_Print(color .. "-- CVAR SET & GET\n")
    et.trap_Cvar_Set( "bla1", "bla2" )
    et.G_Print(color .. "bla1 " .. et.trap_Cvar_Get("bla1") .. "\n")
    et.G_Print(color .. "sv_hostname " .. et.trap_Cvar_Get("sv_hostname") .. "\n")
    
    et.G_Print(color .. "-- CS\n")
    et.G_Print(color .. "configstring 1: " .. et.trap_GetConfigstring(1).. "\n")
    
    et.trap_SetConfigstring(4, "yadda test" )
    et.G_Print(color .. "configstring 4: " .. et.trap_GetConfigstring(4) .. "\n")
    
    et.G_Print(color .. "-- COMMANDS\n")
    et.trap_SendConsoleCommand(et.EXEC_APPEND, "cvarlist *charge*\n" )
    et.trap_SendServerCommand(-1, "print \"Yadda yadda\"")
    
    et.G_Print(color .. "-- ENT\n")
    et.G_Print(color .. "gentity[1022].classname = " .. et.gentity_get(1022, "classname") .. "\n")
       
    --this code lets the server crash/gives segfault?
    --local ent = "test";
    --local ent = et.G_EntitiesFree();
    --et.trap_SendConsoleCommand(et.EXEC_APPEND, "chat " .. ent .. " <- Command outputt\n")
end

function printConstants()
    et.G_Print(color .. "**************** CONSTANTS *****************\n")

    et.G_Print(color .. "et.HOSTARCH       " .. et.HOSTARCH .. "\n")
    
    et.G_Print(color .. "et.EXEC_NOW       " .. et.EXEC_NOW .. "\n")
    et.G_Print(color .. "et.EXEC_INSERT    " .. et.EXEC_INSERT .. "\n")
    et.G_Print(color .. "et.EXEC_APPEND    " .. et.EXEC_APPEND .. "\n")
    
    et.G_Print(color .. "et.FS_READ        " .. et.FS_READ .. "\n")
    et.G_Print(color .. "et.FS_WRITE       " .. et.FS_WRITE .. "\n")
    et.G_Print(color .. "et.FS_APPEND      " .. et.FS_APPEND .. "\n")
    et.G_Print(color .. "et.FS_APPEND_SYNC " .. et.FS_APPEND_SYNC .. "\n")
    
    et.G_Print(color .. "et.SAY_ALL        " .. et.SAY_ALL .. "\n")
    et.G_Print(color .. "et.SAY_TEAM       " .. et.SAY_TEAM .. "\n")
    et.G_Print(color .. "et.SAY_BUDDY      " .. et.SAY_BUDDY .. "\n")
    et.G_Print(color .. "et.SAY_TEAMNL     " .. et.SAY_TEAMNL .. "\n")

    -- FIXME: add all CS related constants
    et.G_Print(color .. "et.CS_MODELS      " .. et.CS_MODELS .. "\n")
    et.G_Print(color .. "et.CS_PLAYERS     " .. et.CS_PLAYERS .. "\n")
    et.G_Print(color .. "et.CS_MAX         " .. et.CS_MAX .. "\n")
end

function et_InitGame(_levelTime, _randomSeed, _restart)
  if debug == 1 then
    et.trap_SendServerCommand( -1 ,"cpm \"" .. color .. "InitGame - levelTime: " .. _levelTime .. " randomSeed: " .. _randomSeed .. " restart: " .. _restart)
    et.G_Print(color .. "InitGame - levelTime:      " .. _levelTime .. " randomSeed: " .. _randomSeed .. " restart: " .. _restart .."\n" )
  end
  et.RegisterModname( "test.lua " .. et.FindSelf() )

  printConstants()

  test_lua_functions()
end

function et_ShutdownGame(_restart)
  if debug == 1 then
    et.trap_SendServerCommand(-1 ,"cpm \"" .. color .. "ShutdownGame - restart: " .. _restart)
    et.G_Print(color .. "ShutdownGame - restart: " .. _restart .."\n" )
   end
end

function et_RunFrame(_levelTime)
  if debugRunFrame == 1 then
    if _levelTime %10000 == 0 then
      et.trap_SendServerCommand( -1 ,"cpm \"" .. color .. "RunFrame - levelTime: " .. _levelTime) 
      et.G_Print(color .. "RunFrame - levelTime: " .. _levelTime .. "\n")      
    end
  end
end

function et_ClientCommand(_clientNum, _command)
  if debug == 1 then
    et.trap_SendServerCommand( -1 ,"cpm \"" .. color .. "ClientCommand - clientNum: " .. _clientNum .. " command: " .. _command)
    et.G_Print(color .. "ClientCommand - clientNum: " .. _clientNum .. " command: " .. _command .. "\n")  
  end
end

function et_ClientUserinfoChanged(_clientNum)
  if debug == 1 then
    et.trap_SendServerCommand( -1 ,"cpm \"" .. color .. "ClientUserinfoChanged - clientNum: " .. _clientNum)
    et.G_Print(color .. "ClientUserinfoChanged - clientNum: " .. _clientNum .. "\n")
  end
end

function et_ClientConnect(_clientNum, _firstTime, _isBot, _reason)
  if debug == 1 then
    et.trap_SendServerCommand( -1 ,"cpm \"" .. color .. "ClientConnect " .. _clientNum .. " - firstTime: " .. _firstTime .. " bot: " .. _isBot)
    et.G_Print(color .. "ClientConnect " .. _clientNum .. " - firstTime: " .. _firstTime .. " bot: " .. _isBot .. "\n")
  end
end

function et_ClientBegin(_clientNum)
  if debug == 1 then
    et.trap_SendServerCommand( -1 ,"cpm \"" .. color .. "ClientBegin - clientNum: " .. _clientNum )
    et.G_Print(color .. "ClientBegin - clientNum: " .. _clientNum .. "\n")
  end
end

function et_ClientSpawn(_clientNum, _revived, _teamChange, _restoreHealth)
  if debug == 1 then
    et.trap_SendServerCommand( -1 , "cpm \"" .. color .. "ClientSpawn client: " .. _clientNum .. " revived: " .. _revived .. " teamChange: " .. _teamChange .. " restoreHealth: " .. _restoreHealth)
    et.G_Print(color .. "ClientSpawn client: " .. _clientNum .. " revived: " .. _revived .. " teamChange: " .. _teamChange .. " restoreHealth: " .. _restoreHealth .. "\n")
  end
end

function et_ClientDisconnect(_clientNum)
  if debug == 1 then
    et.trap_SendServerCommand( -1 ,"cpm \"" .. color .. "ClientDisconnect - clientNum: " .. _clientNum)
    et.G_Print(color .. "ClientDisconnect - clientNum: " .. _clientNum .. "\n")
  end
end

function et_ConsoleCommand(_command)
  if debug == 1 then
    et.trap_SendServerCommand( -1 ,"cpm \"" .. color .. "ConsoleCommand - command: " .. _command)
    et.G_Print(color .. "et_ConsoleCommand: " .. _command  .. " argc: " .. et.trap_Argc() .. " argv[0]: " .. et.trap_Argv(0) .. "\n")
  end
  
  if et.trap_Argv(0) == "listmods" then
    i = 1
    repeat
      modname, signature = et.FindMod(i)
      if modname and signature then
	et.G_Print(color .. "vm slot [%d] name [%s] signature [%s]\n", i, modname, signature)
	et.IPCSend(i, "hello")
      end
      i = i + 1
    until modname == nil or signature == nil
    return 1
  end
  
  return 0
end

-- Different to ETPub!
function et_Obituary(_victim, _killer, _meansOfDeath)
  if debug == 1 then
    et.trap_SendServerCommand( -1 ,"cpm \"" .. color .. "Obituary - victim: " .. _victim .. " killer: " .. _killer .. " meansOfDeath: " .. _meansOfDeath)
    et.G_Print(color .. "Obituary - victim: " .. _victim .. " killer: " .. _killer .. " meansOfDeath: " .. _meansOfDeath .. "\n")
  end
end

function et_UpgradeSkill(_clientNum, _skill)
  if debug == 1 then
    et.trap_SendServerCommand( -1 ,"cpm \"" .. color .. "UpgradeSkill - clientNum: " .. _clientNum .. "skill: " .. _skill)
    et.G_Print(color .. "UpgradeSkill - clientNum: " .. _clientNum .. "skill: " .. _skill .. "\n")
  end
end

function et_Print(_text)
  if debugPrint == 1 then
    et.trap_SendServerCommand( -1 ,"cpm \"" .. color .. "Print - text: " .. _text)
      et.G_Print(color .. "Print - text: " .. _text .. "\n")
  end
end

-- ok, but why called so often in game (for bots only?)
function et_SetPlayerSkill(_clientNum, _skill)
  if debug == 1 then
    et.trap_SendServerCommand( -1 ,"cpm \"" .. color .. "SetPlayerSkill - clientNum: " .. _clientNum .. " skill: " .. _skill)
    et.G_Print(color .. "SetPlayerSkill - clientNum: " .. _clientNum .. " skill: " .. _skill .. "\n")
  end
end
