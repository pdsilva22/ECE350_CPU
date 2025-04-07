module multdiv(
	data_operandA, data_operandB, 
	ctrl_MULT, ctrl_DIV, 
	clock, 
	data_result, data_exception, data_resultRDY);

    input [31:0] data_operandA, data_operandB;
    input ctrl_MULT, ctrl_DIV, clock;

    output [31:0] data_result;
    output data_exception, data_resultRDY;

    // add your code here
    //TODO: Multiplier will not be fast enough with current ALU (before of error with CLA)
    wire[31:0] mult_result, div_result;
    wire mult_RDY, div_RDY, mult_exception, div_exception;

    wire multiply, divide, nextMultiply, nextDivide, resetOpType;
    assign resetOpType = ctrl_MULT | ctrl_DIV;
    assign nextMultiply = (multiply & ~resetOpType) | ctrl_MULT;
    assign nextDivide = (divide & ~resetOpType) | ctrl_DIV;


    
    dffe_ref mult_dff(.q(multiply), .d(nextMultiply), .clk(clock), .en(1'b1), .clr(1'b0));
    dffe_ref div_dff(.q(divide), .d(nextDivide), .clk(clock), .en(1'b1), .clr(1'b0));

    mult myMultiplier(.multiplicand(data_operandA), .multiplier(data_operandB), 
            .control_mult(ctrl_MULT), .clock(clock), .result(mult_result),
            .exception(mult_exception), .ready(mult_RDY));
    //assume its given as A/B??
    div myDivider(.dividend(data_operandA), .divisor(data_operandB), .control_div(ctrl_DIV),
            .clock(clock), .result(div_result), .exception(div_exception), .ready(div_RDY));

    //need to make sure correct value is returned to data_result
    //assign data_result = div_result;
    //assign data_exception = div_exception;
    //assign data_resultRDY = div_RDY;

    //multiply
    //assign data_result = mult_result;
    //assign data_exception = mult_exception;
    //assign data_resultRDY = mult_RDY;


    //mux to select results for division/multiplication
    //3 2:1 muxes 
    //send multiplication results to in1
    //ISSUE IS THAT CONTROL SIGNALS ONLY PULSED BRIEFLY, WILL ALWAYS SELECT DIVISION

    //mux2 selectResult(.out(data_result), .select(ctrl_MULT), .in0(div_result), .in1(mult_result));
    //mux2_1 selectRDY(.out(data_resultRDY), .select(ctrl_MULT), .in0(div_RDY), .in1(mult_RDY));
    //mux2_1 selectException(.out(data_exception), .select(ctrl_MULT), .in0(div_exception), .in1(mult_exception));

    //just assign using mult_RDY/div_RDY instead 
    //issue is mult_RDY will go high even when div_RDY not high yet
    assign data_resultRDY = multiply ? mult_RDY: div_RDY;
    assign data_result = multiply ? mult_result: div_result;
    assign data_exception = multiply ? mult_exception: div_exception;
    //assign data_resultRDY = mult_RDY ? mult_RDY: div_RDY;

    
 
endmodule