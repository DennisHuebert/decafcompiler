	.text
	.file	"llvm/dev/or.llvm.bc"
	.globl	main
	.align	16, 0x90
	.type	main,@function
main:                                   # @main
	.cfi_startproc
# BB#0:                                 # %end19
	pushq	%rax
.Ltmp0:
	.cfi_def_cfa_offset 16
	movl	$1, %edi
	callq	print_int
	movl	$1, %edi
	callq	print_int
	movl	$1, %edi
	callq	print_int
	xorl	%edi, %edi
	callq	print_int
	xorl	%eax, %eax
	popq	%rcx
	retq
.Lfunc_end0:
	.size	main, .Lfunc_end0-main
	.cfi_endproc


	.section	".note.GNU-stack","",@progbits
