#!/usr/bin/env luajit

paranoid=false
verbose=false
version=0.01
ansi=true

usage="Mycroft v"..tostring(version)..[[

Usage:
	mycroft
	mycroft [-h|-?|--help|-help]
	mycroft [file1 file2...] [[-e statement ] [-e statement2]...] [-i] [-p] [-v]
	mycroft -t

Options:
	-h|-?|-help|--help		Print this help
	-i				Interactive mode
	+i				Disable interactive mode (default)
	-t				Run test suite
	+t				Do not run test suite (default)
	-p				Paranoid mode (disable some potentially insecure network-related features
	+ansi				Enable ANSI color codes (default)
	-ansi				Disable ANSI color codes
	-v				Verbose
	+v				Non-verbose (default)
	-e statement			Execute statement
]]

function main(argv)
	local world, interactive, forceInteractive, testMode, i, arg, f, files, strs
	files={}
	strs={}
	world={}
	interactive=true
	testMode=false
	forceInteractive=false
	local nextStr=false
	if(#argv==0) then
		interactive=true
	else
		for i,arg in ipairs(argv) do
			if(nextStr) then 
				table.insert(strs, arg)
				nextStr=false
			elseif("-h"==arg or "-help"==arg or "--help"==arg or "-?"==arg) then
				print(usage)
				os.exit(0)
			elseif("-t"==arg) then testMode=true if(not forceInteractive) then interactive=false end
			elseif("+t"==arg) then testMode=false
			elseif("+p"==arg) then paranoid=false
			elseif("-p"==arg) then paranoid=true
			elseif("+v"==arg) then verbose=false
			elseif("-v"==arg) then verbose=true
			elseif("+ansi"==arg) then ansi=true
			elseif("-ansi"==arg) then ansi=false
			elseif("-i"==arg) then interactive=true forceInteractive=true
			elseif("+i"==arg) then interactive=false forceInteractive=false
			elseif("-e"==arg) then nextStr=true if(not forceInteractive) then interactive=false end
			else 
				if(not forceInteractive) then interactive=false end
				f, err=io.open(arg)
				if(nil==f) then
					print("Could not open file "..arg.." for reading: "..tostring(err).."\nTry mycroft -h for help")
					if(arg~="test.myc") then 
						os.exit(1) -- Exit only if we aren't running the automated test suite, because we should skip that
					end
				end
				table.insert(files, f)
			end
		end
	end
	package.path=package.path..";/usr/share/lua/5.1/?/init.lua;/usr/share/lua/5.1/?.lua"
	if(not pcall(require,"mycCore")) then
		local s,e=pcall(require, "mycroft")
		if(not s) then
			print("Error: cannot load library! "..tostring(e))
			os.exit(1)
		end
	end
	if(ansi) then
		io.write(colorCode("black", "white"))
		io.write(string.char(27).."[2J") -- clear the screen so that our color scheme is being used
		io.write(string.char(27).."[;f") -- move to the top left of the screen
	end
	initMycroft(world)
	for _,f in ipairs(files) do
		parseFile(world, f)
	end
	for _,f in ipairs(strs) do
		parseLine(world, f)
	end
	if(testMode) then
		test()
	end
	if(interactive) then
		print(serialize(executePredicateNA(world, "welcome", {})))
		local s, x=pcall(mainLoop,world)
		while (s and x) do s, x=pcall(mainLoop,world) end
		if(not s) then print(x) end
	end
	print(colorCode().."\n"..string.char(27).."[0J") -- unset the color and clear the screen from the cursor on down
end



main(arg) 
