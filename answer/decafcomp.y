%{
#include <iostream>
#include <ostream>
#include <string>
#include <cstdlib>
#include <list>
#include <vector>
#include "decafast-defs.h"

int yylex(void);
int yyerror(char *); 

// print AST?
bool printAST = false;

#include "decafast.cc"

extern int lineno;

using namespace std;

// this global variable contains all the generated code
//static llvm::Module *TheModule;

// this is the method used to construct the LLVM intermediate code (IR)
//static llvm::IRBuilder<> Builder(llvm::getGlobalContext());
// the calls to getGlobalContext() in the init above and in the
// following code ensures that we are incrementally generating
// instructions in the right order

// dummy main function
// WARNING: this is not how you should implement code generation
// for the main function!
// You should write the codegen for the main method as 
// part of the codegen for method declarations (MethodDecl)
static llvm::Function *TheFunction = 0;

// we have to create a main function f
llvm::Function *gen_main_def() {
  // create the top-level definition for main
  llvm::FunctionType *FT = llvm::FunctionType::get(llvm::IntegerType::get(llvm::getGlobalContext(), 32), false);
  llvm::Function *TheFunction = llvm::Function::Create(FT, llvm::Function::ExternalLinkage, "main", TheModule);
  if (TheFunction == 0) {
    throw runtime_error("empty function block"); 
  }
  // Create a new basic block which contains a sequence of LLVM instructions
  llvm::BasicBlock *BB = llvm::BasicBlock::Create(llvm::getGlobalContext(), "entry", TheFunction);
  // All subsequent calls to IRBuilder will place instructions in this location
  Builder.SetInsertPoint(BB);
  return TheFunction;
}

//void enter_symtbl(string ident, string type, int lineno){
//    syms.enter_symtbl(ident, new descriptor(lineno));
    //cerr << "defined variable: " << ident << ", with type: " << type << ", on line number: " << lineno << endl;
//}

%}

%union{
    class decafAST *ast;
    class StringList *slist;
    std::string *sval;
    int ival;
    char cval;
}


%token T_VAR
%token <sval>T_INTTYPE
%token <sval> T_STRINGTYPE
%token <sval> T_BOOLTYPE
%token <sval> T_VOID
%token T_FUNC
%token T_WHILE
%token T_FOR
%token T_IF
%token T_ELSE
%token T_BREAK
%token T_CONTINUE
%token T_EXTERN
%token T_PACKAGE
%token <ast> T_RETURN
%token T_TRUE
%token T_FALSE
%token T_NULL
%token T_PLUS
%token T_MINUS
%token T_MULT
%token T_DIV
%token T_MOD
%token T_OR
%token T_AND
%token T_DOT
%token T_LCB
%token T_LPAREN
%token T_LSB
%token T_RCB
%token T_RPAREN
%token T_RSB
%token T_SEMICOLON
%token T_COMMA
%token T_LEFTSHIFT
%token T_RIGHTSHIFT
%token T_EQ
%token T_NEQ
%token T_GEQ
%token T_LEQ
%token T_ASSIGN
%token T_GT
%token T_LT
%token T_NOT
%token T_COMMENT
%token <sval> T_STRINGCONSTANT 
%token <sval> T_CHARCONSTANT
%token <ival> T_INTCONSTANT

%token <sval> T_ID

%type <ast> type methodType arrayType externType externs externTypes externTypeList_item externTypeList extern_list decafpackage externDefn typed_symbol var_dec_list booleanOperator unaryOperator unaryNot unaryMinus arithmeticOp methodCall methodArg methodArgList methodArgListItem expr binaryOperator fieldDeclarations fieldDeclarationList fieldDeclarationListItem fieldDeclaration assign assignListItem assignList constant boolConstant block statement varDecls varDecl statements typedSymbol typedSymbols typedSymbolList typedSymbolListItem methodDecls methodDecl methodArgs methodBlock 


%type <slist> idList idList_item 
%type <sval> id stringConstant


%left T_OR
%left T_AND
%left T_EQ T_NEQ T_LT T_LEQ T_GEQ T_GT
%left T_PLUS T_MINUS
%left T_MULT T_DIV T_MOD T_LEFTSHIFT T_RIGHTSHIFT
%left T_NOT
%right UMINUS

%%

start: program

program: externs decafpackage 
    { 
        ProgramAST *prog = new ProgramAST((decafStmtList *)$1, (PackageAST *)$2); 
        if (printAST) {
            cout << getString(prog) << endl;
        }
        try {
            prog -> Codegen();
        } 
        catch (std::runtime_error &e) {
            cout << "semantic error: " << e.what() << endl;
            //cout << prog->str() << endl; 
            exit(EXIT_FAILURE);
        }
        delete prog;
    }
    ;
externs : extern_list {decafStmtList *slist = (decafStmtList*) $1; $$ = slist;}
    |  {decafStmtList *slist = new decafStmtList(); $$ = slist; }
    ;

extern_list: externDefn extern_list { decafStmtList *slist = (decafStmtList*) $2; slist->push_front($1); $$ = slist;}
    |  {decafStmtList *slist = new decafStmtList(); $$ = slist; }
    ;


externDefn: T_EXTERN T_FUNC T_ID T_LPAREN externTypes T_RPAREN methodType T_SEMICOLON
    { 
        string tid_str = $3->c_str();
        MethodTypeAST *mt = (MethodTypeAST*) $7;
        decafStmtList *dsl = (decafStmtList*) $5;

        ExternAST* extDfn = new ExternAST(tid_str, mt, dsl); 
        $$ = extDfn;
    }
    ;
externTypes : externTypeList {$$ = $1;}
	| {decafStmtList *dsl = new decafStmtList(); $$ = dsl;}

externTypeList: externType externTypeList_item { 

        ExternTypeAST *et  = (ExternTypeAST*) $1;
        decafStmtList *dsl = (decafStmtList*) $2;
        dsl->push_front(et);
        $$ = dsl;
    }
    ;

externTypeList_item: T_COMMA externType externTypeList_item { 

        ExternTypeAST *et = (ExternTypeAST*) $2;
        decafStmtList *dsl  = (decafStmtList*) $3;
        dsl->push_front(et);
        $$ = dsl;
     }
     | { decafStmtList *dsl = new decafStmtList(); $$ = dsl; }
    ;

decafpackage: T_PACKAGE T_ID decafpackage_begin fieldDeclarations methodDecls decafpackage_end
    {   $$ = new PackageAST(*$2, (decafStmtList*)$4, (decafStmtList*)$5);
        //delete $2; 
    }
    ;
decafpackage_begin: T_LCB { syms.new_symtbl(); }
    ;
decafpackage_end: T_RCB { syms.remove_symtbl(); }
    ;


/* FIELD DECLARATION */

fieldDeclarations: fieldDeclarationList { decafStmtList *dsl = (decafStmtList*) $1; $$ = dsl; }
    | {decafStmtList *dsl = new decafStmtList(); $$ = dsl; }
    ;

fieldDeclarationList : fieldDeclaration fieldDeclarationList {
       
        decafStmtList *dsl = (decafStmtList*) $2;
        dsl->push_front($1);
        $$ = dsl;
    }
    | {decafStmtList *dsl = new decafStmtList(); $$ = dsl;}
    ;


fieldDeclaration: T_VAR idList type T_SEMICOLON{
       
        decafStmtList *dsl = new decafStmtList();
        string curr_id;
        DecafTypeAST *type = (DecafTypeAST*)$3;
        StringList *sList = (StringList*)$2;
        list<string> idList = sList->getList();
        //idList.push_front(*$2);

        for(list<string>::const_iterator iter = idList.begin(); iter != idList.end(); ++iter){
            curr_id = *iter;
            dsl->push_back(new FieldDeclAST(curr_id, type, new FieldSize()));
            //enter_symtbl(curr_id, type -> str(), lineno);
        }
        $$ = dsl;
    }
    | T_VAR T_ID type T_SEMICOLON{
        
        decafStmtList *dsl = new decafStmtList();
        string curr_id;
        DecafTypeAST *type = (DecafTypeAST*)$3;
        StringList *sList = new StringList();
        list<string> idList = sList->getList();
        idList.push_front(*$2);

        for(list<string>::const_iterator iter = idList.begin(); iter != idList.end(); ++iter){
            curr_id = *iter;
            dsl->push_back(new FieldDeclAST(curr_id, type, new FieldSize()));
            //enter_symtbl(curr_id, type -> str(), lineno);
        }
        $$ = dsl;
    }
	| T_VAR idList arrayType T_SEMICOLON{
        
        decafStmtList *dsl = new decafStmtList();
        string curr_id;
        FieldSize *fs = (FieldSize*) $3;
        DecafTypeAST *type = fs->getType();
        
        list<string> idList = $2->getList();
        for(list<string>::const_iterator iter = idList.begin(); iter != idList.end(); ++iter){
            curr_id = *iter;
            dsl->push_back(new FieldDeclAST(curr_id, type, fs));
            //enter_symtbl(curr_id, type -> str(), lineno);
        }
        $$ = dsl;
        
    }
    | T_VAR T_ID type T_ASSIGN constant T_SEMICOLON { 
        
        string n = *$2;
        DecafTypeAST *t = (DecafTypeAST*) $3;
        Expr *v = (Expr*) $5;
        FieldDeclAST *fd = new FieldDeclAST(n, t, v);
        //enter_symtbl(n, t -> str(), lineno);
        $$ = fd;
    }
    ;

idList: T_ID idList_item { StringList *sl = (StringList*) $2; sl->push_front(*$1); $$ = sl;};

idList_item: T_COMMA T_ID idList_item { StringList *sl = (StringList*) $3; sl->push_front(*$2); $$ = sl; }
	| { StringList *sl = new StringList(); $$ = sl; }
	;

id : T_ID { $$ = $1; }
	;

assignList: assign assignListItem { decafStmtList *dsl = (decafStmtList*) $2; dsl->push_front((Assign*)$1); $$ = dsl; }
	;

assignListItem : T_COMMA assign assignListItem { decafStmtList *dsl = (decafStmtList*) $3; dsl->push_front((Assign*)$2); $$ = dsl; }
    | {decafStmtList *dsl = new decafStmtList(); $$ = dsl; }
	;



assign: T_ID T_ASSIGN expr 
        { Assign *a = new Assign(*$1, (Expr*)$3); 
        //cout << " // using decl on line: " << syms.access_symtbl(*$1) -> lineno; 
        $$ = a; }
	| T_ID T_LSB expr T_RSB T_ASSIGN expr 
        { Assign *a = new Assign(*$1, (Expr*)$3, (Expr*)$6); 
        //cout << " // using decl on line: " << syms.access_symtbl(*$1) -> lineno; 
        $$ = a; } 
	;

/* METHOD DECLARATIONS */

methodDecls: methodDecl methodDecls { decafStmtList *dsl = (decafStmtList*)$2; dsl -> push_front($1); $$ = dsl; }
	| { decafStmtList *dsl = new decafStmtList(); $$ = dsl; }
	;

methodDecl: T_FUNC T_ID T_LPAREN typedSymbols T_RPAREN methodType methodBlock {
	string name = *$2;
	MethodTypeAST *mt = (MethodTypeAST*) $6; // $6;
	decafStmtList *pList = (decafStmtList*) $4;
	MethodBlock *mb = (MethodBlock*)$7;
	MethodDecl *m = new MethodDecl(name, mt, pList, mb); $$ = m;
	}
	;

//methodBlock: T_LCB varDecls statements T_RCB { MethodBlock *mb = new MethodBlock((decafStmtList*)$2, (decafStmtList*)$3); $$ = mb; } 
methodBlock: methodBlock_begin varDecls statements methodBlock_end { MethodBlock *mb = new MethodBlock((decafStmtList*)$2, (decafStmtList*)$3); $$ = mb; }
    ; 

methodBlock_begin: T_LCB { syms.new_symtbl(); }
    ;

methodBlock_end: T_RCB { syms.remove_symtbl(); }
    ;

typedSymbols: typedSymbolList { decafStmtList *dsl = (decafStmtList*)$1;}
	| { decafStmtList *dsl = new decafStmtList(); $$ = dsl;}
	;

typedSymbolList: typedSymbol typedSymbolListItem {
		decafStmtList *dsl = (decafStmtList*)$2; dsl -> push_front((TypedSymbolAST*)$1); $$ = dsl;	
	}
	;

typedSymbolListItem: T_COMMA typedSymbol typedSymbolListItem {
		decafStmtList *dsl = (decafStmtList*)$3; dsl -> push_front($2); $$ = dsl;	
	} 
	| { decafStmtList *dsl = new decafStmtList(); $$ = dsl; }
	;

typedSymbol : T_ID type {
		TypedSymbolAST *t = new TypedSymbolAST(*$1, (DecafTypeAST*)$2); $$ = t;
        DecafTypeAST *d = (DecafTypeAST*)$2;
        //enter_symtbl(*$1, d -> str(), lineno);			
	}	
	;

/*METHOD CALL*/ 
methodCall : T_ID T_LPAREN methodArgs T_RPAREN 
    { MethodCallAST *mc = new MethodCallAST(*$1, (decafStmtList*) $3); $$ = mc; }
	;

methodArgs: methodArgList { decafStmtList *dsl = (decafStmtList*)$1; $$ = dsl; }
		| { decafStmtList *dsl = new decafStmtList(); $$ = dsl; }
		;

methodArgList : methodArg methodArgListItem { 
			decafStmtList *dsl = (decafStmtList*) $2; 
			dsl->push_front((MethodArg*)$1); 
			$$ = dsl;
		}
		;

methodArgListItem : T_COMMA methodArg methodArgListItem { decafStmtList *dsl = (decafStmtList*) $3; dsl->push_front((MethodArg*)$2); $$ = dsl; }
	| { decafStmtList *dsl = new decafStmtList(); $$ = dsl;}
	;

methodArg : stringConstant { string s = *$1; MethodArg *ma = new MethodArg(s); $$ = ma; }
    | expr { MethodArg *ma = new MethodArg((Expr*)$1); $$ = ma; }
    ;
stringConstant: T_STRINGCONSTANT { $$ = $1; }


expr: T_ID { 
        decafStmtList *dsl = new decafStmtList();
        Rvalue *rval = new Rvalue(*$1);
        dsl->push_front(rval);
        Expr *e = new Expr(dsl);
        //cout << " // using decl on line: " << syms.access_symtbl(*$1) -> lineno; 
        $$ = e; 
    }
    | T_ID T_LSB expr T_RSB { 
        decafStmtList *dsl = new decafStmtList();
        Rvalue *rval = new Rvalue(*$1, (Expr*)$3);
        dsl->push_front(rval);
        Expr *e = new Expr(dsl);
        //cout << " // using decl on line: " << syms.access_symtbl(*$1) -> lineno;
        $$ = e; 
    }
    | methodCall 
        { Expr *e = new Expr((MethodCallAST*)$1); $$ = e; }
    | constant 
        { $$ = $1; }
    | expr T_PLUS expr
        { BinaryOperator *ao = new BinaryOperator("+"); Expr *e = new Expr(ao, (Expr*)$1, (Expr*)$3); $$ = e; }
    | expr T_MINUS expr
        { BinaryOperator *ao = new BinaryOperator("-"); Expr *e = new Expr(ao, (Expr*)$1, (Expr*)$3); $$ = e; }
    | expr T_MULT expr
        { BinaryOperator *ao = new BinaryOperator("*"); Expr *e = new Expr(ao, (Expr*)$1, (Expr*)$3); $$ = e; }
    | expr T_DIV expr
        { BinaryOperator *ao = new BinaryOperator("/"); Expr *e = new Expr(ao, (Expr*)$1, (Expr*)$3); $$ = e; }
    | expr T_LEFTSHIFT expr
        { BinaryOperator *ao = new BinaryOperator("<<"); Expr *e = new Expr(ao, (Expr*)$1, (Expr*)$3); $$ = e; }
    | expr T_RIGHTSHIFT expr
        { BinaryOperator *ao = new BinaryOperator(">>"); Expr *e = new Expr(ao, (Expr*)$1, (Expr*)$3); $$ = e; }
    | expr T_MOD expr
        { BinaryOperator *ao = new BinaryOperator("%"); Expr *e = new Expr(ao, (Expr*)$1, (Expr*)$3); $$ = e; }
    | expr T_LT expr
        { BinaryOperator *ao = new BinaryOperator("<"); Expr *e = new Expr(ao, (Expr*)$1, (Expr*)$3); $$ = e; }
    | expr T_GT expr
        { BinaryOperator *ao = new BinaryOperator(">"); Expr *e = new Expr(ao, (Expr*)$1, (Expr*)$3); $$ = e; }
    | expr T_LEQ expr
        { BinaryOperator *ao = new BinaryOperator("<="); Expr *e = new Expr(ao, (Expr*)$1, (Expr*)$3); $$ = e; }
    | expr T_GEQ expr
        { BinaryOperator *ao = new BinaryOperator(">="); Expr *e = new Expr(ao, (Expr*)$1, (Expr*)$3); $$ = e; }
    | expr T_EQ expr
        { BinaryOperator *ao = new BinaryOperator("=="); Expr *e = new Expr(ao, (Expr*)$1, (Expr*)$3); $$ = e; }
    | expr T_NEQ expr
        { BinaryOperator *ao = new BinaryOperator("!="); Expr *e = new Expr(ao, (Expr*)$1, (Expr*)$3); $$ = e; }
    | expr T_AND expr
        { BinaryOperator *ao = new BinaryOperator("&&"); Expr *e = new Expr(ao, (Expr*)$1, (Expr*)$3); $$ = e; }
    | expr T_OR expr
        { BinaryOperator *ao = new BinaryOperator("||"); Expr *e = new Expr(ao, (Expr*)$1, (Expr*)$3); $$ = e; }
    | T_MINUS expr %prec UMINUS 
        { UnaryOperator *uo = new UnaryOperator("-"); $$ = uo; Expr *e = new Expr(uo, (Expr*)$2); $$ = e;}
    | T_NOT expr
        { UnaryOperator *uo = new UnaryOperator("!"); $$ = uo; Expr *e = new Expr(uo, (Expr*)$2); $$ = e;}
    | T_LPAREN expr T_RPAREN
        { $$ = $2; }
    ;

block: begin_block varDecls statements end_block { Block *b = new Block((decafStmtList*)$2, (decafStmtList*)$3); $$ = b; }
	;

begin_block: T_LCB { syms.new_symtbl(); }
    ;

end_block: T_RCB { syms.remove_symtbl(); }
    ;

statements: statement statements {
		decafStmtList *dsl = (decafStmtList*)$2;
		dsl -> push_front($1);
		$$ = dsl;	
	}
	| { decafStmtList *dsl = new decafStmtList(); $$ = dsl; }
	;

statement: block { StatementAST *s = new StatementAST((Block*)$1); $$ = s; }
	| methodCall T_SEMICOLON { StatementAST *s = new StatementAST((MethodCallAST*)$1); $$ = s; }
	| assign T_SEMICOLON { StatementAST *s = new StatementAST((Assign*)$1); $$ = s; }
	| T_IF T_LPAREN expr T_RPAREN block { StatementAST *s = new StatementAST((Expr*)$3, (Block*)$5, (Block*)NULL); $$ = s; }
	| T_IF T_LPAREN expr T_RPAREN block T_ELSE block { StatementAST *s = new StatementAST((Expr*)$3, (Block*)$5, (Block*)$7); $$ = s; }	
	| T_WHILE T_LPAREN expr T_RPAREN block { StatementAST *s = new StatementAST((Expr*)$3, (Block*)$5); $$ = s; }
	| T_FOR T_LPAREN assignList T_SEMICOLON expr T_SEMICOLON assignList T_RPAREN block {
		StatementAST *s = new StatementAST((decafStmtList*)$3, (Expr*)$5, (decafStmtList*)$7, (Block*)$9);
		$$ = s;
	}
	| T_RETURN T_LPAREN expr T_RPAREN T_SEMICOLON { StatementAST *s = new StatementAST((Expr*)$3); $$ = s; }
	| T_RETURN T_LPAREN T_RPAREN T_SEMICOLON {
		decafStmtList *dsl = new decafStmtList();
		StatementAST *s = new StatementAST("return",dsl); $$ = s;
	}
	| T_RETURN T_SEMICOLON {
		decafStmtList *dsl = new decafStmtList();
		StatementAST *s = new StatementAST("return",dsl); $$ = s; }
	| T_BREAK T_SEMICOLON { StatementAST *s = new StatementAST("break"); $$ = s; }
	| T_CONTINUE T_SEMICOLON { StatementAST *s = new StatementAST("continue"); $$ = s; }
	;

varDecls: varDecl varDecls {
		decafStmtList *dsl = (decafStmtList*)$2;
        dsl->push_front((decafStmtList*)$1);
        $$ = dsl; 
	}
	| { decafStmtList *dsl = new decafStmtList(); $$ = dsl; }
	;	
	
varDecl: T_VAR idList type T_SEMICOLON {
        decafStmtList *dsl = new decafStmtList();
        string curr_id;
        StringList *sl = (StringList*)$2;
        list<string> sList = sl->getList();
        DecafTypeAST *d = (DecafTypeAST*)$3;
        for(list<string>::const_iterator iter = sList.begin(); iter != sList.end(); ++iter){
            curr_id = *iter;
            dsl->push_back(new TypedSymbolAST(curr_id, (DecafTypeAST*)$3));
            //enter_symtbl(curr_id, d -> str(), lineno);
        }
        $$ = dsl;   
    } 
    ;

/* UNARY OPS */

arrayType: T_LSB T_INTCONSTANT T_RSB type {FieldSize *fs = new FieldSize($2, (DecafTypeAST*)$4); $$ = fs; }
    ;

externType: T_STRINGTYPE { ExternTypeAST *et = new ExternTypeAST("string"); $$ = et; }
    | type { 
        ExternTypeAST *et = new ExternTypeAST((DecafTypeAST*)$1); 
        $$ = et;
    }
    ;
methodType: T_VOID { MethodTypeAST *mt = new MethodTypeAST("void"); $$ = mt;}
    | type { MethodTypeAST *mt = new MethodTypeAST((DecafTypeAST*)$1); $$ = mt; }
    ;
type: T_INTTYPE { DecafTypeAST *dt = new DecafTypeAST("int"); $$ = dt;}
    | T_BOOLTYPE { DecafTypeAST *dt = new DecafTypeAST("bool"); $$ = dt;}
	;


constant : T_INTCONSTANT { Expr *c = new Expr($1); $$ = c;}
    | T_CHARCONSTANT { 
        char ch;
        if($1->at(1) == '\\'){
            if($1->at(2) == 'n'){
                ch = '\n';
            }else if($1->at(2) == 'r'){
                ch = '\r';
            }else if($1->at(2) == 't'){
                ch = '\t';
            }else if($1->at(2) == 'v'){
                ch = '\v';
            }else if($1->at(2) == 'f'){
                ch = '\f';
            }else if($1->at(2) == 'a'){
                ch = '\a';
            }else if($1->at(2) == 'b'){
                ch = '\b';
            }else if($1->at(2) == '\\'){
                ch = '\\';
            }else if($1->at(2) == '\''){
                ch = '\'';
            }else if($1->at(2) == '"'){
                ch = '\"';
            }
        }else{
            ch = $1->at(1);
        }
        Expr *c = new Expr(ch); $$ = c;
    }
	| boolConstant { $$ = $1; }
	;

boolConstant: T_TRUE { Expr *c = new Expr(true);$$ = c;}
	| T_FALSE { Expr *c = new Expr(false);  $$ = c;}
	;

%%

int main() {
  // initialize LLVM
  llvm::LLVMContext &Context = llvm::getGlobalContext();
  // Make the module, which holds all the code.
  TheModule = new llvm::Module("Test", Context);
  // set up symbol table
  // set up dummy main function
    //TheFunction = gen_main_def();
  // parse the input and create the abstract syntax tree
  int retval = yyparse();
  // remove symbol table
  // Finish off the main function. (see the WARNING above)
  // return 0 from main, which is EXIT_SUCCESS
  //Builder.CreateRet(llvm::ConstantInt::get(llvm::getGlobalContext(), llvm::APInt(32, 0)));
  // Validate the generated code, checking for consistency.
    //verifyFunction(*TheFunction);
  // Print out all of the generated code to stderr
  TheModule->dump();
  return(retval >= 1 ? EXIT_FAILURE : EXIT_SUCCESS);
}