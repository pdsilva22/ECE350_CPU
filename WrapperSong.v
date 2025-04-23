`timescale 1ns / 1ps
/**
 * 
 * READ THIS DESCRIPTION:
 *
 * This is the Wrapper module that will serve as the header file combining your processor, 
 * RegFile and Memory elements together.
 *
 * This file will be used to generate the bitstream to upload to the FPGA.
 * We have provided a sibling file, Wrapper_tb.v so that you can test your processor's functionality.
 * 
 * We will be using our own separate Wrapper_tb.v to test your code. You are allowed to make changes to the Wrapper files 
 * for your own individual testing, but we expect your final processor.v and memory modules to work with the 
 * provided Wrapper interface.
 * 
 * Refer to Lab 5 documents for detailed instructions on how to interface 
 * with the memory elements. Each imem and dmem modules will take 12-bit 
 * addresses and will allow for storing of 32-bit values at each address. 
 * Each memory module should receive a single clock. At which edges, is 
 * purely a design choice (and thereby up to you). 
 * 
 * You must change line 36 to add the memory file of the test you created using the assembler
 * For example, you would add sample inside of the quotes on line 38 after assembling sample.s
 *
 **/

module Wrapper (
    input clk_100mhz,
    input BTNU, 
	inout ps2_clk,
	inout ps2_data,
    input [15:0] SW,
	output audioOut,  //try next with this signal commented out
    output reg [15:0] LED);
    wire clock, clock_ps2, reset;
    assign clock = clk_50mhz;
    //assign clock_ps2 = clk_out_ps2;
    assign reset = BTNU; 
	wire rwe, mwe;
	wire[4:0] rd, rs1, rs2;
	wire[31:0] instAddr, instData, 
		rData, regA, regB,
		memAddr, memDataIn, memDataOut, q_dmem, data;
    reg [15:0] SW_Q, SW_M;  
    
    wire io_read, io_write, audio_write;
    
    wire clk_50mhz, clk_out_ps2, audio_clk;
    wire locked, locked2;
    clk_wiz_0 pll(
      // Clock out ports
      .clk_out1(clk_50mhz),
      // Status and control signals
      .reset(1'b0),
      .locked(locked),
     // Clock in ports
      .clk_in1(clk_100mhz)
     );
     
    reg [9:0] pwm_duty_cycle = 10'd0;

    assign io_read = (memAddr == 32'd4096) ? 1'b1: 1'b0;

    assign io_write = (memAddr == 32'd4097) ? 1'b1: 1'b0;

    assign audio_write = (memAddr == 32'd4098) ? 1'b1: 1'b0; 

     always @(negedge clock) begin
           SW_M <= SW;
           SW_Q <= SW_M; 
       end
       
       always @(posedge clock) begin
            LED[15] <= audio_write;
           if (io_write == 1'b1) begin
               LED[14:0] <= memDataIn[14:0];
			   //audioOut <= memDataIn[0];
           end else begin
               LED <= LED;
           end
           if (audio_write == 1'b1) begin
                pwm_duty_cycle <= memDataIn[9:0]; // Store 10-bit duty cycle --> change to be 10 bit in RAM?
                //pwm_duty_cycle <= memDataIn; // Store 10-bit duty cycle
           end
       end
	   
    assign q_dmem = (io_read == 1'b1) ? SW_Q : memDataOut;


    wire pwm_signal;

    PWMSerializer audio_pwm (
        .clk(clock),
        .reset(reset),
        .audio_enable(1'b1),
        .duty_cycle(pwm_duty_cycle),
        .signal(pwm_signal)
    );

    assign audioOut = pwm_signal;
    
	// ADD YOUR MEMORY FILE HERE
	localparam INSTR_FILE = "timing_song";
	
	// Main Processing Unit
	processor CPU(.clock(clock), .reset(reset), 
								
		// ROM
		.address_imem(instAddr), .q_imem(instData),
									
		// Regfile
		.ctrl_writeEnable(rwe),     .ctrl_writeReg(rd),
		.ctrl_readRegA(rs1),     .ctrl_readRegB(rs2), 
		.data_writeReg(rData), .data_readRegA(regA), .data_readRegB(regB),
									
		// RAM
		.wren(mwe), .address_dmem(memAddr), 
		.data(memDataIn), .q_dmem(q_dmem)); 
	
	// Instruction Memory (ROM)
	ROM #(.MEMFILE({INSTR_FILE, ".mem"}))
	InstMem(.clk(clock), 
		.addr(instAddr[11:0]), 
		.dataOut(instData));
	
	// Register File
	regfile RegisterFile(.clock(clock), 
		.ctrl_writeEnable(rwe), .ctrl_reset(reset), 
		.ctrl_writeReg(rd),
		.ctrl_readRegA(rs1), .ctrl_readRegB(rs2), 
		.data_writeReg(rData), .data_readRegA(regA), .data_readRegB(regB));
						
	// Processor Memory (RAM)
	
	 RAM #(.MEMFILE("songs.mem")) ProcMem(
        .clk(clock), 
        .wEn(mwe), 
        .addr(memAddr[11:0]), 
        .dataIn(memDataIn), 
        .dataOut(memDataOut)
    );
		
	

endmodule