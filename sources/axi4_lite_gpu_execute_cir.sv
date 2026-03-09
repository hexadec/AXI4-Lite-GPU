module axi4_lite_gpu_execute_cir #(
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

    input center_valid,
    input [11:0] center_x,
    input [11:0] center_y,
    input radius_valid,
    input [11:0] radius,
    input color_valid,
    input [COLOR_WIDTH - 1 : 0] color,

    output fbuf_en_wr,
    output fbuf_wrea,
    output [FBUF_ADDR_WIDTH - 1 : 0] fbuf_addr,
    output [FBUF_DATA_WIDTH - 1 : 0] fbuf_data
);

enum logic [3:0] {IDLE, BUSY_PREPARE, BUSY_EVAL, BUSY_CALC_WR_INCR, BUSY_CALC_INCR, DONE, ERR} state, next_state;

reg center_valid_int;
reg radius_valid_int;
reg color_valid_int;

reg signed [13:0] center_x_int, center_y_int;
reg signed [13:0] radius_int;
reg [COLOR_WIDTH - 1:0] color_int;

reg [11:0] pos_x, pos_y;
reg [11:0] max_x, max_y;
reg [11:0] min_x, min_y;

reg [FBUF_ADDR_WIDTH - 1 : 0] fbuf_addr_int;

reg signed [24:0] dist_x_squared, dist_y_squared;
reg signed [24:0] radius_squared;

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
        if ((center_valid && (center_x >= FRAME_WIDTH_SCALED || center_y >= FRAME_HEIGHT_SCALED)) ||
            (radius_valid && (radius >= FRAME_WIDTH_SCALED && radius >= FRAME_HEIGHT_SCALED))) begin
            next_state = ERR;
        end else if (start && center_valid_int && radius_valid_int && color_valid_int) begin
            next_state = BUSY_PREPARE;
        end else if (start) begin
            next_state = ERR;
        end else begin
            next_state = IDLE;
        end
    end else if (state == BUSY_PREPARE) begin
        next_state = BUSY_EVAL;
    end else if (state == BUSY_EVAL) begin
        if (dist_x_squared + dist_y_squared <= radius_squared) begin
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
        center_valid_int <= 0;
        radius_valid_int <= 0;
        color_valid_int <= 0;
        center_x_int <= 0;
        center_y_int <= 0;
        radius_int <= 0;
        color_int <= 0;
    end else begin
        if (state == IDLE) begin
            if (center_valid) begin
                center_valid_int <= 1;
                center_x_int <= center_x;
                center_y_int <= center_y;
            end
            if (radius_valid) begin
                radius_valid_int <= 1;
                radius_int <= radius;
            end
            if (color_valid) begin
                color_valid_int <= 1;
                color_int <= color;
            end
        end else if (state == DONE || state == ERR) begin
            center_valid_int <= 0;
            radius_valid_int <= 0;
            color_valid_int <= 0;
            center_x_int <= 0;
            center_y_int <= 0;
            radius_int <= 0;
            color_int <= 0;
        end
    end
end


function signed [13:0] min;
    input signed [13:0] a, b;
    begin
        min = a < b ? a : b;
    end
endfunction


function signed [13:0] max;
    input signed [13:0] a, b;
    begin
        max = a > b ? a : b;
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
        dist_x_squared <= 0;
        dist_y_squared <= 0;
        radius_squared <= 0;
        fbuf_addr_int <= 0;
    end else begin
        if (state == IDLE) begin
            if (start && center_valid_int && radius_valid_int && color_valid_int) begin
                min_x <= max(0, min(center_x_int - radius_int, FRAME_WIDTH_SCALED - 1));
                min_y <= max(0, min(center_y_int - radius_int, FRAME_HEIGHT_SCALED - 1));
                max_x <= min(FRAME_WIDTH_SCALED - 1, max(0, center_x_int + radius_int));
                max_y <= min(FRAME_HEIGHT_SCALED - 1, max(0, center_x_int + radius_int));

                pos_x <= max(0, min(center_x_int - radius_int, FRAME_WIDTH_SCALED - 1)); // == min_x
                pos_y <= max(0, min(center_y_int - radius_int, FRAME_HEIGHT_SCALED - 1)); // == min_y

                radius_squared <= radius_int * radius_int;
            end
        end else if (state == BUSY_PREPARE || state == BUSY_CALC_WR_INCR || state == BUSY_CALC_INCR) begin
            dist_x_squared <= (signed'(pos_x) - center_x_int) * (signed'(pos_x) - center_x_int);
            dist_y_squared <= (signed'(pos_y) - center_y_int) * (signed'(pos_y) - center_y_int);
        end else if (state == BUSY_EVAL) begin
            if (pos_x < max_x) begin
                pos_x <= pos_x + 1;
            end else begin
                pos_x <= min_x;
                pos_y <= pos_y + 1;
            end
            fbuf_addr_int <= pos_y * FBUF_ADDR_WIDTH'(FRAME_WIDTH_SCALED) + pos_x;
        end else if (state == DONE || state == ERR) begin
            min_x <= 0;
            min_y <= 0;
            max_x <= 0;
            max_y <= 0;
            pos_x <= 0;
            pos_y <= 0;
            dist_x_squared <= 0;
            dist_y_squared <= 0;
            radius_squared <= 0;
            fbuf_addr_int <= 0;
        end
    end
end


assign fbuf_en_wr = state == BUSY_CALC_WR_INCR;
assign fbuf_wrea = state == BUSY_CALC_WR_INCR;
assign fbuf_addr = state == BUSY_CALC_WR_INCR ? fbuf_addr_int : 0;
assign fbuf_data = state == BUSY_CALC_WR_INCR ? color_int : 0;

endmodule
