#!/usr/bin/env python
import uuid
import re
ctvNum="([0-1]\.0|0|1|0\.[0-9]*)"
ctvCanonical=re.compile("<"+ctvNum+", *"+ctvNum+">")
ctvBra=re.compile("<"+ctvNum+"\|")
ctvKet=re.compile("\|"+ctvNum+">")

class CTV(object):
    def __init__(self, truth=0, confidence=0):
        self.truth=truth
        self.confidence=confidence
        self.canonicalize()
    def set(self, s):
        if(s=="YES"):
            self.truth=1
            self.confidence=1
        elif(s=="NO"):
           self.truth=0
           self.confidence=1
        elif(s=="NC"):
            self.truth=0
            self.confidence=0
        else:
            m=ctvCanonical.match(s)
            if(m):
                self.truth=float(m.group(1))
                self.confidence=float(m.group(2))
            else:
                m=ctvBra.match(s)
    def canonicalize(self):
        if(self.truth>1):
            self.truth=1
        elif(self.truth<0):
            self.truth=0
        if(self.confidence>1):
            self.confidence=1
        elif(self.confidence<0):
            self.confidence=0
        if(self.confidence==0):
            self.truth=0
    def __repr__(self):
        self.canonicalize()
        if(self.confidence==0):
            return "NC"
        if(self.confidence==1):
            if(self.truth==1):
                return "YES"
            elif(self.truth==0):
                return "NO"
            else:
                return "<"+str(self.truth)+"|"
        elif(self.truth==1):
            return "|"+str(self.confidence)+">"
        else:
            return "<"+str(self.truth)+","+str(self.confidence)+">"
    def __str__(self):
        return self.__repr__()
    def __eq__(self, other):
        return self.__repr__()==repr(other)
    def bool(self, other, op):
        if(op=="and"):
            return CTV(self.truth*other.truth, self.confidence*other.confidence)
        else:
            A=self.truth; B=self.confidence
            C=other.truth; D=other.confidence
            return CTV((A*B)+(C*D)-(A*C), min(B,D))

class Pred(object):
    def __init__(self, world, name, arity=0, det=None, src=""):
        self.world=world
        self.name=name
        self.arity=arity
        self.det=det
        self.src=src
        self.impl=None
        self.op=None
        self.facts={}
    def __repr__(self):
        return str(self.name)+"/"+str(self.arity)
    def vivify(self, pname):
        if(type(pname)==str):
            if(pname in world.preds):
                return world.preds[pname]
            # TODO: support requesting definition from other nodes
            return world.preds["NC"]
    def setFact(self, args, val):
        self.facts[str(args)]=val
    def getFact(self, args):
        if(str(args) in self.facts):
            return self.facts[str(args)]
        return None
    def setImpl(self, p1, at1, p2, at2, literals, op):
        self.op=op
        self.impl=((str(p1), at1), (str(p2), at2), literals)
        if(self.det==None):
            if(p1.det==True and p2.det==True):
                self.det=True
    def translateArgs(args, at, literals):
        ret=[]
        for i in at:
            if(i>=len(args)):
                ret.append(literals[i-len(args)])
            else:
                ret.append(args[i])
        return ret
    def __call__(self, *args, **kw_args):
        # TODO: support forwarding request to other nodes
        ret=self.getFact(args)
        if(ret!=None):
            return ret
        else:
            # Unpack this part of the tree & perform translation
            lit=self.impl[2]
            p1=self.vivify(self.impl[0][0])
            args1=self.translateArgs(args, self.impl[0][1], lit)
            p2=self.vivify(self.impl[1][0])
            args2=self.translateArgs(args, self.impl[1][1], lit)
            # Evaluate
            return p1(*args1).bool(p2(*args2), self.op)

class AnonPred(Pred):
    def __init__(self, world, arity, det=None, src=""):
        Pred.__init__(self, world, str(uuid.uuid1()).replace("-", "_"), arity, det, src)

class BuiltinPred(Pred):
    def __init__(self, world, name, impl, arity=0, det=False):
        Pred.__init__(self, world, name, arity, det)
        self.impl=impl
    def __call__(self, *args, **kw_args):
        ret=self.getFact(args)
        if(ret!=None):
            return ret
        return self.impl(*args, **kw_args)

