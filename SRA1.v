module SRA1(A, result);
    input [31:0] A;
    output [31:0] result;
    
    assign result[30:0] = A[31:1];  
    assign result[31] = A[31];      

endmodule