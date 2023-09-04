--------------------------------------------------------------------------------
-- ETWsk - ETW-FZ Enemy Territory Anti-Spawnkill Mod for etpro
--------------------------------------------------------------------------------
-- This script can be freely used and modified as long as [ETW-FZ] and the
-- original author are mentioned.
--------------------------------------------------------------------------------
module_name    = "ETWsk"
module_version = "0.9.1"
Author         = "[ETW-FZ] Mad@Mat"
-- 2010-11-24 benny [ quakenet @ #hirntot.org ] --> putspec for etpub
-- 2009-03-12 benny [ quakenet @ #hirntot.org ] --> temp ban persistent offenders
-- 2008-11-16 benny [ quakenet @ #hirntot.org ] --> no warmup punish
-- 2008-10-06 benny [ quakenet @ #hirntot.org ] --> sin bin added.


--------------------------------------------------------------------------------
-- DESCRIPTION
--------------------------------------------------------------------------------
-- ETWsk aims to reduce spawnkilling (SK) on public funservers. An SK here is if
-- someone kills an enemy near a fix spawn point. A fix spawn point means that
-- it can not be cleared by the enemy. E.g. on radar map, the allied Side Gate
-- spawn is not fix as the axis can destroy the command post. However, the Main
-- Bunker spawn is fix after the Allies have destroyed the Main Gate. ETWsk does
-- not prevent but it detects and counts SKs for every player. If a player has
-- caused a certain number of SKs, he gets punished (putspec, kick, ban, ...).
-- As the detection of fix spawns is difficult especially on custom maps, little
-- configuration work has to be done.
--
-- Features:
--     - circular protection areas around spawn points
--     - two protection radius can be defined: heavy weapons and normal weapons
--     - the spawn protection expires when a player hurts an enemy
--       (can be disabled)
--     - fully configurable for individual maps: fixing radius, positions;
--       adding actions that change protected areas during the game; adding new
--       protection areas.
--     - client console commands for stats and help for configuration
--     - no RunFrame() -> low server load
--     - sin bin [benny] --> don't let clients join a team for XX milliseconds
--       if they have been set spec
--     - temp ban for persistent spawn killers [benny]
--------------------------------------------------------------------------------
-- CONFIG
--------------------------------------------------------------------------------
ETWsk_putspec = 1                -- number of sk's needed for setting a client
                                 -- to spectators
ETWsk_kick = 99                  -- number of sk's needed for kicking a client
ETWsk_kicklen = 20*60               -- duration of kick
-- benny -----------------------------------------------------------------------
ETWsk_persistentoffender = 1     -- enable punishment 4 persistent spawn killers
ETWsk_POThreshold = 2            -- if players has been kicked before, he will
                                 -- be temp banned with his XX spawn kill
ETWsk_banval = 30*60                -- (ETWsk_banval * 4 ^ kicksb4) = ban
                                 -- If ETWsk_banval = 30, he'll be kicked 4
                                 -- 120 minutes, next is 480, 1920, 7680, ...
ETWsk_pofile = "ETWsk_PO.txt"    -- save to /etpro/ETWsk_PO.txt
--------------------------------------------------------------------------------
ETWsk_defaultradius1 = 0         -- protection radius for ordinary weapons
ETWsk_defaultradius2 = 0         -- protection radius for heavy weapons. def 800
ETWsk_savemode = 1               -- if enabled, protection is only active on
                                 -- maps that are configured
ETWsk_expires = 0                -- if enabled, spawn protection expires when
                                 -- the victim hurts an enemy
-- benny -----------------------------------------------------------------------
sinbin          = true           -- [true|false]
sinbin_duration = 15000          -- in milliseconds: 30000 = 30 seconds
sinbin_pos      = "chat"          -- prints to client on sin bin, "b 8 " = chat area
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- heavyweapons = {17,19,27,49,57,30}     -- heavy weapon indexes
                               -- (http://wolfwiki.anime.net/index.php/Etdamage)

-- benny 'ref remove' doesn't work w/ bots in etpub...
function putspec(id)
  return(string.format(putspec_str, id))
end
putspec_str = "ref remove %d\n"

heavyweapons = {1, 2, 3, 15, 17, 23, 26, 44, 52, 62, 63, 64}            -- heavy weapon indexes 

maxcheckpointdist = 800          -- used to detect capturable flag poles
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- CONSTANTS
NO_PROTECT     = 0
PROTECT_AXIS   = 1
PROTECT_ALLIES = 2
--------------------------------------------------------------------------------

-- benny: sin bin hash + persistent offender hash
sinbinhash = {}
pohash = {}
et.CS_PLAYERS = 689

--------------------------------------------------------------------------------
function getConfig(map)
--------------------------------------------------------------------------------
-- configures protection of spawn areas in specific maps
--------------------------------------------------------------------------------
--  elseif map == "<the map name>" then
--      <spawn definitions>
--      <action definitions>
--------------------------------------------------------------------------------
-- spawn definitions:
--      c.spawn[<spawn-num>] = {<spawn-fields>}
-- spawn-num: spawn index (see /etwsk_spawns command)
-- spawn-fields: - comma-separated list of "key = value"
--               - for existing spawns all fields are optional (they overwrite
--                 default values).
--               - fields:
--                     name = <String>  : name of spawn point
--                     state = NO_PROTECT|PROTECT_ALLIES|PROTECT_AXIS
--                     pos = {x,y,z}    : map coordinates of spawn point
--                     radius1 = <Int>  : protection radius for normal weapons
--                     radius2 = <Int>  : protection radius for heavy weapons
-- action definitions: actions are definitions of transitions of one state of a
--                     spawn point into another one triggered by a message.
--      c.action[<action-num>] = {<action-fields>}
-- action-num: just an increment number
-- action-fields: - comma-separated list of "key = value"
--                - all fields are mandatory
--                - fields:
--                     spawn = <spawn-num>
--                     newstate = NO_PROTECT|PROTECT_ALLIES|PROTECT_AXIS
--                     trigger = <String>: part of a message that is displayed
--                                         by the server on a specific event.
-- adding new protection areas to maps:
--     new protection areas can easily been added:
--     1. enter the map and walk to the location where you want to add the area
--     2. type /etwsk_spawns and remember the highest spawn index number
--     3. type /etwsk_pos and write down the coordinates
--     4. add spawn to config with at least the name,state and pos field
-- default values:
--     At mapstart, ETWsk scans for all spawnpoints and sets the state either to
--     PROTECT_ALLIES or PROTECT_AXIS. It also scans for capturable flag poles
--     and sets the state of a spawnpoint near a flag pole to NO_PROTECT. The
--     location of a spawnpoint is taken from the WOLF_objective entity, the
--     small spawn flag that can be selected in the command map. This entity is
--     usually placed in the center of the individual player-spawnpoints.
--     However, on some maps this is not the case. Check the positions of the
--     small spawn flags on the command map or type /etwsk_pos after you have
--     spawned to check the distance to protected areas. If needed, adjust the
--     radius, or the pos or add a new protection area to the map.
--     If you wish to set all protection areas manually in a map, add:
--         c.defaults = false
--     to the definitions for a map.
--------------------------------------------------------------------------------
    hasconfig = true
    local c = {spawns = {}, actions = {}, defaults = true}
-- airassfp1 28.03.2010
    if map == "airassfp1" then
        c.spawns[1] = {name = "Base Barracks", state = PROTECT_AXIS, pos = {-410, -4450, 346}, radius2 = 400}
        c.spawns[2] = {name = "Airfield Base", state = PROTECT_AXIS, pos = {-1660, 750, 240}, radius2 = 600}
        c.spawns[3] = {name = "Airfield Base2", state = PROTECT_AXIS, pos = {-1660, 40, 240}, radius2 = 400}
        c.spawns[4] = {name = "Allied Train Entrance", state = PROTECT_ALLIES, pos = {2650, -7530, 410}, radius2 = 1000}
        c.actions[1] = {spawn = 1, newstate = PROTECT_ALLIES, trigger = "Allies have blown up the Main Entrance!"}
-- Siwa Oasis 16.11.2008 Update 21.04.2013
    elseif map == "oasis" then
--        c.spawns[1] = {name = "Axis Garrison", state = PROTECT_AXIS, pos = {7400, 4810, -391}, radius2 = 460}
        c.spawns[1] = {name = "Axis Garrison", state = PROTECT_AXIS, pos = {7420, 4710, -391}, radius2 = 500}
        c.spawns[2] = {name = "Allied Camp Base", state = PROTECT_ALLIES, pos = {1250, 2760, -415}, radius2 = 1140}
        c.spawns[3] = {name = "Old City", state = NO_PROTECT, pos = {4300, 7000, -450}, radius2 = 870}
        c.actions[1] = {spawn = 3, newstate = PROTECT_ALLIES, trigger = "breached the Old City wall"}
-- __BRIDGES__ 28.03.2010
    elseif map == "__bridges__" then
        c.spawns[1] = {name = "The Sawmill Spawns", state = PROTECT_ALLIES, pos = {-4850, -7620, 820}, radius2 = 500}
        c.spawns[2] = {name = "The Mill Tunnel Spawns", state = PROTECT_ALLIES, pos = {-1470, -2230, 630}, radius2 = 460}
        c.spawns[3] = {name = "The Reservoir Spawns", state = PROTECT_AXIS, pos = {9440, 3680, 680}, radius2 = 500}
        c.spawns[4] = {name = "North Tunnel2", state = PROTECT_AXIS, pos = {4020, 1200, 820}, radius2 = 300}
        c.spawns[5] = {name = "The Boathouse Spawns", state = NO_PROTECT, pos = {180, 2100, 310}, radius2 = 500}
        c.spawns[6] = {name = "The Mill Service Tunnel Spawns", state = NO_PROTECT, pos = {-5094, -2452, 480}, radius2 = 300}
        c.actions[1] = {spawn = 5, newstate = PROTECT_AXIS, trigger = "Axis gained spawn positions at The Boathouse!"}
        c.actions[2] = {spawn = 4, newstate = PROTECT_ALLIES, trigger = "Allies gained positions in the North Tunnel!"}
        c.actions[3] = {spawn = 2, newstate = NO_PROTECT, trigger = "Allies gained positions in the North Tunnel!"}
        c.actions[4] = {spawn = 5, newstate = NO_PROTECT, trigger = "Axis are regrouping at the reservoir!"}
        c.actions[5] = {spawn = 2, newstate = PROTECT_ALLIES, trigger = "allies have gained spawn positions in the Mill Tunnel"}
        c.actions[6] = {spawn = 4, newstate = PROTECT_AXIS, trigger = "allies have gained spawn positions in the Mill Tunnel"}
        c.actions[7] = {spawn = 2, newstate = PROTECT_AXIS, trigger = "Axis gained spawn positions at The Mill Tunnel"}
        c.actions[8] = {spawn = 4, newstate = NO_PROTECT, trigger = "Axis gained spawn positions at The Mill Tunnel"}
        c.actions[9] = {spawn = 6, newstate = PROTECT_AXIS, trigger = "Axis gained spawn positions at The Mill Tunnel"}

-- Axislab 28.03.2010
    elseif map == "axislab_final" then
        c.spawns[1] = {name = "Hill Top", state = NO_PROTECT, pos = {-162, 2540, 1130}, radius2 = 600}
        c.spawns[2] = {name = "Allied Side", state = PROTECT_ALLIES, pos = {2250, -4140, 170}, radius2 = 1000}
        c.spawns[3] = {name = "Allied Cabin", state = NO_PROTECT, pos = {-2900, 225, 330}, radius2 = 100}
        c.spawns[4] = {name = "Axis Bunker", state = PROTECT_AXIS, pos = {-1450, 2400, 470}, radius2 = 300}
        c.spawns[5] = {name = "Axis Bunker2", state = PROTECT_AXIS, pos = {-1420, 2100, 470}, radius2 = 300}
        c.spawns[6] = {name = "Axis Bunker3", state = PROTECT_AXIS, pos = {-990, 2038, 470}, radius2 = 300}
        c.spawns[7] = {name = "Boardroom", state = PROTECT_AXIS, pos = {240, 1190, 310}, radius2 = 300}
        c.actions[1] = {spawn = 1, newstate = PROTECT_ALLIES, trigger = "Allies have secured the Hill Top!"}
-- et_mor2 28.03.2010
    elseif map == "et_mor2" then
        c.spawns[1] = {name = "Desert Camp", state = PROTECT_ALLIES, pos = {9590, 1600, -300}, radius2 = 1300}
        c.spawns[2] = {name = "Gate House", state = PROTECT_AXIS, pos = {1720, 700, 30}, radius2 = 470}
        c.spawns[3] = {name = "Gate House2", state = PROTECT_AXIS, pos = {2360, 645, 30}, radius2 = 300}
        c.spawns[4] = {name = "NorthMarket", state = PROTECT_AXIS, pos = {-1290, 1620, 30}, radius2 = 600}
        c.actions[1] = {spawn = 2, newstate = PROTECT_ALLIES, trigger = "Allies have destroyed the Main town gate!"}
        c.actions[2] = {spawn = 3, newstate = PROTECT_ALLIES, trigger = "Allies have destroyed the Main town gate!"}
-- bulge_beta1 aka Wacht am Rhein 07.04.2010
    elseif map == "bulge_beta1" then
        c.spawns[1] = {name = "Hotel", state = PROTECT_ALLIES, pos = {4060, -620, 330}, radius2 = 600}
        c.spawns[2] = {name = "Allied Town Spawn", state = PROTECT_ALLIES, pos = {-4210, -800, 105}, radius2 = 600}
        c.spawns[3] = {name = "Axis Headquarters", state = PROTECT_AXIS, pos = {4120, -4360, 400}, radius2 = 900}        
        c.actions[1] = {spawn = 1, newstate = PROTECT_AXIS, trigger = "The Tank is at the Hotel"}
        c.actions[2] = {spawn = 1, newstate = NO_PROTECT, trigger = "The tank is near the 1st tank barrier"}
-- mp_rocket_et_a1 09.04.2010
    elseif map == "mp_rocket_et_a1" then
        c.spawns[1] = {name = "Security Checkpoint", state = NO_PROTECT}
        c.spawns[2] = {name = "The Train Cars", state = PROTECT_ALLIES, pos = {2570, -470, 25}, radius2 = 500}
        c.spawns[3] = {name = "Security Checkpoint Axis", state = PROTECT_AXIS, pos = {370, 1250, 150}, radius2 = 500}
        c.spawns[4] = {name = "Security Checkpoint Axis", state = PROTECT_AXIS, pos = {-10, 1360, 336}, radius2 = 300}
-- caen2 29.04.2010
-- x0rnn 2018/03/22 decreased allied spawn radius
    elseif map == "caen2" then
        c.spawns[1] = {name = "TOWN", state = NO_PROTECT}
        c.spawns[2] = {name = "Axis Spawn", state = PROTECT_AXIS, pos = {-1690, -2200, 310}, radius2 = 600}
        c.spawns[3] = {name = "Allies Spawn", state = PROTECT_ALLIES, pos = {-2120, 6130, 570}, radius2 = 523}
        c.actions[1] = {spawn = 1, newstate = PROTECT_AXIS, trigger = "The Axis are moving the Tank!"} 
-- snatch3 29.04.2010
    elseif map == "snatch3" then
        c.spawns[1] = {name = "Forest House", state = NO_PROTECT, pos = {-860, -1950, 190}, radius2 = 600}
        c.spawns[2] = {name = "Base Spawn", state = PROTECT_AXIS, pos = {40, 2200, 600}, radius2 = 400}
        c.spawns[3] = {name = "Allied House", state = PROTECT_ALLIES, pos = {2400, 2220, 215}, radius2 = 600}        
-- Railgun
    elseif map == "railgun" then
        c.spawns[1] = {name = "Axis Tower Spawn", state = NO_PROTECT}
        c.spawns[2] = {name = "Axis Construction Site", pos = {-1300, 5183, 420}, state = PROTECT_AXIS, radius2 = 1820}
        c.spawns[4] = {name = "Allied Camp", state = PROTECT_ALLIES, radius2 = 700}
        c.spawns[5] = {name = "Allied Camp", state = PROTECT_ALLIES, pos = {6000, 3370, 280}, radius2 = 790}
-- Seawall Battery
    elseif map == "battery" then
        c.spawns[1] = {name = "Axis Main Bunker", state = PROTECT_AXIS, pos = {3000, -5300, 1016}, radius2 = 400}
        c.spawns[2] = {name = "Allied East Beach", state = PROTECT_ALLIES, pos = {4565, -620, 113}, radius2 = 450}
        c.spawns[3] = {name = "Allied East Beach 2", state = PROTECT_ALLIES, pos = {5136, -1184, 488}, radius2 = 450}
        c.spawns[4] = {name = "Allied West Beach", state = PROTECT_ALLIES, pos = {544, -760, 113}, radius2 = 400}
        c.spawns[5] = {name = "Command Post spawnt", state = NO_PROTECT}
        c.spawns[6] = {name = "West Bunker Allies", state = NO_PROTECT}
        c.spawns[7] = {name = "Axis spawn / Command Post", state = NO_PROTECT}
-- SW Seawall Battery
    elseif map == "sw_battery" then
        c.spawns[1] = {name = "Axis Main Bunker", state = PROTECT_AXIS, pos = {3000, -5300, 1016}, radius2 = 400}
        c.spawns[2] = {name = "Allied East Beach", state = PROTECT_ALLIES, pos = {4565, -620, 113}, radius2 = 550}
        c.spawns[3] = {name = "Allied West Beach", state = PROTECT_ALLIES, pos = {544, -760, 113}, radius2 = 400}
        c.spawns[4] = {name = "Command Post spawnt", state = NO_PROTECT}
        c.spawns[5] = {name = "West Bunker Allies", state = NO_PROTECT}
        c.spawns[6] = {name = "Axis spawn / Command Post", state = NO_PROTECT}
-- W�rzburg Radar
-- Radar 05.10.2018 - added axis house exit protection
    elseif map == "radar" then
        c.spawns[1] = {state = NO_PROTECT} -- Side Gate Command Post Spawn
        c.spawns[2] = {name = "Abandoned Villa", state = PROTECT_ALLIES, pos = {2504, 3422, 1333}, radius2 = 999}
        c.spawns[6] = {name = "Abandoned Villa", state = PROTECT_ALLIES, pos = {1504, 4495, 1333}, radius2 = 660}
        c.spawns[3] = {name = "Forward Bunker", state = NO_PROTECT, pos = {-581, 1661, 1364}, radius2 = 785}
        c.spawns[4] = {name = "Forward Hut", state = NO_PROTECT}
        c.spawns[5] = {name = "Lower Warehouse", state = PROTECT_AXIS, pos = {-1494, -4032, 1248}, radius2 = 330}
        c.spawns[7] = {name = "Lower Warehouse II", state = PROTECT_AXIS, pos = {-1270, -3772, 1248}, radius2 = 230}
        c.spawns[8] = {name = "Lower Warehouse III", state = PROTECT_AXIS, pos = {-1369, -3662, 1248}, radius2 = 151}
        c.actions[1] = {spawn = 3, newstate = PROTECT_ALLIES, trigger = "secured the Forward Bunker"}
    elseif map == "radar_phx_b_3" or map == "radar_truck" then
        c.spawns[1] = {state = NO_PROTECT} -- Side Gate Command Post Spawn
        c.spawns[2] = {name = "Abandoned Villa", state = PROTECT_ALLIES, pos = {2504, 3422, 1333}, radius2 = 999}
        c.spawns[6] = {name = "Abandoned Villa", state = PROTECT_ALLIES, pos = {1504, 4495, 1333}, radius2 = 660}
        c.spawns[3] = {name = "Forward Bunker", state = NO_PROTECT, pos = {-581, 1661, 1364}, radius2 = 785}
        c.spawns[4] = {name = "Forward Hut", state = NO_PROTECT}
        c.spawns[5] = {name = "Lower Warehouse", state = PROTECT_AXIS, pos = {-1494, -4032, 1248}, radius2 = 330}
        c.spawns[7] = {name = "Lower Warehouse II", state = PROTECT_AXIS, pos = {-1270, -3772, 1248}, radius2 = 230}
        c.spawns[8] = {name = "Lower Warehouse III", state = PROTECT_AXIS, pos = {-1369, -3662, 1248}, radius2 = 151}
        c.actions[1] = {spawn = 3, newstate = PROTECT_ALLIES, trigger = "secured the Forward Bunker"}
        c.actions[2] = {spawn = 2, newstate = PROTECT_AXIS, trigger = "Axis Abandoned Villa spawn enabled"}
        c.actions[3] = {spawn = 6, newstate = PROTECT_AXIS, trigger = "Axis Abandoned Villa spawn enabled"}
-- Fueldump
-- Fueldump 05.10.2018 - added lower axis fuel dump spawn exit protection, added allied tunnel spawn protection
    elseif map == "fueldump" then
        c.spawns[1] = {name = "Tunnel Store Room I", state = PROTECT_AXIS, pos = {-5142, -1724, 500}, radius2 = 290}
        c.spawns[6] = {name = "Tunnel Store Room II", state = PROTECT_AXIS, pos = {-5652, -2275, 600}, radius2 = 300}
        c.spawns[7] = {name = "Tunnel Store Room Lower Entrance", state = PROTECT_AXIS, pos = {-5655, -1471, 376}, radius2 = 80}
        c.spawns[8] = {name = "Tunnel Store Room Stair Way", state = PROTECT_AXIS, pos = {-5661, -1699, 520}, radius2 = 320}
        c.spawns[2] = {state = NO_PROTECT} -- Truck
        c.spawns[3] = {state = NO_PROTECT} -- Garage HQ
        c.spawns[4] = {name = "Axis Fuel Dump", state = PROTECT_AXIS, pos = {-8400, -5663, 417}, radius2 = 665}
        c.spawns[9] = {name = "Axis Fuel Dump", state = PROTECT_AXIS, pos = {-8393, -6723, 232}, radius2 = 700}
        c.spawns[5] = {name = "Allied Entrance", state = PROTECT_ALLIES, pos = {-857, -8050, 328}, radius2 = 870}
        c.spawns[10] = {name = "Tunnel Spawn", state = NO_PROTECT, pos = {-6165, -1288, 344}, radius2 = 300}
        c.spawns[11] = {name = "Axis Fuel Dump Lower Exit", state = PROTECT_AXIS, pos = {-8977, -7310, 232}, radius2 = 200}
        c.actions[1] = {spawn = 1, newstate = PROTECT_ALLIES, trigger = "breached the Tunnel Doors"}
        c.actions[2] = {spawn = 6, newstate = PROTECT_ALLIES, trigger = "breached the Tunnel Doors"}
        c.actions[3] = {spawn = 7, newstate = PROTECT_ALLIES, trigger = "breached the Tunnel Doors"}
        c.actions[4] = {spawn = 8, newstate = PROTECT_ALLIES, trigger = "breached the Tunnel Doors"}
        c.actions[5] = {spawn = 10, newstate = PROTECT_ALLIES, trigger = "Tunnel Spawn enabled"}
        c.actions[6] = {spawn = 10, newstate = NO_PROTECT, trigger = "Tunnel Spawn disabled"}
-- Adlernest B4 16.11.2008
    elseif map == "adlernest" or map == "etl_adlernest" then
        c.spawns[1] = {state = PROTECT_ALLIES, radius2 = 570}
        c.spawns[4] = {name = "Tank", state = PROTECT_ALLIES, pos = {2513, -321,-95}, radius2 = 540}
        c.spawns[2] = {state = NO_PROTECT}
        c.spawns[3] = {name = "Axis1", state = PROTECT_AXIS, pos = {-1949, -725, 72}, radius2 = 334}
        c.spawns[5] = {name = "Axis2", state = PROTECT_AXIS, pos = {-1925, -50, 72}, radius2 = 334}
        c.spawns[6] = {name = "Axis3", state = PROTECT_AXIS, pos = {-978, -445, 72}, radius2 = 334}
        c.spawns[7] = {name = "Axis4", state = PROTECT_AXIS, pos = {-1464, -596, 72}, radius2 = 334}
        c.spawns[8] = {name = "Axis5", state = PROTECT_AXIS, pos = {-1241, -212, 72}, radius2 = 434}
        c.spawns[9] = {name = "Axis6", state = PROTECT_AXIS, pos = {-1597, -184, 100}, radius2 = 447}

-- Adlernest_roof_b4
    elseif map == "adlernest_roof_b4" then
        c.spawns[1] = {name = "Tank", state = PROTECT_ALLIES, pos = {3476, -1037, -95}, radius2 = 800}
        c.spawns[2] = {name = "CP Spawn", state = NO_PROTECT}
        c.spawns[3] = {name = "Axis1", state = PROTECT_AXIS, pos = {-1949, -725, 72}, radius2 = 334}
        c.spawns[4] = {name = "Axis2", state = PROTECT_AXIS, pos = {-1925, -50, 72}, radius2 = 334}
        c.spawns[5] = {name = "Axis3", state = PROTECT_AXIS, pos = {-978, -445, 72}, radius2 = 334}
        c.spawns[6] = {name = "Axis4", state = PROTECT_AXIS, pos = {-1464, -596, 72}, radius2 = 334}
        c.spawns[7] = {name = "Axis5", state = PROTECT_AXIS, pos = {-1241, -212, 72}, radius2 = 334}
        c.spawns[8] = {name = "Axis6", state = PROTECT_AXIS, pos = {-1597, -184, 100}, radius2 = 447}
        c.spawns[9] = {name = "Allies Roof1", state = PROTECT_ALLIES, pos = {520, -2522, 546}, radius2 = 650}
        c.spawns[10] = {name = "Allies Roof2", state = PROTECT_ALLIES, pos = {-29, -2296, 296}, radius2 = 200}
        c.spawns[11] = {name = "Axis Roof1", state = PROTECT_AXIS, pos = {-1543, 264, 72}, radius2 = 293}
        c.spawns[12] = {name = "Axis Roof2", state = PROTECT_AXIS, pos = {-1543, 567, 72}, radius2 = 365}
        c.spawns[13] = {name = "Axis Roof3", state = PROTECT_AXIS, pos = {-1277, -386, 296}, radius2 = 400}
        c.spawns[14] = {name = "Axis Roof4", state = PROTECT_AXIS, pos = {-1701, -149, 296}, radius2 = 200}

-- Braundorf B4 16.11.2008
        elseif map == "braundorf_b4" or map == "braundorf_final" then
        c.spawns[1] = {name = "Factory District", state = NO_PROTECT, pos = {3505, -2355, 320}, radius2 = 375}
        c.spawns[9] = {name = "Factory District", state = NO_PROTECT, pos = {3405, -2355, 320}, radius2 = 375}
        c.spawns[2] = {name = "Bunker Back", state = PROTECT_AXIS, pos = {2849, 1919, 74}, radius2 = 250}
        c.spawns[5] = {name = "Bunker Middle Back", state = PROTECT_AXIS, pos = {2687, 1562, 24}, radius2 = 190}
        c.spawns[6] = {name = "Bunker Front", state = PROTECT_AXIS, pos = {2687, 383, 24}, radius2 = 170}
        c.spawns[7] = {name = "Bunker Middle Front", state = PROTECT_AXIS, pos = {2687, 741, 24}, radius2 = 180}
        c.spawns[8] = {name = "Bunker Middle", state = PROTECT_AXIS, pos = {2693, 1140, 24}, radius2 = 202}
        c.spawns[3] = {state = PROTECT_ALLIES, radius2 = 540}--Allied Spawn
        c.spawns[4] = {state = NO_PROTECT} --Command Post Spawn
        c.actions[1] = {spawn = 1, newstate = PROTECT_ALLIES, trigger = "Allies permanently capture the factory district!"}
        c.actions[2] = {spawn = 9, newstate = PROTECT_ALLIES, trigger = "Allies permanently capture the factory district!"}
-- Karsiah TE2
    elseif map == "karsiah_te2" then
        c.spawns[1] =  {name = "Backyard", state = PROTECT_AXIS, pos = {-1152, -263, 73}, radius2 = 395}
        c.spawns[4] =  {name = "Backyard", state = PROTECT_AXIS, pos = {-1050, -263, 73}, radius2 = 395}
        c.spawns[5] =  {name = "Backyard", state = PROTECT_AXIS, pos = {-1240, -263, 73}, radius2 = 470}
        c.spawns[2] =  {name = "Allied Hideout", state = PROTECT_ALLIES, pos = {4165, 430, 152}, radius2 = 335}
        c.spawns[3] =  {name = "Old City", state = NO_PROTECT, pos = {1304, -1430, 290}, radius2 = 400}
        c.actions[1] = {spawn = 3, newstate = PROTECT_ALLIES, trigger = "captured the Old City"}
-- SW Siwa Oasias B3 16.11.2008
    elseif map == "sw_oasis_b3" then
        c.spawns[1] = {name = "Axis Garrison", state = PROTECT_AXIS, pos = {7420, 4610, -391}, radius2 = 550}
        c.spawns[2] = {name = "Old City", state = NO_PROTECT, pos = {4300, 7000, -450}, radius2 = 870}
        c.spawns[3] = {name = "Axis Upper Garrison", state = NO_PROTECT}
        c.spawns[4] = {name = "Allied Camp Base", state = PROTECT_ALLIES, pos = {1250, 2760, -400}, radius2 = 1140}
        c.spawns[5] = {name = "Allied Camp Water Pump", state = NO_PROTECT, pos = {2584, 2144, -592}, radius2 = 1000}
        c.spawns[6] = {name = "Axis Garrison Above", state = PROTECT_AXIS, pos = {7378, 4090, -199}, radius2 = 190}
        c.actions[1] = {spawn = 2, newstate = PROTECT_ALLIES, trigger = "breached the Old City wall"}
        c.actions[2] = {spawn = 4, newstate = NO_PROTECT, trigger = "Allies have built the Oasis Water"}
        c.actions[3] = {spawn = 5, newstate = PROTECT_ALLIES, trigger = "Allies have built the Oasis Water"}
        c.actions[4] = {spawn = 4, newstate = PROTECT_ALLIES, trigger = "Axis have damaged the Oasis Water"}
        c.actions[5] = {spawn = 5, newstate = NO_PROTECT, trigger = "Axis have damaged the Oasis Water"}
-- Goldrush 25.11.2008
-- Goldrush 05.10.2018 - disabled Allied spawnroof protection when truck with gold is near truck barrier #2
        elseif map == "goldrush" or map == "sw_goldrush_te" or map == "uje_goldrush" then
        c.spawns[1] = {name = "Tank Depot Main Exit", state = PROTECT_AXIS, pos = {-79, 3005, 320}, radius2 = 250}
        c.spawns[4] = {name = "Tank Depot Alternate Exit", state = PROTECT_AXIS, pos = {-664, 3541, 386}, radius2 = 420}
        c.spawns[5] = {name = "Tank Depot Room", state = PROTECT_AXIS, pos = {-48, 3649, 344}, radius2 = 550}
        c.spawns[13] = {name = "Tank Depot Room Exit", state = PROTECT_AXIS, pos = {110, 3100, 320}, radius2 = 370}
        c.spawns[6] = {name = "Tank Depot", state = NO_PROTECT, pos = {-354, 2552, 344}, radius2 = 525}
        c.spawns[7] = {name = "Tank Depot", state = NO_PROTECT, pos = {-354, 2052, 344}, radius2 = 525}
        c.spawns[8] = {name = "Tank Depot", state = NO_PROTECT, pos = {-354, 1552, 344}, radius2 = 250}
        c.spawns[2] = {name = "Axis", state = PROTECT_AXIS, pos = {3000, -822, -435}, radius2 = 600}
        c.spawns[9] = {name = "Axis", state = PROTECT_AXIS, pos = {3010, -1555, -435}, radius2 = 250}
        c.spawns[10] = {name = "Axis Lower Spawn", state = PROTECT_AXIS, pos = {3000, -822, -435}, radius2 = 600}
        c.spawns[11] = {name = "Axis Lower Spawn", state = PROTECT_AXIS, pos = {3010, -1555, -435}, radius2 = 250}
        c.spawns[12] = {name = "Axis", state = PROTECT_AXIS, pos = {2327, -868, -199}, radius2 = 200}
        c.spawns[3] = {name = "Allied Spawn", state = PROTECT_ALLIES, pos = {-3360, -218, -67}, radius2 = 720}
        c.actions[1] = {spawn = 1, newstate = PROTECT_ALLIES, trigger = "Allied team has stolen the Tank"}
        c.actions[2] = {spawn = 4, newstate = PROTECT_ALLIES, trigger = "Allied team has stolen the Tank"}
        c.actions[3] = {spawn = 5, newstate = PROTECT_ALLIES, trigger = "Allied team has stolen the Tank"}
        c.actions[4] = {spawn = 6, newstate = PROTECT_ALLIES, trigger = "Allied team has stolen the Tank"}
        c.actions[5] = {spawn = 7, newstate = PROTECT_ALLIES, trigger = "Allied team has stolen the Tank"}
        c.actions[6] = {spawn = 8, newstate = PROTECT_ALLIES, trigger = "Allied team has stolen the Tank"}
        c.actions[7] = {spawn = 3, newstate = NO_PROTECT, trigger = "spawnroof protection disabled"}
        c.actions[8] = {spawn = 13, newstate = PROTECT_ALLIES, trigger = "Allied team has stolen the Tank"}

-- Dubrovnik
    elseif map == "dubrovnik_final" then
        c.spawns[1] = {name = "Convent Up", state = PROTECT_AXIS, pos = {60, 727, 252}, radius2 = 221}
        c.spawns[3] = {name = "Convent Up", state = PROTECT_AXIS, pos = {-611, 727, 228}, radius2 = 221}
        c.spawns[4] = {name = "Convent Down", state = PROTECT_AXIS, pos = {60, 727, 40}, radius2 = 221}
        c.spawns[5] = {name = "Convent Down", state = PROTECT_AXIS, pos = {-611, 727, 40}, radius2 = 221}
        c.spawns[6] = {name = "Convent Yard", state = PROTECT_AXIS, pos = {-12, 1655, 40}, radius2 = 601}
        c.spawns[2] = {name = "East Courtyard", state = PROTECT_ALLIES, pos = {1015, -2146, 40}, radius2 = 300}
        c.spawns[7] = {name = "East Courtyard", state = PROTECT_ALLIES, pos = {1338, -2334, 40}, radius2 = 450}
        c.spawns[8] = {name = "East Courtyard", state = PROTECT_ALLIES, pos = {1933, -2477, 40}, radius2 = 590}
-- Frostbite
    elseif map == "frostbite" then
        c.spawns[1] = {name = "Allied Barracks", state = PROTECT_ALLIES, pos = {-4698, -233, -201}, radius2 = 550}
        c.spawns[2] = {name = "Axis Barracks", state = PROTECT_AXIS, pos = {-134, 1331, 280}, radius2 = 450}
        c.spawns[3] = {name = "Axis Garage", state = PROTECT_AXIS, pos = {-847, 1440, 24}, radius2 = 440}
        c.spawns[4] = {state = NO_PROTECT} -- Upper Complex (Command Post)
        c.spawns[5] = {state = NO_PROTECT} --Axis Spawn (Documents)
        c.actions[1] = {spawn = 3, newstate = NO_PROTECT, trigger = "Allies have transmitted the Supply Documents"}
        
-- ETL Frostbite
    elseif map == "etl_frostbite" then
        c.spawns[1] = {name = "Allied Barracks", state = PROTECT_ALLIES, pos = {-4698, -233, -201}, radius2 = 550}
        c.spawns[2] = {name = "Axis Barracks", state = PROTECT_AXIS, pos = {-140, 1286, 280}, radius2 = 400}
        c.spawns[3] = {name = "Axis Garage", state = PROTECT_AXIS, pos = {-847, 1440, 24}, radius2 = 440}
        c.spawns[4] = {state = NO_PROTECT} -- Upper Complex (Command Post)
        c.spawns[5] = {state = NO_PROTECT} --Axis Spawn (Documents)
        c.actions[1] = {spawn = 3, newstate = NO_PROTECT, trigger = "Allies have transmitted the Supply Documents"}
        
-- ETL Bergen V3 23.10.2018
    elseif map == "etl_bergen_v3" then
        c.spawns[1] = {state = NO_PROTECT} -- Forward Bunker (Flag)
        c.spawns[2] = {name = "Axis Spawn", state = PROTECT_AXIS, pos = {6687, -1149, 216}, radius2 = 270}
        c.spawns[3] = {name = "Allied Spawn", state = PROTECT_ALLIES, pos = {-1231, -2358, 89}, radius2 = 220}
        c.spawns[4] = {name = "Axis Spawn 2", state = PROTECT_AXIS, pos = {6783, -684, 216}, radius2 = 236}
        
-- Northpole 2018-12-11
    elseif map == "northpole" then
        c.spawns[1] = {name = "Axis Spawn", state = PROTECT_AXIS, pos = {-3216, -2753, 827}, radius2 = 900}
        c.spawns[2] = {name = "Town Spawn", state = PROTECT_ALLIES, pos = {2172, -998, 824}, radius2 = 250}
        c.spawns[3] = {name = "Town Spawn", state = PROTECT_ALLIES, pos = {2002, -515, 824}, radius2 = 150}
        c.spawns[4] = {name = "Town Spawn", state = PROTECT_ALLIES, pos = {2357, -473, 824}, radius2 = 200}
        c.spawns[5] = {name = "Town Spawn outside", state = PROTECT_ALLIES, pos = {2697, -431, 827}, radius2 = 150}
        c.spawns[6] = {name = "Town Spawn 2nd floor", state = PROTECT_ALLIES, pos = {2296, -653, 1016}, radius2 = 225}
        
-- Bremen B2 16.11.2008
    elseif map == "bremen_b2" or map == "bremen_b3" or map == "fa_bremen_b3" or map == "fa_bremen_final" then
        c.spawns[1] = {name = "Allied first spawn", state = PROTECT_ALLIES, pos = {-1957, -2222, 88}, radius2 = 440}
        c.spawns[6] = {name = "Allied first spawn*", state = PROTECT_ALLIES, pos = {-2264, -1512, 88}, radius2 = 406}
        c.spawns[2] = {state = NO_PROTECT} -- Axis Flag Spawn
        c.spawns[3] = {name = "Allied Flag", state = NO_PROTECT, pos = {-2517, 1315, 88}, radius2 = 286}
        c.spawns[4] = {name = "Axis Rear I", state = PROTECT_AXIS, pos = {727, -608, 88}, radius2 = 660}
        c.spawns[7] = {name = "Axis Rear II", state = PROTECT_AXIS, pos = {287, 233, 88}, radius2 = 250}
        c.spawns[5] = {state = NO_PROTECT} -- Command Post
        c.actions[1] = {spawn = 3, newstate = PROTECT_ALLIES, trigger = "main gate has been destroyed"}
        c.actions[2] = {spawn = 3, newstate = NO_PROTECT, trigger = "Truck has been repaired"}
-- Venice
    elseif map == "venice" then
        c.spawns[1] = {name = "Allies", state = PROTECT_ALLIES, pos = {-4067, -1001, -103}, radius2 = 850}
        c.spawns[2] = {name = "Outpost", state = PROTECT_AXIS, pos = {517, 1286, -135}, radius2 = 381} --Axis/Allies
        c.spawns[3] = {name = "Axis", state = PROTECT_AXIS, pos = {4859, 1708, -199}, radius2 = 500}
        c.actions[1] = {spawn = 2, newstate = PROTECT_ALLIES, trigger = "captured the Outpost"}
-- Venice TC RC2
    elseif map == "venice_tcrc2_v1" then
        c.spawns[1] = {name = "Allied", state = PROTECT_ALLIES, pos = {-2464, -1202, -213}, radius2 = 483}
        c.spawns[2] = {name = "Outpost", state = PROTECT_AXIS, pos = {517, 1286, -135}, radius2 = 381} --Axis/Allies
        c.spawns[3] = {name = "Axis Spawn North", state = PROTECT_AXIS, pos = {4859, 1708, -199}, radius2 = 500}
        c.spawns[4] = {name = "Axis Spawn South", state = PROTECT_AXIS, pos = {2544, -2784, -215}, radius2 = 800}
        c.actions[1] = {spawn = 2, newstate = PROTECT_ALLIES, trigger = "captured the Outpost"}
-- Reactor
    elseif map == "reactor_final" then
        c.spawns[1] = {name = "Forward Bunker", state = NO_PROTECT, pos = {96, -551, 280}, radius2 = 430}
        c.spawns[2] = {name = "Head Quarters", state = PROTECT_AXIS, pos = {-283, 1415, 216}, radius2 = 320} --Axis
        c.spawns[6] = {name = "Head Quarters", state = PROTECT_AXIS, pos = {292, 1341, 280}, radius2 = 278} --Axis
        c.spawns[3] = {name = "Caves", state = PROTECT_ALLIES, pos = {1668, -3100, 616}, radius2 = 240}
        c.spawns[4] = {name = "Caves", state = PROTECT_ALLIES, pos = {1150, -3128, 456}, radius2 = 200}
        c.actions[1] = {spawn = 1, newstate = PROTECT_ALLIES, trigger = "secured the forward bunker"}
-- Supply 16.11.2008
    elseif map == "supply" then
        c.spawns[1] = {name = "Allied start", state = PROTECT_ALLIES, pos = {-2050, 131, 0}, radius2 = 540}
        c.spawns[3] = {name = "Forward", state = NO_PROTECT, pos = {-283, 2391, 264}, radius2 = 220}
        c.spawns[4] = {state = NO_PROTECT} --Command Post Spawn
        c.spawns[2] = {name = "Axis Depot", state = PROTECT_AXIS, pos = {650, -1810, -135}, radius2 = 330}
        c.spawns[7] = {name = "Axis Depot Stairs", state = PROTECT_AXIS, pos = {719, -1487, -31}, radius2 = 150}
        c.spawns[5] = {name = "Axis Depot Back Exit", state = PROTECT_AXIS, pos = {771, -2629, -47}, radius2 = 260}
        c.spawns[6] = {name = "Axis Depot Tunnel", state = PROTECT_AXIS, pos = {890, -2270, -147}, radius2 = 260}
        c.actions[1] = {spawn = 3, newstate = PROTECT_ALLIES, trigger = "breached the Forward Bunker"}
    elseif map == "etl_supply" then
        c.spawns[1] = {name = "Allied start", state = PROTECT_ALLIES, pos = {-2050, 131, 0}, radius2 = 540}
        c.spawns[3] = {name = "Forward", state = NO_PROTECT, pos = {-283, 2391, 264}, radius2 = 220}
        c.spawns[4] = {state = NO_PROTECT} --Command Post Spawn
        c.spawns[2] = {name = "Axis Depot", state = PROTECT_AXIS, pos = {650, -1810, -135}, radius2 = 330}
        c.spawns[7] = {name = "Axis Depot Stairs", state = PROTECT_AXIS, pos = {719, -1487, -31}, radius2 = 150}
        c.spawns[5] = {name = "Axis Depot Back Exit", state = PROTECT_AXIS, pos = {771, -2629, -47}, radius2 = 260}
        c.spawns[6] = {name = "Axis Depot Tunnel", state = PROTECT_AXIS, pos = {890, -2270, -147}, radius2 = 260}
        c.actions[1] = {spawn = 3, newstate = PROTECT_ALLIES, trigger = "breached the Forward Bunker"}
-- Supply Pro 23.10.2018
    elseif map == "supply_pro" then
        c.spawns[1] = {name = "Farmhouse", state = PROTECT_ALLIES, pos = {-2175, -210, 24}, radius2 = 221}
        c.spawns[5] = {name = "Farmhouse Exit", state = PROTECT_ALLIES, pos = {-2175, 140, 24}, radius2 = 221}
        c.spawns[3] = {name = "Forward Bunker Spawn", state = NO_PROTECT, pos = {-271, 2367, 264}, radius2 = 170}
        c.spawns[4] = {state = NO_PROTECT} --Command Post Spawn
        c.spawns[2] = {name = "Axis Depot Spawn", state = PROTECT_AXIS, pos = {650, -1789, -165}, radius2 = 210}
        c.spawns[8] = {name = "Axis Depot Stairs", state = PROTECT_AXIS, pos = {719, -1487, -31}, radius2 = 150}
        c.spawns[6] = {name = "Axis Depot Spawn Back Exit", state = PROTECT_AXIS, pos = {771, -2629, -47}, radius2 = 220}
        c.spawns[7] = {name = "Axis Depot Spawn Tunnel", state = PROTECT_AXIS, pos = {890, -2270, -147}, radius2 = 260}
        c.actions[1] = {spawn = 3, newstate = PROTECT_ALLIES, trigger = "breached the Forward Bunker"}
        
                
-- missile_b3
    elseif map == "missile_b3" then
		        c.spawns[1] = {name = "Gate Control Spawn", state = PROTECT_AXIS, pos = {3750, -4823, 80}, radius2 = 400}
		        c.spawns[3] = {name = "Bunker Spawn", state = PROTECT_ALLIES, radius2 = 700}
		        c.spawns[5] = {name = "Rocket Hall Spawn", state = PROTECT_AXIS, radius2 = 600}
		        c.spawns[6] = {name = "Rocket Gate Spawn", state = NO_PROTECT, radius2 = 450}
				c.actions[1] = {spawn = 1, newstate = NO_PROTECT, trigger = "Magnetic seal deactivated"}
				--c.actions[2] = {spawn = 6, newstate = PROTECT_ALLIES, trigger = "Allies have activated the Gate Controls"}
    elseif map == "missile_b4" then
		        c.spawns[1] = {name = "Gate Control Spawn", state = PROTECT_AXIS, pos = {4119, -4408, 353}, radius2 = 500}
		        c.spawns[3] = {name = "Bunker Spawn", state = PROTECT_ALLIES, radius2 = 700}
		        c.spawns[5] = {name = "Rocket Hall Spawn", state = PROTECT_AXIS, radius2 = 560}
		        c.spawns[6] = {name = "Rocket Gate Spawn", state = NO_PROTECT, radius2 = 450}
				c.actions[1] = {spawn = 1, newstate = NO_PROTECT, trigger = "Magnetic seal deactivated"}
				--c.actions[2] = {spawn = 6, newstate = PROTECT_ALLIES, trigger = "Allies have activated the Gate Controls"}

				
    elseif map == "transmitter" then
		        c.spawns[3] = {name = "Allied Base", state = PROTECT_ALLIES, radius2 = 1000}
		        c.spawns[2] = {name = "Castle", state = PROTECT_AXIS, radius2 = 400}
-- 1944_beach
    elseif map == "1944_beach" then
        c.spawns[1] = {name = "Axis Spawn", state = PROTECT_AXIS, pos = {3254, -4882, 5384}, radius2 = 500}
        c.spawns[2] = {name = "Forward Spawn", state = NO_PROTECT}
        c.spawns[3] = {name = "Allies Spawn", state = PROTECT_ALLIES, pos = {310, 1984, 4512}, radius2 = 180}
        c.spawns[4] = {name = "Allies Spawn", state = PROTECT_ALLIES, pos = {310, 1884, 4512}, radius2 = 200}
        c.spawns[5] = {name = "Allies Spawn", state = PROTECT_ALLIES, pos = {310, 1684, 4512}, radius2 = 200}
        c.spawns[6] = {name = "Allies Spawn", state = PROTECT_ALLIES, pos = {310, 1584, 4512}, radius2 = 200}
        c.spawns[7] = {name = "Allies Spawn", state = PROTECT_ALLIES, pos = {333, 1457, 4512}, radius2 = 200}
        c.spawns[8] = {name = "Allies Spawn", state = PROTECT_ALLIES, pos = {328, 1211, 4512}, radius2 = 300}
        c.spawns[9] = {name = "Transmitter Spawn", state = NO_PROTECT}
        c.spawns[10] = {name = "Allies Spawn 2", state = PROTECT_ALLIES, pos = {-2193, 1014, 4472}, radius2 = 100}
        c.spawns[11] = {name = "Allies Spawn 2", state = PROTECT_ALLIES, pos = {-2202, 689, 4512}, radius2 = 200}
        c.spawns[12] = {name = "Allies Spawn 2", state = PROTECT_ALLIES, pos = {-2197, 513, 4512}, radius2 = 200}
        c.spawns[13] = {name = "Allies Spawn 2", state = PROTECT_ALLIES, pos = {-2209, 193, 4516}, radius2 = 300}

-- decay_b7
    elseif map == "decay_b7" then
        c.spawns[1] = {name = "Forward Flag", state = NO_PROTECT, pos = {-415, 800, 348}, radius2 = 290}
        c.spawns[2] = {name = "Axis Garrison", state = PROTECT_AXIS, pos = {2956, 3997, 319}, radius2 = 500}
        c.spawns[3] = {name = "Side Entrance", state = NO_PROTECT}
        c.spawns[4] = {name = "Allied Camp", state = PROTECT_ALLIES, pos = {3590, -19, 64}, radius2 = 700}
        c.spawns[5] = {name = "Allied Camp", state = PROTECT_ALLIES, pos = {3722, -709, 64}, radius2 = 700}
        c.spawns[6] = {name = "Allied Camp", state = PROTECT_ALLIES, pos = {3613, 562, 64}, radius2 = 800}
        c.spawns[7] = {name = "Locker Room", state = NO_PROTECT, pos = {-383, 2282, 327}, radius2 = 240}
        c.actions[1] = {spawn = 1, newstate = PROTECT_ALLIES, trigger = "Allies have permanently secured the"}
        c.actions[2] = {spawn = 7, newstate = PROTECT_ALLIES, trigger = "The Allies have destroyed the generator, the vault"}
-- library_b3
    elseif map == "library_b3" then
        c.spawns[1] = {name = "Allied First Spawn", state = PROTECT_ALLIES, pos = {-2202, -3267, -15}, radius2 = 500}
        c.spawns[2] = {name = "Axis Spawn", state = PROTECT_AXIS, pos = {-582, 3303, -115}, radius2 = 400}
        c.spawns[3] = {name = "Library Office Spawn", state = PROTECT_AXIS, pos = {-96, 3971, -75}, radius2 = 260}

-- ET Ice
    elseif map == "et_ice" then
        c.spawns[1] = {name = "Axis North Barracks", state = PROTECT_AXIS, radius2 = 360}
        c.spawns[2] = {name = "Axis South Barracks", state = PROTECT_AXIS, radius2 = 360}
        c.spawns[3] = {name = "Allies North Barracks", state = PROTECT_ALLIES}
        c.spawns[4] = {name = "Allies South Barracks", state = PROTECT_ALLIES} --Transmitter
-- Heart of Gold
    elseif map == "hog_b12_dt" then
        c.spawns[2] = {state = NO_PROTECT} --Gate
        c.spawns[3] = {name = "Village", state = PROTECT_AXIS, radius1 = 150, radius2 = 440}
        c.spawns[5] = {name = "Village", state = PROTECT_AXIS, pos = {-4, 703, 300}, radius2 = 220}
        c.spawns[6] = {name = "Village", state = PROTECT_AXIS, pos = {610, 112, 350}, radius2 = 235}
        c.spawns[1] = {name = "Garage", state = PROTECT_ALLIES, pos = {-4943, -77, 0}, radius2 = 780}
        c.spawns[4] = {state = NO_PROTECT} --Command Post Spawn
-- ET Beach
    elseif map == "et_beach" then
        c.spawns[1] = {name = "Axis Side", state = PROTECT_AXIS, pos = {2541, 3217, 1176}, radius2 = 301}
--      c.spawns[1] = {name = "Axis Side", state = PROTECT_AXIS, pos = {2548, 3116, 1176}, radius2 = 360}
        c.spawns[2] = {state = NO_PROTECT} -- Axis Side (unten)
        c.spawns[3] = {name = "Forward Bunker", state = NO_PROTECT, pos = {1333, 3455, 680}, radius2 = 140} -- Forward Bunker
        c.spawns[4] = {name = "Allied Side", state = PROTECT_ALLIES, pos = {-1872, 3504, 97}, radius2 = 600}
        c.spawns[5] = {name = "Supply Bunker", state = NO_PROTECT} -- Command Post Spawn Supply Bunker
        c.spawns[6] = {name = "Supply Bunker", state = NO_PROTECT} -- Bed Room Spawn
        c.spawns[7] = {state = NO_PROTECT} -- Seawall Breach
        c.spawns[8] = {name = "Allied Side", state = PROTECT_ALLIES, pos = {-1799, -2651, 296}, radius2 = 300}
        c.actions[1] = {spawn = 3, newstate = PROTECT_ALLIES, trigger = "Allies secured the Forward Bunker"}
-- TC Base
    elseif map == "tc_base" then
        c.spawns[1] = {name = "Allies", state = PROTECT_ALLIES, radius2 = 850, radius2 = 1000}
        c.spawns[2] = {name = "Axis", state = PROTECT_AXIS, pos = {3229, 2111, 100}, radius2 = 900}
-- SP Delivery TE 16.11.2008
    elseif map == "sp_delivery_te" then
        c.spawns[1] = {name = "Forward Bunker", state = NO_PROTECT, radius2 = 350} -- flag
        c.spawns[2] = {name = "The Offices", state = PROTECT_AXIS, radius2 = 850} --axis
        c.spawns[3] = {name = "The Train Cars", state = PROTECT_ALLIES, radius2 = 1550}
        c.actions[1] = {spawn = 1, newstate = PROTECT_ALLIES, trigger = "secured the forward bunker"}
-- Warbell
    elseif map == "warbell" then
        c.spawns[1] = {name = "Monastery", state = PROTECT_ALLIES, pos = {2370, -2058, 24}, radius2 = 165}
        c.spawns[5] = {name = "Monastery", state = PROTECT_ALLIES, pos = {2623, -2005, 24}, radius2 = 185}
        c.spawns[2] = {name = "Axis Start", state = PROTECT_AXIS, radius2 = 1000} --axis
        c.spawns[3] = {name = "Command Post", state = NO_PROTECT}
        c.spawns[4] = {name = "Guard House", state = NO_PROTECT, radius2 = 350}
        c.actions[1] = {spawn = 4, newstate = PROTECT_AXIS, trigger = "secured the Guardhouse Flag"}
-- etl_warbell
    elseif map == "etl_warbell" then
        c.spawns[1] = {name = "Monastery", state = PROTECT_ALLIES, pos = {2370, -2058, 24}, radius2 = 380}
        c.spawns[5] = {name = "Monastery", state = PROTECT_ALLIES, pos = {2623, -2005, 24}, radius2 = 185}
        c.spawns[2] = {name = "Axis Spawn", state = PROTECT_AXIS, pos = {960, 2064, 416}, radius2 = 900}
        c.spawns[3] = {name = "Command Post", state = NO_PROTECT}
        c.spawns[4] = {name = "Guard House", state = NO_PROTECT, pos = {-2742, -148, 512}, radius2 = 350}
        c.actions[1] = {spawn = 4, newstate = PROTECT_AXIS, trigger = "have destroyed the Guardhouse Gate"}
-- TroopTrain
    elseif map == "trooptrain" then
        c.spawns[1] = {state = NO_PROTECT}
        c.spawns[2] = {state = NO_PROTECT}
        c.spawns[3] = {state = NO_PROTECT}
-- vengeance_te_final
    elseif map == "vengeance_te_final" then
        c.spawns[6] = {name = "East Spawn", state = PROTECT_AXIS, radius2 = 280} --axis
        c.spawns[3] = {name = "West Spawn", state = PROTECT_AXIS, radius2 = 240} --axis
        c.spawns[2] = {name = "Allied Spawn", state = PROTECT_ALLIES, radius2 = 300}
        c.spawns[1] = {name = "Forward Spawn", state = NO_PROTECT, pos = {973, -704, 128}, radius2 = 185} --Flag Spawn
        c.spawns[7] = {name = "Forward Spawn", state = NO_PROTECT, pos = {1245, -704, 128}, radius2 = 185} --Flag Spawn
        c.spawns[4] = {name = "Allied CP", state = NO_PROTECT}
        c.spawns[5] = {name = "Axis CP", state = NO_PROTECT}
        c.actions[1] = {spawn = 1, newstate = PROTECT_AXIS, trigger = "breached the bunker door"}
        c.actions[2] = {spawn = 7, newstate = PROTECT_AXIS, trigger = "breached the bunker door"}
-- apennines_b2
    elseif map == "apennines_b2" then
        c.spawns[1] = {name = "Desert Cabin", state = NO_PROTECT}
        c.spawns[2] = {name = "Research Complex", state = NO_PROTECT}
        c.spawns[3] = {name = "Garage Spawn", state = NO_PROTECT}
-- italyfp2
    elseif map == "italyfp2" then
        c.spawns[3] = {name = "Axis Spawn", pos = {1018, 3096, 98}, state = PROTECT_AXIS, radius2 = 350} --axis
        c.spawns[6] = {name = "Allied CP Spawn", pos = {-1050, -2125, -290}, state = PROTECT_ALLIES, radius2 = 440}
-- italyfp2
    elseif map == "italyfp2" then
        c.spawns[3] = {name = "Axis Spawn", pos = {1018, 3096, 98}, state = PROTECT_AXIS, radius2 = 350} --axis
        c.spawns[6] = {name = "Allied CP Spawn", pos = {-1050, -2125, -290}, state = PROTECT_ALLIES, radius2 = 440}
        
-- v2base_te 17.06.2019
    elseif map == "v2base_te" then
        c.spawns[1] = {name = "Axis Spawn", pos = {-2467, 1427, -215}, state = PROTECT_AXIS, radius2 = 295} --axis
        c.spawns[2] = {name = "Allies Spawn", pos = {-2047, -1995, 92}, state = PROTECT_ALLIES, radius2 = 200} --allies
        c.spawns[3] = {state = NO_PROTECT}
        c.spawns[4] = {name = "Allies Spawn", pos = {-2047, -1771, 92}, state = PROTECT_ALLIES, radius2 = 200} --allies

-- sos_secret_weapon
    elseif map == "sos_secret_weapon" then
        c.spawns[1] = {state = "Allies Spawn", pos = {2270, -2214, 68}, state = PROTECT_ALLIES, radius2 = 600}
        c.spawns[2] = {state = NO_PROTECT}
        c.spawns[3] = {state = "Axis Spawn", pos = {-1847, 2307, 68}, state = PROTECT_AXIS, radius2 = 500}

-- pirates
    elseif map == "pirates" then
        c.spawns[1] = {state = "Old City", state = NO_PROTECT}
        c.spawns[2] = {state = "Seaport", state = PROTECT_AXIS, radius2 = 450}
        c.spawns[3] = {name = "Beach Spawn", state = PROTECT_ALLIES, radius2 = 430}
        c.spawns[4] = {name = "Courtyard", state = NO_PROTECT}

-- eagles_2ways_b3
    elseif map == "eagles_2ways_b3" then
        c.spawns[1] = {state = "Axis 2", pos = {-4363, -2043, 2208}, state = PROTECT_AXIS, radius2 = 500}
        c.spawns[2] = {state = "Allied 3", state = NO_PROTECT, pos = {-3506, -2322, 1776}, radius2 = 450}
		c.actions[1] = {spawn = 2, newstate = PROTECT_ALLIES, trigger = "Allied 3"}

-- marketgarden_et_r2
    elseif map == "marketgarden_et_r2" then
        c.spawns[1] = {state = "The Bridge", state = NO_PROTECT}
        c.spawns[2] = {state = "Command Center", state = NO_PROTECT}
        c.spawns[3] = {state = "Banner Room", pos = {-5068, 712, 1112}, state = PROTECT_ALLIES, radius2 = 400}
        c.spawns[4] = {state = "South Arch", pos = {2137, -2488, 1104}, state = PROTECT_AXIS, radius2 = 400}

-- falkenstein_b3
    elseif map == "falkenstein_b3" then
        c.spawns[1] = {state = "Station Spawns", pos = {3217, -1241, 112}, state = PROTECT_AXIS, radius2 = 400}
        c.spawns[2] = {state = "Base Spawns", pos = {7476, -3911, 352}, state = PROTECT_AXIS, radius2 = 400}
        c.spawns[3] = {state = "Allied Spawn One", pos = {2263, -4409, 833}, state = PROTECT_ALLIES, radius2 = 600}
        c.actions[1] = {spawn = 1, newstate = PROTECT_ALLIES, trigger = "Allies gained access to the base"}

-- goldendunk_a2
    elseif map == "goldendunk_a2" then
        c.spawns[1] = {name = "Axis Spawn1", pos = {-2370, 750, 60}, state = PROTECT_AXIS, radius2 = 250} 
	 c.spawns[2] = {name = "Axis Spawn2", pos = {-2370, -750, 60}, state = PROTECT_AXIS, radius2 = 250} 
        c.spawns[3] = {name = "Allied Spawn1", pos = {2370, 750, 60}, state = PROTECT_ALLIES, radius2 = 250}
	 c.spawns[4] = {name = "Allied Spawn2", pos = {2370, -750, 60}, state = PROTECT_ALLIES, radius2 = 250}


    else hasconfig = false
    end
    return c
end


--------------------------------------------------------------------------------
-- called when client types a command like "/command" on console
function et_ClientCommand(cno, command)
--------------------------------------------------------------------------------
-- commands:
--     etwsk        : prints mod info and current spawnkill statistics
--     etwsk_spawns : prints list of spawnpoints with current state
--     etwsk_pos    : prints current position and distances to protected spawns
--------------------------------------------------------------------------------
    local cmd = string.lower(command)
    if cmd == "etwsk_spawns" then
        printSpawns(cno)
        return 1
    elseif cmd == "etwsk_pos" then
        printPos(cno)
        return 1
    elseif cmd == "etwsk" then
        printStats(cno)
        return 1
    elseif cmd == "team" and sinbin and sinbinhash[cno] then -- spam...
        if sinbinhash[cno] > et.trap_Milliseconds() then
            local team = et.Info_ValueForKey(  et.trap_GetConfigstring(et.CS_PLAYERS + cno), "t" )
            local penalty_left =  math.ceil( ( sinbinhash[cno] - et.trap_Milliseconds() ) / 1000 )
            et.trap_SendServerCommand( cno,
                sinbin_pos .. " \"^3ATTENTION: ^7You may not join a team for another ^1"..penalty_left.." ^7seconds^1!\"\n")
            return 1
        else
            sinbinhash[cno] = nil --reset
            return 0
        end
        return 1
    end
    return 0
end


--------------------------------------------------------------------------------
-- calculates the distance
-- note: not true distance as hight is doubled. So the body defined by constant
--       distance is not a sphere, but an ellipsoid
function calcDist(pos1, pos2)
--------------------------------------------------------------------------------
    local dist2 = (pos1[1]-pos2[1])^2 + (pos1[2]-pos2[2])^2
                  + ((pos1[3]-pos2[3])*2)^2
    return math.sqrt(dist2)
end

--------------------------------------------------------------------------------
-- called at map start
function et_InitGame( levelTime, randomSeed, restart)
--------------------------------------------------------------------------------
    local modname = string.format("%s v%s", module_name, module_version)
    et.G_Print(string.format("%s loaded\n", modname))
    et.RegisterModname(modname)

    mapname = et.trap_Cvar_Get("mapname")
    c = getConfig(mapname)

    damagegiven = {}
    spawnkills = {}

    local checkpoints = {}
    -- find capturable flag poles
    for i = 64, 1021 do
        if et.gentity_get(i, "classname") == "team_WOLF_checkpoint" then
            table.insert(checkpoints,i)
        end
    end
    -- complete config with default extracted values
    local spawn = 1
    for i = 64, 1021 do
        if et.gentity_get(i, "classname") == "team_WOLF_objective" then
        local pos = et.gentity_get(i, "origin");
            if c.spawns[spawn] == nil then
            c.spawns[spawn] = {} end
        if c.spawns[spawn].name == nil then
            c.spawns[spawn].name = et.gentity_get(i, "message") end
        if c.spawns[spawn].pos == nil then
            c.spawns[spawn].pos = et.gentity_get(i, "origin") end
        if c.spawns[spawn].state == nil then
            local iscapturable = false
            for k,v in pairs(checkpoints) do
                        local cp = et.gentity_get(v, "origin")
                if(calcDist(c.spawns[spawn].pos, cp) <=
                  maxcheckpointdist) then
                    iscapturable = true
                end
            end
            if iscapturable then
                c.spawns[spawn].state = NO_PROTECT
            else
                c.spawns[spawn].state = et.G_GetSpawnVar(i, "spawnflags")
            end
        end
        if c.spawns[spawn].radius1 == nil then
            c.spawns[spawn].radius1 = ETWsk_defaultradius1 end
        if c.spawns[spawn].radius2 == nil then
            c.spawns[spawn].radius2 = ETWsk_defaultradius2 end
        spawn = spawn + 1
        end
    end
    -- auto complete spawns
    for i,spawn in pairs(c.spawns) do
    if spawn.radius1 == nil then
        spawn.radius1 = ETWsk_defaultradius1 end
    if spawn.radius2 == nil then
        spawn.radius2 = ETWsk_defaultradius2 end
    end

    readPO(ETWsk_pofile)
end

--------------------------------------------------------------------------------
-- called when something is printed on server console
function et_Print(text)
--------------------------------------------------------------------------------
    if(c == nil) then return end
    for i,action in pairs(c.actions) do
        if(string.find(text, action.trigger)) then
            local msg
            if action.newstate == NO_PROTECT then
                msg = "is no longer protected!"
            else msg = "is now protected!"
            end
    c.spawns[action.spawn].state = action.newstate
            et.trap_SendServerCommand(-1, "chat \"^3ATTENTION: ^1The "..
                c.spawns[action.spawn].name.." "..msg.."\n\"")
--            et.trap_SendServerCommand(-1, "chat \"^3ATTENTION: ^1The ^4"..
--              c.spawns[action.spawn].name.." Spawn ^2"..msg.."\n\"")

        end
    end
end

--------------------------------------------------------------------------------
-- called when client enters the game
function et_ClientBegin(cno)
--------------------------------------------------------------------------------
    -- reset spawnkills
    spawnkills[cno] = nil
end

--------------------------------------------------------------------------------
-- called when client spawns
function et_ClientSpawn(cno, revived )
--------------------------------------------------------------------------------
    if (hasconfig and revived == 0) then
        damagegiven[cno] = et.gentity_get(cno, "sess.damage_given")
        if(damagegiven[cno] == nil) then damagegiven[cno] = 0 end
    end
end

--------------------------------------------------------------------------------
function et_ClientDisconnect( cno )
--------------------------------------------------------------------------------
    if sinbinhash[cno] then
        sinbinhash[cno] = nil -- reset
    end
end

--------------------------------------------------------------------------------
function printSpawns(cno)
--------------------------------------------------------------------------------
    if not hasconfig then
        et.trap_SendServerCommand(cno,
            "print \"^3ATTENTION:^7 no config for this map!\n\"")
        if ETWsk_savemode == 1 then
            et.trap_SendServerCommand(cno,
                "print \"^3ATTENTION: ^7 protection deactivated (savemode)!\n\"")
        end
    end
    local protect = {}
    protect[0] = "NO_PROTECT"
    protect[1] = "^1PROTECT_AXIS"
    protect[2] = "^4PROTECT_ALLIES"
    if cno >= 0 then
        et.trap_SendServerCommand(cno,"chat \"^3ATTENTION:^7 Mapname: ^3"..mapname.."\n\"")
    end
    for i,spawn in pairs(c.spawns) do
        if cno == -1 then et.G_Print("ETWsk> Spawn %d \"%s\" %s \n", i, spawn.name, protect[spawn.state])
        else et.trap_SendServerCommand(cno, "chat \"^3ATTENTION:^7 Spawn ^3"..i.."^7 "..spawn.name.." "..protect[spawn.state].."\n\"")
        end
    end
end

--------------------------------------------------------------------------------
function printPos(cno)
--------------------------------------------------------------------------------
    local pos = et.gentity_get(cno, "r.currentOrigin")
    local spos = string.format('%.2f, %.2f, %.2f',
        table.unpack(pos))
    et.trap_SendServerCommand(cno,
        "print \"^3ATTENTION:^7 current pos: "..spos.."\n\"")
    local team = et.gentity_get(cno, "sess.sessionTeam")
    local protect_normal = "^2protected_normal"
    local protect_heavy = "^2protected_heavy_only"
    for i,spawn in pairs(c.spawns) do
    local protect = "^1not protected"
        if spawn.state == team then
            local dist = calcDist(pos, spawn.pos)
            if dist < spawn.radius1 then
                protect = protect_normal
            elseif dist < spawn.radius2 then
                protect = protect_heavy
            end
            et.trap_SendServerCommand(cno, string.format(
                "print \"^3ATTENTION:^7 spawn ^3%d (%s): %s ^7distance: %.2f \n\"",
                i, spawn.name, protect, dist))
        end
    end
end

--------------------------------------------------------------------------------
function printStats(cno)
--------------------------------------------------------------------------------
    et.trap_SendServerCommand(cno, "print \"^3ATTENTION: ^7v"..module_version ..
        " spawnkill protection by ^2[^4ETW^2-^4FZ^2] ^4Mad^2@^4Mat^7.\n\"")
    for killer,kills in pairs(spawnkills) do
        local killername =
            et.Info_ValueForKey(et.trap_GetUserinfo(killer), "name")
        et.trap_SendServerCommand(cno,
        "print \"       "..kills.." SKs: "..killername.."\n\"")
    end
end

--------------------------------------------------------------------------------
-- called when someone has been killed
function et_Obituary(victim, killer, meansOfDeath)
--------------------------------------------------------------------------------
    -- same team
    -- et.trap_SendServerCommand(-1, "print \"SK: "..victim.." "..killer.."\n\"")
    -- warmup fix, n00b! benny
    if tonumber(et.trap_Cvar_Get("gamestate")) ~= 0 then return end

    local vteam = et.gentity_get(victim, "sess.sessionTeam")

    -- IlDuca - fix: check if the killer is a real player or if it's something else...
    if ( et.gentity_get( killer, "s.number" ) < tonumber( et.trap_Cvar_Get( "sv_maxClients" )) ) then
        if( vteam == et.gentity_get(killer, "sess.sessionTeam")) then
            return
        end
    else
        return
    end

    -- protection expired ?
    if ETWsk_expires == 1 then
    local vdg = 0
    vdg = et.gentity_get(victim, "sess.damage_given")
           -- et.G_Printf("vdg = %d, dg = %d\n", vdg, damagegiven[victim])
           if(vdg ~= nil and vdg > damagegiven[victim]) then return end
    end
    -- was heavyweapon?
    local isheavy = false
    for k,v in pairs(heavyweapons) do
        if (meansOfDeath == v) then isheavy = true end
    end
    -- protected spawn?
    local vpos = et.gentity_get(victim, "r.currentOrigin")
    local isprotected = false
    local dist2
    local radius2
    for i,spawn in pairs(c.spawns) do
        if spawn.state == vteam then
            if(isheavy) then
                radius2 = spawn.radius2
            else
                radius2 = spawn.radius1
            end
            dist = calcDist(vpos, spawn.pos)
            if(dist < radius2) then
                ClientSpawnkill(victim, killer, isheavy)
            end
        end
    end
end

--------------------------------------------------------------------------------
-- called when ETWsk has detected a spawnkill
function ClientSpawnkill(victim, killer, isheavy)
--------------------------------------------------------------------------------
    if killer < 0 or (ETWsk_savemode == 1 and not hasconfig) then return end

    local killername = et.Info_ValueForKey(et.trap_GetUserinfo(killer), "name")

    if spawnkills[killer] == nil then spawnkills[killer] = 0 end

    spawnkills[killer] = spawnkills[killer] + 1
    local numsk = spawnkills[killer]

    -- he has been kicked before
    if numsk >= ETWsk_POThreshold then
        local kicksb4 = isPO(killer)

        if kicksb4 > 0 then
            et.trap_DropClient(killer, "temp ban - "..kicksb4.." former kicks for spawn killing!", (ETWsk_banval * math.pow(1,kicksb4)))
            et.trap_SendServerCommand(-1, "chat \"^3ATTENTION: ^7"..killername..
                " ^2has been temp banned - repeated spawn killing!\"\n")
            spawnkills[killer] = nil
            addPO (killer)
            savePO(ETWsk_pofile)
            return
        end
    end

    et.trap_SendServerCommand(-1, "chat \"^3ATTENTION: ^1WARNING: ^2Spawn kill (#"..
        numsk..") by ^7"..killername.."\"\n" )
    et.trap_SendServerCommand(killer, "cp \""..killername.." : ^1DO NOT SPAWN KILL!!! \"\n")

    if(numsk >= ETWsk_putspec and numsk < ETWsk_kick) then
        et.trap_SendConsoleCommand(et.EXEC_APPEND, putspec(killer))
        sinbinhash[killer] = et.trap_Milliseconds() + sinbin_duration
        et.trap_SendServerCommand(-1, "chat \"^3ATTENTION: ^7"..killername..
            " ^2was set to Spectators - too many Spawnkills!\"\n")
        et.trap_SendServerCommand( killer,
            "bp \"^3ATTENTION: ^1WARNING: ^2You were set to Spectator \"\n")
    elseif(numsk == ETWsk_kick) then
        et.trap_DropClient(killer, "too many spawn kills!", ETWsk_kicklen)
        et.trap_SendServerCommand(-1, "chat \"^3ATTENTION: ^7"..killername..
            " ^2has been kicked - too many spawn kills!\"\n")
        addPO(killer)
        savePO(ETWsk_pofile)
    elseif(numsk > ETWsk_kick) then
        -- do nothing you dumb shit
    else
        et.gentity_set(killer, "health", -511)
    end

end

--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- persistent offenders stuff
function isPO (cno)
    local guid = string.lower(et.Info_ValueForKey(et.trap_GetUserinfo(cno), "cl_guid"))
    if pohash[guid] then
        return pohash[guid]
    end
    return 0
end

function addPO (cno) -- unreliable shit
    local guid = string.lower(et.Info_ValueForKey(et.trap_GetUserinfo(cno), "cl_guid"))
    if string.find(guid, "[^%x]") or string.len(guid) ~= 32 then return end
    if pohash[guid] then
        pohash[guid] = pohash[guid] + 1
    else
        pohash[guid] = 1
    end
end

function readPO (file)
	local fd,len = et.trap_FS_FOpenFile( file, et.FS_READ )
	local count = 0
	if len > -1 then
		local filestr = et.trap_FS_Read(fd, len)
		for guid, kicks in string.gmatch(filestr,"[^%#](%x+)%s(%d+)%;") do
			if not string.find(guid, "[^%x]") and string.len(guid) == 32 then
				pohash[string.lower(guid)] = tonumber(kicks)
				count = count + 1
			end
		end
		filestr = nil
		et.trap_FS_FCloseFile(fd)
	else
		et.G_LogPrint("ETWsk failed to open " .. file .. "\n")
		return
	end
    et.G_LogPrint("ETWsk loaded "..count.." persistent spawn killers.\n")
end

function savePO (file)
    local count = 0
    local fd, len = et.trap_FS_FOpenFile(file, et.FS_WRITE)
    if len == -1 then
        et.G_LogPrint("ETWsk failed to open " .. file .. "\n")
        return(0)
    end
    local head = string.format(
        "# %s, written %s\n# to reload this file do a 'etwskread' via rcon/screen!\n",
        file, os.date()
    )
    et.trap_FS_Write(head, string.len(head), fd)
    for guid, kicks in pairs(pohash) do
        local line = guid.." "..kicks..";\n"
        et.trap_FS_Write(line, string.len(line), fd)
        count = count + 1
    end
    et.trap_FS_FCloseFile(fd)
    et.G_LogPrint("ETWsk saved "..count.." persistent spawn killers.\n")
end
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- et_ShutdownGame
function et_ShutdownGame( restart )
--------------------------------------------------------------------------------
    savePO(ETWsk_pofile)
end



--------------------------------------------------------------------------------
-- et_ConsoleCommand
function et_ConsoleCommand()
--------------------------------------------------------------------------------
    if et.trap_Argv(0) == "etwskread" then
        pohash = {}
        readPO(ETWsk_pofile)
        return 1
    end
    return 0
end
