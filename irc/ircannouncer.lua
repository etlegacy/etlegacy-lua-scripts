--[[
	Author:      ET:Legacy Team
	Description: Ensure the server is connected to IRC - see irc_* cvars. Set irc_mode flag 1 and 2.
]]--

modname = "IRC announcer"
version = "1.1"

function et_InitGame()
  et.RegisterModname(modname.." "..version)
end

-- see http://etconfig.net/et-color-codes/et-color-codes/
-- see http://www.mirc.com/colors.html
function ircColorStr(str)
    local escape = "\003"
    local q3colorescape = "%^"
    str = str:gsub(q3colorescape .. "[7Ww%.Nn]",         escape .. "0")  -- white
    str = str:gsub(q3colorescape .. "[0Pp]",             escape .. "1")  -- black
    str = str:gsub(q3colorescape .. "[4Tt>]",            escape .. "2")  -- blue (no support for double ^ and ~)
    str = str:gsub(q3colorescape .. "[<\\|%(Hh]",        escape .. "3")  -- green
    str = str:gsub(q3colorescape .. "[1Qq%)Ii%*Jj]",     escape .. "4")  -- light red
    str = str:gsub(q3colorescape .. "[%+Kk%?_@`]",       escape .. "5")  -- brown
    str = str:gsub(q3colorescape .. "[#Cc%%Ee]",         escape .. "6")  -- purple
    str = str:gsub(q3colorescape .. "[8Xx!Aa,Ll]",       escape .. "7")  -- orange
    str = str:gsub(q3colorescape .. "[3Ss%/Oo]",         escape .. "8")  -- yellow
    str = str:gsub(q3colorescape .. "[2Rr'Gg=%]}%-Mm]",  escape .. "9")  -- light green
    str = str:gsub(q3colorescape .. "[\"Bb]",            escape .. "10") -- cyan
    str = str:gsub(q3colorescape .. "[5Uu]",             escape .. "11") -- light cyan
    str = str:gsub(q3colorescape .. "[%$Dd&Ff]",         escape .. "12") -- light blue
    str = str:gsub(q3colorescape .. "[6Vv]",             escape .. "13") -- pink
    str = str:gsub(q3colorescape .. "[9Yy]",             escape .. "14") -- grey
    str = str:gsub(q3colorescape .. "[:Zz;%[{]",         escape .. "15") -- light grey
    return str .. "\015"
end

function getTeamInfo()
  local temp = et.trap_GetConfigstring(0)
  temp = et.Info_ValueForKey(temp, "P")

  local team_free_cnt, team_ax_cnt, team_al_cnt, team_spec_cnt = 0, 0, 0, 0

  for i = 1, #temp do
    if (string.sub(temp, i, i) == "0") then
      team_free_cnt = team_free_cnt + 1
    end
    if (string.sub(temp, i, i) == "1") then
      team_ax_cnt = team_ax_cnt + 1
    end
    if (string.sub(temp, i, i) == "2") then
      team_al_cnt = team_al_cnt + 1
    end
    if (string.sub(temp, i, i) == "3") then
      team_spec_cnt = team_spec_cnt + 1
    end
  end

  return team_free_cnt, team_ax_cnt, team_al_cnt, team_spec_cnt
end

function getBotInfo()
  local cs = et.trap_GetConfigstring(0)
  local bots_cnt = et.Info_ValueForKey(cs, "omnibot_playing")

  return bots_cnt
end

function et_ClientConnect(_clientNum, _firstTime, _isBot)
  -- skip bots
  if _isBot == 1 then return end

  if _firstTime == 1 then
    local clientname
    -- note pers.netname is empty on first connect
    clientname = et.Info_ValueForKey(et.trap_GetUserinfo(_clientNum), "name")

    -- name length sanity check
    if string.len(clientname) > 36 then return end

    -- name ASCII sanity check
    local c
    for c in clientname:gmatch"." do
      if string.byte(clientname, c) < 32 then return end
    end

    clientname = ircColorStr(clientname)

    -- get player type and team count
    local free, axis, allies, spec = 0, 0, 0, 0
    free, axis, allies, spec = getTeamInfo()

    -- count humans players
    local bots, humans = 0, 0
    bots = getBotInfo()

    if bots then
      humans = free + axis + allies + spec - bots
    else
      humans = free + axis + allies + spec
    end

    -- float to int conversion
    humans = math.floor(humans)

    -- current player is connecting but doesn't show up in the total yet
    -- let's add it manually
    humans = humans + 1

    -- send message
    local msg        = "irc_say  \"" .. clientname .. " connected. Now online:^7 " .. humans .. "^9(+" .. bots .. ")\""
    et.trap_SendConsoleCommand(et.EXEC_NOW , ircColorStr(msg))
  end
end

-- function et_ClientDisconnect(_clientNum)
--  local clientname = ircColorStr(et.gentity_get(_clientNum ,"pers.netname"))
--  local msg        = "irc_say  \"" .. clientname .. " disconnected.\""
--  et.trap_SendConsoleCommand(et.EXEC_NOW , ircColorStr(msg))
-- end
