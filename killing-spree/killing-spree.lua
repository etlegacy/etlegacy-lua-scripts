--[[
    Author: Kewin Polok [Sheldar]
    Contributors:
    License: MIT

    Description: Killing spree sounds and messages
]]--

local modname = "killing-spree"
local version = "0.1"

local WORLDSPAWN_ENTITY = 1022
local ENTITYNUM_NONE = 1023

local BROADCAST = -1

local SPREE = 5
local RAMPAGE = 10
local DOMINATING = 15
local UNSTOPPABLE = 20
local GODLIKE = 25
local WICKED_SICK = 30
local REAL_POTTER = 35

local SPREE_ANNOUNCEMENTS = {
    [SPREE] = {
        sound = "/sound/misc/killingspree.wav",
        message = "%s^7 is on a killing spree!"
    },
    [RAMPAGE] = {
        sound = "/sound/misc/rampage.wav",
        message = "%s^7 is on a rampage!!"
    },
    [DOMINATING] = {
        sound = "/sound/misc/dominating.wav",
        message = "%s^7 is dominating!!"
    },
    [UNSTOPPABLE] = {
        sound = "/sound/misc/unstoppable.wav",
        message = "%s^7 is unstoppable!!!!"
    },
    [GODLIKE] = {
        sound = "/sound/misc/godlike.wav",
        message = "%s^7 is godlike!!!!!"
    },
    [WICKED_SICK] = {
        sound = "/sound/misc/wickedsick.wav",
        message = "%s^7 is wicked sick!!!!!!"
    },
    [REAL_POTTER] = {
        sound = "/sound/misc/realpotter.wav",
        message = "%s^7 is real POTTER!!!!!!!"
    }
}

local killingSprees = {}

function et_InitGame()
    et.RegisterModname(modname .. " " .. version)
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
        local message = string.format(announcement.message, name)

        et.G_globalSound(announcement.sound)
        et.trap_SendServerCommand(BROADCAST, "cpm \"" .. message .. "\n\"")
    end
end

function announceEndOfSpree(target, attacker)
    local targetGuid = getGuid(target)
    local spree = killingSprees[targetGuid]
    
    if spree >= SPREE then
        local message = string.format(
            "%s^7 killing spree ended (^3%d^7), killed by %s^7!",
            getName(target),
            spree,
            getName(attacker)
        )

        et.trap_SendServerCommand(BROADCAST, "cpm \"" .. message .. "\n\"")
    end
end

function et_Obituary(target, attacker, meansOfDeath)
    local targetTeam = getTeam(target)
    local attackerTeam = getTeam(attacker)
    
    local suicide = target == attacker
    local teamkill = targetTeam == attackerTeam
    local killerIsNotPlayer = killer == WORLDSPAWN_ENTITY or killer == ENTITYNUM_NONE
    
    announceEndOfSpree(target, attacker)

    local targetGuid = getGuid(target)
    killingSprees[targetGuid] = 0

    if suicide or teamkill or killerIsNotPlayer then
        return 
    end

    local attackerGuid = getGuid(attacker)
    killingSprees[attackerGuid] = killingSprees[attackerGuid] + 1

    announceSpree(attacker, attackerGuid)
end
