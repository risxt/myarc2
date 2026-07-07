-- UIRegistry.lua
-- Keeps UI section/control registration separate from feature logic.

local UIRegistry = {}
UIRegistry.Sections = {}
UIRegistry.Controls = {}

function UIRegistry.init(deps)
    deps = deps or {}
    UIRegistry.Logger = deps.Logger
    return UIRegistry
end

function UIRegistry.registerSection(name, section)
    UIRegistry.Sections[name] = section
    return section
end

function UIRegistry.registerControl(id, meta)
    UIRegistry.Controls[id] = meta
    return meta
end

function UIRegistry.getControl(id)
    return UIRegistry.Controls[id]
end

return UIRegistry
