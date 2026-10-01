# dmc-touchmanager Documentation

New here? The [Quick Start](../README.md#quick-start) makes a square that holds several touches at once in about 10 minutes.

## Start

- [Quick Start](../README.md#quick-start): copy the library in, a square that holds touches

## Use

- [API reference](api.md): `register()`, `setFocus()` and the rest, the touch event, how touches are routed, configuration, known issues
- [Examples](../examples/): two objects, one with a table listener and one with a function listener

## Contribute

- [Development](development.md): which files are generated, building, testing, possible future changes
- [Issues](https://github.com/dmccuskey/dmc-touchmanager/issues)

## Project Structure

```text
README.md                   landing page and Quick Start
CHANGELOG.md                what changed in each version
LICENSE
docs/                       this documentation
└── images/                 screenshots for the README
dmc_corona/                 what apps copy
└── dmc_touchmanager.lua    the library (source)
dmc_corona_boot.lua         loader, from dmc-corona-boot (generated copy)
dmc_corona.cfg              library configuration
examples/                   sample app, with its own generated dmc_corona/
└── screenshots/            one per app, for examples/README.md
Snakefile                   build rules for the generated copies
tests/                      unit tests (lunatest); run_unit.sh runs them with Lua 5.1
```
