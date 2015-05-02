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
