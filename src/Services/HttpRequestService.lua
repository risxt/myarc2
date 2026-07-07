-- HttpRequestService.lua
-- Central executor HTTP request adapter.

local HttpRequestService = {}

local function detectRequest()
    if type(syn) == "table" and type(syn.request) == "function" then return syn.request end
    if type(http_request) == "function" then return http_request end
    if type(request) == "function" then return request end
    if type(getgenv) == "function" then
        local g = getgenv()
        if type(g.request) == "function" then return g.request end
    end
    return nil
end

function HttpRequestService.init(deps)
    deps = deps or {}
    HttpRequestService.Logger = deps.Logger
    HttpRequestService.request = deps.request or detectRequest()
    HttpRequestService.HttpService = deps.HttpService or (game and game:GetService("HttpService"))
    return HttpRequestService
end

function HttpRequestService.available()
    return type(HttpRequestService.request) == "function"
end

function HttpRequestService.jsonEncode(data)
    local http = HttpRequestService.HttpService
    if not http then return nil, "missing_httpservice" end
    local ok, encoded = pcall(function() return http:JSONEncode(data) end)
    if not ok then return nil, encoded end
    return encoded
end

function HttpRequestService.send(options)
    if type(HttpRequestService.request) ~= "function" then
        return false, "missing_request"
    end
    local ok, response = pcall(function()
        return HttpRequestService.request(options)
    end)
    return ok, response
end

function HttpRequestService.postJson(url, payload)
    local body, err = HttpRequestService.jsonEncode(payload)
    if not body then return false, err end
    return HttpRequestService.send({
        Url = url,
        Method = "POST",
        Headers = { ["Content-Type"] = "application/json" },
        Body = body,
    })
end

return HttpRequestService
