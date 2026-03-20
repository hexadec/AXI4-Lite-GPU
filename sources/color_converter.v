module color_converter #(
    parameter SWITCH_RGB_TO_RBG = 1,
    parameter FBUF_DATA_WIDTH = 8
) (
    input clk,
    input [FBUF_DATA_WIDTH - 1 : 0] in_color,
    output reg [23:0] out_color
);
    generate
        if (FBUF_DATA_WIDTH != 8) begin
            invalid_fbuf_data_width();
        end
    endgenerate

    generate
        always @(posedge clk) begin
            if (SWITCH_RGB_TO_RBG == 0) begin
                out_color <= {in_color[7:5], 5'b0, in_color[4:2], 5'b0, in_color[1:0], 6'b0};
            end else begin
                out_color <= {in_color[7:5], 5'b0, in_color[1:0], 6'b0, in_color[4:2], 5'b0};
            end
        end
    endgenerate
endmodule
