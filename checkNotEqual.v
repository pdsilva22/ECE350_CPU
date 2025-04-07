module checkNotEqual(A, B, result);
    input[31:0] A;
    input[31:0] B;
    output result;

     wire [31:0] xor_out;

    // Manually create XOR gates for each bit
    xor (xor_out[0], A[0], B[0]);
    xor (xor_out[1], A[1], B[1]);
    xor (xor_out[2], A[2], B[2]);
    xor (xor_out[3], A[3], B[3]);
    xor (xor_out[4], A[4], B[4]);
    xor (xor_out[5], A[5], B[5]);
    xor (xor_out[6], A[6], B[6]);
    xor (xor_out[7], A[7], B[7]);
    xor (xor_out[8], A[8], B[8]);
    xor (xor_out[9], A[9], B[9]);
    xor (xor_out[10], A[10], B[10]);
    xor (xor_out[11], A[11], B[11]);
    xor (xor_out[12], A[12], B[12]);
    xor (xor_out[13], A[13], B[13]);
    xor (xor_out[14], A[14], B[14]);
    xor (xor_out[15], A[15], B[15]);
    xor (xor_out[16], A[16], B[16]);
    xor (xor_out[17], A[17], B[17]);
    xor (xor_out[18], A[18], B[18]);
    xor (xor_out[19], A[19], B[19]);
    xor (xor_out[20], A[20], B[20]);
    xor (xor_out[21], A[21], B[21]);
    xor (xor_out[22], A[22], B[22]);
    xor (xor_out[23], A[23], B[23]);
    xor (xor_out[24], A[24], B[24]);
    xor (xor_out[25], A[25], B[25]);
    xor (xor_out[26], A[26], B[26]);
    xor (xor_out[27], A[27], B[27]);
    xor (xor_out[28], A[28], B[28]);
    xor (xor_out[29], A[29], B[29]);
    xor (xor_out[30], A[30], B[30]);
    xor (xor_out[31], A[31], B[31]);

    // OR xor results, can reduce to avoid 32 input or gate
    wire [15:0] or_stage1;
    wire [7:0] or_stage2;
    wire [3:0] or_stage3;
    wire [1:0] or_stage4;

    or (or_stage1[0], xor_out[0], xor_out[1]);
    or (or_stage1[1], xor_out[2], xor_out[3]);
    or (or_stage1[2], xor_out[4], xor_out[5]);
    or (or_stage1[3], xor_out[6], xor_out[7]);
    or (or_stage1[4], xor_out[8], xor_out[9]);
    or (or_stage1[5], xor_out[10], xor_out[11]);
    or (or_stage1[6], xor_out[12], xor_out[13]);
    or (or_stage1[7], xor_out[14], xor_out[15]);
    or (or_stage1[8], xor_out[16], xor_out[17]);
    or (or_stage1[9], xor_out[18], xor_out[19]);
    or (or_stage1[10], xor_out[20], xor_out[21]);
    or (or_stage1[11], xor_out[22], xor_out[23]);
    or (or_stage1[12], xor_out[24], xor_out[25]);
    or (or_stage1[13], xor_out[26], xor_out[27]);
    or (or_stage1[14], xor_out[28], xor_out[29]);
    or (or_stage1[15], xor_out[30], xor_out[31]);

    or (or_stage2[0], or_stage1[0], or_stage1[1]);
    or (or_stage2[1], or_stage1[2], or_stage1[3]);
    or (or_stage2[2], or_stage1[4], or_stage1[5]);
    or (or_stage2[3], or_stage1[6], or_stage1[7]);
    or (or_stage2[4], or_stage1[8], or_stage1[9]);
    or (or_stage2[5], or_stage1[10], or_stage1[11]);
    or (or_stage2[6], or_stage1[12], or_stage1[13]);
    or (or_stage2[7], or_stage1[14], or_stage1[15]);

    or (or_stage3[0], or_stage2[0], or_stage2[1]);
    or (or_stage3[1], or_stage2[2], or_stage2[3]);
    or (or_stage3[2], or_stage2[4], or_stage2[5]);
    or (or_stage3[3], or_stage2[6], or_stage2[7]);

    or (or_stage4[0], or_stage3[0], or_stage3[1]);
    or (or_stage4[1], or_stage3[2], or_stage3[3]);

    or (result, or_stage4[0], or_stage4[1]);

endmodule
