-- RuntimeContext.lua
-- Collects Roblox/executor dependencies for modular GAG2.

local RuntimeContext = {}

local function getRequest()
    if type(syn) == "table" and type(syn.request) == "function" then return syn.request end
    if type(http_request) == "function" then return http_request end
    if type(request) == "function" then return request end
    if type(getgenv) == "function" then
        local g = getgenv()
        if type(g.request) == "function" then return g.request end
    end
    return nil
end

function RuntimeContext.build()
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    while not LocalPlayer do
        task.wait()
        LocalPlayer = Players.LocalPlayer
    end

    return {
        Players = Players,
        Player = LocalPlayer,
        LocalPlayer = LocalPlayer,
        HttpService = game:GetService("HttpService"),
        TeleportService = game:GetService("TeleportService"),
        ReplicatedStorage = game:GetService("ReplicatedStorage"),
        RunService = game:GetService("RunService"),
        request = getRequest(),
    }
end

return RuntimeContext
