#include "mycroft.h"
#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include <stdarg.h>

ArgList* translateArgList(ArgList* list, ArityConversion* arity) {
	ArgList* ret=malloc(sizeof(ArgList));
	ArgList* l = list;
	for(int i = 0; i<arity->length; i++) {
		setListItem(ret, arity->p2args[i], getListItem(l, arity->p2args[i]));
	}
	return ret;
}



/* The core of our system: recursive functions */
CompositeTruthVal* executePredicatePA(PredicateLookupTree* world, PredID* p, ArgList* a) {
	CompositeTruthVal* ret = malloc(sizeof(CompositeTruthVal));
	char* hash=hashList(a);
	Predicate* p_out=NULL;
	Fact* f_out=NULL;
	if (factExists(world, p, hash, p_out, f_out)) {
		return f_out->truthy;
	} else {
		ret->truth=0; ret->confidence=0;
		if(NULL==(void*)p_out) 			return ret;
		if(NULL==(void*)p_out->def) 			return ret;
		if(NULL==(void*)p_out->def->children) 	return ret;
		if(NULL==(void*)p_out->def->children[0]) 	return ret;
		if(NULL==(void*)p_out->def->children[1]) {
			ret=executePredicatePA(world,  (p_out->def->children[0]), translateArgList(a,  (p_out->def->correspondences[0])));
		} else 	ret=
			performPLBoolean(executePredicatePA(world,  (p_out->def->children[0]), translateArgList(a,  (p_out->def->correspondences[0]))), 
				executePredicatePA(world,  (p_out->def->children[1]), translateArgList(a,  (p_out->def->correspondences[1]))),
				p_out->def->andOr);
		if(MYC_ERR_NOERR!=MYCERR) {
			ret->truth=0; ret->confidence=0;
			if(NULL==(void*)MYCERR_STR) MYCERR_STR=error_string(MYCERR);
			char* argListStr=arg2String(createList(a));
			char* tmp=malloc(1024+strlen(p->name)+strlen(MYCERR_STR)+strlen(argListStr));
			sprintf(tmp, "%s at %s/%d %s%s\n", MYCERR_STR, p->name, p->arity, p->name, argListStr);
			free(MYCERR_STR);
			MYCERR_STR=tmp;
		} else {
			if(p_out->def->isDet) {
				insertFact(world, p, hash, ret);
			}
		}
		return ret;
	}
}
CompositeTruthVal* executePredicateNIA(PredicateLookupTree* world, char* pname, int arity, ArgList* a) {
	return executePredicatePA(world, createPredID(pname, arity), a);
}
CompositeTruthVal* executePredicateNA(PredicateLookupTree* world, char* pname, ArgList* a) {
	 return executePredicateNIA(world, pname, listSize(a), a);
}
