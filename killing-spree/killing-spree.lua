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

function et_InitGame()
    et.RegisterModname(modname .. " ".. version)
end

function et_Obituary(target, attacker, meansOfDeath)
    local targetTeam = et.gentity_get(target, "sess.sessionTeam")
    local attackerTeam = et.gentity_get(attacker, "sess.sessionTeam")
    
    local suicide = target == attacker
    local teamkill = targetTeam == attackerTeam
    local killerIsNotPlayer = killer == WORLDSPAWN_ENTITY or killer == ENTITYNUM_NONE

    if suicide or teamkill or killerIsNotPlayer then
        return 
    end
end


