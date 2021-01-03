`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/01/03 14:42:17
// Design Name: 
// Module Name: snake_game
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module snake_game(
    input  clk,
    input  reset_n,
    input  [3:0] usr_btn,
    output [3:0] usr_led,
    
    // VGA specific I/O ports
    output VGA_HSYNC,
    output VGA_VSYNC,
    output [3:0] VGA_RED,
    output [3:0] VGA_GREEN,
    output [3:0] VGA_BLUE
    );

    // Declare system variables



    // Declare SRAM control signals

    wire [16:0] sram_addr;
    wire [11:0] data_in;
    wire [11:0] data_out;
    wire        sram_en, sram_we;

    // General VGA control signals

    wire vga_clk;
    wire video_on;
    wire pixel_tick;

    wire [9:0] pixel_x, pixel_y;

    reg [11:0] rgb_reg;
    reg [11:0] rgb_next;

    // Application specifc VGA signals

    reg [17:0] pixel_addr;

    // Video buffer size
    localparam VBUF_W = 320; // might need to change those afterwards
    localparam VBUF_H = 240;

    // Instiantiate the VGA sync signal generator
    vga_sync vs0(
      .clk(vga_clk), .reset(~reset_n), .oHS(VGA_HSYNC), .oVS(VGA_VSYNC),
      .visible(video_on), .p_tick(pixel_tick),
      .pixel_x(pixel_x), .pixel_y(pixel_y)
    );

    clk_divider#(2) clk_divider0(
      .clk(clk),
      .reset(~reset_n),
      .clk_out(vga_clk)
    );

    assign sram_en = 1;
    assign data_in = 12'h000;

    assign sram_addr = pixel_addr;

    assign {VGA_RED,VGA_GREEN,VGA_BLUE} = rgb_reg;

    

endmodule
