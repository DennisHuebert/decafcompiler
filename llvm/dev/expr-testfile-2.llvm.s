	.text
	.file	"llvm/dev/expr-testfile-2.llvm.bc"
	.globl	main
	.align	16, 0x90
	.type	main,@function
main:                                   # @main
	.cfi_startproc
# BB#0:                                 # %end6
	pushq	%rax
.Ltmp0:
	.cfi_def_cfa_offset 16
	movl	$958, 4(%rsp)           # imm = 0x3BE
	movl	$-958, 4(%rsp)          # imm = 0xFFFFFFFFFFFFFC42
	movb	$1, 3(%rsp)
	movb	$0, 2(%rsp)
	movb	3(%rsp), %al
	movb	%al, %cl
	notb	%cl
	testb	$1, %cl
	je	.LBB0_2
# BB#1:                                 # %scfalse
	orb	2(%rsp), %al
.LBB0_2:                                # %end
	andb	$1, %al
	movb	%al, 3(%rsp)
	movl	4(%rsp), %edi
	negl	%edi
	callq	print_int
	xorl	%eax, %eax
	popq	%rcx
	retq
.Lfunc_end0:
	.size	main, .Lfunc_end0-main
	.cfi_endproc


	.section	".note.GNU-stack","",@progbits
