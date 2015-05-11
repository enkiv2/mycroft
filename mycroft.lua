#!/usr/bin/env luajit

paranoid=false
verbose=false
version=0.01
ansi=true

usage="Mycroft v"..tostring(version)..[[

Usage:
	mycroft
	mycroft [-h|-?|--help|-help]
	mycroft [file1 file2...] [[-e statement ] [-e statement2]...] [-i] [-p] [-v] [[-P peername peerport] [-P peername peerport]...]
	mycroft -t

Options:
	-h|-?|-help|--help		Print this help
	-i				Interactive mode
	+i				Disable interactive mode (default)
	-t				Run test suite
	+t				Do not run test suite (default)
	-p				Paranoid mode (disable some potentially insecure network-related features
	+p 				Disable paranoid mode (default)
	+ansi				Enable ANSI color codes (default)
	-ansi				Disable ANSI color codes
	-v				Verbose
	+v				Non-verbose (default)
	-d 				Daemon mode (listen for requests)
	+d 				Disable daemon mode (default)
	-j n				Spawn n worker jobs
	-l port				Set listen port
	-P peername peerport		Add peer 
	-e statement			Execute statement
]]

function main(argv)
	local world, interactive, forceInteractive, testMode, i, arg, f, files, strs
	files={}
	strs={}
	world={}
	peers={}
	daemonMode=false
	interactive=true
	testMode=false
	forceInteractive=false
	local nextStr=false
	local nextPN=false
	local nextPP=false
	local nextLP=false
	local nextJ=false
	local port=1960
	local peer={}
	if(#argv==0) then
		interactive=true
	else
		for _,arg in ipairs(argv) do
			if(nextStr) then 
				table.insert(strs, arg)
				nextStr=false
			elseif(nextPN) then
				peer[1]=arg
				nextPN=false
				nextPP=true
			elseif(nextPP) then
				peer[2]=tonumber(arg)
				table.insert(peers, peer)
				nextPP=false
			elseif(nextLP) then
				port=tonumber(arg)
				nextLP=false
			elseif(nextJ) then
				nextJ=false
				jobCount=tonumber(arg)
				jobs={}
				if(jobCount~=nil) then
					local i
					local chunk=""
					for i=1,jobCount do
						chunk=chunk.." -P 127.0.0.1 "..tostring(port+i)
						table.insert(peers, {"127.0.0.1", port+i})
						table.insert(jobs, {"127.0.0.1", port+i})
					end
					for i=1,jobCount do
						local tmp=string.gsub(chunk, "-P 1270.0.01 "..tostring(port+1), "")
						os.execute("sh -c 'echo PID $$ > _mycroft_log_"..tostring(port+1).." ; mycroft -d -l "..tostring(port+i)..tmp.." >> _mycroft_log_"..tostring(port+i).." ' &")
					end
				end
			elseif("-h"==arg or "-help"==arg or "--help"==arg or "-?"==arg) then
				print(usage)
				os.exit(0)
			elseif("-t"==arg) then testMode=true if(not forceInteractive) then interactive=false end
			elseif("+t"==arg) then testMode=false
			elseif("+p"==arg) then paranoid=false
			elseif("-p"==arg) then paranoid=true
			elseif("+d"==arg) then daemonMode=false
			elseif("-d"==arg) then daemonMode=true interactive=false forceInteractive=false ansi=false
			elseif("-P"==arg) then nextPN=true
			elseif("-j"==arg) then nextJ=true
			elseif("+v"==arg) then verbose=false
			elseif("-v"==arg) then verbose=true
			elseif("+ansi"==arg) then ansi=true
			elseif("-ansi"==arg) then ansi=false
			elseif("-i"==arg) then interactive=true forceInteractive=true
			elseif("+i"==arg) then interactive=false forceInteractive=false
			elseif("-l"==arg) then nextLP=true
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
	mycnet={}
	mycnet.port=port
	initMycroft(world)
	for _,f in ipairs(peers) do
		table.insert(mycnet.peers, f)
	end
	debugPrint({"peers:", mycnet.peers})
	local mainCoroutine=coroutine.create(function() 
		local home=os.getenv("HOME")
		if(nil==home) then
			home=""
		end
		local cfg=string.split(package.config, "[\n]")
		sep=cfg[1]
		debugPrint("Home directory: "..home)
		debugPrint("Config files: "..home..sep..".mycroftrc "..sep.."etc"..sep.."mycroftrc")
		s,e = pcall(io.open, home..sep..".mycroftrc")
		if(s and nil~=e) then
			parseFile(world, e)
		else
			s,e = pcall(io.open, sep.."etc"..sep.."mycroftrc")
			if(s and nil~=e) then
				parseFile(world, e)
			else
				parseLines(world, defaultConfig)
			end
		end
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
			coroutine.yield()
		elseif(daemonMode) then
			while(true) do
				mycnet.yield(world)
				coroutine.yield()
			end
		end
	end)
	local listenCoroutine=coroutine.create(function()
		while(true) do
			mycnet.yield(world)
			coroutine.yield()
		end
	end)
	while(coroutine.status(mainCoroutine)~="dead") do
		coroutine.resume(mainCoroutine)
		coroutine.resume(listenCoroutine)
	end
	exitClean(0)
end



main(arg) 
