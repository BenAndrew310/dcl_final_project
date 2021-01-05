module _input(
input  clk,
input  reset_n,
input  [3:0] usr_btn,

output [3:0]direction
);

reg  [3:0]   direction_reg;

localparam UP       = 4'b1000;
localparam RIGHT    = 4'b0100;
localparam DOWN     = 4'b0010;
localparam LEFT     = 4'b0001;

assign direction = (|usr_btn)?usr_btn:direction_reg;

always @(posedge clk) begin
    if (~reset_n) begin
        direction_reg = {1'b0,1'b0,1'b0,1'b1};
    end
    direction_reg = direction;
end
endmodule