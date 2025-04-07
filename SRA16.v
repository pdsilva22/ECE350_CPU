module SRA16(A, result);
    input [31:0] A;
    output [31:0] result;
    
    assign result[15:0] = A[31:16];  
    assign result[31:16] = {16{A[31]}};  

endmodule