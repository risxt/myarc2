-- migration_status.lua
-- Tiny remote-readable status script.
return {
    percent = 90,
    honestMeaning = "architecture/readiness coverage; not pure behavior completion",
    fallbackRequired = true,
    fullyMigrated = false,
    liveEntrypoint = "releases/main.lua",
    monolithFallback = "releases/gag2.live.lua",
}
