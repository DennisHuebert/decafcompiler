	.text
	.file	"llvm/test/multi-list.llvm.bc"
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
	.bss
	.globl	a
	.align	16
a:
	.zero	400
	.size	a, 400

	.type	b,@object               # @b
	.globl	b
	.align	16
b:
	.zero	400
	.size	b, 400

	.type	c,@object               # @c
	.globl	c
	.align	16
c:
	.zero	400
	.size	c, 400


	.section	".note.GNU-stack","",@progbits
