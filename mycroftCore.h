#ifndef MYCROFT_CORE_H
#define MYCROFT_CORE_H

ArgList* translateArgList(ArgList* list, ArityConversion* arity);
/* The core of our system: recursive functions */
CompositeTruthVal* executePredicatePA(PredicateLookupTree* world, PredID* p, ArgList* a); 
CompositeTruthVal* executePredicateNIA(PredicateLookupTree* world, char* pname, int arity, ArgList* a); 
CompositeTruthVal* executePredicateNA(PredicateLookupTree* world, char* pname, ArgList* a); 

#endif
