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

always @(posedge clk) begin
    if (~reset_n) begin
        direction_reg = 4'b0;
    end
    direction_reg = direction;
end

wire [3:0] debounced_usr_btn;

genvar gi;
generate
  for(gi=0;gi<4;gi=gi+1)begin
    debounce Debounce(
        .clk(clk), .btn_input(usr_btn[gi]), .btn_output(debounced_usr_btn[gi])
    );
  end
endgenerate

reg [3:0]usr_btn_one;
reg [3:0]usr_btn_one_temp;
integer i, j;
always @(posedge clk) begin
    if (~reset_n) begin
        usr_btn_one = 4'b0;
        usr_btn_one_temp = 4'b0;
    end else begin
        //make usr_btn have only one "1" and others are "0"
        for (i = 0; i < 4; i = i + 1) begin
            usr_btn_one_temp[i] = debounced_usr_btn[i];
            if (debounced_usr_btn[i]) begin
                for (j = 0; j < 4; j = j + 1) begin
                    if ( i != j) 
                        usr_btn_one_temp[j] = 0;
                end
            end
        end

        //opposite direction prevention
        if ((usr_btn_one_temp == UP) && (direction_reg == DOWN))
            usr_btn_one <= 4'b0;
        else if ((usr_btn_one_temp == DOWN) && (direction_reg == UP))
            usr_btn_one <= 4'b0;
        else if ((usr_btn_one_temp == RIGHT) && (direction_reg == LEFT))
            usr_btn_one <= 4'b0;
        else if ((usr_btn_one_temp == LEFT) && (direction_reg == RIGHT))
            usr_btn_one <= 4'b0; 
        else if (usr_btn_one_temp != 0)
            usr_btn_one <= usr_btn_one_temp;
    end
end

assign direction = (~reset_n)? 4'b0 : (|usr_btn_one) ? usr_btn_one : direction_reg;

endmodule