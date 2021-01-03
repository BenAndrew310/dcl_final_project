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

    localparam TILE_LENGTH = 40;
    localparam COLUMN = 16;
    localparam ROW = 12;

    reg [4:0] map [COLUMN*ROW-1:0];
    integer i;
    initial begin
        for (i=0; i<COLUMN*ROW; i=i+1) begin
            if (i<16)
              map[i] <= 4;
            else if (i%16==0)
              map[i] <= 2;
            else if ((i-15)%16==0)
              map[i] <= 3;
            else if (i >= COLUMN*ROW-16)
              map[i] <= 1;
            else
              map[i] <= 21;
            map[0] <= 22;
            map[COLUMN-1] <= 23;
            map[COLUMN*(ROW-1)] <= 19;
            map[COLUMN*ROW-1] <= 20;
            map[COLUMN*(4)+5] <= 0;
        end
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

    sram #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(TILE_LENGTH*TILE_LENGTH*24)) //ADDR_WIDTH(18)
        ram1 (.clk(clk), .we(sram_we), .en(sram_en),
            .addr(sram_addr), .data_i(data_in), .data_o(data_out));


    assign sram_en = 1;
    assign data_in = 12'h000;

    assign sram_addr = pixel_addr;

    assign {VGA_RED,VGA_GREEN,VGA_BLUE} = rgb_reg;

    integer pos_x;
    integer pos_y;
    reg [15:0] start_point = 0;
    always @(posedge clk)  begin
        if (~reset_n)
            start_point <= 0;
        else begin
            pos_x <= pixel_x/TILE_LENGTH;
            pos_y <= pixel_y/TILE_LENGTH;
            start_point <= map[pos_y*COLUMN+pos_x]*1600;
        end
    end

    always @ (posedge clk) begin
      if (~reset_n)
        pixel_addr <= 0;
      else
        // (pixel_x, pixel_y) ranges from (0,0) to (639, 479)
        pixel_addr <= (pixel_y%TILE_LENGTH)*TILE_LENGTH + pixel_x%TILE_LENGTH + start_point;
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
