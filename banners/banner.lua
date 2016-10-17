modname = "Banners"
version = "0.1"

welcome = "..." -- Welcome message here when client finished connecting to the server

-- Set Banners of you desire
banner = "..."
banner1 = "..."
banner2 = "..."
banner3 = "..."
banner4 = "..."
banner5 = "..."

-- Set a time which
timer = 0
timer1 = 0
timer2 = 0
timer3 = 0
timer4 = 0
timer5 = 0


--------------------	SAMPLE	-----------------------------------------------------------------------------------
--	timer = 100000 
--	timer1 = 5000
--	timer2 = 6000
--	timer3 = 7000			OR ALL THEY SHOULD BE REPLACED BY 1000 ? (BUT THIS WAY MIGHT GET MESSY)
--	timer4 = 8000			ARE THOSE VALUES CORRECT AND MAKE SENSE HERE
--	timer5 = 9000			

-------------------------------------------------------------------------------------------------------------------
------------------ TODO! ------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------
-- print welcome message to connected client to show gratitude for client 
-- Get millisec value then increase it with timer's values 		IMPORTANT! "timer++" ?? 
-- Do a conditional statement if/elseif/else comparing
-------------------------------------------------------------------------------------------------------------------
-- BEST CHOISE SHOULD BE LOOP FOR WITH DO ? INSIDE FOR DO IF STATEMENTS???? 
-------------------------------------------------------------------------------------------------------------------

function et_InitGame( levelTime, randomSeed, restart )
     et.RegisterModname( modname .. " " .. version )
end