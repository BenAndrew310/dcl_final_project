 `timescale 1ns / 1ps

module logic
#(parameter TILE_LENGTH = 40, COLUMN = 16, ROW = 12)(
input  clk,
input  reset_n,
input  [3:0] direction,

output [COLUMN*ROW*5-1:0] flattened_map
);
    reg [3:0] snake_pos[1:0][COLUMN*ROW-1:0];
    reg [7:0] snake_len =1;
    reg [4:0] map [COLUMN*ROW-1:0];

    wire [COLUMN*ROW*5-1:0] flatten_map;
    genvar fi;
    generate for (fi=0; fi<COLUMN*ROW; fi=fi+1) begin
      assign flattened_map[5*fi+5-1:5*fi] = map[fi];
    end endgenerate

    integer si,sj;
    initial begin
       for (si = 0; si<COLUMN*ROW; si=si+1) begin
           for (sj = 0; sj<2;sj=sj+1) begin
               snake_pos[sj][si] = 0;
           end
        end
        snake_pos[10][10] = 11;
    end

    integer i;
    always @(posedge clk) begin
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
        end
        map[COLUMN-1] <= 23;
        map[COLUMN*(ROW-1)] <= 19;
        map[COLUMN*ROW-1] <= 20;
        map[COLUMN*(4)+5] <= 0;
        for (i=0; i <snake_len; i = i+1) begin
            map[snake_pos[0][i]][snake_pos[1][i]] = 11; 
        end
    end



endmodule
