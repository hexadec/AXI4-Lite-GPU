module axi4_lite_gpu_execute_tri #(
    parameter FRAME_WIDTH_SCALED = 640,
    parameter FRAME_HEIGHT_SCALED = 480,
    parameter COLOR_WIDTH = 8,
    parameter FBUF_ADDR_WIDTH = 19,
    parameter FBUF_DATA_WIDTH = 8
) (
    input clk,
    input rst_n,
    input start,
    output busy,
    output done,
    output err,

    input xy0_valid,
    input [11:0] x0,
    input [11:0] y0,
    input xy1_valid,
    input [11:0] x1,
    input [11:0] y1,
    input xy2_valid,
    input [11:0] x2,
    input [11:0] y2,
    input color_valid,
    input [COLOR_WIDTH - 1 : 0] color,

    output fbuf_en_wr,
    output fbuf_wrea,
    output [FBUF_ADDR_WIDTH - 1 : 0] fbuf_addr,
    output [FBUF_DATA_WIDTH - 1 : 0] fbuf_data
);

enum logic [3:0] {IDLE, BUSY_PREPARE, BUSY_EVAL, BUSY_CALC_WR_INCR, BUSY_CALC_INCR, DONE, ERR} state, next_state;

reg xy0_valid_int;
reg xy1_valid_int;
reg xy2_valid_int;
reg color_valid_int;

reg signed [12:0] x0_int, y0_int;
reg signed [12:0] x1_int, y1_int;
reg signed [12:0] x2_int, y2_int;
reg [COLOR_WIDTH - 1:0] color_int;

reg [11:0] pos_x, pos_y;
reg [11:0] max_x, max_y;
reg [11:0] min_x, min_y;

reg signed [23:0] a, b, c;
reg signed [23:0] xy21;
reg signed [23:0] xy02;
reg signed [23:0] xy10;
reg [2:0] signs;

reg [FBUF_ADDR_WIDTH - 1 : 0] fbuf_addr_int;

assign busy = state == BUSY_PREPARE || state == BUSY_EVAL || state == BUSY_CALC_WR_INCR || state == BUSY_CALC_INCR;
assign done = state == DONE;
assign err = state == ERR;


always_ff @(posedge clk) begin
    if (!rst_n) begin
        state <= IDLE;
    end else begin
        state <= next_state;
    end
end


always_comb begin
    if (!rst_n) begin
        next_state = IDLE;
    end else if (state == IDLE) begin
        if ((xy0_valid && (x0 >= FRAME_WIDTH_SCALED || y0 >= FRAME_HEIGHT_SCALED)) ||
            (xy1_valid && (x1 >= FRAME_WIDTH_SCALED || y1 >= FRAME_HEIGHT_SCALED)) ||
            (xy2_valid && (x2 >= FRAME_WIDTH_SCALED || y2 >= FRAME_HEIGHT_SCALED))) begin
            next_state = ERR;
        end else if (start && xy0_valid_int && xy1_valid_int && xy2_valid_int && color_valid_int) begin
            next_state = BUSY_PREPARE;
        end else if (start) begin
            next_state = ERR;
        end else begin
            next_state = IDLE;
        end
    end else if (state == BUSY_PREPARE) begin
        next_state = BUSY_EVAL;
    end else if (state == BUSY_EVAL) begin
        if ((a[23] == signs[0] || a == 0) && (b[23] == signs[1] || b == 0) && (c[23] == signs[2] || c == 0)) begin
            next_state = BUSY_CALC_WR_INCR;
        end else begin
            next_state = BUSY_CALC_INCR;
        end
    end else if (state == BUSY_CALC_WR_INCR || state == BUSY_CALC_INCR) begin
        if (pos_x == max_x && pos_y == max_y) begin
            next_state = DONE;
        end else begin
            next_state = BUSY_EVAL;
        end
    end else if (state == DONE) begin
        next_state = IDLE;
    end else if (state == ERR) begin
        next_state = IDLE;
    end else begin
        next_state = ERR;
    end
end


always_ff @(posedge clk) begin
    if (!rst_n) begin
        xy0_valid_int <= 0;
        xy1_valid_int <= 0;
        xy2_valid_int <= 0;
        color_valid_int <= 0;
        x0_int <= 0;
        y0_int <= 0;
        x1_int <= 0;
        y1_int <= 0;
        x2_int <= 0;
        y2_int <= 0;
        color_int <= 0;
    end else begin
        if (state == IDLE) begin
            if (xy0_valid) begin
                xy0_valid_int <= 1;
                x0_int <= x0;
                y0_int <= y0;
            end
            if (xy1_valid) begin
                xy1_valid_int <= 1;
                x1_int <= x1;
                y1_int <= y1;
            end
            if (xy2_valid) begin
                xy2_valid_int <= 1;
                x2_int <= x2;
                y2_int <= y2;
            end
            if (color_valid) begin
                color_valid_int <= 1;
                color_int <= color;
            end
        end else if (state == DONE || state == ERR) begin
            xy0_valid_int <= 0;
            xy1_valid_int <= 0;
            xy2_valid_int <= 0;
            color_valid_int <= 0;
            x0_int <= 0;
            y0_int <= 0;
            x1_int <= 0;
            y1_int <= 0;
            x2_int <= 0;
            y2_int <= 0;
            color_int <= 0;
        end
    end
end


function [11:0] min;
    input [11:0] a, b, c;
    begin
        min = a < b ? (a < c ? a : c) : (b < c ? b : c);
    end
endfunction


function [11:0] max;
    input [11:0] a, b, c;
    begin
        max = a > b ? (a > c ? a : c) : (b > c ? b : c);
    end
endfunction


always_ff @(posedge clk) begin
    if (!rst_n) begin
        min_x <= 0;
        min_y <= 0;
        max_x <= 0;
        max_y <= 0;
        pos_x <= 0;
        pos_y <= 0;
        a <= 0;
        b <= 0;
        c <= 0;
        signs <= 0;
        xy21 <= 0;
        xy02 <= 0;
        xy10 <= 0;
        fbuf_addr_int <= 0;
    end else begin
        if (state == IDLE) begin
            if (start && xy0_valid_int && xy1_valid_int && xy2_valid_int) begin
                min_x <= min(x0_int, x1_int, x2_int);
                min_y <= min(y0_int, y1_int, y2_int);
                max_x <= max(x0_int, x1_int, x2_int);
                max_y <= max(y0_int, y1_int, y2_int);

                pos_x <= min(x0_int, x1_int, x2_int); // == min_x
                pos_y <= min(y0_int, y1_int, y2_int); // == min_y

                xy21 <= x2_int * y1_int - y2_int * x1_int;
                xy02 <= x0_int * y2_int - y0_int * x2_int;
                xy10 <= x1_int * y0_int - y1_int * x0_int;
            end
        end else if (state == BUSY_PREPARE || state == BUSY_CALC_WR_INCR || state == BUSY_CALC_INCR) begin
            if (state == BUSY_PREPARE) begin
                signs[0] <= ((y2_int - y1_int) * x0_int - (x2_int - x1_int) * y0_int + xy21) < 8'sd0;
                signs[1] <= ((y0_int - y2_int) * x1_int - (x0_int - x2_int) * y1_int + xy02) < 8'sd0;
                signs[2] <= ((y1_int - y0_int) * x2_int - (x1_int - x0_int) * y2_int + xy10) < 8'sd0;
            end
            
            a <= (y2_int - y1_int) * signed'(pos_x) - (x2_int - x1_int) * signed'(pos_y) + xy21;
            b <= (y0_int - y2_int) * signed'(pos_x) - (x0_int - x2_int) * signed'(pos_y) + xy02;
            c <= (y1_int - y0_int) * signed'(pos_x) - (x1_int - x0_int) * signed'(pos_y) + xy10;
        end else if (state == BUSY_EVAL) begin
            if (pos_x < max_x) begin
                pos_x <= pos_x + 1;
            end else begin
                if (pos_y < max_y) begin
                    pos_x <= min_x;
                    pos_y <= pos_y + 1;
                end
            end
            fbuf_addr_int <= pos_y * FBUF_ADDR_WIDTH'(FRAME_WIDTH_SCALED) + pos_x;
        end else if (state == DONE || state == ERR) begin
            min_x <= 0;
            min_y <= 0;
            max_x <= 0;
            max_y <= 0;
            pos_x <= 0;
            pos_y <= 0;
            a <= 0;
            b <= 0;
            c <= 0;
            signs <= 0;
            xy21 <= 0;
            xy02 <= 0;
            xy10 <= 0;
            fbuf_addr_int <= 0;
        end
    end
end


assign fbuf_en_wr = state == BUSY_CALC_WR_INCR;
assign fbuf_wrea = state == BUSY_CALC_WR_INCR;
assign fbuf_addr = state == BUSY_CALC_WR_INCR ? fbuf_addr_int : 0;
assign fbuf_data = state == BUSY_CALC_WR_INCR ? color_int : 0;

endmodule
