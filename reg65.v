module reg65(clock, ctrl_reset, enable, data_in, data_out);

    input clock, ctrl_reset, enable;
    input [64:0] data_in;
    output [64:0] data_out;
    
    wire [64:0] data_out;  //why is data_out declared twice??
    
    //instantiate 32 D-flip flops with dffe_ref.v 
    //each one needs singular bit, clock, and ctrl_reset
    //HOW DO I USE CTRL_RESET
    //each one takes a singular bit from data_in
    //take all 32 outputs of dff_ref.v, wire to data_out 

    //use and gate of write enable with one-hot wire from decoder to set enable bit 
    //generate DFFs
    genvar i;
    generate 
        for(i=0; i<65; i=i+1) begin: loop1
            dffe_ref myDFF(.q(data_out[i]), .d(data_in[i]), .clk(clock), .en(enable), .clr(ctrl_reset));
        end
    endgenerate 

endmodule
