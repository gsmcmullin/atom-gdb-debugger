/* GDB/MI parser. */

%lex

DIGIT                       [0-9]
IDENTIFIER                  [a-zA-Z][a-zA-Z0-9_-]*

%x cstring

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

\s                 /* skip whitespace */

{DIGIT}+           return 'INTEGER';
{IDENTIFIER}       return 'STRING';

\"                      { this.gdbmi_cstring = ""; this.begin('cstring'); }
<cstring>\"             { yytext = this.gdbmi_cstring; this.begin('INITIAL'); return 'CSTRING'; }
<cstring>\n             { throw new Error('Unterminated string'); }
<cstring>\\[0-7]\{1-3\} { this.gdbmi_cstring += parseInt(yytext, 8); }
<cstring>\\[0-9]+       { throw new Error('Invalid escape sequence'); }
<cstring>\\n            { this.gdbmi_cstring += '\n' }
<cstring>\\t            { this.gdbmi_cstring += '\t' }
<cstring>\\r            { this.gdbmi_cstring += '\r' }
<cstring>\\b            { this.gdbmi_cstring += '\b' }
<cstring>\\f            { this.gdbmi_cstring += '\f' }
<cstring>\\(.|\n)       { this.gdbmi_cstring += yytext.slice(1) }
<cstring>[^\\\n\"]+     { this.gdbmi_cstring += yytext }

/lex

%%

all
    : record
        { return $1 }
    | PROMPT
        { return null }
    ;

record
    : result_record
    | async_record
    | stream_record
    ;

result_record
    : opt_token CARROT result_class
        {$$ = {type: 'RESULT', token: $1, cls:$3}}
    | opt_token CARROT result_class COMMA result_list
        {$$ = {type: 'RESULT', token: $1, cls:$3, results: $5}}
    ;

async_record
    : opt_token async_record_class async_class
        {$$ = {type: 'ASYNC', token: $1, cls: $2, rcls: $3, results: {}}}
    | opt_token async_record_class async_class COMMA result_list
        {$$ = {type: 'ASYNC', token: $1, cls: $2, rcls: $3, results: $5}}
    | opt_token async_record_class async_class COMMA BRACE_OPEN result_list BRACE_CLOSE
        {$$ = {type: 'ASYNC', token: $1, cls: $2, rcls: $3, results: $6}}
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
        {
            $$ = $1;
            if ($3.key in $$) {
                if ($$[$3.key].constuctor == Array)
                    $$[$3.key].push($3.value);
                else
                    $$[$3.key] = [$$[$3.key], $3.value];
            } else {
                $$[$3.key] = $3.value;
            }
        }
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
        {
            var keys = Object.keys($2);
            if (keys.length != 1)
                throw new Error('List may only have a single key');
            var key = keys[0];
            if ($2[key].constructor != Array)
                $2[key] = [$2[key]];
            $$ = $2;
        }
    ;

stream_record
    : stream_record_class CSTRING
        {$$ = {type: 'OUTPUT', cls: $1, "cstring": $2}}
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
