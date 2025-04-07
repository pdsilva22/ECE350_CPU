module SLL1(A, result);
    input[31:0] A;
    output[31:0] result;

    assign result[31:1] = A[30:0];  
    assign result[0] = 0;          

endmodule