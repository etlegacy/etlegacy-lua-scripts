--[[
    This script adds a server side command to 
	send text to the chat with your own prefix.
	
	 - Replace "mycommand" by your custom command.
	
	 - Replace "myprefix" by your custom prefix or
	remove it for no prefix.
]]--

description = "Custom Prefix"
version = "0.1"

function et_InitGame(levelTime,randomSeed,restart)
    local modname = string.format("%s", description)
    et.G_Print(string.format("%s loaded\n", modname))
    et.RegisterModname(modname)
end

function et_ConsoleCommand(command,message)
  if et.trap_Argv(0) == "mycommand" then
    local message = et.trap_Argv(1)
    et.G_Print(message.."\n")
    et.trap_SendServerCommand(-1, "chat myprefix ^w "..message.."\n\"")
    end
  return 0
end
