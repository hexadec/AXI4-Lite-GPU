module axi4_lite_gpu_execute_line #(
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
    input color_valid,
    input [COLOR_WIDTH - 1 : 0] color,

    output fbuf_en_wr,
    output fbuf_wrea,
    output [FBUF_ADDR_WIDTH - 1 : 0] fbuf_addr,
    output [FBUF_DATA_WIDTH - 1 : 0] fbuf_data
);

enum logic [2:0] {IDLE, BUSY_PREPARE, BUSY, BUSY_LASTWRITE, DONE, ERR} state, next_state;

reg xy0_valid_int;
reg xy1_valid_int;
reg color_valid_int;

reg signed [12:0] x0_int, y0_int, x1_int, y1_int;
reg [COLOR_WIDTH - 1 : 0] color_int;

reg signed [12:0] pos_x, pos_y, dx, dy;
reg signed [17:0] error, error_dx, error_dy;
reg signed [1:0] sx, sy;

reg [FBUF_ADDR_WIDTH - 1 : 0] fbuf_addr_int;

assign busy = state == BUSY_PREPARE || state == BUSY || state == BUSY_LASTWRITE;
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
            (xy1_valid && (x1 >= FRAME_WIDTH_SCALED || y1 >= FRAME_HEIGHT_SCALED))) begin
            next_state = ERR;
        end else if (start && xy0_valid_int && xy1_valid_int && color_valid_int) begin
            next_state = BUSY_PREPARE;
        end else if (start) begin
            next_state = ERR;
        end else begin
            next_state = IDLE;
        end
    end else if (state == BUSY || state == BUSY_PREPARE) begin
        if (pos_x == x1_int && pos_y == y1_int) begin
            next_state = BUSY_LASTWRITE;
        end else begin
            next_state = BUSY;
        end
    end else if (state == BUSY_LASTWRITE) begin
        next_state = DONE;
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
        color_valid_int <= 0;
        x0_int <= 0;
        y0_int <= 0;
        x1_int <= 0;
        y1_int <= 0;
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
            if (color_valid) begin
                color_valid_int <= 1;
                color_int <= color;
            end
        end else if (state == DONE || state == ERR) begin
            xy0_valid_int <= 0;
            xy1_valid_int <= 0;
            color_valid_int <= 0;
            x0_int <= 0;
            y0_int <= 0;
            x1_int <= 0;
            y1_int <= 0;
            color_int <= 0;
        end
    end
end


always_ff @(posedge clk) begin
    if (!rst_n) begin
        pos_x <= 0;
        pos_y <= 0;
        dx <= 0;
        dy <= 0;
        sx <= 0;
        sy <= 0;
        error <= 0;
        error_dx <= 0;
        error_dy <= 0;
        fbuf_addr_int <= 0;
    end else begin
        if (state == IDLE) begin
            if (start && xy0_valid_int && xy1_valid_int && color_valid_int) begin
                pos_x <= x0_int;
                pos_y <= y0_int;

                sx <= (x0_int < x1_int) ? 2'sd1 : -2'sd1;
                sy <= (y0_int < y1_int) ? 2'sd1 : -2'sd1;

                dx <= x0_int > x1_int ? (x0_int - x1_int) : (x1_int - x0_int);
                dy <= y0_int < y1_int ? (y0_int - y1_int) : (y1_int - y0_int);
            end
        end else if (state == BUSY_PREPARE) begin
            error <= (dx + dy) * 2;
            error_dx <= (dx + dy) * 2 + dx;
            error_dy <= (dx + dy) * 2 + dy;
            fbuf_addr_int <= (pos_y) * FBUF_ADDR_WIDTH'(FRAME_WIDTH_SCALED) + pos_x;
        end else if (state == BUSY) begin
            if (error >= dy) begin
                if (error_dy <= dx) begin
                    error <= error_dx + dy;
                    error_dx <= error_dy + 2 * dx;
                    error_dy <= error_dy + dx + dy;
                    pos_y <= pos_y + sy;
                end else begin
                    error <= error_dy;
                    error_dx <= error_dx + dy;
                    error_dy <= error_dy + dy;
                end
                pos_x <= pos_x + sx;
            end else if (error <= dx) begin
                error <= error_dx;
                error_dx <= error_dx + dx;
                error_dy <= error_dy + dx;
                pos_y <= pos_y + sy;
            end
            fbuf_addr_int <= (pos_y) * FBUF_ADDR_WIDTH'(FRAME_WIDTH_SCALED) + pos_x;
        end else begin
            pos_x <= 0;
            pos_y <= 0;
            dx <= 0;
            dy <= 0;
            sx <= 0;
            sy <= 0;
            error <= 0;
            error_dx <= 0;
            error_dy <= 0;
            fbuf_addr_int <= 0;
        end
    end
end


assign fbuf_en_wr = state == BUSY || state == BUSY_LASTWRITE;
assign fbuf_wrea = state == BUSY || state == BUSY_LASTWRITE;
assign fbuf_addr = state == BUSY || state == BUSY_LASTWRITE ? fbuf_addr_int : 0;
assign fbuf_data = state == BUSY || state == BUSY_LASTWRITE ? color_int : 0;

endmodule
