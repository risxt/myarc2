-- PlantingService.lua
-- Adapter/wrapper for APS planting batch.

local PlantingService = {}

function PlantingService.init(deps)
    deps = deps or {}
    PlantingService.Logger = deps.Logger
    PlantingService.Cfg = deps.Cfg
    PlantingService.plantSeedBatchAtImpl = deps.plantSeedBatchAt
    return PlantingService
end

function PlantingService.plantSeedBatchAt(pos, seedName, amount, sprinklerName)
    if type(PlantingService.plantSeedBatchAtImpl) == "function" then
        return PlantingService.plantSeedBatchAtImpl(pos, seedName, amount, sprinklerName)
    end
    return 0, "plant_seed_batch_impl_missing"
end

return PlantingService
