
-- skill identifiers
BATTLESENSE 	= 0
ENGINEERING 	= 1
MEDIC 			= 2
FIELDOPS 		= 3
LIGHTWEAPONS	= 4
HEAVYWEAPONS	= 5
COVERTOPS		= 6

skills = {}
skills[BATTLESENSE]		= "Battlesense"
skills[ENGINEERING]		= "Engineering"
skills[MEDIC]			= "Medic"
skills[FIELDOPS]		= "Field ops"
skills[LIGHTWEAPONS]	= "Light weapons"
skills[HEAVYWEAPONS]	= "Heavy weapons"
skills[COVERTOPS]		= "Covert ops"

-- con:prepare with bind_names should be used to prevent sql injections
-- but it doesn't work on my version of luasql
-- cno is optional
-- TODO: log his ip
function validateGUID(guid, cno)
	-- allow only alphanumeric characters in guid
	if(string.match(guid, "%W")) then
		if not cno then
			cno = 0
			while cno < tonumber( et.trap_Cvar_Get( "sv_maxclients" ) ) do
				local checkguid = et.Info_ValueForKey( et.trap_GetUserinfo( cno ), "cl_guid" )
				if guid == checkguid then
					break
				end
				cno = cno + 1
			end
		end
		-- Invalid characters detected. We should probably drop this client
		et.G_Print("^3WARNING: user with id " .. cno .. " has an invalid GUID: " .. guid .. "\n")
		et.trap_SendServerCommand (cno, "cpm \"" .. "^1Your XP won't be saved because you have an invalid cl_guid.\n\"")
		return false
	end
	
	return true
end

-- saves XP values of a player with id 'cno' into sqlite database
function saveXP(cno)
	local name = et.Info_ValueForKey( et.trap_GetUserinfo( cno ), "name" )
	local guid = et.Info_ValueForKey( et.trap_GetUserinfo( cno ), "cl_guid" )
	
	if not validateGUID(cno, guid) then return end
	
	cur = assert (con:execute(string.format("SELECT * FROM %susers WHERE guid='%s' LIMIT 1", dbprefix, guid)))
	local player = cur:fetch({}, 'a')
	
	if not player then
		-- This should not happen	
		et.G_Print ("^1ERROR: user was not found in the database!\n")
		return
	else
		--for id, name in pairs(skills) do et.G_Print (name .. ": " .. et.gentity_get (cno, "sess.skillpoints", id) .. " XP\n") end
		
		cur = assert (con:execute(string.format([[UPDATE %susers SET 
			nick='%s',
			last_seen='%s', 
			xp_battlesense='%s',
			xp_engineering='%s', 
			xp_medic='%s', 
			xp_fieldops='%s', 
			xp_lightweapons='%s', 
			xp_heavyweapons='%s', 
			xp_covertops='%s' 
			WHERE guid='%s']], 
			dbprefix,
			name,
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

function getPlayerByGUID(guid)		
	if not validateGUID(guid) then return nil end

	cur = assert (con:execute(string.format("SELECT * FROM %susers WHERE guid='%s'", dbprefix, guid)))
	return cur:fetch({}, 'a') -- player table or nil
end

function getPlayerName(id)
	local name

	if not id or not (id >= 0 or id < tonumber(et.trap_Cvar_Get("sv_maxclients"))) and not (id == 999) then 
		return nil 
	end
 
 	if id == 999 then
 		name = "^JServer" 
	else
		name = et.gentity_get( id, "pers.netname" )
	end

	return name
end