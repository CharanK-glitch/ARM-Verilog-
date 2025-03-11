`timescale 1ns / 1ps
module ControlUnit(
	output IRWrite,
	output [1:0]PCWrite,
	output memIsWrite, 
	output regIsWrite,
	output AluSrcAControl,
	output AdrSrc,
	output RegSrc,
	output [1:0]RegSrc2,
	output [1:0] ImmSrc,
	output [1:0] ResultSrc,
	output [3:0] AluControl,
	output [1:0] AluSrcBControl,
	output reg byteRead,
	output byteWrite,

	input [3: 0] cond,
	input [1: 0] op,
	input [5: 0] funct,
	input [3: 0] rd,
	input zr,
	input neg,
	input clock,
	input interrupt
);

parameter Reset = 0;
parameter Fetch = 1;
parameter Decode = 2;
parameter MemAdr = 3;
parameter MemRead = 4;
parameter MemWB = 5;
parameter MemWrite = 6;
parameter ExecuteR = 7;
parameter ExecuteI = 8;
parameter AluWB = 9;
parameter Branch = 10;
parameter InterruptState1 = 11;
parameter InterruptState2 = 12;

reg [3:0] state;
wire [3:0] nextState;
reg interruptMode;
reg prev;

initial 
    begin
        state = Reset;
        interruptMode <= 1'b0;
        prev <= 1'b0;
    end

always @ (negedge clock) 
    begin
        if( nextState == Fetch && prev != interrupt && interruptMode == 1'b0 )
            begin
                state <= InterruptState1;
                interruptMode <= 1'b1;
                prev <= interrupt;
            end
        else
	       state <= nextState;
	       
	    if( nextState == MemRead && funct[1] == 1'b1 )
	       byteRead <= 1'b1;
	    else if( nextState == MemRead && funct[1] == 1'b0 )
	       byteRead <= 1'b0;
	    
	    if( nextState == Branch && funct[5:4] == 2'b01 )
	       interruptMode <= 1'b0;
    end

assign IRWrite      = (state == Fetch ) ? 1'b1 : 1'b0;
assign PCWrite      = (state == Branch || state == Fetch ) ? 2'b01 : 
                      (state == InterruptState2) ? 2'b10: 
                      2'b00;
//assign PCWrite      = (state == Branch || state == Fetch ) ? 1'b1 : 1'b0;
assign memIsWrite   = (state == MemWrite ) ? 1'b1 : 1'b0;
assign regIsWrite   = (state == MemWB || state == AluWB || state == InterruptState1 ) ? 1'b1 : 1'b0;
//assign regIsWrite   = (state == MemWB || state == AluWB ) ? 1'b1 : 1'b0;
//assign AluSrcAControl   = (state == Fetch || state == Decode || state == Branch) ? 1'b1 : 1'b0;
assign AluSrcAControl   = (state == Fetch || state == Decode || state == Branch || state == InterruptState1 ) ? 1'b1 : 1'b0;
assign AdrSrc       = (state == MemRead || state == MemWrite) ? 1'b1 : 1'b0;
assign RegSrc       = (op == 2'b01 && funct[0] == 1'b0 ) ? 1'b1 : 1'b0;
//assign RegSrc2       = (state == AluWB && op == 2'b11 ) ? 1'b1 : 1'b0;
assign RegSrc2      = (state == AluWB && op == 2'b11 ) ? 2'b01 :
                      (state == InterruptState1 ) ? 2'b10 :
                      2'b00;
assign ImmSrc       = (op == 2'b11) ? 2'b11 :
                      (op == 2'b10) ? 2'b00 :
                      2'b01;

//assign ResultSrc    = (state == Fetch || state == Decode || state == Branch) ? 2'b10 : (state == MemWB) ? 2'b01 : 2'b00;
assign ResultSrc    = (state == Fetch || state == Decode || state == Branch || state == InterruptState1) ? 2'b10 : (state == MemWB) ? 2'b01 : 2'b00;
//assign AluControl   = (state == ExecuteR && funct[0] == 1'b1) ? 4'b10 : 4'b00;
assign AluControl = (state == ExecuteR ) ? funct[4:1] : 
                    (state == ExecuteI && op == 2'b11 ) ? 4'd3 :
                    (state == ExecuteI && op != 2'b11 ) ? funct[4:1] :
                    4'd0;
//assign AluSrcBControl = (state == Fetch || state == Decode) ? 2'b10 : (state == ExecuteR || (state == Branch && funct[4] == 1'b1 ) ) ? 2'b00 : 2'b01;
assign AluSrcBControl = (state == Fetch || state == Decode || state == InterruptState1) ? 2'b10 : (state == ExecuteR || (state == Branch && funct[4] == 1'b1 ) ) ? 2'b00 : 2'b01;
assign byteWrite = (state == MemWrite && funct[1] == 1'b1 ) ? 1'b1 : 1'b0;

assign nextState = (state == Fetch) ? Decode :
                   (state == MemAdr && funct[0] == 1'b1) ? MemRead :
                   (state == MemAdr && funct[0] == 1'b0) ? MemWrite :
                   (state == MemRead ) ? MemWB :
                   //(state == MemWrite ) ? Fetch :
                   //(state == MemWB ) ? Fetch :
                   //(state == ExecuteR && funct[0] == 1'b1 ) ? Fetch :
                   (state == ExecuteR && funct[4:1] != 4'd2 ) ? AluWB :
                   (state == ExecuteI) ? AluWB :
                   //(state == AluWB) ? Fetch:
                   //(state == Branch) ? Fetch:
                   (state == Decode && op == 2'b01) ? MemAdr :
                   (state == Decode && op == 2'b00 && funct[5] == 1'b0) ? ExecuteR :
                   (state == Decode && op == 2'b00 && funct[5] == 1'b1) ? ExecuteI :
                   (state == Decode && op == 2'b10 && cond == 4'b1110 ) ? Branch :
                   (state == Decode && op == 2'b10 && cond == 4'b0000 && zr == 1'b1 ) ? Branch :
                   (state == Decode && op == 2'b10 && cond == 4'b0001 && zr == 1'b0 ) ? Branch :
                   (state == Decode && op == 2'b11 ) ? ExecuteI :
                   (state == InterruptState1 ) ? InterruptState2 :
                   Fetch;
                
endmodule
