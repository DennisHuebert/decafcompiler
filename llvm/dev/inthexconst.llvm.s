	.text
	.file	"llvm/dev/inthexconst.llvm.bc"
	.globl	main
	.align	16, 0x90
	.type	main,@function
main:                                   # @main
	.cfi_startproc
# BB#0:                                 # %entry
	pushq	%rax
.Ltmp0:
	.cfi_def_cfa_offset 16
	xorl	%edi, %edi
	callq	print_int
	movl	$6575, %edi             # imm = 0x19AF
	callq	print_int
	movl	$-6575, %edi            # imm = 0xFFFFFFFFFFFFE651
	callq	print_int
	xorl	%eax, %eax
	popq	%rcx
	retq
.Lfunc_end0:
	.size	main, .Lfunc_end0-main
	.cfi_endproc


	.section	".note.GNU-stack","",@progbits
