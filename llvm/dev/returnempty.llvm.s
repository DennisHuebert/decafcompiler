	.text
	.file	"llvm/dev/returnempty.llvm.bc"
	.globl	f
	.align	16, 0x90
	.type	f,@function
f:                                      # @f
	.cfi_startproc
# BB#0:                                 # %entry
	retq
.Lfunc_end0:
	.size	f, .Lfunc_end0-f
	.cfi_endproc


	.section	".note.GNU-stack","",@progbits
