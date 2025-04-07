/**
 * READ THIS DESCRIPTION!
 *
 * This is your processor module that will contain the bulk of your code submission. You are to implement
 * a 5-stage pipelined processor in this module, accounting for hazards and implementing bypasses as
 * necessary.
 *
 * Ultimately, your processor will be tested by a master skeleton, so the
 * testbench can see which controls signal you active when. Therefore, there needs to be a way to
 * "inject" imem, dmem, and regfile interfaces from some external controller module. The skeleton
 * file, Wrapper.v, acts as a small wrapper around your processor for this purpose. Refer to Wrapper.v
 * for more details.
 *
 * As a result, this module will NOT contain the RegFile nor the memory modules. Study the inputs 
 * very carefully - the RegFile-related I/Os are merely signals to be sent to the RegFile instantiated
 * in your Wrapper module. This is the same for your memory elements. 
 *
 *
 */
module processor(
    // Control signals
    clock,                          // I: The master clock
    reset,                          // I: A reset signal

    // Imem
    address_imem,                   // O: The address of the data to get from imem
    q_imem,                         // I: The data from imem

    // Dmem
    address_dmem,                   // O: The address of the data to get or put from/to dmem
    data,                           // O: The data to write to dmem
    wren,                           // O: Write enable for dmem
    q_dmem,                         // I: The data from dmem

    // Regfile
    ctrl_writeEnable,               // O: Write enable for RegFile
    ctrl_writeReg,                  // O: Register to write to in RegFile
    ctrl_readRegA,                  // O: Register to read from port A of RegFile
    ctrl_readRegB,                  // O: Register to read from port B of RegFile
    data_writeReg,                  // O: Data to write to for RegFile
    data_readRegA,                  // I: Data from port A of RegFile
    data_readRegB                   // I: Data from port B of RegFile
	 
	);

	// Control signals
	input clock, reset;
	
	// Imem
    output [31:0] address_imem;  //get from PC = PC+1 or from branch (custom)  
	input [31:0] q_imem;          

	// Dmem
	output [31:0] address_dmem, data;
	output wren;
	input [31:0] q_dmem;

	// Regfile
	output ctrl_writeEnable;
	output [4:0] ctrl_writeReg, ctrl_readRegA, ctrl_readRegB;
	output [31:0] data_writeReg;
	input [31:0] data_readRegA, data_readRegB;    //these are inputs because register file is in wrapper.v 

	/* YOUR CODE STARTS HERE */

    //create all 5 pipelined latches, updated on falling edge (use ~clock)

    //FD stage register data
    wire [31:0] fd_insn, dx_insn, dx_pc; 

    //DX stage register data
    wire [31:0] xm_insn, dx_A_in, dx_A_out, dx_B_in, dx_B_out, xm_pc;
    
    //XM stage register data
    wire [31:0] mw_insn, xm_B_in, xm_B_out, xm_O_in, xm_O_out, mw_pc;
    wire xm_exception;

    //MW stage register data
    wire [31:0] wback_insn, mw_O_in, mw_O_out, mw_D_in, mw_D_out, wb_pc;
    wire mw_exception, wb_exception;
    
    //need reg for current pc 
    wire [31:0] nextPC, PC, PC_add1, nextPC_temp;
    wire stall, nextStall;
    reg32 currPCreg(.clock(clock), .ctrl_reset(reset), .enable(!nextStall), .data_in(nextPC), .data_out(PC));  //as of now, not using PC (PC gets written to on rising edge)

    //dff for stall signal
    //toggle to low when result is ready, otherwise send high 
    dffe_ref stallReg(.q(stall), .d(nextStall), .clk(clock), .en(1'b1), .clr(1'b0));
    

    //Set pipeline registers for each stage 
    wire isValidBranch, isJump, flush;  //used for flushing
    assign flush = isValidBranch | isJump;
    //FD STAGE
    reg32 fd_latch_insn(.clock(~clock), .ctrl_reset(flush), .enable(!stall), .data_in(fd_insn), .data_out(dx_insn));
    reg32 fd_latch_pc(.clock(~clock), .ctrl_reset(flush), .enable(!nextStall), .data_in(PC), .data_out(dx_pc));  //PC should be incremented (changed from .data_in(PC) to .data_in(nextPC))

    //DX STAGE
    reg32 dx_latch_insn(.clock(~clock), .ctrl_reset(reset), .enable(!nextStall), .data_in(dx_insn), .data_out(xm_insn));
    reg32 dx_latch_PC(.clock(~clock), .ctrl_reset(reset), .enable(!nextStall), .data_in(dx_pc), .data_out(xm_pc));
    reg32 dx_latch_A(.clock(~clock), .ctrl_reset(reset), .enable(!nextStall), .data_in(dx_A_in), .data_out(dx_A_out));
    reg32 dx_latch_B(.clock(~clock), .ctrl_reset(reset), .enable(!nextStall), .data_in(dx_B_in), .data_out(dx_B_out));
    
    //XM STAGE
    reg32 xm_latch_insn(.clock(~clock), .ctrl_reset(reset), .enable(!nextStall), .data_in(xm_insn), .data_out(mw_insn));
    reg32 xm_latch_B(.clock(~clock), .ctrl_reset(reset), .enable(!nextStall), .data_in(xm_B_in), .data_out(xm_B_out));
    reg32 xm_latch_O(.clock(~clock), .ctrl_reset(reset), .enable(!nextStall), .data_in(xm_O_in), .data_out(xm_O_out));
    reg32 xm_latch_PC(.clock(~clock), .ctrl_reset(reset), .enable(!nextStall), .data_in(xm_pc), .data_out(mw_pc));
    dffe_ref xm_latch_exception(.q(mw_exception), .d(xm_exception), .clk(~clock), .en(!nextStall), .clr(1'b0));

    //MW STAGE
    reg32 mw_latch_insn(.clock(~clock), .ctrl_reset(reset), .enable(!nextStall), .data_in(mw_insn), .data_out(wback_insn));
    reg32 mw_latch_O(.clock(~clock), .ctrl_reset(reset), .enable(!nextStall), .data_in(mw_O_in), .data_out(mw_O_out));
    reg32 mw_latch_D(.clock(~clock), .ctrl_reset(reset), .enable(!nextStall), .data_in(mw_D_in), .data_out(mw_D_out));
    reg32 mw_latch_PC(.clock(~clock), .ctrl_reset(reset), .enable(!nextStall), .data_in(mw_pc), .data_out(wb_pc));
    dffe_ref mw_latch_exception(.q(wb_exception), .d(mw_exception), .clk(~clock), .en(!nextStall), .clr(1'b0));

    //FETCH STAGE

    //grab instruction so it can be passed along pipeline
    assign fd_insn = !flush ? q_imem: 32'd0;

    //send PC through ALU to increment by 1, used in case of no jumps/branches
    wire t1, t2, t3;
    alu pcALU(.data_operandA(PC), 
                .data_operandB(32'd1),
                .ctrl_ALUopcode(5'd0),
                .ctrl_shiftamt(5'd0),
                .data_result(PC_add1),
                .isNotEqual(t1),
                .isLessThan(t2),
                .overflow(t3));
    
   //determine nextPC based on if we have branch or jump in execute stage
    wire [31:0] branchedPC, address_imem_temp, jumpPC, jumpPC_temp;

    //assigning PC output (to grab next instruction from i-memory)
    mux2 pcMux1(.out(address_imem_temp), .select(isValidBranch), .in0(PC), .in1(branchedPC));  
    mux2 pcMux2(.out(address_imem), .select(isJump), .in0(address_imem_temp), .in1(jumpPC));
    
    //assign nextPC for PC register
    assign nextPC_temp = isValidBranch ? branchedPC: PC_add1;  
    assign nextPC = isJump ? jumpPC: nextPC_temp;  
    

    /*
    **
    ***DECODE STAGE
    **
    */

    wire isRType_D;  
    wire isIType_D;
    wire isBranch_D;
    wire[4:0] opcode_D;
    //determine if I or R type 
    assign opcode_D = dx_insn[31:27];
    assign isRType_D = (opcode_D == 5'd0);   
    //if not RType, we can say it is IType (NOTE: only because JI, JII insns can be treated as I-type according to this ISA)
    assign isIType_D = isRType_D ? 1'd0: 1'd1;  //if we treat non RType as IType, then this not necessary(hold for now in case we need to differentiate from jumps)
    assign isBranch_D = (opcode_D == 5'd2 | opcode_D == 5'd6);
    
    //check if bex instruction
    wire isBex = (opcode_D == 5'd22);

    //rewrite this to account for branch register comparisons vs add immediate where rd is destination
    wire [4:0] ctrl_readRegA_temp, ctrl_readRegB_temp;
   
    assign ctrl_readRegA_temp = isBranch_D ? dx_insn[26:22]: dx_insn[21:17];
    //assign ctrl_readRegA_bypass = memBypass2_rs ? mw_O_in : ctrl_readRegA_temp;  //bypass check 
    assign ctrl_readRegB_temp = (!isBranch_D & isIType_D & !isBex) ? dx_insn[26:22]:   //add immediate case and jr case 
                            isBranch_D ?               dx_insn[21:17]:   //important note: technically handles jr case, but weak logic
                            isBex ?                    5'd30:           //assign to read from rstatus for bex
                                                       dx_insn[16:12];
    assign ctrl_readRegA = !flush ? ctrl_readRegA_temp: 5'd0;
    assign ctrl_readRegB = !flush ? ctrl_readRegB_temp: 5'd0;

    //if I type and not Branch, then assign it to dx_insn[26:22]
    //if branch, then assign it to [21:27]
    //if R type, assign it to 16:12 
   
    //take inputs and push to d/x pipeline register
    //use condition !isValidBranch to flush if we have a branch inn execute stage
    //assign dx_A_in = !flush ? data_readRegA: 32'd0; 
    wire priorityConditionA, priorityConditionB;
    assign priorityConditionA = (bypassALU_addi2_rs | bypassALU_addiR_rs | bypassALU_Raddi | bypassALU_RR_rs | bypassALU_addi_branch_rs);
    assign priorityConditionB = (bypassALU_addiR_rt | bypassALU_RR_rt | bypassALU_addi_jr);
    assign dx_A_in = memBypass2_rs ? mw_O_in:    //if bypass, send value from data mem stage
                     memBypass_loadBeforeR_rs_2 ? mw_D_in:  //send value extracted from dmem to rs if load before R-type/addi
                     ((bypassDMEM_D_addi_rs | bypassDMEM_D_addiR_rs | bypassDMEM_D_RR_rs) & (!priorityConditionA)) ? mw_O_in:  //added priority condition
                     //(bypassALU_addi2_rs | bypassALU_addiR_rs | bypassALU_Raddi | bypassALU_RR_rs) ? xm_O_in_temp:
                     priorityConditionA ? xm_O_in_temp:
                    !flush ? data_readRegA:      //if not a flush, proceed as normal
                    32'd0;                       //else we have flush, send in 0
    assign dx_B_in = memBypass_loadBeforeR_rt_2 ? mw_D_in:  ////send value extracted from dmem to rs if load before R-type/addi
                    memBypass_Rtype_sw_2 ? mw_O_in: 
                    ((bypassDMEM_D_addiR_rt | bypassDMEM_D_RR_rt | bypassDMEM_D_addiB_rs) & (!priorityConditionB)) ? mw_O_in:
                    //(bypassALU_addiR_rt | bypassALU_RR_rt) ? xm_O_in_temp:
                    priorityConditionB ? xm_O_in_temp:
                    bypassALU_setxbex ? jumpPC_temp: //taken from execute stage if we have bex following setx
                    !flush ? data_readRegB: 
                    32'd0;  
   

    /*
    **
    ***EXECUTE STAGE
    **
    */


    wire [4:0] opcode, ALU_opcode, shiftamt;
    wire [16:0] intermediate;
    wire [31:0] sx_intermediate;
    wire [26:0] target;
    wire [31:0] ALU_inB;
    wire [31:0] bexPC;
    wire [31:0] xm_O_in_temp;
    wire isIType_X;
    wire isRType_X;
    wire isBranch_X;
    wire isJr;
    wire isMult, isDiv, isMultDiv;
    wire isALU;
    wire bexValid;
    wire isBex_X;

    assign opcode = xm_insn[31:27];
    
    assign isRType_X = (opcode == 5'd0);   //double check this is valid verilog 
    //if not RType, we can say it is IType (NOTE: only because JI, JII insns can be treated as I-type according to this ISA)
    assign isIType_X = isRType_X ? 1'd0: 1'd1; //need to modify 

    //for exception
    assign isALU = ((opcode == 5'd0 & (ALU_opcode == 5'd0 | ALU_opcode == 5'd1)) | opcode == 5'd5);

    assign isBranch_X = (opcode == 5'd2 | opcode == 5'd6);

    //handle bex command 
    assign isBex_X = (opcode == 5'd22);
    assign bexValid = (dx_B_out != 31'd0 && isBex_X);  //jump to T

    assign isJump = (opcode == 5'd1 | opcode == 5'd3 | opcode == 5'd4 | bexValid);  //need to adjust for other types of jumps
    assign isJr = (opcode == 5'd4);
   

    //I-type instruction doesn't have ALU opcode, need to force it to be bit-string of 5 zeroes if I-type
    assign ALU_opcode = isIType_X ? 5'd0: xm_insn[6:2]; 
   
    assign isMult = stall ? 1'b0: (ALU_opcode == 5'd6);
    assign isDiv = stall ? 1'b0: (ALU_opcode==5'd7);  //if stall then we are actively computing a mult/div, don't want this signal on
    assign isMultDiv = (isMult | isDiv);
   
    assign nextStall = ((isMult | isDiv | stall) & !multDivRDY);  //if stalling and result not ready, continue to stall
    
    assign shiftamt = xm_insn[11:7];
    assign intermediate = xm_insn[16:0];
    assign target = xm_insn[26:0];
    //sign extend immediate
    assign sx_intermediate = {{15{intermediate[16]}}, intermediate};
    
    //if bex
    assign bexPC = bexValid ? {{5{target[26]}}, target}: xm_pc; //xm_pc is just PC+1
    //if jr, then jumpPC is different
    //assign jumpPC_temp = {{5{target[26]}}, target};  //if jump or bex, will have same target 
    //wire jumpPC_nobypass;
    assign jumpPC_temp = {{5{target[26]}}, target};
    //assign jumpPC = isJr ? dx_B_out : jumpPC_temp; 

    assign jumpPC = (isJr & bypassDMEM_lw_jr) ? mw_D_in:
                    isJr ? dx_B_out:
                    {{5{target[26]}}, target};   
    //assign jumpPC_nobypass = isJr ? dx_B_out : jumpPC_temp;  //assign to value of rd if we have jr instruction
    //assign jumpPC = bypassDMEM_lw_jr ? mw_D_in: jumpPC_nobypass;
    //use mux to determine what ALU_inB is. Either dx_B_out or sign extended immediate 
    mux2 B_mux(.out(ALU_inB), .select(isIType_X & !isBranch_X), .in0(dx_B_out), .in1(sx_intermediate));
    wire notEqual, lessThan, over; 
    wire[31:0] ALU_out, A_in, B_in;
    assign A_in = memBypass_loadBeforeR_rs ? mw_D_in: dx_A_out;
    assign B_in = memBypass_loadBeforeR_rt ? mw_D_in: ALU_inB;
    alu myALU(.data_operandA(A_in),   //changed from dx_A_out
                .data_operandB(B_in),  //changed from ALU_inB
                .ctrl_ALUopcode(ALU_opcode),
                .ctrl_shiftamt(shiftamt),
                .data_result(ALU_out),  
                .isNotEqual(notEqual),
                .isLessThan(lessThan),
                .overflow(over));
   
   wire[31:0] multDivOut;
    wire multDivException, multDivRDY;
    /*
    multdiv myMultDiv(.data_operandA(A_in), 
                    .data_operandB(B_in),
                    .ctrl_MULT(isMult),
                    .ctrl_DIV(isDiv),
                    .clock(clock),
                    .data_result(multDivOut),
                    .data_exception(multDivException),
                    .data_resultRDY(multDivRDY));*/
   assign multDivOut = 32'd0;
   assign multDivException = 0;
   assign multDivRDY = 0;
   
    wire nopCheck;
    assign nopCheck = (xm_insn == 32'd0);
    //only assign exception if we dont have a nop
    assign xm_exception = nopCheck ? 1'd0: ((multDivException & stall)| (over & isALU));  

    assign xm_O_in_temp = (multDivRDY & stall) ? multDivOut: ALU_out;  //stall means we have a mult/div in execute stage
    assign xm_O_in = memBypass_rd_load ? mw_O_in: 
                    ((memBypass_lwsw_rs | memBypass_lwlw_rs) & (xm_insn[16:0] == 17'd0)) ? mw_D_in:  //note: this only works if immediate for instruction is 0, otherwise will throw an error (because nature of bypass would require intervention before ALU, not possible if adjacent instructions)
                    xm_O_in_temp;  //bypass value from data_mem stage
    assign xm_B_in = memBypass_rd_store ? mw_O_in: 
                    memBypass_lwsw_rd ? mw_D_in:  //handles lw into rX followed sw from rX
                    dx_B_out;  //rd in B register for sw
    
    //assigns select to 1 if rd and rs not equal with bne insn, or rd < rs with blt insn
    wire [31:0] bltResult; //implement separately from ALU lessThan signal due to bug
    wire carry; //not needed
    cla_32 branchCheckALU(.A(dx_A_out), 
                        .B(ALU_inB),
                        .opcode(5'd1),
                        .S(bltResult),
                        .cout(carry));

    wire bltCheck;
    //first logical check if if we have different signs (A negative, B positive)
    //second logical check handles same sign but A < B (MSB of trial subtract is 1)
    assign bltCheck = ((dx_A_out[31] & !dx_B_out[31] ) | 
                        (dx_A_out[31] == dx_B_out[31] & bltResult[31] == 1'b1));
    
    assign isValidBranch = (notEqual & opcode == 5'd2) | (bltCheck & opcode == 5'd6);
    wire b1, b2, b3;
    
    alu branchALU(.data_operandA(xm_pc),  //xm_pc = PC+1 
                .data_operandB(sx_intermediate),
                .ctrl_ALUopcode(5'd0),
                .ctrl_shiftamt(5'd0),
                .data_result(branchedPC),
                .isNotEqual(b1), 
                .isLessThan(b2),
                .overflow(b3));
    

    //BYPASSING ALU INTO DECODE STAGE
    wire bypassALU_XD_rs, prevIsAddi, prevIsR, isAddi_X; //RIType means R type with addi included
    //need to account for difference between addi and other R type instructions
    //check if rd of addi/Rtype is same as either input to ALU, need to specify which one
    //and handle uniquely because of mult div
    wire[4:0] rd_X = xm_insn[26:22];
    assign prevIsAddi = (dx_insn[31:27] == 5'd5);
    
    assign prevIsR = (dx_insn[31:27] == 5'd0);
   
    assign isAddi_X = (xm_insn[31:27] == 5'd5);
    
    //on addi addi, compare rd 26:22 (note rd is same for all of them) to dx[21:17]
    //also need to account for case of r5 = r5 + immediate 
    wire bypassALU_addi2_rs; //do I need to handle case above? --> as of now, not doing it
    assign bypassALU_addi2_rs = (prevIsAddi & isAddi_X & (dx_insn[21:17] == rd_X) & (rd_X != 0)); //rs same as rd for addi
   
    //addi, non addi
    wire bypassALU_addiR_rs, bypassALU_addiR_rt;
    assign bypassALU_addiR_rs = (prevIsR & isAddi_X & (dx_insn[21:17]==rd_X) & (rd_X != 0));
    assign bypassALU_addiR_rt = (prevIsR & isAddi_X & (dx_insn[16:12]==rd_X) & (rd_X != 0));  //distinguish between rt and rs

    //non addi, addi
    wire bypassALU_Raddi;
    assign bypassALU_Raddi = (prevIsAddi & isRType_X & (dx_insn[21:17]==rd_X) & (rd_X != 0));
   
   //non addi, non addi
   wire bypassALU_RR_rs, bypassALU_RR_rt;
   assign bypassALU_RR_rs = (prevIsR & isRType_X & (dx_insn[21:17] == rd_X) & (rd_X != 0));
   assign bypassALU_RR_rt = (prevIsR & isRType_X & (dx_insn[16:12] == rd_X) & (rd_X != 0));

   //addi, branch 

   wire bypassALU_addi_branch_rs, prevIsBranch;
   assign prevIsBranch = ((dx_insn[31:27] == 5'd2) | (dx_insn[31:27] == 5'd6));
   assign bypassALU_addi_branch_rs = (prevIsBranch & isAddi_X & (dx_insn[26:22] == rd_X) & (rd_X != 0));


    //addi, jr
    wire bypassALU_addi_jr, prevIsJr;
    assign prevIsJr = (dx_insn[31:27] == 5'd4);
    assign bypassALU_addi_jr = (prevIsJr & isAddi_X &(dx_insn[26:22] == rd_X) & (rd_X != 0));

    //setx, bex
    wire isSet_X,prevIsBex, bypassALU_setxbex;
    assign isSet_X = (xm_insn[31:27] == 5'd21);
    assign prevIsBex = (dx_insn[31:27] == 5'd22);
    assign bypassALU_setxbex = (isSet_X & prevIsBex); 



    /*
    **
    ***MEMORY STAGE
    **
    */
    wire store, load;  

    //ONE STAGE BYPASS CHECK FOR LW/SW IMMEDIATELY FOLLOWING R-TYPE INSN

    //grab rd of R-type, only assign if R-type
    wire memBypass_rd_load, memBypass_rd_store; //holds 1 if bypass required 
    wire isRType_M;
    wire [4:0] rd_RType_M;
    assign isRType_M = (((mw_insn[31:27] == 5'd0) & (mw_insn != 32'd0)) | mw_insn[31:27] == 5'd5);  //check for R-type insn or addi, also need to make sure not a nop
    
    assign rd_RType_M = mw_insn[26:22]; //destination register of insn if R-type
    //assign rd_IType_M = //rd is the 
    //check if this is in rs of previous instruction 
    //if lw, sw, rd is 21:17 of instruction 
    wire prevIsLoad, prevIsStore;
    wire [4:0] rd_LwSw_prev;  //have two cycle prev on wire in decode stage, don't need to explicitly determine
    assign prevIsLoad = (xm_insn[31:27] == 5'd8);
    assign prevIsStore = (xm_insn[31:27] == 5'd7); 
    assign rd_LwSw_prev = prevIsLoad ? xm_insn[21:17]: xm_insn[26:22];  //if store word, rd is 26:22

    assign memBypass_rd_load = (isRType_M & prevIsLoad & (rd_RType_M == rd_LwSw_prev));  
    assign memBypass_rd_store = (isRType_M & prevIsStore & (rd_RType_M == rd_LwSw_prev));
    //if true, change value written from ALU output to pipeline register for rs (done in execute stage with memBypass_1 signal)

    //TWO STAGE BYPASS CHECK FOR RD OF ADDI/R-TYPE BEING USED IN RS OF LW/SW 2 STAGES BACK
    //use same rd_RType_M as above
    wire prev2IsStoreLoad, memBypass2_rs;  //same for load and store 
    wire [4:0] rs_LwSw_prev2;
    assign rs_LwSw_prev2 = dx_insn[21:17]; //grab rs 
    assign prev2IsStoreLoad = (dx_insn[31:27] == 5'd7 | dx_insn[31:27] == 5'd8);
    assign memBypass2_rs = (isRType_M & prev2IsStoreLoad & (rs_LwSw_prev2 == rd_RType_M));

    //ONE STAGE BYPASS CHECK FOR R-TYPE IMMEDIATELY FOLLOWING LW
    wire prevIsRType, memBypass_loadBeforeR_rs, memBypass_loadBeforeR_rt; //include addi in this category
    wire[4:0] rs_prev; //could be rs or rt 
    wire [4:0] rt_prev;   //but need two variables to differentiate between the two because order matters in division
    assign rs_prev = xm_insn[21:17];
    assign rt_prev = xm_insn[16:12];
    assign prevIsRType = (((xm_insn[31:27] == 5'd0) & (xm_insn != 32'd0)) | xm_insn[31:27] == 5'd5); //include addi in this category
    assign memBypass_loadBeforeR_rs = ((rs_prev == mw_insn[26:22]) & load & prevIsRType);
    assign memBypass_loadBeforeR_rt = ((rt_prev == mw_insn[26:22]) & load & prevIsRType);


    //TWO STAGE BYPASS CHECK FOR R-TYPE FOLLOWING LW 
    wire prev2IsRType, memBypass_loadBeforeR_rs_2, memBypass_loadBeforeR_rt_2; //include addi in this category
    wire[4:0] rs_prev2; //could be rs or rt 
    wire [4:0] rt_prev2;   //but need two variables to differentiate between the two because order matters in division
    assign rs_prev2 = dx_insn[21:17];
    assign rt_prev2 = dx_insn[16:12];
    assign prev2IsRType = (((dx_insn[31:27] == 5'd0) & (dx_insn != 32'd0)) | dx_insn[31:27] == 5'd5); //include addi in this category
    assign memBypass_loadBeforeR_rs_2 = ((rs_prev2 == mw_insn[26:22]) & load & prev2IsRType);
    assign memBypass_loadBeforeR_rt_2 = ((rt_prev2 == mw_insn[26:22]) & load & prev2IsRType);

    //ONE STAGE BYPASS CHECK FOR SW FOLLOWING LW 
    //just do rd for now
    //use prevIsStore from above and rd_LwSw_prev from above
    wire memBypass_lwsw_rd, memBypass_lwsw_rs;
    wire [4:0] rs_LwSw_prev;
    assign rs_LwSw_prev = xm_insn[21:17];
    assign memBypass_lwsw_rd = (load & prevIsStore & (rd_LwSw_prev == mw_insn[26:22]));
    assign memBypass_lwsw_rs = (load & prevIsStore & (rs_LwSw_prev == mw_insn[26:22]));

    //ONE STAGE BYPASS CHECK FOR LW FOLLOWING LW
    wire memBypass_lwlw_rs;
    //assign memBypass_lwlw_rd = (load & prevIsLoad & (rd_Lw_prev) == mw_insn[26:22]); //rd we load to is same as rd in next load 
    assign memBypass_lwlw_rs = (load & prevIsLoad & (rs_LwSw_prev == mw_insn[26:22]));

    //TWO STAGE BYPASS CHECK FOR RD OF RTYPE/ADDI BEING USED AS RD FOR SW
    wire memBypass_Rtype_sw_2, prev2IsStore;
    wire [4:0] rd_sw_prev2;
    assign prev2IsStore = (dx_insn[31:27] == 5'd7);
    assign rd_sw_prev2 = dx_insn[26:22];
    assign memBypass_Rtype_sw_2 = (prev2IsStore & isRType_M & (rd_sw_prev2 == rd_RType_M));

    //ALU addi, .., addi check
    wire prev2IsAddi, prev2IsR, isAddi_M;
    assign isAddi_M = (mw_insn[31:27] == 5'd5);
    assign prev2IsR = (dx_insn[31:27] == 5'd0);
    assign prev2IsAddi = (dx_insn[31:27] == 5'd5);
    wire bypassDMEM_D_addi_rs; //do I need to handle case above? --> as of now, not doing it
    assign bypassDMEM_D_addi_rs = (prev2IsAddi & isAddi_M & (dx_insn[21:17] == rd_RType_M) & (rd_RType_M != 0)); //rs same as rd for addi

    //ALU addi, ..., RType check
    wire bypassDMEM_D_addiR_rs, bypassDMEM_D_addiR_rt;
    assign bypassDMEM_D_addiR_rs = (isAddi_M & prev2IsR & (dx_insn[21:17] == rd_RType_M) & (rd_RType_M != 0));
    assign bypassDMEM_D_addiR_rt = (isAddi_M & prev2IsR & (dx_insn[16:12] == rd_RType_M) & (rd_RType_M != 0));

    //ALU RType, ..., RType check
    wire bypassDMEM_D_RR_rs, bypassDMEM_D_RR_rt;
    assign bypassDMEM_D_RR_rs = ((mw_insn[31:27] == 5'd0) & prev2IsR & (dx_insn[21:17] == rd_RType_M) & (rd_RType_M != 0));
    assign bypassDMEM_D_RR_rt = ((mw_insn[31:27] == 5'd0) & prev2IsR & (dx_insn[16:12] == rd_RType_M) & (rd_RType_M != 0));

    //addi, ... , branch check
    wire prev2IsBranch, bypassDMEM_D_addiB_rs;
    assign prev2IsBranch = ((dx_insn[31:27] == 5'd6) | (dx_insn[31:27] == 5'd2));
    assign bypassDMEM_D_addiB_rs = (prev2IsBranch & isAddi_M & (mw_insn[26:22] == dx_insn[21:17])); //rs of branch, not rd

    //lw, jr check
    wire prevIsJr_M, bypassDMEM_lw_jr;
    assign prevIsJr_M = (xm_insn[31:27] == 5'd4);
    assign bypassDMEM_lw_jr = (prevIsJr_M & load);

    


    //assign output of ALU to input of pipeline MW register for insns that don't deal with memory
    assign mw_O_in = xm_O_out;
   
    //sw and lw are only cases where we touch memory, (opcode in decimal is 7, 8 respectively)
    
    assign store = (mw_insn[31:27] == 5'd7);
    assign load = (mw_insn[31:27] == 5'd8);
    //write to data mem if store 
    //xm_O_out is memory address we are loading/storing to(immediate added to rs)
    assign address_dmem = xm_O_out;  //output from ALU
    assign wren = store ? 1'd1: 1'd0;  //if storing enable write to dmem
    assign data = xm_B_out;  //contains value from rd 

    //for load word, use q_dmem, which is an input to our processor from memory
    assign mw_D_in = q_dmem;  //data loaded from memory

    /*
    **
    ***WRITE-BACK STAGE
    **
    */

    wire load_WB, store_WB, wback, isJal_WB, notRType;
    wire [4:0] ctrl_writeReg_temp;
    wire [31:0] data_writeReg_temp;
    wire [4:0] wb_ALUop;
    wire [31:0] target_wb;
    wire isSetx;
    assign load_WB = (wback_insn[31:27] == 5'd8);  //if load_WB, then take output from d_mem instead of ALU output
    assign store_WB = (wback_insn[31:27] == 5'd7);
    assign wback = (wback_insn[31:27] == 5'd5 | wback_insn[31:27] == 5'd0 | wback_insn[31:27] == 5'd3); 
    assign isJal_WB = (wback_insn[31:27] == 5'd3);
    assign notRType = (wback_insn[31:27] != 5'd0);   //for our purposes no need to specify beyond this
    assign wb_ALUop = wback_insn[6:2];
    assign isSetx = (wback_insn[31:27] == 5'd21);
    assign target_wb = ({{5{wback_insn[26]}}, wback_insn[26:0]});
    
    //this will take care of blt and bne
    assign ctrl_writeEnable = (wback | load_WB | isSetx);

    
    wire [31:0] exceptionVal_temp, exceptionVal;
    //check ALU opcode, assign exception value accordingly
    //if addi, then set opcode to be 1 
    assign exceptionVal_temp = (wb_ALUop == 5'd0) ? 32'd1:  //add
                                (wb_ALUop == 5'd1) ? 32'd3: //sub
                                (wb_ALUop == 5'd6) ? 32'd4: //multiply
                                32'd5; //must be divide

    assign exceptionVal = notRType ? 32'd2: exceptionVal_temp;   //if not RType, then we have I type and need to assign rstatus to be 2

    assign data_writeReg = load_WB ? mw_D_out:
                            isJal_WB ? wb_pc:
                            wb_exception ? exceptionVal:
                            isSetx ? target_wb:
                            mw_O_out;
    
    assign ctrl_writeReg = isJal_WB ? 5'd31: 
                                (wb_exception | isSetx) ? 5'd30:  //if exception, write back to r30
                                wback_insn[26:22];


	/* END CODE */

endmodule
