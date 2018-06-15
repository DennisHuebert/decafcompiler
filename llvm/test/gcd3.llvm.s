	.text
	.file	"llvm/test/gcd3.llvm.bc"
	.globl	main
	.align	16, 0x90
	.type	main,@function
main:                                   # @main
	.cfi_startproc
# BB#0:                                 # %entry
	pushq	%rbx
.Ltmp0:
	.cfi_def_cfa_offset 16
.Ltmp1:
	.cfi_offset %rbx, -16
	callq	read_int
	movl	%eax, %ebx
	callq	read_int
	movl	%ebx, %edi
	movl	%eax, %esi
	callq	gcd
	movl	%eax, %edi
	callq	print_int
	xorl	%eax, %eax
	popq	%rbx
	retq
.Lfunc_end0:
	.size	main, .Lfunc_end0-main
	.cfi_endproc

	.globl	gcd
	.align	16, 0x90
	.type	gcd,@function
gcd:                                    # @gcd
	.cfi_startproc
# BB#0:                                 # %entry
	pushq	%rax
.Ltmp2:
	.cfi_def_cfa_offset 16
	movl	%edi, 4(%rsp)
	movl	%esi, (%rsp)
	cmpl	$0, (%rsp)
	je	.LBB1_1
# BB#2:                                 # %iffalse
	movl	(%rsp), %edi
	movl	4(%rsp), %eax
	cltd
	idivl	%edi
	movl	%edx, %esi
	callq	gcd
	popq	%rcx
	retq
.LBB1_1:                                # %iftrue
	movl	4(%rsp), %eax
	popq	%rcx
	retq
.Lfunc_end1:
	.size	gcd, .Lfunc_end1-gcd
	.cfi_endproc

	.type	a,@object               # @a
	.data
	.align	4
a:
	.long	10                      # 0xa
	.size	a, 4

	.type	b,@object               # @b
	.align	4
b:
	.long	20                      # 0x14
	.size	b, 4


	.section	".note.GNU-stack","",@progbits
