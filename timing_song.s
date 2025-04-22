main:
	jal read_switches
	add $a0, $v0, $0
	jal led  #turn on LED corresponding to switch
	#based on value in s0, determine which song to play
	jal play_song
	j main

led:
	sw $a0, 4097($0)
	nop
	nop
	nop
	nop
	jr $ra

read_switches:
	lw $v0, 4096($0)
	nop
	nop
	nop
	nop
	jr $ra

play_song:
    # Calculate base address of selected song
    sll $t1, $a0, 8         # $t1 = $a0 * 256
    add $t2, $t1, $0        # $t2 = base address
    addi $t3, $0, 0         # $t3 = loop index (offset)

play_loop:
    addi $t4, $0, 256       # $t4 = 256 (loop limit)
    nop
    nop
    nop
    nop
    blt $t3, $t4, continue_loop
    j play_done             # if $t3 >= 256, exit

continue_loop:
    add $t5, $t2, $t3       # $t5 = current address
    lw $t0, 0($t5)          # load sample
    sw $t0, 4097($0)        # write to audioOut
    nop
    nop
    nop
    nop
    addi $t3, $t3, 1        # $t3++
    j play_loop

play_done:
    jr $ra


