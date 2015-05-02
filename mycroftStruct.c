#include "mycroftStruct.h"
#include <string.h>

/**************************************************************************************
 * Functions                                                                          *
 **************************************************************************************/

int cmpPredID(PredID* x, PredID* y) {
	if(x.arity==y.arity) {
		if(0==strcmp(x->name, y->name)) {
			return 1;
		}
	}
	return 0;
}
int cmpTruth(CompositeTruthVal* x, CompositeTruthVal* y) {
	return (0==(x->truth)-(y->truth) && 0==(x->confidence)-(y->confidence));
}
/* Return 0 if a fact does not exist; set f_out to it and return 1 if it does. 
 * If the predicate exists, set p_out to that pred.
 * Developers are strongly encouraged to set p_out and f_out to NULL before running the function
 * Even if the pred is not found, w will be set to the pred tree that would be its parent; likewise for f and facts
 */
int factExists_r(PredicateLookupTree* world, PredID* p, char* hash, Predicate* p_out, Fact* f_out, PredicateLookupTree* w, FactTree* f) {
	int found=0; int gaveUp=0;
	w=world;
	do {
		if (NULL!=w->item && NULL!=w->item->pred) {
			p_out=w->item->pred;
			if(cmpPredId(w->item->pred, p)) {
				if(NULL==w->item->facts) {
					gaveUp=1;
				} else {
					f=w->item->facts;
					do {
						if(cmpPredId(f->item->pred, p)) {
							int x=strcmp(f->item->hash, hash);
							f_out=f->item;
							if(0==x) {
								found=1;
							} else if(0>x) {
								f=f->children[0]; // We are searching for a smaller hash
							} else f=f->children[1];
						} else gaveUp=1;
					} while(!found && !gaveUp && NULL!=f)
					if(!found) {
						gaveUp=1;
					}
				}
			} else {
				if(NULL=w->children) {
					gaveUp=1;
				} else {
					x=strcmp(w->item->pred->name, p->name);
					if(0==x) {
						x=(w->item->pred->arity)-(p->arity);
					}
					if (0>x) {
						w=w->children[0];
					} else w=w->children[1];
				}
			}
		} else {
			gaveUp=1;
		}
	} while (!found && !gaveUp && NULL!=w)
	return found;
}
int factExists(PredicateLookupTree* world, PredID* p, char* hash, Predicate* p_out, Fact* f_out) {
	PredicateLookupTree* w;
	FactTree* f;
	return factExists_r(world, p, hash, p_out, f_out, w, f);
}

void insertFact(PredicateLookupTree* world, PredID* p, char* hash, CompositeTruthVal* truthy) {
	PredicateLookupTree* w=NULL;
	FactTree* f=NULL;
	PredID* p_out; Fact* f_out;
	if(factExists_r(world, p, hash, p_out, f_out, w, f)) {
		if(cmpTruth(f_out->truthy, truthy)) {
			// Shouldn't happen for det!
			MYCERR|=MYC_ERR_DETNONDET;
		}
	} else {
		if(NULL==w) {
			MYCERR|=MYC_ERR_UNDEFWORLD;
		} else {
			Fact* ff=malloc(sizeof(Fact));
			ff->pred=p;
			ff->hash=hash;
			ff->truthy=truthy;
			FactTree* ft=malloc(sizeof(FactTree));
			ft->children=NULL;
			ft->item=ff;
			if(NULL==f) {
					Predicate* pred=malloc(sizeof(Predicate));
					pred->pred=p;
					pred->def=NULL;
					pred->facts=ft;
					PredicateLookupTree plt=malloc(sizeof(PredicateLookupTree));
					plt->children=NULL;
					plt->item=pred;
					if(NULL==w->item) {
						w->item=pred;
						free(plt);
					} else {
						int x=strcmp(w->item->pred->name, p->name);
						if(0==x) x=(w->item->pred->length)-(p->length);
						if(0==x) {
							free(plt);
							w->item->facts=ft;
						} else {
							if(NULL==w->children) {
								w->children=malloc(sizeof(PredicateLookupTree*)*2);
								w->children[0]=NULL; w->children[1]=NULL;
							}
							if(x>0) {
								w->children[0]=plt;
							} else w->children[1]=plt;
						}
					}
			} else {
				int x=strcmp(f->item->hash, hash);
				if(NULL==f->children) {
					f->children=malloc(sizeof(FactTree*)*2);
					f->children[0]=NULL; f->children[1]=NULL;
				}
				if(x>0) {
					f->children[0]=ft;
				} else f->children[1]=ft;
			}
		}
	}
}
/* Take an arglist and produce a hash */
char* hashList(ArgList* list) {
	ArgList* l = list;
	char* hash="";
	char* tmp=NULL;
	char* tmp2=NULL;
	int hashSize=0;
	int itemLen;
	do {
		if(tmp!=NULL) {
			free(tmp);
		}
		if(tmp2!=NULL) {
			free(tmp2);
		}
		/* Just consider the ptr to be a string */
		itemLen=l->item->length;
		tmp=(char*)malloc(itemLen+1);
		memcpy(tmp, l->item->ptr, itemLen);
		*(tmp+itemLen+1)=(char)0;
		/* In order to prevent our fake string from being tricked by null terminators, invert the bits for zeros */
		for(int i=0; i<=itemLen; i++) {
			if((char)0 == tmp[i]) {
				tmp[i]=(char)255;
			}
		}
		
		/* Create a new hash out of the concatenation of the old hash and the new value */
		tmp2=malloc(hashSize+itemLen+1);
		memcpy(tmp2, hash, hashSize+1);
		strncat(tmp2, tmp, hashSize+itemLen+1);
		hash=crypt(tmp2, "$1$");
		
		/* Swap out & allocate space for our hash */
		hashSize=strlen(hash);
		if(hashSize>strlen(tmp2)) {
			free(tmp2);
			tmp2=malloc(hashSize+1);
		}
		strcpy(tmp2, hash);
		hash=malloc(hashSize+1);
		strcpy(hash, tmp2);

		l=l->next;
	} while (l!=NULL)
	return hash;
}
/* Dumb function to get the length of a list */
int listSize(ArgList* list) {
	ArgList* l = list;
	int i=0; 
	while(l!=NULL) { 
		l=l->next; i++;
	} 
	return i;
}
CompositeTruthVal* performPLBoolean(CompositeTruthVal* p, CompositeTruthVal* q, int operation) {
	CompositeTruthVal* result=malloc(sizeof(CompositeTruthValue));
	if (operation) { // AND
		result->truth=p->truth*q->truth;
		result->confidence=p->confidence*q->confidence;
	} else { // OR
		result->truth=(p->truth*p->confidence)+(q->truth*q->confidence)-(p->truth*q->truth);
		if (p->confidence>q->confidence)
			result->confidence=q->confidence;
		else
			result->confidence=p->confidence;
	}
	return result;
}

/* Just allocate a new PredID structure and fill it in */
PredID* createPredID(char* pname, int arity) {
	PredID* ret = malloc(sizeof(PredID));
	ret->pname=pname;
	ret->arity=arity;
	return ret;
}

/* Mostly for interaction between foreign/C types and native types */
Argument* createArg(int type, int length, void* ptr) {
	Argument* ret = malloc(sizeof(Argument));
	ret->type=type; ret->length=length; ret->ptr=ptr;
	return ret;
}
Argument* createDC() {
	return createArg(MYC_TYPE_DC, 0, NULL);
}
Argument* createInt(int x) {
	int* ptr=malloc(sizeof(int));
	(*ptr)=x;
	return createArg(MYC_TYPE_INT, sizeof(int), ptr);
}
Argument* createString(char* x) {
	return createArg(MYC_TYPE_STR, strlen(x), x);
}
Argument* createStringSafe(char* x, int length) {
	return createArg(MYC_TYPE_STR, length, x);
}
Argument* createFloat(float x) {
	float* ptr=malloc(sizeof(float));
	(*ptr)=x;
	return createArg(MYC_TYPE_FLOAT, sizeof(float), x);
}
Argument* createTruth(CompositeTruthVal* x) {
	return createArg(MYC_TYPE_TRUTH, sizeof(CompositeTruthVal), x);
}
Argument* createPred(PredID* x) {
	return createArg(MYC_TYPE_PRED, sizeof(PredID), x);
}
Argument* createForeignFunction(MycForeignFunction x) {
	return createArg(MYC_TYPE_FN, sizeof(MycForeignFunction), x);
}
Argument* createList(ArgList* x) {
	return createArg(MYC_TYPE_LIST, sizeof(ArgList), x);
}
int isDC(Argument* x) {
	return ((MYC_TYPE_DC == x.type)?1:0);
}
int isInt(Argument* x) {
	return ((MYC_TYPE_INT == x.type)?1:0);
}
int isString(Argument* x) {
	return ((MYC_TYPE_STR == x.type)?1:0);
}
int isFloat(Argument* x) {
	return ((MYC_TYPE_FLOAT == x.type)?1:0);
}
int isTruth(Argument* x) {
	return ((MYC_TYPE_TRUTH == x.type)?1:0);
}
int isPred(Argument* x) {
	return ((MYC_TYPE_PRED == x.type)?1:0);
}
int isForeignFunction(Argument* x) {
	return ((MYC_TYPE_FN == x.type)?1:0);
}
int isList(Argument* x) {
	return ((MYC_TYPE_LIST == x.type)?1:0);
}
int getDC(Argument* x) {
	return 0;
}
int getInt(Argument* x) {
	return *((int*)(x->ptr));
}
char* getString(Argument* x) {
	return (char*)(x->ptr);
}
float getFloat(Argument* x) {
	return *((float*)(x->ptr));
}
CompositeTruthVal* getTruth(Argument* x) {
	return (CompositeTruthVal*)(x->ptr);
}
PredID* getPred(Argument* x) {
	return (PredID*)(x->ptr);
}
MycForeignFunction getForeignFunction(Argument* x) {
	return (MycForeignFunction)(x->ptr);
}
ArgList* getList(Argument* x) {
	return (ArgList*)(x->ptr);
}
Argument* getListItem(ArgList* list, int i) {
	ArgList* l=list;
	do {
		l=l->next;
		if(NULL==l) return NULL;
	} while (i--);
	return l->item;
}
void setListItem(ArgList* list, int i, Argument* a) {
	ArgList* l=list;
	ArgList* tmp;
	do {
		if(NULL==l->next) {
			tmp=malloc(sizeof(ArgList));
			tmp->next=NULL;
			tmp->item=NULL;
			l->next=tmp;
		}
		l=l->next;
	} while (i--)
	l->item=a;
}

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
		if(NULL==p_out) 			return ret;
		if(NULL==p_out->defs) 			return ret;
		if(NULL==p_out->defs->children) 	return ret;
		if(NULL==p_out->defs->children[0]) 	return ret;
		if(NULL==p_out->defs->children[1]) {
			ret=executePredicatePA(world, p_out->defs->children[0], translateArgList(a, p_out->defs->conversions[0]));
		} else 	ret=
			performPLBoolean(executePredicatePA(world, p_out->defs->children[0], translateArgList(a, p_out->defs->conversions[0])), 
				executePredicatePA(world, p_out->defs->children[1], translateArgList(a, p_out->defs->conversions[1])),
				p_out->defs->andOr);
		if(MYC_ERR_NOERR!=MYCERR) {
			ret->truth=0; ret->confidence=0;
			if(NULL==MYCERR_STR) MYCERR_STR=error_string(MYCERR);
			char* tmp=malloc(1024+strlen(p->name)+strlen(MYCERR_STR));
			sprintf(tmp, "%s at %s/%d\n", MYCERR_STR, p->name, p->arity);
			free(MYCERR_STR);
			MYCERR_STR=tmp;
		}
		return ret;
	}
}
CompositeTruthVal* executePredicateNIA(PredicateLookupTree* world, char* pname, int arity, ArgList* a); {
	return executePredicatePA(world, createPredID(pname, arity), a);
}
CompositeTruthVal* executePredicateNA(PredicateLookupTree* world, char* pname, ArgList* a); {
	 return executePredicateNIA(world, pname, listSize(a), a);
}
char* error_string(int code) {
	switch(code) {
		case MYC_ERR_NOERR: return "No error.";
		case MYC_ERR_DETNONDET: return "Predicate marked determinate has indeterminate results.";
		case MYC_ERR_UNDEFWORLD: return "World undefined -- no predicates found.";
	}
	return "FIXME unknown/undocumented error.";
}

