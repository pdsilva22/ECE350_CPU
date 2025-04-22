main:
    addi $1, $0, 4096       # $1 = address to read switches
    lw   $2, 0($1)          # $2 = switch value (SW[15:0])
    addi $3, $0, 1          # $3 = mask = 0x1
    addi $5, $0, 0          # $5 = song index = 0

check_switches:
    and  $4, $2, $3         # $4 = result of masked switch
    nop
    nop
    nop
    nop
    bne  $4, $0, play_song  # If bit is ON, jump to play_song
    sll  $3, $3, 1          # shift mask left
    addi $5, $5, 1          # increment song index
    nop
    nop
    nop
    nop
    bne  $5, $16, check_switches  # Loop while index < 16
    j done                  # None pressed, halt

play_song:
    sll  $6, $5, 8          # $6 = song address offset = song# * 256
    addi $7, $0, 256        # $7 = sample count (loop limit)
    addi $8, $0, 0          # $8 = offset within song

play_loop:
    add  $9, $6, $8         # $9 = current sample address
    lw   $10, 0($9)         # $10 = current sample
    addi $11, $0, 4097      # $11 = audioOut I/O address
    sw   $10, 0($11)        # send to audioOut
    addi $8, $8, 1          # offset++
    nop
    nop
    nop
    nop
    bne  $8, $7, play_loop  # loop until 256 samples played

done:
    j done                  # loop forever