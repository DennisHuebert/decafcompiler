#include "decafast-defs.h"
#include <list>
#include <ostream>
#include <iostream>
#include <sstream>

#ifndef YYTOKENTYPE
#include "decafcomp.tab.h"
#endif

using namespace std;

/// decafAST - Base class for all abstract syntax tree nodes.

// this global variable contains all the generated code
static llvm::Module *TheModule;

// this is the method used to construct the LLVM intermediate code (IR)
static llvm::IRBuilder<> Builder(llvm::getGlobalContext());
// the calls to getGlobalContext() in the init above and in the
// following code ensures that we are incrementally generating
// instructions in the right order

symboltable syms;
bool defaultRet = true;

void enter_symtbl(string ident, llvm::Value *v){
    syms.enter_symtbl(ident, new descriptor(v));
    //cerr << "defined variable: " << ident << ", with type: " << type << ", on line number: " << lineno << endl;
}

class decafAST {
public:
  virtual ~decafAST() {}
  virtual string str() { return string(""); }
  virtual llvm::Value *Codegen() = 0;
  virtual llvm::Value *proto(){return 0;};
};

string getString(decafAST *d) {
	if (d != NULL) {
		return d->str();
	} else {
		return string("None");
	}
}

template <class T>
string commaList(list<T> vec) {
    string s("");
    for (typename list<T>::iterator i = vec.begin(); i != vec.end(); i++) { 
        s = s + (s.empty() ? string("") : string(",")) + (*i)->str(); 
    }   
    if (s.empty()) {
        s = string("None");
    }   
    return s;
}

template <class T>
llvm::Value *listCodegen(list<T> vec) {
	llvm::Value *val = NULL;
	for (typename list<T>::iterator i = vec.begin(); i != vec.end(); i++) { 
		llvm::Value *j = (*i)->Codegen();
		if (j != NULL) { val = j; }
	}	
	return val;
}

template <class T>
vector<llvm::Type *> vectorCodegenTypes(list<T> vec){
	
	vector<llvm::Type*> params;
	llvm::Type *t = NULL;
	for (typename list<T>::iterator i = vec.begin(); i != vec.end(); i++) { 
		llvm::Type *j = (llvm::Type *)(*i)->Codegen();//->getType();
		if (j != NULL) {
		 	t = j; 
		 	params.push_back(t);
		 }
	}
	return params;
}
template <class T>
vector<llvm::Type *> vectorMethodParamTypes(list<T> vec){
	
	vector<llvm::Type*> params;
	llvm::Type *t = NULL;
	/*for (typename list<T>::iterator i = vec.begin(); i != vec.end(); i++) { 
		llvm::Type *j = (*i)->Codegen()->getType();
		if (j != NULL) {
		 	t = j; 
		 	params.push_back(t);
		 }
	}*/
	llvm::Type *intType = Builder.getInt32Ty();
	llvm::Type *boolType = Builder.getInt1Ty();

	for (typename list<T>::iterator i = vec.begin(); i != vec.end(); i++) { 
		llvm::Type *j = (*i)->Codegen()->getType();
		if (j == intType->getPointerTo()) {
		 	params.push_back(Builder.getInt32Ty());
		 }else if( j == boolType->getPointerTo()){
		 	params.push_back(Builder.getInt1Ty());
		 }else{
		 	throw runtime_error("VECTORMETHODPARAMSTYPE WRONG");
		 }
	}	 
	return params;
}
template <class T>
vector<llvm::Value *> vectorMethodArgs(list<T> vec){
	
	vector<llvm::Value*> params;
	llvm::Value *v = NULL;
	for (typename list<T>::iterator i = vec.begin(); i != vec.end(); i++) { 
		llvm::Value *j = (*i)->Codegen();
		if (j != NULL) {
		 	v = j; 
		 	params.push_back(v);
		 }
	}
	return params;
}


/// decafStmtList - List of Decaf statements
class decafStmtList : public decafAST {
	list<decafAST *> stmts;
public:
	decafStmtList() {}
	~decafStmtList() {
		for (list<decafAST *>::iterator i = stmts.begin(); i != stmts.end(); i++) { 
			delete *i;
		}
	}
	int size() { return stmts.size(); }
	void push_front(decafAST *e) { stmts.push_front(e); }
	void push_back(decafAST *e) { stmts.push_back(e); }
	string str() { return commaList<class decafAST *>(stmts); }
	list<decafAST *> getList(){return stmts;}
	llvm::Value *Codegen() { 
		return listCodegen<decafAST *>(stmts); 
	}
	vector<llvm::Type *> getParamTypes(){
		return vectorCodegenTypes<decafAST *>(stmts);
	}
	vector<llvm::Type *> getMethodParamTypes(){
		return vectorMethodParamTypes<decafAST *>(stmts);
	}
	vector<llvm::Value *> getMethodArgs(){
		return vectorMethodArgs<decafAST *>(stmts);
	}
};

class PackageAST : public decafAST {
	string Name;
	decafStmtList *FieldDeclList;
	decafStmtList *MethodDeclList;
public:
	PackageAST(string name, decafStmtList *fieldlist, decafStmtList *methodlist) 
		: Name(name), FieldDeclList(fieldlist), MethodDeclList(methodlist) {}
	~PackageAST() { 
		if (FieldDeclList != NULL) { delete FieldDeclList; }
		if (MethodDeclList != NULL) { delete MethodDeclList; }
	}
	string str() { 
		return string("Package") + "(" + Name + "," + getString(FieldDeclList) + "," + getString(MethodDeclList) + ")";
	}
	llvm::Value *Codegen() { 
		for(auto m : MethodDeclList->getList()){
			m->proto();
		}

		syms.new_symtbl();
		
		llvm::Value *val = NULL;
		TheModule->setModuleIdentifier(llvm::StringRef(Name)); 
		if (NULL != FieldDeclList) {
			val = FieldDeclList->Codegen();
		}
		if (NULL != MethodDeclList) {
			val = MethodDeclList->Codegen();
		} 

		syms.remove_symtbl();
		// Q: should we enter the class name into the symbol table?
		return val; 
	}
};

/// ProgramAST - the decaf program
class ProgramAST : public decafAST {
	decafStmtList *ExternList;
	PackageAST *PackageDef;
public:
	ProgramAST(decafStmtList *externs, PackageAST *c) : ExternList(externs), PackageDef(c) {}
	~ProgramAST() { 
		if (ExternList != NULL) { delete ExternList; } 
		if (PackageDef != NULL) { delete PackageDef; }
	}
	string str() { return string("Program") + "(" + getString(ExternList) + "," + getString(PackageDef) + ")"; }
	llvm::Value *Codegen() { 
		syms.new_symtbl();
		llvm::Value *val = NULL;
		if (NULL != ExternList) {
			val = ExternList->Codegen();
		}
		if (NULL != PackageDef) {
			val = PackageDef->Codegen();
		} else {
			throw runtime_error("no package definition in decaf program");
		}
		syms.remove_symtbl();
		return val; 
	}
};


// StringList - list<string> wrapper
class StringList{
	list<string> sList;
public:
	int size() { return sList.size(); }
	void push_front(string s) { sList.push_front(s); }
	void push_back(string s) { sList.push_back(s); }
	string str(){
		string ret_str;
		for(list<string>::const_iterator iter = sList.begin(); iter != sList.end(); ++iter){
			if(iter != sList.begin()){
				ret_str += ",";
			}
			ret_str += *iter;
		}
		return ret_str;
	}
	list<string> getList(){
		return sList;
	}
};



class DecafTypeAST : public decafAST{
	string type;
public:
	DecafTypeAST(string t){
		
		if(t.compare("int")==0){
			type = "int";
		}else if(t.compare("bool")==0){
			type = "bool";
		}else{
			printf("bad type");
			//exit(EXIT_FAILURE);
		}
	}
	~DecafTypeAST(){}
	string str(){
		return type;
	}
	llvm::Value *Codegen(){ return 0; };
};

class MethodTypeAST : public decafAST{
	string type;
	DecafTypeAST *decafType;
public:
	MethodTypeAST(string t){
		if(t.compare("void")==0){
			type = "VoidType";
		}else if(t.compare("int")==0){
			type = "IntType";
		}else if(t.compare("bool")==0){
			type = "BoolType";
		}else{
			printf("bad method type");
			//exit(EXIT_FAILURE);
		}
	}
	MethodTypeAST(DecafTypeAST *dt){
		decafType = dt;
		string t = getString(dt);
		if(t.compare("void")==0){
			type = "VoidType";
		}else if(t.compare("int")==0){
			type = "IntType";
		}else if(t.compare("bool")==0){
			type = "BoolType";
		}else{
			printf("bad method type");
			//exit(EXIT_FAILURE);
		}
	}
	~MethodTypeAST(){}
	string str(){
		return type;
	}
	llvm::Value *Codegen(){ 
		if(type==string("VoidType")){
			return (llvm::Value *) Builder.getVoidTy();
		}else if(type==string("IntType")){
			return (llvm::Value *) Builder.getInt32Ty();
		}else if(type==string("BoolType")){
			return (llvm::Value *) Builder.getInt1Ty();
		}else{
			throw runtime_error("Invalid method type of "+type);
		}

	};
};

class ExternTypeAST : public decafAST{
	string type;
	DecafTypeAST *decafType;
public:
	ExternTypeAST(string t){
		
		if(t.compare("string")==0){
			type = "StringType";
		}else if(t.compare("int")==0){
			type = "IntType";
		}else if(t.compare("bool")==0){
			type = "BoolType";
		}else{
			printf("bad extern type");
			//exit(EXIT_FAILURE);
		}
	}
	ExternTypeAST(DecafTypeAST *dt){
		decafType = dt;
		string t = getString(dt);
		if(t.compare("string")==0){
			type = "StringType";
		}else if(t.compare("int")==0){
			type = "IntType";
		}else if(t.compare("bool")==0){
			type = "BoolType";
		}else{
			printf("bad extern type");
			//exit(EXIT_FAILURE);
		}
	}
	~ExternTypeAST(){}
	string str(){
		return string("VarDef") + '(' + type.c_str() + ')';
	}
	llvm::Value *Codegen(){ 
		if(type == "IntType"){
			return (llvm::Value *) Builder.getInt32Ty();
		}
		else if(type == "BoolType"){
			return (llvm::Value *) Builder.getInt1Ty();
		}
		else if(type == "StringType"){
			return (llvm::Value *) Builder.getInt8PtrTy();
		}
		else{
			throw runtime_error("Invalid extern type of " + type);
		}

	}
};


class TypedSymbolAST : public decafAST {
	string name;
	DecafTypeAST *type;
public:
	TypedSymbolAST(string n, DecafTypeAST *t) : name(n), type(t) {}
	~TypedSymbolAST(){}
	string str()
	{
		return string("VarDef") + "(" + name + "," + getString(type) + ")";
	}
	string getName(){
		return name;
	}
	string getTypeStr(){
		return type->str();
	}
	llvm::Value *Codegen(){ 
		llvm::Type *t;
		if(type->str()==string("int")){
			t = Builder.getInt32Ty();
			//llvm::Type *t = llvm::IntegerType::get(getGlobalContext(), 32);
		}else if(type->str()==string("bool")){
			t = Builder.getInt1Ty();
			//llvm::Type *t = llvm::IntegerType::get(getGlobalContext(), 1);
		}

		llvm::AllocaInst *Alloca;
		Alloca = Builder.CreateAlloca(t, nullptr, name);

		enter_symtbl(name, Alloca);
		return Alloca; 
	};
};


// ExternAST - external function statements
class ExternAST : public decafAST {
	string name;
	MethodTypeAST *return_type;
	decafStmtList *type_list;

public: 
	ExternAST(string n, MethodTypeAST *rt, decafStmtList *tl){
		name = n;
		return_type = rt;
		type_list = tl;
	}
	~ExternAST(){}

	string str(){
		return string("ExternFunction") + "(" + name + "," + getString(return_type) + "," + getString(type_list) + ")";
	}
	llvm::Value *Codegen(){
		llvm::Value *val = NULL;
		llvm::Type *returnTy = (llvm::Type *)return_type -> Codegen();
		std::vector<llvm::Type *> args = type_list -> getParamTypes();
		llvm::FunctionType *FT;
		if(args.size() == 0){
			FT = llvm::FunctionType::get(returnTy, false);	
		}
		else{
			FT = llvm::FunctionType::get(returnTy, args, false);
		}
		llvm::Function *func = llvm::Function::Create(
			FT,
			llvm::Function::ExternalLinkage,
			name,
			TheModule
			);
		enter_symtbl(name, func);
		return func;
	}
};


class BinaryOperator : public decafAST {
	string op;
public:
	BinaryOperator(string o) : op(o) {}
	~BinaryOperator() {}
	string str() {
		string ret_str;
		if(op == "+")
			ret_str = string("Plus");
		else if(op == "-")
			ret_str = string("Minus");
		else if(op == "*")
			ret_str = string("Mult");
		else if(op == "/")
			ret_str = string("Div");
		else if(op == "<<")
			ret_str = string("Leftshift");
		else if(op == ">>")
			ret_str = string("Rightshift");
		else if(op == "%")
			ret_str = string("Mod");
		else if(op == "<")
			ret_str = string("Lt");
		else if(op == ">")
			ret_str = string("Gt");
		else if(op == "<=")
			ret_str = string("Leq");
		else if(op == ">=")
			ret_str = string("Geq");
		else if(op == "==")
			ret_str = string("Eq");
		else if(op == "!=")
			ret_str = string("Neq");
		else if(op == "&&")
			ret_str = string("And");
		else
			ret_str = string("Or");
		
		return ret_str;
	}
	llvm::Value *Codegen(){ return 0; };
};

class UnaryOperator : public decafAST {
	string op;
public:
	UnaryOperator(string o) : op(o) {}
	~UnaryOperator() {}
	string str() {
		string ret_str;
		if(op == "-")
			ret_str = string("UnaryMinus");
		else
			ret_str = string("Not");
		
		return ret_str;
	}
	llvm::Value *Codegen(){ return 0; };
};

class MethodCallAST : public decafAST {
	string name;
	decafStmtList* methodArg_list;
public: 
	MethodCallAST(string n, decafStmtList *m) : name(n), methodArg_list(m) {}
	~MethodCallAST() { if(methodArg_list != NULL) { delete methodArg_list; } }
	
	string str(){
		return string("MethodCall") + "(" + name + "," + getString(methodArg_list) + ")";
	}
	llvm::Value *Codegen(){ 

		descriptor *d = syms.access_symtbl(name);
		if(d){
			llvm::Function *call = (llvm::Function *) d->getVal();

			std::vector<llvm::Value *> args_in = methodArg_list->getMethodArgs();

		//PROMOTING
			int argIdx = 0;
			llvm::Type *t;
			llvm::Type *t_in;
			llvm::Value *arg_in;
			for (auto &Arg : call->args()) {
				
				t = Arg.getType();
				arg_in = args_in.at(argIdx);
				t_in = arg_in->getType();
				if(t != t_in){
					llvm::Value *promo = Builder.CreateZExt(arg_in, t, "zexttmp");
					args_in[argIdx] = promo;

				}
				argIdx++;
			}

			bool isVoid = call->getReturnType()->isVoidTy();

			return Builder.CreateCall(
				call,
				args_in,
				isVoid ? "" : "calltmp"
			);

		}else{
			//some code about protoypes?
			throw runtime_error("Method not found in symboltable");
		}
		return 0;
	};
	
};

class Expr : public decafAST {
	decafStmtList *rvalue = NULL;
	MethodCallAST *method_call_list = NULL;
	int iValue = -1;
	bool bValue;
	BinaryOperator *bOp = NULL;
	UnaryOperator *uOp = NULL;
	Expr *left_value = NULL;
	Expr *right_value = NULL;
	Expr *value = NULL;
public:
	Expr(decafStmtList *rVal) : rvalue(rVal) {}
	Expr(MethodCallAST *methCall) : method_call_list(methCall) {}

	Expr(int value) : iValue(value) {}
	Expr(bool value) : bValue(value) {}

	Expr(BinaryOperator *op, Expr *lv, Expr *rv) : bOp(op), left_value(lv), right_value(rv) {}
	Expr(UnaryOperator *op, Expr *v) : uOp(op), value(v) {}
	
	~Expr(){
		if(rvalue != NULL) { delete rvalue; }
		if(method_call_list != NULL) { delete method_call_list; }
		if(bOp != NULL) { delete bOp; }
		if(uOp != NULL) { delete uOp; }
		if(left_value != NULL) { delete left_value; }
		if(right_value != NULL) { delete right_value; }
		if(value != NULL) { delete value; }
	} 
	string str() {
		string ret_str;
		if(rvalue != NULL) {
			ret_str = getString(rvalue);
		}
		else if(method_call_list != NULL){
			ret_str = getString(method_call_list);
		}
		else if(bOp != NULL){
			ret_str = string("BinaryExpr") + "(" + getString(bOp) + "," + getString(left_value) + ","+ getString(right_value) + ")";
		}
		else if(uOp != NULL){
			ret_str = string("UnaryExpr") + "(" + getString(uOp) + "," + getString(value) + ")";
		}
		else if(iValue != -1){
			std::ostringstream stream;
			stream << "NumberExpr(" << iValue << ")";
			ret_str = stream.str(); 
		}
		else{
			string bValue_str;
			if(bValue == true){
				bValue_str = "True";
			}else{
				bValue_str = "False";
			}
			std::ostringstream stream;
			stream << "BoolExpr(" << bValue_str << ")";
			ret_str = stream.str();
		}
		return ret_str;
	}

	llvm::Value *Codegen() {
		if(bOp != NULL){
			llvm::Value *L;
			llvm::Value *R;

			if(getString(bOp) == "Or"){
				llvm::Function *TheFunction = Builder.GetInsertBlock()->getParent();
				llvm::BasicBlock *scstartBB = llvm::BasicBlock::Create(llvm::getGlobalContext(), "scstart", TheFunction);
				llvm::BasicBlock *sctrueBB = llvm::BasicBlock::Create(llvm::getGlobalContext(), "sctrue", TheFunction);
				llvm::BasicBlock *scfalseBB = llvm::BasicBlock::Create(llvm::getGlobalContext(), "scfalse", TheFunction);
				llvm::BasicBlock *scphiBB = llvm::BasicBlock::Create(llvm::getGlobalContext(), "scphi", TheFunction);
				llvm::BasicBlock *endBB = llvm::BasicBlock::Create(llvm::getGlobalContext(), "end", TheFunction);

			// scstart block
				Builder.CreateBr(scstartBB);
				Builder.SetInsertPoint(scstartBB);

				L = left_value->Codegen();
				llvm::Value *trueVal = Builder.getInt1(1);
				llvm::Value *brCondV = Builder.CreateICmpEQ(L,trueVal,"eqtmp");
				Builder.CreateCondBr(brCondV, sctrueBB, scfalseBB);

			// sctrue block
				Builder.SetInsertPoint(sctrueBB);
				// store L in tmp 
				Builder.CreateBr(scphiBB);

			// scfalse block
				Builder.SetInsertPoint(scfalseBB);
				R = right_value->Codegen();
				llvm::Value *opval = Builder.CreateOr(L, R, "ortmp");
				Builder.CreateBr(scphiBB);
			
			// phi block
				Builder.SetInsertPoint(scphiBB);

				llvm::PHINode *val = Builder.CreatePHI(L->getType(), 2, "phival");
				val->addIncoming(L,sctrueBB);
				val->addIncoming(opval, scfalseBB);

				Builder.CreateBr(endBB);
			
			// end block??
				Builder.SetInsertPoint(endBB);
				return val;

			}else if(getString(bOp) == "And"){
				llvm::Function *TheFunction = Builder.GetInsertBlock()->getParent();
				llvm::BasicBlock *scstartBB = llvm::BasicBlock::Create(llvm::getGlobalContext(), "scstart", TheFunction);
				llvm::BasicBlock *sctrueBB = llvm::BasicBlock::Create(llvm::getGlobalContext(), "sctrue", TheFunction);
				llvm::BasicBlock *scfalseBB = llvm::BasicBlock::Create(llvm::getGlobalContext(), "scfalse", TheFunction);
				llvm::BasicBlock *scphiBB = llvm::BasicBlock::Create(llvm::getGlobalContext(), "scphi", TheFunction);
				llvm::BasicBlock *endBB = llvm::BasicBlock::Create(llvm::getGlobalContext(), "end", TheFunction);

			// scstart block
				Builder.CreateBr(scstartBB);
				Builder.SetInsertPoint(scstartBB);

				L = left_value->Codegen();
				llvm::Value *trueVal = Builder.getInt1(0);
				llvm::Value *brCondV = Builder.CreateICmpEQ(L,trueVal,"eqtmp");
				Builder.CreateCondBr(brCondV, sctrueBB, scfalseBB);

			// sctrue block
				Builder.SetInsertPoint(sctrueBB);
				// store L in tmp 
				Builder.CreateBr(scphiBB);

			// scfalse block
				Builder.SetInsertPoint(scfalseBB);
				R = right_value->Codegen();
				llvm::Value *opval = Builder.CreateAnd(L, R, "andtmp");
				Builder.CreateBr(scphiBB);
			
			// phi block
				Builder.SetInsertPoint(scphiBB);

				llvm::PHINode *val = Builder.CreatePHI(L->getType(), 2, "phival");
				val->addIncoming(L,sctrueBB);
				val->addIncoming(opval, scfalseBB);

				Builder.CreateBr(endBB);
			
			// end block??
				Builder.SetInsertPoint(endBB);
				return val;

			}else{
				L = left_value -> Codegen();
				R = right_value -> Codegen();	
			
				if (getString(bOp) == "Plus"){
					return Builder.CreateAdd(L, R, "addtmp");
				}
				else if(getString(bOp) == "Minus"){
					return Builder.CreateSub(L, R, "subtmp");
				}
				else if(getString(bOp) == "Mult"){
					return Builder.CreateMul(L, R, "multmp");
				}
				else if(getString(bOp) == "Div"){
					return Builder.CreateSDiv(L, R, "divtmp");
				}
				else if(getString(bOp) == "Leftshift"){
					return Builder.CreateShl(L, R, "shltmp");
				}
				else if(getString(bOp) == "Rightshift"){
					return Builder.CreateLShr(L, R, "lshrtmp");
				}
				else if(getString(bOp) == "Mod"){
					return Builder.CreateSRem(L, R, "modtmp");
				}
				else if(getString(bOp) == "Lt"){
					return Builder.CreateICmpSLT(L, R, "lcmptmp");
				}
				else if(getString(bOp) == "Gt"){
					return Builder.CreateICmpSGT(L, R, "gcmptmp");
				}
				else if(getString(bOp) == "Leq"){
					return Builder.CreateICmpSLE(L, R, "lecmptmp");
				}
				else if(getString(bOp) == "Geq"){
					return Builder.CreateICmpSGE(L, R, "gecmptmp");
				}
				else if(getString(bOp) == "And"){ //////////////////////////////////////////DELETE AFTER SHORT CIRCUITING DONE
					return Builder.CreateAnd(L, R, "andtmp");
				}
				else if(getString(bOp) == "Or"){ //////////////////////////////////////////DELETE AFTER SHORT CIRCUITING DONE
					return Builder.CreateOr(L, R, "ortmp");
				}
				else if(getString(bOp) == "Eq"){
					return Builder.CreateICmpEQ(L, R, "eqtmp");
				}
				else if(getString(bOp) == "Neq"){
					return Builder.CreateICmpNE(L, R, "cmpnetmp");
				}
				else{
					throw runtime_error("Unsupported Binary Operator " + getString(bOp));
				}
			}
		}
		else if(uOp != NULL){
			llvm::Value *U = value -> Codegen();
			if(getString(uOp) == "UnaryMinus"){
				return Builder.CreateNeg(U, "negtemp");
			}
			else if(getString(uOp) == "Not"){
				return Builder.CreateNot(U, "notmp");
			}
			else{
				throw runtime_error("Unsupported Unary Operator " + getString(uOp));
			}
		}
		else if(rvalue != NULL){
			llvm::Value *R = rvalue -> Codegen();
			return R;
		}
		else if(method_call_list != NULL){
			llvm::Value *M = method_call_list -> Codegen();
			return M;
		}
		else if(iValue != -1){ 		//Bool and Int values need codegen functions still
			return llvm::ConstantInt::get(llvm::getGlobalContext(), llvm::APInt(32, iValue));
		}
		else{
			return llvm::ConstantInt::get(llvm::getGlobalContext(), llvm::APInt(1, bValue));
		}
	}
};


class FieldSize : public decafAST{
	DecafTypeAST *type;
	int size;
public: 
	FieldSize(){}
	FieldSize(int arraySize, DecafTypeAST *t){size = arraySize; type = t;}
	~FieldSize(){}
	string str() { 
		if(type == NULL){
			return string("Scalar");
		}else{
			std::ostringstream stream;
			stream << "Array(" << size << ")";
			string ret_str = stream.str();
			return ret_str;	
		}
	}
	DecafTypeAST* getType(){ return type; }
	int getSize(){ return size; }
	llvm::Value *Codegen(){ return 0; };
};

class FieldDeclAST : public decafAST {
	string name;
	DecafTypeAST *type;
	FieldSize *fieldSize;
	Expr *value;

public:
    FieldDeclAST(string n, DecafTypeAST *t, FieldSize *fs) : name(n), fieldSize(fs) {type = t;}
    FieldDeclAST(string n, DecafTypeAST *t, Expr *v) : name(n){ type = t; value = v; fieldSize = NULL; }
    ~FieldDeclAST() {}
    string str() { 
    	string ret_str;
    	if(fieldSize != NULL){
    		ret_str = string("FieldDecl(") + name + "," + getString(type) + "," + getString(fieldSize) + ")";	
    	}else{
    		ret_str = string("AssignGlobalVar(") + name + "," + getString(type) + "," + getString(value) + ")";	
    	}
    	return ret_str;
    }
    llvm::Value *Codegen(){ 

    	llvm::GlobalVariable *globVar;

    // FIELD DECL 
    	if(fieldSize != NULL){
    	//  CHECK IF SCALAR OR ARRAY
    		if(getString(fieldSize)=="Scalar"){
    	// IF SCALAR
    		// Type & Zero Init
    			string typeStr = getString(type);
    			llvm::Type *t;
    			llvm::ConstantInt *val;
    			if(typeStr == "int"){
    				t = Builder.getInt32Ty();
    				val = Builder.getInt32(0);
    			}else if(typeStr == "bool"){
    				t = Builder.getInt1Ty();
    				val = Builder.getInt1(0);
    			}
    		// Declare
    			globVar = new llvm::GlobalVariable(
    				*TheModule
    				, t
    				, false
    				, llvm::GlobalValue::InternalLinkage
    				, val
    				, name
    			);

    		}else{
    	// IF GLOBAL ARRAY
    		// Type / Size
				int size = fieldSize->getSize();
				string typeStr = getString(type);
				llvm::ArrayType *arrType;
				if(typeStr == "int"){
					arrType = llvm::ArrayType::get(Builder.getInt32Ty(), size);
				}else if(typeStr == "bool"){
					arrType = llvm::ArrayType::get(Builder.getInt1Ty(), size);
				}
			// Zero Initialize
				llvm::Constant *zeroInit = llvm::Constant::getNullValue(arrType);
			// Declare Global Arr
				globVar = new llvm::GlobalVariable(
					*TheModule
					, arrType
					, false
					, llvm::GlobalValue::ExternalLinkage
					, zeroInit
					, name
				);

			// Add to symbol table
				enter_symtbl(name, globVar);
    		}


    // ASSIGN GLOBAL VAR
    	}else{
    		string typeStr = getString(type);
    		llvm::Type *t;
			if(typeStr == "int"){
				t = Builder.getInt32Ty();
			}else if(typeStr == "bool"){
				t = Builder.getInt1Ty();
			}

    		llvm::ConstantInt *val = (llvm::ConstantInt*) (value->Codegen());

    		globVar = new llvm::GlobalVariable(
    			*TheModule
    			, t
    			, false
    			, llvm::GlobalValue::InternalLinkage
    			, val
    			, name
    		);

    		enter_symtbl(name, globVar);
    	}


    };
};

class MethodArg : public decafAST {
	string value;
	Expr *expr = NULL;
public:
	MethodArg(string v) { 
		int len = v.size();
		string s = v.substr(1, len-2);
		
		vector<char> charVec;
		for(int i=0; i<s.size();i++){
			char c = s[i];
			if( c=='\\' ){
				i++;
				c = s[i];
				if(c=='n'){
					charVec.push_back('\n');
				}else if(c=='r'){
					charVec.push_back('\r');
				}else if(c=='t'){
					charVec.push_back('\t');
				}else if(c=='v'){
					charVec.push_back('\v');
				}else if(c=='f'){
					charVec.push_back('\f');
				}else if(c=='a'){
					charVec.push_back('\a');
				}else if(c=='b'){
					charVec.push_back('\b');
				}else if(c=='\\'){
					charVec.push_back('\\');
				}else if(c=='\''){
					charVec.push_back('\'');
				}else if(c=='"'){
					charVec.push_back('\"');
				}
			}else{
				charVec.push_back(c);
			}
		}
		value = string(charVec.begin(), charVec.end());
	}
	MethodArg(Expr *e) : expr(e) {}
	~MethodArg() { if(expr != NULL) { delete expr; } }
	string str(){
		string ret_str;
		if(expr != NULL){
			ret_str = getString(expr);
		}
		else{
			ret_str = string("StringConstant") + "(" + value + ")";
		}
		return ret_str;
	}

	llvm::Value *Codegen(){
		if(expr != NULL){
			llvm::Value *E = expr -> Codegen();
			return E;
		}
		else{
			//Value CodeGen needs to be completed here
			llvm::GlobalVariable *GS = Builder.CreateGlobalString(value, "globalstring");
			llvm::Value *stringConst = Builder.CreateConstGEP2_32(GS->getValueType(), GS, 0, 0, "cast");
			return stringConst;
		}
	}
	//llvm::Value *Codegen(){ return 0; };
};

class MethodBlock : public decafAST{
	decafStmtList *var_decl_list; // typed_symbol*
	decafStmtList *statement_list; // statement*
public:
	MethodBlock(decafStmtList *vdl, decafStmtList *sl){ var_decl_list = vdl; statement_list = sl; }
	~MethodBlock(){ if(var_decl_list != NULL) {delete var_decl_list;} if(statement_list != NULL) {delete statement_list;} }
	string str(){ return string("MethodBlock") + '(' + getString(var_decl_list) + ',' + getString(statement_list) + ')'; }
	llvm::Value *Codegen(){ 
		llvm::Value *val = NULL;
		if(var_decl_list!=NULL){
			val = var_decl_list->Codegen();	
		}
		if( statement_list != NULL){
			val = statement_list->Codegen();	
		}
		
		return val;
	};
};

class MethodDecl : public decafAST{
	string name;
	MethodTypeAST *return_type;
	decafStmtList *param_list; //typed_symbol
	MethodBlock *block;
public:
	MethodDecl(string n, MethodTypeAST *rt, decafStmtList *pl, MethodBlock *b){ name = n; return_type = rt;	param_list = pl; block = b; }
	~MethodDecl(){delete return_type; delete param_list; delete block; }
	string str(){ return string("Method(") + name.c_str() + "," + getString(return_type) + "," + getString(param_list) + "," + getString(block) + ")" ; }
	llvm::Value *proto(){
		syms.new_symtbl();

		llvm::Type *returnTy;
		string ret_str = return_type->str();
		if(ret_str == "VoidType"){
			returnTy = Builder.getVoidTy();
		}else if(ret_str == "IntType"){
			returnTy = Builder.getInt32Ty();
		}else if(ret_str == "BoolType"){
			returnTy = Builder.getInt1Ty();
		}

		std::vector<llvm::Type *> args;
		list<decafAST *> argASTList = param_list->getList();
		for(typename list<decafAST *>::iterator i = argASTList.begin(); i != argASTList.end(); i++){
			TypedSymbolAST *ts = (TypedSymbolAST *) *i;
			if(ts->getTypeStr()=="int"){
				args.push_back(Builder.getInt32Ty());
			}else if(ts->getTypeStr()=="bool"){
				args.push_back(Builder.getInt1Ty());
			}
		}

		llvm::FunctionType *FT;
		if(args.size()==0){
			 FT = llvm::FunctionType::get(returnTy, false);	
		}else{
			FT = llvm::FunctionType::get(returnTy, args, false);
		}

		llvm::Function *func = llvm::Function::Create(
			FT,
			llvm::Function::ExternalLinkage,
			name,
			TheModule
		);
    	syms.remove_symtbl();

		enter_symtbl(name, func);

		return func;

	}
	llvm::Value *Codegen(){
		syms.new_symtbl();
		llvm::Function *func = (llvm::Function *)syms.access_symtbl(name)->getVal();

		llvm::Type *returnTy = (llvm::Type *)return_type->Codegen();			//have to get return type of function here
		
		//std::vector<llvm::Type *> args = param_list->getMethodParamTypes();	//have to get list of function args here
		std::vector<llvm::Type *> args;
		list<decafAST *> argASTList = param_list->getList();
		for(typename list<decafAST *>::iterator i = argASTList.begin(); i != argASTList.end(); i++){
			TypedSymbolAST *ts = (TypedSymbolAST *) *i;
			if(ts->getTypeStr()=="int"){
				args.push_back(Builder.getInt32Ty());
			}else if(ts->getTypeStr()=="bool"){
				args.push_back(Builder.getInt1Ty());
			}
		}

		llvm::FunctionType *FT;
		if(args.size()==0){
			 FT = llvm::FunctionType::get(returnTy, false);	
		}else{
			FT = llvm::FunctionType::get(returnTy, args, false);
		}

		if(func == NULL){
			func = llvm::Function::Create(
				FT,
				llvm::Function::ExternalLinkage,
				name,
				TheModule
			);
		}

		// Get all args of TypedSymbolAST
		std::vector<string> names;
		for(typename list<decafAST *>::iterator i = argASTList.begin(); i != argASTList.end(); i++){
			TypedSymbolAST *ts = (TypedSymbolAST *) *i;
			names.push_back(ts->getName());
		}
		
		//// Set names for all arguments ////
		
		int Idx = 0;
		for (auto &Arg : func->args())
    		Arg.setName(names[Idx++]);

		//// Basic Block //////////		

		llvm::BasicBlock *BB = llvm::BasicBlock::Create(llvm::getGlobalContext(), "entry", func);
		Builder.SetInsertPoint(BB);

		// Extra variable creation////////////////////////////////////
		llvm::AllocaInst *Alloca;
		for (auto &Arg : func->args()) {
			 Alloca = Builder.CreateAlloca(Arg.getType(), nullptr, Arg.getName());

			Builder.CreateStore(&Arg, Alloca);
			enter_symtbl(Arg.getName(), Alloca);
		}
		///////////////////////////////////////////////////

		llvm::Value *blockRetVal = block->Codegen();

		// COMPARE RETURN TYPES//////////////////////////////////////////
		// Return Type
		llvm::Type *retType = func->getReturnType();
		llvm::Value *defaultRetVal;

		if(getString(return_type)=="VoidType" && defaultRet == true){
			defaultRetVal = Builder.CreateRetVoid();
		}else if(getString(return_type)=="IntType" && defaultRet == true){
			defaultRetVal = Builder.CreateRet(llvm::ConstantInt::get(llvm::getGlobalContext(), llvm::APInt(32, 0)));
		}else if(getString(return_type)=="BoolType" && defaultRet == true){
			defaultRetVal = Builder.CreateRet(llvm::ConstantInt::get(llvm::getGlobalContext(), llvm::APInt(1, 1)));
		}

		///////////////////////////////////////////////////////////////
		
		defaultRet = true;
		syms.remove_symtbl();
		enter_symtbl(name, func);

		return func;
	}
};


class Rvalue : public decafAST {
	string name;
	Expr *index;
public:
	Rvalue(string n) : name(n) {}
	Rvalue(string n, Expr *e) : name(n), index(e) {}
	~Rvalue() { if(index != NULL) { delete index; } }
	string ret_str;
	string str() {
		if(index != NULL){
			ret_str = string("ArrayLocExpr") + "(" + name + "," + getString(index) + ")"; 
		}else{
			ret_str = string("VariableExpr") + "(" + name + ")";
		}
	return ret_str;
	}
	llvm::Value *Codegen(){ 
		if(index != NULL){
			throw runtime_error("Array index allocation not supported yet");
		}else{
			descriptor *d = syms.access_symtbl(name);
			llvm::Value *v = d->getVal();
			return Builder.CreateLoad(v,name);

		}
	};

};

class Assign : public decafAST {
	string name;
	Expr *value = NULL;
	Expr *index = NULL;
public:
	Assign(string n, Expr *v) : name(n), value(v) {}
	Assign(string n, Expr *i, Expr *v) : name(n), index(i), value(v) {}
	~Assign(){
		if(value != NULL){ delete value; }
		if(index != NULL){ delete index; }
	}
	string str(){
		if(index == NULL){
			return string("AssignVar") + "(" + name + "," + getString(value) + ")";
		}else
		{
			return string("AssignArrayLoc") + "(" + name + "," + getString(index) + "," + getString(value) + ")";
		}
	}
	llvm::Value *Codegen(){ 
		if(index==NULL){
			descriptor *d = syms.access_symtbl(name);
			if(d==NULL){
				throw runtime_error("Cannot assign undeclared variable");
			}
			llvm::AllocaInst *Alloca = (llvm::AllocaInst *)d->getVal();
			
			llvm::Value *v = value->Codegen();


			if ( d->getVal()->getType() != v->getType()->getPointerTo() ){
				throw runtime_error("mismatched type for variable "+name);
			}

			//return Builder.CreateStore(value->Codegen(), d->getVal());
			return Builder.CreateStore(v, Alloca);
		}else{
			throw runtime_error("assign array loc not supported");
		}
	}
};

class Block : public decafAST {
	decafStmtList *stmt_list = NULL;
	decafStmtList *var_dec_list = NULL;
public:
	Block(decafStmtList *v, decafStmtList *s) : var_dec_list(v), stmt_list(s) {}
	~Block(){
		if(stmt_list != NULL){ delete stmt_list; }
		if(var_dec_list != NULL) { delete var_dec_list; }
	}
	string str(){
		return string("Block") + "(" + getString(var_dec_list) + "," + getString(stmt_list) + ")";
	}
	llvm::Value *Codegen(){ 
		syms.new_symtbl();
		llvm::Value *val = NULL;
		if(var_dec_list!=NULL){
			val = var_dec_list->Codegen();	
		}
		if( stmt_list != NULL){
			val = stmt_list->Codegen();	
		}
		syms.remove_symtbl();
		return val;
	};

};

class StatementAST : public decafAST {
	string state;
	Assign *assign = NULL;
	MethodCallAST *methCall = NULL;
	Block *if_block = NULL;
	Block *else_block = NULL;
	Block *while_block = NULL;
	Block *for_block = NULL;
	Expr *condition = NULL;
	decafStmtList *pre_assign_list = NULL;
	decafStmtList *loop_assign_list = NULL;
	Expr *return_value = NULL;
	Block *block = NULL;
	decafStmtList *eReturn = NULL;
	MethodDecl *temp;
public:
	StatementAST(Assign *a) : assign(a) {}
	StatementAST(MethodCallAST *m) : methCall(m) {}
	StatementAST(Expr *c, Block *i, Block *e) : condition(c), if_block(i), else_block(e) {}
	StatementAST(Expr *c, Block *w) : condition(c), while_block(w) {}
	StatementAST(decafStmtList *p, Expr *c, decafStmtList *l, Block* b) : pre_assign_list(p), condition(c), loop_assign_list(l), for_block(b){}
	StatementAST(Expr *r) : return_value(r) {}
	StatementAST(Block *b) : block(b) {}
	StatementAST(string s) : state(s) {}
	StatementAST(string s, decafStmtList *d) : state(s), eReturn(d) {}
	~StatementAST(){
		if(assign != NULL){ delete assign; }
		if(methCall != NULL){ delete methCall; }
		if(if_block != NULL){ delete if_block; }
		if(else_block != NULL){ delete else_block; }
		if(while_block != NULL){ delete while_block; }
		if(condition != NULL){ delete condition; }
		if(pre_assign_list != NULL){ delete pre_assign_list; }
		if(loop_assign_list != NULL){ delete loop_assign_list; }
		if(return_value != NULL){ delete return_value; }
		if(block != NULL){ delete block; }
		if(eReturn != NULL){ delete eReturn; }
	}
	string str(){
		if(assign != NULL){
			return getString(assign);
		}else if(methCall != NULL){
			return getString(methCall);
		}else if(condition != NULL && if_block != NULL){
			return string("IfStmt") + "(" + getString(condition) + "," + getString(if_block) + "," + getString(else_block) + ")";  
		}else if(condition != NULL && while_block != NULL){
			return string("WhileStmt") + "(" + getString(condition) + "," + getString(while_block) + ")";
		}else if(pre_assign_list != NULL && condition != NULL && loop_assign_list != NULL && for_block != NULL){
			return string("ForStmt") + "(" + getString(pre_assign_list) + "," + getString(condition) + "," + getString(loop_assign_list) + "," + getString(for_block) +")";
		}else if(return_value != NULL){
			return string("ReturnStmt") + "(" + getString(return_value) + ")";
		}else if(state == "break"){
			return string("BreakStmt");
		}else if(state == "continue"){
			return string("ContinueStmt");
		}else if(block != NULL){
			return getString(block);
		}else if(state == "return"){
			return string("ReturnStmt") + "(" + getString(eReturn) + ")";
		}
	}
	llvm::Value *Codegen(){ 
		if(assign != NULL){
			return assign -> Codegen();
		}
		else if(methCall != NULL){
			return methCall -> Codegen();
		}
		else if(block != NULL){
			return block -> Codegen();
		}
		else if(state == "return"){	
			defaultRet = false;
			return Builder.CreateRetVoid();
		}
		else if(return_value != NULL){
			llvm::Value *val = return_value -> Codegen();
			defaultRet = false;
			return Builder.CreateRet(val);
		}
		else if(condition != NULL && while_block != NULL){
		// Initialize
			llvm::Function *TheFunction = Builder.GetInsertBlock() -> getParent();
			llvm::BasicBlock *whilestartBB = llvm::BasicBlock::Create(llvm::getGlobalContext(), "whilestart", TheFunction);
			llvm::BasicBlock *whiledoBB = llvm::BasicBlock::Create(llvm::getGlobalContext(), "whiledo", TheFunction);
			llvm::BasicBlock *endBB = llvm::BasicBlock::Create(llvm::getGlobalContext(), "end", TheFunction);

			Builder.CreateBr(whilestartBB);
			
		// whilestart Basic Block
			Builder.SetInsertPoint(whilestartBB);
			llvm::Value *condV = condition->Codegen();
			Builder.CreateCondBr(condV, whiledoBB, endBB);

		// whiledo Basic Block
			Builder.SetInsertPoint(whiledoBB);
			while_block->Codegen();
			Builder.CreateBr(whilestartBB);

		// end Basic Block
			Builder.SetInsertPoint(endBB);
		}
		else if(pre_assign_list != NULL && condition != NULL && loop_assign_list != NULL && for_block != NULL){
		// Initialize
			llvm::Function *TheFunction = Builder.GetInsertBlock() -> getParent();
			llvm::BasicBlock *forstartBB = llvm::BasicBlock::Create(llvm::getGlobalContext(), "forstart", TheFunction);
			llvm::BasicBlock *fordoBB = llvm::BasicBlock::Create(llvm::getGlobalContext(), "fordo", TheFunction);
			llvm::BasicBlock *endBB = llvm::BasicBlock::Create(llvm::getGlobalContext(), "end", TheFunction);

			pre_assign_list->Codegen();
			
			Builder.CreateBr(forstartBB);

		// forstart Basic Block
			Builder.SetInsertPoint(forstartBB);
			llvm::Value *condV = condition->Codegen();
			Builder.CreateCondBr(condV, fordoBB, endBB);
			
		// fordo Basic Block
			Builder.SetInsertPoint(fordoBB);
			// block codegen
			for_block->Codegen();
			// iterate
			loop_assign_list->Codegen();
			Builder.CreateBr(forstartBB);

		// end Basic Block
			Builder.SetInsertPoint(endBB);

		}
		else if(condition != NULL && if_block != NULL && else_block != NULL){
			llvm::Function *TheFunction = Builder.GetInsertBlock() -> getParent();
			llvm::BasicBlock *ifStart = llvm::BasicBlock::Create(llvm::getGlobalContext(), "ifstart", TheFunction);
			Builder.CreateBr(ifStart);
			Builder.SetInsertPoint(ifStart);
			llvm::Value *condV = condition -> Codegen();
			TheFunction = Builder.GetInsertBlock() -> getParent();

			llvm::BasicBlock *iftrue = llvm::BasicBlock::Create(llvm::getGlobalContext(), "iftrue", TheFunction);
			llvm::BasicBlock *iffalse = llvm::BasicBlock::Create(llvm::getGlobalContext(), "iffalse");
			llvm::BasicBlock *end = llvm::BasicBlock::Create(llvm::getGlobalContext(), "end");

			Builder.CreateCondBr(condV, iftrue, iffalse);

			//iftrue block Code Generation
			Builder.SetInsertPoint(iftrue);
			llvm::Value *vIfTrue = if_block -> Codegen();
			Builder.CreateBr(end);
			iftrue = Builder.GetInsertBlock();

			//end block Code Genration (merge block)
			TheFunction -> getBasicBlockList().push_back(end);
			
			//iffalse block Code Generation
			TheFunction -> getBasicBlockList().push_back(iffalse);
			Builder.SetInsertPoint(iffalse);
			llvm::Value *vIfFalse = else_block -> Codegen();
			Builder.CreateBr(end);
			iffalse = Builder.GetInsertBlock();
			
			Builder.SetInsertPoint(end);
			defaultRet = true;
		}
		else if(condition != NULL && if_block != NULL && else_block == NULL){
			llvm::Function *TheFunction = Builder.GetInsertBlock() -> getParent();
			llvm::BasicBlock *ifStart = llvm::BasicBlock::Create(llvm::getGlobalContext(), "ifstart", TheFunction);
			Builder.CreateBr(ifStart);
			Builder.SetInsertPoint(ifStart);
			llvm::Value *condV = condition -> Codegen();
			TheFunction = Builder.GetInsertBlock() -> getParent();

			llvm::BasicBlock *iftrue = llvm::BasicBlock::Create(llvm::getGlobalContext(), "iftrue", TheFunction);
			llvm::BasicBlock *end = llvm::BasicBlock::Create(llvm::getGlobalContext(), "end");

			Builder.CreateCondBr(condV, iftrue, end);

			//iftrue block Code Generation
			Builder.SetInsertPoint(iftrue);
			llvm::Value *vIfTrue = if_block -> Codegen();
			Builder.CreateBr(end);
			iftrue = Builder.GetInsertBlock();

			TheFunction -> getBasicBlockList().push_back(end);
			Builder.SetInsertPoint(end);
			defaultRet = true;
		}
		else{
			throw runtime_error("statement not currently supported");
		}
	}
};

class Constant : public decafAST {
	string type;
	int intval;
	bool boolval;
	char charval;
public:
	Constant(int val) : intval(val) { type = string("int");}
	Constant(bool val) : boolval(val) { type = string("bool");}
	Constant(char val) : charval(val) { type = string("char");}
	~Constant(){}
	string getType(){return type;}
	int getInt(){return intval;}
	bool getBool(){return boolval;}
	char getChar(){return charval;}
};

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Code Generation ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// prog = Program(extern* extern_list, package body)
// extern = ExternFunction(identifier name, method_type return_type, extern_type* typelist)
// package = Package(identifier name, field_decl* field_list, method_decl* method_list)
// extern_type = VarDef(StringType) | VarDef(decaf_type)
// method_decl = Method(identifier name, method_type return_type, typed_symbol* param_list, method_block block)
// method_block = MethodBlock(typed_symbol* var_decl_list, statement* statement_list)
// block = Block(typed_symbol* var_decl_list, statement* statement_list)
// statement = assign
//      | method_call
//      | ReturnStmt(expr? return_value)
//		| block
// assign = AssignVar(identifier name, expr value)
// expr = rvalue
//      | method_call
//      | NumberExpr(int value)
//      | BoolExpr(bool value)
//      | BinaryExpr(binary_operator op, expr left_value, expr right_value)
//		| UnaryExpr(unary_operator op, expr value)
// rvalue = VariableExpr(identifier name)
// decaf_type = IntType | BoolType
// method_type = VoidType | decaf_type
// typed_symbol = VarDef(identifier name, decaf_type type)
// method_call = MethodCall(identifier name, method_arg* method_arg_list)
// method_arg = StringConstant(string value)
//	| expr
// bool = True | False
// binary_operator = Plus | Minus | Mult | Div | Leftshift | Rightshift | Mod | Lt | Gt | Leq | Geq | Eq | Neq | And | Or
// unary_operator = UnaryMinus | Not
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
