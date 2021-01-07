module _input(
input  clk,
input  reset_n,
input  [3:0] usr_btn,

output [3:0]direction,
output reg game_started
);

reg  [3:0]   direction_reg;

localparam UP       = 4'b1000;
localparam RIGHT    = 4'b0100;
localparam DOWN     = 4'b0010;
localparam LEFT     = 4'b0001;

// if usr_btn was clicked once, game started
always @(posedge clk) begin
    if (~reset_n) begin
        game_started = 0;
    end else begin
        if (game_started || (|usr_btn)) begin
            game_started = 1;
        end
    end
end

/**
  * snake is going left at the very beginning, this logic is 
  * written in here and in logic.v
  */
always @(posedge clk) begin
    if (~reset_n) begin
        direction_reg = {1'b0,1'b0,1'b0,1'b1};
    end
    direction_reg = direction;
end

reg [3:0]usr_btn_one;
reg [3:0]usr_btn_one_temp;
integer i, j;
always @(posedge clk) begin
    if (~reset_n) begin
        usr_btn_one = 0;
    end else begin
        //make usr_btn have only one "1" and others are "0"
        for (i = 0; i < 4; i = i + 1) begin
            usr_btn_one_temp[i] = usr_btn[i];
            if (usr_btn[i]) begin
                for (j = 0; j < 4; j = j + 1) begin
                    if ( i != j) 
                        usr_btn_one_temp[j] = 0;
                end
            end
        end

        //opposite direction prevention
        if ((usr_btn_one_temp == UP) && (direction_reg == DOWN))
            usr_btn_one <= DOWN;
        else if ((usr_btn_one_temp == DOWN) && (direction_reg == UP))
            usr_btn_one <= UP;
        else if ((usr_btn_one_temp == RIGHT) && (direction_reg == LEFT))
            usr_btn_one <= LEFT;
        else if ((usr_btn_one_temp == LEFT) && (direction_reg == RIGHT))
            usr_btn_one <= RIGHT; 
        else if (usr_btn_one_temp != 0)
            usr_btn_one <= usr_btn_one_temp;
    end
end

assign direction = (|usr_btn) ? usr_btn_one : direction_reg;

endmodule