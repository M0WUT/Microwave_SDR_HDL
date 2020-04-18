`timescale 1ns / 1ps
`default_nettype none
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: M0WUT
// 
// Create Date: 18.04.2020 13:52:27
// Design Name: 
// Module Name: fft_repeating_buffer
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Buffers data to an FFT but allows for data overlap in the time 
//  domain to reduce the sample rate required. Input data is read on the rising
//  edge. Output data should be read on the rising edge. Note this does not support
//  back pressure. An external FIFO should be used before the FFT
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module fft_repeating_buffer #(
    DATA_WIDTH = 16,
    FFT_LENGTH = 2048,  // Must be a power of two
    NEW_SAMPLES_PER_FFT = 512
)(
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S_AXIS TDATA" *)
    input wire [DATA_WIDTH - 1 : 0] i_data, // Transfer Data (optional)
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 S_AXIS TVALID" *)
    input wire i_valid, // Transfer valid (required)

    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 M_AXIS TDATA" *)
    output reg [DATA_WIDTH - 1 : 0] o_data, // Transfer Data (optional)
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 M_AXIS TVALID" *)
    output reg o_valid, // Transfer valid (required)

    
    (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 i_clk CLK" *)
    (* X_INTERFACE_PARAMETER = "ASSOCIATED_BUSIF S_AXIS : M_AXIS, ASSOCIATED_RESET i_resetn" *)
    input wire i_clk,
    input wire i_resetn
);

reg[DATA_WIDTH - 1 : 0] r_data [FFT_LENGTH * 2 - 1 : 0]; // Buffer twice the length of the FFT

localparam counterWidth = $clog2(FFT_LENGTH) + 1;

reg[counterWidth - 1 : 0] r_writeLocation = 0;
reg[counterWidth - 1 : 0] r_samplesRcvd = 0;
reg[counterWidth - 1 : 0] r_fftStartLocation = 0;
reg[counterWidth - 1 : 0] r_readLocation = 0;
reg [$clog2(FFT_LENGTH) - 1 : 0] r_samplesSent = 0;
reg r_startSending = 0;
reg r_sending = 0;


// Reading stuff in
always @(posedge i_clk or negedge i_resetn) begin
    if(~i_resetn) begin
        r_writeLocation <= 0;
        r_samplesRcvd <= 0;
        r_startSending <= 0;
    end else begin
        if(i_valid) begin
            // Add input data to r_data
            r_data[r_writeLocation] = i_data;
            if(r_writeLocation == FFT_LENGTH * 2 - 1) begin
                r_writeLocation <= 0;
            end else begin
                r_writeLocation <= r_writeLocation + 1;
            end
            
            //Check if we have enough samples to output data
            if(r_samplesRcvd == NEW_SAMPLES_PER_FFT - 1) begin
                r_startSending <= 1;
                r_samplesRcvd <= 0;
            end else begin
                r_startSending <= 0;
                r_samplesRcvd <= r_samplesRcvd + 1;
            end
        end else begin
            r_startSending <= 0;
        end
    end
end

// Output stuff
always @(negedge i_clk or negedge i_resetn) begin
    if(~i_resetn) begin
        r_samplesSent = 0;
        r_fftStartLocation <= NEW_SAMPLES_PER_FFT;
        r_readLocation <= 0;
        o_valid <= 0;
        o_data <= 0;
    end else begin
        if (r_sending == 1) begin
            o_data <= r_data[r_readLocation];
            o_valid <= 1;
            if(r_samplesSent == FFT_LENGTH - 1) begin
                r_sending <= 0;
                r_fftStartLocation <= r_fftStartLocation + NEW_SAMPLES_PER_FFT;
            end else begin
                r_samplesSent <= r_samplesSent + 1;
                r_readLocation <= r_readLocation + 1;
            end


        end else begin
            // Wait for r_startSending
            if (r_startSending == 1) begin
                r_sending <= 1;
                r_readLocation <= r_fftStartLocation;
                r_samplesSent <= 0;
            end else begin
                r_sending <= 0;
            end
            o_data <= 0;
            o_valid <= 0;
        end   
    end
end             





endmodule