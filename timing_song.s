main:
	jal read_switches
    add $a0, $v0, $0
    nop
    nop
    nop
    nop
	jal led  #turn on LED corresponding to switch
    
    addi $s5, $0, 1     #sets s5 to hold one (use this to avoid playing song if no switches on)
    nop
    nop
    nop
    nop
    blt $a0, $s5, main    #keep looping main if no input switches flipped
    nop
    nop
    nop
    nop
	jal play_song
    j end
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
    addi $a0, $a0, -1 #will not work for song 3 (4-1 = 3, should be 2)
    nop
    nop
    nop
    nop
    sll $t1, $a0, 8         # $t1 = $a0 * 256
    nop
	nop
	nop
	nop
    add $t2, $t1, $0        # $t2 = base address
    addi $t3, $0, 0         # $t3 = loop index (offset)
    addi $t4, $0, 256       # $t4 = 256 (loop limit)

play_loop:
    nop
    nop
    nop
    nop
    blt $t3, $t4, continue_loop
    nop
	nop
	nop
	nop
    j play_done             # if $t3 >= 256, exit

continue_loop:
    add $t5, $t2, $t3       # $t5 = current address
    nop
	nop
	nop
	nop
    lw $t0, 0($t5)          # load sample

    # Nested loop to repeat the sw command 2000 times for the current sample
    addi $t6, $0, 2000       # $t6 = 2000 (number of repetitions)
    nop
    nop
    nop
    
repeat_loop:
    sw $t0, 4098($0)         # Write the sample value to audioOut (4097)
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
    nop
	nop
	nop
	nop
    addi $t3, $t3, 1         # Increment the song sample index ($t3++)
    nop
	nop
	nop
	nop
    j play_loop              # Jump back to check the next sample

play_done:
    jr $ra                    # Return from play_song
    #need to somehow reset switches before immediately doing load store from main

end:
    j end
