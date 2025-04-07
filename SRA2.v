module SRA2(A, result);
    input [31:0] A;
    output [31:0] result;
    
    assign result[29:0] = A[31:2];  
    assign result[31:30] = {2{A[31]}};  

endmodule