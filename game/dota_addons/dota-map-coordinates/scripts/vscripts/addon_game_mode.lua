require("util")
require("json")

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
    AppendToLogFile("mapdata.txt", json.encode(data))
    --print (json.encode(data))
end


function GameMode:InitGameMode()
	-- print( "Template addon is loaded." )
    DumpCoordinateData()
end