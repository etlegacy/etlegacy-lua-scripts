# Lua scripts

* Lua scripts for the Legacy mod.


## banners

* Banners managment system in lua

## dynamite

* This script supports beside legacy mod: ETPro, EtPub & NoQuarter
* Clients can toggle dynatimer with `setu v_dynatimer 1/0`

## xpsave

* This script is intended for Legacy mod, but may work in NoQuarter 1.2.9 and above
* LuaSQL module with sqlite3 driver is required
* The script could be tweaked to use file backend or other database drivers instead of sqlite3

## announcehp

* Killer's HP is displayed to their victims.

## medic-syringe-heal

Allows medics to heal nearly dead players using syringe.

If player has less than 25% of the health, medic can use syringe to heal the teammates either to full or half health, depending on medic healing skill level (eg. medic level 3 or more, heals teammate to the full health).
 
* This script is intended for legacy `2.77+` mod.

# Notes
* Please always add modname and version to your lua script
```
modname="NameofLua"
version="1.0"

function et_InitGame()
        et.RegisterModname(modname.." "..version)
end
```

