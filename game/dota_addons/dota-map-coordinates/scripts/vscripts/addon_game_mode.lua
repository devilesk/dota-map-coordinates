require("libraries/util")
require("libraries/json")
require("libraries/timers")
require("libraries/list")

if GameMode == nil then
	GameMode = class({})
end

function Precache( context )
end

-- Create the game mode when we activate
function Activate()
	GameRules.AddonTemplate = GameMode()
	GameRules.AddonTemplate:InitGameMode()
end

function round(num, idp)
  local mult = 10^(idp or 0)
  return math.floor(num * mult + 0.5) / mult
end

function v2c(v)
    return {
        x = round(v.x),
        y = round(v.y)
    }
end

function DumpCoordinateData()
    local keys = {
        "trigger_multiple",
        "npc_dota_tower",
        "npc_dota_healer",
        "npc_dota_roshan_spawner",
        "dota_item_rune_spawner_powerup",
        "dota_item_rune_spawner_bounty",
        "ent_dota_shop",
        "ent_dota_tree",
        "npc_dota_barracks",
        "npc_dota_filler",
        "npc_dota_fort",
        "npc_dota_tower"
    }
    
    -- mapping to rename keys to what the app consuming the json data uses
    local schema = {
        dota_item_rune_spawner_powerup = "dota_item_rune_spawner",
        npc_dota_filler = "npc_dota_building",
    }
    
    local data = {}
    
    for k, v in pairs(keys) do
        print(v)
        data[v] = {}
        local entities = Entities:FindAllByClassname(v)
        if v == "trigger_multiple" then
            for k, ent in pairs(entities) do
                if string.find(ent:GetName(), "neutralcamp") ~= nil then
                    local a1 = ent:GetOrigin() + ent:GetBounds().Mins
                    local a2 = ent:GetOrigin() + ent:GetBounds().Maxs
                    local b1 = Vector(a1.x, a1.y)
                    local b2 = Vector(a1.x, a2.y)
                    local b3 = Vector(a2.x, a2.y)
                    local b4 = Vector(a2.x, a1.y)
                    local c = {
                        v2c(b1),
                        v2c(b2),
                        v2c(b3),
                        v2c(b4)
                    }
                    table.insert(data[v], c)
                end
            end
        else
            for k, ent in pairs(entities) do
                local a1 = ent:GetOrigin()
                local b1 = v2c(a1)
                table.insert(data[v], b1)
            end
        end
    end
    
    --PrintTable(data)
    --PrintTable(json)
    
    for k, v in pairs(schema) do
        print (k .. v)
        data[v] = data[k]
        data[k] = nil
    end
    AppendToLogFile("mapdata.json", json.encode(data))
    --print (json.encode(data))
end


function GameMode:InitGameMode()
	-- print( "Template addon is loaded." )
    DumpCoordinateData()
    GameRules:SetTreeRegrowTime(99999999)
    GameRules:SetPreGameTime(5)
    ListenToGameEvent("game_rules_state_change", Dynamic_Wrap(GameMode, "OnGameRulesStateChange"), self)
    SendToServerConsole( "sv_cheats 1" )
    SendToServerConsole( "dota_creeps_no_spawning 1" )
    GameRules:GetGameModeEntity():SetThink( "OnSetTimeOfDayThink", self, "SetTimeOfDay", 2 )
    GridNav:DestroyTreesAroundPoint(Vector(0, 0, 0), 9999, true)
end

function GameMode:OnSetTimeOfDayThink()
    GameRules:SetTimeOfDay(.5)
    return 10
end

function DestroyBuildings()
    local keys = {
        "ent_dota_shop",
        "npc_dota_tower",
        "npc_dota_healer",
        "npc_dota_barracks",
        "npc_dota_filler",
        "npc_dota_effigy_statue",
        "npc_dota_tower"
    }
    for k, v in pairs(keys) do
        local entities = Entities:FindAllByClassname(v)
        for k, ent in pairs(entities) do
            ent:RemoveSelf()
        end
    end
    --[[local e = Entities:First()
    while e ~= nil do
        if e:GetName() ~= "" then
            print (e:GetClassname())
        end
        e = Entities:Next(e)
    end]]
    
    local entities = Entities:FindAllByClassname("npc_dota_fort")
    for k, ent in pairs(entities) do
        ent:SetDayTimeVisionRange(0)
        ent:SetNightTimeVisionRange(0)
    end
end

function MapVision()
    local pos = Vector(-512, -512, 0)
    local ward = CreateUnitByName("npc_dota_observer_wards", pos, false, nil, nil, 2 )
    print (ward:GetOrigin())
    local pos2 = Vector(0, 0, 0)
    local enemy_ward = CreateUnitByName("npc_dota_observer_wards", pos2, false, nil, nil, 3 )
    print (enemy_ward:GetOrigin())
    
    
    Timers:CreateTimer(1, function ()
        print (ward:CanEntityBeSeenByMyTeam(enemy_ward))
        print (enemy_ward:CanEntityBeSeenByMyTeam(ward))
        return 1
    end)
end

local elevation_data = {}
local worldMaxX
local worldMaxY
local worldMinX
local worldMinY
local gridSize = 64
local a = 1
local b = 1

function isint(n)
  return n==math.floor(n)
end

function InitElevationData()
    worldMaxX = GetWorldMaxX()
    worldMaxY = GetWorldMaxY()
    worldMinX = GetWorldMinX()
    worldMinY = GetWorldMinY()
    for i = worldMinX , worldMaxX - gridSize, gridSize do
        b = 1
        elevation_data[a] = {}
        for j = worldMinY , worldMaxY - gridSize, gridSize do
            local z = GetGroundHeight(Vector(i, j, 0), nil)
            elevation_data[a][b] = z / 128
            b = b + 1
        end
        a = a + 1
    end
end

function MapElevations()
    local points = List()
    for i = 1, a - 1 do
        for j = 1, b - 1 do
            local z = elevation_data[i][j]
            --print (i, j, z, isint(elevation_data[i][j]))
            if not isint(elevation_data[i][j]) then
                points:Push({x = i, y = j})
            end
        end
    end
    
    print ("total points to process", points:Size())
    MapElevationsHelper(points, function ()
        print("MapElevations done.")
        AppendToLogFile("elevationdata.json", json.encode(elevation_data))
    end)
end

function MapElevationsHelper(points, callback)
    if points:Size() > 0 then
        if points:Size() % 200 == 0 then
            print ("remaining", points:Size())
        end
        local point = points:Pop()
        ProcessPoint(point.x, point.y, function ()
            MapElevationsHelper(points, callback)
        end)
    else
        callback()
    end
end

function ProcessPointHelper(x, y, ring, callback)
    --print("ProcessPointHelper", ring:Size())
    if ring:Size() > 0 then
        local pt1 = {x=x, y=y}
        local pt2 = ring:Pop()
        TestVision(pt1, pt2, function (result)
            ProcessResult(pt1, pt2, result)
            ProcessPointHelper(x, y, ring, callback)
        end)
    else
        callback()
    end
end

function ProcessResult(pt1, pt2, result)
    local z1 = elevation_data[pt1.x][pt1.y]
    local z2 = elevation_data[pt2.x][pt2.y]
    if result[1] == true and result[2] == true then
        if isint(z2) then
            elevation_data[pt1.x][pt1.y] = z2
            return
        end
    end
    if math.floor(z1) == math.floor(z2) then
        if result[1] == false then
            elevation_data[pt1.x][pt1.y] = math.floor(z1)
            elevation_data[pt2.x][pt2.y] = math.ceil(z2)
        end
    elseif math.floor(z1) == math.floor(z2) - 1 then
        if result[1] == true then
            elevation_data[pt1.x][pt1.y] = math.ceil(z1)
        else
            elevation_data[pt1.x][pt1.y] = math.floor(z1)
        end
    end
end

function ProcessPoint(x, y, callback)
    --print ("ProcessPoint", x, y)
    local ring = List(GetPoints(x, y))
    ProcessPointHelper(x, y, ring, callback)
end

function IsValidPoint(pt)
    local x = pt.x
    local y = pt.y
    return x >= 1 and x < a and y >= 1 and y < b
end

function GetPoints(x, y)
    local pt1 = {x = x, y = y}
    local ring = {}
    for i = -3, 3 do
        for j = -3, 3, 6 do
            local pt2 = {x = x + i, y = y + j}
            if IsValidPoint(pt2) then table.insert(ring, pt2) end
        end
    end
    for j = -2, 2 do
        for i = -3, 3, 6 do
            local pt2 = {x = x + i, y = y + j}
            if IsValidPoint(pt2) then table.insert(ring, pt2) end
        end
    end
    
    return ring
end

function XYtoWorldXY(x, y)
    local worldX = (x - 1) * 64 + worldMinX
    local worldY = (y - 1) * 64 + worldMinY
    return Vector(worldX, worldY, 0)
end

function WorldXYtoXY(worldXYVector)
    return {
        x = (worldXYVector.x - worldMinX) / 64 + 1,
        y = (worldXYVector.y - worldMinY) / 64 + 1
    }
end

function TestVision(pt1, pt2, callback)
    local ward1 = CreateWard(pt1.x, pt1.y, 2)
    local ward2 = CreateWard(pt2.x, pt2.y, 3)    
    Timers:CreateTimer(function ()
        local result = {
            ward1:CanEntityBeSeenByMyTeam(ward2),
            ward2:CanEntityBeSeenByMyTeam(ward1)
        }
        ward1:RemoveSelf()
        ward2:RemoveSelf()
        callback(result)
        return nil
    end)
end

function CreateWard(x, y, team)
    local worldXY = XYtoWorldXY(x, y)
    return CreateUnitByName("npc_dota_observer_wards", worldXY, false, nil, nil, team)
end

function ElevationData()
    local worldMaxX = GetWorldMaxX()
    local worldMaxY = GetWorldMaxY()
    local worldMinX = GetWorldMinX()
    local worldMinY = GetWorldMinY()
    local gridSize = 64
    
    print (worldMaxX)
    print (worldMaxY)
    print (worldMinX)
    print (worldMinY)
    
    local a = 0
    local b = 0
    local points = {}
    for i = worldMinX , worldMaxX - gridSize, gridSize do
        b = 0
        for j = worldMinY , worldMaxY - gridSize, gridSize do
            --print(a, b, i + 32, j + 32, GetGroundHeight(Vector(i + 32, j + 32, 0), nil))
            table.insert(points, {
                x = a,
                y = b,
                worldX = i + 32,
                worldY = j + 32,
                worldZ = GetGroundHeight(Vector(i + 32, j + 32, 0), nil)
            })
            b = b + 1
        end
        a = a + 1
    end
    --print (a, b)
    local data = {
        worldMaxX = worldMaxX,
        worldMaxY = worldMaxY,
        worldMinX = worldMinX,
        worldMinY = worldMinY,
        width = a,
        height = b,
        points = points
    }
    
    AppendToLogFile("elevationdata.json", json.encode(data))
end

function GameMode:OnGameRulesStateChange()
    local nNewState = GameRules:State_Get()
    if nNewState == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
        local hero = PlayerResource:GetSelectedHeroEntity(0)
        hero:SetDayTimeVisionRange(0)
        hero:SetNightTimeVisionRange(0)
        
        DestroyBuildings()
        
        InitElevationData()
        
        MapElevations()
        --ProcessPoint(0, 0)
        --ProcessPoint(127, 127)
        --CreateWard(126, 126, 2)
        --CreateWard(123, 129, 3)
        

        --[[TestVision({x=127, y=127}, {x=130,y=130}, function (result)
            print (result[1])
            print (result[2])
        end)]]
        
        
        --MapVision()
        
        --[[local result = TestVision({x=126,y=126}, {x=130, y=130})
        print (result[1])
        print (result[2])
        
        print (" ")
        local result = TestVision({x=130, y=130}, {x=126,y=126})
        print (result[1])
        print (result[2])]]
        
        --ElevationData()
        --[[Timers:CreateTimer(1, function ()
            local hero = PlayerResource:GetSelectedHeroEntity(0)
            hero:SetDayTimeVisionRange(100)
            hero:SetNightTimeVisionRange(100)
            if hero ~= nil then
                print (hero:GetOrigin())
                print (GetGroundHeight(hero:GetOrigin(), nil))
            end
            
            return 1
        end)]]
    end

end