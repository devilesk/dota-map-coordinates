%lex
%%

"<!--".*?"-->"  { return 'HEADER'; }
\s*\n\s*  {/* ignore */}
\"[a-z-_A-Z0-9. \/,:]*\"  { return 'STRING'; }
\s+ {/* ignore */}
","   { return 'COMMA'; }
\{   { return 'LBRACE'; }
\}   { return 'RBRACE'; }
\[   { return 'LBRACKET'; }
\]   { return 'RBRACKET'; }
<<EOF>>   { return 'EOF'; }
/lex

%%

file
    : HEADER keyvalues EOF
        { console.log(JSON.stringify($2)); return $2; }
    | keyvalues EOF
        { console.log(JSON.stringify($1)); return $1; }
    ;

keyvalues
    : keyvalue
        { $$ = [$1]; }
    | keyvalue keyvalues
        { $$ = [$1].concat($2); }
    ;

keyvalue
    : string object
        { $$ = {key: $string, values: $object}; }
    ;

object
    : LBRACE properties RBRACE
        { $$ = $properties; }
    | LBRACE RBRACE
        { $$ = []; }
    ;

properties
    : property
        { $$ = [$1]; }
    | property properties
        { $$ = [$1].concat($2); }
    ;

property
    : string string value
        { $$ = {key: $1, _type: $2, values: $value}; }
    ;

value
    : string
        { $$ = $1; }
    | array
        { $$ = $1; }
    | object
        { $$ = $1; }
    ;

array
    : LBRACKET RBRACKET
        { $$ = []; }
    | LBRACKET elements RBRACKET
        { $$ = $2; }
    ;

elements
    : element
        { $$ = [$1]; }
    | element COMMA elements
        { $$ = [$1].concat($3); }
    ;

element
    : string
        { $$ = $1; }
    | keyvalue
        { $$ = $1; }
    ;
    
string
    : STRING
        { $$ = $1.substring(1, $1.length - 1); }
    ;