#include "mycroft.h"
#include <string.h>
#include <crypt.h>
#include <stdlib.h>
#include <stdio.h>
#include <stdarg.h>

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
