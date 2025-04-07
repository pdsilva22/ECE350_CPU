module SRA8(A, result);
    input [31:0] A;
    output [31:0] result;
    
    assign result[23:0] = A[31:8];  
    assign result[31:24] = {8{A[31]}};  

endmodule