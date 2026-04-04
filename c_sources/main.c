#include "platform.h"
#include "sleep.h"
#include "gpu_driver.h"

int main() {
    init_platform();
    uint32_t height_x_width = Xil_In32(XPAR_AXI4_LITE_GPU_0_BASEADDR + 8);
    uint32_t height = height_x_width >> 16;
    uint32_t width = height_x_width & 0xffff;
    axi4_lite_gpu_draw_rect(0, 0, width - 1, height - 1, 0b11111111U);
    axi4_lite_gpu_draw_rect(4, 4, width - 5, height - 5, 0b00100100U);
    axi4_lite_gpu_draw_triangle(0, 0, width - 1, height - 1, 0, height - 1, 0b00011100U);
    axi4_lite_gpu_draw_rect(width / 4, height / 4, width * 3 / 4, height * 3 / 4, 0b11111100U);
    axi4_lite_gpu_draw_triangle(width * 3 / 4, height / 4, width * 3 / 4, height * 3 / 4, width / 4, height * 3 / 4, 0b11100000U);
    axi4_lite_gpu_draw_circle(width / 8, height / 8, 10, 0b00000011U);
    axi4_lite_gpu_draw_line(width / 6, height / 6, width * 4 / 6, height * 2 / 6, 0b10000010U);
    axi4_lite_gpu_draw_pixel(width / 2, height / 2, 0b11111111U);
    axi4_lite_gpu_draw_string(48, 8, "AXI4-LITE-GPU text test #1", 0b11100011);
    axi4_lite_gpu_draw_string(48, 16, "ABCDEFGHIJKLMNOPQRSTUQVXYZ #2", 0b11110010);
    axi4_lite_gpu_draw_string(48, 24, "abcdefghijklmnopqrstuvwxyz #3", 0b10010010);
    axi4_lite_gpu_draw_string(48, 32, "0123456789-_*.:<>?,;[]{}^! #4", 0b00110011);
    axi4_lite_gpu_draw_string(48, 40, "()+~'\"`/\\|@$&=%# #5", 0b01001011);
    cleanup_platform();
    return 0;
}
