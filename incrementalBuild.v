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
endmodule