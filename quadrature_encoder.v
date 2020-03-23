`timescale 1ns / 1ps
`default_nettype none
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 23.03.2020 20:04:07
// Design Name: 
// Module Name: quadrature_encoder
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


module quadrature_encoder(
    input wire i_clk,
    input wire i_resetn,
    input wire i_a,
    input wire i_b,
    input wire i_sw,

    output reg o_up,
    output reg o_down,
    output reg o_switch,
    output reg [31:0] r_counter  // DEBUG
);

reg r_oldA;
reg r_oldSw;


always @(negedge i_clk or negedge i_resetn) begin
    if(~i_resetn) begin
        o_up <= 0;
        o_down <= 0;
        o_switch <= 0;
    end else begin  
        if(~r_oldA && i_a) begin
            // Rising edge on A
            if(i_b) begin
                o_down <= 1;
            end else begin
                o_up <= 1;
            end
        end else begin
            o_up <= 0;
            o_down <= 0;
        end

        r_oldA <= i_a;

        if(~r_oldSw && i_sw) begin
            o_switch <= 1;
        end else begin
            o_switch <= 0;
        end

        r_oldSw <= i_sw;
    end
end

always @(posedge i_clk) begin
    if(o_up) begin
        r_counter <= r_counter + 1;
    end else if (o_down) begin
        r_counter <= r_counter - 1;
    end else begin
        r_counter <= r_counter;
    end
end

endmodule
