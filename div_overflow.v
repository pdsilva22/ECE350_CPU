module div_overflow(dividend, divisor, overflow);
    input[31:0] dividend, divisor;
    output overflow;

    //check if divisor is 0 
    assign overflow = ~|divisor;
    
endmodule