-- PositionService.lua
-- Owns saved position resolution for APS/tool placement.

local PositionService = {}

function PositionService.init(deps)
    deps = deps or {}
    PositionService.Logger = deps.Logger
    PositionService.Cfg = deps.Cfg
    PositionService.getSavedSprinklerVectorImpl = deps.getSavedSprinklerVector
    return PositionService
end

function PositionService.getSavedSprinklerVector(plot)
    if type(PositionService.getSavedSprinklerVectorImpl) == "function" then
        return PositionService.getSavedSprinklerVectorImpl(plot)
    end
    local cfg = PositionService.Cfg or {}
    local pos = cfg.savedSprinklerPos or cfg.apsSavedSprinklerPos or cfg.sprinklerSavedPos
    if typeof and typeof(pos) == "Vector3" then return pos end
    if type(pos) == "table" then
        local x, y, z = tonumber(pos.x or pos.X or pos[1]), tonumber(pos.y or pos.Y or pos[2]), tonumber(pos.z or pos.Z or pos[3])
        if x and y and z and Vector3 then return Vector3.new(x, y, z) end
    end
    return nil, "saved_position_missing"
end

return PositionService
