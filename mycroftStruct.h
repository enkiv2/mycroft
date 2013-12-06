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
typedef struct {
	Argument* item;
	ArgList* next;
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
	ArityConversion* correspondences;	/* Two sets of correspondences: one between the parent and each child */
	unsigned int andOr; 			/* Boolean: 0 -> OR, otherwise AND */
	PredID* parent;
	PredID* children;			/* Exactly two children */
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
typedef struct {
	Fact* item;
	FactTree* children; 			/* If children=NULL, we have no children; otherwise, we have an array of exactly two children */
} FactTree;

typedef struct {
	PredID* pred;
	PredDefinitionTree* def;
	FactTree* facts;			/* facts=NULL unless we have already determined some results */
} Predicate;

/* Lookup tree for whole predicates. Use just like FactTree.
 */
typedef struct {
	Predicate* item;
	PredicateLookupTree* children;
} PredicateLookupTree;

/**************************************************************************************
 * Functions                                                                          *
 **************************************************************************************/

/* Return 0 if a fact does not exist; set f_out to it and return 1 if it does. 
 * If the predicate exists, set p_out to that pred.
 * Developers are strongly encouraged to set p_out and f_out to NULL before running the function
 */
int factExists(PredicateLookupTree* world, PredID* p, char* hash, Predicate* p_out, Fact* f_out);
/* Take an arglist and produce a hash */
char* hashList(ArgList* l);
/* Dumb function to get the length of a list */
int listSize(ArgList* l); /* i=0; while(l!=NULL) { l=l->next; i++;} return i; */
CompositeTruthValue* performPLBoolean(CompositeTruthValue* p, CompositeTruthValue* q, int operation); /*
	CompositeTruthValue* result=malloc(sizeof(CompositeTruthValue));
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
	return result;*/
/* Just allocate a new PredID structure and fill it in */
PredID* createPredID(char* pname, int arity);
/* Mostly for interaction between foreign/C types and native types */
Argument* createDC();
Argument* createInt(int x);
Argument* createString(char* x);
Argument* createFloat(float x);
Argument* createTruth(CompositeTruthValue* x);
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
CompositeTruthValue* getTruth(Argument* x);
PredID* getPred(Argument* x);
MycForeignFunction getForeignFunction(Argument* x);
ArgList* getList(Argument* x);
/* The core of our system: recursive functions */
CompositeTruthValue* executePredicatePA(PredicateLookupTree* world, PredID* p, ArgList* a); /* 
	char* hash=hashList(a);
	Predicate* p_out=NULL;
	Fact* f_out=NULL;
	if (factExists(world, p, hash, p_out, f_out)) {
		return f_out->truthy;
	} else {
		// translate our args and traverse the predicate definition tree recursively
	}
	*/
CompositeTruthValue* executePredicateNIA(PredicateLookupTree* world, char* pname, int arity, ArgList* a); /* 
	return executePredicatePA(world, createPredID(pname, arity), a); */
CompositeTruthValue* executePredicateNA(PredicateLookupTree* world, char* pname, ArgList* a); /* return executePredicateNIA(world, pname, listSize(a), a); */
#endif

