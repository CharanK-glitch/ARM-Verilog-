`timescale 1ns / 1ps
//(*DONT_TOUCH = "true"*)
module Extend(
//    (*DONT_TOUCH = "true"*)
	output signed [31:0] ExtImm,
//	(*DONT_TOUCH = "true"*)
	input [1:0] ImmSrc,
//	(*DONT_TOUCH = "true"*)
	input signed [23:0] Immediate
);

assign ExtImm = (ImmSrc == 2'b00 ) ? $signed(Immediate) : 
                (ImmSrc == 2'b01 ) ? $signed(Immediate[11:0]) :
                $signed(Immediate[21:0]);

endmodule
