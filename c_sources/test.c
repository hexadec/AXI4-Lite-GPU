#include <stdint.h>
#include <stdio.h>
#include "platform.h"
#include "xil_io.h"
#include "sleep.h"

void drawChar(uint16_t x, uint16_t y, char character, uint8_t color) {
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

void drawLine(uint16_t x0, uint16_t y0, uint16_t x1, uint16_t y1, uint8_t color) {
    Xil_Out32(XPAR_AXI4_LITE_GPU_0_BASEADDR + 0x404, ((uint32_t) x0) << 16 | ((uint32_t) y0));
    Xil_Out32(XPAR_AXI4_LITE_GPU_0_BASEADDR + 0x408, ((uint32_t) x1) << 16 | ((uint32_t) y1));
    Xil_Out32(XPAR_AXI4_LITE_GPU_0_BASEADDR + 0x40C, ((uint32_t) color));
    Xil_Out32(XPAR_AXI4_LITE_GPU_0_BASEADDR + 0x400, 0);
}

void drawCircle(uint16_t center_x, uint16_t center_y, uint16_t radius, uint8_t color) {
    Xil_Out32(XPAR_AXI4_LITE_GPU_0_BASEADDR + 0x304, ((uint32_t) center_x) << 16 | ((uint32_t) center_y));
    Xil_Out32(XPAR_AXI4_LITE_GPU_0_BASEADDR + 0x308, ((uint32_t) radius));
    Xil_Out32(XPAR_AXI4_LITE_GPU_0_BASEADDR + 0x30C, ((uint32_t) color));
    Xil_Out32(XPAR_AXI4_LITE_GPU_0_BASEADDR + 0x300, 0);
}

void drawTriangle(uint16_t x0, uint16_t y0, uint16_t x1, uint16_t y1, uint16_t x2, uint16_t y2, uint8_t color) {
    Xil_Out32(XPAR_AXI4_LITE_GPU_0_BASEADDR + 0x204, ((uint32_t) x0) << 16 | ((uint32_t) y0));
    Xil_Out32(XPAR_AXI4_LITE_GPU_0_BASEADDR + 0x208, ((uint32_t) x1) << 16 | ((uint32_t) y1));
    Xil_Out32(XPAR_AXI4_LITE_GPU_0_BASEADDR + 0x20C, ((uint32_t) x2) << 16 | ((uint32_t) y2));
    Xil_Out32(XPAR_AXI4_LITE_GPU_0_BASEADDR + 0x210, ((uint32_t) color));
    Xil_Out32(XPAR_AXI4_LITE_GPU_0_BASEADDR + 0x200, 0);
}

void drawRect(uint16_t x0, uint16_t y0, uint16_t x1, uint16_t y1, uint8_t color) {
    Xil_Out32(XPAR_AXI4_LITE_GPU_0_BASEADDR + 0x104, ((uint32_t) x0) << 16 | ((uint32_t) y0));
    Xil_Out32(XPAR_AXI4_LITE_GPU_0_BASEADDR + 0x108, ((uint32_t) x1) << 16 | ((uint32_t) y1));
    Xil_Out32(XPAR_AXI4_LITE_GPU_0_BASEADDR + 0x10C, ((uint32_t) color));
    Xil_Out32(XPAR_AXI4_LITE_GPU_0_BASEADDR + 0x100, 0);
}

void drawPixel(uint16_t x, uint16_t y, uint8_t color) {
    Xil_Out32(XPAR_AXI4_LITE_GPU_0_BASEADDR, ((uint32_t) x) << 20 | ((uint32_t) y) << 8 | ((uint32_t) color));
}


int main()
{
    init_platform();
    uint32_t height_x_width = Xil_In32(XPAR_AXI4_LITE_GPU_0_BASEADDR + 8);
    uint32_t height = height_x_width >> 16;
    uint32_t width = height_x_width & 0xffff;
    drawRect(0, 0, width - 1, height - 1, 0b11111111U);
    drawRect(4, 4, width - 5, height - 5, 0b00100100U);
    drawTriangle(0, 0, width - 1, height - 1, 0, height - 1, 0b00011100U);
    drawRect(width / 4, height / 4, width * 3 / 4, height * 3 / 4, 0b11111100U);
    drawTriangle(width * 3 / 4, height / 4, width * 3 / 4, height * 3 / 4, width / 4, height * 3 / 4, 0b11100000U);
    drawCircle(width / 8, height / 8, 10, 0b00000011U);
    drawLine(width / 6, height / 6, width * 4 / 6, height * 2 / 6, 0b10000010U);
    drawPixel(width / 2, height / 2, 0b11111111U);
    for (int i = 0; i < 26; i++) {
        drawChar(i * 8 + 8, 8, 'A' + i, i);
        if (i % 3 == 0) {
            sleep(1);
        }
    }
    for (int i = 0; i < 10; i++) {
        drawChar(i * 8 + 8, 16, '0' + i, i);
        if (i % 3 == 0) {
            sleep(1);
        }
    }
    cleanup_platform();
    return 0;
}
