main:
    addi $1, $0, 4096       # Address of input-mapped I/O (SW)
    nop
    nop
    nop
    lw   $2, 0($1)          # Load switch input into $2
    addi $3, $0, 1          # Constant 1 for masking

check_switches:
    and  $4, $2, $3         # Check if current switch bit is set
    nop
    nop
    nop
    nop
    beq  $4, $0, shift_next # If not set, check next
    addi $5, $0, 0          # Song index (will be increased below)

    # Calculate song start address = song index * 256
    sll  $6, $5, 8          # $6 = base address of song in memory

    # Set up loop counter for song length
    addi $7, $0, 256        # 256 samples
    addi $8, $0, 0          # Offset into song

play_song:
    add  $9, $6, $8         # Current song address = base + offset
    lw   $10, 0($9)         # Load sample
    addi $11, $0, 4097      # Audio output-mapped I/O address
    sw   $10, 0($11)        # Write sample to audioOut
    addi $8, $8, 1          # offset++
    nop
    nop
    nop
    nop
    bne  $8, $7, play_song  # Loop until all samples played

done:
    j done                 # Halt (infinite loop)

shift_next:
    sll  $3, $3, 1          # Shift mask left
    addi $5, $5, 1          # Song index++
    nop
    nop
    nop
    nop
    blt  $5, 16, check_switches  # Max 16 switches
    j done