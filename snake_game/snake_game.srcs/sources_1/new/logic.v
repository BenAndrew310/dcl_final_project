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
    //apple
    reg [7:0]apple_pos;


    //for view module
    reg [4:0] map [COLUMN*ROW-1:0];
    //for calculation
    reg [4:0] calc_map [CALC_COL*CALC_ROW-1:0];

    reg [3:0]STATE;
    reg [3:0]NEXT_S;
    localparam  S_IDLE = 0,
                S_CHECK_COLLIDE = 1,
                S_MOVE = 2,
                S_DIR_CALC = 3,
                S_TILE_CALC = 4,
                S_EMPTY_TILE_COUNT = 5,
                S_NEW_APPLE = 6,
                S_DISPLAY = 7;
                
    always @(posedge clk)begin
        if(~reset_n)
            STATE <= S_IDLE;
        else
            STATE <= NEXT_S;
    end

    always@(*)begin
        case(STATE)
            S_IDLE:
                if (timer)  NEXT_S = S_CHECK_COLLIDE;
            S_CHECK_COLLIDE:
                if (~game_ended) NEXT_S = S_MOVE;
            S_MOVE:
                if(moved) NEXT_S = S_DIR_CALC;
            S_DIR_CALC:
                if (direction_calculated) NEXT_S = S_TILE_CALC;
            S_TILE_CALC:
                if (tile_calculated) 
                    if (apple_eaten) NEXT_S = S_EMPTY_TILE_COUNT;
                    else NEXT_S = S_DISPLAY;
            S_EMPTY_TILE_COUNT:
                if (empty_tile_counted) NEXT_S = S_NEW_APPLE;
            S_NEW_APPLE:
                NEXT_S = S_DISPLAY;
            S_DISPLAY:
                if (display_finished) NEXT_S = S_IDLE;
            default:
                NEXT_S = S_IDLE;
        endcase
    end

    //flatten map
    genvar fi;
    generate for (fi=0; fi<COLUMN*ROW; fi=fi+1) begin
      assign flattened_map[5*fi+5-1:5*fi] = map[fi];
    end endgenerate

    //timer
    wire timer;
    reg [27:0] counter;
    localparam TICK_PER_CLK = 40000000;
    always @(posedge clk) begin
        counter = (counter <= TICK_PER_CLK)? counter + 1: 0;
    end
    assign timer = counter == TICK_PER_CLK;

    //put calc_map in the middle of map
    integer i, j;
    always @(*) begin
        for (i=0; i < CALC_COL; i = i + 1) begin
            for (j = 0; j < CALC_ROW; j = j+1) begin
                map[(i+1)+(j+1)*COLUMN] = calc_map[i+j*CALC_COL];
            end
        end
    end

    initial begin
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
    end

    //calc_map
    always @(posedge clk) begin
        if (STATE == S_DISPLAY) begin
            for (i = 0; i < CALC_COL*CALC_ROW; i = i + 1) begin
                calc_map[i] = TILE_EMPTY;
            end

            //snake
            for (i = 0; i < CALC_COL*CALC_ROW; i = i + 1) begin
                if (i < snake_len) begin
                    calc_map[snake_pos[i]] = snake_tile_type[i];
                end
            end
            
            //apple
            calc_map[apple_pos] = APPLE;
        end
    end


    wire [7:0] random_number;
    random Random( .o(random_number), .clk(clk));
    wire apple_eaten;
    assign apple_eaten = snake_pos[0] == apple_pos;

    wire tile_count_finished;
    reg [7:0] apple_rand_pos;
    reg [7:0] apple_pos_pointer;

    wire [7:0]empty_tile_count_counter;
    reg [7:0]empty_tile_count_counter_reg;
    assign empty_tile_count_counter = apple_eaten ? empty_tile_count_counter_reg : 0;
    assign empty_tile_counted = empty_tile_count_counter == apple_rand_pos;
    always @(posedge clk) begin
        if (~reset_n) begin
            apple_pos = 3*CALC_COL+4;
            snake_len = 5;
        end
        if (STATE == S_TILE_CALC && NEXT_S = S_EMPTY_TILE_COUNT) begin
            apple_rand_pos = random_number%(CALC_COL*CALC_ROW - snake_len-1);
        end
        if (STATE == S_EMPTY_TILE_COUNT) begin
            apple_pos_pointer = apple_pos_pointer + 1;
            empty_tile_count_counter_reg = empty_tile_count_counter_reg + (calc_map[empty_tile_count_counter] == TILE_EMPTY);
            
        end
    end

    always @(posedge clk) begin
        if (STATE == S_NEW_APPLE) begin
            //new apple
            //snake len
        end
    end

    reg collided;
    always @(posedge clk) begin
        if (timer && game_started && (~game_ended)) begin
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
        end
    end

    integer si;
    reg [7:0]body_forward_counter;
    reg had_move;
    wire moved;
    assign moved = body_forward_counter == CALC_COL*CALC_ROW-1;
    always @(posedge clk) begin
        if (~reset_n || ~game_started) begin
            collided <= 0;
            snake_pos[0] <= (2-1)*CALC_COL+(CALC_ROW-1);
            snake_pos[1] <= (3-1)*CALC_COL+(CALC_ROW-1);
            snake_pos[2] <= (4-1)*CALC_COL+(CALC_ROW-1);
            snake_pos[3] <= (5-1)*CALC_COL+(CALC_ROW-1);
            snake_pos[4] <= (6-1)*CALC_COL+(CALC_ROW-1);
            for (si = 5; si < CALC_COL*CALC_ROW; si = si +1 ) begin
                snake_pos[si] = NULL;
            end
            had_move = 0;
        end
        else begin
            if (STATE == S_MOVE) begin //seperate collide dectection and move in clk
                if (~had_move) begin
                    if (direction[0]) begin //UP
                        snake_pos_temp[0] = snake_pos[0] - CALC_COL;
                    end else 
                    if (direction[1]) begin //RIGHT
                        snake_pos_temp[0] = snake_pos[0] + 1;

                    end else
                    if (direction[2]) begin //DOWN
                        snake_pos_temp[0] = snake_pos[0] + CALC_COL;

                    end else 
                    if (direction[3]) begin //LEFT
                        snake_pos_temp[0] = snake_pos[0] - 1;
                    end
                end

                if(body_forward_counter >= snake_len)
                    snake_pos[body_forward_counter] = NULL;
                else begin
                    snake_pos_temp[body_forward_counter+1] = snake_pos[body_forward_counter];
                end
                body_forward_counter = body_forward_counter + 1;
                if (moved) begin
                    for (i = 0; i < CALC_COL*CALC_ROW; i = i + 1) begin
                        snake_pos[i] = snake_pos_temp[i];
                    end
                end
            end else
                body_forward_counter = 0;
        end
    end

    localparam UP       = 8'b11110010; //-CALC_COL
    localparam RIGHT    = 8'b00000001; //1
    localparam DOWN     = 8'b00001110; //CALC_COL
    localparam LEFT     = 8'b11111111; //-1

    //snake tile type
    reg [7:0]left_snake_body_direction[CALC_ROW*CALC_COL-1:0];
    reg [7:0]right_snake_body_direction[CALC_ROW*CALC_COL-1:0];
    reg [7:0]direction_calc_counter;
    wire direction_calc_finished;
    assign direction_calc_finished = direction_calc_counter == snake_len-1;

    wire body_tile_applied;
    reg [7:0]body_tile_counter;
    assign body_tile_applied = body_tile_counter == snake_len-1;

    always @(posedge clk) begin
        //body left, right calculation
        if (body_tile_applied) begin
            direction_calc_counter = 1;
        end
        if (~direction_calc_finished) begin
            left_snake_body_direction[direction_calc_counter] = snake_pos[direction_calc_counter] - snake_pos[direction_calc_counter-1];
            right_snake_body_direction[direction_calc_counter] = snake_pos[direction_calc_counter] - snake_pos[direction_calc_counter+1];
            direction_calc_counter = direction_calc_counter + 1;
        end
    end

    always @(posedge clk) begin
        //head
        if      (snake_pos[0] - snake_pos[1] == LEFT) //LEFT
            snake_tile_type[0] = SNAKE_H_R;
        else if (snake_pos[0] - snake_pos[1] == RIGHT) //RIGHT
            snake_tile_type[0] = SNAKE_H_L;
        else if (snake_pos[0] - snake_pos[1] == UP) //TOP
            snake_tile_type[0] = SNAKE_H_B;
        else if (snake_pos[0] - snake_pos[1] == DOWN) //BOTTOM
            snake_tile_type[0] = SNAKE_H_T;
        
        if (body_tile_applied && direction_calc_finished) begin
            body_tile_counter = 1;
        end

        if (direction_calc_finished) begin
            if (left_snake_body_direction[body_tile_counter] == LEFT) begin
                if (right_snake_body_direction[body_tile_counter] == RIGHT) 
                    snake_tile_type[body_tile_counter] = SNAKE_B_H;
                if (right_snake_body_direction[body_tile_counter] == DOWN)
                    snake_tile_type[body_tile_counter] = SNAKE_B_T2R;
                if (right_snake_body_direction[body_tile_counter] == UP)
                    snake_tile_type[body_tile_counter] = SNAKE_B_B2R;
            end
            if (left_snake_body_direction[body_tile_counter] == RIGHT) begin
                if (right_snake_body_direction[body_tile_counter] == LEFT) 
                    snake_tile_type[body_tile_counter] = SNAKE_B_H;
                if (right_snake_body_direction[body_tile_counter] == DOWN)
                    snake_tile_type[body_tile_counter] = SNAKE_B_T2L;
                if (right_snake_body_direction[body_tile_counter] == UP)
                    snake_tile_type[body_tile_counter] = SNAKE_B_L2B;
            end
            if (left_snake_body_direction[body_tile_counter] == UP) begin
                if (right_snake_body_direction[body_tile_counter] == RIGHT) 
                    snake_tile_type[body_tile_counter] = SNAKE_B_L2B;
                if (right_snake_body_direction[body_tile_counter] == DOWN)
                    snake_tile_type[body_tile_counter] = SNAKE_B_V;
                if (right_snake_body_direction[body_tile_counter] == LEFT)
                    snake_tile_type[body_tile_counter] = SNAKE_B_B2R;
            end
            if (left_snake_body_direction[body_tile_counter] == DOWN) begin
                if (right_snake_body_direction[body_tile_counter] == RIGHT) 
                    snake_tile_type[body_tile_counter] = SNAKE_B_T2L;
                if (right_snake_body_direction[body_tile_counter] == UP)
                    snake_tile_type[body_tile_counter] = SNAKE_B_V;
                if (right_snake_body_direction[body_tile_counter] == LEFT)
                    snake_tile_type[body_tile_counter] = SNAKE_B_T2R;
            end
            body_tile_counter = body_tile_counter + 1;
        end

        //tail
        if      (snake_pos[snake_len-1] - snake_pos[snake_len-2] == LEFT) //LEFT
            snake_tile_type[snake_len-1] = SNAKE_T_R;
        else if (snake_pos[snake_len-1] - snake_pos[snake_len-2] == RIGHT) //RIGHT
            snake_tile_type[snake_len-1] = SNAKE_T_L;
        else if (snake_pos[snake_len-1] - snake_pos[snake_len-2] == UP) //TOP
            snake_tile_type[snake_len-1] = SNAKE_T_B;
        else if (snake_pos[snake_len-1] - snake_pos[snake_len-2] == DOWN) //BOTTOM
            snake_tile_type[snake_len-1] = SNAKE_T_T;
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
