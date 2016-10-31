	modname = "Banners"
version = "0.5"

-- Welcome message when client finished connecting to the server
welcome = "^3WELCOME MESSAGE"

-- Set Banners of you desire
banner = "..."
banner1 = "..."
banner2 = "..."
banner3 = "..."
banner4 = "..."
banner5 = "..."

-- Set time in seconds when banners string has to be executed
timer = 10
timer1 = 15
timer2 = 20
timer3 = 25
timer4 = 30
timer5 = 35


-------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------
------------------------------------------!!DO NOT CHANGE BELOW!!--------------------------------------------------

function et_InitGame( levelTime, randomSeed, restart )
	et.RegisterModname( modname .. " " .. version )
	
	local milliseconds = et.trap_Milliseconds() -- is this right way ?
	local a = (milliseconds*1000)%60

	if(a == timer) 
		then et.trap_SendServerCommand(-1, "cp \"" .. banner .."^7\n") -- not better to announce it globally instead only to clientnum ?
	elseif(a == timer1)
		then et.trap_SendServerCommand(-1, "cp \"" .. banner1 .."^7\n")
	elseif(a == timer2)
		then et.trap_SendServerCommand(-1, "cp \"" .. banner2 .."^7\n")
	elseif(a == timer3)
		then et.trap_SendServerCommand(-1, "cp \"" .. banner3 .."^7\n")
	elseif(a == timer4)
		then et.trap_SendServerCommand(-1, "cp \"" .. banner4 .."^7\n")
	elseif(a == timer5)
		then et.trap_SendServerCommand(-1, "cp \"" .. banner5 .."^7\n")
		local milliseconds = 0 -- we reset it here
	else
		et.trap_SendServerCommand(-1, "cp \"" .. "NO BANNERS" .."^7\n")
	
	return milliseconds 
	
	end

end
	
function et_ClientConnect( clientNum, firstTime, isBot )
	et.trap_SendServerCommand(clientNum, "cp \"" .. welcome .."^7\n")	
end

function et_ShutdownGame( restart )

end