#!/bin/bash
# Runs the Rage Hub test suite under the plain Luau CLI using a mocked Roblox environment.
# Needs the `luau` binary: https://github.com/luau-lang/luau/releases
set -e
cd "$(dirname "$0")"
{
  echo "local M = (function()"; cat mock.lua; echo "end)()"
  echo "local RageHub = (function()"; cat ../RageHub.lua; echo "end)()"
  cat test.lua
} > /tmp/ragehub_combined.lua
"${LUAU:-luau}" /tmp/ragehub_combined.lua
