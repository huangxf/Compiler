/*
 *  The scanner definition for COOL.
 */

/*
 *  Stuff enclosed in %{ %} in the first section is copied verbatim to the
 *  output, so headers and global definitions are placed here to be visible
 * to the code in the file.  Don't remove anything that was here initially
 */
%{
#include <cool-parse.h>
#include <stringtab.h>
#include <utilities.h>

/* The compiler assumes these identifiers. */
#define yylval cool_yylval
#define yylex  cool_yylex

/* Max size of string constants */
#define MAX_STR_CONST 1025
#define YY_NO_UNPUT   /* keep g++ happy */

extern FILE *fin; /* we read from this file */

/* define YY_INPUT so we read from the FILE fin:
 * This change makes it possible to use this scanner in
 * the Cool compiler.
 */
#undef YY_INPUT
#define YY_INPUT(buf,result,max_size) \
	if ( (result = fread( (char*)buf, sizeof(char), max_size, fin)) < 0) \
		YY_FATAL_ERROR( "read() in flex scanner failed");

char string_buf[MAX_STR_CONST]; /* to assemble string constants */
char *string_buf_ptr;

int string_buf_index = 0;
int comment_level = 0;

extern int curr_lineno;
extern int verbose_flag;

extern YYSTYPE cool_yylval;

/*
 *  Add Your own definitions here
 */

%}

/*
 * Define names for regular expressions here.
 */

DARROW          =>
DIGITS		[0-9]+

CLASS class|CLASS
ELSE [Ee][Ll][Ss][Ee]
FI [Ff][Ii]
IF [Ii][Ff]
IN [Ii][Nn]
INHERITS [Ii][Nn][Hh][Ee][Rr][Ii][Tt][Ss]
LET [Ll][Ee][Tt]
LOOP [Ll][Oo][Oo][Pp]
POOL [Pp][Oo][Oo][Ll]
THEN [Tt][Hh][Ee][Nn]
WHILE [Ww][Hh][Ii][Ll][Ee]
CASE [Cc][Aa][Ss][Ee]
ESAC [Ee][Ss][Aa][Cc]
OF [Oo][Ff]
NEW [Nn][Ee][Ww]
ISVOID [Ii][Ss][Vv][Oo][Ii][Dd]
ASSIGN <-
NOT not
LE <=
SPACE [ \f\r\t\v]+
QUOTE "
TRUE	     t[rR][uU][eE]
FALSE	     f[aA][lL][sS][eE]
TYPEID	[A-Z][a-zA-Z0-9_]*
OBJECTID [a-z][a-zA-Z0-9_]*
NEWLINE "\n"
SINGLE_OPER [,\.;:\(\)\+\-\*\/\=\{\}\<]
STRING_CONST \"
COMMENT_BEGIN "(*"
COMMENT_END "*)"
SINGLE_LINE_COMMENT "--"




%x STRING_CONST_CONTENT COMMENT_CONTENT SINGLE_LINE_COMMENT_CONTENT
%%
 /*
  *   Single comment
  */
{SINGLE_LINE_COMMENT} {BEGIN(SINGLE_LINE_COMMENT_CONTENT);}
<SINGLE_LINE_COMMENT_CONTENT>"\n" { BEGIN(INITIAL); curr_lineno++; }
<SINGLE_LINE_COMMENT_CONTENT><<EOF>> {
	cool_yylval.error_msg = "EOF in comment";
	return (ERROR);
}
<SINGLE_LINE_COMMENT_CONTENT>. {}

 /*
  *  Nested comments
  */
{COMMENT_BEGIN}	{ BEGIN(COMMENT_CONTENT); comment_level++; }
<COMMENT_CONTENT><<EOF>> {
		cool_yylval.error_msg = "EOF in comment";
		BEGIN(INITIAL);
		return (ERROR);
}
<COMMENT_CONTENT>{COMMENT_BEGIN} { comment_level++; }
<COMMENT_CONTENT>{COMMENT_END}	 { 
		comment_level--;
		if(comment_level == 0) {
		     BEGIN(INITIAL);
		}
}
<COMMENT_CONTENT>. {}
<COMMENT_CONTENT>"\n" { curr_lineno++; }

{COMMENT_END}	   {
	            cool_yylval.error_msg = "(* unmatched";
		    return (ERROR);
}




 /*
  *  The multiple-character operators.
  */
{DARROW}	{ return (DARROW); }
{LE}            { return (LE); }

 
  /*
  * Keywords are case-insensitive except for the values true and false,
  * which must begin with a lower-case letter.
  */

{CLASS}    { return (CLASS); }
{ELSE}     { return (ELSE);  }
{FI} 	   { return (FI);    }
{IF} 	   { return (IF);    }
{IN}       { return (IN);    }
{INHERITS} { return (INHERITS); }
{LET}      { return (LET); }
{LOOP}     { return (LOOP); }
{POOL}     { return (POOL); }
{THEN}     { return (THEN); }
{WHILE}    { return (WHILE); }
{CASE}     { return (CASE); }
{ESAC}     { return (ESAC); }
{OF}       { return (OF);   }
{NEW}      { return (NEW);  }
{ISVOID}   { return (ISVOID); }
{TRUE} { cool_yylval.boolean = true;
	       	 return BOOL_CONST;}
{FALSE} { cool_yylval.boolean = false;
	       	 return BOOL_CONST;}
{NOT}      { return (NOT); }
{TYPEID}   { cool_yylval.symbol = idtable.add_string(yytext);
	     return (TYPEID); }
{OBJECTID} { cool_yylval.symbol = idtable.add_string(yytext);
	     return (OBJECTID); }
{ASSIGN}   { return (ASSIGN); }




{SPACE}    ;
{NEWLINE}  { curr_lineno++; }
{SINGLE_OPER} { return yytext[0]; }
{STRING_CONST} { BEGIN(STRING_CONST_CONTENT); string_buf_index = 0;}

<STRING_CONST_CONTENT><<EOF>> { 
		cool_yylval.error_msg = "EOF in string constant";
		BEGIN(INITIAL);
		return (ERROR);
}
<STRING_CONST_CONTENT>"\\b" |
<STRING_CONST_CONTENT>"\\t" |
<STRING_CONST_CONTENT>"\\n" |
<STRING_CONST_CONTENT>"\\f" { 
	string_buf[string_buf_index++] = yytext[0];
	string_buf[string_buf_index++] = yytext[1];
}
<STRING_CONST_CONTENT>"\\".	{	    string_buf[string_buf_index++] = yytext[1];
}
<STRING_CONST_CONTENT>"\\\n"	{	    curr_lineno++;

}

<STRING_CONST_CONTENT>"\n" { 
		    cool_yylval.error_msg = "Unterminated string constant";
		    BEGIN(INITIAL);
		    return (ERROR);
}

<STRING_CONST_CONTENT>"\0" {
	            cool_yylval.error_msg = "String contains null character";
		    return (ERROR);
}

<STRING_CONST_CONTENT>\" {
		if(string_buf_index >= MAX_STR_CONST) {
	            cool_yylval.error_msg = "String constant too long";
	            BEGIN(INITIAL);
		    return (ERROR);
		}
		string_buf[string_buf_index++] = 0;
	        BEGIN(INITIAL);
		cool_yylval.symbol = stringtable.add_string(string_buf);
		return (STR_CONST);		 
}
<STRING_CONST_CONTENT>. {
	        string_buf[string_buf_index++] = yytext[0];
}



{DIGITS}        { cool_yylval.symbol = inttable.add_string(yytext);
					return (INT_CONST); }

 /*
  *  String constants (C syntax)
  *  Escape sequence \c is accepted for all characters c. Except for 
  *  \n \t \b \f, the result is c.
  *
  */

.	{ cool_yylval.error_msg = yytext;
            return (ERROR); }

%%