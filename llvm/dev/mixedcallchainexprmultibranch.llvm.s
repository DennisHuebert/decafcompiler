	.text
	.file	"llvm/dev/mixedcallchainexprmultibranch.llvm.bc"
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

	.globl	test2b
	.align	16, 0x90
	.type	test2b,@function
test2b:                                 # @test2b
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
	movl	4(%rsp), %esi
	movzbl	3(%rsp), %edi
	callq	test3
	popq	%rax
	retq
.Lfunc_end1:
	.size	test2b, .Lfunc_end1-test2b
	.cfi_endproc

	.globl	test2a
	.align	16, 0x90
	.type	test2a,@function
test2a:                                 # @test2a
	.cfi_startproc
# BB#0:                                 # %entry
	pushq	%rax
.Ltmp2:
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
.Lfunc_end2:
	.size	test2a, .Lfunc_end2-test2a
	.cfi_endproc

	.globl	test1
	.align	16, 0x90
	.type	test1,@function
test1:                                  # @test1
	.cfi_startproc
# BB#0:                                 # %entry
	pushq	%rax
.Ltmp3:
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
	callq	test2a
	movl	(%rsp), %edi
	incl	%edi
	movb	7(%rsp), %al
	xorb	$1, %al
	movzbl	%al, %esi
	callq	test2b
	popq	%rax
	retq
.Lfunc_end3:
	.size	test1, .Lfunc_end3-test1
	.cfi_endproc

	.globl	main
	.align	16, 0x90
	.type	main,@function
main:                                   # @main
	.cfi_startproc
# BB#0:                                 # %entry
	pushq	%rax
.Ltmp4:
	.cfi_def_cfa_offset 16
	movl	$1, %edi
	movl	$1, %esi
	callq	test1
	xorl	%eax, %eax
	popq	%rcx
	retq
.Lfunc_end4:
	.size	main, .Lfunc_end4-main
	.cfi_endproc


	.section	".note.GNU-stack","",@progbits
