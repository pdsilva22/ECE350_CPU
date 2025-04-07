module alu(data_operandA, data_operandB, ctrl_ALUopcode, ctrl_shiftamt, data_result, isNotEqual, isLessThan, overflow);
        
    input [31:0] data_operandA, data_operandB;
    input [4:0] ctrl_ALUopcode, ctrl_shiftamt;

    output [31:0] data_result;
    output isNotEqual, isLessThan, overflow;

    wire [31:0] S, SLL, SRA, logicalAnd, logicalOr;
    wire Cout;
    wire notMSB;
    cla_32 add_sub(.A(data_operandA), .B(data_operandB), .opcode(ctrl_ALUopcode), .S(S), .cout(Cout));

    //issue is that ctrl_ALUopcode here is not correct
    checkOverflow over(.A(data_operandA[31]), .B(data_operandB[31]), .S(S[31]), .op(ctrl_ALUopcode[0]), .result(overflow));
    //checkOverflow over(.A(data_operandA[31]), .B(data_operandB[31]), .S(S[31]), .op(), .result(overflow));  //want to subtract for overflow detection?, nah would be incorrect

    checkNotEqual equality(.A(data_operandA), .B(data_operandB), .result(isNotEqual));

    //if overflow do notMSB 
    //otherwise do MSB
    //assign ternary_output = cond ? High : Low;
    not nMSB(notMSB, S[31]);
    assign isLessThan = overflow ? notMSB : S[31];

    //do SLL, SRA
    sll shift_left(.A(data_operandA), .shift(ctrl_shiftamt), .result(SLL));
    sra shift_right(.A(data_operandA), .shift(ctrl_shiftamt), .result(SRA));

    //compute logicalAnd, logicalOr
    logicalA logA(.A(data_operandA), .B(data_operandB), .result(logicalAnd));
    logicalO logO(.A(data_operandA), .B(data_operandB), .result(logicalOr));

    //determine result with 8-input mux
    mux8 selectOp(.out(data_result), 
                .select(ctrl_ALUopcode[2:0]),
                .in0(S), 
                .in1(S),
                .in2(logicalAnd), 
                .in3(logicalOr),
                .in4(SLL),
                .in5(SRA),
                .in6(32'b0),
                .in7(32'b0));

endmodule