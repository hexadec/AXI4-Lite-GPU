module color_converter #(
    parameter SWITCH_RGB_TO_RBG = 1
) (
    input [23 : 0] in_color,
    output [23:0] out_color
);

    generate
        if (SWITCH_RGB_TO_RBG == 0) begin
            assign out_color = {in_color[23:16], 5'b0, in_color[15:8], 5'b0, in_color[7:0], 6'b0};
        end else begin
            assign out_color = {in_color[23:16], 5'b0, in_color[7:0], 6'b0, in_color[15:8], 5'b0};
        end
    endgenerate
endmodule
