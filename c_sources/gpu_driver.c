#include "xil_io.h"
#include "sleep.h"
#include "gpu_driver.h"

void axi4_lite_gpu_draw_char(uint16_t x, uint16_t y, char character, uint8_t color) {
    uint16_t char_code;
    if (character >= ' ' && character <= '~') {
        char_code = character - ' ';
    } else {
        return;
    }
    Xil_Out32(XPAR_AXI4_LITE_GPU_0_BASEADDR + 0x504, ((uint32_t) x) << 16 | ((uint32_t) y));
    Xil_Out32(XPAR_AXI4_LITE_GPU_0_BASEADDR + 0x508, char_code);
    Xil_Out32(XPAR_AXI4_LITE_GPU_0_BASEADDR + 0x50C, ((uint32_t) color));
    Xil_Out32(XPAR_AXI4_LITE_GPU_0_BASEADDR + 0x500, 0);
}

void axi4_lite_gpu_draw_string(uint16_t x, uint16_t y, char * text, uint8_t color) {
    uint32_t height_x_width = Xil_In32(XPAR_AXI4_LITE_GPU_0_BASEADDR + 8);
    uint32_t height = height_x_width >> 16;
    uint32_t width = height_x_width & 0xffff;
    int idx = 0;
    while (text[idx] != 0) {
        uint16_t x_pos = (x + idx * 8) % width;
        uint16_t y_pos = (y + ((x + idx * 8) / width) * 8) % height;
        axi4_lite_gpu_draw_char(x_pos, y_pos, text[idx], color);
        idx++;
        if (Xil_In32(XPAR_AXI4_LITE_GPU_0_BASEADDR) & 0b100000) {
            msleep(100);
        }
    }
}

void axi4_lite_gpu_draw_line(uint16_t x0, uint16_t y0, uint16_t x1, uint16_t y1, uint8_t color) {
    Xil_Out32(XPAR_AXI4_LITE_GPU_0_BASEADDR + 0x404, ((uint32_t) x0) << 16 | ((uint32_t) y0));
    Xil_Out32(XPAR_AXI4_LITE_GPU_0_BASEADDR + 0x408, ((uint32_t) x1) << 16 | ((uint32_t) y1));
    Xil_Out32(XPAR_AXI4_LITE_GPU_0_BASEADDR + 0x40C, ((uint32_t) color));
    Xil_Out32(XPAR_AXI4_LITE_GPU_0_BASEADDR + 0x400, 0);
}

void axi4_lite_gpu_draw_circle(uint16_t center_x, uint16_t center_y, uint16_t radius, uint8_t color) {
    Xil_Out32(XPAR_AXI4_LITE_GPU_0_BASEADDR + 0x304, ((uint32_t) center_x) << 16 | ((uint32_t) center_y));
    Xil_Out32(XPAR_AXI4_LITE_GPU_0_BASEADDR + 0x308, ((uint32_t) radius));
    Xil_Out32(XPAR_AXI4_LITE_GPU_0_BASEADDR + 0x30C, ((uint32_t) color));
    Xil_Out32(XPAR_AXI4_LITE_GPU_0_BASEADDR + 0x300, 0);
}

void axi4_lite_gpu_draw_triangle(uint16_t x0, uint16_t y0, uint16_t x1, uint16_t y1, uint16_t x2, uint16_t y2, uint8_t color) {
    Xil_Out32(XPAR_AXI4_LITE_GPU_0_BASEADDR + 0x204, ((uint32_t) x0) << 16 | ((uint32_t) y0));
    Xil_Out32(XPAR_AXI4_LITE_GPU_0_BASEADDR + 0x208, ((uint32_t) x1) << 16 | ((uint32_t) y1));
    Xil_Out32(XPAR_AXI4_LITE_GPU_0_BASEADDR + 0x20C, ((uint32_t) x2) << 16 | ((uint32_t) y2));
    Xil_Out32(XPAR_AXI4_LITE_GPU_0_BASEADDR + 0x210, ((uint32_t) color));
    Xil_Out32(XPAR_AXI4_LITE_GPU_0_BASEADDR + 0x200, 0);
}

void axi4_lite_gpu_draw_rect(uint16_t x0, uint16_t y0, uint16_t x1, uint16_t y1, uint8_t color) {
    Xil_Out32(XPAR_AXI4_LITE_GPU_0_BASEADDR + 0x104, ((uint32_t) x0) << 16 | ((uint32_t) y0));
    Xil_Out32(XPAR_AXI4_LITE_GPU_0_BASEADDR + 0x108, ((uint32_t) x1) << 16 | ((uint32_t) y1));
    Xil_Out32(XPAR_AXI4_LITE_GPU_0_BASEADDR + 0x10C, ((uint32_t) color));
    Xil_Out32(XPAR_AXI4_LITE_GPU_0_BASEADDR + 0x100, 0);
}

void axi4_lite_gpu_draw_pixel(uint16_t x, uint16_t y, uint8_t color) {
    Xil_Out32(XPAR_AXI4_LITE_GPU_0_BASEADDR, ((uint32_t) x) << 20 | ((uint32_t) y) << 8 | ((uint32_t) color));
}
