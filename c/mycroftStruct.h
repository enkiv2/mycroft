#ifndef MYCROFT_STRUCT_H
#define MYCROFT_STRUCT_H

/* We use prolog-style identifiers: pred/arity
 *  ex: 
 *   foo(Bar, Baz) 		->	foo/2
 *   foo(Bar, Baz, Quux) 	-> 	foo/3
 */
typedef struct {
	char* name;
	unsigned int arity;
} PredID;

/* We use PLN-style truth values: <Truth, Confidence>
 * <DC, 0> (any truth, no confidence) is equivalent to <0, 0>
 * <A, B> or  <C, D> => <AB+CD-(AC), min(BD)>
 * <A, B> and <C, D> => <AC, BD>
 * Although we use ints here, we actually are considering each component
 * to be implicitly a ratio over MAXINT.
 */
typedef struct {
	unsigned int truth;
	unsigned int confidence;
} CompositeTruthVal;

#define MYC_TYPE_DC	0
#define MYC_TYPE_INT	1
#define MYC_TYPE_STR	2			/* char* */
#define MYC_TYPE_FLOAT	4
#define MYC_TYPE_TRUTH	5			/* CompositeTruthVal */
#define MYC_TYPE_PRED	6
#define MYC_TYPE_FN	7			/* Foreign function */
#define MYC_TYPE_LIST	8			/* ArgList */
typedef struct {
	unsigned int type;			/* MYC_TYPE_something */
	unsigned int length;			/* number of bytes */
	void* ptr;
} Argument;

/* Any list is an ArgList, not just the arg lists to preds!
 */
typedef struct ArgList_t {
	Argument* item;
	struct ArgList_t* next;
} ArgList;

typedef Argument* (*MycForeignFunction)(ArgList*);


/* Parallel arrays specify conversion between arg numbers.
 * For instance, to represent:
 * 	foo(Bar, Baz, Quux) :- bar(Baz, Bar)
 * We end up with a conversion like:
 * 	length=2
 * 	p1args={0, 1}
 *	p2args={1, 0}
 * Unused args are simply omitted.
 * Args whose numbers are greater than the arity of the parent are used between
 * children for unification (and are treated like args given to the parent as
 * a DC/_ value) but, on the parser level, cannot be specified.
 */
typedef struct {
	unsigned int length;
	unsigned int* p1args;			/* The arg numbers for the parent */
	unsigned int* p2args;			/* The arg numbers for the child  */
} ArityConversion;

typedef struct {
	ArityConversion** correspondences;	/* Two sets of correspondences: one between the parent and each child */
	unsigned int andOr; 			/* Boolean: 0 -> OR, otherwise AND */
	PredID* parent;
	PredID** children;			/* Exactly two children */
	unsigned int isDet; 			/* Is this function noted as determinate? i.e., do we memoize it? */
} PredDefinitionTree;


/* 
 */
typedef struct {
	PredID* pred;
	char* hash;
	CompositeTruthVal* truthy;
} Fact;

/* Lookup tree for facts matching a particular predicate ID... For the sake of simplicity, let's do a binary tree sorted on item->hash
 */
typedef struct FactTree_t {
	Fact* item;
	struct FactTree_t** children; 			/* If children=NULL, we have no children; otherwise, we have an array of exactly two children */
} FactTree;

typedef struct {
	PredID* pred;
	PredDefinitionTree* def;
	FactTree* facts;			/* facts=NULL unless we have already determined some results */
} Predicate;

/* Lookup tree for whole predicates. Use just like FactTree.
 */
typedef struct PredicateLookupTree_t {
	Predicate* item;
	struct PredicateLookupTree_t** children;
} PredicateLookupTree;

/**************************************************************************************
 * Functions                                                                          *
 **************************************************************************************/

int cmpPredID(PredID* x, PredID* y);
int cmpTruth(CompositeTruthVal* x, CompositeTruthVal* y);


CompositeTruthVal* performPLBoolean(CompositeTruthVal* p, CompositeTruthVal* q, int operation); 
/* Just allocate a new PredID structure and fill it in */
PredID* createPredID(char* pname, int arity);
/* Mostly for interaction between foreign/C types and native types */
Argument* createArg(int type, int length, void* ptr);
Argument* createDC();
Argument* createInt(int x);
Argument* createString(char* x);
Argument* createStringSafe(char* x, int length);
Argument* createFloat(float x);
Argument* createTruth(CompositeTruthVal* x);
Argument* createPred(PredID* x);
Argument* createForeignFunction(MycForeignFunction);
Argument* createList(ArgList* x);
int isDC(Argument* x);
int isInt(Argument* x);
int isString(Argument* x);
int isFloat(Argument* x);
int isTruth(Argument* x);
int isPred(Argument* x);
int isForeignFunction(Argument* x);
int isList(Argument* x);
int getDC(Argument* x);
int getInt(Argument* x);
char* getString(Argument* x);
float getFloat(Argument* x);
CompositeTruthVal* getTruth(Argument* x);
PredID* getPred(Argument* x);
MycForeignFunction getForeignFunction(Argument* x);

char* arg2String(Argument* x);

#ifdef experimental_bison
Argument* buildTruth(float t, float c);
PredID* buildPredInfo(PredID* p, int isDet);
PredID* buildPredIDNoArgs(PredID* p, CompositeTruthVal* t);
PredID* insertTruthy(PredID* p, CompositeTruthVal* t);
PredID* buildAnonymousFact(CompositeTruthVal* t);
PredID* buildFact(PredID* p);
PredID* definePred(PredID* p, PredID* q);
PredID* buildAND(PredID* p, PredID* q);
PredID* buildOR(PredID* p, PredID* q);
ArgList* buildList(Argument* a);
ArgList* appendList(ArgList* list, Argument* a);
#endif

#endif
