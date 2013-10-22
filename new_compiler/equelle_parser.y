%token COLLECTION
%token SEQUENCE
%token OF
%token ON
%token SUBSET
%token SCALAR
%token VECTOR
%token BOOL
%token CELL
%token FACE
%token EDGE
%token VERTEX
%token FUNCTION
%token AND
%token OR
%token NOT
%token XOR
%token TRUE
%token FALSE
%token FOR
%token IN
%token MUTABLE
%token <str> BUILTIN
%token <str> ID
%token <str> INT
%token <str> FLOAT
%token <str> COMMENT
%token <str> STRING_LITERAL
%token LEQ
%token GEQ
%token EQ
%token NEQ
%token RET
%token EOL

%type <seq> program
%type <seq> lineblock
%type <node> line
%type <node> statement
%type <vardecl> declaration
%type <node> f_declaration
%type <node> assignment
%type <node> comb_decl_assign
%type <node> expr
%type <type> type_expr
%type <ftype> f_type_expr
%type <type> basic_type
%type <fargdecl> f_decl_args
%type <node> number
%type <fcall> function_call
%type <farg> f_call_args
%type <seq> block
%type <node> f_startdef
%type <loop> loop_start


%output "equelle_parser.cpp"
%defines "equelle_parser.hpp"

%start program
%error-verbose

%nonassoc MUTABLE
%nonassoc '?'
%nonassoc ON
%left OR
%nonassoc XOR
%left AND
%nonassoc EQ NEQ
%nonassoc LEQ GEQ '<' '>'
%left '+' '-'
%left '*'
%nonassoc '/'
%nonassoc '^'
%nonassoc NOT UMINUS



%code requires{
#include "ParseActions.hpp"
#include <iostream>
}

%union{
    Node* node;
    TypeNode* type;
    VarDeclNode* vardecl;
    FuncTypeNode* ftype;
    FuncArgsNode* farg;
    FuncArgsDeclNode* fargdecl;
    FuncCallNode* fcall;
    SequenceNode* seq;
    LoopNode* loop;
    std::string* str;
}


%%

program: lineblock                { $$ = handleProgram($1); }

lineblock: lineblock line         { $$ = $1; $$->pushNode($2); }
         |                        { $$ = new SequenceNode(); }
         ;

line: statement EOL             { $$ = $1; }
    | statement COMMENT EOL     { $$ = $1; }
    | COMMENT EOL               { $$ = nullptr; }
    | EOL                       { $$ = nullptr; }
    ;

block: '{' EOL lineblock '}'     { $$ = handleBlock($3); }

statement: declaration          { $$ = $1; }
         | f_declaration        { $$ = $1; }
         | assignment           { $$ = $1; }
         | comb_decl_assign     { $$ = $1; }
         | function_call        { $$ = handleFuncCallStatement($1); }
         | RET expr             { $$ = handleReturnStatement($2); }
         | loop_start block     { $$ = handleLoopStatement($1, $2); }
         ;

declaration: ID ':' type_expr  { $$ = handleDeclaration(*($1), $3); delete $1; }

f_declaration: ID ':' f_type_expr  { $$ = handleFuncDeclaration(*($1), $3); delete $1; }

assignment: ID '=' expr       { $$ = handleAssignment(*($1), $3); delete $1; }
          | f_startdef block  { $$ = handleFuncAssignment($1, $2); }
          ;

f_startdef: ID '(' f_call_args ')' '='       { $$ = handleFuncStart(*($1), $3); delete $1; }

comb_decl_assign: ID ':' type_expr '=' expr  { $$ = handleDeclarationAssign(*($1), $3, $5); delete $1; }

expr: number              { $$ = $1; }
    | function_call       { $$ = $1; }
    | '(' expr ')'        { $$ = $2; }
    | '|' expr '|'        { $$ = handleNorm($2); }
    | expr '/' expr       { $$ = handleBinaryOp(Divide, $1, $3); }
    | expr '*' expr       { $$ = handleBinaryOp(Multiply, $1, $3); }
    | expr '-' expr       { $$ = handleBinaryOp(Subtract, $1, $3); }
    | expr '+' expr       { $$ = handleBinaryOp(Add, $1, $3); }
    | '-' expr %prec UMINUS  { $$ = handleUnaryNegation($2); }
    | expr '?' expr ':' expr %prec '?' { $$ = handleTrinaryIf($1, $3, $5); }
    | expr ON expr        { $$ = handleOn($1, $3); }
    | ID                  { $$ = handleIdentifier(*($1)); delete $1; }
    | STRING_LITERAL      { $$ = handleString(*($1)); delete $1; }
    | MUTABLE expr        { $$ = handleMutableExpr($2); }
    ;

type_expr: basic_type                                  { $$ = $1; }
         | COLLECTION OF basic_type                    { $$ = handleCollection($3, nullptr,  nullptr); }
         | COLLECTION OF basic_type ON expr            { $$ = handleCollection($3,      $5,  nullptr); }
         | COLLECTION OF basic_type SUBSET OF expr     { $$ = handleCollection($3, nullptr,       $6); }
         | SEQUENCE OF basic_type                      { $$ = handleSequence($3); }
         | MUTABLE type_expr                           { $$ = handleMutableType($2); }
         ;

f_type_expr: f_starttype '(' f_decl_args ')' RET type_expr      { $$ = handleFuncType($3, $6); }

f_starttype: FUNCTION                                           { handleFuncStartType(); }

basic_type: SCALAR  { $$ = new TypeNode(EquelleType(Scalar)); }
          | VECTOR  { $$ = new TypeNode(EquelleType(Vector)); }
          | BOOL    { $$ = new TypeNode(EquelleType(Bool)); }
          | CELL    { $$ = new TypeNode(EquelleType(Cell)); }
          | FACE    { $$ = new TypeNode(EquelleType(Face)); }
          | EDGE    { $$ = new TypeNode(EquelleType(Edge)); }
          | VERTEX  { $$ = new TypeNode(EquelleType(Vertex)); }
          ;

f_decl_args: f_decl_args ',' declaration { $$ = $1; $$->addArg($3); }
           | declaration                 { $$ = new FuncArgsDeclNode($1); }
           |                             { $$ = new FuncArgsDeclNode(); }
           ;

number: INT                     { $$ = handleNumber(numFromString(*($1))); delete $1; }
      | FLOAT                   { $$ = handleNumber(numFromString(*($1))); delete $1; }
      ;

function_call: BUILTIN '(' f_call_args ')'  { $$ = handleFuncCall(*($1), $3); delete $1; }
             | ID '(' f_call_args ')'       { $$ = handleFuncCall(*($1), $3); delete $1; }
             ;

f_call_args: f_call_args ',' expr     { $$ = $1; $$->addArg($3); }
           | expr                     { $$ = new FuncArgsNode($1); }
           |                          { $$ = new FuncArgsNode(); }
           ;

loop_start: FOR ID IN ID              { $$ = handleLoopStart(*($2), *($4)); delete $2; delete $4; }



%%

void yyerror(const char* err)
{
    std::cerr << "Parser error near line " << yylineno << ": " << err << std::endl;
}