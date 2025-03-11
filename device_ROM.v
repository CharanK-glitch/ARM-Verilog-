module ROM (
    input [15:0] address,
    input clock,
    input IRWrite,
    output reg [31:0] IR
    );
    
    (* ram_style="block" *)
    reg [31:0] ROM[16383:0];

    initial
        begin
            $readmemb("os.mem", ROM, 0, 16383);
            IR <= 32'd15;
        end
    
    always @(posedge clock)
        begin
            if( IRWrite )
                IR <= ROM[address];
        end
        
endmodule

						
						
