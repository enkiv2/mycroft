#ifndef MYCROFT_ERR_H
#define MYCROFT_ERR_H

extern int MYCERR;
extern char* MYCERR_STR;
#define MYC_ERR_NOERR 0
#define MYC_ERR_DETNONDET 1
#define MYC_ERR_UNDEFWORLD 2

char* error_string(int code);

#endif
