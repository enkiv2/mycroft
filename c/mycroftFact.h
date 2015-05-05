#ifndef MYCROFT_FACT_H
#define MYCROFT_FACT_H

/* Return 0 if a fact does not exist; set f_out to it and return 1 if it does. 
 * If the predicate exists, set p_out to that pred.
 * Developers are strongly encouraged to set p_out and f_out to NULL before running the function
 * Even if the pred is not found, w will be set to the pred tree that would be its parent; likewise for f and facts
 */
int factExists_r(PredicateLookupTree* world, PredID* p, char* hash, Predicate* p_out, Fact* f_out, PredicateLookupTree* w, FactTree* f);
int factExists(PredicateLookupTree* world, PredID* p, char* hash, Predicate* p_out, Fact* f_out);
void insertFact(PredicateLookupTree* world, PredID* p, char* hash, CompositeTruthVal* truthy);

#endif
