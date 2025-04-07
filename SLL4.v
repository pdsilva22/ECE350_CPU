module SLL4(A, result);
    input [31:0] A;
    output [31:0] result;
    
    assign result[31:4] = A[27:0];  
    assign result[3:0] = 4'b0000;    

endmodule
