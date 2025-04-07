module SLL16(A, result);
    input [31:0] A;
    output [31:0] result;
    
    assign result[31:16] = A[15:0];  
    assign result[15:0] = 16'b0000000000000000;    

endmodule