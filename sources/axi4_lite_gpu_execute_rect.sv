module axi4_lite_gpu_execute_rect #(
    parameter FRAME_WIDTH_SCALED = 640,
    parameter FRAME_HEIGHT_SCALED = 480,
    parameter COLOR_WIDTH = 24,
    parameter FBUF_ADDR_WIDTH = 19,
    parameter FBUF_DATA_WIDTH = 24
) (
    input clk,
    input rst_n,
    input start,
    output busy,
    output done,
    output err,

    input left_valid,
    input [11:0] left_x,
    input [11:0] left_y,
    input right_valid,
    input [11:0] right_x,
    input [11:0] right_y,
    input color_valid,
    input [COLOR_WIDTH - 1 : 0] color,

    output fbuf_en_wr,
    output fbuf_wrea,
    output [FBUF_ADDR_WIDTH - 1 : 0] fbuf_addr,
    output [FBUF_DATA_WIDTH - 1 : 0] fbuf_data
);

enum logic [2:0] {IDLE, BUSY_PREPARE, BUSY, BUSY_LASTWRITE, DONE, ERR} state, next_state;

reg left_valid_int;
reg right_valid_int;
reg color_valid_int;

reg [11:0] left_x_int;
reg [11:0] left_y_int;
reg [11:0] right_x_int;
reg [11:0] right_y_int;
reg [COLOR_WIDTH - 1 : 0] color_int;

reg [11:0] pos_x, pos_y;
reg [11:0] max_x, max_y;
reg [11:0] min_x, min_y;

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
        if ((left_valid && (left_x >= FRAME_WIDTH_SCALED || left_y >= FRAME_HEIGHT_SCALED)) ||
            (right_valid && (right_x >= FRAME_WIDTH_SCALED || right_y >= FRAME_HEIGHT_SCALED))) begin
            next_state = ERR;
        end else if (start && left_valid_int && right_valid_int && color_valid_int) begin
            next_state = BUSY_PREPARE;
        end else if (start) begin
            next_state = ERR;
        end else begin
            next_state = IDLE;
        end
    end else if (state == BUSY_LASTWRITE) begin
        next_state = DONE;
    end else if (state == BUSY || state == BUSY_PREPARE) begin
        if (pos_x == max_x && pos_y == max_y) begin
            next_state = BUSY_LASTWRITE;
        end else begin
            next_state = BUSY;
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
        left_valid_int <= 0;
        right_valid_int <= 0;
        color_valid_int <= 0;
        left_x_int <= 0;
        left_y_int <= 0;
        right_x_int <= 0;
        right_y_int <= 0;
        color_int <= 0;
    end else begin
        if (state == IDLE) begin
            if (left_valid) begin
                left_valid_int <= 1;
                left_x_int <= left_x;
                left_y_int <= left_y;
            end
            if (right_valid) begin
                right_valid_int <= 1;
                right_x_int <= right_x;
                right_y_int <= right_y;
            end
            if (color_valid) begin
                color_valid_int <= 1;
                color_int <= color;
            end
        end else if (state == DONE || state == ERR) begin
            left_valid_int <= 0;
            right_valid_int <= 0;
            color_valid_int <= 0;
            left_x_int <= 0;
            left_y_int <= 0;
            right_x_int <= 0;
            right_y_int <= 0;
            color_int <= 0;
        end
    end
end


always_ff @(posedge clk) begin
    if (!rst_n) begin
        min_x <= 0;
        min_y <= 0;
        max_x <= 0;
        max_y <= 0;
        pos_x <= 0;
        pos_y <= 0;
        fbuf_addr_int <= 0;
    end else begin
        if (state == IDLE) begin
            if (start && left_valid_int && right_valid_int && color_valid_int) begin
                min_x <= left_x_int < right_x_int ? left_x_int : right_x_int;
                min_y <= left_y_int < right_y_int ? left_y_int : right_y_int;
                max_x <= left_x_int > right_x_int ? left_x_int : right_x_int;
                max_y <= left_y_int > right_y_int ? left_y_int : right_y_int;

                pos_x <= left_x_int < right_x_int ? left_x_int : right_x_int; // == min_x
                pos_y <= left_y_int < right_y_int ? left_y_int : right_y_int; // == min_y
            end
        end else if (state == BUSY || state == BUSY_PREPARE) begin
            if (pos_x < max_x) begin
                pos_x <= pos_x + 1;
            end else begin
                pos_x <= min_x;
                if (pos_y < max_y) begin
                    pos_y <= pos_y + 1;
                end
            end
            fbuf_addr_int <= (pos_y) * FBUF_ADDR_WIDTH'(FRAME_WIDTH_SCALED) + pos_x;
        end else begin
            min_x <= 0;
            min_y <= 0;
            max_x <= 0;
            max_y <= 0;
            pos_x <= 0;
            pos_y <= 0;
            fbuf_addr_int <= 0;
        end
    end
end


assign fbuf_en_wr = state == BUSY || state == BUSY_LASTWRITE;
assign fbuf_wrea = state == BUSY || state == BUSY_LASTWRITE;
assign fbuf_addr = state == BUSY || state == BUSY_LASTWRITE ? fbuf_addr_int : 0;
assign fbuf_data = state == BUSY || state == BUSY_LASTWRITE ? color_int : 0;

endmodule
