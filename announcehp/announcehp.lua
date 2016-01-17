//Source: http://lua.wolffiles.de/?fileid=32
function et_Obituary(victimnum, killernum, meansofdeath) 
	local victimteam = tonumber(et.gentity_get(victimnum, "sess.sessionTeam")) 
	local killerteam = tonumber(et.gentity_get(killernum, "sess.sessionTeam")) 
    if victimteam ~= killerteam and killernum ~= 1022 then 
		local killername = string.gsub(et.gentity_get(killernum, "pers.netname"), "%^$", "^^ ") 
		local killerhp = et.gentity_get(killernum, "health")
		--this sends a message to the client only
		msg = string.format("cpm  \"" .. killername ..  "^7 had^o " .. killerhp .. " ^7HP left\n")
		et.trap_SendServerCommand(victimnum, msg)
    end 
end
