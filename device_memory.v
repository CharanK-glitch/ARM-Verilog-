
module RAM(
    input clock,
    input [3:0] isWrite,
    input [31:0] writeData,
    input [17:0] address,
    output reg [31:0] data,
    input isRead,
    input byteRead
    );
    
    (*ram_decomp = "power"*)
    (* ram_style="block" *)
    reg [31:0] RAM[16383:0];
    
    initial
        begin
            $readmemb("ram.mem", RAM, 0, 16383);
            data <= 32'd100;
        end
    
    wire [15:0] addr;
    assign addr = 16'd0 | address[17:2];
    
    wire [1:0] selection;
    assign selection = address[1:0];
    
    always @(posedge clock)
        begin
//            if( isRead && byteRead == 1'b1 && selection == 2'b00 )
//                data <= RAM[addr][31:24];
//            else if( isRead && byteRead == 1'b1 && selection == 2'b01 )
//                data <= RAM[addr][23:16];
//            else if( isRead && byteRead == 1'b1 && selection == 2'b10 )
//                data <= RAM[addr][15:8];
//            else if( isRead && byteRead == 1'b1 && selection == 2'b11 )
//                data <= RAM[addr][7:0];
//            else if( isRead && byteRead == 1'b0 )
//                data <= RAM[addr];
            if( isRead )
                data <= RAM[addr];
        end
        

    generate
        genvar i;
        for( i = 0 ; i < 4 ; i = i+1 ) begin: byte_write
            always @(posedge clock)
                if( isWrite[i] )
                    RAM[addr][(i+1)*8 - 1:i*8] <= writeData[(i+1)*8 -1 : i*8];
                end
    endgenerate

endmodule				
						
					
//module RAM (
//  input [15:0] address,
//  input [31:0] writeData,
//  input clock,
//  input [3:0] isWrite,
//  output reg [31:0] data
//);
//    (* ram_style = "block" *)
//    reg [(NB_COL*COL_WIDTH)-1:0] BRAM [RAM_DEPTH-1:0];
    
//    always @(posedge clock)
//        begin
//                IR <= BRAM[address];
//                data <= BRAM[address];
//        end
    
//    generate
//        genvar i;
//        for (i = 0; i < NB_COL; i = i+1) begin: byte_write
//            always @(posedge clock)
//                if (isWrite[i])
//                    BRAM[address][(i+1)*COL_WIDTH-1:i*COL_WIDTH] <= writeData[(i+1)*COL_WIDTH-1:i*COL_WIDTH];
//            end
//    endgenerate
//RAM							
							
