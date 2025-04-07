module counter16(clk, reset, ready);
    input clk; 
    input reset; 
    output wire ready;

    //make a register to hold count
    //on each clk we pass counter through register, take output and increment by 1 
    //then reroute back into input of register (Q)
    //on reset we clear register
    //after each clk, we take value output by increnmenter (ALU?) and use comparator to compare to 16
    //assign isequal (result from comparator) to ready output

    //checkReady bits gets output of comparator
    wire[31:0] count_in;
    wire[31:0] count_out;
    

    //need another register to hold 5 bit count (just store as 32-bit value)
    reg32 countReg(.clock(clk), .ctrl_reset(reset), .enable(1'b1), .data_in(count_in), .data_out(count_out));

    comparator_5b compare(.a(count_out[4:0]), .b(5'b10000), .eq(ready)); //does comparator only compare once?? -> no, wiring is always there so appropriate change to count_out will be reflected in ready bit
    
    wire[31:0] incrementVal;
    assign incrementVal = 32'b00000000000000000000000000000001;
    //build ALU to add to count 
    //assign output of ALU to count_in
    wire equality, less, overflow;  //must be instantiated, but not used
    wire[31:0] ALU_out;
    alu myALU(.data_operandA(count_out), .data_operandB(incrementVal), .ctrl_ALUopcode(5'b00000), .ctrl_shiftamt(5'b00000), .data_result(ALU_out), .isNotEqual(equality), .isLessThan(less), .overflow(overflow));
    assign count_in = ALU_out;


    
    //only need singular D-Flip Flop
    //dffe_ref storeReady(.q(ready), .d(checkReady), .ctrl_reset(reset), .)





endmodule