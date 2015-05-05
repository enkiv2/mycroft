%{
	#include "mycroft.h"
	#include <stdio.h>
	#include <math.h>
	int yylex(void);
	void yyerror(char const*);
%}

%define api.value.type union
%token <double> NUM
%token <operator> ':-' IMPLIES
%left <operator> ',' COMMA
%token <operator> '.' DOT
%token <operator> ';' SEMI
%right <operator> '<' LT
%left <operator> '>' GT
%right <operator> '(' LP
%left <operator> ')' RP
%token <operator> '|' PIPE
%right <operator> 'det' DET
%right <operator> 'nondet' NONDET
%token <operator> 'YES' YES
%token <operator> 'NO' NO
%token <operator> 'DK' DK
%token <operator> '_' DC
%token <symrec*> VAR

%%

input:
	%empty
| input chunk
;

chunk:
	pred
| fact
;

preddef:
	predcall
| predid truthy			{ $$=buildPredIDNoArgs($1, $2); }
| predcall truthy		{ $$=insertTruthy($1, $2); }
|predid				{ $$=buildPredIDNoArgs($1, buildTruth(1.0, 1.0)); }
;

predcall:
	predid arglist		{ $$=buildPredID($1, $2); }
;

preddefexp:
	DET preddef		{ $$=buildPredInfo($2, 1); }
| NONDET preddef		{ $$=buildPredInfo($2, 0); }
| preddef			{ $$=buildPredInfo($1, 0); }
;

fact:
	preddefexp DOT		{ $$=buildFact($1); }
;

pred:
	preddefexp IMPLIES predbody DOT	{ $$=definePred($1, $3); }
;

predbody:
	preditem
| predbody COMMA preditem	{ $$=buildAND($1, $3); }
| predbody SEMI preditem	{ $$=buildOR($1, $3); }
;

preditem:
	truthy			{ $$=buildAnonymousFact($1); }
| predid
| predcall
;

argitem:
	preditem
| str
| NUM				{ $$=createFloat($1); }
| VAR
;

str:
	'"' [^"]* '"'		{ $$=createString($2); }
;

truthy:
	LT NUM COMMA NUM GT	{ $$=buildTruth($2, $4); }
| LT NUM PIPE			{ $$=buildTruth($2, 1.0); }
| PIPE NUM GT			{ $$=buildTruth(1.0, $2); }
| YES				{ $$=buildTruth(1.0, 1.0); }
| NO				{ $$=buildTruth(0.0, 1.0); }
| DK				{ $$=buildTruth(0.0, 0.0); }
;

arglist:
	LP arglistbody RP	{ $$=$2; }
;

arglistbody:
	argitem			{ $$=buildList($1); }
| arglistbody COMMA argitem	{ $$=appendList($1, $3); }
;

