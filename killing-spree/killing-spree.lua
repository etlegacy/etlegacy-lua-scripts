--[[
    Author: Kewin Polok [Sheldar]
    Contributors:
    License: MIT

    Description: Script for killing spree sounds
]]--

local modname = "killing-spree"
local version = "0.1"

local WORLDSPAWN_ENTITY = 1022
local ENTITYNUM_NONE = 1023

local killingSprees = {}

function et_InitGame()
    et.RegisterModname(modname .. " ".. version)
end

function getTeam(clientNumber)
    return et.gentity_get(clientNumber, "sess.sessionTeam")
end

function getGuid(clientNumber)
    return et.Info_ValueForKey( et.trap_GetUserinfo(clientNumber), "cl_guid")
end

function et_ClientBegin(clientNumber)
    local guid = getGuid(clientNumber)

    killingSprees[guid] = 0
end

function et_Obituary(target, attacker, meansOfDeath)
    local targetTeam = getTeam(target)
    local attackerTeam = getTeam(attacker)
    
    local suicide = target == attacker
    local teamkill = targetTeam == attackerTeam
    local killerIsNotPlayer = killer == WORLDSPAWN_ENTITY or killer == ENTITYNUM_NONE
    
    local targetGuid = getGuid(target)
    killingSprees[targetGuid] = 0

    if suicide or teamkill or killerIsNotPlayer then
        et.G_Print("suicide or teamkill or killerIsNotPlayer\n")
        return 
    end

    local attackerGuid = getGuid(attacker)
    killingSprees[attackerGuid] = killingSprees[attackerGuid] + 1

    et.G_Print("target " .. targetGuid .. " killed by " .. attackerGuid .. "\n")
    et.G_Print("target spree " .. killingSprees[targetGuid] .. "\nattacker spree " .. killingSprees[attackerGuid] .. "\n")
end
