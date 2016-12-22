%lex
%%

"<!--".*?"-->"  { return 'HEADER'; }
\s*\n\s*  {/* ignore */}
\"[a-z-_A-Z0-9.\/,:$\s\(\)]*\"  { return 'STRING'; }
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
    | keyvalues EOF
    ;

keyvalues
    : keyvalue
    | keyvalue keyvalues}
    ;

keyvalue
    : string object
    ;

object
    : LBRACE properties RBRACE
    | LBRACE RBRACE
    ;

properties
    : property
    | property properties
    ;

property
    : string string value
    ;

value
    : string
    | array
    | object
    ;

array
    : LBRACKET RBRACKET
    | LBRACKET elements RBRACKET
    ;

elements
    : element
    | element COMMA elements
    ;

element
    : string
    | string string
    | keyvalue
    ;
    
string
    : STRING
    ;