module mult_overflow(
    multiplicand, multiplier, result, out
    );
    input [64:0] result;
    input [31:0] multiplicand, multiplier;
    output out;

    wire top_n_1;
    wire [32:0] overflow_check;
    assign overflow_check = result[64:32];  //top n+1 bits
    assign top_n_1 = ~|overflow_check || &overflow_check; //if either all zeros or all ones assign overflow

    
    //check sign
    //if sign of + * + yield - 
    //or + * - yields +
    //or - * - yields - 
    //overflow

    wire sign_bit, sign_multiplicand, sign_multiplier;
    assign sign_bit = result[32];
    assign sign_multiplicand = multiplicand[31];
    assign sign_multiplier = multiplier[31];

    //check for - * - = -
    wire neg_overflow;
    and (neg_overflow, sign_bit, sign_multiplicand, sign_multiplier); //all bits 1 --> overflow

    //check for + * + = -
    wire pos_overflow;
    and (pos_overflow, sign_bit, ~sign_multiplier, ~sign_multiplicand);  

    //check for + * - = +
    wire diff_overflow_1;
    and(diff_overflow_1, sign_multiplicand, ~sign_multiplier, ~sign_bit);

    //check for - * + = +
    wire diff_overflow_2;
    and(diff_overflow_2, ~sign_multiplicand, sign_multiplier, ~sign_bit);

    wire of_intermediate;
    or (of_intermediate, neg_overflow, pos_overflow, diff_overflow_1, diff_overflow_2);
    //need to check result isn't all zeros and we have overflow
    wire no_zero;
    assign no_zero = ~(~|result[32:1]);
    wire over;
    assign over = no_zero & of_intermediate;

    assign out = ~top_n_1 || over;


    //or (out, all_zeros, all_ones, neg_overflow, pos_overflow, diff_overflow);
    
    //or(out, all_zeros, all_ones);



endmodule