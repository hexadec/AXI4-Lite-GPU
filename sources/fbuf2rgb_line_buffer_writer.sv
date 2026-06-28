module fbuf2rgb_line_buffer_writer 
#(
    parameter FRAME_H = 90,
    parameter FRAME_V = 90,
    parameter FRAME_H_TOTAL = 100,
    parameter FRAME_V_TOTAL = 100,
    parameter SCALING_FACTOR = 2,
    parameter COLOR_WIDTH = 8
) (
    input wire clk,
    input wire rst_n,
    input wire [12:0] h_counter_gray,
    input wire [12:0] v_counter_gray,

    output wire [12:0] line1_addr,
    output wire [COLOR_WIDTH - 1 : 0] line1_data,
    output wire line1_wrea,

    output wire [12:0] line2_addr,
    output wire [COLOR_WIDTH - 1 : 0] line2_data,
    output wire line2_wrea
);

    reg [12:0] h_counter_axi, h_counter_gray_axi, h_counter_scaled_axi;
    reg [12:0] v_counter_axi, v_counter_gray_axi, v_counter_scaled_axi;
    reg [12:0] line1_v_axi, line_1_received_h_axi;
    reg [12:0] line2_v_axi, line_2_received_h_axi;
    reg [12:0] tmp_next_line1_axi, tmp_next_line2_axi;
    
    integer i;

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            h_counter_axi <= 0;
            v_counter_axi <= 0;
            h_counter_gray_axi <= 0;
            v_counter_gray_axi <= 0;
            h_counter_scaled_axi <= 0;
            v_counter_scaled_axi <= 0;
        end else begin
            h_counter_gray_axi <= h_counter_gray;
            v_counter_gray_axi <= v_counter_gray;
            // Ternary operator to ignore possible sudden jumps when toggling to 0
            h_counter_scaled_axi <= h_counter_axi >= FRAME_H_TOTAL ? h_counter_scaled_axi : h_counter_axi / SCALING_FACTOR;
            v_counter_scaled_axi <= v_counter_axi >= FRAME_V_TOTAL ? v_counter_scaled_axi : v_counter_axi / SCALING_FACTOR;

            for (i = 0; i < 12; i = i + 1) begin
                h_counter_axi[i] <= ^(h_counter_gray_axi >> i);
                v_counter_axi[i] <= ^(v_counter_gray_axi >> i);
            end
        end
    end

    enum logic [2:0] {
        LINE_1_WAIT_LOAD,
        LINE_1_PREPARE_LOAD,
        LINE_1_LOAD,
        LINE_2_WAIT_LOAD,
        LINE_2_PREPARE_LOAD,
        LINE_2_LOAD
    } state, next_state;

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            state <= LINE_1_WAIT_LOAD;
        end else begin
            state <= next_state;
        end
    end

    always_comb begin
        if (!rst_n) begin
            next_state = LINE_1_WAIT_LOAD;
        end else begin
            if (state == LINE_1_WAIT_LOAD) begin // LINE_1_WAIT_LOAD
                if (v_counter_scaled_axi >= line1_v_axi && h_counter_scaled_axi >= FRAME_H / SCALING_FACTOR) begin
                    next_state = LINE_1_PREPARE_LOAD;
                end else begin
                    next_state = LINE_1_WAIT_LOAD;
                end
            end else if (state == LINE_1_PREPARE_LOAD) begin // LINE_1_PREPARE_LOAD
                next_state = LINE_1_LOAD;
            end else if (state == LINE_1_LOAD) begin // LINE_1_LOAD
                if (line_1_received_h_axi < FRAME_H / SCALING_FACTOR) begin
                    next_state = LINE_1_LOAD;
                end else begin
                    next_state = LINE_2_WAIT_LOAD;
                end
            end else if (state == LINE_2_WAIT_LOAD) begin // LINE_2_WAIT_LOAD
                if (v_counter_scaled_axi >= line2_v_axi && h_counter_scaled_axi >= FRAME_H / SCALING_FACTOR) begin
                    next_state = LINE_2_PREPARE_LOAD;
                end else begin
                    next_state = LINE_2_WAIT_LOAD;
                end
            end else if (state == LINE_2_PREPARE_LOAD) begin // LINE_2_PREPARE_LOAD
                next_state = LINE_2_LOAD;
            end else if (state == LINE_2_LOAD) begin // LINE_2_LOAD
                if (line_2_received_h_axi < FRAME_H / SCALING_FACTOR) begin
                    next_state = LINE_2_LOAD;
                end else begin
                    next_state = LINE_1_WAIT_LOAD;
                end
            end else begin
                next_state = LINE_1_WAIT_LOAD;
            end
        end
    end

    always_ff @(posedge clk) begin
        if (!rst_n) begin 
            line1_v_axi <= 0;
            line2_v_axi <= 1;
            line_1_received_h_axi <= 0;
            line_2_received_h_axi <= 0;
            tmp_next_line1_axi <= 2;
            tmp_next_line2_axi <= 3;
        end else begin
            if (state == LINE_1_WAIT_LOAD) begin
                tmp_next_line1_axi[12:1] <= (v_counter_scaled_axi + 3) >> 1;
                tmp_next_line1_axi[0] <= 0;
            end else if (state == LINE_1_PREPARE_LOAD) begin
                line1_v_axi <= tmp_next_line1_axi < FRAME_V / SCALING_FACTOR ? tmp_next_line1_axi : 0;
                line_1_received_h_axi <= 0;
            end else if (state == LINE_1_LOAD) begin
                // TODO COMMAND TO READ FROM AXI DMA AND MANAGE READ POSITION
            end else if (state == LINE_2_WAIT_LOAD) begin
                tmp_next_line2_axi[12:1] <= (v_counter_scaled_axi + 2) >> 1;
                tmp_next_line2_axi[0] <= 1;
            end else if (state == LINE_2_PREPARE_LOAD) begin
                line2_v_axi <= tmp_next_line2_axi < FRAME_V / SCALING_FACTOR ? tmp_next_line2_axi : 1;
                line_2_received_h_axi <= 0;
            end else if (state == LINE_2_LOAD) begin
                // TODO COMMAND TO READ FROM AXI DMA AND MANAGE READ POSITION
            end else begin
                // TODO handle invalid state
            end
        end
    end

endmodule
