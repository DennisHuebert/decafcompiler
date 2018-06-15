	.text
	.file	"llvm/dev/whileloop.llvm.bc"
	.globl	f
	.align	16, 0x90
	.type	f,@function
f:                                      # @f
	.cfi_startproc
# BB#0:                                 # %entry
	.align	16, 0x90
.LBB0_1:                                # %whiledo
                                        # =>This Inner Loop Header: Depth=1
	movl	$1, -4(%rsp)
	jmp	.LBB0_1
.Lfunc_end0:
	.size	f, .Lfunc_end0-f
	.cfi_endproc


	.section	".note.GNU-stack","",@progbits
