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

The rationale behind directedMode is that routing will (in the normal case) require many fewer hops and much less replication will be necessary: even though the routing is arbitrary, it represents a consistent ordering and is more resistant to split-brain problems in a non-fully-connected network than round robin routing in a similarly connected network outside of pathological cases. However, this comes at the cost of making sybil attacks on particular known requests easier: an attacker with the ability to set his own node name can guarantee control over that predicate for as long as he is on the network by ensuring he is always in control of the node name with the closest hash to the predicate (so if the attacker can precompute hash collisions -- which may not be so difficult since for performance reasons on embedded hardware we aren't using a cryptographic hash -- he can avoid needing to control most of the network).

Because of the request ordering in directedMode, even if the node that already has the solution for a particular determinate query is not (or no longer) the best candidate in terms of hash similarity, it will as a result of responding to the request distribute the response to be memozied by the most-matching node in its peer list first (meaning that over time the routing improves).

Memoized results should eventually be put into a priority queue, and a redistribution protocol of memoized results is planned as follows: results for which the current node is the closest hash match should never be discarded by the gc even if they are very stale, and results at the bottom of the queue should be forwarded to the best-matching node that responds within timeout period before being discarded by the gc. A node that is going offline should send its entire 'world' to every node, in the order defined by directedMode. (Currently there is no distinction between memoized results and user-defined facts that have been distributed by a peer; however, since only facts are memoized, and facts are small, this may be sufficient.)

On NodeMCU (i.e., on an ESP8622), a device *should* determine whether or not an AP exists with some special name and connect to it if it does, but switch into AP mode and create it if it does not. This is not yet impemented.

Depending upon whether or not a node is in daemon mode (along with other circumstances), timeouts are changed in order to ensure reliability. Currently, the default timeout for daemon mode for server listen in 300 seconds and the current default timeout outside of daemon mode is one tenth of a second. Timeouts on connections to other peers during request forwarding are set to one tenth of a second. This is hard-coded but subject to future tuning.
 
