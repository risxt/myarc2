-- RemoteService.lua
-- Central remote lookup and safe fire helpers.

local RemoteService = {}

function RemoteService.init(deps)
    deps = deps or {}
    RemoteService.Logger = deps.Logger
    RemoteService.ReplicatedStorage = deps.ReplicatedStorage or (game and game:GetService("ReplicatedStorage"))
    return RemoteService
end

function RemoteService.getPacketRemote()
    local rs = RemoteService.ReplicatedStorage
    local ok, remote = pcall(function()
        return rs.SharedModules.Packet.RemoteEvent
    end)
    if ok then return remote end
    return nil, remote
end

function RemoteService.fire(remote, ...)
    if not remote or type(remote.FireServer) ~= "function" then
        return false, "invalid_remote"
    end
    local args = { ... }
    local ok, err = pcall(function()
        remote:FireServer(table.unpack(args))
    end)
    return ok, err
end

function RemoteService.firePacket(...)
    local remote, err = RemoteService.getPacketRemote()
    if not remote then return false, err end
    return RemoteService.fire(remote, ...)
end

return RemoteService
