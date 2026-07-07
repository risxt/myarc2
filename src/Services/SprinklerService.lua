-- SprinklerService.lua
-- Adapter/wrapper for sprinkler placement.

local SprinklerService = {}

function SprinklerService.init(deps)
    deps = deps or {}
    SprinklerService.Logger = deps.Logger
    SprinklerService.Cfg = deps.Cfg
    SprinklerService.placeOneSprinklerAtImpl = deps.placeOneSprinklerAt
    return SprinklerService
end

function SprinklerService.placeOneSprinklerAt(pos, sprinklerName)
    if type(SprinklerService.placeOneSprinklerAtImpl) == "function" then
        return SprinklerService.placeOneSprinklerAtImpl(pos, sprinklerName)
    end
    return false, "place_sprinkler_impl_missing"
end

return SprinklerService
