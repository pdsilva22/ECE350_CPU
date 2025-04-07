module div(
    dividend, divisor, 
    control_div, clock, 
    result, exception, ready
    );  

    input [31:0] dividend, divisor;
    input control_div, clock;

    output [31:0] result;
    output exception, ready;
  
    wire reset;   //reset registers when we want to start a new nultiply/divide
    assign reset = control_div;

    wire reset_latch;
    dffe_ref reset_ff(.q(reset_latch), .d(reset), .clk(clock), .en(1'b1), .clr(1'b0));

    counter32 myCounter(.clk(clock), .reset(reset), .ready(ready)); //should count number of shifts, when 32 data is ready

    wire [31:0] A_in, A_out, Q_in, Q_out, dividend_in, dividend_out, divisor_in, divisor_out;

    //need to make dividend and divisor positive if they aren't already
    //then fix sign at the end 
    wire [31:0] negate_dividend, negate_divisor;

    //only do if dividend or divisor are negative 
    calc_2s_comp genCompDividend(.in(dividend), .out(negate_dividend));
    calc_2s_comp genCompDivisor(.in(divisor), .out(negate_divisor));

    //mux to choose, 2:1, need to do for each 
    //select bit is MSB of divisor/dividend, then  in1 is negated version 
    //what about instability of dividend (input can change during divide)
    //need to make sure I'm using dividend_out, and latch dividend_in instead of flip flop
    //MAY NEED TO COME BACK TO THIS AND IMPLEMENT LATCH
    mux2 selectDividend(.out(dividend_in), .select(dividend[31]), .in0(dividend), .in1(negate_dividend));
    mux2 selectDivisor(.out(divisor_in), .select(divisor[31]), .in0(divisor), .in1(negate_divisor));

    //assign dividend_in = dividend;
    //assign divisor_in = divisor;
   
    //make registers for initial divisor and dividend
    reg32 regDividend(.clock(clock), .ctrl_reset(reset), .enable(1'b1), .data_in(dividend_in), .data_out(dividend_out));
    reg32 regDivisor(.clock(clock), .ctrl_reset(reset), .enable(1'b1), .data_in(divisor_in), .data_out(divisor_out));

    wire flipSign;  //signal to flip result sign depending on signs of divisor, and dividend
    assign flipSign = (dividend[31] & ~divisor[31]) | (~dividend[31] & divisor[31]);


    
    //make register for A, Q 
    reg32 regA(.clock(clock), .ctrl_reset(reset), .enable(1'b1), .data_in(A_in), .data_out(A_out));
    reg32 regQ(.clock(clock), .ctrl_reset(reset), .enable(1'b1), .data_in(Q_in), .data_out(Q_out));

    //reg to hold AQ (64 bits) --> NEED TO CREATE THIS MODULE
    wire [63:0] AQ_out;
    wire [63:0] AQ_in;
    wire [63:0] shifted_AQ;
    wire [63:0] AQ_intermediate;
    reg64 regAQ(.clock(clock), .ctrl_reset(reset), .enable(1'b1), .data_in(AQ_in), .data_out(AQ_out));

   

    wire[31:0] alu_out;
    wire[31:0] A_init;
    wire[31:0] Q_init;
    assign A_init = reset_latch ? {32'b0}: A_out; //reset high, no value in A_out, need to initialize to 0
    assign Q_init = reset_latch ? {dividend_in}: Q_out; 

    assign AQ_intermediate = {A_init, Q_init}; 
    //need to shift before subtraction 
    assign shifted_AQ = AQ_intermediate << 1; //left shift by 1 

    wire equality, less, overflow;

    alu sub_alu(.data_operandA(shifted_AQ[63:32]), .data_operandB(divisor_in), .ctrl_ALUopcode(5'b00001),
                .ctrl_shiftamt(5'b00000), .data_result(alu_out), .isNotEqual(equality), .isLessThan(less), .overflow(overflow));
    
    
    wire A_MSB;
    assign A_MSB = alu_out[31];  //use this bit to determine bit of Q, and whether or not to restores

    //and this bit with every bit in M, add result to alu_out 
    //if bit is 1 (we want to restore), then we will be adding M to A (restoration)
    //if bit is 0 (no restoration), we will be adding 0 to A --> good
    //then need to set LSB of Q 

    wire[31:0] alu_restore_in;
    wire[31:0] A_post_restore;
    assign alu_restore_in = divisor_in & {32{A_MSB}};

    wire equality_restore, less_restore, overflow_restore;

    alu restore_alu(.data_operandA(alu_out), .data_operandB(alu_restore_in), .ctrl_ALUopcode(5'b00000),
                .ctrl_shiftamt(5'b00000), .data_result(A_post_restore), .isNotEqual(equality_restore), .isLessThan(less_restore), .overflow(overflow_restore));

    //if reset_latch high, need to initialize A and Q (can't take from register outputs)
    //assign AQ_intermediate = reset_latch ? {32'b0, shifted_AQ[31:0]}: {A_post_restore, shifted_AQ[31:0]};  //shifted_AQ will already have a 0 in LSB, don't need to overwrite
    //modify Q
    wire Q_LSB;
    wire [31:0] negate_result, temp_result;
    //nor shifted_AQ[0] with MSB to determine LSB of Q
    nor (Q_LSB, shifted_AQ[0], A_MSB);
    assign A_in = A_post_restore;
    assign Q_in = {shifted_AQ[31:1], Q_LSB};
    assign AQ_in = {A_post_restore, shifted_AQ[31:1], Q_LSB};
    //assign result = Q_out; 
    assign temp_result = Q_out;
    calc_2s_comp fixSign(.in(Q_out), .out(negate_result));

    mux2 selectResult(.out(result), .select(flipSign), .in0(temp_result), .in1(negate_result));
    div_overflow checkOverflow(.dividend(dividend_in), .divisor(divisor_in), .overflow(exception));
    //assign exception = 1'b0;  


endmodule
