module axi4_lite_gpu_execute_cir #(
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

enum logic [5:0] {  IDLE = 0, 
                    BUSY_PREPARE_1 = 6'b100001, 
                    BUSY_PREPARE_2 = 6'b100010,
                    BUSY_PREPARE_3 = 6'b100011, 
                    BUSY_PREPARE_4 = 6'b100100, 
                    BUSY_WR_INCR = 6'b110110, 
                    BUSY_INCR = 6'b100111, 
                    BUSY_LAST_WR_1 = 6'b111000,
                    BUSY_LAST_NOWR_1 = 6'b101001,
                    BUSY_LAST_WR_2 = 6'b111010, 
                    DONE = 6'b001011, 
                    ERR = 6'b001100} state, next_state;

reg center_valid_int;
reg radius_valid_int;
reg color_valid_int;

reg signed [13:0] center_x_int, center_y_int;
reg signed [13:0] radius_int;
reg [COLOR_WIDTH - 1:0] color_int;

reg [11:0] pos_x, pos_y;
reg [11:0] max_x, max_y;
reg [11:0] min_x, min_y;

reg [FBUF_ADDR_WIDTH - 1 : 0] fbuf_addr_int [2:0];

reg signed [24:0] dist_x_squared, dist_y_squared, posx_m_centerx, posy_m_centery;
reg signed [24:0] radius_squared;

assign busy = state[5];
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
        next_state = BUSY_PREPARE_4;
    end else if (state == BUSY_PREPARE_4 || state == BUSY_WR_INCR || state == BUSY_INCR) begin
        if (dist_x_squared + dist_y_squared <= radius_squared) begin
            if (pos_y >= max_y && pos_x >= max_x) begin
                next_state = BUSY_LAST_WR_1;
            end else begin
                next_state = BUSY_WR_INCR;
            end
        end else begin
            if (pos_y >= max_y && pos_x >= max_x) begin
                next_state = BUSY_LAST_NOWR_1;
            end else begin
                next_state = BUSY_INCR;
            end
        end
    end else if (state == BUSY_LAST_WR_1 || state == BUSY_LAST_NOWR_1) begin
        if (dist_x_squared + dist_y_squared <= radius_squared) begin
            next_state = BUSY_LAST_WR_2;
        end else begin
            next_state = DONE;
        end 
    end else if (state == BUSY_LAST_WR_2) begin
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
        posx_m_centerx <= 0;
        posy_m_centery <= 0;
        dist_x_squared <= 0;
        dist_y_squared <= 0;
        radius_squared <= 0;
        fbuf_addr_int[0] <= 0;
        fbuf_addr_int[1] <= 0;
        fbuf_addr_int[2] <= 0;
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
        end else if (state == BUSY_PREPARE_1) begin
            posx_m_centerx <= (signed'(pos_x) - center_x_int);
            posy_m_centery <= (signed'(pos_y) - center_y_int);
            if (radius_int < 5) begin
                radius_squared <= radius_squared + radius_int / 2;
            end else begin
                radius_squared <= radius_squared + radius_int;
            end
        end else if (state == BUSY_PREPARE_2 || state == BUSY_PREPARE_3 || state == BUSY_PREPARE_4 || state == BUSY_WR_INCR || state == BUSY_INCR) begin
            dist_x_squared <= posx_m_centerx * posx_m_centerx;
            dist_y_squared <= posy_m_centery * posy_m_centery;
            if (pos_x < max_x) begin
                pos_x <= pos_x + 1;
            end else begin
                pos_x <= min_x;
                pos_y <= pos_y + 1;
            end
            fbuf_addr_int[0] <= pos_y * FBUF_ADDR_WIDTH'(FRAME_WIDTH_SCALED) + pos_x;
            fbuf_addr_int[1] <= fbuf_addr_int[0];
            fbuf_addr_int[2] <= fbuf_addr_int[1];

            posx_m_centerx <= (signed'(pos_x) - center_x_int);
            posy_m_centery <= (signed'(pos_y) - center_y_int);
        end else if (state == BUSY_LAST_WR_1 || state == BUSY_LAST_NOWR_1) begin
            fbuf_addr_int[2] <= fbuf_addr_int[1];
        end else if (state == DONE || state == ERR) begin
            min_x <= 0;
            min_y <= 0;
            max_x <= 0;
            max_y <= 0;
            pos_x <= 0;
            pos_y <= 0;
            posx_m_centerx <= 0;
            posy_m_centery <= 0;
            dist_x_squared <= 0;
            dist_y_squared <= 0;
            radius_squared <= 0;
            fbuf_addr_int[0] <= 0;
            fbuf_addr_int[1] <= 0;
            fbuf_addr_int[2] <= 0;
        end
    end
end


assign fbuf_en_wr = state[5:4] == 2'b11;
assign fbuf_wrea = state[5:4] == 2'b11;
assign fbuf_addr = state[5:4] == 2'b11 ? fbuf_addr_int[2] : 0;
assign fbuf_data = state[5:4] == 2'b11 ? color_int : 0;

endmodule
