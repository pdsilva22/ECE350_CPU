main:
	jal read_switches
    add $a0, $v0, $0
    nop
    nop
    nop
    nop
	jal led  #turn on LED corresponding to switch
    addi $s5, $0, 1     #sets s5 to hold one (use this in blt check to avoid playing song if no switches on)
    nop
    nop
    nop
    nop
    blt $a0, $s5, main    #continuously check switches for input to determine which song to play from memory 
    nop
    nop
    nop
    nop
	jal play_song
	j main    #when we j main, need to somehow reset switches or else will immediately start song 1 again

led:
	sw $a0, 4097($0)
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
    addi $a0, $a0, -1 #subtract 1 to get correct offset in memory (song 1 starts at index 0, song 2 at index 257, etc)
    nop
    nop
    nop
    nop
    sll $t1, $a0, 8         # $t1 = $a0 * 256 (each song in memory is 256 lines, this gives us base address in memory to start reading from)
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
    lw $t0, 0($t5)          # load sample from memory 
    nop
    nop
    nop
    nop
    add $a0, $0, $t0
    nop
    nop
    nop
    nop
    jal led           #display duty cycle value on leds

    # Nested loop to repeat the sw command many times for the current sample
    #Done to ensure each note is played for a sufficient amount of time 
    addi $t6, $0, 20000       # $t6 = 2000 (number of repetitions)
    nop
    nop
    nop
    nop
    sll $t6, $t6, 5       #increase loop counter
    nop
    nop
    nop

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
    bne $t6, $0, repeat_loop # If $t6 != 0, repeat the sw to set pwm signal
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
   
