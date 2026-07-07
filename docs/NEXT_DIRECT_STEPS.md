# Next Direct Steps

This is the shortest path from current state to GitHub test.

## Step 1 — Repo ready

- [x] `README.md`
- [x] `.gitignore`
- [x] `releases/loader.lua`
- [x] docs/tests/modules present

## Step 2 — User creates GitHub repo

Needed values:

```txt
GitHub username/org:
Repo name:
Branch for test: main
Branch for stable: stable
```

## Step 3 — Replace loader URL

Edit `releases/loader.lua`:

```lua
BaseUrl = "https://raw.githubusercontent.com/<USER>/<REPO>/<BRANCH>/"
```

## Step 4 — Push GAG2 to GitHub

Then test raw URL:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/<USER>/<REPO>/<BRANCH>/releases/loader.lua"))()
```

## Step 5 — Runtime test

Only after GitHub loader loads modules successfully, test APS in private server.
