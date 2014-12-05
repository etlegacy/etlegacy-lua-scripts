--------------------------------------------------------------------------
-- dynamite.lua - a server side dynamite timer script                    -
--------------------------------------------------------------------------
-- 1.42:
--   - made the script Lua 5.2.3 compatible
-- 1.41:
--   - pheno: made the script ETpub (and other mod?) compatible
--   - pheno: made the script Lua 5.2 compatible
--
-- 1.4:
--   - first release
--------------------------------------------------------------------------
local version = "1.42"

-- Config:
-- where to place the timer message, see
--   http://wolfwiki.anime.net/index.php/SendServerCommand#Printing 
-- for valid locations
-- local announce_pos   = "b 128"
-- local announce_pos   = "b 8"
local announce_pos   = "cpm"


-- print "Dynamite planted at LOCATION"? This only affects this message,
-- not the countdown messages
local announce_plant = true

-- enable timer for all on default or just the clients who did a 
-- 'setu v_dynatimer 1'?
local cl_default = true

-- for 20, 10, 5, 3, 2, 1, NOW use:
local steps = { -- [step] = { next step, diff to next step }
                   [20]   =  { 10,        10 }, 
                   [10]   =  {  5,         5 }, 
                    [5]   =  {  3,         2 }, 
                    [3]   =  {  2,         1 }, 
                    [2]   =  {  1,         1 }, 
                    [1]   =  {  0,         1 },
                    [0]   =  {  0,         0 } -- delete if diff to next == 0
              }
----------------------------------------------------------------------------
-- [!!!] Hirnlos settings:
-- local steps = { -- [step] = { next step, diff to next step }
--                   [20]   =  { 10,        10 }, 
--                   [10]   =  {  5,         5 }, 
--                    [5]   =  {  2,         3 },
--                    [2]   =  {  0,         0 } -- no BOOM
--              }
----------------------------------------------------------------------------
-- -- for 25, 15, 5, 3, 2, 1 use:
-- local steps = {
--                 [25]={15,10},
--                 [15]={5,10},
--                  [5]={3,2},
--                  [3]={2,1}, 
--                  [2]={1,1}, 
--                  [1]={0,0} -- no "Dynamite at %s exploding now" message
--               }
-- -- I think you got the idea now ...oh setting first_step = 30 will print
-- -- everything one (server) frame too late ... FIXED: all messages moved
-- -- one frame earlier ;-)
-- END Config


local timers     = {}
local client_msg = {}
local levelTime
local sv_maxclients
local sv_fps
local first_step 

local ST_NEXT = 1
local ST_DIFF = 2

local T_TIME     = 1
local T_STEP     = 2
local T_LOCATION = 3

-- called when game inits
function et_InitGame(levelTime, randomSeed, restart)
    et.RegisterModname("dynamite.lua " .. version .. " " .. et.FindSelf())
    sv_maxclients = tonumber(et.trap_Cvar_Get("sv_maxclients")) + 1
    sv_fps        = tonumber(et.trap_Cvar_Get("sv_fps"))
    local i = 0
    for i=1, sv_maxclients do
        -- set to false, clients will change it, as soon as they enter the world
        table.insert(client_msg, i, false) 
    end
    first_step = 0
    for i, data in pairs(steps) do
        if i > first_step then
            first_step = i
        end
    end
    et.G_Print("Vetinari's dynamite.lua version "..version.." activated...\n")
end

-- the dynamite planted/defused messages... grab them and start / stop the
-- timer
function et_Print(text)
    -- etpro popup: allies planted "the Old City Wall"
    -- etpro popup: axis defused "the Old City Wall"
    local pattern = "^" .. et.trap_Cvar_Get("gamename") .. "%s+popup:%s+(%w+)%s+(%w+)%s+\"(.+)\""
    local junk1,junk2,team,action,location = string.find(text, pattern)
    if team ~= nil and action ~= nil and location ~= nil then
        if action == "planted" then
            if announce_plant then
                sayClients(announce_pos, 
                    string.format("Dynamite planted at ^8%s^7", location))
            end
            addTimer(location)
        end
        if action == "defused" then
            sayClients(announce_pos, 
                string.format("Dynamite defused at ^8%s^7", location))
            removeTimer(location)
        end
    end

    if text == "Exit: Timelimit hit.\n" or text == "Exit: Wolf EndRound.\n" then
        -- stop countdowns on intermission
        timers = {}
    end
end

-- check if we have to print the countdown messages
function et_RunFrame(lvltime)
    levelTime = lvltime
    for i, timer in pairs(timers) do
        if timer[T_TIME] <= levelTime then 
            printTimer(timer[T_STEP], timer[T_LOCATION])
            local step = steps[timer[T_STEP]]
            if step[ST_DIFF] == 0 then
                removeTimer(timer[T_LOCATION])
            else
                timer[T_STEP] = step[ST_NEXT]
                timer[T_TIME] = levelTime + (step[ST_DIFF] * 1000)
            end
        end
	end
end

-- \dynatimer client command, switch on/off, get status about the setting
-- The client setting (and server's default, if unset on client) are now
-- stored in a userinfo var. This keeps the setting across map changes.
function et_ClientCommand(id, command)
    if string.lower(et.trap_Argv(0)) == "dynatimer" then
        local arg = et.trap_Argv(1)
        if arg == "" then
            local status = "^8on^7"
            if client_msg[id + 1] == false then
                status = "^8off^7"
            end
            et.trap_SendServerCommand(id, string.format("%s \"^#(dynatimer):^7 Dynatimer is %s\"", announce_pos, status))
        elseif tonumber(arg) == 0 then
            setTimerMessages(id, false)
            et.trap_SendServerCommand(id,
                    string.format("%s \"^#(dynatimer):^7 Dynatimer is now ^8off^7\"", announce_pos))
        else
            setTimerMessages(id, true)
            et.trap_SendServerCommand(id, 
                    string.format("%s \"^#(dynatimer):^7 Dynatimer is now ^8on^7\"", announce_pos))
        end
        return(1)
    end
    return(0)
end

-- print messages... just to the clients, who want them
function sayClients(pos, msg) 
    local message = string.format("%s \"%s^7\"", pos, msg)
    for id, timer_wanted in pairs(client_msg) do
        if timer_wanted then
            et.trap_SendServerCommand(id - 1, message)
        end
    end
end

function printTimer(seconds, loc) 
    local when = string.format("in ^8%d^7 seconds", seconds)
    if seconds == 0 then
        when = "^8now^7"
    elseif seconds == 1 then
        when = "in ^81^7 second"
    end
    sayClients(announce_pos, 
            string.format("Dynamite at ^8%s^7 exploding %s", loc, when))
end

function addTimer(location) 
    -- local diff = (30 - first_step) * 1000
    -- move one server frame earlier
    local diff = ((30 - first_step) * 1000) - math.floor(1000 / sv_fps)
    table.insert(timers, { levelTime + diff, first_step, location })
end

function removeTimer(location)
    for i, timer in pairs(timers) do 
        -- problem with 2 or more planted dynas at one location
        -- ... remove the one which was planted first
        if timer[T_LOCATION] == location then
            table.remove(timers, i)
        end
    end
end

function setTimerMessages(id, value) 
    client_msg[id + 1] = value
    if value then
        value = "1"
    else
        value = "0"
    end
    et.trap_SetUserinfo(id, 
        et.Info_SetValueForKey(et.trap_GetUserinfo(id), "v_dynatimer", value)
    )
end

function updateUInfoStatus(id) 
    local timer = et.Info_ValueForKey(et.trap_GetUserinfo(id), "v_dynatimer")
    if timer == "" then
        setTimerMessages(id, cl_default)
    elseif tonumber(timer) == 0 then
        client_msg[id + 1] = false
    else
        client_msg[id + 1] = true 
    end
end

function et_ClientBegin(id)
    updateUInfoStatus(id) 
end

function et_UserinfoChanged(id) 
    updateUInfoStatus(id) 
end

function et_ClientDisconnect(id) 
    client_msg[id + 1] = false
end

-- vim: ts=4 sw=4 expandtab syn=lua
