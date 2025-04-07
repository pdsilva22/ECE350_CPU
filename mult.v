module mult(
    multiplicand, multiplier, 
	control_mult, clock, 
	result, exception, ready);

    input [31:0] multiplicand, multiplier;
    input control_mult, clock;

    output [31:0] result;
    output exception, ready;
  
    wire reset;   //reset registers when we want to start a new nultiply/divide
    assign reset = control_mult;

    wire reset_latch;
    dffe_ref reset_ff(.q(reset_latch), .d(reset), .clk(clock), .en(1'b1), .clr(1'b0));
    
    //when introducing divide will need control bits
    //save operands --> they may change
    wire signed [31:0] multiplicand_in = multiplicand; //this shouldn't change, will be sent into B of ALU 
    wire signed [31:0] multiplicand_out;
    wire signed [31:0] multiplier_in = multiplier;
    wire signed [31:0] multiplier_out;
    
    wire signed [31:0] left_running_prod; 
    wire signed [32:0] right_running_prod;   
    wire signed [31:0] left_running_prod_out;
    wire signed [32:0] right_running_prod_out;
    wire signed [31:0] alu_out;


    wire signed [64:0] product_post;
    wire signed [64:0] product_intermediate;
    wire signed [64:0] product_prior;
    
    assign product_intermediate = reset_latch ? {alu_out, right_running_prod}: {alu_out, product_post[32:0]}; 
    assign product_prior = product_intermediate >>>2;
    assign left_running_prod = product_prior[64:33];
    assign right_running_prod = reset_latch ? {multiplier_in, 1'b0}: product_prior[32:0]; //33 bits
    
    //may not be necessary to have register for multiplicand, other than if we just want to hold its value for the entire multiply
    //same goes for multiplier 
    reg32 reg1(.clock(clock), .ctrl_reset(reset), .enable(1'b1), .data_in(multiplicand_in), .data_out(multiplicand_out));
    
    reg32 reg2(.clock(clock), .ctrl_reset(reset), .enable(1'b1), .data_in(multiplier_in), .data_out(multiplier_out));
   
    reg32 reg_left(.clock(clock), .ctrl_reset(reset), .enable(1'b1), .data_in(left_running_prod), .data_out(left_running_prod_out));

    reg33 reg_right(.clock(clock), .ctrl_reset(reset), .enable(1'b1), .data_in(right_running_prod), .data_out(right_running_prod_out));

    reg65 reg_65(.clock(clock), .ctrl_reset(reset), .enable(1'b1), .data_in(product_prior), .data_out(product_post));

  
    wire signed [2:0] controlSelect;
    assign controlSelect = reset_latch ? right_running_prod[2:0]: product_post[2:0]; //select bits for mux 
    wire signed [2:0] control; //3 bits 
    //use control to determine if we are adding/subtracting
    //use control to determine how much we adding/subtracting 
    //control will output three bits, MSB tells us if we are doing nothing, 2nd bit for shift, 3rd for add/sub

    mux8_3 controlMux(.out(control), .select(controlSelect),
                    .in0(3'b000), .in1(3'b100), .in2(3'b100), .in3(3'b110), .in4(3'b111), .in5(3'b101), .in6(3'b101), .in7(3'b000));

    
    wire signed [31:0] intermediate_B = multiplicand_in & {32{control[2]}};  //bitwise and with MSB of control (will set ALU_in_B to all zeroes if control[2] 0)
    wire signed [31:0] ALU_in_B;
    wire signed [31:0] intermediate_B_shifted = intermediate_B<<1;
    assign ALU_in_B = control[1] ? intermediate_B_shifted: intermediate_B;  //assigns shift/no shift

    wire signed[4:0] opcode;
    assign opcode = {4'b0000, control[0]};  
    
    //don't care about these signals, still need to assign to avoid crash
    wire equality;
    wire less;
    wire overflow;

    alu my_alu(.data_operandA(left_running_prod_out), .data_operandB(ALU_in_B), .ctrl_ALUopcode(opcode),
                .ctrl_shiftamt(5'b00000), .data_result(alu_out), .isNotEqual(equality), .isLessThan(less), .overflow(overflow));

    


    assign result = product_post[32:1];
    counter16 myCounter(.clk(clock), .reset(reset), .ready(ready)); //should count number of shifts, when 16 data is ready

   //overflow check
    mult_overflow overflowCheck(.result(product_post), .multiplicand(multiplicand_out), .multiplier(multiplier_out), .out(exception));



 
endmodule