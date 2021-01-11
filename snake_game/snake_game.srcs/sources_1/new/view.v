`timescale 1ns / 1ps

module view
#(parameter TILE_LENGTH = 40, COLUMN = 16, ROW = 12)(
input  clk,
input  reset_n,
input  [COLUMN*ROW*5-1:0] flattened_map,
input  game_started,
input  [7:0]score,

// VGA specific I/O ports
output VGA_HSYNC,
output VGA_VSYNC,
output [3:0] VGA_RED,
output [3:0] VGA_GREEN,
output [3:0] VGA_BLUE
);

wire [4:0] map [COLUMN*ROW-1:0];
genvar fi;
generate for (fi=0;fi<COLUMN*ROW;fi=fi+1) begin
    assign map[fi] = flattened_map[5*fi+5-1:5*fi];
end
endgenerate

// Declare SRAM control signals

wire [16:0] sram_addr;
wire [11:0] data_in;
wire [11:0] data_out;
wire        sram_en, sram_we;

wire [16:0] sram_score_addr;
wire [11:0] data_score_out;

// General VGA control signals

wire vga_clk;
wire video_on;
wire pixel_tick;

wire [9:0] pixel_x, pixel_y;

reg [11:0] rgb_reg;
reg [11:0] rgb_next;

// Application specifc VGA signals

reg [17:0] pixel_addr;
reg [17:0] score_pixel_addr;

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

sram_score #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(TILE_LENGTH*TILE_LENGTH*16)) //ADDR_WIDTH(18)
    ram2 (.clk(clk), .we(sram_we), .en(sram_en),
    .addr(sram_score_addr), .data_i(data_in), .data_o(data_score_out));


assign sram_en = 1;
assign data_in = 12'h000;

assign sram_addr = pixel_addr;
assign sram_score_addr = score_pixel_addr;

assign {VGA_RED,VGA_GREEN,VGA_BLUE} = rgb_reg;

integer pos_x;
integer pos_y;
reg [15:0] start_point = 0;
reg [15:0] score_start_point = 0;
always @(posedge clk)  begin
    if (~reset_n)
        start_point <= 0;
    else begin
        pos_x <= pixel_x/TILE_LENGTH;
        pos_y <= pixel_y/TILE_LENGTH;
        start_point <= map[pos_y*COLUMN+pos_x]*1600;
        if (pos_x == 0 && pos_y == 0)
            score_start_point <= 240*40 + score / 100 * 1600;
        else if (pos_x == 1 && pos_y == 0)
            score_start_point <= 240*40 + (score%100) / 10 * 1600;
        else if (pos_x == 2 && pos_y == 0)
            score_start_point <= 240*40 + score % 10 * 1600;
        else score_start_point <= 12'b111111111111;
    end
end

always @ (posedge clk) begin
    if (~reset_n) begin
        pixel_addr <= 0;
        score_pixel_addr <= 0;
    end
    else
    // (pixel_x, pixel_y) ranges from (0,0) to (639, 479)
    pixel_addr <= (pixel_y%TILE_LENGTH)*TILE_LENGTH + pixel_x%TILE_LENGTH - 1 + start_point;
    if (score_start_point == 12'b111111111111) begin
        score_pixel_addr <= 0;
    end else begin
        score_pixel_addr <= (pixel_y%TILE_LENGTH)*TILE_LENGTH + pixel_x%(TILE_LENGTH) - 1 + score_start_point;
    end
end

always @(posedge clk) begin
    if (pixel_tick) rgb_reg <= rgb_next;
end

always @(*) begin
    if (~video_on)
        rgb_next = 12'h000;
    else rgb_next = (data_score_out == 12'b111111111111 || score_start_point == 12'b111111111111) ? data_out : data_score_out;
end

endmodule
