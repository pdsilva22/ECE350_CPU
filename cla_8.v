module cla_8(x, y, cin, S, Pout, Gout);
    input [7:0] x, y;
    input cin;
    output Gout, Pout;
    output [7:0] S;

    //input cin;
    //output Gout, Pout;
    //output [7:0] S;
    
    wire [7:0] P, G, C;   //generate and propagate signals 
    wire w0, w1, w2, w3, w4, w5, w6;
    wire w01, w02, w03, w04, w05, w06, w07;
    wire w12, w13, w14, w15, w16, w17;
    wire w23, w24, w25, w26, w27;
    wire w34, w35, w36, w37;
    wire w45, w46, w47;
    wire w56, w57;
    wire w67;


    
    assign C[0] = cin;  //is this not allowed?

    or ORP1(P[0], x[0], y[0]);
    or ORP2(P[1], x[1], y[1]);
    or ORP3(P[2], x[2], y[2]);
    or ORP4(P[3], x[3], y[3]);
    or ORP5(P[4], x[4], y[4]);
    or ORP6(P[5], x[5], y[5]);
    or ORP7(P[6], x[6], y[6]);
    or ORP8(P[7], x[7], y[7]);

    and ANDP1(G[0], x[0], y[0]);
    and ANDP2(G[1], x[1], y[1]);
    and ANDP3(G[2], x[2], y[2]);
    and ANDP4(G[3], x[3], y[3]);
    and ANDP5(G[4], x[4], y[4]);
    and ANDP6(G[5], x[5], y[5]);
    and ANDP7(G[6], x[6], y[6]);
    and ANDP8(G[7], x[7], y[7]);

    //need intermediate carries
    and ANDC1(w0, P[0], C[0]);
    or ORC1(C[1], w0, G[0]);

    and ANDC2(w1, w0, P[1]);
    and ANDC2b(w01, P[1], G[0]);
    or ORC2(C[2], G[1], w01, w1);

    and ANDC3(w2, w1, P[2]);
    and ANDC3b(w02, w01, P[2]);
    and ANDC3c(w12, P[2], G[1]);
    or ORC3(C[3], w2, w02, w12, G[2]);

    and ANDC4(w3, w2, P[3]);
    and ANDC4b(w03, w02, P[3]);
    and ANDC4c(w13, w12, P[3]);
    and ANDC4d(w23, P[3], G[2]);
    or ORC4(C[4], w3, w03, w13, w23, G[3]);

    and ANDC5(w4, w3, P[4]);
    and ANDC5b(w04, w03, P[4]);
    and ANDC5c(w14, w13, P[4]);
    and ANDC5d(w24, w23, P[4]);
    and ANDC5e(w34, P[4], G[3]);
    or ORC5(C[5], w4, w04, w14, w24, w34, G[4]);

    and ANDC6(w5, w4, P[5]);
    and ANDC6b(w05, w04, P[5]);
    and ANDC6c(w15, w14, P[5]);
    and ANDC6d(w25, w24, P[5]);
    and ANDC6e(w35, w34, P[5]);
    and ANDC6f(w45, P[5], G[4]);
    or ORC6(C[6], w5, w05, w15, w25, w35, w45, G[5]);

    and ANDC7(w6, w5, P[6]);
    and ANDC7b(w06, w05, P[6]);
    and ANDC7c(w16, w15, P[6]);
    and ANDC7d(w26, w25, P[6]);
    and ANDC7e(w36, w35, P[6]);
    and ANDC7f(w46, w45, P[6]);
    and ANDC7g(w56, P[6], G[5]);
    or ORC7(C[7], w6, w06, w16, w26, w36, w46, w56, G[6]);

    //calculate S and Gout, Pout
    //note that Pout/Gout doesn't include cin at all
    and ANDP(Pout, P[0], P[1], P[2], P[3], P[4], P[5], P[6], P[7]);

    and ANDG07(w07, w06, P[7]);
    and ANDG17(w17, w16, P[7]); 
    and ANDG27(w27, w26, P[7]); 
    and ANDG37(w37, w36, P[7]); 
    and ANDG47(w47, w46, P[7]);
    and ANDG57(w57, w56, P[7]); 
    and ANDG67(w67, G[6], P[7]);  
    or ORG(Gout, w07, w17, w27, w37, w47, w57, w67, G[7]);

    xor SUM_CALC[7:0] (S, x, y, C);


    
endmodule