# Hybrid Live Entrypoint

Use:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/risxt/myarc2/main/releases/main.lua"))()
```

It loads modular GAG2 runtime first, exposes `_G.GAG2`, then loads `releases/gag2.live.lua` fallback so the full current hub still works while migration continues.

Current honest migration percentage: 35%.
