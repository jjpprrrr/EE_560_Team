`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Course: EE560 
// 
// 
// Create Date:    21:43:27 05/20/2013 
// Design Name: 32-bit Parity Generator 
// Module Name:    parity 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module parity(in_data, parity);

	//inputs
	input[31:0] in_data;
	
	//outputs
	output parity;
	
	//declarations
	reg parity;
	integer i;
	
	
	//parity generator 
	always @(*) begin
		parity = 0; 
		for (i=0; i<32; i=i+1) begin
			parity = parity ^ in_data[i];
		end
	end


endmodule
