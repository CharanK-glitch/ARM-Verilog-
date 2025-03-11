`timescale 1ns / 1ps
//(*DONT_TOUCH = "true"*)
module ALU (
//    (*DONT_TOUCH = "true"*)
	input signed [31:0] in1,
//	(*DONT_TOUCH = "true"*)
	input signed [31:0] in2,
//	(*DONT_TOUCH = "true"*)
    input clock,
    
//    (*DONT_TOUCH = "true"*)
	input [3:0] controlBits,

//    (*DONT_TOUCH = "true"*)
	output signed [31:0] out,
//	(*DONT_TOUCH = "true"*)
	output zr,
//	(*DONT_TOUCH = "true"*)
	output neg
);

reg zreg,nreg;

assign out = (controlBits == 4'd0) ? in1+in2 :
             (controlBits == 4'd1) ? in1-in2 : 
             (controlBits == 4'd2) ? 32'd0 : 
             (controlBits == 4'd3) ? in2 :
             (controlBits == 4'd4) ? in1*in2 :
             (controlBits == 4'd5) ? in1/in2 :
             (controlBits == 4'd6) ? in1%in2 :
             (controlBits == 4'd7) ? in1|in2 :
             (controlBits == 4'd8) ? in1&in2 :
             (controlBits == 4'd9) ? ((in1<in2) ? 32'd1 : 32'd0) :
             (controlBits == 4'd10) ? ((in1<=in2) ? 32'd1 : 32'd0) :
             (controlBits == 4'd11) ? ((in1>in2) ? 32'd1 : 32'd0) :
             (controlBits == 4'd12) ? ((in1>=in2) ? 32'd1 : 32'd0) :
             (controlBits == 4'd13) ? ((in1==in2) ? 32'd1 : 32'd0) :
             (controlBits == 4'd14) ? ((in1!=in2) ? 32'd1 : 32'd0) :
             in1 << in2;
             

assign zr = zreg;
assign neg = nreg; 

always @(posedge clock)
    begin
        if( controlBits == 4'd2 )
            begin
                zreg = (in1 == in2);
                nreg = (in1 < in2);
            end
    end         
//assign zr = (controlBits == 4'd2 && in1 == in2 ) ? 1'b1 : 1'b0;
//assign neg = (controlBits == 4'd2 && in1 < in2 ) ? 1'b1 : 1'b0;
//assign neg = (controlBits == 4'd2 ) ? (in1 < in2) : neg;
endmodule
