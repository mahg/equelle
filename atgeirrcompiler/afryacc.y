%token COLLECTION
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
%token <str> BUILTIN
%token <str> ID
%token <str> INT
%token <str> FLOAT
%token <str> COMMENT
%token LEQ
%token GEQ
%token EQ
%token NEQ
%token RET
%token EOL

%type <node> program
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
%type <node> function_call
%type <node> f_call_args
%type <node> fbody


%output "afryacc.cpp"
%defines "afryacc.hpp"

%start program
%error-verbose

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
#include "Parser.hpp"
}

%union{
    NodePtr node;
    TypeNodePtr type;
    VarDeclNode* vardecl;
    FuncTypeNodePtr ftype;
    FuncArgsDeclNode* fargdecl;
    std::string* str;
}


%%

program: program line           { $$ = new Node(); }
       |                        { $$ = new Node(); }
       ;

line: statement EOL             { $$ = $1; }
    | statement COMMENT EOL     { $$ = $1; }
    | COMMENT EOL               { $$ = 0; }
    | EOL                       { $$ = 0; }
    ;

fbody: '{' EOL program '}'      { $$ = new Node(); }

statement: declaration          { $$ = new Node(); }
         | f_declaration        { $$ = new Node(); }
         | assignment           { $$ = new Node(); }
         | comb_decl_assign     { $$ = new Node(); }
         | function_call        { $$ = new Node(); }
         | RET expr             { $$ = new Node(); }
;

declaration: ID ':' type_expr  { $$ = handleDeclaration(*($1), $3); delete $1; }

f_declaration: ID ':' f_type_expr  { $$ = handleFuncDeclaration(*($1), $3); delete $1; }

assignment: ID '=' expr   { $$ = new VarAssignNode(*($1), $3); delete $1; }
          | ID '(' f_call_args ')' '=' fbody  { $$ = new FuncAssignNode(*($1), $3, $6); delete $1; }
          ;

comb_decl_assign: ID ':' type_expr '=' expr  { $$ = handleDeclarationAssign(*($1), $3, $5); delete $1; }

expr: number              { $$ = $1; }
    | function_call       { $$ = $1; }
    | '(' expr ')'        { $$ = $2; }
    | '|' expr '|'        { $$ = new NormNode($2); }
    | expr '/' expr       { $$ = new BinaryOpNode(Divide, $1, $3); }
    | expr '*' expr       { $$ = new BinaryOpNode(Multiply, $1, $3); }
    | expr '-' expr       { $$ = new BinaryOpNode(Subtract, $1, $3); }
    | '-' expr %prec UMINUS  { $$ = new UnaryNegationNode($2); }
    | expr '+' expr       { $$ = new BinaryOpNode(Add, $1, $3); }
    | expr '?' expr ':' expr %prec '?' { $$ = new TrinaryIfNode($1, $3, $5); }
    | expr ON expr        { $$ = new OnNode($1, $3); }
    | ID                  { $$ = new VarNode(*($1)); delete $1; }
    ;

type_expr: basic_type                                      { $$ = $1; }
         | COLLECTION OF basic_type                        { $$ = handleCollection($3,  0,  0); }
         | COLLECTION OF basic_type ON expr                { $$ = handleCollection($3, $5,  0); }
         | COLLECTION OF basic_type SUBSET OF expr         { $$ = handleCollection($3,  0, $6); }
         | COLLECTION OF basic_type ON expr SUBSET OF expr { $$ = handleCollection($3, $5, $8); }
         ;

f_type_expr: FUNCTION '(' f_decl_args ')' RET type_expr      { $$ = handleFuncType($3, $6); }

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

function_call: BUILTIN '(' f_call_args ')'  { $$ = new FuncCallNode(*($1), $3); delete $1; }
             | ID '(' f_call_args ')'       { $$ = new FuncCallNode(*($1), $3); delete $1; }
             ;

f_call_args: f_call_args ',' expr     { $$ = new Node(); }
           | expr                     { $$ = new Node(); }
           |                          { $$ = new Node(); }
           ;

%%

void yyerror(const char* err)
{
    std::cerr << "Parser error on line " << yylineno << ": " << err << std::endl;
}
