	.text
	.file	"llvm/dev/arith1.llvm.bc"
	.globl	main
	.align	16, 0x90
	.type	main,@function
main:                                   # @main
	.cfi_startproc
# BB#0:                                 # %scstart
	pushq	%rax
.Ltmp0:
	.cfi_def_cfa_offset 16
	movb	$1, 6(%rsp)
	movb	$0, 5(%rsp)
	movb	$1, 4(%rsp)
	movb	6(%rsp), %al
	movb	%al, %cl
	notb	%cl
	testb	$1, %cl
	je	.LBB0_2
# BB#1:                                 # %scfalse
	movb	4(%rsp), %cl
	xorb	$1, %cl
	andb	5(%rsp), %cl
	orb	%cl, %al
.LBB0_2:                                # %end
	andb	$1, %al
	movb	%al, 7(%rsp)
	movl	$0, (%rsp)
	xorl	%edi, %edi
	callq	print_int
	xorl	%eax, %eax
	popq	%rcx
	retq
.Lfunc_end0:
	.size	main, .Lfunc_end0-main
	.cfi_endproc


	.section	".note.GNU-stack","",@progbits
