require("libraries/util")
require("libraries/json")
require("libraries/timers")
require("libraries/list")

RANGE_PARTICLE = "particles/custom/range_display.vpcf"

function CreateParticleCircle(ent, radius, prop)
	local particle
    local hero = PlayerResource:GetSelectedHeroEntity(0)
    local player = PlayerResource:GetPlayer(0)
    particle = ParticleManager:CreateParticleForPlayer(RANGE_PARTICLE, PATTACH_CUSTOMORIGIN, hero, player)
    print (ent:GetAbsOrigin())
    --[[if ent[prop] ~= nil then
        ParticleManager:DestroyParticle(ent[prop], true)
    end]]
    --ent[prop] = particle
	ParticleManager:SetParticleControl(particle, 0, ent:GetAbsOrigin())
	ParticleManager:SetParticleControl(particle, 1, Vector(radius, 100, 100))
	return particle
end

if GameMode == nil then
    GameMode = class({})
end

function Precache( context )
    PrecacheResource( "particle", RANGE_PARTICLE, context )
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
                    if ent:GetName() ~= "" then
                        c.name = ent:GetName()
                        print (ent:GetName())
                    end
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
                print (ent:GetClassname())
                if ent:GetName() ~= "" then
                    b1.name = ent:GetName()
                    print (ent:GetName())
                end
                
                if ent.HasAttackCapability and ent:HasAttackCapability() then
                    if ent.GetAttackRange then
                        --print (ent:GetAttackRange())
                        b1.attackRange = ent:GetAttackRange()
                    end
                    if ent.GetBaseDamageMax then
                        --print (ent:GetBaseDamageMax())
                        b1.damageMax = ent:GetBaseDamageMax()
                    end
                    if ent.GetBaseDamageMin then
                        --print (ent:GetBaseDamageMin())
                        b1.damageMin = ent:GetBaseDamageMin()
                    end
                end
                
                if ent:GetTeamNumber() ~= 0 then
                    if ent.GetBaseDayTimeVisionRange then
                        print (ent:GetBaseDayTimeVisionRange())
                        b1.dayVision = ent:GetBaseDayTimeVisionRange()
                    end
                    if ent.GetBaseNightTimeVisionRange then
                        print (ent:GetBaseNightTimeVisionRange())
                        b1.nightVision = ent:GetBaseNightTimeVisionRange()
                    end
                end
                
                if ent.GetBaseHealthRegen then
                    --print (ent:GetBaseHealthRegen())
                    b1.healthRegen = ent:GetBaseHealthRegen()
                end
                if ent.GetBaseMaxHealth then
                    --print (ent:GetBaseMaxHealth())
                    b1.health = ent:GetBaseMaxHealth()
                end
                if ent.GetPhysicalArmorValue then
                    --print (ent:GetPhysicalArmorValue())
                    b1.armor = ent:GetPhysicalArmorValue()
                end
                if ent.GetTeamNumber then
                    ---print (ent:GetTeamNumber())
                    b1.team = ent:GetTeamNumber()
                end
                if ent.GetBaseAttackTime then
                    --print (ent:GetBaseAttackTime())
                    b1.bat = ent:GetBaseAttackTime()
                end
                
                if v ~= "ent_dota_tree" and ent.GetBoundingMaxs then
                    --print (ent:GetBaseAttackTime())
                    b1.bounds = {ent:GetBoundingMaxs().x, ent:GetBoundingMaxs().y}
                end

                table.insert(data[v], b1)
            end
        end
    end
    
    --[[for k, v in pairs(schema) do
        print (k .. " to " .. v)
        data[v] = data[k]
        data[k] = nil
    end]]
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
            "ent_dota_fountain",
            "ent_dota_shop",
            "ent_dota_tree",
            "npc_dota_barracks",
            "npc_dota_filler",
            "npc_dota_fort",
            "npc_dota_tower",
            "npc_dota_neutral_spawner"
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

local worldMaxX
local worldMaxY
local worldMinX
local worldMinY
local gridSize = 64
local gridWidth = 1
local gridHeight = 1
local tx = 129
local ty = 127
local DEBUG = true

local TEAM_INDEX = 1
local TEAMS = {
    DOTA_TEAM_GOODGUYS,
    DOTA_TEAM_BADGUYS,
    DOTA_TEAM_CUSTOM_1,
    DOTA_TEAM_CUSTOM_2,
    DOTA_TEAM_CUSTOM_3,
    DOTA_TEAM_CUSTOM_4,
    DOTA_TEAM_CUSTOM_5,
    DOTA_TEAM_CUSTOM_6,
    DOTA_TEAM_CUSTOM_7,
    DOTA_TEAM_CUSTOM_8
}

function XYtoWorldXY(x, y)
    local worldX, worldY = (x - 1) * 64 + worldMinX, (y - 1) * 64 + worldMinY
    return Vector(worldX, worldY, 0)
end

function WorldXYtoXY(worldXYVector)
    return (worldXYVector.x - worldMinX) / 64 + 1, (worldXYVector.y - worldMinY) / 64 + 1
end

function InitWorldData()
    worldMaxX = GetWorldMaxX()
    worldMaxY = GetWorldMaxY()
    worldMinX = GetWorldMinX()
    worldMinY = GetWorldMinY()
    local a = 1
    local b = 1
    for i = worldMinX , worldMaxX, gridSize do
        b = 1
        for j = worldMinY , worldMaxY, gridSize do
            b = b + 1
        end
        a = a + 1
    end
    gridWidth = a
    gridHeight = b
end

function GetElevationData(threshold, do_ceil)
    local data = {}
    threshold = threshold or 0
    for i = 1, gridWidth - 1 do
        data[i] = {}
        for j = 1, gridHeight - 1 do
            local z = GetGroundHeight(XYtoWorldXY(i, j), nil) / 128
            local zI, zF = math.modf(z)
            if zF >= 0 and zF <= threshold then
                data[i][j] = zI
            elseif zF < -threshold then
                data[i][j] = math.floor(z)
            elseif do_ceil then
                data[i][j] = math.ceil(z)
            else
                data[i][j] = z
            end
        end
    end
    return data
end

function MapElevations(elevation_data, points, callback)
    if points == nil then
        points = FindPoints(elevation_data)
    end
    local totalPoints = points:Size()
    print ("MapElevations start. Total points to process:", totalPoints)
    MapElevationsHelper(elevation_data, points, function ()
        local newPoints = FindPoints(elevation_data, true)
        local newTotalPoints = newPoints:Size()
        print("MapElevations done.", totalPoints, newTotalPoints)
        
        -- finish when no fractional elevation points left or remaining has not changed
        if newTotalPoints == 0 or totalPoints == newTotalPoints then
            -- floor any remaining points
            for i = 1, gridWidth - 1 do
                for j = 1, gridHeight - 1 do
                    elevation_data[i][j] = math.floor(elevation_data[i][j])
                    --[[local zI, zF = math.modf(elevation_data[i][j])
                    if zF > 0 then
                        elevation_data[i][j] = 255
                    end]]
                end
            end
            callback()
        else
            MapElevations(elevation_data, newPoints, callback)
        end
    end)
end

function FindPoints(elevation_data, skip_floored)
    local points = List()
    for i = 1, gridWidth - 1 do
        for j = 1, gridHeight - 1 do
            if skip_floored then
                if elevation_data[i][j]~=math.floor(elevation_data[i][j]) then
                    points:Push({x = i, y = j})
                end
            else
                points:Push({x = i, y = j})
            end
        end
    end
    return points
end

function MapElevationsHelper(elevation_data, points, callback)
    if points:Size() > 0 then
        if points:Size() % 200 == 0 then
            print ("remaining", points:Size())
        end
        local point = points:Pop()
        TestPointElevation(elevation_data, point.x, point.y, function ()
            MapElevationsHelper(elevation_data, points, callback)
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

function TestPointElevation(elevation_data, x, y, callback, DEBUG, delay)
    delay = delay or 0.01
    local ring = GetSurroundingPoints(x, y)
    if DEBUG then print ("TestPointElevation", x, y, elevation_data[x][y], GetGroundHeight(XYtoWorldXY(x, y), nil), ring:Size(), delay) end
    if ring:Size() > 0 and elevation_data[x][y]~=math.floor(elevation_data[x][y]) then
        local pt1 = {x=x, y=y}
        local ward1 = CreateUnitByName("npc_dota_observer_wards", Vector((pt1.x - 1) * 64 + worldMinX, (pt1.y - 1) * 64 + worldMinY, 0), false, nil, nil, 2)
        if DEBUG then print (ward1:GetOrigin(), ward1:GetAbsOrigin()) end
        ring:Each(function (pt2)
            pt2.ward = CreateUnitByName("npc_dota_observer_wards", Vector((pt2.x - 1) * 64 + worldMinX, (pt2.y - 1) * 64 + worldMinY, 0), false, nil, nil, 3)
            --if DEBUG then print ("    ", pt2.x, pt2.y) end
            if DEBUG then print ("    ", pt2.ward:GetOrigin(), pt2.ward:GetAbsOrigin()) end
        end)
        --TEAM_INDEX = TEAM_INDEX + 2
        --if TEAM_INDEX > 10 then TEAM_INDEX = 1 end
        --print (ring:Size())
        Timers:CreateTimer(delay, function ()
            --if x == tx and y == ty then print ("testing", x, y) end
            local f = 0
            for k, pt2 in pairs(ring:Items()) do
                local z1, z2 = elevation_data[pt1.x][pt1.y], elevation_data[pt2.x][pt2.y]
                --if z1==math.floor(z1) then break end
                --if pt1.x == tx and pt1.y == ty then print (pt1.x, pt1.y, z1, pt2.x, pt2.y, z2) end
                if z1 <= z2 then
                    --local hero = PlayerResource:GetPlayer(0):GetAssignedHero()
                    local v = ProcessResultHelper(elevation_data, pt1, pt2, z1, z2, ward1:CanEntityBeSeenByMyTeam(pt2.ward), DEBUG)
                    if f == 0 or v == 1 then
                        f = v
                    end
                end
            end
            if DEBUG then
                print (f)
            end
            if f == -1 then
                elevation_data[pt1.x][pt1.y] = math.floor(elevation_data[pt1.x][pt1.y])
            elseif f == 1 then
                elevation_data[pt1.x][pt1.y] = math.ceil(elevation_data[pt1.x][pt1.y])
            end
            ring:Each(function (pt2)
                if not DEBUG then pt2.ward:RemoveSelf() end
            end)
            if not DEBUG then ward1:RemoveSelf() end
            callback()
            return nil
        end)
    else
        if DEBUG and ring:Size() > 0 then
            local pt1 = {x=x, y=y}
            local ward1 = CreateUnitByName("npc_dota_observer_wards", Vector((pt1.x - 1) * 64 + worldMinX, (pt1.y - 1) * 64 + worldMinY, 512), false, nil, nil, 2)
            if DEBUG then print (ward1:GetOrigin(), ward1:GetAbsOrigin()) end
            ring:Each(function (pt2)
                pt2.ward = CreateUnitByName("npc_dota_observer_wards", Vector((pt2.x - 1) * 64 + worldMinX, (pt2.y - 1) * 64 + worldMinY, 0), false, nil, nil, 3)
                --if DEBUG then print ("    ", pt2.x, pt2.y) end
                if DEBUG then print ("    ", pt2.ward:GetOrigin(), pt2.ward:GetAbsOrigin()) end
            end)
        end
        callback()
    end
end

-- zA always <= zB
function ProcessResultHelper(elevation_data, ptA, ptB, zA, zB, ptASeesB, DEBUG)
    local result = 0
    -- A and B are in same elevation range
    if math.floor(zA) == math.floor(zB) then
        -- A does not see B
        if not ptASeesB then
            -- zA goes down, zB goes up
            --elevation_data[ptA.x][ptA.y] = math.floor(zA)
            elevation_data[ptB.x][ptB.y] = math.ceil(zB)
            result = -1
        end
    -- B is one elevation above A
    elseif math.floor(zB) - math.floor(zA) == 1 then
        -- A sees B
        if ptASeesB then
            -- zA goes up, zB goes down
            --elevation_data[ptA.x][ptA.y] = math.ceil(zA)
            elevation_data[ptB.x][ptB.y] = math.floor(zB)
            --if ptA.x == tx and ptA.y == ty then print ("1 up, 2 down") end
            result = 1
        -- A does not see B and isint(zB)
        elseif zB==math.floor(zB) then
            -- zA goes down
            --elevation_data[ptA.x][ptA.y] = math.floor(zA)
            --if ptA.x == tx and ptA.y == ty then print ("1 down") end
            result = -1
        end
    end
    if DEBUG then print (ptA.x, ptA.y, ptB.x, ptB.y, zA, zB, ptASeesB, result) end
    return result
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

function CreateNeutralCircles()
    Timers:CreateTimer(function ()
        local entities = Entities:FindAllByClassname("npc_dota_neutral_spawner")
        for k, ent in pairs(entities) do
            CreateParticleCircle(ent, 400, PlayerResource:GetPlayer(0))
        end
        local hero = PlayerResource:GetSelectedHeroEntity(0)
        CreateParticleCircle(hero, 400, PlayerResource:GetPlayer(0))
        return nil
    end)
end

function OnSubmit(eventSourceIndex, args)
    print("OnSubmit", eventSourceIndex)
    PrintTable(args)
    local elevation_data = GetElevationData()
    local x, y, delay = tonumber(args.x), tonumber(args.y), tonumber(args.delay)
    if x ~= nil and y ~= nil then
        print( x, y, elevation_data[x][y], GetGroundHeight(XYtoWorldXY(x, y), nil), GetGroundPosition(XYtoWorldXY(x, y), nil))
        TestPointElevation(elevation_data, x, y, function ()
            print( x, y, elevation_data[x][y])
        end, true, delay)
    else
        print ("invalid input", x, y)
    end
end

function OnClear(eventSourceIndex, args)
    print("OnClear", eventSourceIndex)
    PrintTable(args)
    local wards = Entities:FindAllByClassname("npc_dota_ward_base")
    if wards ~= nil then
        for k, ent in pairs(wards) do
            ent:RemoveSelf()
        end
    end
    OnTestNeutralRange(eventSourceIndex, args)
end

local particles = {}
function OnTestNeutralRange(eventSourceIndex, args)
    local x, y, delay = tonumber(args.x), tonumber(args.y), tonumber(args.delay)
    for k, particle in pairs(particles) do
        print ("destroy", particle)
        ParticleManager:DestroyParticle(particle, true)
    end
    particles = {}
    
    local entities = Entities:FindAllByClassname("npc_dota_creep_neutral")
    
    for k, ent in pairs(entities) do
        if ent ~= nil and ent:IsAlive() then
            table.insert(particles, CreateParticleCircle(ent, 400, "guard_range"))
            table.insert(particles, CreateParticleCircle(ent, 400 + x * ent:GetBaseMoveSpeed(), "max_range"))
        end
    end
    local mode = GameRules:GetGameModeEntity()
    mode:SetFogOfWarDisabled(true)
end

function GameMode:InitGameMode()
    GenerateMapData("mapdata.json")
    GameRules:SetTreeRegrowTime(99999999)
    GameRules:SetPreGameTime(3)
    ListenToGameEvent("game_rules_state_change", Dynamic_Wrap(GameMode, "OnGameRulesStateChange"), self)
    CustomGameEventManager:RegisterListener( "submit", OnSubmit )
    CustomGameEventManager:RegisterListener( "clear", OnClear )
    SendToServerConsole( "sv_cheats 1" )
    SendToServerConsole( "dota_creeps_no_spawning 1" )
    GameRules:GetGameModeEntity():SetThink( "OnSetTimeOfDayThink", self, "SetTimeOfDay", 2 )
end

function GameMode:OnSetTimeOfDayThink()
    GameRules:SetTimeOfDay(0.5)
    return 10
end

function GameMode:OnGameRulesStateChange()
    local nNewState = GameRules:State_Get()
    if nNewState == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
        --CreateNeutralCircles()
        
    
        InitWorldData()
        world_data = {
            worldMaxX = GetWorldMaxX(),
            worldMaxY = GetWorldMaxY(),
            worldMinX = GetWorldMinX(),
            worldMinY = GetWorldMinY()
        }
        AppendToLogFile("worlddata.json", json.encode(world_data))
        
        
        GridNav:DestroyTreesAroundPoint(Vector(0, 0, 0), 9999, true)
        --DestroyBuildings()
        --SetNoVision()
        
        if not DEBUG then
            local elevation_data = GetElevationData(0.75, true)
            TestGridNav("gridnavdata.json")
            AppendToLogFile("elevationdata.json", json.encode({data = elevation_data}))
            --[[Timers:CreateTimer(1, function ()
                MapElevations(elevation_data, nil, function ()
                    AppendToLogFile("elevationdata.json", json.encode({data = elevation_data}))
                end)
                return nil
            end)]]
        else
            --[[local elevation_data = GetElevationData()
            print( tx, ty, elevation_data[tx][ty])
            TestPointElevation(tx, ty, function ()
                print( tx, ty, elevation_data[tx][ty])
                
                --local w1 = CreateUnitByName("npc_dota_observer_wards", Vector((tx - 1) * 64 + worldMinX, (ty - 1) * 64 + worldMinY, 0), false, nil, nil, 2)
                --print (w1:GetOrigin(), XYtoWorldXY(tx, ty))
            end)]]
            --local w1 = CreateUnitByName("npc_dota_observer_wards", Vector((tx - 1) * 64 + worldMinX, (ty - 1) * 64 + worldMinY, 0), false, nil, nil, 2)
            --AddFOWViewer(2, Vector((tx - 1) * 64 + worldMinX, (ty - 1) * 64 + worldMinY, 0), 1000, 60, true)
            --AddFOWViewer(2, Vector(0, 0, 0), 200, 60, true)
        end
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