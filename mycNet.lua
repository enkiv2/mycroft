-- Support for distributed mycroft clusters
if(not mycnet) then 
	mycnet={}
end
function setupNetworkingNMCU()
	debugPrint("detected NodeMCU; setting up.")
	setupNetworkingCommon()
	setupNetworkingDummy() --XXX
end
function setupNetworkingLJIT()
	debugPrint("detected luajit; setting up.")
	setupNetworkingCommon()
	if(pcall(require, "socket")) then
		setupNetworkingLSOCK() -- prefer LuaSocket
	elseif(pcall(require, "ffi")) then
		ffi=require("ffi") 
		ffi.cdef[[
			int     accept(int, struct sockaddr *restrict, int *restrict);
			int     bind(int, const struct sockaddr *, int);
			int     connect(int, const struct sockaddr *, int);
			int     getpeername(int, struct sockaddr *restrict, int *restrict);
			int     getsockname(int, struct sockaddr *restrict, int *restrict);
			int     getsockopt(int, int, int, void *restrict, int *restrict);
			int     listen(int, int);
			int recv(int, void *, size_t, int);
			int recvfrom(int, void *restrict, size_t, int, struct sockaddr *restrict, int *restrict);
			int recvmsg(int, struct msghdr *, int);
			int send(int, const void *, size_t, int);
			int sendmsg(int, const struct msghdr *, int);
			int sendto(int, const void *, size_t, int, const struct sockaddr *, int);
			int     setsockopt(int, int, int, const void *, int);
			int     shutdown(int, int);
			int     socket(int, int, int);
			int     sockatmark(int);
			int     socketpair(int, int, int, int[2]);

		]]
		setupNetworkingDummy()

	else
		debugPrint("Despite having the jit table, we are not luajit or are unable to load ffi. Falling back to luasock")
		setupNetworkingLSOCK()
	end
end
function setupNetworkingLSOCK()
	netPrint("detected luasocket; setting up.")
	setupNetworkingCommon()
	if(pcall(require, "socket")) then
		socket=require("socket")
	end
	if(nil==socket) then
		s,e=pcall(require, "socket")
		debugPrint("luasocket failed to load: "..e.."; falling back to dummy")
		return setupNetworkingDummy()
	end
	mycnet.restartServer=function()
		local err
		mycnet.server, err=socket.bind("*", mycnet.port, mycnet.backlog)
		if(nil==mycnet.server) then netPrint(err) return setupNetworkingDummy() end
		if(daemonMode) then
			mycnet.server:settimeout(300, 't')
		else
			mycnet.server:settimeout(0.1, 't')
		end
	end
	mycnet.forwardRequest=function(world, c) 
		local firstPeer=mycnet.getCurrentPeer(world)
		local peer=mycnet.getNextPeer(world)
		if(nil==peer) then return nil end
		local client=socket.connect(unpack(peer))
		while(nil==client and peer~=firstPeer) do
			netPrint("attempting to send "..c.." to peer "..serialize(peer))
			peer=mycnet.getNextPeer(world)
			if(nil==peer) then return nil end
			client=socket.connect(unpack(peer))
		end
		if(peer==firstPeer) then return nil end
		client:send(c.."\n")
		local ret=client:receive("*l")
		return ret
	end -- send a line of code to next peer
	mycnet.checkMailbox=function(world) 
		local client, e=mycnet.server:accept()
		netPrint({client, e})
		if(nil==client) then return mycnet.mailbox end
		if(daemonMode) then 
			client:settimeout(300)
		else
			client:settimeout(10)
		end
		local line,err=client:receive("*l")
		netPrint({line, err})
		if(nil~=line) then
			netPrint("got line [["..tostring(line).."]] from peer "..serialize(client:getpeername()))
			if(string.find(line, '^ *%?%-')~=nil) then
				netPrint("line is query; executing immediately")
				client:send(serialize(parseLine(world, line)))
			else
				table.insert(mycnet.mailbox, {line, client:getpeername()})
				netPrint("contents of mailbox: "..serialize(mycnet.mailbox))
			end
		end
		client:close()
	end -- get a list of requests from peers
	return mycnet.restartServer()
end
function setupNetworkingCommon()
	netPrint("setting up common networking features")
	if(not mycnet.port) then
		mycnet.port=1960 -- hardcode default for now
	end
	mycnet.backlog=512
	mycnet.peers={}
	mycnet.mailbox={}
	mycnet.pptr=1
	mycnet.forwardedLines={}
	mycnet.getPeers=function(world) return mycnet.peers end -- get a list of peers
	mycnet.getCurrentPeer=function(world) local ret=mycnet.peers[mycnet.pptr] return ret end 
	mycnet.getNextPeer=function(world) 
		mycnet.pptr=mycnet.pptr+1 
		if(mycnet.pptr>#mycnet.peers) then mycnet.pptr=1 end
		return mycnet.getCurrentPeer(world)
	end -- round robin
	mycnet.yield=function(world)
		mycnet.checkMailbox(world)
		if(#mycnet.mailbox>0) then
			local item=mycnet.mailbox[1]
			table.remove(mycnet.mailbox, 1)
			local line=item[1]
			netPrint({"received line", line})
			ret=parseLine(world, line)
			return nil
		end
	end -- process one step of somebody else's request
	mycnet.forwardFact=function(world, l)
		netPrint("forwarding fact [["..l.."]]")
		if(mycnet.forwardedLines[l]) then return nil end
		mycnet.forwardedLines[l]=true
		local sp=mycnet.getCurrentPeer(world)
		netPrint({"current peer", sp})
		if(nil==sp) then return nil end
		mycnet.forwardRequest(world, line)
		while(sp~=mycnet.getCurrentPeer()) do
			mycnet.forwardRequest(world, line)
		end
		return nil
	end
	netPrint("listen port="..tostring(mycnet.port)..",backlog="..tostring(mycnet.backlog))
end
function setupNetworkingDummy()
	netPrint("setting up dummy networking functions")
	mycnet.getPeers=function() return {} end -- get a list of peers
	mycnet.getCurrentPeer=function() return nil end 
	mycnet.forwardRequest=function(c) return nil end -- send a line of code to next peer
	mycnet.checkMailbox=function() return {} end -- get a list of requests from peers
end
function setupNetworking()
	if(nil~=node) then
		if(nil~=node.chipid) then
			if(nil~=node.chipid()) then
				return setupNetworkingNMCU()
			end
		end
	end
	if(jit~=nil) then
		return setupNetworkingLJIT()
	end
	return setupNetworkingLSOCK()
end
function netPrint(x)
	if(verbose or daemonMode) then 
		print(serialize(x))
		io.flush()
	end
end
