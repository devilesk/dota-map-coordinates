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

function DumpCoordinateData(keys, schema, out)    
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
                -- add z to tree coordinates
                if v == "ent_dota_tree" then
                    b1.z = ent:GetOrigin().z
                end
                table.insert(data[v], b1)
            end
        end
    end
    
    for k, v in pairs(schema) do
        print (k .. v)
        data[v] = data[k]
        data[k] = nil
    end
    AppendToLogFile(out, json.encode({data = data}))
end

function GenerateMapData(out)
    DumpCoordinateData(
        {
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
        },
        {
            dota_item_rune_spawner_powerup = "dota_item_rune_spawner",
            npc_dota_filler = "npc_dota_building",
        },
        out
    )
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
    local b = 1
    for i = worldMinX , worldMaxX, gridSize do
        b = 1
        elevation_data[a] = {}
        for j = worldMinY , worldMaxY, gridSize do
            local z = GetGroundHeight(Vector(i, j, 0), nil) / 128
            local zI, zF = math.modf(z)
            if zF >= 0 and zF <= 0.5 then
                elevation_data[a][b] = zI
            elseif zF < -0.5 then
                elevation_data[a][b] = math.floor(z)
            else
                elevation_data[a][b] = z
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
        
        -- finish when no fractional elevation points left or remaining has not changed
        if newTotalPoints == 0 or totalPoints == newTotalPoints then
            -- floor any remaining points
            for i = 1, gridWidth - 1 do
                for j = 1, gridHeight - 1 do
                    elevation_data[i][j] = math.floor(elevation_data[i][j])
                end
            end
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
        TestPointElevation(point.x, point.y, function ()
            MapElevationsHelper(points, callback)
        end)
    else
        callback()
    end
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
            if x2 >= 1 and x2 < gridWidth and y2 >= 1 and y2 < gridHeight then
                ring:Push({x=x2,y=y2})
            end
        end
    end
    for i = -1, 1 do
        for j = -3, 3, 6 do
            local x2, y2 = x + i, y + j
            if x2 >= 1 and x2 < gridWidth and y2 >= 1 and y2 < gridHeight then
                ring:Push({x=x2,y=y2})
            end
        end
    end
    for j = -1, 1 do
        for i = -3, 3, 6 do
            local x2, y2 = x + i, y + j
            if x2 >= 1 and x2 < gridWidth and y2 >= 1 and y2 < gridHeight then
                ring:Push({x=x2,y=y2})
            end
        end
    end
    
    return ring
end

function TestPointElevation(x, y, callback)
    local ring = GetSurroundingPoints(x, y)
    if ring:Size() > 0 and elevation_data[x][y]~=math.floor(elevation_data[x][y]) then
        local pt1 = {x=x, y=y}
        ward1 = CreateUnitByName("npc_dota_observer_wards", Vector((pt1.x - 1) * 64 + worldMinX, (pt1.y - 1) * 64 + worldMinY, 0), false, nil, nil, 2)
        ring:Each(function (pt2)
            pt2.ward = CreateUnitByName("npc_dota_observer_wards", Vector((pt2.x - 1) * 64 + worldMinX, (pt2.y - 1) * 64 + worldMinY, 0), false, nil, nil, 3)
        end)
        Timers:CreateTimer(function ()
            local f
            for k, pt2 in pairs(ring:Items()) do
                local z1, z2 = elevation_data[pt1.x][pt1.y], elevation_data[pt2.x][pt2.y]
                --if z1==math.floor(z1) then break end
                if z1 <= z2 then
                    f = ProcessResultHelper(pt1, pt2, z1, z2, ward1:CanEntityBeSeenByMyTeam(pt2.ward))
                end
            end
            if f ~= nil then
                elevation_data[pt1.x][pt1.y] = f(elevation_data[pt1.x][pt1.y])
            end
            ring:Each(function (pt2)
                pt2.ward:RemoveSelf()
            end)
            ward1:RemoveSelf()
            callback()
            return nil
        end)
    else
        callback()
    end
end

-- zA always <= zB
function ProcessResultHelper(ptA, ptB, zA, zB, ptASeesB)
    -- A and B are in same elevation range
    if math.floor(zA) == math.floor(zB) then
        -- A does not see B
        if not ptASeesB then
            -- zA goes down, zB goes up
            --elevation_data[ptA.x][ptA.y] = math.floor(zA)
            elevation_data[ptB.x][ptB.y] = math.ceil(zB)
            return math.floor
        end
    -- B is one elevation above A
    elseif math.floor(zB) - math.floor(zA) == 1 then
        -- A sees B
        if ptASeesB then
            -- zA goes up, zB goes down
            --elevation_data[ptA.x][ptA.y] = math.ceil(zA)
            elevation_data[ptB.x][ptB.y] = math.floor(zB)
            return math.ceil
        -- A does not see B and isint(zB)
        elseif zB==math.floor(zB) then
            -- zA goes down
            --elevation_data[ptA.x][ptA.y] = math.floor(zA)
            return math.floor
        end
    end
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

function TestGridNav(out)
    local points = {}
    for i = 1, gridWidth - 1 do
        for j = 1, gridHeight - 1 do
            --local z = GetGroundHeight(Vector(i, j, 0), nil)
            local pos = XYtoWorldXY(i, j)
            local bIsTraversable = GridNav:IsTraversable(pos)
            print (i, j, bIsTraversable)
            if not bIsTraversable then
                table.insert(points, {x = pos.x, y = pos.y})
            end
        end
    end
    AppendToLogFile(out, json.encode({data = points}))
    return points
end

--[[function TestWardPlace()
    local ward
    local player = PlayerResource:GetPlayer(0)
    if player ~= nil then
        local hero = player:GetAssignedHero()
        if hero ~= nil then
            ward = CreateItem("item_ward_observer", hero, hero)
            hero:AddItem(ward)
            
            hero:CastAbilityOnPosition(Vector(-2315, 1759, 0), ward, 0)
            --FindClearSpaceForUnit(ward, Vector(-2315, 1759, 0), true)
            FindClearSpaceForUnit(ward, Vector(-200, 0, 0), true)
        end
    end]]
--[[
    local points = List()
    for i = 1, gridWidth - 1 do
        for j = 1, gridHeight - 1 do
            points:Push({x = i, y = j})
        end
    end
    
    local data = {}
    function TestWardPlaceHelper()
        --local z = GetGroundHeight(Vector(i, j, 0), nil)
        local point = points:Pop()
        local pos = XYtoWorldXY(point.x, point.y)
        --ward = CreateUnitByName("npc_dota_observer_wards", pos, true, nil, nil, 2)
        FindClearSpaceForUnit(ward, pos, true)
        local bPosUnchanged = ward:GetOrigin().x == pos.x and ward:GetOrigin().y == pos.y
        if points:Size() % 1000 == 0 then print (point.x, point.y, bPosUnchanged, points:Size()) end
        if not bPosUnchanged then
            table.insert(data, {x = point.x, y = point.y})
        end
        --ward:RemoveSelf()
    end
    
    Timers:CreateTimer(function ()
        if points:Size() > 0 then
            TestWardPlaceHelper()
            return 0.01
        else
            AppendToLogFile("invalidwarddata.json", json.encode(points))
            return nil
        end
    end)
end]]

--[[function TreeElevations()
    local data = {}
    local entities = Entities:FindAllByClassname("ent_dota_tree")
    for k, ent in pairs(entities) do
        print ("tree", ent:GetOrigin(), ent:GetAbsOrigin())
        table.insert(data, {x = ent:GetOrigin().x, y = ent:GetOrigin().y, z = ent:GetOrigin().z})
    end
    AppendToLogFile("treeelevationdata.json", json.encode({data = data}))
end]]

function GameMode:InitGameMode()
    --GenerateMapData("mapdata.json")
    GameRules:SetTreeRegrowTime(99999999)
    GameRules:SetPreGameTime(3)
    ListenToGameEvent("game_rules_state_change", Dynamic_Wrap(GameMode, "OnGameRulesStateChange"), self)
    SendToServerConsole( "sv_cheats 1" )
    SendToServerConsole( "dota_creeps_no_spawning 1" )
    GameRules:GetGameModeEntity():SetThink( "OnSetTimeOfDayThink", self, "SetTimeOfDay", 2 )
    --GridNav:DestroyTreesAroundPoint(Vector(0, 0, 0), 9999, true)
end

function GameMode:OnSetTimeOfDayThink()
    GameRules:SetTimeOfDay(.5)
    return 10
end

function GameMode:OnGameRulesStateChange()
    local nNewState = GameRules:State_Get()
    if nNewState == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
        --[[world_data = {
            worldMaxX = GetWorldMaxX(),
            worldMaxY = GetWorldMaxY(),
            worldMinX = GetWorldMinX(),
            worldMinY = GetWorldMinY()
        }
        AppendToLogFile("worlddata.json", json.encode(world_data))]]
        
        --GridNav:DestroyTreesAroundPoint(Vector(0, 0, 0), 9999, true)
        DestroyBuildings()
        SetNoVision()
        --[[InitElevationData()
        TestGridNav("gridnavdata.json")
        
        Timers:CreateTimer(1, function ()
            MapElevations(nil, function ()
                AppendToLogFile("elevationdata.json", json.encode(elevation_data))
            end)
            return nil
        end)]]
        

        
        --ward = CreateUnitByName("npc_dota_observer_wards", Vector(0, 0, 0), true, nil, nil, 2)
        --TestWardPlace()
        
        --[[]]
        

        
        --[[local e = Entities:First()
        while e ~= nil and e:GetClassname() ~= "ent_dota_tree" do
            print (e:GetClassname())
            e = Entities:Next(e)
        end]]
        --[[local ents = Entities:FindAllInSphere(Vector(0, 0, 0), 99999)
        for k, e in pairs(ents) do
            if e:GetClassname() ~= "ent_dota_tree" then
                print (e:GetClassname())
            end
            if e:GetClassname() == "worldent" then
                PrintTable(e, 2, nil)
            end
        end]]
        
        --[[Timers:CreateTimer(function ()
            local hero = PlayerResource:GetSelectedHeroEntity(0)
            print (hero:GetOrigin())
            return 1
        end)]]
    end
end