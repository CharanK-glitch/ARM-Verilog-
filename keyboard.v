module keyboard

    (
	       input wire clk, reset,
        input wire ps2d, ps2c,               // ps2 data and clock lines
        input wire [7:0] ascii,
        output wire [7:0] scan_code,         // scan_code received from keyboard to process
        output wire scan_code_ready,         // signal to outer control system to sample scan_code
        output wire letter_case_out,          // output to determine if scan code is converted to lower or upper ascii code for a key
        output reg [3:0] code
    );
	parameter lowercase = 0;
	parameter break = 1;
	parameter shift = 2;
	parameter ignore_shift_break = 3;
	
	parameter BREAK = 8'hf0;
	parameter SHIFT1 = 8'h12;
	parameter SHIFT2 = 8'h59;

//    (*DONT_TOUCH = "true"*)
    wire [2:0] next_state;
//    (*DONT_TOUCH = "true"*)
    reg [2:0] current_state;
//    (*DONT_TOUCH = "true"*)
    wire [7:0] scan_out;
//    (*DONT_TOUCH = "true"*)
    wire scan_done_tick;
//    (*DONT_TOUCH = "true"*)
    reg [7:0] shiftType;
    ps2_rx ps2_rx_unit (.clk(clk), .reset(reset), .rx_en(1'b1), .ps2d(ps2d), .ps2c(ps2c), .rx_done_tick(scan_done_tick), .rx_data(scan_out));

	initial 
	   begin
	       current_state = lowercase;
	   end
	
	always @(posedge scan_done_tick)
	   begin
	       current_state <= next_state;
	   end
	
	assign next_state = (current_state == lowercase && scan_out == BREAK ) ? break : lowercase;
	assign scan_code_ready = (current_state == break) ? 1'b1 : 1'b0;

    assign letter_case_out = 1'b0; 

    assign scan_code = scan_out;
    
    always @(negedge scan_code_ready)
        code <= ascii[3:0];  
//    assign code[3] = scan_code_ready;
//    assign code[2:0] = ascii[2:0];
	
endmodule
