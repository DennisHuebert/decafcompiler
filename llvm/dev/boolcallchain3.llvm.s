	.text
	.file	"llvm/dev/boolcallchain3.llvm.bc"
	.globl	test3
	.align	16, 0x90
	.type	test3,@function
test3:                                  # @test3
	.cfi_startproc
# BB#0:                                 # %entry
	pushq	%rax
.Ltmp0:
	.cfi_def_cfa_offset 16
	andl	$1, %edi
	movb	%dil, 7(%rsp)
	movzbl	7(%rsp), %edi
	andl	$1, %edi
	callq	print_int
	popq	%rax
	retq
.Lfunc_end0:
	.size	test3, .Lfunc_end0-test3
	.cfi_endproc

	.globl	test2
	.align	16, 0x90
	.type	test2,@function
test2:                                  # @test2
	.cfi_startproc
# BB#0:                                 # %entry
	pushq	%rax
.Ltmp1:
	.cfi_def_cfa_offset 16
	andl	$1, %edi
	movb	%dil, 7(%rsp)
	movzbl	7(%rsp), %edi
	andl	$1, %edi
	callq	print_int
	movzbl	7(%rsp), %edi
	callq	test3
	popq	%rax
	retq
.Lfunc_end1:
	.size	test2, .Lfunc_end1-test2
	.cfi_endproc

	.globl	test1
	.align	16, 0x90
	.type	test1,@function
test1:                                  # @test1
	.cfi_startproc
# BB#0:                                 # %entry
	pushq	%rax
.Ltmp2:
	.cfi_def_cfa_offset 16
	andl	$1, %edi
	movb	%dil, 7(%rsp)
	movzbl	7(%rsp), %edi
	andl	$1, %edi
	callq	print_int
	movzbl	7(%rsp), %edi
	callq	test2
	popq	%rax
	retq
.Lfunc_end2:
	.size	test1, .Lfunc_end2-test1
	.cfi_endproc

	.globl	main
	.align	16, 0x90
	.type	main,@function
main:                                   # @main
	.cfi_startproc
# BB#0:                                 # %entry
	pushq	%rax
.Ltmp3:
	.cfi_def_cfa_offset 16
	movl	$1, %edi
	callq	test1
	xorl	%eax, %eax
	popq	%rcx
	retq
.Lfunc_end3:
	.size	main, .Lfunc_end3-main
	.cfi_endproc


	.section	".note.GNU-stack","",@progbits
