#ifndef MYCROFT_LIST_H
#define MYCROFT_LIST_H

/* Take an arglist and produce a hash */
char* hashList(ArgList* list);
/* Dumb function to get the length of a list */
int listSize(ArgList* list); 

ArgList* getList(Argument* x);
Argument* getListItem(ArgList* list, int i);
void setListItem(ArgList* list, int i, Argument* a);

#endif
