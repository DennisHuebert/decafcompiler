	.text
	.file	"llvm/dev/charescapevals.llvm.bc"
	.globl	main
	.align	16, 0x90
	.type	main,@function
main:                                   # @main
	.cfi_startproc
# BB#0:                                 # %entry
	pushq	%rax
.Ltmp0:
	.cfi_def_cfa_offset 16
	movl	$9, %edi
	callq	print_int
	movl	$11, %edi
	callq	print_int
	movl	$13, %edi
	callq	print_int
	movl	$10, %edi
	callq	print_int
	movl	$7, %edi
	callq	print_int
	movl	$12, %edi
	callq	print_int
	movl	$8, %edi
	callq	print_int
	movl	$92, %edi
	callq	print_int
	movl	$39, %edi
	callq	print_int
	xorl	%eax, %eax
	popq	%rcx
	retq
.Lfunc_end0:
	.size	main, .Lfunc_end0-main
	.cfi_endproc


	.section	".note.GNU-stack","",@progbits
