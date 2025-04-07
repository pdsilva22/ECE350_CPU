module tristate(in, oe, out);
    input oe;
    input[31:0] in;
    output[31:0] out;

    assign out = oe ? in: 32'bz;

endmodule