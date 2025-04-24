// Polyphonic sine wave synth

module AudioController(
    input        clk,     
    output       chSel,
    output       audioOut,  
    output       audioEn,
    inout        ps2_clk,
    inout        ps2_data,
    input        reset 
);
    assign chSel   = 1'b0;
    assign audioEn = 1'b1;

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

    // Frequency lookup table
    reg [11:0] PS2_FREQs [0:255];
    initial $readmemh("PS2_to_freq.mem", PS2_FREQs);

    // Constants for octave transposition, overdrive, and pitch modulation
    localparam [7:0] Z_KEY = 8'h1A;  
    localparam [7:0] X_KEY = 8'h22;  
    localparam [7:0] C_KEY = 8'h21;  
    localparam [7:0] V_KEY = 8'h2A;  
    localparam [7:0] B_KEY = 8'h32;  

    localparam integer MAX_OCTAVE     = 3;
    localparam integer MIN_OCTAVE     = -3;
    localparam integer MAX_PITCH_MOD  = 100;   // Hz
    localparam integer PITCH_MOD_STEP = 4;    // Hz
    localparam integer DELAY_DEPTH    = 1024;

    // state registers
    reg signed [2:0]  octave_shift;
    reg               delay_on;
    reg signed [7:0]  pitch_mod;

    // Polyphony parameters
    localparam integer MAX_KEYS = 8;
    integer   i, idx;

    reg [7:0] active_keys [0:MAX_KEYS-1];
    reg       key_active  [0:MAX_KEYS-1];

    // handle PS/2 events
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
                // key releases
                for (i = 0; i < MAX_KEYS; i = i + 1)
                    if (active_keys[i] == rx_data)
                        key_active[i] <= 1'b0;
            end else begin
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

    // DDS and lookup table parameters
    localparam SYSTEM_FREQ_HZ = 100_000_000;
    localparam PHASE_WIDTH    = 32;
    localparam LUT_ADDR_BITS  = 8;
    localparam LUT_SIZE       = 1 << LUT_ADDR_BITS;
    localparam PWM_BITS       = 10;
    localparam [31:0] PHASE_INC_MULT = 32'd42;

    reg [PWM_BITS-1:0] sine_lut [0:LUT_SIZE-1];
    initial $readmemh("sine_lut.mem", sine_lut);

    // phase accumulators and increments
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
        wire signed [31:0] signed_f  = $signed(shifted_f);
        wire signed [31:0] final_f_s = signed_f + pitch_mod;

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

    // voice mixing
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

    // Overdrive buffer
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

    // PWM output
    reg [PWM_BITS-1:0] pwm_counter = 0;
    always @(posedge clk)
        pwm_counter <= pwm_counter + 1;
    assign audioOut = (pwm_counter < total_sine);

endmodule
