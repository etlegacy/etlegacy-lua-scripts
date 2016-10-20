modname = "Banners"
version = "0.3"

welcome = "^WELCOME MESSAGE" -- Welcome message here when client finished connecting to the server

-- Set Banners of you desire
banner = "..."
banner1 = "..."
banner2 = "..."
banner3 = "..."
banner4 = "..."
banner5 = "..."

-- Set time in miliseconds when banners string has to be executed
timer = 0
timer1 = 0
timer2 = 0
timer3 = 0
timer4 = 0
timer5 = 0


--------------------	SAMPLE	-----------------------------------------------------------------------------------
--	timer = 100000
--	timer1 = 105000
--	timer2 = 106000			ARE THOSE VALUES CORRECT AND MAKE SENSE HERE
--	timer3 = 107000			OR ALL THEY SHOULD BE REPLACED BY 1000 ? (BUT THIS WAY MIGHT GET MESSY)
--	timer4 = 108000
--	timer5 = 109000

-------------------------------------------------------------------------------------------------------------------
------------------ TODO! ------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------
-- print welcome message to connected client to show gratitude for client 
-- Get millisec value
-- FIND OUT HOW TO MAKE IT INTO LOOP!! OR JUST MILISECONDS (a) = NULL ?
-- Do a conditional statement if/elseif/else comparing
-------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------
------------------------------------------!!DO NOT CHANGE BELOW!!--------------------------------------------------

function et_InitGame( levelTime, randomSeed, restart )
	et.RegisterModname( modname .. " " .. version )
	
	local milliseconds = et.trap_Milliseconds() -- is this right way ?
	local a = (milliseconds*1000)/60

	if(a == timer)
		et.trap_SendServerCommand(clientNum, "cpm \"" .. banner .."^7\n")
	elseif(a == timer1)
		et.trap_SendServerCommand(clientNum, "cpm \"" .. banner1 .."^7\n")
	elseif(a == timer2)
		et.trap_SendServerCommand(clientNum, "cpm \"" .. banner2 .."^7\n")
	elseif(a == timer3)
		et.trap_SendServerCommand(clientNum, "cpm \"" .. banner3 .."^7\n")
	elseif(a == timer4)
		et.trap_SendServerCommand(clientNum, "cpm \"" .. banner4 .."^7\n")
	elseif(a == timer5)
		et.trap_SendServerCommand(clientNum, "cpm \"" .. banner5 .."^7\n")
	else
		et.trap_SendServerCommand(clientNum, "cpm \"" .. "NO BANNERS" .."^7\n")
	end

end
	
function et_ClientConnect( clientNum, firstTime, isBot )
	et.trap_SendServerCommand(clientNum, "cpm \"" .. welcome .."^7\n")	
end

function et_ShutdownGame( restart )

end