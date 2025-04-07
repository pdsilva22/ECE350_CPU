module cla_32 (
    input [31:0] A, B,
    input [4:0] opcode, // 5-bit ALU opcode
    output [31:0] S,
    output cout
);

    wire [3:0] P0, G0, C;  // 8 bits
    wire cin;
    wire [31:0] B_sub;  //holds 2s complement of B if opcode deems necessary
    // Determine if we are performing subtraction
    assign cin = opcode[0]; // Carry-in = 1 for subtraction, 0 for addition
    wire w0, w1, w2, w3;
    wire w01, w02, w03;
    wire w12, w13;
    wire w23;


    xor SUBXOR[31:0](B_sub, B,{32{opcode[0]}});


    //Four 8-bit CLAs 
    cla_8 cla0(A[7:0], B_sub[7:0], cin, S[7:0], P0[0], G0[0]);
    and ANDC8(w0, P0[0], cin);
    or ORC8(C[0], G0[0], w0);
   
    cla_8 cla1(A[15:8], B_sub[15:8], C[0], S[15:8], P0[1], G0[1]);
    and ANDC16(w1, w0, P0[1]);
    and ANDC16b(w01, G0[0], P0[1]);
    or ORC16(C[1], G0[1], w01, w1);
    
    cla_8 cla2(A[23:16], B_sub[23:16], C[1], S[23:16], P0[2], G0[2]);
    and ANDC24(w2, w1, P0[2]);
    and ANDC24b(w02, w01, P0[2]);
    and ANDC24c(w12, G0[1], P0[2]);
    or ORC24(C[2], G0[2], w12, w02, w2);
    
    cla_8 cla3(A[31:24], B_sub[31:24], C[2], S[31:24], P0[3], G0[3]);
    and ANDC32(w3, w2, P0[3]);
    and ANDC32b(w03, w02, P0[3]);
    and ANDC32c(w13, w12, P0[3]);
    and ANDC32d(w23, G0[2], P0[3]);
    or ORC32(C[3], G0[3], w23, w13, w03, w3);

    assign cout = C[3];

endmodule

