# Lua scripts

* Lua scripts for the Legacy mod. They might or might not work with other mods.
* Lua API doc: see https://legacy-lua-api.readthedocs.io

## banners

Banner management system for `legacy` mod.

Reserves next cvars to configure banners:
* `g_bannerTime` sets banner change interval (default `5000`)
* `g_bannerLocation` sets banner print location (default `top`)  
	Possible values:
	* `top` top of the screen, banner print spot (`bp`)
	* `left` popup messages (`cpm`)
	* `center` center print (`cp`)
	* `chat` chat print (`chat`)
* `g_bannerN` (where N is a number in range of `1` to `5`) sets banner messages

All cvars should be filled before lua module gets initialized.

* This script is intended for legacy `2.77+` mod.

## dynamite

* Clients can toggle dynatimer with `setu v_dynatimer 1/0`

## announcehp

* Killer's HP is displayed to their victims.

## medic-syringe-heal

Allows medics to heal nearly dead players using syringe.

If player has less than 25% of the health, medic can use syringe to heal the teammates either to full or half health, depending on medic healing skill level (eg. medic level 3 or more, heals teammate to the full health).
 
* This script is intended for legacy `2.77+` mod.

## spawn-invul-fair

Remove spawn shield protection when firing.

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

