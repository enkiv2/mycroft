#include "mycroft.h"

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
