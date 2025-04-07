module checkOverflow(A, B, S, op, result);
    input A, B, S, op;
    output result;

    wire nA, nB, nS, nop;
    wire w1, w2, w3, w4;
    not (nA, A);
    not (nB, B);
    not (nS, S);
    not (nop, op);

    //Add overflow
    and (w1, nA, nB, S, nop);
    and (w2, A, B, nS, nop);
    
    //Subtract overflow
    and (w3, nA, B, S, op);
    and (w4, A, nB, nS, op);

    or (result, w1, w2, w3, w4);

endmodule 