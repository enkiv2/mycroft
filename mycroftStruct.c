#include "mycroft.h"
#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include <stdarg.h>

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

char* arg2String(Argument* x) {
	char* ret;
	if(isDC(x)) return "_";
	if(isInt(x)) {
		ret=malloc(1024);
		snprintf(ret, 1024, "%d", *(x->ptr));
		return ret;
	}
	if(isString(x)) {
		ret=malloc(strlen(x->ptr)+3);
		sprintf(ret, "\"%s\"", x->ptr);
		return ret;
	}
	if(isFloat(x)) {
		ret=malloc(1024);
		snprintf(ret, 1024, "%f", *(x->ptr));
		return ret;
	}
	if(isTruth(x)) {
		ret=malloc(1024);
		CompositeTruthVal* t=(CompositeTruthVal*)(x->ptr);
		if(1.0==t->confidence) {
			if(1.0==t->truth) {
				snprintf(ret, 1024, "YES");
			} else {
				if(0.0==t->truth) {
					snprintf(ret, 1024, "NO");
				} else {
					snprintf(ret, 1024, "<%f|", t->truth);
				}
			}
		} else {
			if(1.0==t->truth) {
				snprintf(ret, 1024, "|%f>", t->confidence);
			} else { 
				if (0.0==t->confidence) {
					snprintf(ret, 1024, "DK");
				} else {
					snprintf(ret, 1024, "<%f,%f>", t->truth, t->confidence);
				}
			}
		}
		return ret;
	}
	if(isPred(x)) {
		PredID* p=(PredID*)(x->ptr);
		int len=strlen(p->name);
		ret=malloc(1024+len);
		snprintf(ret, 1024+len, "%s/%d", p->name, p->arity);
		return ret;
	}
	if(isForeignFunction(x)) {
		ret=malloc(1024);
		snprintf(ret, 1024, "@%x", x->ptr);
		return ret;
	}
	if(isList(x)) {
		ArgList* l=(ArgList*)(x->ptr);
		char* tmp;
		char* tmp2;
		int sl;
		ret=malloc(2);
		tmp2=malloc(2);
		sprintf(ret, "(");
		do {
			tmp=arg2String(l->item);
			sl=strlen(ret);
			if(sl==1) {
				realloc(ret, strlen(tmp)+3);
				sprintf(ret, "(%s", tmp);
			} else {
				sl+=strlen(tmp);
				realloc(ret, sl+3);
				realloc(tmp2, sl);
				strncpy(tmp2, ret, sl);
				snprintf(ret, sl+2, "%s,%s", ret, tmp);
			}
			l=l->next;
		} while(NULL!=l)
		return ret;
	}
	return "FIXME_UNKNOWN_TYPE";
}


#ifdef experimental_bison
PredicateLookupTree interpreterWorld;
int anonymousPredCount=0;
Argument* buildTruth(float t, float c) {
	CompositeTruthVal* x=malloc(sizeof(CompositeTruthVal));
	x->truth=t; x->confidence=c;
	return createTruth(x);
}
PredID* buildPredInfo(PredID* p, int isDet) {
	Predicate* p_out=malloc(sizeof(Predicate));
	Fact* f_out=malloc(sizeof(Fact));
	factExists(&interpreterWorld, p, "", p_out, f_out);
	p_out->def->isDet=isDet;
}
PredID* buildPredIDNoArgs(PredID* p, CompositeTruthVal* t) {
	insertFact(&interpreterWorld, p, "", t);
}
PredID* insertTruthy(PredID* p, CompositeTruthVal* t) {
	return buildAND(p, buildAnonymousFact(t));
}
PredID* buildAnonymousFact(CompositeTruthVal* t) {
	PredID* p=malloc(sizeof(PredID));
	p->name=malloc(1024);
	sprintf(p->name, "__ANONPRED%d", anonymousPredCount++);
	insertFact(&interpreterWorld, p, "", t);
}
PredID* buildFact(PredID* p) {
	insertFact(&interpreterWorld, p, "", buildTruth(1.0, 1.0));
}
PredID* definePred(PredID* p, PredID* q) {
	return buildAND(p, q);
}
PredID* buildY(PredID* p, PredID* q, int andOr) {
	Predicate* p_out=malloc(sizeof(Predicate));
	Fact* f_out=malloc(sizeof(Fact));
	PredicateLookupTree w=malloc(sizeof(PredicateLookupTree));
	FactTree f=malloc(sizeof(FactTree));
	PredID* new=malloc(sizeof(PredID));
	new->name=malloc(1024);
	sprintf(new->name, "__ANONPRED%d", anonymousPredCount++);
	new->arity=0;
	Predicate* newPred=malloc(sizeof(Predicate));
	newPred->pred=new;
	newPred->def=malloc(sizeof(PredicateDefinitionTree));
	newPred->def->children=malloc(sizeof(PredID)*2);
	newPred->def->children[0]=p;
	newPred->def->children[1]=q;
	newPred->def->andOr=andOr;
	newPred->def->correspondences=malloc(sizeof(ArityConversion)*2);
	newPred->def->correspondences[0]->length=0;
	newPred->def->correspondences[1]->length=0;
	factExists(&interpreterWorld, new, "", p_out, f_out, w, f);
	if(NULL==w->item) {
		w->item=newPred;
	} else {
		x=strcmp(w->item->name, new->name);
		if(NULL==w->children) {
			w->children=malloc(sizeof(PredicateLookupTree)*2);
			w->children[0]=NULL;
			w->children[1]=NULL;
		}
		if(x>=0) {
			w->children[0]=newPred;
		} else {
			w->children[1]=newPred;
		}
	}
	return new;
}
PredID* buildAND(PredID* p, PredID* q) {
	return buildY(p, q, 1);
}
PredID* buildOR(PredID* p, PredID* q) {
	return buildY(p, q, 0);
}
ArgList* buildList(Argument* a) {
	ArgList* ret=malloc(sizeof(ArgList));
	ret->next=NULL;
	ret->item=a;
	return ret;
}
ArgList* appendList(ArgList* list, Argument* a) {
	ArgList* l=list;
	while(NULL!=l->next) { l=l->next; }
	l->next=malloc(sizeof(ArgList));
	l=l->next;
	l->next=NULL;
	l->item=a;
	return list;
}
#endif
