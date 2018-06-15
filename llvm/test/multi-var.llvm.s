	.text
	.file	"llvm/test/multi-var.llvm.bc"
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

	.type	a,@object               # @a
	.local	a
	.comm	a,4,4
	.type	b,@object               # @b
	.local	b
	.comm	b,4,4
	.type	c,@object               # @c
	.local	c
	.comm	c,4,4

	.section	".note.GNU-stack","",@progbits
