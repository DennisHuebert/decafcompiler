	.text
	.file	"llvm/dev/stringconst-3.llvm.bc"
	.globl	main
	.align	16, 0x90
	.type	main,@function
main:                                   # @main
	.cfi_startproc
# BB#0:                                 # %entry
	pushq	%rax
.Ltmp0:
	.cfi_def_cfa_offset 16
	movl	$.Lglobalstring, %edi
	callq	print_string
	movl	$.Lglobalstring.1, %edi
	callq	print_string
	movl	$.Lglobalstring.2, %edi
	callq	print_string
	xorl	%eax, %eax
	popq	%rcx
	retq
.Lfunc_end0:
	.size	main, .Lfunc_end0-main
	.cfi_endproc

	.type	.Lglobalstring,@object  # @globalstring
	.section	.rodata.str1.1,"aMS",@progbits,1
.Lglobalstring:
	.asciz	"hello,"
	.size	.Lglobalstring, 7

	.type	.Lglobalstring.1,@object # @globalstring.1
.Lglobalstring.1:
	.asciz	" world"
	.size	.Lglobalstring.1, 7

	.type	.Lglobalstring.2,@object # @globalstring.2
.Lglobalstring.2:
	.asciz	"\n"
	.size	.Lglobalstring.2, 2


	.section	".note.GNU-stack","",@progbits
