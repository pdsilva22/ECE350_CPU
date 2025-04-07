module comparator_5b (
    input [4:0] a, 
    input [4:0] b, 
    output eq
);
    assign eq = (a == b); // Structural equality check
endmodule