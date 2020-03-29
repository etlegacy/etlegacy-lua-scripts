--[[
    ET: Legacy
    Copyright (C) 2012-2020 ET:Legacy team <mail@etlegacy.com>
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

local modname = "banners"
local version = "0.2"

-- Map Data Structure
	
local MapPrototype = {}
MapPrototype.__index = MapPrototype 

function Map(tab)
	local obj = { _storage = assign({}, tab) }
	setmetatable(obj, MapPrototype)
	return obj
end

function MapPrototype:set(key, value)
	self._storage[key] = value
	return value
end 

function MapPrototype:get(key, def)
	return self._storage[key] or self._storage[def]
end

function MapPrototype:has(key)
	return self._storage[key] and true or false
end

function MapPrototype:toKeyString()
	local str = ""
	for k, v in pairs(self._storage) do
		str = str .. "'" .. k .. "', "
	end
	return string.sub(str, 1, -3)
end

-- Banner System --

local BannerSystemPrototype = {}
BannerSystemPrototype.__index = BannerSystemPrototype

function BannerSystem(props)
	local obj = {}
	obj.nextUpdateTime = 0
	obj.nextBanner = 0
	obj.interval = props.interval
	obj.command = props.command
	obj.banners = {}
	obj.isPaused = false
	for _, val in ipairs(props.banners) do
		if string.len(val) > 0 then
			table.insert(obj.banners, val)
		end
	end
	setmetatable(obj, BannerSystemPrototype)
	return obj
end

function BannerSystemPrototype:frame(time)
	if self.isPaused or self.nextUpdateTime > time then
		return
	end
	if #self.banners == 0 then
		return
	end
	-- don't run banners in intermission
	local g_gamestate = tonumber(et.trap_Cvar_Get("gamestate"))
	if g_gamestate == et.GS_INTERMISSION then
		self.isPaused = true
		return
	end
	-- perform work
	self:update(time)
	self:render(time)
end

function BannerSystemPrototype:update(time)
	self.nextUpdateTime = time + self.interval
	self.nextBanner = 1 + (self.nextBanner % #self.banners)
end

function BannerSystemPrototype:render(time)
	local banner = self.banners[self.nextBanner]
	et.trap_SendServerCommand(-1, string.format('%s \"%s\"^7', self.command, banner))
end

function BannerSystemPrototype:add(banner)
	if (string.len(banner) > 0) then
		table.insert(self.banners, banner)
	end
end

function BannerSystemPrototype:count()
	return #self.banners
end

-- Main Code --

local DEFAULT_TIME           = 5000
local DEFAULT_TIME_THRESHOLD = 2000 
local DEFAULT_LOCATION       = "top"
local bannerSystem = nil -- BannerSystem instance global (well, local)
local MAX_BANNERS            = 10

function et_InitGame(levelTime, randomSeed, restart)
	et.RegisterModname(modname .. " " .. version)

	local locationMapping = Map {
		top    = "bp",
		left   = "cpm",
		center = "cpm",
		chat   = "chat"
	}
	
	local g_bannerTime = tonumber(et.trap_Cvar_Get("g_bannerTime")) or DEFAULT_TIME
	local g_bannerLocation = string.lower(et.trap_Cvar_Get("g_bannerLocation")) or DEFAULT_LOCATION

	if (g_bannerTime < DEFAULT_TIME_THRESHOLD) then
		et.G_Print(
			string.format(
				"^3%s.lua: Warning! You cannot set banner time lower than %ims, forcing to %ims.\n", 
					modname, DEFAULT_TIME_THRESHOLD, DEFAULT_TIME))
		g_bannerTime = DEFAULT_TIME
	end

	if not locationMapping:has(g_bannerLocation) then
		et.G_Print(
			string.format(
				"^3%s.lua: Warning! Invalid location '%s', forcing to '%s'; valid locations: %s.\n", 
					modname, g_bannerLocation, DEFAULT_LOCATION, locationMapping:toKeyString()))
		g_bannerLocation = DEFAULT_LOCATION
	end

	-- find banners by checking the g_bannerN cvars
	local banners = {}
	for i = 1, MAX_BANNERS do
		local banner = et.trap_Cvar_Get("g_banner" .. i)
		if banner == nil or banner == "" then
			break
		end
		table.insert(banners, banner)
	end

	bannerSystem = BannerSystem {
		interval = g_bannerTime,
		command  = locationMapping:get(g_bannerLocation),
		banners  = banners
	}

	if bannerSystem:count() > 0 then
		et.G_Print(
			string.format(
				"^2%s.lua: Initialized banner system (%is, '%s'); showing %i banners.\n", 
					modname, g_bannerTime / 1000, g_bannerLocation, bannerSystem:count()))
	else
		et.G_Print(string.format("^3%s.lua: Warning! No banners were set.\n", modname))
		bannerSystem = nil
	end
end

function et_RunFrame(levelTime)
	if bannerSystem then
		bannerSystem:frame(levelTime)
	end
end

function et_ShutdownGame( restart )
	et.G_Print("Shutting down: " .. modname .. "\n")
end

-- Utils --

function assign(tab1, ...)
	local tables = { ... }
	for _, tab in pairs(tables) do
		for k, v in pairs(tab) do
			tab1[k] = v
		end
	end
	return tab1
end
