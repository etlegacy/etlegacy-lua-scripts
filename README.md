# Lua scripts

* Lua scripts for the Legacy mod.


## CONSTANTS

* Scripts with useful constants for custom scripts

## banners (under construction)

* Banners managment system in lua

## dynamite

* This Script supports beside legacy mod: ETPro, EtPub & NoQuarter
* Clients can toggle dynatimer with `setu v_dynatimer 1/0`

## xpsave

* This script is intended for Legacy mod, but may work in NoQuarter 1.2.9 and above
* LuaSQL module with sqlite3 driver is required
* The script could be tweaked to use file backend or other database drivers instead of sqlite3

## announcehp

* Killer's HP is displayed to their victims.

# Notes
* Please always add modname and version to your lua script
```
modname="NameofLua"
version="1.0"

function et_InitGame()
        et.RegisterModname(modname.." "..version)
end
```

