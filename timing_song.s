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

    # Nested loop to repeat the sw command 2000 times for the current sample
    addi $t6, $0, 2000       # $t6 = 2000 (number of repetitions)
repeat_loop:
    sw $t0, 4097($0)         # Write the sample value to audioOut (4097)
    nop
    nop
    nop
    nop
    addi $t6, $t6, -1        # Decrease repetition counter
    nop
    nop
    nop
    nop
    bne $t6, $0, repeat_loop # If $t6 != 0, repeat the write

    addi $t3, $t3, 1         # Increment the song sample index ($t3++)
    j play_loop              # Jump back to check the next sample

play_done:
    jr $ra                    # Return from play_song


