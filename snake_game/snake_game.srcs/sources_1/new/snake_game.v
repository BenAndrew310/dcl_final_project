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

    localparam TILE_LENGTH = 40;
    localparam COLUMN = 16;
    localparam ROW = 12;

    wire [3:0]direction;

    wire [COLUMN*ROW*5-1:0] flattened_map;
    _input Input ( .clk(clk),  .reset_n(reset_n), .usr_btn(usr_btn),
                  .direction(direction));
    logic Logic ( .clk(clk),  .reset_n(reset_n), .direction(direction),
                  .flattened_map(flattened_map));
    view  View  ( .clk(clk),  .reset_n(reset_n), .flattened_map(flattened_map),
                  .VGA_HSYNC(VGA_HSYNC), .VGA_VSYNC(VGA_VSYNC), .VGA_RED(VGA_RED), .VGA_GREEN(VGA_GREEN), .VGA_BLUE(VGA_BLUE));

    
endmodule
