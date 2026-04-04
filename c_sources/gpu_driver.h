#ifndef _AXI4_LITE_GPU_DRIVER_H
#define _AXI4_LITE_GPU_DRIVER_H

#include <stdint.h>

void axi4_lite_gpu_draw_char(uint16_t x, uint16_t y, char character, uint8_t color);
void axi4_lite_gpu_draw_string(uint16_t x, uint16_t y, char * text, uint8_t color);
void axi4_lite_gpu_draw_line(uint16_t x0, uint16_t y0, uint16_t x1, uint16_t y1, uint8_t color);
void axi4_lite_gpu_draw_circle(uint16_t center_x, uint16_t center_y, uint16_t radius, uint8_t color);
void axi4_lite_gpu_draw_triangle(uint16_t x0, uint16_t y0, uint16_t x1, uint16_t y1, uint16_t x2, uint16_t y2, uint8_t color);
void axi4_lite_gpu_draw_rect(uint16_t x0, uint16_t y0, uint16_t x1, uint16_t y1, uint8_t color);
void axi4_lite_gpu_draw_pixel(uint16_t x, uint16_t y, uint8_t color);

#endif