	.text
	.file	"llvm/dev/forloop.llvm.bc"
	.globl	f
	.align	16, 0x90
	.type	f,@function
f:                                      # @f
	.cfi_startproc
# BB#0:                                 # %entry
	movl	$5, -12(%rsp)
	movl	$0, -4(%rsp)
	jmp	.LBB0_1
	.align	16, 0x90
.LBB0_2:                                # %fordo
                                        #   in Loop: Header=BB0_1 Depth=1
	movl	$1, -8(%rsp)
	incl	-4(%rsp)
.LBB0_1:                                # %forstart
                                        # =>This Inner Loop Header: Depth=1
	movl	-4(%rsp), %eax
	cmpl	-12(%rsp), %eax
	jl	.LBB0_2
# BB#3:                                 # %end
	retq
.Lfunc_end0:
	.size	f, .Lfunc_end0-f
	.cfi_endproc


	.section	".note.GNU-stack","",@progbits
