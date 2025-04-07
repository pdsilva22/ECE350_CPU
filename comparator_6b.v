module comparator_6b (
    input [5:0] a, 
    input [5:0] b, 
    output eq
);
    assign eq = (a == b); // Structural equality check
endmodule