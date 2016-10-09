
/* GDB/MI parser. */

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
        {$$ = $1.concat([$2])}
    |
        {$$ = []}
    ;

record
    : result_record
    | async_record
    | stream_record
    ;

result_record
    : opt_token CARROT result_class
        {$$ = {token: $1, cls:$3}}
    | opt_token CARROT result_class COMMA result_list
        {$$ = {token: $1, cls:$3, results: $5}}
    ;

async_record
    : opt_token async_record_class async_class
        {$$ = {token: $1, cls: $2, rcls: $3, results: []}}
    | opt_token async_record_class async_class COMMA result_list
        {$$ = {token: $1, cls: $2, rcls: $3, results: $5}}
    | opt_token async_record_class async_class COMMA BRACE_OPEN result_list BRACE_CLOSE
        {$$ = {token: $1, cls: $2, rcls: $3, results: $6}}
    ;

async_record_class
    : ASTERISC
        {$$ = 'EXEC'}
    | PLUS
        {$$ = 'STATUS'}
    | EQUALS
        {$$ = 'NOTIFY'}
    ;

result_class: STRING;

async_class: STRING;

result_list
    : result
        {$$ = {}; $$[$1.key] = $1.value;}
    | result_list COMMA result
        {$$ = $1; $$[$3.key] = $3.value;}
    ;

result
    : variable EQUALS value
        {$$ = {key:$1, value:$3}}
    ;

variable
    : STRING
    ;

value_list
    : value
        {$$ = []}
    | value_list COMMA value
        {$$ = $1.concat($3)}
    ;

value
    : CSTRING
    | tuple
    | list
    ;

tuple
    : BRACE_OPEN BRACE_CLOSE
        {$$ = {}}
    | BRACE_OPEN result_list BRACE_CLOSE
        {$$ = $2}
    ;

list
    : BRACKET_OPEN BRACKET_CLOSE
        {$$ = []}
    | BRACKET_OPEN value_list BRACKET_CLOSE
        {$$ = $2}
    | BRACE_OPEN value_list BRACE_CLOSE
        {$$ = $2}
    | BRACKET_OPEN result_list BRACKET_CLOSE
        {$$ = $2}
    ;

stream_record
    : stream_record_class CSTRING
        {$$ = {cls: $1, "cstring": $2}}
    ;

stream_record_class
    : TILDA
        {$$ = 'CONSOLE'}
    | AT
        {$$ = 'TARGET'}
    | AMPERSAND
        {$$ = 'LOG'}
    ;

opt_token
    :
    | token
    ;

token: INTEGER;
