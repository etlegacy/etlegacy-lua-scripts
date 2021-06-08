modname="Antichat"
version="1.0"

function et_InitGame()
        et.RegisterModname(modname.." "..version)
end
-- Antichat by Ryven
-- Allow only wolfadmin commands to be passed

local blackList = { "say", "say_team", "say_buddy", "say_teamnl", "m", "pm" }
local whitelist = {
	"!help",
	"!admintest",
	"!greeting",
	"!rules",
	"!stats",
	"!sprees",
	"!listmaps",
	"!time",
	"!listplayers",
	"!finger",
	"!listaliases",
	"!listlevels",
	"!showwarns",
	"!showhistory",
	"!dewarn",
	"!showbans",
	"!warn",
	"!put",
	"!mute",
	"!unmute",
	"!vmute",
	"!vunmute",
	"!plock",
	"!punlock",
	"!kick",
	"!ban",
	"!unban",
	"!slap",
	"!gib",
	"!setlevel",
	"!incognito",
	"!balance",
	"!lock",
	"!unlock",
	"!shuffle",
	"!shufflesr",
	"!spec999",
	"!swap",
	"!cointoss",
	"!nextmap",
	"!pause",
	"!unpause",
	"!reset",
	"!restart",
	"!enablevote",
	"!needbots",
	"!kickbots",
	"!putbots",
	"!readconfig",
	"!listlevels",
	"!resetsprees"
}

local function contains(table, value)
	if value == "" then 
		return false
	end
   	for i = 1, #table do
      	if table[i] == value then 
         	return true
      	end
   	end
   return false
end

function et_ClientCommand(clientNum, command)
	if contains(blackList, command) then
		local arg = et.trap_Argv(1)
		if not contains(whitelist, arg) then
			return 1
		end
	end
	return 0
end
