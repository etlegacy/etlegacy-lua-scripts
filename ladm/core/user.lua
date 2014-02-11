
-- skill identifiers
local BATTLESENSE 	= 0
local ENGINEERING 	= 1
local MEDIC 		= 2
local FIELDOPS 		= 3
local LIGHTWEAPONS	= 4
local HEAVYWEAPONS	= 5
local COVERTOPS		= 6

local skills = {}
skills[BATTLESENSE]		= "Battlesense"
skills[ENGINEERING]		= "Engineering"
skills[MEDIC]			= "Medic"
skills[FIELDOPS]		= "Field ops"
skills[LIGHTWEAPONS]	= "Light weapons"
skills[HEAVYWEAPONS]	= "Heavy weapons"
skills[COVERTOPS]		= "Covert ops"

-- con:prepare with bind_names should be used to prevent sql injections
-- but it doesn't work on my version of luasql
function validateGUID(cno, guid)
	-- allow only alphanumeric characters in guid
	if(string.match(guid, "%W")) then
		-- Invalid characters detected. We should probably drop this client
		et.G_Print("^3WARNING: (XP Save) user with id " .. cno .. " has an invalid GUID: " .. guid .. "\n")
		et.trap_SendServerCommand (cno, "cpm \"" .. "Your XP won't be saved because you have an invalid cl_guid.\n\"")
		return false
	end
	
	return true
end

-- saves XP values of a player with id 'cno' into sqlite database
function saveXP(cno)
	local name = et.Info_ValueForKey( et.trap_GetUserinfo( cno ), "name" )
	local guid = et.Info_ValueForKey( et.trap_GetUserinfo( cno ), "cl_guid" )
	
	if not validateGUID(cno, guid) then return end
	
	cur = assert (con:execute(string.format("SELECT * FROM users WHERE guid='%s' LIMIT 1", guid)))
	local player = cur:fetch({}, 'a')
	
	if not player then
		-- This should not happen	
		et.G_Print ("^1ERROR: (XP Save) user was not found in the database!\n")
		return
	else
		et.trap_SendServerCommand (cno, "cpm \"" .. "See you again soon, " .. name .. "\n\"")
		--for id, name in pairs(skills) do et.G_Print (name .. ": " .. et.gentity_get (cno, "sess.skillpoints", id) .. " XP\n") end
		
		cur = assert (con:execute(string.format([[UPDATE users SET 
			last_seen='%s', 
			xp_battlesense='%s',
			xp_engineering='%s', 
			xp_medic='%s', 
			xp_fieldops='%s', 
			xp_lightweapons='%s', 
			xp_heavyweapons='%s', 
			xp_covertops='%s' 
			WHERE guid='%s']], 
			os.date("%Y-%m-%d %H:%M:%S"), 
			et.gentity_get (cno, "sess.skillpoints", BATTLESENSE), 
			et.gentity_get (cno, "sess.skillpoints", ENGINEERING), 
			et.gentity_get (cno, "sess.skillpoints", MEDIC), 
			et.gentity_get (cno, "sess.skillpoints", FIELDOPS), 
			et.gentity_get (cno, "sess.skillpoints", LIGHTWEAPONS), 
			et.gentity_get (cno, "sess.skillpoints", HEAVYWEAPONS), 
			et.gentity_get (cno, "sess.skillpoints", COVERTOPS), 
			guid
		)))
	end
end
