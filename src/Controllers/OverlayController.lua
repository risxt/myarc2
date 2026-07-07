-- OverlayController.lua
-- Modular overlay/ESP controller with tracked GUI ownership.
local OverlayController = {}
local running = {}
local guis = {}
function OverlayController.init(deps) deps=deps or {}; OverlayController.Logger=deps.Logger; OverlayController.Cfg=deps.Cfg or {}; OverlayController.LocalPlayer=deps.LocalPlayer; OverlayController.FeatureRegistry=deps.FeatureRegistry; if OverlayController.FeatureRegistry then OverlayController.FeatureRegistry.set("ESP","modular"); OverlayController.FeatureRegistry.set("Overlays","modular") end; return OverlayController end
function OverlayController.playerGui() local lp=OverlayController.LocalPlayer; return lp and lp:FindFirstChild("PlayerGui") end
function OverlayController.createGui(name) local pg=OverlayController.playerGui(); if not pg then return nil,"missing_playergui" end; if guis[name] and guis[name].Parent then return guis[name] end; local gui=Instance.new("ScreenGui"); gui.Name="GAG2_"..tostring(name); gui.ResetOnSpawn=false; gui.Parent=pg; guis[name]=gui; return gui end
function OverlayController.destroyGui(name) if guis[name] then guis[name]:Destroy(); guis[name]=nil end; return true end
function OverlayController.start(name) name=name or "Overlay"; running[name]=true; return OverlayController.createGui(name) ~= nil end
function OverlayController.stop(name) name=name or "Overlay"; running[name]=false; return OverlayController.destroyGui(name) end
function OverlayController.isRunning(name) return running[name or "Overlay"]==true end
function OverlayController.setTextOverlay(name, text) local gui=OverlayController.createGui(name); if not gui then return false end; local label=gui:FindFirstChild("Text") or Instance.new("TextLabel"); label.Name="Text"; label.Size=UDim2.fromOffset(360,40); label.BackgroundTransparency=0.35; label.TextColor3=Color3.new(1,1,1); label.Text=tostring(text or ""); label.Parent=gui; return true end
return OverlayController
