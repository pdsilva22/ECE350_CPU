module SRA4(A, result);
    input [31:0] A;
    output [31:0] result;
    
    assign result[27:0] = A[31:4];  
    assign result[31:28] = {4{A[31]}};  

endmodule