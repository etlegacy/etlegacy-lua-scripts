require "core/user"
require "core/db"

Command = {}

-- Heads or tails
Command["cointoss"] = function(cno, cmd)
	local player = getPlayerName( cno )
	local number = math.random( 0, 99 )

	math.randomseed( os.time() )

	et.G_Print( "cointoss: " .. player .. " " .. number .. "\n" )

	et.trap_SendServerCommand ( -1, "chat \"" .. player .. "^7 tossed a coin...\"" )

	if number < 49 then
		et.trap_SendServerCommand ( -1, "chat \"Heads.\"" )
	elseif number > 50 then
		et.trap_SendServerCommand ( -1, "chat \"Tails.\"" )
	elseif number == 49 then
		et.trap_SendServerCommand ( -1, "chat \"The coin falls on its side!\"" )
	elseif number == 50 then
		et.trap_SendServerCommand ( -1, "chat \"A gypsy stole the coin.\"" )
	end
end

-- Private message
Command["pm"] = function(cno, cmd)
	if tonumber( et.trap_Argc() ) < 3 then
			et.trap_SendServerCommand( cno, "chat \"Usage: pm name message\"" )
			return(1)
	end

	local recipient_name = string.lower( et.Q_CleanStr( et.trap_Argv(1) ) )

	if recipient_name then
		for i=0, tonumber( et.trap_Cvar_Get( "sv_maxclients" ) )-1 do
			local player_name = getPlayerName( i )

			if player_name then
				local sender_name = getPlayerName( cno )
				s, e = string.find( string.lower( et.Q_CleanStr( player_name ) ), recipient_name )
				if s and e then
					if i ~= cno then -- PMing yourself?
						et.trap_SendServerCommand( i, "chat \"" .. sender_name .. "^7 -> " .. player_name .. "^7: ^5" .. et.ConcatArgs(2) .. "\"" )
						et.trap_SendServerCommand( cno, "chat \"" .. sender_name .. "^7 -> " .. player_name .. "^7: ^5" .. et.ConcatArgs(2) .. "\"" )
						return(1) -- send only to the first player matched	
					end
				end
			end
		end
		et.trap_SendServerCommand( cno, "chat \"No player whose name matches the pattern \'" .. recipient_name .. "\' was found.\"" )
		return(1)
	end
end

-- List users
Command["users"] = function(cno, cmd)
	et.G_Print ("^4List of users in the database:\n")
	for guid, nick, first_seen, last_seen, privilege, xp_battlesense, xp_engineering, xp_medic, xp_fieldops, xp_lightweapons, xp_heavyweapons, xp_covertops 
	in db_rows ( con, string.format ( [[ SELECT * FROM %susers ORDER BY nick DESC ]], dbprefix ) ) do
		  et.G_Print (string.format ( "\t%s is a level %i user who was last seen on %s and has a total of %i XP\n", 
		  nick, privilege, last_seen, (xp_battlesense + xp_engineering + xp_medic + xp_fieldops + xp_lightweapons + xp_heavyweapons + xp_covertops) ) )
	end
end
