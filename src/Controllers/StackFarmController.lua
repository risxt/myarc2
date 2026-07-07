-- StackFarmController.lua
-- Modular Stack Farm manager ported from gag2.lua.
local StackFarmController = {}
local running = false
local tasks = {}
function StackFarmController.init(deps) deps=deps or {}; StackFarmController.Logger=deps.Logger; StackFarmController.Cfg=deps.Cfg or {}; StackFarmController.SpeedLibrary=deps.SpeedLibrary; StackFarmController.FeatureRegistry=deps.FeatureRegistry; if StackFarmController.FeatureRegistry then StackFarmController.FeatureRegistry.set("StackFarm","modular") end; _G._SFM_Tasks=tasks; _G._SFM_Register=function(id,fn) return StackFarmController.register(id,fn) end; return StackFarmController end
function StackFarmController.register(id, fn) if type(id)=="string" and type(fn)=="function" then tasks[id]=fn; return true end; return false,"invalid_task" end
function StackFarmController.unregister(id) tasks[id]=nil; return true end
function StackFarmController.tick() local cfg=StackFarmController.Cfg or {}; if not cfg.stackFarm then return true end; local order={}; for id,fn in pairs(tasks) do table.insert(order,{id=id,fn=fn,prio=(cfg.sfPriority and cfg.sfPriority[id]) or 99}) end; table.sort(order,function(a,b) return a.prio<b.prio end); for _,item in ipairs(order) do pcall(item.fn); task.wait(0.3) end; return true end
function StackFarmController.start() if running then return true end; running=true; task.spawn(function() while running do task.wait(0.2); StackFarmController.tick() end end); return true end
function StackFarmController.stop() running=false; return true end
return StackFarmController
