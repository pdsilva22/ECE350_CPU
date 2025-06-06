`timescale 1ns / 1ps
module RAM #( parameter DATA_WIDTH = 32, ADDRESS_WIDTH = 12, DEPTH = 4096, MEMFILE = "") (  //added MEMFILE param
    input wire                     clk,
    input wire                     wEn,
    input wire [ADDRESS_WIDTH-1:0] addr,
    input wire [DATA_WIDTH-1:0]    dataIn,
    output reg [DATA_WIDTH-1:0]    dataOut = 0);
    
    reg[DATA_WIDTH-1:0] MemoryArray[0:DEPTH-1];
    
    integer i;
    initial begin
        if(MEMFILE > 0) begin
            $readmemb(MEMFILE, MemoryArray);    //uncommented this portion (3 lines)
        end
        // for (i = 0; i < DEPTH; i = i + 1) begin
        //     MemoryArray[i] <= 0;
        // end
    end
    
    always @(posedge clk) begin
        if(wEn) begin
            MemoryArray[addr] <= dataIn;
        end else begin
            dataOut <= MemoryArray[addr];
        end
        // MemoryArray[0] <= 1024;
    end
endmodule
