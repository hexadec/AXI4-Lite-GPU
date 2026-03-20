`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09.06.2025 11:56:34
// Design Name: 
// Module Name: btn_debounce
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module btn_debounce(
    input clk,
    input rst_n,
    input btn_in,
    output btn_out
    );
    
    reg [3:0] state;
    reg out_reg;
    
    always @(posedge clk) begin
        if (!rst_n) begin
            state <= 0;
            out_reg <= 0;
        end
        if (btn_in) begin
            if (state != 4'b1111) begin
                state <= state + 1;
            end else begin
                out_reg <= 1;
            end
        end else begin
            if (state != 0) begin
                state <= state - 1;
            end else begin
                out_reg <= 0;
            end
        end
    end
    
    assign btn_out = out_reg;
    
endmodule
