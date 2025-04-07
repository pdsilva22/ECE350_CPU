module decoder32(select, out);
    input[4:0] select;
    output[31:0] out;

    assign out = 1'b1 << select;

endmodule