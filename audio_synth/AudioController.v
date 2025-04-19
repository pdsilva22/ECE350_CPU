// prev square wave synth

/*

module AudioController(
    input        clk, 		// System Clock Input 100 Mhz
    input        micData,	// Microphone Output
    input[12:0]   switches,	// Tone control switches
    output reg   micClk = 0, 	// Mic clock 
    output       chSel,		// Channel select; 0 for rising edge, 1 for falling edge
    output       audioOut,	// PWM signal to the audio jack	
    output       audioEn,   // Audio Enable
    inout ps2_clk,          // PS2 interface clock
    inout ps2_data,         // PS2 interface data
    input reset);        
    localparam MHz = 1000000;
    localparam SYSTEM_FREQ = 100*MHz; // System clock frequency
    localparam MAX_ACTIVE_KEYS = 8;   // Maximum number of keys that can be played simultaneously
    
    // Constants for octave transposition
    localparam Z_KEY = 8'h1A;  // Z key scan code for octave down
    localparam X_KEY = 8'h22;  // X key scan code for octave up
    localparam C_KEY = 8'h21;  // C key scan code for reverb toggle
    localparam MAX_OCTAVE = 3; // Maximum octave shift up
    localparam MIN_OCTAVE = -3; // Maximum octave shift down
    
    // Constants for pitch modulation and vibrato
    localparam V_KEY = 8'h2A;  // V key scan code for pitch mod down
    localparam B_KEY = 8'h32;  // B key scan code for pitch mod up
    localparam N_KEY = 8'h31;  // N key scan code for vibrato toggle
    localparam MAX_PITCH_MOD = 50; // Maximum pitch modulation amount
    localparam PITCH_MOD_STEP = 2; // Step size for pitch modulation changes
    
    // Reverb toggle
    reg reverb_enabled = 0;
    
    // Pitch modulation state
    reg signed [7:0] pitch_mod_amount = 0; // Current pitch modulation amount
    
    // Vibrato state
    reg vibrato_enabled = 0;
    reg [23:0] vibrato_counter = 0;
    reg signed [7:0] vibrato_value = 0;
    localparam VIBRATO_DEPTH = 15;  // Maximum vibrato depth
    localparam VIBRATO_RATE = 100000; // Vibrato frequency rate divisor
        
    assign chSel   = 1'b0;  // Collect Mic Data on the rising edge 
    assign audioEn = 1'b1;  // Enable Audio Output
    
    // Initialize PS2 - frequency table
    reg [11:0] PS2_FREQs[0:255];  // 12-bit values for each scan code
    initial begin
        $readmemh("PS2_to_freq.mem", PS2_FREQs);
    end
    
    // Audio Interface with PS2 Keyboard
    wire read_data;
    wire[7:0] rx_data;
    reg[7:0] latched_rx_data;
    Ps2Interface controller(.ps2_clk(ps2_clk), .ps2_data(ps2_data), .clk(clk), .rst(reset), .rx_data(rx_data), .read_data(read_data));
    
    // Track all active keys (up to a maximum of MAX_ACTIVE_KEYS)
    reg [7:0] active_keys [0:MAX_ACTIVE_KEYS-1];
    reg [MAX_ACTIVE_KEYS-1:0] key_active;  // Bitmap of active key slots
    
    // Octave transposition state
    reg signed [3:0] octave_shift = 0;  // Current octave shift (-3 to +3)
    
    // Flag for keyboard break code
    reg waiting_for_break = 0;
    
    // Variables for looping constructs
    integer i, j, k;
    reg [3:0] found_slot;
    
    // Mix the tones - simple additive mixing
    // Count the number of active tones
    reg [3:0] active_tone_count;
    reg [3:0] active_tone_sum;
    
    // Generate tones for all active keys
    reg [MAX_ACTIVE_KEYS-1:0] tones;            // Tones for each active key
    reg [17:0] counters [0:MAX_ACTIVE_KEYS-1];  // Counters for each active key
    
    // Apply octave transpose to frequencies - fixed function implementation
    function [11:0] transpose_frequency;
        input [11:0] base_freq;
        input signed [3:0] shift_amount;
        reg [11:0] result;
        begin
            result = base_freq;
            
            // For positive shifts (higher octaves) - multiply by powers of 2
            if (shift_amount == 1)
                result = base_freq << 1;
            else if (shift_amount == 2)
                result = base_freq << 2;
            else if (shift_amount == 3)
                result = base_freq << 3;
            // For negative shifts (lower octaves) - divide by powers of 2
            else if (shift_amount == -1)
                result = base_freq >> 1;
            else if (shift_amount == -2)
                result = base_freq >> 2;
            else if (shift_amount == -3)
                result = base_freq >> 3;
            else
                result = base_freq; // No shift (0)
                
            transpose_frequency = result;
        end
    endfunction
    
    // Fixed pitch modulation function that properly handles both upward and downward pitch changes
    function [11:0] apply_pitch_mod;
        input [11:0] base_freq;
        input signed [7:0] mod_amount;
        input signed [7:0] vib_amount;
        reg [15:0] temp;
        reg [15:0] mod_value;
        reg [15:0] vib_value;
        reg [11:0] result;
        begin
            // Start with base frequency
            temp = base_freq;
            
            // Apply vibrato if vib_amount is non-zero
            if (vib_amount != 0) begin
                vib_value = (temp * $unsigned(vib_amount > 0 ? vib_amount : -vib_amount)) >> 5;
                if (vib_amount > 0)
                    temp = temp + vib_value;
                else
                    temp = temp - vib_value;
            end
            
            // Apply pitch modulation - properly handle both positive and negative values
            if (mod_amount != 0) begin
                // Calculate modulation value based on percentage
                mod_value = (temp * $unsigned(mod_amount > 0 ? mod_amount : -mod_amount)) >> 6;
                
                // Apply modulation based on direction
                if (mod_amount > 0)
                    temp = temp + mod_value;  // Pitch up
                else 
                    temp = (temp > mod_value) ? (temp - mod_value) : 1;  // Pitch down with underflow protection
            end
            
            // Ensure we don't overflow or underflow
            result = (temp > 12'hFFF) ? 12'hFFF : 
                     (temp < 12'h001) ? 12'h001 : temp[11:0];
            apply_pitch_mod = result;
        end
    endfunction
    
    // Frequency calculation for each active key
    wire [11:0] transposed_freqs [0:MAX_ACTIVE_KEYS-1];
    wire [11:0] modulated_freqs [0:MAX_ACTIVE_KEYS-1];
    wire [17:0] limits [0:MAX_ACTIVE_KEYS-1];
    
    // Calculate transposed frequencies for all active keys
    genvar g;
    generate
        for (g = 0; g < MAX_ACTIVE_KEYS; g = g + 1) begin : gen_freqs
            // First apply octave shift
            assign transposed_freqs[g] = transpose_frequency(PS2_FREQs[active_keys[g]], octave_shift);
            // Then apply pitch modulation and vibrato - only pass vibrato_value when enabled
            assign modulated_freqs[g] = apply_pitch_mod(transposed_freqs[g], pitch_mod_amount, 
                                                       vibrato_enabled ? vibrato_value : 0);
            // Finally calculate the counter limit for tone generation
            assign limits[g] = (key_active[g] && modulated_freqs[g] > 0) ? 
                              (SYSTEM_FREQ/(2*modulated_freqs[g])) - 1 : 0;
        end
    endgenerate
    
    // Vibrato LFO (Low-Frequency Oscillator)
    always @(posedge clk) begin
        if (reset) begin
            vibrato_counter <= 0;
            vibrato_value <= 0;
        end else if (vibrato_enabled) begin
            vibrato_counter <= vibrato_counter + 1;
            
            if (vibrato_counter >= VIBRATO_RATE) begin
                vibrato_counter <= 0;
                
                // Simple oscillation - if value is 0 or positive, go negative, otherwise go positive
                if (vibrato_value >= 0)
                    vibrato_value <= -VIBRATO_DEPTH;
                else
                    vibrato_value <= VIBRATO_DEPTH;
            end
        end else begin
            // When vibrato is disabled, reset counter and value
            vibrato_counter <= 0;
            vibrato_value <= 0;
        end
    end
   
    // Process keyboard input for all keys
    always @(posedge clk) begin
        if (read_data) begin
            if (rx_data == 8'hF0) begin
                // We got the break prefix; next byte is the key being released
                waiting_for_break <= 1;
            end else if (waiting_for_break) begin
                // Process key release
                waiting_for_break <= 0;
                
                // Find and remove the released key
                for (i = 0; i < MAX_ACTIVE_KEYS; i = i + 1) begin
                    if (key_active[i] && active_keys[i] == rx_data) begin
                        key_active[i] <= 0;  // Mark the slot as inactive
                    end
                end
            end else begin
                // Process octave transpose keys
                if (rx_data == Z_KEY && octave_shift > MIN_OCTAVE) begin
                    // Z key - transpose down one octave (divide frequency by 2)
                    octave_shift <= octave_shift - 1;
                end else if (rx_data == X_KEY && octave_shift < MAX_OCTAVE) begin
                    // X key - transpose up one octave (multiply frequency by 2)
                    octave_shift <= octave_shift + 1;
                end else if (rx_data == C_KEY) begin
                    // C key - toggle reverb effect
                    reverb_enabled <= ~reverb_enabled;
                end else if (rx_data == V_KEY && pitch_mod_amount > -MAX_PITCH_MOD) begin
                    // V key - decrease pitch (negative modulation)
                    pitch_mod_amount <= pitch_mod_amount - PITCH_MOD_STEP;
                end else if (rx_data == B_KEY && pitch_mod_amount < MAX_PITCH_MOD) begin
                    // B key - increase pitch (positive modulation)
                    pitch_mod_amount <= pitch_mod_amount + PITCH_MOD_STEP;
                end else if (rx_data == N_KEY) begin
                    // N key - toggle vibrato effect
                    // vibrato_enabled <= ~vibrato_enabled;
                end else if (PS2_FREQs[rx_data] > 0) begin
                    // Process tone-generating keys (any key with a non-zero frequency)
                    // Check if key is already active (prevent duplicates)
                    found_slot = 4'hF; // Initialize to an invalid value
                    for (i = 0; i < MAX_ACTIVE_KEYS; i = i + 1) begin
                        if (key_active[i] && active_keys[i] == rx_data) begin
                            found_slot = i[3:0];
                        end
                    end
                    
                    // If key isn't already active, find an empty slot
                    if (found_slot == 4'hF) begin
                        found_slot = 4'hF;
                        for (i = 0; i < MAX_ACTIVE_KEYS; i = i + 1) begin
                            if (!key_active[i] && found_slot == 4'hF) begin
                                found_slot = i[3:0];
                            end
                        end
                        
                        // If we found an empty slot, add the key
                        if (found_slot != 4'hF) begin
                            active_keys[found_slot] <= rx_data;
                            key_active[found_slot] <= 1;
                        end
                    end
                end
            end
        end
    end
    
    // Generate tones for all active keys
    always @(posedge clk) begin
        for (k = 0; k < MAX_ACTIVE_KEYS; k = k + 1) begin
            if (key_active[k] && limits[k] > 0) begin
                if (counters[k] >= limits[k]) begin
                    counters[k] <= 0;
                    tones[k] <= ~tones[k];
                end else begin
                    counters[k] <= counters[k] + 1;
                end
            end else begin
                tones[k] <= 0;
                counters[k] <= 0;
            end
        end
    end
    
    // Mix all active tones
    always @(posedge clk) begin
        active_tone_count = 0;
        active_tone_sum = 0;
        
        for (j = 0; j < MAX_ACTIVE_KEYS; j = j + 1) begin
            if (key_active[j]) begin
                active_tone_count = active_tone_count + 1;
                active_tone_sum = active_tone_sum + tones[j];
            end
        end
    end
    
    // Generate PWM signal based on mixed tones
    wire [9:0] pwm_value;
    assign pwm_value = (active_tone_sum > 0) ? 10'b1111111111 : 10'b0000000000;
    
    // Audio output is enabled if any key is active
    wire audio_out_en;
    assign audio_out_en = (active_tone_count > 0);
    
    //////////////////////////////////////////////////
    /////// Simple Echo Reverb
    //////////////////////////////////////////////////
    // FIFO-based delay line
    localparam DELAY_LENGTH = 16000; // adjust based on desired echo (~16000 for ~160ms @100kHz)
    reg [9:0] delay_line [0:DELAY_LENGTH-1];
    reg [13:0] delay_index = 0;

    reg [9:0] dry_signal;
    reg [9:0] wet_signal;
    reg [9:0] mixed_signal;

    always @(posedge clk) begin
        if (audio_out_en) begin
            dry_signal <= pwm_value;

            // Get the delayed sample
            wet_signal <= delay_line[delay_index];

            // Mix current and delayed sample
            mixed_signal <= (dry_signal >> 1) + (wet_signal >> 1); // 50% dry, 50% wet

            // Write current sample into delay line
            delay_line[delay_index] <= dry_signal;

            // Move circular buffer index
            delay_index <= (delay_index == DELAY_LENGTH - 1) ? 0 : delay_index + 1;
        end else begin
            mixed_signal <= 0;
        end
    end
    
    // PWM Serializer Audio Output
    PWMSerializer serial(clk, reset, audio_out_en, reverb_enabled ? mixed_signal : pwm_value, audioOut);
    
    // Initialize active key registers
    initial begin
        for (i = 0; i < MAX_ACTIVE_KEYS; i = i + 1) begin
            active_keys[i] = 8'h00;
            key_active[i] = 0;
            counters[i] = 0;
            tones[i] = 0;
        end
        octave_shift = 0;    // Start at default octave
        pitch_mod_amount = 0; // Start with no pitch modulation
        vibrato_enabled = 0;  // Start with vibrato disabled
        vibrato_value = 0;    // Start with zero vibrato effect
    end
endmodule

*/

// Polyphonic sine wave synth

/*
module AudioController(
    input        clk,        // 100?MHz
    input        micData,    // unused
    input [12:0] switches,   // unused
    output reg   micClk = 0,
    output       chSel,
    output       audioOut,   // PWM audio output
    output       audioEn,
    inout        ps2_clk,
    inout        ps2_data,
    input        reset       // asynchronous reset
);
    // static assignments
    assign chSel   = 1'b0;
    assign audioEn = 1'b1;

    //================================================================
    // PS/2 keyboard interface
    wire [7:0] rx_data;
    wire       read_data;
    reg        waiting_break = 1'b0;

    Ps2Interface ps2(
        .ps2_clk   (ps2_clk),
        .ps2_data  (ps2_data),
        .clk       (clk),
        .rst       (reset),
        .rx_data   (rx_data),
        .read_data (read_data)
    );

    //================================================================
    // Frequency lookup table
    reg [11:0] PS2_FREQs [0:255];
    initial $readmemh("PS2_to_freq.mem", PS2_FREQs);

    //================================================================
    // Constants for octave transposition, delay, and pitch modulation
    localparam [7:0] Z_KEY = 8'h1A;  // Z make code for octave down
    localparam [7:0] X_KEY = 8'h22;  // X make code for octave up
    localparam [7:0] C_KEY = 8'h21;  // C make code for delay toggle
    localparam [7:0] V_KEY = 8'h2A;  // V make code for pitch mod down
    localparam [7:0] B_KEY = 8'h32;  // B make code for pitch mod up

    localparam integer MAX_OCTAVE     = 3;
    localparam integer MIN_OCTAVE     = -3;
    localparam integer MAX_PITCH_MOD  = 100;   // Hz
    localparam integer PITCH_MOD_STEP = 4;    // Hz
    localparam integer DELAY_DEPTH    = 1024;

    // state registers
    reg signed [2:0]  octave_shift;
    reg               delay_on;
    reg signed [7:0]  pitch_mod;

    //================================================================
    // Polyphony parameters
    localparam integer MAX_KEYS = 8;
    integer   i, idx;

    reg [7:0] active_keys [0:MAX_KEYS-1];
    reg       key_active  [0:MAX_KEYS-1];

    // handle PS/2 events: note make/break, toggles
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            waiting_break  <= 1'b0;
            octave_shift   <= 3'd0;
            delay_on       <= 1'b0;
            pitch_mod      <= 8'sd0;
            for (i = 0; i < MAX_KEYS; i = i + 1) begin
                active_keys[i] <= 8'h00;
                key_active[i]  <= 1'b0;
            end
        end else if (read_data) begin
            if (rx_data == 8'hF0) begin
                waiting_break <= 1'b1;
            end else if (waiting_break) begin
                waiting_break <= 1'b0;
                // release notes
                for (i = 0; i < MAX_KEYS; i = i + 1)
                    if (active_keys[i] == rx_data)
                        key_active[i] <= 1'b0;
            end else begin
                // make code: handle toggles first
                if (rx_data == Z_KEY) begin
                    if (octave_shift > MIN_OCTAVE) octave_shift <= octave_shift - 1;
                end else if (rx_data == X_KEY) begin
                    if (octave_shift < MAX_OCTAVE) octave_shift <= octave_shift + 1;
                end else if (rx_data == C_KEY) begin
                    delay_on <= ~delay_on;
                end else if (rx_data == V_KEY) begin
                    if (pitch_mod > -MAX_PITCH_MOD) pitch_mod <= pitch_mod - PITCH_MOD_STEP;
                end else if (rx_data == B_KEY) begin
                    if (pitch_mod <  MAX_PITCH_MOD) pitch_mod <= pitch_mod + PITCH_MOD_STEP;
                end else if (PS2_FREQs[rx_data] != 12'd0) begin
                    // musical key ? allocate voice
                    idx = MAX_KEYS;
                    for (i = 0; i < MAX_KEYS; i = i + 1)
                        if ((idx == MAX_KEYS) && !key_active[i])
                            idx = i;
                    if (idx < MAX_KEYS) begin
                        active_keys[idx] <= rx_data;
                        key_active[idx]  <= 1'b1;
                    end
                end
            end
        end
    end

    //================================================================
    // DDS & Lookup Table parameters
    localparam SYSTEM_FREQ_HZ = 100_000_000;
    localparam PHASE_WIDTH    = 32;
    localparam LUT_ADDR_BITS  = 8;
    localparam LUT_SIZE       = 1 << LUT_ADDR_BITS;
    localparam PWM_BITS       = 10;
    localparam [31:0] PHASE_INC_MULT = 32'd42;

    reg [PWM_BITS-1:0] sine_lut [0:LUT_SIZE-1];
    initial $readmemh("sine_lut.mem", sine_lut);

    // phase accumulators and increments per voice
    reg  [PHASE_WIDTH-1:0] phase_acc [0:MAX_KEYS-1];
    wire [PHASE_WIDTH-1:0] phase_inc [0:MAX_KEYS-1];

    generate
      genvar k;
      for (k = 0; k < MAX_KEYS; k = k + 1) begin : DDS_GEN
        // base frequency
        wire [31:0] base_f = PS2_FREQs[active_keys[k]];
        // octave shift
        wire [31:0] shifted_f =
            (octave_shift > 0) ? (base_f <<  octave_shift) :
            (octave_shift < 0) ? (base_f >> -octave_shift) :
                                  base_f;
        // pitch modulation: signed add
        wire signed [31:0] signed_f  = $signed(shifted_f);
        wire signed [31:0] final_f_s = signed_f + pitch_mod;
        // clamp negative to zero
        wire [31:0] final_f = final_f_s < 0 ? 32'd0 : final_f_s;

        assign phase_inc[k] = final_f * PHASE_INC_MULT;

        always @(posedge clk or posedge reset) begin
            if (reset)
                phase_acc[k] <= 0;
            else if (key_active[k])
                phase_acc[k] <= phase_acc[k] + phase_inc[k];
        end
      end
    endgenerate

    // mix voices
    reg [PWM_BITS+4:0] sine_sum;
    integer active_count;
    always @(*) begin
        sine_sum     = 0;
        active_count = 0;
        for (i = 0; i < MAX_KEYS; i = i + 1) begin
            if (key_active[i]) begin
                sine_sum     = sine_sum +
                    sine_lut[phase_acc[i][PHASE_WIDTH-1 -: LUT_ADDR_BITS]];
                active_count = active_count + 1;
            end
        end
    end
    wire [PWM_BITS-1:0] mixed_sine =
        (active_count > 0) ? (sine_sum / active_count) : 0;

    //================================================================
    // Delay buffer
    reg [PWM_BITS-1:0] delay_buf [0:DELAY_DEPTH-1];
    reg [$clog2(DELAY_DEPTH)-1:0] delay_ptr;
    always @(posedge clk or posedge reset) begin
        if (reset) delay_ptr <= 0;
        else begin
            delay_buf[delay_ptr] <= mixed_sine;
            delay_ptr            <= delay_ptr + 1;
        end
    end
    wire [PWM_BITS-1:0] delayed_sine = delay_buf[delay_ptr];
    wire [PWM_BITS-1:0] total_sine   =
        delay_on ? ((mixed_sine + delayed_sine) >> 1) : mixed_sine;

    //================================================================
    // PWM output
    reg [PWM_BITS-1:0] pwm_counter = 0;
    always @(posedge clk)
        pwm_counter <= pwm_counter + 1;
    assign audioOut = (pwm_counter < total_sine);

endmodule
*/
