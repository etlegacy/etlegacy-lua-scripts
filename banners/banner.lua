modname = "Banners"
version = "0.2"

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
--	timer1 = 5000
--	timer2 = 6000			ARE THOSE VALUES CORRECT AND MAKE SENSE HERE
--	timer3 = 7000			OR ALL THEY SHOULD BE REPLACED BY 1000 ? (BUT THIS WAY MIGHT GET MESSY)
--	timer4 = 8000
--	timer5 = 9000

-------------------------------------------------------------------------------------------------------------------
------------------ TODO! ------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------
-- print welcome message to connected client to show gratitude for client 
-- Get millisec value then increase it with timer's values
-- FIND OUT HOW TO MAKE IT INTO LOOP!!
-- Do a conditional statement if/elseif/else comparing
-------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------

function et_InitGame( levelTime, randomSeed, restart )
	et.RegisterModname( modname .. " " .. version )
	
	local milliseconds = et.trap_Milliseconds() -- is this right way ?

	if(milliseconds == timer)
		et.trap_SendServerCommand(clientNum, "cpm \"" .. banner .."^7\n")
		
		if(milliseconds == timer1)
			et.trap_SendServerCommand(clientNum, "cpm \"" .. banner1 .."^7\n")
			
			if(miliseconds == timer2)
				et.trap_SendServerCommand(clientNum, "cpm \"" .. banner2 .."^7\n")
				
				if(miliseconds == timer3)
					et.trap_SendServerCommand(clientNum, "cpm \"" .. banner3 .."^7\n")
					
					if(miliseconds == timer4)
						et.trap_SendServerCommand(clientNum, "cpm \"" .. banner4 .."^7\n")
						
							if(miliseconds == timer5)
								et.trap_SendServerCommand(clientNum, "cpm \"" .. banner5 .."^7\n")
							end -- is every if() statement needs else() ??
						
					end
					
				end
				
				
			end
		end
	else
		et.trap_SendServerCommand(clientNum, "cpm \"" .. "NO BANNERS" .."^7\n")
	end

end

function et_ClientConnect( clientNum, firstTime, isBot )
	et.trap_SendServerCommand(clientNum, "cpm \"" .. welcome .."^7\n")
	
end

function et_ShutdownGame( restart )

end