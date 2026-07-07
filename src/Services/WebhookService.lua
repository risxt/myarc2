-- WebhookService.lua
-- APS notification service. Webhook is observer-only and never controls APS logic.

local WebhookService = {}

local function log(level, message, data)
    local logger = WebhookService.Logger
    local fn = logger and logger[string.lower(level)]
    if type(fn) == "function" then
        fn("WebhookService", message, data)
    elseif logger and type(logger.log) == "function" then
        logger.log(level, "WebhookService", message, data)
    else
        print(string.format("[%s] [WebhookService] %s %s", tostring(level), tostring(message), data ~= nil and tostring(data) or ""))
    end
end

local function getRequest()
    if type(WebhookService.request) == "function" then return WebhookService.request end
    if type(getgenv) == "function" then
        local g = getgenv()
        if type(g.request) == "function" then return g.request end
    end
    if type(syn) == "table" and type(syn.request) == "function" then return syn.request end
    if type(http_request) == "function" then return http_request end
    if type(request) == "function" then return request end
    return nil
end

function WebhookService.init(deps)
    deps = deps or {}
    WebhookService.Logger = deps.Logger
    WebhookService.Cfg = deps.Cfg
    WebhookService.Player = deps.Player
    WebhookService.HttpService = deps.HttpService
    WebhookService.request = deps.request
    return WebhookService
end

function WebhookService.buildApsSuccessPayload(data)
    data = type(data) == "table" and data or {}
    local cfg = WebhookService.Cfg or {}
    local player = WebhookService.Player or (game and game:GetService("Players").LocalPlayer)
    local playerName = player and player.Name or "?"
    local kg = tonumber(data.kg)
    local threshold = tonumber(cfg.apsWeightThresh) or 0
    local mode = tostring(cfg.apsThreshMode or "Above")

    local desc = table.concat({
        "**Target Status** Target reached",
        "**Weight** `" .. (kg and string.format("%.2f kg", kg) or "N/A") .. "`",
        "**Target** `" .. mode .. " " .. string.format("%.2f", threshold) .. " kg`",
        "**Focus** `" .. tostring(cfg.apsSeedName or "?") .. "`",
        "**Scanning** `" .. tostring(data.cropName or cfg.apsCropName or "?") .. "`",
        "**Username** `" .. tostring(playerName) .. "`",
        "**Action Status** `Success — stopped`",
    }, "\n")

    return {
        username = "GAG Auto Plant Scan",
        content = "@everyone",
        allowed_mentions = { parse = { "everyone" } },
        embeds = {{
            title = "Auto-Plant — Target Hit",
            description = desc,
            color = 5763719,
            footer = { text = "Client: " .. tostring(playerName) },
            timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
        }},
    }
end

function WebhookService.sendApsSuccess(data)
    local cfg = WebhookService.Cfg
    if not cfg then
        log("WARN", "webhook_skip_no_cfg")
        return false
    end

    local url = tostring(cfg.apsWebhookUrl or "")
    local validUrl = url ~= "" and url:find("discord.com/api/webhooks", 1, true)
    if not cfg.apsWebhook and not validUrl then
        log("INFO", "webhook_skip_disabled", "enabled=" .. tostring(cfg.apsWebhook))
        return false
    end
    if not validUrl then
        log("WARN", "webhook_skip_bad_url", "len=" .. tostring(#url))
        return false
    end

    local req = getRequest()
    if type(req) ~= "function" then
        log("WARN", "webhook_skip_no_request")
        return false
    end

    local http = WebhookService.HttpService or (game and game:GetService("HttpService"))
    if not http then
        log("WARN", "webhook_skip_no_httpservice")
        return false
    end

    task.spawn(function()
        local payload = WebhookService.buildApsSuccessPayload(data)
        local encodeOk, body = pcall(function()
            return http:JSONEncode(payload)
        end)
        if not encodeOk then
            log("WARN", "webhook_encode_failed", tostring(body))
            return
        end

        local ok, response = pcall(function()
            return req({
                Url = url,
                Method = "POST",
                Headers = { ["Content-Type"] = "application/json" },
                Body = body,
            })
        end)
        local code = type(response) == "table" and (response.StatusCode or response.Status or response.status_code) or "nil"
        local kg = type(data) == "table" and tonumber(data.kg) or nil
        log(ok and "INFO" or "WARN", "webhook_send", "ok=" .. tostring(ok) .. " code=" .. tostring(code) .. " kg=" .. tostring(kg))
    end)

    return true
end

return WebhookService
