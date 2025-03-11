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
 
 endmodule