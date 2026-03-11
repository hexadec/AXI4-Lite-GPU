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

enum logic [3:0] {IDLE, BUSY_PREPARE_1, BUSY_PREPARE_2, BUSY_PREPARE_3, BUSY_EVAL, BUSY_CALC_WR_INCR, BUSY_CALC_INCR, DONE, ERR} state, next_state;

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
reg signed [23:0] xy21, xy21_tmp, y2my1_x0, x2mx1_y0, y2my1_posx, x2mx1_posy;
reg signed [23:0] xy02, xy02_tmp, y0my2_x1, x0mx2_y1, y0my2_posx, x0mx2_posy;
reg signed [23:0] xy10, xy10_tmp, y1my0_x2, x1mx0_y2, y1my0_posx, x1mx0_posy;

reg signed [12:0] y2my1, x2mx1, y0my2, x0mx2, y1my0, x1mx0;

reg [2:0] signs;

reg [FBUF_ADDR_WIDTH - 1 : 0] fbuf_addr_int;

assign busy = state == BUSY_PREPARE_1 || state == BUSY_PREPARE_2  || state == BUSY_PREPARE_3 || state == BUSY_EVAL || state == BUSY_CALC_WR_INCR || state == BUSY_CALC_INCR;
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
            next_state = BUSY_PREPARE_1;
        end else if (start) begin
            next_state = ERR;
        end else begin
            next_state = IDLE;
        end
    end else if (state == BUSY_PREPARE_1) begin
        next_state = BUSY_PREPARE_2;
    end else if (state == BUSY_PREPARE_2) begin
        next_state = BUSY_PREPARE_3;
    end else if (state == BUSY_PREPARE_3) begin
        next_state = BUSY_EVAL;
    end else if (state == BUSY_EVAL) begin
        if ((a[23] == signs[0] || a == 0) && (b[23] == signs[1] || b == 0) && (c[23] == signs[2] || c == 0)) begin
            next_state = BUSY_CALC_WR_INCR;
        end else begin
            next_state = BUSY_CALC_INCR;
        end
    end else if (state == BUSY_CALC_WR_INCR || state == BUSY_CALC_INCR) begin
        if (pos_y > max_y) begin
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

        xy21_tmp <= 0;
        xy02_tmp <= 0;
        xy10_tmp <= 0;

        y2my1 <= 0;
        x2mx1 <= 0;
        y0my2 <= 0;
        x0mx2 <= 0;
        y1my0 <= 0;
        x1mx0 <= 0;

        y2my1_x0 <= 0;
        x2mx1_y0 <= 0;
        y0my2_x1 <= 0;
        x0mx2_y1 <= 0;
        y1my0_x2 <= 0;
        x1mx0_y2 <= 0;

        y2my1_posx <= 0;
        x2mx1_posy <= 0;
        y0my2_posx <= 0;
        x0mx2_posy <= 0;
        y1my0_posx <= 0;
        x1mx0_posy <= 0;

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

                xy21 <= x2_int * y1_int;
                xy02 <= x0_int * y2_int;
                xy10 <= x1_int * y0_int;

                xy21_tmp <= y2_int * x1_int;
                xy02_tmp <= y0_int * x2_int;
                xy10_tmp <= y1_int * x0_int;

                y2my1 <= y2_int - y1_int;
                x2mx1 <= x2_int - x1_int;
                y0my2 <= y0_int - y2_int;
                x0mx2 <= x0_int - x2_int;
                y1my0 <= y1_int - y0_int;
                x1mx0 <= x1_int - x0_int;
            end
        end else if (state == BUSY_PREPARE_1) begin
            xy21 <= xy21 - xy21_tmp;
            xy02 <= xy02 - xy02_tmp;
            xy10 <= xy10 - xy10_tmp;

            y2my1_x0 <= y2my1 * x0_int;
            x2mx1_y0 <= x2mx1 * y0_int;
            y0my2_x1 <= y0my2 * x1_int;
            x0mx2_y1 <= x0mx2 * y1_int;
            y1my0_x2 <= y1my0 * x2_int;
            x1mx0_y2 <= x1mx0 * y2_int;

            y2my1_posx <= y2my1 * signed'(pos_x);
            x2mx1_posy <= x2mx1 * signed'(pos_y);
            y0my2_posx <= y0my2 * signed'(pos_x);
            x0mx2_posy <= x0mx2 * signed'(pos_y);
            y1my0_posx <= y1my0 * signed'(pos_x);
            x1mx0_posy <= x1mx0 * signed'(pos_y);
        end else if (state == BUSY_PREPARE_2) begin
            y2my1_x0 <= y2my1_x0 - x2mx1_y0 + xy21;
            y0my2_x1 <= y0my2_x1 - x0mx2_y1 + xy02;
            y1my0_x2 <= y1my0_x2 - x1mx0_y2 + xy10;
        end else if (state == BUSY_PREPARE_3 || state == BUSY_CALC_WR_INCR || state == BUSY_CALC_INCR) begin
            if (state == BUSY_PREPARE_3) begin
                signs[0] <= y2my1_x0 < 8'sd0;
                signs[1] <= y0my2_x1 < 8'sd0;
                signs[2] <= y1my0_x2 < 8'sd0;
            end
            
            a <= y2my1_posx - x2mx1_posy + xy21;
            b <= y0my2_posx - x0mx2_posy + xy02;
            c <= y1my0_posx - x1mx0_posy + xy10;

            if (pos_x < max_x) begin
                pos_x <= pos_x + 1;
            end else begin
                pos_x <= min_x;
                pos_y <= pos_y + 1;
            end
            fbuf_addr_int <= pos_y * FBUF_ADDR_WIDTH'(FRAME_WIDTH_SCALED) + pos_x;
        end else if (state == BUSY_EVAL) begin
            y2my1_posx <= y2my1 * signed'(pos_x);
            x2mx1_posy <= x2mx1 * signed'(pos_y);
            y0my2_posx <= y0my2 * signed'(pos_x);
            x0mx2_posy <= x0mx2 * signed'(pos_y);
            y1my0_posx <= y1my0 * signed'(pos_x);
            x1mx0_posy <= x1mx0 * signed'(pos_y);
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

            xy21_tmp <= 0;
            xy02_tmp <= 0;
            xy10_tmp <= 0;

            y2my1 <= 0;
            x2mx1 <= 0;
            y0my2 <= 0;
            x0mx2 <= 0;
            y1my0 <= 0;
            x1mx0 <= 0;

            y2my1_x0 <= 0;
            x2mx1_y0 <= 0;
            y0my2_x1 <= 0;
            x0mx2_y1 <= 0;
            y1my0_x2 <= 0;
            x1mx0_y2 <= 0;

            y2my1_posx <= 0;
            x2mx1_posy <= 0;
            y0my2_posx <= 0;
            x0mx2_posy <= 0;
            y1my0_posx <= 0;
            x1mx0_posy <= 0;

            fbuf_addr_int <= 0;
        end
    end
end


assign fbuf_en_wr = state == BUSY_CALC_WR_INCR;
assign fbuf_wrea = state == BUSY_CALC_WR_INCR;
assign fbuf_addr = state == BUSY_CALC_WR_INCR ? fbuf_addr_int : 0;
assign fbuf_data = state == BUSY_CALC_WR_INCR ? color_int : 0;

endmodule
