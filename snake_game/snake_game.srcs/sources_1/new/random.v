// DEFINES
`timescale 1ns/1ns
`define DEL     1               // Clock-to-output delay. Zero
                                        // time delays can be confusing
                                        // and sometimes cause problems.

                                        // These are good tap values for 2 to 32 bits
`define TAP2    2'b11
`define TAP3    3'b101
`define TAP4    4'b1001
`define TAP5    5'b10010
`define TAP6    6'b100001
`define TAP7    7'b1000001
`define TAP8    8'b10001110
`define TAP9    9'b100001000
`define TAP10   10'b1000000100
`define TAP11   11'b10000000010
`define TAP12   12'b100000101001
`define TAP13   13'b1000000001101
`define TAP14   14'b10000000010101
`define TAP15   15'b100000000000001
`define TAP16   16'b1000000000010110
`define TAP17   17'b10000000000000100
`define TAP18   18'b100000000001000000
`define TAP19   19'b1000000000000010011
`define TAP20   20'b10000000000000000100
`define TAP21   21'b100000000000000000010
`define TAP22   22'b1000000000000000000001
`define TAP23   23'b10000000000000000010000
`define TAP24   24'b100000000000000000001101
`define TAP25   25'b1000000000000000000000100
`define TAP26   26'b10000000000000000000100011
`define TAP27   27'b100000000000000000000010011
`define TAP28   28'b1000000000000000000000000100
`define TAP29   29'b10000000000000000000000000010
`define TAP30   30'b100000000000000000000000101001
`define TAP31   31'b1000000000000000000000000000100
`define TAP32   32'b10000000000000000000000001100010

`define BITS 8  // Number of bits in the LFSR
`define TAPS `TAP8      // This must be the taps for the
                                        // number of bits specified above
// `define INIT 1          // This can be any non-zero value
//                                         // for initialization of the LFSR

// TOP MODULE
module random(input clk, input reset_n, input [7:0]init, output [`BITS-1:0] data);

reg [`BITS-1:0] _data;
assign data = _data;
// MAIN CODE

    // Look at the rising edge of clock or reset
    always @(posedge clk) begin
            if (~reset_n)
                    _data <= #`DEL init;
            else begin
                    // Shift all of the bits left
                    _data[`BITS-1:1] <= #`DEL _data[`BITS-2:0];

    `ifdef ADD_ZERO                 // Use this code if data == 0 is required
                    // Create the new bit 0
                    _data[0] <= #`DEL ^(_data & `TAPS) ^ ~|_data[`BITS-2:0];
    `else                                   // Use this code for a standard LFSR
                    // Create the new bit 0
                    _data[0] <= #`DEL ^(_data & `TAPS);
    `endif

            end
    end
endmodule