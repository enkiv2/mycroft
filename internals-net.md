# Mycroft internals: networking and message passing

Mycroft polyfills a table called mycnet with the following settings:

	mycnet.port=1960
	mycnet.directedMode=true
	mycnet.backlog=512

The following values:

	mycnet.peers={} -- each element is an array consisting of a hostname followed by a port
	mycnet.peerHashed={} -- an associative array of the elements of the peers table keyed by the sha256 hash of the serialized elements
	mycnet.mailbox={} -- a set of requests we have recieved from our peers
	mycnet.pptr=1 -- the index into the peers table pointing to the 'current' selected peer
	mycnet.forwardedLines={} -- a list of facts we've already forwarded, to prevent infinite loops

And, the following methods:

	mycnet.getPeers(world) -- get a list of peers
	mycnet.getCurrentPeer(world) 
	mycnet.getNextPeer(world) -- increment mycnet.pptr and return getCurrentPeer
	mycnet.forwardRequest(world, c) -- send a line of code to next peer
	mycnet.forwardFact(world, c) -- send a line of code to all peers, if it has not already been sent
	mycnet.checkMailbox(world) -- get a list of requests from peers
	mycnet.yield(world) -- process a request from the mailbox, if one exists
	mycnet.restartServer()
	mycnet.hashPeers(world, force) -- hash the list of peers. If 'force' is set, then rehash all peers; otherwise, hash only if the number of peers has changed


If directedMode is set to false, a request will be sent to the next peer in the peers table, in round-robin fashion.


If directedMode is set to true, then for any given request, the order in which it is sent will be defined by the comparison of some consistent hash (in this case sha256) of the signature of the first predicate with the hash of the entire serialized representation of the peer -- we send to the peer with the most similar hash first, and send to all others in order of more or less decreasing similarity. This method of routing is similar to Chord's DHT routing.

On NodeMCU (i.e., on an ESP8622), a device *should* determine whether or not an AP exists with some special name and connect to it if it does, but switch into AP mode and create it if it does not. This is not yet impemented.

Depending upon whether or not a node is in daemon mode (along with other circumstances), timeouts are changed in order to ensure reliability. Currently, the default timeout for daemon mode for server listen in 300 seconds and the current default timeout outside of daemon mode is one tenth of a second. Timeouts on connections to other peers during request forwarding are set to one tenth of a second. This is hard-coded but subject to future tuning.
 
