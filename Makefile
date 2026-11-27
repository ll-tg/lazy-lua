LUA ?= lua5.5
LUAC ?= luac5.5

.PHONY: test check format clean

test:
	$(LUA) tests/test.lua

check:
	$(LUAC) -p src/ll-lua.lua src/ll-lua/*.lua bin/ll-lua tests/test.lua examples/echo.lua

format:
	@echo "No formatter is required; source follows the Lua 5.5 style guide."

clean:
	rm -rf .rocks *.rock *.src.rock
