#include "mycroftErr.h"
int MYCERR;
char* MYCERR_STR;

char* error_string(int code) {
	switch(code) {
		case MYC_ERR_NOERR: return "No error.";
		case MYC_ERR_DETNONDET: return "Predicate marked determinate has indeterminate results.";
		case MYC_ERR_UNDEFWORLD: return "World undefined -- no predicates found.";
	}
	return "FIXME unknown/undocumented error.";
}

