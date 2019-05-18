--[[
    ET: Legacy
    Copyright (C) 2012-2019 ET:Legacy team <mail@etlegacy.com>

    This file is part of ET: Legacy - http://www.etlegacy.com

    ET: Legacy is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    ET: Legacy is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with ET: Legacy. If not, see <http://www.gnu.org/licenses/>.
]]--

local modname = "spawn-invul-fair"
local version = "0.1"

function et_WeaponFire(clientNum, weapNum)
	et.gentity_set(clientNum, "ps.powerups", et.PW_INVULNERABLE, 0 )
end

function et_FixedMGFire(clientNum, weapNum)
	et.gentity_set(clientNum, "ps.powerups", et.PW_INVULNERABLE, 0 )
end

function et_MountedMGFire(clientNum, weapNum)
	et.gentity_set(clientNum, "ps.powerups", et.PW_INVULNERABLE, 0 )
end

function et_AAGunFire(clientNum, weapNum)
	et.gentity_set(clientNum, "ps.powerups", et.PW_INVULNERABLE, 0 )
end

function et_InitGame()
    et.RegisterModname(modname .. " " .. version)
end
