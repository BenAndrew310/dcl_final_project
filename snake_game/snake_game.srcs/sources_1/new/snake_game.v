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

    localparam TILE_WIDTH = 60, TILE_HEIGHT = 60;

    wire [15:0] start_point = 0;
    reg [4:0] map [7:0];
    integer i,j;
    initial begin
        for (i=0; i<16*12; i=i+1) begin
            map[i] = 21;
            // for (j=0; j<12; j=j+1) begin
            //     map[i][j] = 21;
            // end
        end
        // map[0][0] = 1;
        // map[12][10] = 1;
    end

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
    localparam VBUF_W = 640;
    localparam VBUF_H = 480;

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

    sram #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(TILE_WIDTH*TILE_HEIGHT)) //ADDR_WIDTH(18)
        ram1 (.clk(clk), .we(sram_we), .en(sram_en),
            .addr(sram_addr), .data_i(data_in), .data_o(data_out));


    assign sram_en = 1;
    assign data_in = 12'h000;

    assign sram_addr = pixel_addr;

    assign {VGA_RED,VGA_GREEN,VGA_BLUE} = rgb_reg;

    // initial begin
    //     pixel_addr <= 18'd0;
    // end

    integer x, y;

    // always @(posedge clk)  begin
    //     if (~reset_n)
    //         start_point <= 0;
    //     else begin
    //         start_point <= 11*1600;
    //         // x = pixel_x/40;
    //         // y = pixel_y/40;
    //         // start_point = map[x*16+y]*1600;
    //     end
    // end

    assign start_point = 11*1600;

    always @ (posedge clk) begin
      if (~reset_n)
        pixel_addr <= 0;
      else
        // Scale up a 320x240 image for the 640x480 display.
        // (pixel_x, pixel_y) ranges from (0,0) to (639, 479)
        // pixel_addr <= (pixel_y >> 1) * VBUF_W + (pixel_x >> 1) + start_point;
        pixel_addr <= pixel_y%40*40 + pixel_x%40 + start_point;
    end

    always @(posedge clk) begin
      if (pixel_tick) rgb_reg <= rgb_next;
    end

    always @(*) begin
        if (~video_on)
            rgb_next = 12'h000;
        else rgb_next = data_out;
    end
endmodule
