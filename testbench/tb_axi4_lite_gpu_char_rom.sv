module tb_axi4_lite_gpu_char_rom;

localparam CHAR_WIDTH = 8;
localparam CHAR_HEIGHT = 8;
localparam CHARACTER_COUNT = 95;

logic clk = 0;

logic en = 0;
logic [$clog2(CHARACTER_COUNT) - 1 : 0] char_code = 0;
logic [$clog2(CHAR_HEIGHT) - 1 : 0] char_row_addr = 0;
logic [CHAR_WIDTH - 1:0] char_row;

int char_rom_fd;
int row_idx;
string line_content;

axi4_lite_gpu_char_rom #(
    .CHAR_WIDTH(CHAR_WIDTH),
    .CHAR_HEIGHT(CHAR_HEIGHT),
    .CHARACTER_COUNT(CHARACTER_COUNT)
) axi4_lite_gpu_char_rom_inst (
    .clk(clk),
    .en(en),
    .char_code(char_code),
    .char_row_addr(char_row_addr),
    .char_row(char_row)
);

always #5 clk = ~clk;

initial begin
    #10
    $display("ROM contents loaded from file");
    char_rom_fd = $fopen("./font.mem", "r");
    row_idx = 0;
    while ($fscanf(char_rom_fd, "%s", line_content) == 1) begin
        #10
        en = 1;
        char_code = row_idx / 8;
        char_row_addr = row_idx % 8;
        #10
        en = 0;
        assert(line_content.atobin() == char_row) else $display("Char ROM mismatch: Row: %s, Idx: %d, ROM content: %b", line_content, row_idx, char_row);
        row_idx += 1;
    end
    #10
    $finish();
end

endmodule
