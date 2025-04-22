# Song Player Program with song data preloading
# Memory map:
# 0x1000 (4096): Switch input read address
# 0x1001 (4097): LED output write address
# 0x1002 (4098): Audio output write address
# 0x2000-0x2FFF: Song storage area

.data
# Constants
SWITCH_ADDR:    .word 0x1000      # Address to read switches
LED_ADDR:       .word 0x1001      # Address to control LEDs
AUDIO_ADDR:     .word 0x1002      # Address to send audio data

# Bitmasks
MASK1:          .word 0x0001      # Mask for switch 0
MASK2:          .word 0x0002      # Mask for switch 1
MASK3:          .word 0x0004      # Mask for switch 2
MASK4:          .word 0x0008      # Mask for switch 3

# Song storage parameters
SONG_START:     .word 0x2000      # Start of song storage area
SONG1_ADDR:     .word 0x2000      # Start address of song 1
SONG1_LEN:      .word 16          # Length of song 1 in samples
SONG2_ADDR:     .word 0x2100      # Start address of song 2
SONG2_LEN:      .word 16          # Length of song 2 in samples
SONG3_ADDR:     .word 0x2200      # Start address of song 3
SONG3_LEN:      .word 16          # Length of song 3 in samples
SONG4_ADDR:     .word 0x2300      # Start address of song 4
SONG4_LEN:      .word 16          # Length of song 4 in samples

# Variables
current_song:   .word 0           # Current song being played
play_position:  .word 0           # Current position in song
last_switches:  .word 0           # Last switch state

# Song data (simplified for example)
# Song 1 - Basic ascending scale
song1_data:    .word 0x4000, 0x4800, 0x5000, 0x5800    # First four notes
               .word 0x6000, 0x6800, 0x7000, 0x7800    # Next four notes
               .word 0x8000, 0x8800, 0x9000, 0x9800    # Next four notes
               .word 0xA000, 0xA800, 0xB000, 0xB800    # Last four notes

# Song 2 - Basic descending scale
song2_data:    .word 0xB800, 0xB000, 0xA800, 0xA000    # First four notes
               .word 0x9800, 0x9000, 0x8800, 0x8000    # Next four notes  
               .word 0x7800, 0x7000, 0x6800, 0x6000    # Next four notes
               .word 0x5800, 0x5000, 0x4800, 0x4000    # Last four notes

# Song 3 - Simple melody
song3_data:    .word 0x5000, 0x6000, 0x7000, 0x5000    # First four notes
               .word 0x5000, 0x6000, 0x7000, 0x5000    # Next four notes
               .word 0x7000, 0x8000, 0x9000, 0x7000    # Next four notes
               .word 0x7000, 0x6000, 0x5000, 0x4000    # Last four notes

# Song 4 - Simple rhythm
song4_data:    .word 0x8000, 0x4000, 0x8000, 0x4000    # First four notes
               .word 0x8000, 0x4000, 0x8000, 0x4000    # Next four notes
               .word 0x9000, 0x4000, 0x9000, 0x4000    # Next four notes
               .word 0x9000, 0x4000, 0x9000, 0x4000    # Last four notes

.text
main:
    # Initialize registers
    addi $sp, $0, 0x1000          # Initialize stack pointer
    add $s0, $0, $0               # Clear current song register
    add $s1, $0, $0               # Clear position counter
    add $s2, $0, $0               # Clear last switch state
    
    # Call subroutine to load songs into memory
    jal load_songs
    
main_loop:
    # Read switch input
    lw $t0, SWITCH_ADDR($0)       # Read current switch state
    lw $t1, last_switches($0)     # Load previous switch state
    beq $t0, $t1, check_playing   # If no change, skip to playing check
    
    # Update last switch state
    sw $t0, last_switches($0)
    
    # Update LEDs to match switches
    sw $t0, LED_ADDR($0)
    
    # Check which switch is on (using priority encoder logic)
    add $s0, $0, $0               # Reset current song
    
    # Check switch 0
    lw $t3, MASK1($0)             # Load bitmask for switch 0
    and $t2, $t0, $t3             # Apply mask
    beq $t2, $0, check_switch1
    addi $s0, $0, 1               # Song 1 selected
    j setup_song
    
check_switch1:
    lw $t3, MASK2($0)             # Load bitmask for switch 1
    and $t2, $t0, $t3             # Apply mask
    beq $t2, $0, check_switch2
    addi $s0, $0, 2               # Song 2 selected
    j setup_song
    
check_switch2:
    lw $t3, MASK3($0)             # Load bitmask for switch 2
    and $t2, $t0, $t3             # Apply mask
    beq $t2, $0, check_switch3
    addi $s0, $0, 3               # Song 3 selected
    j setup_song
    
check_switch3:
    lw $t3, MASK4($0)             # Load bitmask for switch 3
    and $t2, $t0, $t3             # Apply mask
    beq $t2, $0, no_song
    addi $s0, $0, 4               # Song 4 selected
    j setup_song

no_song:
    # No song selected, reset position
    add $s1, $0, $0
    sw $0, AUDIO_ADDR($0)         # Send silence to audio output
    j check_playing

setup_song:
    # Reset position for new song
    add $s1, $0, $0

check_playing:
    # Check if we have a song to play
    beq $s0, $0, main_loop
    
    # Play the current song - use jump table approach
    addi $t0, $0, 1
    beq $s0, $t0, play_song1
    addi $t0, $0, 2
    beq $s0, $t0, play_song2
    addi $t0, $0, 3
    beq $s0, $t0, play_song3
    addi $t0, $0, 4
    beq $s0, $t0, play_song4
    j main_loop                    # Shouldn't reach here
    
play_song1:
    lw $t0, SONG1_ADDR($0)         # Get song start address
    lw $t1, SONG1_LEN($0)          # Get song length
    j play_sample
    
play_song2:
    lw $t0, SONG2_ADDR($0)         # Get song start address
    lw $t1, SONG2_LEN($0)          # Get song length
    j play_sample
    
play_song3:
    lw $t0, SONG3_ADDR($0)         # Get song start address
    lw $t1, SONG3_LEN($0)          # Get song length
    j play_sample
    
play_song4:
    lw $t0, SONG4_ADDR($0)         # Get song start address
    lw $t1, SONG4_LEN($0)          # Get song length
    j play_sample
    
play_sample:
    # Check if we've reached the end of the song
    slt $t2, $s1, $t1
    beq $t2, $0, song_end
    
    # Calculate current sample address
    add $t3, $t0, $s1              # Base address + position
    sll $t3, $t3, 2                # Multiply by 4 for word addressing
    lw $t4, 0($t3)                 # Load sample data
    
    # Output to audio
    sw $t4, AUDIO_ADDR($0)         # Send to audio output
    
    # Increment position
    addi $s1, $s1, 1
    
    # Delay for sample rate timing
    jal delay
    
    j main_loop
    
song_end:
    # Reset position to restart the song
    add $s1, $0, $0
    j main_loop
    
# Delay subroutine - adjust to control sample playback rate
delay:
    addi $t9, $0, 1000             # Delay count (adjust for playback speed)
delay_loop:
    addi $t9, $t9, -1
    bne $t9, $0, delay_loop
    jr $ra

# Load songs into memory at startup
load_songs:
    # Save return address
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    # Load Song 1
    la $t0, song1_data             # Source address
    lw $t1, SONG1_ADDR($0)         # Destination address
    lw $t2, SONG1_LEN($0)          # Length
    jal copy_song
    
    # Load Song 2
    la $t0, song2_data             # Source address
    lw $t1, SONG2_ADDR($0)         # Destination address
    lw $t2, SONG2_LEN($0)          # Length
    jal copy_song
    
    # Load Song 3
    la $t0, song3_data             # Source address
    lw $t1, SONG3_ADDR($0)         # Destination address
    lw $t2, SONG3_LEN($0)          # Length
    jal copy_song
    
    # Load Song 4
    la $t0, song4_data             # Source address
    lw $t1, SONG4_ADDR($0)         # Destination address
    lw $t2, SONG4_LEN($0)          # Length
    jal copy_song
    
    # Restore return address and return
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

# Copy song data subroutine
# t0: source address
# t1: destination address
# t2: number of words to copy
copy_song:
    # Save return address
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    # Initialize counter
    add $t3, $0, $0                # Counter
    
copy_loop:
    # Check if we're done
    beq $t3, $t2, copy_done
    
    # Calculate source address
    sll $t4, $t3, 2                # Multiply by 4 for word addressing
    add $t5, $t0, $t4              # Source address + offset
    lw $t6, 0($t5)                 # Load value
    
    # Calculate destination address
    sll $t7, $t3, 2                # Multiply by 4 for word addressing
    add $t8, $t1, $t7              # Destination address + offset
    sw $t6, 0($t8)                 # Store value
    
    # Increment counter
    addi $t3, $t3, 1
    j copy_loop
    
copy_done:
    # Restore return address and return
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra