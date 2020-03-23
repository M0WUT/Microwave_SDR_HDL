`timescale 1ns / 1ps
`default_nettype none
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: M0WUT
// 
// Create Date: 25.02.2020 20:29:15
// Design Name: 
// Module Name: adau1361_handler
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Drives ADAU1361 Audio ADC/DAC
//              Doesn't handle I2C register setup, waits for i_enable to go
//              high, will assume everything is fine and chuck data out
//
//              Currently just creates clock signals with correct timing
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module adau1361_handler #(
    MCLK_DIVIDER = 8  // How much to divide i_clk to generate MCLK
)(
    input wire i_clk,  // Main clock
    input wire i_resetn,  // Active low reset input
    input wire i_enable,
    input wire i_valid,
    input wire [15:0] i_leftData,
    input wire [15:0] i_rightData,
    output wire o_mclk,
    output wire o_bclk,
    output wire o_lrclk,
    output wire o_afDacData
);



// o_mclk should run at 256 x fs
// o_bclk should run at 32 x fs (16 bits per channel per sample * 2 channels)
// o_lrclk should run at fs (one sample per sample)

// so need 8 bonus bits to perform extra division by 256 for o_lrclk

reg [$clog2(MCLK_DIVIDER) + 8 - 1 : 0] r_dividerCounter = 0;
reg r_started = 0;

always @(negedge i_clk or negedge i_resetn) begin
    // Used to initially sync clock divider with valid signal
    if(i_valid) begin
        r_started <= 1;
    end else begin
        r_started <= r_started;
    end
    
    if(~i_resetn | ~r_started) begin
        r_dividerCounter <= 0;
    end else begin
        r_dividerCounter <= r_dividerCounter + 1;
    end
end

assign o_lrclk = i_enable & ~r_dividerCounter[$clog2(MCLK_DIVIDER) + 8 - 1];  // MSB of r_dividerCounter
assign o_bclk = i_enable & r_dividerCounter[$clog2(MCLK_DIVIDER) + 8 - 6];  // 5 bits in from MSB (32 times faster)
assign o_mclk = r_dividerCounter[$clog2(MCLK_DIVIDER) + 8 - 9];  // 8 bits in from MSB (256 times faster)

reg [31:0] r_afData = 0;
reg [5:0] r_bitCounter = 0;

assign o_afDacData = r_afData[r_bitCounter];

always @(negedge o_bclk or negedge i_resetn) begin
    if(~i_resetn) begin
        r_afData <= 0;
        r_bitCounter <= 0;
    end else begin
         if(r_bitCounter == 0) begin
            if(i_valid) begin
                r_afData <= {i_leftData, i_rightData};
                r_bitCounter <= 31;
            end
        end else begin
            r_bitCounter <= r_bitCounter - 1;
        end   
    end
end
endmodule
