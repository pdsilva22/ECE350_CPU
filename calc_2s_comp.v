module calc_2s_comp(
    in, out);
    input [31:0] in;
    output [31:0] out;
    wire [31:0] not_in;

    //flip all bits 
    assign not_in = ~in;

    wire equality, less, overflow;
    alu add_1(.data_operandA(not_in), .data_operandB({32'b1}), .ctrl_ALUopcode(5'b00000),
                .ctrl_shiftamt(5'b00000), .data_result(out), .isNotEqual(equality), .isLessThan(less), .overflow(overflow));

endmodule