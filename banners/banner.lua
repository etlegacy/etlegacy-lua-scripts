modname = "Banners"
version = "0.5"

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
	
	local mil_sec = (levelTime*1000)%60
	
	while(true) do
	
		if(mil_sec == timer) 
			then et.trap_SendConsoleCommand( et.EXEC_NOW, "cp \"" .. banner .."^7\n" )
		elseif(mil_sec == timer1)
			then et.trap_SendConsoleCommand( et.EXEC_NOW, "cp \"" .. banner1 .."^7\n" )
		elseif(mil_sec == timer2)
			then et.trap_SendConsoleCommand( et.EXEC_NOW, "cp \"" .. banner2 .."^7\n" )
		elseif(mil_sec == timer3)
			then et.trap_SendConsoleCommand( et.EXEC_NOW, "cp \"" .. banner3 .."^7\n" )
		elseif(mil_sec == timer4)
			then et.trap_SendConsoleCommand( et.EXEC_NOW, "cp \"" .. banner4 .."^7\n" )
		elseif(mil_sec == timer5)
			then et.trap_SendConsoleCommand( et.EXEC_NOW, "cp \"" .. banner5 .."^7\n" )
			local mil_sec = 0 -- we reset it here
		else
			et.trap_SendConsoleCommand( et.EXEC_NOW, "cp \"" .. "NO BANNERS" .."^7\n" )
	
		end
	end
	
	return 0
end

function et_ShutdownGame( restart )
	et.G_Print("Shutting down: " .. modname .. "\n")
end