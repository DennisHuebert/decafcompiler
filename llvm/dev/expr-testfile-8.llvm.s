	.text
	.file	"llvm/dev/expr-testfile-8.llvm.bc"
	.globl	main
	.align	16, 0x90
	.type	main,@function
main:                                   # @main
	.cfi_startproc
# BB#0:                                 # %entry
	subq	$24, %rsp
.Ltmp0:
	.cfi_def_cfa_offset 32
	movl	$958, 20(%rsp)          # imm = 0x3BE
	imull	$-30, 8(%rsp), %eax
	leal	80(%rax), %ecx
	movl	%ecx, 12(%rsp)
	movl	$-80, %ecx
	subl	%eax, %ecx
	movl	%ecx, 8(%rsp)
	movb	$0, 19(%rsp)
	movl	20(%rsp), %edi
	callq	print_int
	xorl	%eax, %eax
	addq	$24, %rsp
	retq
.Lfunc_end0:
	.size	main, .Lfunc_end0-main
	.cfi_endproc


	.section	".note.GNU-stack","",@progbits
