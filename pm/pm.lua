
-- Private message
function et_ClientCommand(id, command)
	if string.lower( et.trap_Argv(0) ) == "pm" then

		if tonumber( et.trap_Argc ) < 3 then
				et.trap_SendServerCommand( id, "chat \"Usage: pm name message\"" )
				return(1)
		end

		local recipient_name = string.lower( et.Q_CleanStr( et.trap_Argv(1) ) )

		if recipient_name then
			for i=0, tonumber( et.trap_Cvar_Get( "sv_maxclients" ) )-1 do
				local player_name = et.gentity_get( i, "pers.netname" )

				if recipient_name then
					local sender_name = et.gentity_get( id, "pers.netname" )
					s, e = string.find( string.lower( et.Q_CleanStr( player_name ) ), recipient_name )
					if s and e then
						if i ~= id then -- PMing yourself?
							et.trap_SendServerCommand( i, "chat \"" .. sender_name .. "^7 -> " .. player_name .. "^7: ^5" .. et.ConcatArgs(2) .. "\"" )
						end
						et.trap_SendServerCommand( id, "chat \"" .. sender_name .. "^7 -> " .. player_name .. "^7: ^5" .. et.ConcatArgs(2) .. "\"" )
						return(1) -- send only to the first player matched				
					end
				end
			end
			et.trap_SendServerCommand( id, "chat \"No player whose name matches the pattern \'" .. recipient_name .. "\' was found.\"" )
			return(1)
		end
	end
end
