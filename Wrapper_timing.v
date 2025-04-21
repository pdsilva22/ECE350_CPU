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
    
    wire io_read, io_write;
    
    wire clk_50mhz, clk_out_ps2, audio_clk;
    wire locked, locked2;
//    clk_wiz_0 pll(
//      // Clock out ports
//      .clk_out1(clk_50mhz),
//      // Status and control signals
//      .reset(1'b0),
//      .locked(locked),
//     // Clock in ports
//      .clk_in1(clk_100mhz)
//     );
     
//     clk_wiz_3 pll2
//   (
//    // Clock out ports
//    .clk_out1(clk_50mhz),     // output clk_out1(31.25 mhz)
//    .clk_out2(audio_clk),     // output clk_out2 (6.5 mhz)
//    // Status and control signals
//    .reset(reset), // input reset
//    .locked(locked),       // output locked
//   // Clock in ports
//    .clk_in1(clk_100mhz));      // input clk_in1
    
    clk_wiz_4 pll2
   (
    // Clock out ports
    .clk_out1(clk_50mhz),     // output clk_out1
    .clk_out2(audio_clk),     // output clk_out2
    // Status and control signals
    .reset(reset), // input reset
    .locked(locked),       // output locked
   // Clock in ports
    .clk_in1(clk_100mhz));      // input clk_in1

     
//     clk_wiz_2 pll2
//   (
//    // Clock out ports
//    .clk_out1(audio_clk),     // output clk_out1
//    // Status and control signals
//    .reset(reset), // input reset
//    .locked(locked2),       // output locked
//   // Clock in ports
//    .clk_in1(clk_100mhz));      // input clk_in1
     //same 31.25 mHz clock as pll above 
//    clk_wiz_1 pll2
//   (
//    // Clock out ports
//    .clk_out1(clk_out_ps2),     // output clk_out1
//    // Status and control signals
//    .reset(reset), // input reset
//    .locked(locked2),       // output locked
//   // Clock in ports
//    .clk_in1(ps2_clk));      // input clk_in1 (can I do this, route board clk to two different places)
    
    assign io_read = (memAddr == 32'd4096) ? 1'b1: 1'b0;

    assign io_write = (memAddr == 32'd4097) ? 1'b1: 1'b0;
     always @(negedge clock) begin
           SW_M <= SW;
           SW_Q <= SW_M; 
       end
       
       always @(posedge clock) begin
           if (io_write == 1'b1) begin
               LED <= memDataIn[15:0];
           end else begin
               LED <= LED;
           end
       end
	   
    assign q_dmem = (io_read == 1'b1) ? SW_Q : memDataOut;
	// ADD YOUR MEMORY FILE HERE
	localparam INSTR_FILE = "timing";
	
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
	RAM ProcMem(.clk(clock), 
		.wEn(mwe), 
		.addr(memAddr[11:0]), 
		.dataIn(memDataIn), 
		.dataOut(memDataOut));

	//are other signals needed?
	//what is audioOut, how many bits?
	//wire[15:0] audioOut; //wire or reg?? --> don't need, specified in constraints file
	AudioController audio(
	   .clk(audio_clk), //should this be system clock at 100 mHz???
		.audioOutput(audioOut),
		//.psclk(clock_ps2)  //try assigning main clock to ps_2 (may need to generate separate clock wizard)
		.psclk(ps2_clk),
		.psdata(ps2_data),
		.reset(reset)
	);
		
	

endmodule
