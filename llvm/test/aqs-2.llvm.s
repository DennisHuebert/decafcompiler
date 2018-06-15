	.text
	.file	"llvm/test/aqs-2.llvm.bc"
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

	.type	list,@object            # @list
	.bss
	.globl	list
	.align	16
list:
	.zero	400
	.size	list, 400


	.section	".note.GNU-stack","",@progbits
