
function et_ClientCommand(id, command)
	-- Private message
	if string.lower( et.trap_Argv(0) ) == "pm" then
		local recipient_name = string.lower( et.Q_CleanStr( et.trap_Argv(1) ) )

		if recipient_name then
			for i=0, tonumber( et.trap_Cvar_Get( "sv_maxclients" ) )-1 do
				local player_name = string.lower( et.Q_CleanStr( et.gentity_get( i, "pers.netname" ) ) )

				if recipient_name then
					local sender_name = et.gentity_get( id, "pers.netname" )
					s, e = string.find( player_name, recipient_name )
					if s and e then
						et.trap_SendServerCommand( i, "chat \"" .. sender_name .. "^7: ^5" .. et.ConcatArgs(2) .. "\" " .. i  .. " 0")
						return(1) -- send only to the first player matched				
					end
				end
			end
		end
	end
end
	