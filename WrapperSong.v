module Wrapper (
    input clk_100mhz,
    input BTNU, 
    inout ps2_clk,
    inout ps2_data,
    input [15:0] SW,
    output audioOut,
    output reg [15:0] LED
);
    wire clock, reset;
    assign clock = clk_50mhz;
    assign reset = BTNU; 
    wire rwe, mwe;
    wire[4:0] rd, rs1, rs2;
    wire[31:0] instAddr, instData, 
        rData, regA, regB,
        memAddr, memDataIn, memDataOut, q_dmem;
    reg [15:0] SW_Q, SW_M;  
    
    wire io_read, io_write, audio_write;
    wire audio_data_valid;
    
    wire clk_50mhz;
    wire locked;
    
    // Clock generator
    clk_wiz_0 pll(
      // Clock out ports
      .clk_out1(clk_50mhz),
      // Status and control signals
      .reset(1'b0),
      .locked(locked),
      // Clock in ports
      .clk_in1(clk_100mhz)
    );
     
    // IO address decoding
    assign io_read = (memAddr == 32'd4096) ? 1'b1 : 1'b0;  // 0x1000: Switch read
    assign io_write = (memAddr == 32'd4097) ? 1'b1 : 1'b0; // 0x1001: LED write
    assign audio_write = (memAddr == 32'd4098) ? 1'b1 : 1'b0; // 0x1002: Audio write
    assign audio_data_valid = audio_write & mwe;
    
    // Switch input synchronization
    always @(negedge clock) begin
        SW_M <= SW;
        SW_Q <= SW_M; 
    end
    
    // LED output handling
    always @(posedge clock) begin
        if (io_write == 1'b1 && mwe) begin
            LED <= memDataIn[15:0];
        end
    end
    
    // Memory data mux
    assign q_dmem = (io_read == 1'b1) ? {16'h0000, SW_Q} : memDataOut;
    
    // Memory file
    localparam INSTR_FILE = "playsong";
    
    // Main Processing Unit
    processor CPU(
        .clock(clock), 
        .reset(reset), 
        // ROM
        .address_imem(instAddr), 
        .q_imem(instData),
        // Regfile
        .ctrl_writeEnable(rwe),
        .ctrl_writeReg(rd),
        .ctrl_readRegA(rs1),
        .ctrl_readRegB(rs2), 
        .data_writeReg(rData), 
        .data_readRegA(regA), 
        .data_readRegB(regB),                              
        // RAM
        .wren(mwe), 
        .address_dmem(memAddr), 
        .data(memDataIn), 
        .q_dmem(q_dmem)
    ); 
    
    // Instruction Memory (ROM)
    ROM #(.MEMFILE({INSTR_FILE, ".mem"}))
    InstMem(
        .clk(clock), 
        .addr(instAddr[11:0]), 
        .dataOut(instData)
    );
    
    // Register File
    regfile RegisterFile(
        .clock(clock), 
        .ctrl_writeEnable(rwe), 
        .ctrl_reset(reset), 
        .ctrl_writeReg(rd),
        .ctrl_readRegA(rs1), 
        .ctrl_readRegB(rs2), 
        .data_writeReg(rData), 
        .data_readRegA(regA), 
        .data_readRegB(regB)
    );
                        
    // Processor Memory (RAM)
    RAM ProcMem(
        .clk(clock), 
        .wEn(mwe), 
        .addr(memAddr[11:0]), 
        .dataIn(memDataIn), 
        .dataOut(memDataOut)
    );

    // Audio Controller
    PlayBackController controller(
        .clk(clock),
        .reset(reset),
        .audio_data(memDataIn),
        .data_valid(audio_data_valid),
        .audioOut(audioOut)
    );
endmodule