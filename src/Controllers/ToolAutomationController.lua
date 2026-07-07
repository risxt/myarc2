-- ToolAutomationController.lua
-- Modular tool automation boundary with concrete equip/use primitives.
local ToolAutomationController = {}
local running = {}
local function backpack() local lp=ToolAutomationController.LocalPlayer; return lp and lp:FindFirstChild("Backpack") end
local function char() local lp=ToolAutomationController.LocalPlayer; return lp and lp.Character end
function ToolAutomationController.init(deps) deps=deps or {}; ToolAutomationController.Logger=deps.Logger; ToolAutomationController.Cfg=deps.Cfg or {}; ToolAutomationController.LocalPlayer=deps.LocalPlayer; ToolAutomationController.FeatureRegistry=deps.FeatureRegistry; if ToolAutomationController.FeatureRegistry then ToolAutomationController.FeatureRegistry.set("Tools","modular") end; return ToolAutomationController end
function ToolAutomationController.findTool(predicate) local bp=backpack(); if not bp then return nil end; for _,t in ipairs(bp:GetChildren()) do if t:IsA("Tool") and predicate(t) then return t end end; return nil end
function ToolAutomationController.equipTool(tool) if not tool then return false,"missing_tool" end; local c=char(); local hum=c and c:FindFirstChildOfClass("Humanoid"); if hum then hum:EquipTool(tool); return true end; tool.Parent=c; return true end
function ToolAutomationController.activateTool(tool) local ok,err=ToolAutomationController.equipTool(tool); if not ok then return ok,err end; if type(tool.Activate)=="function" then tool:Activate(); return true end; return false,"tool_no_activate" end
function ToolAutomationController.useByAttribute(attrName, attrValue) local tool=ToolAutomationController.findTool(function(t) local v=t:GetAttribute(attrName); return attrValue==nil and v~=nil or v==attrValue end); return ToolAutomationController.activateTool(tool) end
function ToolAutomationController.start(featureName) running[featureName or "default"]=true; return true end
function ToolAutomationController.stop(featureName) running[featureName or "default"]=false; return true end
function ToolAutomationController.isRunning(featureName) return running[featureName or "default"]==true end
return ToolAutomationController
