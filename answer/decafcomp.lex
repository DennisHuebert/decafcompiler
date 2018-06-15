%{
#include "decafast-defs.h"
#include "decafcomp.tab.h"
#include <cstring>
#include <string>
#include <sstream>
#include <iostream>

using namespace std;

int lineno = 1;
int tokenpos = 1;

int intConst(char *s){
	if(s[0] == '0' && (s[1] == 'x' || 'X')){
		int i = 0;
		sscanf(s, "%i", &i);
		return i;
	} 
	else{
		return atoi(s);
	}
}

%}

%%
  /*
    Pattern definitions for all tokens 
  */
var	                       				{ /*cout<<yytext;*/ tokenpos++; return T_VAR; } 
int                        				{ /*cout<<yytext;*/ tokenpos++; return T_INTTYPE; } 
string                     				{ /*cout<<yytext;*/ tokenpos++; return T_STRINGTYPE; } 
bool                       				{ /*cout<<yytext;*/ tokenpos++; return T_BOOLTYPE; }
void 					   				{ /*cout<<yytext;*/ tokenpos++; return T_VOID; }
func                       				{ /*cout<<yytext;*/ tokenpos++; return T_FUNC; }
while                      				{ /*cout<<yytext;*/ tokenpos++; return T_WHILE; }
for                        				{ /*cout<<yytext;*/ tokenpos++; return T_FOR; }
if                         				{ /*cout<<yytext;*/ tokenpos++; return T_IF; }
else                       				{ /*cout<<yytext;*/ tokenpos++; return T_ELSE; }
break                      				{ /*cout<<yytext;*/ tokenpos++; return T_BREAK; }
continue                   				{ /*cout<<yytext;*/ tokenpos++; return T_CONTINUE; }
extern                     				{ /*cout<<yytext;*/ tokenpos++; return T_EXTERN; }
package                    				{ /*cout<<yytext;*/ tokenpos++; return T_PACKAGE; }
return                     				{ /*cout<<yytext;*/ tokenpos++; return T_RETURN; }
true                       				{ /*cout<<yytext;*/ tokenpos++; return T_TRUE; }
false                      				{ /*cout<<yytext;*/ tokenpos++; return T_FALSE; }
null                       				{ /*cout<<yytext;*/ tokenpos++; return T_NULL; }
\+                         				{ /*cout<<yytext;*/ tokenpos++; return T_PLUS; }
-                          				{ /*cout<<yytext;*/ tokenpos++; return T_MINUS; }
\*                         				{ /*cout<<yytext;*/ tokenpos++; return T_MULT; }
\/                        				{ /*cout<<yytext;*/ tokenpos++; return T_DIV; }
%                          				{ /*cout<<yytext;*/ tokenpos++; return T_MOD; }
\|\|                       				{ /*cout<<yytext;*/ tokenpos++; return T_OR; }
&&                         				{ /*cout<<yytext;*/ tokenpos++; return T_AND; }
\.                         				{ /*cout<<yytext;*/ tokenpos++; return T_DOT; }
\{                         				{ /*cout<<yytext;*/ tokenpos++; return T_LCB; }
\(                         				{ /*cout<<yytext;*/ tokenpos++; return T_LPAREN; }
\[                         				{ /*cout<<yytext;*/ tokenpos++; return T_LSB; }
\}                         				{ /*cout<<yytext;*/ tokenpos++; return T_RCB; } 
\)                         				{ /*cout<<yytext;*/ tokenpos++; return T_RPAREN; }
\]                         				{ /*cout<<yytext;*/ tokenpos++; return T_RSB; }
;                          				{ /*cout<<yytext;*/ tokenpos++; return T_SEMICOLON; }
,                          				{ /*cout<<yytext;*/ tokenpos++; return T_COMMA; }
\<\<                       				{ /*cout<<yytext;*/ tokenpos++; return T_LEFTSHIFT; }
\>\>                       				{ /*cout<<yytext;*/ tokenpos++; return T_RIGHTSHIFT; }
==                         				{ /*cout<<yytext;*/ tokenpos++; return T_EQ; }
!=                         				{ /*cout<<yytext;*/ tokenpos++; return T_NEQ; }
>=                         				{ /*cout<<yytext;*/ tokenpos++; return T_GEQ; }
\<=                        				{ /*cout<<yytext;*/ tokenpos++; return T_LEQ; }
=                          				{ /*cout<<yytext;*/ tokenpos++; return T_ASSIGN; }
>                          				{ /*cout<<yytext;*/ tokenpos++; return T_GT; }
\<                         				{ /*cout<<yytext;*/ tokenpos++; return T_LT; }
!                          				{ /*cout<<yytext;*/ tokenpos++; return T_NOT; }
\/\/[^(\n)]*\n             				{ /*cout<<yytext;*/ tokenpos++; /*return T_COMMENT;*/ }
\"([^\\"(\n)]|\\[abtnvfr\\\'\"])*\"     { /*cout<<yytext;*/ tokenpos++; yylval.sval = new string(yytext);return T_STRINGCONSTANT; }
\'(\\[abtnvfr\\\'\"]|[^\\'])\'          { /*cout<<yytext;*/ tokenpos++; yylval.sval = new string(yytext);return T_CHARCONSTANT; }
(0[xX][0-9a-fA-F]+)|([0-9]+)    		{ /*cout<<yytext;*/ tokenpos++; yylval.ival = intConst(yytext); return T_INTCONSTANT; }
[a-zA-Z\_][a-zA-Z\_0-9]*   				{ /*cout<<yytext;*/ tokenpos++; yylval.sval = new string(yytext); return T_ID; } /* note that identifier
pattern must be after all keywords */
\n 										{ /*cout<<yytext;*/ lineno++; }
[\t\r\a\v\b ]+           				{ /*cout<<yytext;*/} /* ignore whitespace */
.                          				{ cerr << "Error: unexpected character in input" << endl; return -1; }

%%

int yyerror(const char *s) {
  cerr << lineno << ": " << s << " at " << yytext << endl;
  return 1;
}

