`timescale 1ns / 1ps
`default_nettype none
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: M0WUT
// 
// Create Date: 15.02.2020 12:30:33
// Design Name: 
// Module Name: cordic
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module cordic #(

    DATA_WIDTH = 16,
    ITERATIONS = 16
)(
    input wire i_clk,
    input wire i_resetn,
    input wire signed [DATA_WIDTH - 1:0] i_xIn,
    input wire signed [DATA_WIDTH - 1:0] i_yIn,
    input wire signed [31:0] i_angle,

    output reg signed [DATA_WIDTH - 1:0] o_xOut, 
    output reg signed [DATA_WIDTH - 1:0] o_yOut
);

localparam ANGLE_WIDTH = 32; // Doesn't nicely handle this changing yet.  

reg signed [DATA_WIDTH:0] r_x [ITERATIONS:0];
reg signed [DATA_WIDTH:0] r_y [ITERATIONS:0];
reg signed [31:0] r_angleErrors [ITERATIONS:0];


// This table is larger than we require, just saves re-generating
// it later if I change anything
wire signed[30:0] w_cordicAngles [ANGLE_WIDTH - 1:0];
assign w_cordicAngles[00] = 32'b00100000000000000000000000000000;
assign w_cordicAngles[01] = 32'b00010010111001000000010100011110;
assign w_cordicAngles[02] = 32'b00001001111110110011100001011011;
assign w_cordicAngles[03] = 32'b00000101000100010001000111010100;
assign w_cordicAngles[04] = 32'b00000010100010110000110101000011;
assign w_cordicAngles[05] = 32'b00000001010001011101011111100001;
assign w_cordicAngles[06] = 32'b00000000101000101111011000011110;
assign w_cordicAngles[07] = 32'b00000000010100010111110001010101;
assign w_cordicAngles[08] = 32'b00000000001010001011111001010011;
assign w_cordicAngles[09] = 32'b00000000000101000101111100101111;
assign w_cordicAngles[10] = 32'b00000000000010100010111110011000;
assign w_cordicAngles[11] = 32'b00000000000001010001011111001100;
assign w_cordicAngles[12] = 32'b00000000000000101000101111100110;
assign w_cordicAngles[13] = 32'b00000000000000010100010111110011;
assign w_cordicAngles[14] = 32'b00000000000000001010001011111010;
assign w_cordicAngles[15] = 32'b00000000000000000101000101111101;
assign w_cordicAngles[16] = 32'b00000000000000000010100010111110;
assign w_cordicAngles[17] = 32'b00000000000000000001010001011111;
assign w_cordicAngles[18] = 32'b00000000000000000000101000110000;
assign w_cordicAngles[19] = 32'b00000000000000000000010100011000;
assign w_cordicAngles[20] = 32'b00000000000000000000001010001100;
assign w_cordicAngles[21] = 32'b00000000000000000000000101000110;
assign w_cordicAngles[22] = 32'b00000000000000000000000010100011;
assign w_cordicAngles[23] = 32'b00000000000000000000000001010001;
assign w_cordicAngles[24] = 32'b00000000000000000000000000101001;
assign w_cordicAngles[25] = 32'b00000000000000000000000000010100;
assign w_cordicAngles[26] = 32'b00000000000000000000000000001010;
assign w_cordicAngles[27] = 32'b00000000000000000000000000000101;
assign w_cordicAngles[28] = 32'b00000000000000000000000000000011;
assign w_cordicAngles[29] = 32'b00000000000000000000000000000001;
assign w_cordicAngles[30] = 32'b00000000000000000000000000000001;



// Loading new data into CORDIC
always @(posedge i_clk or negedge i_resetn) begin
    if(~i_resetn) begin
        r_x[0] <= 0;
        r_y[0] <= 0;
        r_angleErrors[0] <= 0;
    end else begin
        // Copy new data into first position in the pipeline
        // CORDIC on works in the range -90<x<90 degrees so need to pre-rotate at start
        // Luckily top 2 bits in i_angle divide the circle into the 4 quadrants
        // 00: 0<=x<90
        // 01: 90<=x<180
        // 10: 180<=x<270
        // 11: 270<=x<360

        case(i_angle[ANGLE_WIDTH - 1 -: 2])
            // These two are valid inputs to CORDIC
            2'b00: begin
                r_x[0] <= i_xIn;
                r_y[0] <= i_yIn;
                r_angleErrors[0] <= i_angle;
            end
            
            2'b11: begin
                r_x[0] <= i_xIn;
                r_y[0] <= i_yIn;
                r_angleErrors[0] <= i_angle;
            end  

            2'b01: begin
                // 90<=x<180

                // Perform manual rotation of 90 degrees
                r_x[0] <= -i_yIn;
                r_y[0] <= i_xIn;
                // Subtract 90 from angle to be rotated by
                r_angleErrors[0] <= {2'b00, i_angle[ANGLE_WIDTH - 3:0]};
            end

            2'b10: begin
                // 180<=x<270

                // Perform manual rotation of -90 degrees
                r_x[0] <= i_yIn;
                r_y[0] <= -i_xIn; 

                // Add 90 degrees to the angle to be rotated by
                r_angleErrors[0] <= {2'b11, i_angle[ANGLE_WIDTH - 3:0]};
            end
        endcase
    end
end

// Generating all of the stages of the CORDIC
genvar i;
generate
    for(i = 0; i < ITERATIONS; i = i + 1) begin
        always @(posedge i_clk) begin
            if(r_angleErrors[i] > 0) begin
                // We need to perform a positive rotation
                r_x[i+1] <= r_x[i] - (r_y[i] >>> i);
                r_y[i+1] <= r_y[i] + (r_x[i] >>> i);
                // Update angle
                r_angleErrors[i+1] <= r_angleErrors[i] - w_cordicAngles[i];
            end else begin
                // We need to perform a positive rotation
                r_x[i+1] <= r_x[i] + (r_y[i] >>> i);
                r_y[i+1] <= r_y[i] - (r_x[i] >>> i);
                // Update angle
                r_angleErrors[i+1] <= r_angleErrors[i] + w_cordicAngles[i];
            end
        end
    end
endgenerate

always @(negedge i_clk) begin
    o_xOut <= r_x[ITERATIONS][DATA_WIDTH: 1];
    o_yOut <= r_y[ITERATIONS][DATA_WIDTH: 1];
end




endmodule
