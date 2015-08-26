-- Support for distributed mycroft clusters
if(not mycnet) then 
	mycnet={}
end
function hashProximity(tbl, hash)
	local keys, res, item
	keys={}
	for n in pairs(tbl) do
		table.insert(keys, n)
	end
	table.sort(keys)
	item=keys[0]
	res={}
	for i,n in ipairs(keys) do
		if(n<hash) then 
			item=i
			table.insert(res, 1, tbl[n])
		else 
			if(#res<i-item) then
				table.insert(res, (i-item)+1, tbl[n])
			else
				table.insert(res, tbl[n])
			end
		end
	end
	return res
	
end
function setupNetworkingNMCU()
	debugPrint("detected NodeMCU; setting up.")
	setupNetworkingCommon()
	mycnet.temp={}
	local ignore=function() end
	mycnet.restartServer=function()
		if(daemonMode) then
			mycnet.server=net.createServer(net.TCP, 300)
		else
			mycnet.server=net.createServer(net.TCP, 0.1)
		end
		updateMBX=function(client, str)
			if(not mycnet.temp[client]) then mycnet.temp[client]="" end
			if(string.find(str, "\n$")~=nil) then
				mycnet.temp[client]=mycnet.temp[client]..str
			else
				local line=string.gsub(mycnet.temp[client]..str, "\n$", "")
				mycnet.temp[client]=""
				if(string.find(line, '^ *%?%-')~=nil) then
					netPrint("line is query; executing immediately")
					client:send(serialize(parseLine(world, line)).."\n", ignore)
				else
					table.insert(mycnet.mailbox, {line, client})
					netPrint("contents of mailbox: "..serialize(mycnet.mailbox))
				end
				client.close()
			end
		end
		callbackFn=function(client) 
			client:on("receive", updateMBX)
		end
		mycnet.server=createServer(net.TCP, callbackFn)
	end
	mycnet.forwardRequest=function(world, c) 
		if(mycnet.directedMode) then
			local hashl=sha2.hash256(c)
			mycnet.hashPeers(world)
			mycnet.peers=hashProximity(mycnet.peerHash, hashl)
			mycnet.pptr=1
		end
		local handleSend=function(cl, s)
			cl:send(c.."\n")
		end
		local handleReceive=function(cl, s)
			parseLine(world, string.gsub(c, ".\n$", " :- "..s.."."))
			cl.close()
		end
		local client=net.createConnection(net.TCP, 0)
		client:on("connection", handleSend)
		local firstPeer=mycnet.getCurrentPeer(world)
		netPrint({"firstPeer", firstPeer})
		local peer=mycnet.getNextPeer(world)
		netPrint({"peer", peer})
		if(nil==peer) then return nil end
		client:connect(peer[2], peer[1])
		return nil
	end -- send a line of code to next peer
	mycnet.checkMailbox=function(world) end
	return mycnet.restartServer()
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
		if(mycnet.directedMode) then
			local hashl=sha2.hash256(c)
			mycnet.hashPeers(world)
			mycnet.peers=hashProximity(mycnet.peerHash, hashl)
			mycnet.pptr=1
		end
		local firstPeer=mycnet.getCurrentPeer(world)
		netPrint({"firstPeer", firstPeer})
		local peer=mycnet.getNextPeer(world)
		netPrint({"peer", peer})
		if(nil==peer) then return nil end
		local client=socket.connect(unpack(peer))
		while(nil==client and peer~=firstPeer) do
			netPrint("attempting to send "..c.." to peer "..serialize(peer))
			peer=mycnet.getNextPeer(world)
			if(nil==peer) then return nil end
			client=socket.connect(unpack(peer))
		end
		if(peer==firstPeer) then return nil end
		client:settimeout(0.1)
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
	mycnet.directedMode=true
	mycnet.backlog=512
	mycnet.peers={}
	mycnet.peerHashed={}
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
	mycnet.hashPeers=function(world)
		if(#mycnet.peers~=table.maxn(mycnet.peerHashed)) then
			for i=table.maxn(mycnet.peerHashed),#mycnet.peers do
				mycnet.peerHashed[sha2.hash256(serialize(mycnet.peers[i]))]=mycnet.peers[i]
			end
		end
	end
	mycnet.forwardFact=function(world, l)
		local hashl=sha2.hash256(l)
		netPrint("forwarding fact [["..l.."]]")
		if(mycnet.forwardedLines[hashl]) then return nil end
		mycnet.forwardedLines[hashl]=true
		if(mycnet.directedMode) then
			mycnet.hashPeers(world)
			mycnet.peers=hashProximity(mycnet.peerHash, hashl)
			mycnet.pptr=1
		end
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
