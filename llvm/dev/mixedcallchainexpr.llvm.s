	.text
	.file	"llvm/dev/mixedcallchainexpr.llvm.bc"
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
	movl	%esi, (%rsp)
	movl	%esi, %edi
	callq	print_int
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
	movl	%edi, 4(%rsp)
	andl	$1, %esi
	movb	%sil, 3(%rsp)
	movl	4(%rsp), %edi
	callq	print_int
	movzbl	3(%rsp), %edi
	andl	$1, %edi
	callq	print_int
	movb	3(%rsp), %al
	xorb	$1, %al
	movl	4(%rsp), %esi
	incl	%esi
	movzbl	%al, %edi
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
	movl	%esi, (%rsp)
	movl	%esi, %edi
	callq	print_int
	movzbl	7(%rsp), %edi
	andl	$1, %edi
	callq	print_int
	movl	(%rsp), %edi
	incl	%edi
	movb	7(%rsp), %al
	xorb	$1, %al
	movzbl	%al, %esi
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
	movl	$1, %esi
	callq	test1
	xorl	%eax, %eax
	popq	%rcx
	retq
.Lfunc_end3:
	.size	main, .Lfunc_end3-main
	.cfi_endproc


	.section	".note.GNU-stack","",@progbits
