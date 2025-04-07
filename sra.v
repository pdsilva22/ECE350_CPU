module sra(A, shift, result);

    input[31:0] A;
    input[4:0] shift;
    output[31:0] result;

    wire [31:0] intermediate1;
    wire [31:0] intermediate2;
    wire [31:0] intermediate3;
    wire [31:0] intermediate4;

    wire [31:0] shiftBy1;
    wire [31:0] shiftBy2;
    wire [31:0] shiftBy4;
    wire [31:0] shiftBy8;
    wire [31:0] shiftBy16;
    
    
    //create barrel shifter with muxes 
    //SLL1 shifts input by 1 bit left
    SRA1 shiftby1(.A(A), .result(shiftBy1));
    mux2 m1(intermediate1, shift[0], A, shiftBy1);

    SRA2 shiftby2(.A(intermediate1), .result(shiftBy2));
    mux2 m2(intermediate2, shift[1], intermediate1, shiftBy2);

    SRA4 shiftby4(.A(intermediate2), .result(shiftBy4));
    mux2 m3(intermediate3, shift[2], intermediate2, shiftBy4);

    SRA8 shiftby8(.A(intermediate3), .result(shiftBy8));
    mux2 m4(intermediate4, shift[3], intermediate3, shiftBy8);

    SRA16 shiftby16(.A(intermediate4), .result(shiftBy16));
    mux2 m5(result, shift[4], intermediate4, shiftBy16);


endmodule