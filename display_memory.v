module Display_Memory(
    input clock,
    input [15:0] address,
    input [15:0] displayAddr,
    input byteWrite,
    input isWrite,
    input [31:0] writeData,
    output [31:0] displayData
    );
    
    (* ram_style = "block" *)
    reg [31:0] memory [2399:0];
    
    initial
        $readmemb("display.mem", memory, 0, 2399);
    
    wire [15:0] addr;
    assign addr = 16'd0 | address[15:2];
    
    always @ (posedge clock) 
	begin
		if(isWrite) 
			begin
			    if( byteWrite == 1'b0 )
			         memory[addr] <= writeData;
			    else
			         begin
			             if( address[1:0] == 2'b00 )
			                 memory[addr][31:24] <= writeData[7:0];
			             else if( address[1:0] == 2'b01 )
			                 memory[addr][23:16] <= writeData[7:0];
			             else if( address[1:0] == 2'b10 )
			                 memory[addr][15:8] <= writeData[7:0];
			             else 
			                 memory[addr][7:0] <= writeData[7:0];
			         end
			end
	end

assign displayData = (displayAddr < 16'd2400 ) ? memory[displayAddr] : 32'd0;

endmodule
