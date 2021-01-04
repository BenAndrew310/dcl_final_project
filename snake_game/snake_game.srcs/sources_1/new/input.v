module _input(
input  clk,
input  reset_n,
input  [3:0] usr_btn,

output [3:0]direction
);

wire [3:0]   direction;
reg  [3:0]   direction_reg;

assign direction = (|usr_btn)?usr_btn:direction_reg;
always @(posedge clk) begin
    if (~reset_n) begin
        direction_reg = {0,0,0,1};
    end
    direction_reg = direction;
end
endmodule