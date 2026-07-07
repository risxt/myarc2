# GitHub Loader Prep

## Status

Prepared, not active.

Template:

- `releases/loader.github.template.lua`

## Required Before Upload

Replace placeholders:

```txt
<USER>
<REPO>
<BRANCH>
```

Recommended branch strategy:

```txt
main   = development
stable = tested runtime release
tag    = pinned production version
```

## Production Rule

Do not use `main` for autoexecute after release. Use `stable` or tag.

## Cache Fallback

The loader template supports:

1. Fetch raw GitHub source.
2. Cache source using `writefile` if available.
3. If GitHub fetch fails, load cached module if present.
4. If critical module cannot load, bootstrap errors and APS should not start.

## Dependency Injection

Modules do not hardcode URLs. Loader owns fetch logic and injects runtime dependencies.
