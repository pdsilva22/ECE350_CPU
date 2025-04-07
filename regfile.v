module regfile (
	clock,
	ctrl_writeEnable, ctrl_reset, ctrl_writeReg,
	ctrl_readRegA, ctrl_readRegB, data_writeReg,
	data_readRegA, data_readRegB
);

	input clock, ctrl_writeEnable, ctrl_reset;
	input [4:0] ctrl_writeReg, ctrl_readRegA, ctrl_readRegB;
	input [31:0] data_writeReg;

	output [31:0] data_readRegA, data_readRegB;

	// add your code here
	//REGISTER 0 always holds zero
	//Does ctrl_reset reser the entire regfile (all 32 registers, which
	//means all 32*32 D-flip flops)

	//generate all 32 registers 
	//how to map correct outputs if I do this???
	//just create a unique data bus for all 32 registers, send each to a tri-state (2 sets of 32 tri-states, will need 64 total)
	//then decoder with ctrl_readReg bits activates the two desired tri-states 
	//AM I ALLOWED TO USE NAMED GEN VAR LOOP??

	//decode destination write (one hot encoding)
	wire[31:0] enableWriteReg;

	decoder32 decodeDest(ctrl_writeReg, enableWriteReg);


	wire [31:0] reg_out [31:0];  //array of 32 wires to access each registers data output 
	wire[31:0] enable;
	//need to make sure register 0 always outputs 0
	//make register 0 first
	reg32 reg0(.clock(clock), .ctrl_reset(ctrl_reset), .enable(1'b0), .data_in(data_writeReg), .data_out(reg_out[0]));
	genvar i;
	generate
		for(i=1; i<32; i=i+1) begin: loopRegisters  
			and (enable[i], enableWriteReg[i], ctrl_writeEnable);
			reg32 my_reg(.clock(clock), .ctrl_reset(ctrl_reset), .enable(enable[i]), .data_in(data_writeReg), .data_out(reg_out[i]));
		end
	endgenerate


	//2 decoders, each one has 32 output wires that need to be wired to
	//output enable bit of tri-state for corresponding register
	wire[31:0] enableRegA, enableRegB;

	decoder32 decodeA(ctrl_readRegA, enableRegA);
	decoder32 decodeB(ctrl_readRegB, enableRegB);

	//generate tri-states:
	//hook each register output to input of a tri-state, output enable to
	//that tri-state must match up with enableRegA, enableRegB
	
	genvar j;
	generate 
		for(j=0; j<32; j=j+1) begin: loopRegATriStates
			tristate my_tri(.in(reg_out[j]), .oe(enableRegA[j]), .out(data_readRegA));
		end
	endgenerate

	genvar k;
	generate 
		for(k=0; k<32; k=k+1) begin: loopRegBTriStates
			tristate my_tri(.in(reg_out[k]), .oe(enableRegB[k]), .out(data_readRegB));
			//can't do output assignment like this because it will output high impedance always
			//(unless we are reading from register 31)
		end
	endgenerate


endmodule
