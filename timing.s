main:
	jal read_mem
	add $s0, $v0, $0
	addi $a0, $s0, 10   
	nop
	nop
	nop
	nop
	jal write_mem
	j main

write_mem:
	sw $a0, 4097($0)
	nop
	nop
	nop
	nop
	jr $ra

read_mem:
	lw $v0, 4096($0)
	nop
	nop
	nop
	nop
	jr $ra

