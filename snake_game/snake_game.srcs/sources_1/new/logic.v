 `timescale 1ns / 1ps

module logic
#(parameter TILE_LENGTH = 40, COLUMN = 16, ROW = 12)(
input  clk,
input  reset_n,
input  [3:0] direction,
input  game_started,

output [COLUMN*ROW*5-1:0] flattened_map,
output reg game_ended
);

    localparam CALC_COL = COLUMN - 2;
    localparam CALC_ROW = ROW - 2;

    localparam  APPLE = 0,
                BORDER_B = 1,
                BORDER_L = 2,
                BORDER_R = 3,
                BORDER_T = 4,
                SNAKE_B_B2R = 5,
                SNAKE_B_H = 6,
                SNAKE_B_L2B = 7,
                SNAKE_B_T2L = 8,
                SNAKE_B_T2R = 9,
                SNAKE_B_V = 10,
                SNAKE_H_B = 11,
                SNAKE_H_L = 12,
                SNAKE_H_R = 13,
                SNAKE_H_T = 14,
                SNAKE_T_B = 15,
                SNAKE_T_L = 16,
                SNAKE_T_R = 17,
                SNAKE_T_T = 18,
                TILE_BL = 19,
                TILE_BR = 20,
                TILE_EMPTY = 21,
                TILE_TL = 22,
                TILE_TR = 23,
                NULL = 31;

    //snake array
    reg [7:0] snake_pos[CALC_COL*CALC_ROW-1:0];
    reg [7:0] snake_temp[CALC_COL*CALC_ROW-1:0];
    reg [7:0] snake_len;


    //for view module
    reg [4:0] map [COLUMN*ROW-1:0];
    //for calculation
    reg [4:0] calc_map [CALC_COL*CALC_ROW-1:0];

    //flatten map
    genvar fi;
    generate for (fi=0; fi<COLUMN*ROW; fi=fi+1) begin
      assign flattened_map[5*fi+5-1:5*fi] = map[fi];
    end endgenerate

    wire timer;
    reg [27:0] counter;
    localparam TICK_PER_CLK = 80000000;
    always @(posedge clk) begin
        counter = (counter <= TICK_PER_CLK)? counter + 1: 0;
    end
    assign timer = counter == TICK_PER_CLK;

    integer i, j;
    always @(posedge clk) begin

        //border and corner
        for (i=0; i<COLUMN*ROW; i=i+1) begin
            if (i<COLUMN)
                map[i] <= BORDER_T;
            else if (i%COLUMN==0)
                map[i] <= BORDER_L;
            else if ((i-COLUMN+1)%COLUMN==0)
                map[i] <= BORDER_R;
            else if (i >= COLUMN*ROW-COLUMN)
                map[i] <= BORDER_B;
        end
        map[0] <= TILE_TL;
        map[COLUMN-1] <= TILE_TR;
        map[COLUMN*(ROW-1)] <= TILE_BL;
        map[COLUMN*ROW-1] <= TILE_BR;

        //put calc_map in the middle of map
        for (i=0; i < CALC_COL; i = i + 1) begin
            for (j = 0; j < CALC_ROW; j = j+1) begin
                map[(i+1)+(j+1)*COLUMN] = calc_map[i+j*CALC_COL];
            end
        end
    end

    //calc_map
    always @(posedge clk) begin
        //snake
        for (i = 0; i < CALC_COL*CALC_ROW; i = i + 1) begin
            calc_map[i] = TILE_EMPTY;
        end

        for (i = 0; i < CALC_COL*CALC_ROW; i = i + 1) begin
            if (snake_len > i) begin
                calc_map[snake_pos[i]] = SNAKE_H_B;
            end
        end
        
        //apple
        calc_map[CALC_COL*3+1] = APPLE;
        //todo
    end

    integer si;
    reg collided;
    always @(posedge clk) begin
        if (~reset_n) begin
            collided <= 0;
            snake_pos[0] <= (2-1)*CALC_COL+(CALC_ROW-1);
            snake_pos[1] <= (3-1)*CALC_COL+(CALC_ROW-1);
            snake_pos[2] <= (4-1)*CALC_COL+(CALC_ROW-1);
            snake_pos[3] <= (5-1)*CALC_COL+(CALC_ROW-1);
            snake_pos[4] <= (6-1)*CALC_COL+(CALC_ROW-1);
            snake_len = 5;
            for (si = 0; si < CALC_COL*CALC_ROW; si = si +1 ) begin
                if(si >= snake_len) begin
                    snake_pos[si] = NULL;
                end
            end

            for (si = 0; si < CALC_COL*CALC_ROW; si = si + 1) begin
                snake_temp[si] = snake_pos[si];
            end
        end
        else if (timer && ~game_ended) begin
            if (direction[0]) begin //UP
                collided <= (snake_pos[0] < CALC_COL);
                if (~collided) 
                    snake_temp[0] = snake_pos[0] - CALC_COL;

            end else 
            if (direction[1]) begin //RIGHT
                collided <= ((snake_pos[0] + 1)%CALC_COL == 0);
                if (~collided) 
                    snake_temp[0] = snake_pos[0] + 1;

            end else
            if (direction[2]) begin //DOWN
                collided <= ((snake_pos[0] ) >= CALC_COL*(CALC_ROW-1));
                if (~collided) 
                    snake_temp[0] = snake_pos[0] + CALC_COL;

            end else begin //LEFT, which is also the default direction
                collided <= ((snake_pos[0]%CALC_COL) == 0);
                if (~collided)
                    snake_temp[0] = snake_pos[0] - 1;
            end

            if (~collided) begin
                for (i = 0; i < CALC_COL*CALC_ROW-1; i = i + 1) begin
                    if(i >= snake_len)
                        snake_pos[i] = NULL;
                    else begin
                        snake_temp[i+1] = snake_pos[i];
                    end
                end
            end
        end

        for (i = 0; i < CALC_COL*CALC_ROW; i = i + 1) begin
            snake_pos[i] = snake_temp[i];
        end
    end

    always @(posedge clk) begin
        if (~reset_n) begin
            game_ended = 0;
        end else begin
            if (game_ended || collided) begin
                game_ended = 1;
            end
        end
    end

endmodule
