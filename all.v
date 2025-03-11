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
`timescale 1ns / 1ps

module DisplayDriver(
	input clk,
    input [0:31] displayData,
 
	output [2:0] TMDSp, TMDSn,
	output TMDSp_clock, TMDSn_clock,
	output [31:0] pointer
);

////////////////////////////////////////////////////////////////////
// clk divider 125 MHz to 25 MHz pixclk, and multiplier 125 MHz to 250 MHz
        wire MMCM_pix_clock, pixclk;
        wire clk_TMDS, DCM_TMDS_CLKFX;
        wire clkfb_in, clkfb_out;

   MMCME2_BASE #(
      .BANDWIDTH("OPTIMIZED"),   // Jitter programming (OPTIMIZED, HIGH, LOW)
      .CLKFBOUT_MULT_F(6.0),     // Multiply value for all CLKOUT (2.000-64.000).
      .CLKFBOUT_PHASE(0.0),      // Phase offset in degrees of CLKFB (-360.000-360.000).
      .CLKIN1_PERIOD(8.0),       // Input clock period in ns to ps resolution (i.e. 33.333 is 30 MHz).
      // CLKOUT0_DIVIDE - CLKOUT6_DIVIDE: Divide amount for each CLKOUT (1-128)
      .CLKOUT1_DIVIDE(30),  // 125*6/30 = 25 MHz
      .CLKOUT2_DIVIDE(3),   // 125*6/3  = 250 MHz
      .CLKOUT3_DIVIDE(1),
      .CLKOUT4_DIVIDE(1),
      .CLKOUT5_DIVIDE(1),
      .CLKOUT6_DIVIDE(1),
      .CLKOUT0_DIVIDE_F(1.0),    // Divide amount for CLKOUT0 (1.000-128.000).
      // CLKOUT0_DUTY_CYCLE - CLKOUT6_DUTY_CYCLE: Duty cycle for each CLKOUT (0.01-0.99).
      .CLKOUT0_DUTY_CYCLE(0.5),
      .CLKOUT1_DUTY_CYCLE(0.5),
      .CLKOUT2_DUTY_CYCLE(0.5),
      .CLKOUT3_DUTY_CYCLE(0.5),
      .CLKOUT4_DUTY_CYCLE(0.5),
      .CLKOUT5_DUTY_CYCLE(0.5),
      .CLKOUT6_DUTY_CYCLE(0.5),
      // CLKOUT0_PHASE - CLKOUT6_PHASE: Phase offset for each CLKOUT (-360.000-360.000).
      .CLKOUT0_PHASE(0.0),
      .CLKOUT1_PHASE(0.0),
      .CLKOUT2_PHASE(0.0),
      .CLKOUT3_PHASE(0.0),
      .CLKOUT4_PHASE(0.0),
      .CLKOUT5_PHASE(0.0),
      .CLKOUT6_PHASE(0.0),
      .CLKOUT4_CASCADE("FALSE"), // Cascade CLKOUT4 counter with CLKOUT6 (FALSE, TRUE)
      .DIVCLK_DIVIDE(1),         // Master division value (1-106)
      .REF_JITTER1(0.0),         // Reference input jitter in UI (0.000-0.999).
      .STARTUP_WAIT("FALSE")     // Delays DONE until MMCM is locked (FALSE, TRUE)
   )
   MMCME2_BASE_INST (
      // Clock Outputs: 1-bit (each) output: User configurable clock outputs
      .CLKOUT0(CLKOUT0),     // 1-bit output: CLKOUT0
      .CLKOUT0B(CLKOUT0B),   // 1-bit output: Inverted CLKOUT0
      .CLKOUT1(MMCM_pix_clock),     // 1-bit output: CLKOUT1
      .CLKOUT1B(CLKOUT1B),   // 1-bit output: Inverted CLKOUT1
      .CLKOUT2(DCM_TMDS_CLKFX),     // 1-bit output: CLKOUT2
      .CLKOUT2B(CLKOUT2B),   // 1-bit output: Inverted CLKOUT2
      .CLKOUT3(CLKOUT3),     // 1-bit output: CLKOUT3
      .CLKOUT3B(CLKOUT3B),   // 1-bit output: Inverted CLKOUT3
      .CLKOUT4(CLKOUT4),     // 1-bit output: CLKOUT4
      .CLKOUT5(CLKOUT5),     // 1-bit output: CLKOUT5
      .CLKOUT6(CLKOUT6),     // 1-bit output: CLKOUT6
      // Feedback Clocks: 1-bit (each) output: Clock feedback ports
      .CLKFBOUT(clkfb_in),   // 1-bit output: Feedback clock
      .CLKFBOUTB(CLKFBOUTB), // 1-bit output: Inverted CLKFBOUT
      // Status Ports: 1-bit (each) output: MMCM status ports
      .LOCKED(LOCKED),       // 1-bit output: LOCK
      // Clock Inputs: 1-bit (each) input: Clock input
      .CLKIN1(clk),       // 1-bit input: Clock
      // Control Ports: 1-bit (each) input: MMCM control ports
      .PWRDWN(PWRDWN),       // 1-bit input: Power-down
      .RST(1'b0),             // 1-bit input: Reset
      // Feedback Clocks: 1-bit (each) input: Clock feedback ports
      .CLKFBIN(clkfb_out)      // 1-bit input: Feedback clock
   );

   BUFG BUFG_pixclk (
      .O(pixclk), // 1-bit output: Clock output
      .I(MMCM_pix_clock)  // 1-bit input: Clock input
   );
 
   BUFG BUFG_TMDSp (
      .O(clk_TMDS), // 1-bit output: Clock output
      .I(DCM_TMDS_CLKFX)  // 1-bit input: Clock input
   );
 
   BUFG BUFG_CLKFB (
      .O(clkfb_out), // 1-bit output: Clock output
      .I(clkfb_in)  // 1-bit input: Clock input
   );


// counter and sync generation
reg [9:0] CounterX = 0, CounterY = 0;
reg hSync, vSync, DrawArea;
wire [7:0] red, green, blue;

always @(posedge pixclk)
    begin
        DrawArea <= (CounterX<640) && (CounterY<480);           // define picture dimensions for 640x480 (off-screen data 800x525)
        CounterX <= (CounterX==799) ? 0 : CounterX+1;           // horizontal counter (including off-screen horizontal 160 pixels) total of 800 pixels 
        if(CounterX==799) 
            CounterY <= (CounterY==524) ? 0 : CounterY+1;       /* vertical counter (including off-screen vertical 45 pixels) total of 525 pixels
                                                                   only counts up 1 count after horizontal finishes. */                                                          
        hSync <= (CounterX>=656) && (CounterX<752);         // hsync high for 96 counts                                                 
        vSync <= (CounterY>=490) && (CounterY<492);         // vsync high for 2 counts
    end

//assign red = 8'd0;
//assign blue = 8'd0;
//assign green = 8'd255;

parameter memOffset = 0;
parameter hx = 2;
parameter yx = 2;

wire [31:0] current;
wire [31:0] yoffset;
wire [31:0] xoffset;

assign yoffset = (CounterY/yx)*10;
assign xoffset = (CounterX/64);
wire [31:0] sum;
assign sum = memOffset + yoffset + xoffset;
assign pointer = memOffset + yoffset + xoffset;

wire [5:0] mod = CounterX % 64;
assign red = (displayData[mod/2] == 1'b1 ) ? 8'd52 : 8'd45;
assign blue = (displayData[mod/2] == 1'b1 ) ? 8'd164 : 8'd34;
assign green = (displayData[mod/2] == 1'b1 ) ? 8'd101 : 8'd9;


wire [9:0] TMDS_red, TMDS_green, TMDS_blue;

// instantiate TMDS encoders (TMDS_encoder.vhd file from github)
TMDS_encoder encode_R(.clk(pixclk), .VD(red  ), .CD(2'b00)        , .VDE(DrawArea), .TMDS(TMDS_red));
TMDS_encoder encode_G(.clk(pixclk), .VD(green), .CD(2'b00)        , .VDE(DrawArea), .TMDS(TMDS_green));
TMDS_encoder encode_B(.clk(pixclk), .VD(blue ), .CD({vSync,hSync}), .VDE(DrawArea), .TMDS(TMDS_blue));   // I think HDMI standard says both "sync" signals are sent over the "blue" line control inputs

reg [3:0] TMDS_mod10=0;  // modulus 10 counter
reg [9:0] TMDS_shift_red=0, TMDS_shift_green=0, TMDS_shift_blue=0;
reg TMDS_shift_load=0;

always @(posedge clk_TMDS) 
    TMDS_shift_load <= (TMDS_mod10==4'd9);  // shift load is high only if mod ten counter is done

always @(posedge clk_TMDS)
    begin
        TMDS_shift_red   <= TMDS_shift_load ? TMDS_red   : TMDS_shift_red  [9:1];  // only if all the old data has been serialized, then start shifting new data
        TMDS_shift_green <= TMDS_shift_load ? TMDS_green : TMDS_shift_green[9:1];  // kind of a wierd way of shifting but it works. replacing the last shift data with the MSB:LSB+1
        TMDS_shift_blue  <= TMDS_shift_load ? TMDS_blue  : TMDS_shift_blue [9:1];	
        TMDS_mod10 <= (TMDS_mod10==4'd9) ? 4'd0 : TMDS_mod10+4'd1;                 // increase counter or reset after 10 counts
    end

begin
   OBUFDS #(
      .IOSTANDARD("DEFAULT"), // Specify the output I/O standard
      .SLEW("SLOW")           // Specify the output slew rate
   ) OBUFDS_red (
      .O(TMDSp[2]),     // Diff_p output (connect directly to top-level port)
      .OB(TMDSn[2]),   // Diff_n output (connect directly to top-level port)
      .I(TMDS_shift_red[0])      // Buffer input
   );

   OBUFDS #(
      .IOSTANDARD("DEFAULT"), // Specify the output I/O standard
      .SLEW("SLOW")           // Specify the output slew rate
   ) OBUFDS_green (
      .O(TMDSp[1]),     // Diff_p output (connect directly to top-level port)
      .OB(TMDSn[1]),   // Diff_n output (connect directly to top-level port)
      .I(TMDS_shift_green[0])      // Buffer input
   );

   OBUFDS #(
      .IOSTANDARD("DEFAULT"), // Specify the output I/O standard
      .SLEW("SLOW")           // Specify the output slew rate
   ) OBUFDS_blue (
      .O(TMDSp[0]),     // Diff_p output (connect directly to top-level port)
      .OB(TMDSn[0]),   // Diff_n output (connect directly to top-level port)
      .I(TMDS_shift_blue[0])      // Buffer input
   );

   OBUFDS #(
      .IOSTANDARD("DEFAULT"), // Specify the output I/O standard
      .SLEW("SLOW")           // Specify the output slew rate
   ) OBUFDS_clock (
      .O(TMDSp_clock),     // Diff_p output (connect directly to top-level port)
      .OB(TMDSn_clock),   // Diff_n output (connect directly to top-level port)
      .I(pixclk)      // Buffer input
   );
end
endmodule  // HDMI_test

`timescale 1ns / 1ps

module TMDS_encoder(
	input clk,
	input [7:0] VD,  // video data (red, green or blue)
	input [1:0] CD,  // control data
	input VDE,  // video data enable, to choose between CD (when VDE=0) and VD (when VDE=1)
	output reg [9:0] TMDS = 0
);
    begin
        wire [3:0] Nb1s = VD[0] + VD[1] + VD[2] + VD[3] + VD[4] + VD[5] + VD[6] + VD[7];
        wire XNOR = (Nb1s>4'd4) || (Nb1s==4'd4 && VD[0]==1'b0);
        wire [8:0] q_m = {~XNOR, q_m[6:0] ^ VD[7:1] ^ {7{XNOR}}, VD[0]};
        
        reg [3:0] balance_acc = 0;
        wire [3:0] balance = q_m[0] + q_m[1] + q_m[2] + q_m[3] + q_m[4] + q_m[5] + q_m[6] + q_m[7] - 4'd4;
        wire balance_sign_eq = (balance[3] == balance_acc[3]);
        wire invert_q_m = (balance==0 || balance_acc==0) ? ~q_m[8] : balance_sign_eq;
        wire [3:0] balance_acc_inc = balance - ({q_m[8] ^ ~balance_sign_eq} & ~(balance==0 || balance_acc==0));
        wire [3:0] balance_acc_new = invert_q_m ? balance_acc-balance_acc_inc : balance_acc+balance_acc_inc;
        wire [9:0] TMDS_data = {invert_q_m, q_m[8], q_m[7:0] ^ {8{invert_q_m}}};
        wire [9:0] TMDS_code = CD[1] ? (CD[0] ? 10'b1010101011 : 10'b0101010100) : (CD[0] ? 10'b0010101011 : 10'b1101010100);
        
        always @(posedge clk) TMDS <= VDE ? TMDS_data : TMDS_code;
        always @(posedge clk) balance_acc <= VDE ? balance_acc_new : 4'h0;
    end
endmodule`timescale 1ns / 1ps
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
module Datapath(
    input sysclk,
    input [7:0] je,
    output [3:0] sysled,
    output [2:0] TMDSp, TMDSn,
	output TMDSp_clock, TMDSn_clock
    );

(*DONT_TOUCH = "true"*)
reg [28:0] counter;
always @ (posedge(sysclk))
    begin
        if( counter[28] != 1'b1 || counter[27] != 1'b1 )
                counter <= counter + 1;
        else
                counter = 0;
    end    

wire clock;
assign clock = counter[6];

//control unit var
wire [3:0] led;
wire IRWrite; 
wire [1:0]PCWrite;
wire memIsWrite;
wire regIsWrite;
wire AluSrcAControl;
wire AdrSrc;
wire RegSrc;
wire [1:0]RegSrc2;
wire [1:0] ImmSrc;
wire [1:0] ResultSrc;
wire [3:0] AluControl;
wire [1:0] AluSrcBControl;
wire [3: 0] cond;
wire [1: 0] op;
wire [5: 0] funct;
wire [3: 0] rd;
wire byteRead;
wire byteWrite;

//Memory vars
wire [31:0] memA;
wire [31:0] memWD;


//Register vars
wire [3:0] regA1;
wire [3:0] regA2;
wire [3:0] regA3;
wire [31:0] regWD3;
wire [31:0] regRD1;
wire [31:0] regRD2;

//Un Architectural registers
reg [31:0] PC;
wire [31:0] IR;
reg [31:0] AluOut;
reg [31:0] regRD1A;
reg [31:0] regRD2A;
wire [31:0] memRDData;

//Un Architectural wires
wire [31:0] Result;

//Alu vars
wire [31:0] AlusrcA;
wire [31:0] AlusrcB;
wire [31:0] AluResult;
wire zr;
wire neg;

//Extend vars
wire [31:0] ExtImm;

//display vars 
wire [31:0] displayData;
wire [31:0] pointer;

//keyboar
wire [7:0] ascii_code;
(*DONT_TOUCH = "true"*)
wire scan_code_ready;
reg [7:0] key_reg;
reg sample;

wire [3:0] du;
(*DONT_TOUCH = "true"*)
top keyb(
    .je(je),
    .sysclk(sysclk),
    .led(du),
    .ascii_code(ascii_code),
    .scan_code_ready(scan_code_ready)
);

//(*DONT_TOUCH = "true"*)
Memory mem(
	.clock(clock),
	.isWrite(memIsWrite),
	.address(memA[17:0]),
	.writeData(memWD),
	.data(memRDData),
	.IRWrite(IRWrite),
	.IR(IR),
    .byteWrite(byteWrite),
	.displayAddr(pointer),
	.displayData(displayData),
	.byteRead(byteRead),
	.key_reg(key_reg),
	.sample(sample)
);

//(*DONT_TOUCH = "true"*)
DisplayDriver dis(
    .clk(sysclk),
    .displayData(displayData),
    .pointer(pointer),
    .TMDSn(TMDSn),
    .TMDSp(TMDSp),
    .TMDSp_clock(TMDSp_clock),
    .TMDSn_clock(TMDSn_clock)
);

//(*DONT_TOUCH = "true"*)
RegisterFile regFile(
	.clock(clock),
	.A1(regA1),
	.A2(regA2),
	.A3(regA3),
	.RD1(regRD1),
	.RD2(regRD2),
	.writeData(regWD3),
	.isWrite(regIsWrite),
	.led(led)
);

//(*DONT_TOUCH = "true"*)
ALU alu(
	.in1(AlusrcA),
	.in2(AlusrcB),
	.controlBits(AluControl),
	.out(AluResult),
	.zr(zr),
	.neg(neg),
	.clock(clock)
);

//(*DONT_TOUCH = "true"*)
Extend ext(
	.ExtImm(ExtImm),
	.Immediate(IR[23:0]),
	.ImmSrc(ImmSrc)
);

//(*DONT_TOUCH = "true"*)
ControlUnit cu(
	.IRWrite(IRWrite),
	.PCWrite(PCWrite),
	.memIsWrite(memIsWrite),
	.regIsWrite(regIsWrite),
	.AluSrcAControl(AluSrcAControl),
	.AdrSrc(AdrSrc),
	.ImmSrc(ImmSrc),
	.ResultSrc(ResultSrc),
	.AluControl(AluControl),
	.AluSrcBControl(AluSrcBControl),
	.clock(clock),
	.byteRead(byteRead),
	.byteWrite(byteWrite),
	.RegSrc(RegSrc),
	.RegSrc2(RegSrc2),
	.cond(cond),
	.op(op),
	.rd(rd),
	.zr(zr),
	.neg(neg),
	.funct(funct),
	.interrupt(interrupt)
);

wire interrupt;

initial
	begin
		PC <= 32'd9600;
		counter[28] <= 1'b1;
		sample <= 1'b1;
		key_reg <= 8'd49;
	end

assign sysled   = led;
assign regA1    = IR[19:16];
assign regA2    = (RegSrc == 1'b0)? IR[3:0]: IR[15:12];
//assign regA3    = (RegSrc2 == 1'b1) ? IR[25:22] : IR[15:12];
assign regA3    = (RegSrc2 == 2'b01) ? IR[25:22] : 
                  (RegSrc2 == 2'b10) ? 4'd5:
                  IR[15:12];
assign AlusrcA  = AluSrcAControl ? PC : regRD1A;
assign AlusrcB  = (AluSrcBControl == 2'b00)? regRD2A : (AluSrcBControl == 2'b01 ) ? ExtImm : (AluSrcBControl == 2'b10) ? 32'd4 : 32'd0;
assign Result   = (ResultSrc == 2'b00) ? AluOut : (ResultSrc == 2'b01) ? memRDData : AluResult;
assign memA     = AdrSrc ? Result : PC;
assign cond     = IR[31:28];
assign funct    = IR[25:20];
assign op       = IR[27:26];
assign rd       = IR[15:12];
assign regWD3   = Result;
assign memWD   = regRD2;

parameter scheduler_loc = 18'd9636;
   
always @(negedge scan_code_ready)
    begin
        key_reg <= ascii_code;
        sample <= ~sample;
    end
assign interrupt = counter[25];
//assign interrupt = 1'b0;
always @ (posedge clock)
	begin
	    if( PCWrite == 2'b01 )
			PC <= Result;
		else if (PCWrite == 2'b10)
		  PC <= scheduler_loc;

		regRD1A   <= regRD1;
		regRD2A   <= regRD2;
		AluOut    <= AluResult;
	end
endmodulemodule keyboard

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
`timescale 1ns / 1ps
module Memory
(
    input clock,
    input isWrite,
    input byteWrite,
    input byteRead,
    input [17:0] address,
    input [31:0] writeData,
    output [31:0] data,
    input [31:0] displayAddr,
    output [31:0] displayData,
    input IRWrite,
    output [31:0] IR,
    input sample,
    input [7:0] key_reg
    );
    
    wire [15:0] displayAddress;
    wire [17:0] ramAddress;
    wire [17:0] romAddress;
    
    assign displayAddress = address;
    assign ramAddress = address - 18'd42368;
    assign romAddress = address - 18'd9600;
    
    wire displayIsWrite;
    wire [3:0] ramIsWrite;
    
    assign displayIsWrite = (address < 18'd9600 && isWrite == 1'b1 ) ? 1'b1 : 1'b0;
    assign ramIsWrite[0] = (address >= 18'd42368 && isWrite == 1'b1 && (byteWrite == 1'b0 || address [1:0] == 2'd3 )) ? 1'b1 : 1'b0;
    assign ramIsWrite[1] = (address >= 18'd42368 && isWrite == 1'b1 && (byteWrite == 1'b0 || address [1:0] == 2'd2 )) ? 1'b1 : 1'b0;
    assign ramIsWrite[2] = (address >= 18'd42368 && isWrite == 1'b1 && (byteWrite == 1'b0 || address [1:0] == 2'd1 )) ? 1'b1 : 1'b0;
    assign ramIsWrite[3] = (address >= 18'd42368 && isWrite == 1'b1 && (byteWrite == 1'b0 || address [1:0] == 2'd0 )) ? 1'b1 : 1'b0;
    
    wire [31:0] ramWriteData;
    assign ramWriteData =   (byteWrite == 1'b0 ) ? writeData :
                            (address[1:0] == 2'd0 ) ? (writeData << 24) :
                            (address[1:0] == 2'd1 ) ? (writeData << 16) :
                            (address[1:0] == 2'd2 ) ? (writeData << 8)  :
                            writeData;
    
    wire ramIsRead;
    assign ramIsRead = (address >= 18'd42368 ) ? 1'b1 : 1'b0;
    
    reg [1:0] addrLatch;
    reg [7:0] keyVal;
    reg dample;
    reg readKeyboard;
    
    initial
        begin
            addrLatch <= 2'd0;
            keyVal <= 8'd0;
            dample <= 1'b1;
            readKeyboard <= 1'b0;
        end
    
    always @(posedge clock)
        begin
            if( ramIsRead )
                addrLatch <= address[1:0];
        end
    
    always @(posedge ramIsRead)
        begin
            if( address == 18'd76000 )
                begin
                    readKeyboard <= 1'b1;
                    if( sample != dample )
                        begin
                            keyVal <= key_reg;
                            dample <= sample;
                        end
                    else
                        keyVal <= 8'd0;
                end
            else
                readKeyboard <= 1'b0;
        end
        
    
    wire [31:0] ramReadData;
    assign data =   (readKeyboard == 1'b1 ) ? keyVal :
                    (byteRead == 1'b1 && addrLatch == 2'd0) ? ramReadData[31:24] :
                    (byteRead == 1'b1 && addrLatch == 2'd1) ? ramReadData[23:16] :
                    (byteRead == 1'b1 && addrLatch == 2'd2) ? ramReadData[15:8] :
                    (byteRead == 1'b1 && addrLatch == 2'd3) ? ramReadData[7:0] :
                    ramReadData;
    
    Display_Memory disMem (
        .clock(clock),  //correct
        .address(displayAddress),   
        .displayAddr(displayAddr[15:0]),  //corrrect
        .byteWrite(byteWrite),      //correct
        .isWrite(displayIsWrite),              
        .writeData(writeData),      //correct
        .displayData(displayData)   //correct
    );
    
    RAM ram(
        .clock(clock),          //correct
        .isWrite(ramIsWrite),      
        .writeData(ramWriteData),  //correct
        .address(ramAddress),    
        .data(ramReadData),             //correct
        .isRead(ramIsRead),
        .byteRead(byteRead)
    );
    
    ROM rom(
        .address(romAddress[17:2]),     
        .clock(clock),          //correct
        .IRWrite(IRWrite),      //correct
        .IR(IR)                 //correct
    );
 
 endmodulemodule ps2_rx
	(
		input wire clk, reset, 
		input wire ps2d, ps2c, rx_en,    // ps2 data and clock inputs, receive enable input
		output reg rx_done_tick,         // ps2 receive done tick
		output reg [7:0] rx_data        // data received 
	);
	
	reg [3:0] b;
	initial
	   begin
	       b <= 4'h1;
	       rx_done_tick <= 1'b0;
	   end
	
	always @(negedge ps2c)
	   begin
	       case(b)
	           1:;
	           2:rx_data[0] <= ps2d;
	           3:rx_data[1] <= ps2d;
	           4:rx_data[2] <= ps2d;
	           5:rx_data[3] <= ps2d;
	           6:rx_data[4] <= ps2d;
	           7:rx_data[5] <= ps2d;
	           8:rx_data[6] <= ps2d;
	           9:rx_data[7] <= ps2d;
	           10:rx_done_tick <= 1'b1;
	           11: rx_done_tick <= 1'b0;
	       endcase
	       if( b <= 10 )
	           b <= b+1;
	       else if( b == 11 )
	           b <= 1;
	   end
//	// FSMD state declaration
//	localparam 
//		idle = 1'b0,
//		rx   = 1'b1;
		
//	// internal signal declaration
//	reg state_reg, state_next;          // FSMD state register
//	reg [7:0] filter_reg;               // shift register filter for ps2c
//	wire [7:0] filter_next;             // next state value of ps2c filter register
//	reg f_val_reg;                      // reg for ps2c filter value, either 1 or 0
//	wire f_val_next;                    // next state for ps2c filter value
//	reg [3:0] n_reg, n_next;            // register to keep track of bit number 
//	reg [10:0] d_reg, d_next;           // register to shift in rx data
//	wire neg_edge;                      // negative edge of ps2c clock filter value
	
//	// register for ps2c filter register and filter value
//	always @(posedge clk, posedge reset)
//		if (reset)
//			begin
//			filter_reg <= 0;
//			f_val_reg  <= 0;
//			end
//		else
//			begin
//			filter_reg <= filter_next;
//			f_val_reg  <= f_val_next;
//			end

//	// next state value of ps2c filter: right shift in current ps2c value to register
//	assign filter_next = {ps2c, filter_reg[7:1]};
	
//	// filter value next state, 1 if all bits are 1, 0 if all bits are 0, else no change
//	assign f_val_next = (filter_reg == 8'b11111111) ? 1'b1 :
//			    (filter_reg == 8'b00000000) ? 1'b0 :
//			    f_val_reg;
	
//	// negative edge of filter value: if current value is 1, and next state value is 0
//	assign neg_edge = f_val_reg & ~f_val_next;
	
//	// FSMD state, bit number, and data registers
//	always @(posedge clk, posedge reset)
//		if (reset)
//			begin
//			state_reg <= idle;
//			n_reg <= 0;
//			d_reg <= 0;
//			end
//		else
//			begin
//			state_reg <= state_next;
//			n_reg <= n_next;
//			d_reg <= d_next;
//			end
	
//	// FSMD next state logic
//	always @*
//		begin
		
//		// defaults
//		state_next = state_reg;
//		rx_done_tick = 1'b0;
//		n_next = n_reg;
//		d_next = d_reg;
		
//		case (state_reg)
			
//			idle:
//				if (neg_edge & rx_en)                 // start bit received
//					begin
//					n_next = 4'b1010;             // set bit count down to 10
//					state_next = rx;              // go to rx state
//					end
				
//			rx:                                           // shift in 8 data, 1 parity, and 1 stop bit
//				begin
//				if (neg_edge)                         // if ps2c negative edge...
//					begin
//					d_next = {ps2d, d_reg[10:1]}; // sample ps2d, right shift into data register
//					n_next = n_reg - 1;           // decrement bit count
//					end
			
//				if (n_reg==0)                         // after 10 bits shifted in, go to done state
//                                        begin
//					 rx_done_tick = 1'b1;         // assert dat received done tick
//					 state_next = idle;           // go back to idle
//					 end
//				end
//		endcase
//		end
		
//	assign rx_data = d_reg[8:1]; // output data bits 
endmodule

`timescale 1ns / 1ps
//(*DONT_TOUCH = "true"*)
module RegisterFile
(
//    (*DONT_TOUCH = "true"*)
	output [31:0] RD1,
//	(*DONT_TOUCH = "true"*)
	output [31:0] RD2,
//	(*DONT_TOUCH = "true"*)
	input clock,
//	(*DONT_TOUCH = "true"*)
	input isWrite,
//	(*DONT_TOUCH = "true"*)
	input [3:0] A1,
//	(*DONT_TOUCH = "true"*)
	input [3:0] A2,
//	(*DONT_TOUCH = "true"*)
	input [3:0] A3,
//	(*DONT_TOUCH = "true"*)
	input [31:0] writeData,
	output [3:0] led
	
//	output [3:0] led
);

//(*DONT_TOUCH = "true"*)
reg [31:0] registerFile [15:0];
//(*DONT_TOUCH = "true"*)
reg [4:0] i;

initial begin
	for( i = 0 ; i < 16 ; i = i+1 ) 
		registerFile[i] <= 32'd0;
    registerFile[4] <= 32'd2;
end

always @ (posedge clock) 
begin
	if( isWrite ) 
	begin
		registerFile[A3] <= writeData;
	end
		
end

assign led[0] = registerFile[4][0];
assign led[1] = registerFile[4][1];
assign led[2] = registerFile[4][2];
assign led[3] = registerFile[4][3];

assign RD1 = registerFile[A1];
assign RD2 = registerFile[A2];

endmodule
module key2ascii
	(
		input wire letter_case,
		input wire [7:0] scan_code,
		output reg [7:0] ascii_code
	);
	
always @*
	begin
	if(letter_case == 1'b1)  // uppercase 
		begin
		case(scan_code)
			8'h45: ascii_code = 8'h29;   // )
			8'h16: ascii_code = 8'h21;   // !
			8'h1e: ascii_code = 8'h40;   // @
			8'h26: ascii_code = 8'h23;   // #
			8'h25: ascii_code = 8'h24;   // $
			8'h2e: ascii_code = 8'h25;   // %
			8'h36: ascii_code = 8'h5E;   // ^
			8'h3d: ascii_code = 8'h26;   // &
			8'h3e: ascii_code = 8'h2A;   // *
			8'h46: ascii_code = 8'h28;   // (
			8'h1c: ascii_code = 8'h41;   // A
			8'h32: ascii_code = 8'h42;   // B
			8'h21: ascii_code = 8'h43;   // C
			8'h23: ascii_code = 8'h44;   // D
			8'h24: ascii_code = 8'h45;   // E
			8'h2b: ascii_code = 8'h46;   // F
			8'h34: ascii_code = 8'h47;   // G
			8'h33: ascii_code = 8'h48;   // H
			8'h43: ascii_code = 8'h49;   // I
			8'h3b: ascii_code = 8'h4A;   // J
			8'h42: ascii_code = 8'h4B;   // K
			8'h4b: ascii_code = 8'h4C;   // L
			8'h3a: ascii_code = 8'h4D;   // M
			8'h31: ascii_code = 8'h4E;   // N
			8'h44: ascii_code = 8'h4F;   // O
			8'h4d: ascii_code = 8'h50;   // P
			8'h15: ascii_code = 8'h51;   // Q
			8'h2d: ascii_code = 8'h52;   // R
			8'h1b: ascii_code = 8'h53;   // S
			8'h2c: ascii_code = 8'h54;   // T
			8'h3c: ascii_code = 8'h55;   // U
			8'h2a: ascii_code = 8'h56;   // V
			8'h1d: ascii_code = 8'h57;   // W
			8'h22: ascii_code = 8'h58;   // X
			8'h35: ascii_code = 8'h59;   // Y
			8'h1a: ascii_code = 8'h5A;   // Z
			8'h0e: ascii_code = 8'h7E;   // ~
			8'h4e: ascii_code = 8'h5F;   // _
			8'h55: ascii_code = 8'h2B;   // +
			8'h54: ascii_code = 8'h7B;   // {
			8'h5b: ascii_code = 8'h7D;   // }
			8'h5d: ascii_code = 8'h7C;   // |
			8'h4c: ascii_code = 8'h3A;   // :
			8'h52: ascii_code = 8'h22;   // "
			8'h41: ascii_code = 8'h3C;   // <
			8'h49: ascii_code = 8'h3E;   // >
			8'h4a: ascii_code = 8'h3F;   // ?
			8'h29: ascii_code = 8'h20;   // space
			8'h5a: ascii_code = 8'h0D;   // enter
			8'h66: ascii_code = 8'h08;   // backspace
			8'h0D: ascii_code = 8'h09;   // horizontal tab	
			
			default: ascii_code = 8'h2A; // *
		endcase
		end
	else   // lowercase
		begin
		case(scan_code)
			8'h45: ascii_code = 8'h30;   // 0
			8'h16: ascii_code = 8'h31;   // 1
			8'h1e: ascii_code = 8'h32;   // 2
			8'h26: ascii_code = 8'h33;   // 3
			8'h25: ascii_code = 8'h34;   // 4
			8'h2e: ascii_code = 8'h35;   // 5
			8'h36: ascii_code = 8'h36;   // 6
			8'h3d: ascii_code = 8'h37;   // 7
			8'h3e: ascii_code = 8'h38;   // 8
			8'h46: ascii_code = 8'h39;   // 9
			8'h1c: ascii_code = 8'h61;   // a
			8'h32: ascii_code = 8'h62;   // b
			8'h21: ascii_code = 8'h63;   // c
			8'h23: ascii_code = 8'h64;   // d
			8'h24: ascii_code = 8'h65;   // e
			8'h2b: ascii_code = 8'h66;   // f
			8'h34: ascii_code = 8'h67;   // g
			8'h33: ascii_code = 8'h68;   // h
			8'h43: ascii_code = 8'h69;   // i
			8'h3b: ascii_code = 8'h6A;   // j
			8'h42: ascii_code = 8'h6B;   // k
			8'h4b: ascii_code = 8'h6C;   // l
			8'h3a: ascii_code = 8'h6D;   // m
			8'h31: ascii_code = 8'h6E;   // n
			8'h44: ascii_code = 8'h6F;   // o
			8'h4d: ascii_code = 8'h70;   // p
			8'h15: ascii_code = 8'h71;   // q
			8'h2d: ascii_code = 8'h72;   // r
			8'h1b: ascii_code = 8'h73;   // s
			8'h2c: ascii_code = 8'h74;   // t
			8'h3c: ascii_code = 8'h75;   // u
			8'h2a: ascii_code = 8'h76;   // v
			8'h1d: ascii_code = 8'h77;   // w
			8'h22: ascii_code = 8'h78;   // x
			8'h35: ascii_code = 8'h79;   // y
			8'h1a: ascii_code = 8'h7A;   // z
			8'h0e: ascii_code = 8'h60;   // `
			8'h4e: ascii_code = 8'h2D;   // -
			8'h55: ascii_code = 8'h3D;   // =
			8'h54: ascii_code = 8'h5B;   // [
			8'h5b: ascii_code = 8'h5D;   // ]
			8'h5d: ascii_code = 8'h5C;   // \
			8'h4c: ascii_code = 8'h3B;   // ;
			8'h52: ascii_code = 8'h27;   // '
			8'h41: ascii_code = 8'h2C;   // ,
			8'h49: ascii_code = 8'h2E;   // .
			8'h4a: ascii_code = 8'h2F;   // /
			8'h29: ascii_code = 8'h20;   // space
			8'h5a: ascii_code = 8'h0D;   // enter
			8'h66: ascii_code = 8'h08;   // backspace
			8'h0D: ascii_code = 8'h09;   // horizontal tab	
			
			default: ascii_code = 8'h2A; // *
		endcase
		end
	end
endmodulemodule top
	(	
		input [7:0] je,
		input sysclk,
		output [3:0] led,
		output [7:0] ascii_code,
		output scan_code_ready
	);
		
	// signal declaration
	wire [7:0] scan_code;
	wire letter_case;
	
	wire reset;
	assign reset = 1'b0;
	
	wire [3:0] code;
	
	// instantiate keyboard scan code circuit
	keyboard kb_unit (.clk(sysclk), .reset(reset), .ps2d(je[0]), .ps2c(je[1]), .ascii(ascii_code),
			 .scan_code(scan_code), .scan_code_ready(scan_code_ready), .letter_case_out(letter_case), .code(code));
			
	// instantiate key-to-ascii code conversion circuit
	key2ascii k2a_unit (.letter_case(letter_case), .scan_code(scan_code), .ascii_code(ascii_code));
	
	assign led = code;
endmodule


