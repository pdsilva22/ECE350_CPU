module SLL8(A, result);
    input [31:0] A;
    output [31:0] result;
    
    assign result[31:8] = A[23:0];  
    assign result[7:0] = 8'b00000000;    

endmodule