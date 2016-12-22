%lex

%%
\s*\n\s*  {/* ignore */}
"<!--".*?"-->"  { return 'HEADER'; }
.* { return 'ANY' }

/lex

%%

file
    : HEADER ANY
    ;
    