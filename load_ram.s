main:
    add $s0, $s0, $0   #base index
    addi $s1, $0, 0         # $s1 = loop index (offset)
    addi $s2, $0, 256       # $t4 = 256 (loop limit)
    j play_loop

led:
	sw $a0, 4097($0)
	nop
	nop
	nop
	nop
	jr $ra

play_loop:
    nop
    nop
    nop
    nop
    blt $s1, $s2, continue_loop
    nop
	nop
	nop
	nop
    j done            # if $t3 >= 256, exit

continue_loop:
    add $s3, $s0, $s1       # $s3 = current address
    nop
	nop
	nop
	nop
    lw $a0, 0($s3)          # load sample
    nop
    nop
    nop
    nop
    jal led
    addi $t6, $0, 20000       # $t6 = 2000 (number of repetitions)
    nop
    nop
    nop
    nop
    sll $t6, $t6, 10   #wait for one second
    nop
    nop
    nop
    nop
    addi $s1, $s1, -1
    j wait

wait:
    nop
    nop
    nop
    nop
    addi $t6, $t6, -1        # Decrease repetition counter
    nop
    nop
    nop
    nop
    bne $t6, $0, wait
    nop
    nop
    nop
    nop
    j play_loop
   
done:
    j done
