module PlayBackController (
    input clk,                    // System clock
    input reset,                  // Reset signal
    input [31:0] audio_data,      // Audio data from processor
    input data_valid,             // Signal indicating new data is available
    output reg audioOut           // PWM audio output
);
    // Audio processing parameters
    reg [15:0] current_sample = 0;
    reg [15:0] pwm_counter = 0;
    
    // Handle new audio data and generate PWM
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            current_sample <= 16'h8000;  // Middle value (silence)
            pwm_counter <= 0;
            audioOut <= 0;
        end else begin
            // Accept new sample when available
            if (data_valid) begin
                current_sample <= audio_data[15:0]; // Use lower 16 bits
            end
            
            // PWM generation - simple PWM
            pwm_counter <= pwm_counter + 1;
            audioOut <= (pwm_counter < current_sample) ? 1'b1 : 1'b0;
        end
    end
endmodule
