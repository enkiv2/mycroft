#!/usr/bin/env lua

paranoid=false
verbose=false
version=0.01


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
				print("Usage:\n\tmycroft\nmycroft [-h|-?|--help|-help]\n\tmycroft [file1 file2...] [[-e statement ] [-e statement2]...] [-i] [-p] [-v]\n\tmycroft -t")
				print("Options:\n\t-h|-?|-help|--help\t\tPrint this help\n\t-i\t\t\tInteractive mode\n\t-t\t\t\tRun test suite\n\t-p\t\t\tParanoid mode (disable some potentially insecure network-related features\n\t-v\t\t\tVerbose\n\t-e statement\t\tExecute statement")
			elseif("-t"==arg) then testMode=true if(not forceInteractive) then interactive=false end
			elseif("-p"==arg) then paranoid=true
			elseif("-v"==arg) then verbose=true
			elseif("-i"==arg) then interactive=true forceInteractive=true
			elseif("-e"==arg) then nextStr=true if(not forceInteractive) then interactive=false end
			else 
				if(not forceInteractive) then interactive=false end
				f, err=io.open(arg)
				if(nil==f) then
					print("Could not open file "..arg.." for reading: "..tostring(err).."\nTry mycroft -h for help")
					os.exit(1)
				end
				table.insert(files, f)
			end
		end
	end
	require("mycCore")
	initMycroft()
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
		local x=mainLoop(world)
		while (x) do x=mainLoop(world) end
	end
end



main(arg)
