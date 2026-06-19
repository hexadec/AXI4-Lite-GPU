module color_converter #(
    parameter SWITCH_RGB_TO_RBG = 1
) (
    input [7:0] in_color,
    output [23:0] out_color
);

    generate
        if (SWITCH_RGB_TO_RBG == 0) begin
            assign out_color = {in_color[7:5], 5'b0, in_color[4:2], 5'b0, in_color[1:0], 6'b0};
        end else begin
            assign out_color = {in_color[7:5], 5'b0, in_color[1:0], 6'b0, in_color[4:2], 5'b0};
        end
    endgenerate
endmodule
