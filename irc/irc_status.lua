--[[
	Author:      IR4
	Description: Ensure the server is connected to IRC - see irc_* cvars. Set irc_mode flag 1 and 2.
]]--

modname ="IRC status"
version ="0.01"

function et_InitGame()
  et.RegisterModname(modname.." "..version)
end

function et_ClientConnect(_clientNum, _firstTime, _isBot)
  if _firstTime then
    -- FIXME: clean the name
    -- note pers.netname is empty on first connect
    local clientname = et.Info_ValueForKey(et.trap_GetUserinfo(_clientNum), "name")
    local msg        = "irc_say  \"" .. clientname .. " connected to server\""
    et.trap_SendConsoleCommand(et.EXEC_NOW , msg)
  end
end

function et_ClientDisconnect(_clientNum)
  -- FIXME: clean the name
  local clientname = et.gentity_get(_clientNum ,"pers.netname")
  local msg        = "irc_say  \"" .. clientname .. " disconnected from server\""
  et.trap_SendConsoleCommand(et.EXEC_NOW , msg)
end
