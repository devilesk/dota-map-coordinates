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
end

local elevation_data = {}
local worldMaxX
local worldMaxY
local worldMinX
local worldMinY
local gridSize = 64
local gridWidth = 1
local gridHeight = 1

function XYtoWorldXY(x, y)
    local worldX, worldY = (x - 1) * 64 + worldMinX, (y - 1) * 64 + worldMinY
    return Vector(worldX, worldY, 0)
end

function WorldXYtoXY(worldXYVector)
    return (worldXYVector.x - worldMinX) / 64 + 1, (worldXYVector.y - worldMinY) / 64 + 1
end

function InitElevationData()
    worldMaxX = GetWorldMaxX()
    worldMaxY = GetWorldMaxY()
    worldMinX = GetWorldMinX()
    worldMinY = GetWorldMinY()
    local a = 1
    for i = worldMinX , worldMaxX - gridSize, gridSize do
        local b = 1
        elevation_data[a] = {}
        for j = worldMinY , worldMaxY - gridSize, gridSize do
            local z = GetGroundHeight(Vector(i, j, 0), nil) / 128
            local zI, zF = math.modf(z)
            if zF >= 0 and zF <= 0.5 then
                elevation_data[a][b] = zI
            elseif zF < -0.5
                elevation_data[a][b] = math.floor(z)
            end
            b = b + 1
        end
        a = a + 1
    end
    gridWidth = a
    gridHeight = b
end

function MapElevations(points, callback)
    if points == nil then
        points = FindPoints()
    end
    local totalPoints = points:Size()
    print ("MapElevations start. Total points to process:", totalPoints)
    MapElevationsHelper(points, function ()
        local newPoints = FindPoints()
        local newTotalPoints = newPoints:Size()
        print("MapElevations done.", totalPoints, newTotalPoints)
        if newTotalPoints == 0 or totalPoints == newTotalPoints then
            callback()
        else
            MapElevations(newPoints, callback)
        end
    end)
end

function FindPoints()
    local points = List()
    for i = 1, gridWidth - 1 do
        for j = 1, gridHeight - 1 do
            local z = elevation_data[i][j]
            -- not isint(elevation_data[i][j])
            if elevation_data[i][j]~=math.floor(elevation_data[i][j]) then
                points:Push({x = i, y = j})
            end
        end
    end
    return points
end

function MapElevationsHelper(points, callback)
    if points:Size() > 0 then
        if points:Size() % 200 == 0 then
            print ("remaining", points:Size())
        end
        local point = points:Pop()
        --[[FindPointElevation(point.x, point.y, function ()
            MapElevationsHelper(points, callback)
        end)]]
        FindPointElevationHelper(point.x, point.y, GetSurroundingPoints(point.x, point.y), function ()
            MapElevationsHelper(points, callback)
        end)
    else
        callback()
    end
end

function FindPointElevation(x, y, callback)
    local ring = GetSurroundingPoints(x, y)
    FindPointElevationHelper(x, y, ring, callback)
end

--[[
   OOO
  O---O
 O-----O
 O--W--O
 O-----O
  O---O
   OOO
]]
function GetSurroundingPoints(x, y)
    local ring = List()
    
    for i = -2, 2, 4 do
        for j = -2, 2, 4 do
            local x2, y2 = x + i, y + j
            -- IsValidPoint
            if x2 >= 1 and x2 < gridWidth and y2 >= 1 and y2 < gridHeight then
                ring:Push({x=x2,y=y2})
            end
        end
    end
    for i = -1, 1 do
        for j = -3, 3, 6 do
            local x2, y2 = x + i, y + j
            -- IsValidPoint
            if x2 >= 1 and x2 < gridWidth and y2 >= 1 and y2 < gridHeight then
                ring:Push({x=x2,y=y2})
            end
        end
    end
    for j = -1, 1 do
        for i = -3, 3, 6 do
            local x2, y2 = x + i, y + j
            -- IsValidPoint
            if x2 >= 1 and x2 < gridWidth and y2 >= 1 and y2 < gridHeight then
                ring:Push({x=x2,y=y2})
            end
        end
    end
    
    return ring
end

function IsValidPoint(x, y)
    return x >= 1 and x < gridWidth and y >= 1 and y < gridHeight
end

function FindPointElevationHelper(x, y, ring, callback)
    -- ring:Size() > 0 and not isint(elevation_data[x][y])
    if ring:Size() > 0 and elevation_data[x][y]~=math.floor(elevation_data[x][y]) then
        local pt1, pt2 = {x=x, y=y}, ring:Pop()
        TestVision(pt1, pt2, function (r1, r2)
            --ProcessResult(pt1, pt2, r1, r2)
            local z1, z2 = elevation_data[pt1.x][pt1.y], elevation_data[pt2.x][pt2.y]
            if z1 < z2 then
                ProcessResultHelper(pt1, pt2, z1, z2, r1, r2)
            else
                ProcessResultHelper(pt2, pt1, z2, z1, r2, r1)
            end
            
            FindPointElevationHelper(x, y, ring, callback)
        end)
    else
        callback()
    end
end

function ProcessResult(pt1, pt2, r1, r2)
    local z1, z2 = elevation_data[pt1.x][pt1.y], elevation_data[pt2.x][pt2.y]
    if z1 < z2 then
        ProcessResultHelper(pt1, pt2, z1, z2, r1, r2)
    else
        ProcessResultHelper(pt2, pt1, z2, z1, r2, r1)
    end
end

-- zA always <= zB
function ProcessResultHelper(ptA, ptB, zA, zB, ptASeesB, ptBSeesA)
    -- A and B are in same elevation range
    if math.floor(zA) == math.floor(zB) then
        -- A does not see B
        if not ptASeesB then
            -- zA goes down, zB goes up
            elevation_data[ptA.x][ptA.y] = math.floor(zA)
            elevation_data[ptB.x][ptB.y] = math.ceil(zB) -- zB already be int, in which case this does nothing
        end
    -- B is one elevation above A
    elseif math.floor(zB) - math.floor(zA) == 1 then
        -- A sees B
        if ptASeesB Then
            -- zA goes up, zB goes down
            elevation_data[ptA.x][ptA.y] = math.ceil(zA)
            elevation_data[ptB.x][ptB.y] = math.floor(zB) -- zB already be int, in which case this does nothing
        -- A does not see B and isint(zB)
        elseif zB==math.floor(zB)
            -- zA goes down
            elevation_data[ptA.x][ptA.y] = math.floor(zA)
        end
    end
end

-- creates two wards and in next frame executes callback with result of whether they have vision of each other
function TestVision(pt1, pt2, callback)
    -- CreateWard, XYtoWorldXY
    local ward1 = CreateUnitByName("npc_dota_observer_wards", Vector((pt1.x - 1) * 64 + worldMinX, (pt1.y - 1) * 64 + worldMinY, 0), false, nil, nil, 2)
    local ward2 = CreateUnitByName("npc_dota_observer_wards", Vector((pt2.x - 1) * 64 + worldMinX, (pt2.y - 1) * 64 + worldMinY, 0), false, nil, nil, 3)
    -- use timer that executes in next frame to give chance for vision to update
    Timers:CreateTimer(function ()
        local r1, r2 = ward1:CanEntityBeSeenByMyTeam(ward2), ward2:CanEntityBeSeenByMyTeam(ward1)
        ward1:RemoveSelf()
        ward2:RemoveSelf()
        callback(r1, r2)
        return nil
    end)
end

function CreateWard(x, y, team)
    return CreateUnitByName("npc_dota_observer_wards", XYtoWorldXY(x, y), false, nil, nil, team)
end

function SetNoVision()
    local hero = PlayerResource:GetSelectedHeroEntity(0)
    hero:SetDayTimeVisionRange(0)
    hero:SetNightTimeVisionRange(0)

    local entities = Entities:FindAllByClassname("npc_dota_fort")
    for k, ent in pairs(entities) do
        ent:SetDayTimeVisionRange(0)
        ent:SetNightTimeVisionRange(0)
    end
end

function GameMode:InitGameMode()
    DumpCoordinateData()
    GameRules:SetTreeRegrowTime(99999999)
    GameRules:SetPreGameTime(3)
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

function GameMode:OnGameRulesStateChange()
    local nNewState = GameRules:State_Get()
    if nNewState == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
        DestroyBuildings()
        
        SetNoVision()
        
        InitElevationData()
        
        MapElevations(nil, function ()
            AppendToLogFile("elevationdata.json", json.encode(elevation_data))
        end)
        
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
                
        --[[local e = Entities:First()
        while e ~= nil do
            if e:GetName() ~= "" then
                print (e:GetClassname())
            end
            e = Entities:Next(e)
        end]]
    end
end

--[[function ElevationData()
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
end]]