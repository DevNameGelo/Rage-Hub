#!/bin/bash
# Runs the Rage Hub test suite on plain Luau with a mocked Roblox environment.
# Needs the `luau` CLI: https://github.com/luau-lang/luau/releases   (or set LUAU=/path/to/luau)
set -e
cd "$(dirname "$0")"
{
  echo "local M = (function()"; cat mock.lua; echo "end)()"
  echo "local function LoadLib()"; cat ../RageHub.lua; echo "end"
  echo "local RageHub = LoadLib()"
  cat 01_core.lua 02_elements_components.lua 03_modules_and_more.lua
} > /tmp/ragehub_tests.lua
"${LUAU:-luau}" /tmp/ragehub_tests.lua
