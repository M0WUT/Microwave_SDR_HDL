`timescale 1ns / 1ps
`default_nettype none
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: M0WUT
// 
// Create Date: 15.02.2020 09:59:21
// Design Name: 
// Module Name: phase_accumulator
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description:     Ouput o_phaseAngle is a angle scaled to 32 bits. i.e. 2^32 is 1 complete rotation, 0 is no rotation
//                  o_phaseAngle is increased on every posedge of i_adcClock by i_phaseDelta which is expected to use the 
//                  same units
// 
// Dependencies:    
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module phase_accumulator(
    input wire i_adcClock,
    input wire [31:0] i_phaseDelta,
    input wire i_resetn,
    output reg [31:0] o_phaseAngle
);

always @(posedge i_adcClock or negedge i_resetn) begin
    if(~i_resetn) begin
        o_phaseAngle <= -32'b0;
    end else begin
        o_phaseAngle <= o_phaseAngle + i_phaseDelta;
    end
end

endmodule
