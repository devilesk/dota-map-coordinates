%{

var valueHandler = function (type, value) {
    if (type.endsWith('_array')) {
        var arrayType = type.substring(0, type.length - 6);
        return value.map(function (v) { return valueHandler(arrayType, v); });
    }
    else if (type.startsWith('vector')) {
        return value.split(" ").map(function (v) { return parseFloat(v); });
    }
    else {
        switch (type) {
            case "float":
                return parseFloat(value);
            break;
            case "int":
                return parseInt(value);
            break;
            case "bool":
                return !!parseInt(value);
            break;
            case "color":
                return value.split(" ").map(function (v) { return parseInt(v); });
            break;
            case "qangle":
                return value.split(" ").map(function (v) { return parseFloat(v); });
            break;
            case "CDmePolygonMesh":
            case "CDmePolygonMeshDataArray":
            case "CDmePolygonMeshSubdivisionData":
            case "DmePlugList":
            case "EditGameClassProps":
            case "element":
            case "elementid":
            case "string":
            case "uint64":
            case "binary":
                return value;
            break;
            default:
                //console.log('unhandled', type, value);
                return value;
            break;
        }
    }
}

%}

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
        { $object.key = $string; $$ = $object; }
    ;

object
    : LBRACE properties RBRACE
        { $$ = $properties; }
    | LBRACE RBRACE
        { $$ = {}; }
    ;

properties
    : property
        { $$ = $1; }
    | property properties
        {
            for (var i in $2) {
                if ($1.hasOwnProperty(i)) {
                    $1[i] = ($1[i] || []).concat($2[i]);
                }
                else {
                    $1[i] = $2[i];
                }
            }
            $$ = $1;
        }
    ;

property
    : string string value
        { $$ = {}; $$[$1] = {type: $2, values: valueHandler($2, $value)}; }
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
    | string string
        { $$ = {}; $$[$1] = $2; }
    | keyvalue
        { $$ = $1; }
    ;
    
string
    : STRING
        { $$ = $1.substring(1, $1.length - 1); }
    ;