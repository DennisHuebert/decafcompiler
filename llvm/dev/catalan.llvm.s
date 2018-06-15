	.text
	.file	"llvm/dev/catalan.llvm.bc"
	.globl	main
	.align	16, 0x90
	.type	main,@function
main:                                   # @main
	.cfi_startproc
# BB#0:                                 # %entry
	pushq	%rax
.Ltmp0:
	.cfi_def_cfa_offset 16
	callq	read_int
	movl	%eax, %edi
	callq	cat
	movl	%eax, %edi
	callq	print_int
	popq	%rax
	retq
.Lfunc_end0:
	.size	main, .Lfunc_end0-main
	.cfi_endproc

	.globl	fact
	.align	16, 0x90
	.type	fact,@function
fact:                                   # @fact
	.cfi_startproc
# BB#0:                                 # %entry
	pushq	%rbx
.Ltmp1:
	.cfi_def_cfa_offset 16
	subq	$16, %rsp
.Ltmp2:
	.cfi_def_cfa_offset 32
.Ltmp3:
	.cfi_offset %rbx, -16
	movl	%edi, 12(%rsp)
	cmpl	$1, 12(%rsp)
	jne	.LBB1_3
# BB#1:                                 # %iftrue
	movl	$1, %eax
	jmp	.LBB1_2
.LBB1_3:                                # %iffalse
	movl	12(%rsp), %ebx
	leal	-1(%rbx), %edi
	callq	fact
	imull	%ebx, %eax
.LBB1_2:                                # %iftrue
	addq	$16, %rsp
	popq	%rbx
	retq
.Lfunc_end1:
	.size	fact, .Lfunc_end1-fact
	.cfi_endproc

	.globl	choose
	.align	16, 0x90
	.type	choose,@function
choose:                                 # @choose
	.cfi_startproc
# BB#0:                                 # %entry
	pushq	%rbp
.Ltmp4:
	.cfi_def_cfa_offset 16
	pushq	%rbx
.Ltmp5:
	.cfi_def_cfa_offset 24
	pushq	%rax
.Ltmp6:
	.cfi_def_cfa_offset 32
.Ltmp7:
	.cfi_offset %rbx, -24
.Ltmp8:
	.cfi_offset %rbp, -16
	movl	%edi, 4(%rsp)
	movl	%esi, (%rsp)
	movl	4(%rsp), %edi
	callq	fact
	movl	%eax, %ebx
	movl	(%rsp), %edi
	callq	fact
	movl	%eax, %ebp
	movl	4(%rsp), %edi
	subl	(%rsp), %edi
	callq	fact
	movl	%eax, %ecx
	imull	%ebp, %ecx
	movl	%ebx, %eax
	cltd
	idivl	%ecx
	addq	$8, %rsp
	popq	%rbx
	popq	%rbp
	retq
.Lfunc_end2:
	.size	choose, .Lfunc_end2-choose
	.cfi_endproc

	.globl	cat
	.align	16, 0x90
	.type	cat,@function
cat:                                    # @cat
	.cfi_startproc
# BB#0:                                 # %entry
	pushq	%rax
.Ltmp9:
	.cfi_def_cfa_offset 16
	movl	%edi, %eax
	movl	%eax, 4(%rsp)
	leal	(%rax,%rax), %edi
	movl	%eax, %esi
	callq	choose
	movl	4(%rsp), %ecx
	incl	%ecx
	cltd
	idivl	%ecx
	popq	%rcx
	retq
.Lfunc_end3:
	.size	cat, .Lfunc_end3-cat
	.cfi_endproc


	.section	".note.GNU-stack","",@progbits
