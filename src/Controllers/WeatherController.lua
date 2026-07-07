-- WeatherController.lua
-- Modular Weather Predict + Auto Weather Disconnect controller.

local WeatherController = {}
local running = false
local triggered = false
local weatherOrder = {
    {name = "Rainbow Moon", chance = 6}, {name = "Goldmoon", chance = 13}, {name = "Bloodmoon", chance = 2}, {name = "Moon", chance = 79},
}
function WeatherController.init(deps)
    deps = deps or {}; WeatherController.Logger=deps.Logger; WeatherController.Cfg=deps.Cfg or {}; WeatherController.LocalPlayer=deps.LocalPlayer; WeatherController.TeleportService=deps.TeleportService or (game and game:GetService("TeleportService")); WeatherController.Workspace=deps.Workspace or workspace; WeatherController.FeatureRegistry=deps.FeatureRegistry
    if WeatherController.FeatureRegistry then WeatherController.FeatureRegistry.set("Weather", "modular") end
    return WeatherController
end
function WeatherController.predictNightType(cycleNum)
    local rng=Random.new(cycleNum*1000+3); local roll=rng:NextNumber()*100; local cum=0
    for _,w in ipairs(weatherOrder) do cum+=w.chance; if roll<=cum then return w.name end end
    return "Moon"
end
function WeatherController.fmtCountdown(s) s=math.max(0,math.floor(s)); local h=math.floor(s/3600); local m=math.floor((s%3600)/60); local sec=s%60; if h>0 then return string.format("%dh %02dm %02ds",h,m,sec) end; return string.format("%dm %02ds",m,sec) end
function WeatherController.getNextSpecialNights()
    local now=os.time(); local offset=WeatherController.Workspace:GetAttribute("CycleOffset") or 0; local pos=(now+offset)%600; local secs=((480-pos)+600)%600; if secs==0 then secs=600 end
    local finds={}; local nightTime=now+secs; local limit=now+86400*3
    while nightTime<limit do local nType=WeatherController.predictNightType(math.floor(nightTime/600)); if nType~="Moon" and not finds[nType] then finds[nType]=nightTime-now end; if finds["Bloodmoon"] and finds["Goldmoon"] and finds["Rainbow Moon"] then break end; nightTime+=600 end
    return finds
end
function WeatherController.normalizeWeatherName(name)
    name=tostring(name or ""):gsub("^%s+",""):gsub("%s+$",""); local low=name:lower():gsub("%s+",""); local map={rainbowmoon="Rainbow Moon",goldmoon="Goldmoon",bloodmoon="Bloodmoon",starfall="Starfall",sunburst="Sunburst",snowfall="Snowfall",lightning="Lightning",rainbow="Rainbow",aurora="Aurora",night="Night",moon="Moon",rain="Rain"}; return map[low] or name
end
function WeatherController.selectedBadWeatherSet()
    local set={}; local sel=(WeatherController.Cfg or {}).selDisconnectWeather
    if type(sel)=="table" then for _,name in ipairs(sel) do local n=WeatherController.normalizeWeatherName(name); if n~="" and n~="Select Options" then set[n]=true end end end
    return set
end
function WeatherController.getVisibleWeatherCard(set)
    local pg=WeatherController.LocalPlayer and WeatherController.LocalPlayer:FindFirstChild("PlayerGui"); local weatherGui=pg and pg:FindFirstChild("WeatherUI"); local frame=weatherGui and weatherGui:FindFirstChild("Frame"); if not frame then return nil end
    for _,card in ipairs(frame:GetChildren()) do if card:IsA("GuiObject") and card.Visible and card.Name:sub(1,3)~="PW_" and card.Name:sub(1,6)~="_Pred_" then local weatherName=WeatherController.normalizeWeatherName(card:GetAttribute("WeatherToolTip") or card.Name); local label=card:FindFirstChild("Weather",true); if label and label:IsA("TextLabel") and label.Text~="" then weatherName=WeatherController.normalizeWeatherName(label.Text) end; if set[weatherName] then return weatherName end end end
    return nil
end
function WeatherController.getBadActiveWeather()
    local set=WeatherController.selectedBadWeatherSet(); if not next(set) then return nil end
    local active=WeatherController.normalizeWeatherName(WeatherController.Workspace:GetAttribute("ActiveWeather")); if set[active] and active~="Day" then return active end
    local phase=WeatherController.normalizeWeatherName(WeatherController.Workspace:GetAttribute("ActivePhase")); if set[phase] and phase~="Day" then return phase end
    return WeatherController.getVisibleWeatherCard(set)
end
function WeatherController.tickDisconnect()
    local cfg=WeatherController.Cfg or {}; if cfg.autoWeatherDisconnect and not triggered then local bad=WeatherController.getBadActiveWeather(); if bad then triggered=true; local minutes=math.max(tonumber(cfg.weatherReconnectMinutes) or 3,0.1); local seconds=math.floor(minutes*60); local player=WeatherController.LocalPlayer; local tp=WeatherController.TeleportService; task.delay(seconds,function() pcall(function() tp:Teleport(game.PlaceId, player) end) end); player:Kick(("Auto Disconnect: %s weather detected. Reconnecting in ~%s min..."):format(bad,tostring(minutes))); return true,bad end elseif not cfg.autoWeatherDisconnect then triggered=false end; return false end
function WeatherController.startPredict() return true, WeatherController.getNextSpecialNights() end
function WeatherController.startDisconnect() if running then return true end; running=true; task.spawn(function() while running do WeatherController.tickDisconnect(); task.wait(2) end end); return true end
function WeatherController.startHud() return true, "hud_owned_by_overlay_controller" end
function WeatherController.start() return WeatherController.startDisconnect() end
function WeatherController.stop() running=false; return true end
return WeatherController
