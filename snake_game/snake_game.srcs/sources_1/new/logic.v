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
                NULL = TILE_EMPTY;

    //snake array
    reg [7:0] snake_pos[CALC_COL*CALC_ROW-1:0];
    reg [7:0] snake_pos_temp[CALC_COL*CALC_ROW-1:0];
    reg [4:0] snake_tile_type[CALC_COL*CALC_ROW-1:0];
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
    localparam TICK_PER_CLK = 70000000;
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
            if (i < snake_len) begin
                calc_map[snake_pos[i]] = snake_tile_type[i];
            end
        end
        
        //apple
        calc_map[CALC_COL*3+1] = APPLE;
        //todo
    end

    integer si;
    reg collided;
    reg _move;
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
                snake_pos_temp[si] = snake_pos[si];
            end
        end
        else if (~game_ended) begin
            if (timer && game_started) begin
                if (direction[0]) begin //UP
                    collided <= (snake_pos[0] < CALC_COL);
                end else 
                if (direction[1]) begin //RIGHT
                    collided <= ((snake_pos[0] + 1)%CALC_COL == 0);
                end else
                if (direction[2]) begin //DOWN
                    collided <= ((snake_pos[0] ) >= CALC_COL*(CALC_ROW-1));
                end else 
                if (direction[3]) begin
                    collided <= ((snake_pos[0]%CALC_COL) == 0);
                end
                _move = ~collided;
            end
            if (_move && ~timer) begin //seperate collide dectection and move in clk

                if (direction[0]) begin //UP
                    if (~collided) 
                        snake_pos_temp[0] = snake_pos[0] - CALC_COL;
                end else 
                if (direction[1]) begin //RIGHT
                    if (~collided) 
                        snake_pos_temp[0] = snake_pos[0] + 1;

                end else
                if (direction[2]) begin //DOWN
                    if (~collided) 
                        snake_pos_temp[0] = snake_pos[0] + CALC_COL;

                end else begin //LEFT, which is also the default direction
                    if (~collided)
                        snake_pos_temp[0] = snake_pos[0] - 1;
                end

                for (i = 0; i < CALC_COL*CALC_ROW-1; i = i + 1) begin
                    if(i >= snake_len)
                        snake_pos[i] = NULL;
                    else begin
                        snake_pos_temp[i+1] = snake_pos[i];
                    end
                end
                _move = 0;
            end
            for (i = 0; i < CALC_COL*CALC_ROW; i = i + 1) begin
                snake_pos[i] = snake_pos_temp[i];
            end
        end
    end

    localparam UP       = 8'b11110010; //-CALC_COL
    localparam RIGHT    = 8'b00000001; //1
    localparam DOWN     = 8'b00001110; //CALC_COL
    localparam LEFT     = 8'b11111111; //-1

    //snake tile type
    integer ti;
    reg [7:0]left_snake_body_direction[CALC_ROW*CALC_COL-1:0];
    reg [7:0]right_snake_body_direction[CALC_ROW*CALC_COL-1:0];
    always @(posedge clk) begin
        if (~reset_n) begin
            for (ti = 0; ti < CALC_COL*CALC_ROW; ti = ti + 1) begin
                snake_tile_type[ti] = NULL;
            end
            snake_tile_type[0] = SNAKE_H_B;
            snake_tile_type[1] = SNAKE_B_V;
            snake_tile_type[2] = SNAKE_B_V;
            snake_tile_type[3] = SNAKE_B_V;
            snake_tile_type[4] = SNAKE_T_T;
        end else begin
            if      (snake_pos[0] - snake_pos[1] == LEFT) //LEFT
                snake_tile_type[0] = SNAKE_H_R;
            else if (snake_pos[0] - snake_pos[1] == RIGHT) //RIGHT
                snake_tile_type[0] = SNAKE_H_L;
            else if (snake_pos[0] - snake_pos[1] == UP) //TOP
                snake_tile_type[0] = SNAKE_H_B;
            else if (snake_pos[0] - snake_pos[1] == DOWN) //BOTTOM
                snake_tile_type[0] = SNAKE_H_T;
            
            for (ti = 1; ti < CALC_COL*CALC_ROW-1; ti = ti + 1) begin
                if (ti < snake_len) begin
                    left_snake_body_direction[ti] = snake_pos[ti] - snake_pos[ti-1];
                    right_snake_body_direction[ti] = snake_pos[ti] - snake_pos[ti+1];
                end
            end
            for (ti = 1; ti < CALC_COL*CALC_ROW-1; ti = ti + 1) begin
                if (ti < snake_len-1) begin
                    if (left_snake_body_direction[ti] == LEFT) begin
                        if (right_snake_body_direction[ti] == RIGHT) 
                            snake_tile_type[ti] = SNAKE_B_H;
                        if (right_snake_body_direction[ti] == DOWN)
                            snake_tile_type[ti] = SNAKE_B_T2R;
                        if (right_snake_body_direction[ti] == UP)
                            snake_tile_type[ti] = SNAKE_B_B2R;
                    end
                    if (left_snake_body_direction[ti] == RIGHT) begin
                        if (right_snake_body_direction[ti] == LEFT) 
                            snake_tile_type[ti] = SNAKE_B_H;
                        if (right_snake_body_direction[ti] == DOWN)
                            snake_tile_type[ti] = SNAKE_B_T2L;
                        if (right_snake_body_direction[ti] == UP)
                            snake_tile_type[ti] = SNAKE_B_L2B;
                    end
                    if (left_snake_body_direction[ti] == UP) begin
                        if (right_snake_body_direction[ti] == RIGHT) 
                            snake_tile_type[ti] = SNAKE_B_L2B;
                        if (right_snake_body_direction[ti] == DOWN)
                            snake_tile_type[ti] = SNAKE_B_V;
                        if (right_snake_body_direction[ti] == LEFT)
                            snake_tile_type[ti] = SNAKE_B_B2R;
                    end
                    if (left_snake_body_direction[ti] == DOWN) begin
                        if (right_snake_body_direction[ti] == RIGHT) 
                            snake_tile_type[ti] = SNAKE_B_T2L;
                        if (right_snake_body_direction[ti] == UP)
                            snake_tile_type[ti] = SNAKE_B_V;
                        if (right_snake_body_direction[ti] == LEFT)
                            snake_tile_type[ti] = SNAKE_B_T2R;
                    end
                end else
                    snake_tile_type[ti] = NULL;
            end
            if      (snake_pos[snake_len-1] - snake_pos[snake_len-2] == LEFT) //LEFT
                snake_tile_type[snake_len-1] = SNAKE_T_R;
            else if (snake_pos[snake_len-1] - snake_pos[snake_len-2] == RIGHT) //RIGHT
                snake_tile_type[snake_len-1] = SNAKE_T_L;
            else if (snake_pos[snake_len-1] - snake_pos[snake_len-2] == UP) //TOP
                snake_tile_type[snake_len-1] = SNAKE_T_B;
            else if (snake_pos[snake_len-1] - snake_pos[snake_len-2] == DOWN) //BOTTOM
                snake_tile_type[snake_len-1] = SNAKE_T_T;
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
