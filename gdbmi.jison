
/* description: GDB/MI parser. */

%lex

DIGIT                       [0-9]
IDENTIFIER                  [a-zA-Z][a-zA-Z0-9_-]*

%%
"^"                return 'CARROT';
","                return 'COMMA';
"+"                return 'PLUS';
"*"                return 'ASTERISC';
"="                return 'EQUALS';
"~"                return 'TILDA';
"@"                return 'AT';
"&"                return 'AMPERSAND';
"["                return 'BRACKET_OPEN';
"]"                return 'BRACKET_CLOSE';
"{"                return 'BRACE_OPEN';
"}"                return 'BRACE_CLOSE';
"(gdb)"            return 'PROMPT';

\n                 return 'NEWLINE';
\r\n               return 'NEWLINE';
\r                 return 'NEWLINE';

\s                 /* skip whitespace */

{DIGIT}+           return 'INTEGER';
{IDENTIFIER}       return 'STRING';

\"(\\.|[^\\"])*\"  return 'CSTRING';

/lex

%%

opt_record_list
    : opt_record_list PROMPT NEWLINE
    | opt_record_list record NEWLINE
    |
    ;

record
    : result_record
    | async_record
    | stream_record
    ;

result_record
    : opt_token CARROT result_class
    | opt_token CARROT result_class COMMA result_list
    ;

async_record
    : opt_token async_record_class async_class
    | opt_token async_record_class async_class COMMA result_list
    | opt_token async_record_class async_class COMMA BRACE_OPEN result_list BRACE_CLOSE
    ;

async_record_class
    : ASTERISC
    ;

async_record_class
    : PLUS
    | EQUALS
    ;

result_class: STRING;

async_class: STRING;
result_list
    : result
    ;

result_list
    : result_list COMMA result
    ;

result
    : variable EQUALS value
    ;

variable
    : STRING
    ;

value_list
    : value
    | value_list COMMA value
    ;

value
    : CSTRING
    | tuple
    | list
    ;

tuple
    : BRACE_OPEN BRACE_CLOSE
    | BRACE_OPEN result_list BRACE_CLOSE
    ;

list
    : BRACKET_OPEN BRACKET_CLOSE
    | BRACKET_OPEN value_list BRACKET_CLOSE
    | BRACE_OPEN value_list BRACE_CLOSE
    | BRACKET_OPEN result_list BRACKET_CLOSE
    ;

stream_record: stream_record_class CSTRING;

stream_record_class
    : TILDA
    | AT
    | AMPERSAND
    ;

opt_token
    :
    | token
    ;

token: INTEGER;
