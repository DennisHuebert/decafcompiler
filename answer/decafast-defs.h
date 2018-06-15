
#ifndef _DECAF_DEFS
#define _DECAF_DEFS

#include "llvm/IR/DerivedTypes.h"
#include "llvm/IR/LLVMContext.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/Type.h"
#include "llvm/IR/Verifier.h"
#include "llvm/IR/IRBuilder.h"
#include <cstdio> 
#include <cstdlib>
#include <cstring> 
#include <string>
#include <stdexcept>
#include <vector>
#include <iostream>

using namespace std;

extern int lineno;
extern int tokenpos;

class descriptor{
public:
	int lineno;
	llvm::Value *val;
	descriptor(int num){
		lineno = num;
	}
	descriptor(llvm::Value *v){
		val = v;		
	}
	void print(){
		cerr << "line: " << lineno << endl;
	}
	llvm::Value *getVal(){
		return val;
	}
};

#include "symbol_table.cc"

extern "C"
{
	extern int yyerror(const char *);
	int yyparse(void);
	int yylex(void);  
	int yywrap(void);
}

#endif