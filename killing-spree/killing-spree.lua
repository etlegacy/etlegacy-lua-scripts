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

local BROADCAST = -1

local SPREE = 5
local RAMPAGE = 10
local DOMINATION = 15
local UNSTOPPABLE = 20
local GODLIKE = 25
local WICKED_SICK = 30
local REAL_POTTER = 35

-- local SPREE = 1
-- local RAMPAGE = 2
-- local DOMINATION = 3
-- local UNSTOPPABLE = 5
-- local GODLIKE = 5
-- local WICKED_SICK = 6
-- local REAL_POTTER = 7

local SPREE_ANNOUNCEMENTS = {
    [SPREE] = {
        sound = "/sound/misc/killing-spree.wav",
        message = "is on a killing spree!"
    },
    [RAMPAGE] = {
        sound = "/sound/misc/rampage.wav",
        message = "is on a rampage!!"
    },
    [DOMINATION] = {
        sound = "/sound/misc/domination.wav",
        message = "is dominating!!"
    },
    [UNSTOPPABLE] = {
        sound = "/sound/misc/unstoppable.wav",
        message = "is unstoppable!!!!"
    },
    [GODLIKE] = {
        sound = "/sound/misc/godlike.wav",
        message = "is godlike!!!!!"
    },
    [WICKED_SICK] = {
        sound = "/sound/misc/wicked-sick.wav",
        message = "is wicked sick!!!!!!"
    },
    [REAL_POTTER] = {
        sound = "/sound/misc/real-potter.wav",
        message = "is real POTTER!!!!!!!"
    },
}

function et_InitGame()
    et.RegisterModname(modname .. " ".. version)
end

function getTeam(clientNumber)
    return et.gentity_get(clientNumber, "sess.sessionTeam")
end

function getGuid(clientNumber)
    return et.Info_ValueForKey( et.trap_GetUserinfo(clientNumber), "cl_guid")
end

function getName(clientNumber)
    return et.gentity_get(clientNumber, "pers.netname")
end

function et_ClientBegin(clientNumber)
    local guid = getGuid(clientNumber)

    local spree = killingSprees[guid]

    if not spree then
        killingSprees[guid] = 0
    end
end

function announceSpree(clientNumber, guid)
    local spree = killingSprees[guid]
    local announcement = SPREE_ANNOUNCEMENTS[spree]
    
    if announcement then
        local name = getName(clientNumber)

        et.G_globalSound(announcement.sound);
        et.trap_SendServerCommand(BROADCAST, "cpm \"" .. name .. " " .. announcement.message .. "\n\"")
    end
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
        return 
    end

    local attackerGuid = getGuid(attacker)
    killingSprees[attackerGuid] = killingSprees[attackerGuid] + 1

    announceSpree(attacker, attackerGuid)
end
