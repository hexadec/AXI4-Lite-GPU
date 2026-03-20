module block(
    input clk,
    input [3:0] in_btn,
    output reg [3:0] out_led
    );
    
    always @(posedge clk)
    begin
        out_led <= in_btn;
    end
    
endmodule
