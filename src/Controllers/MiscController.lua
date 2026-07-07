-- MiscController.lua
-- Modular misc controller for generic recurring task ownership.
local MiscController = {}
local tasks = {}
function MiscController.init(deps) deps=deps or {}; MiscController.Logger=deps.Logger; MiscController.Cfg=deps.Cfg or {}; MiscController.FeatureRegistry=deps.FeatureRegistry; if MiscController.FeatureRegistry then MiscController.FeatureRegistry.set("Misc","modular") end; return MiscController end
function MiscController.register(id, fn) if type(id)=="string" and type(fn)=="function" then tasks[id]=fn; return true end; return false,"invalid_task" end
function MiscController.run(id, ...) local fn=tasks[id]; if not fn then return false,"missing_task" end; return pcall(fn, ...) end
function MiscController.start(name) return MiscController.run(name) end
function MiscController.stop(name) tasks[name]=nil; return true end
function MiscController.list() local out={}; for k in pairs(tasks) do table.insert(out,k) end; return out end
return MiscController
