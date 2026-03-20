module framebuffer #(
    parameter FRAME_WIDTH = 640,
    parameter FRAME_HEIGHT = 480,
    parameter SCALING_FACTOR = 1,
    parameter ADDR_WIDTH = 19,
    parameter DATA_WIDTH = 8
    ) (
    input clk_wr, clk_rd, en_wr, en_rd, wrea,
    input [ADDR_WIDTH - 1:0] addr_rd, addr_wr,
    input [DATA_WIDTH - 1:0] din, 
    output reg [DATA_WIDTH - 1:0] dout
    );

    localparam NUMBER_OF_PIXELS = FRAME_WIDTH / SCALING_FACTOR * FRAME_HEIGHT / SCALING_FACTOR;

    generate
        if (2 ** ADDR_WIDTH < NUMBER_OF_PIXELS) begin
            $error("Not all pixels are addressable");
        end else if (2 ** (ADDR_WIDTH - 1) > NUMBER_OF_PIXELS) begin
            $error("Pixel address with larger than necessary");
        end
    endgenerate

    reg [DATA_WIDTH - 1:0] ram [NUMBER_OF_PIXELS - 1:0];
    
    always @(posedge clk_wr) begin
        if (en_wr) begin
            if (wrea)
                ram[addr_wr] <= din;
        end
    end

    always @(posedge clk_rd) begin
        if (en_rd)  begin
            dout <= ram[addr_rd];
        end
    end

endmodule
