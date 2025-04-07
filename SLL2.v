module SLL2(A, result);
    input [31:0] A;
    output [31:0] result;
    
    assign result[31:2] = A[29:0];  
    assign result[1:0] = 2'b00;    

endmodule