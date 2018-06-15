	.text
	.file	"llvm/test/aqs.llvm.bc"
	.globl	main
	.align	16, 0x90
	.type	main,@function
main:                                   # @main
	.cfi_startproc
# BB#0:                                 # %entry
	retq
.Lfunc_end0:
	.size	main, .Lfunc_end0-main
	.cfi_endproc

	.type	x,@object               # @x
	.local	x
	.comm	x,4,4

	.section	".note.GNU-stack","",@progbits
