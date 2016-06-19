////////////////////////////////////////////////////////////
//// File: router.v
//// Author: Aparna Srinivasan
//// Version: 0.0
//// Date: 23rd April 2014
//// Description: This router has five input buffers and five out put buffers.	
////							Packets from input buffers are routed to output buffers throuth
////							the module routing_logic.
//// Updated by Yiheng Guo, 04/2015
//////////////////////////////////////////////////////////////

/*
	1: xp direction
	2: xn direction
	3: yp direction
	4: yn direction
	5: PE
	
	in: 	input buffer
	out: 	output buffer
*/

module router ( clk, reset, 
				in_valid1, 	in_valid2, 	in_valid3, 	in_valid4, 	in_valid5, 			 	
				in_din1, 		in_din2, 		in_din3, 		in_din4,		in_din5,
				in_ready1, 	in_ready2, 	in_ready3, 	in_ready4, 	in_ready5,
				out_ready1,	out_ready2, out_ready3, out_ready4, out_ready5,
 			  out_valid1, 	out_valid2, 	out_valid3, 	out_valid4, 	out_valid5,
				out_dout1, 	out_dout2, 	out_dout3, 	out_dout4, 	out_dout5
				);


input 	clk, reset;
input 	[31:0] in_din1, in_din2, in_din3, in_din4;
input 	[159:0] in_din5;
input 	in_valid1, in_valid2, in_valid3, in_valid4, in_valid5, out_ready1,out_ready2, out_ready3, out_ready4, out_ready5;
output 	in_ready1, in_ready2, in_ready3, in_ready4, in_ready5, out_valid1, out_valid2, out_valid3, out_valid4, out_valid5;
output	[31:0] out_dout1, out_dout2, out_dout3, out_dout4;
output	[159:0] out_dout5;

// output buffer signals
wire out_put1, out_put2, out_put3, out_put4, out_put5;
wire out_get1, out_get2, out_get3, out_get4, out_get5;
wire out_emptybar1, out_emptybar2, out_emptybar3, out_emptybar4, out_emptybar5;
wire out_fullbar1, out_fullbar2, out_fullbar3, out_fullbar4, out_fullbar5;
wire [31:0] out_din1, out_din2, out_din3, out_din4, out_din5;

// input buffer signals
wire in_put1, in_put2, in_put3, in_put4, in_put5;
wire in_get1, in_get2, in_get3, in_get4, in_get5;
wire in_fullbar1, in_fullbar2, in_fullbar3, in_fullbar4, in_fullbar5;
wire in_emptybar1, in_emptybar2, in_emptybar3, in_emptybar4, in_emptybar5;
wire [31:0] in_dout1, in_dout2, in_dout3,in_dout4,in_dout5;

// header_x to indicate if the phit is header or not (this phit is at the output of x input buffer)
wire  header_1, header_2, header_3, header_4, header_5;

// hop_info stores the desired look up table info, that is x_direction (1 bit), x_hct (2 bits), y_direction (1 bit), y_hct (2 bits)
reg [5:0] hop_info;

// headerdata stores the header modified by router
reg [31:0] headerdata_1,headerdata_2,headerdata_3,headerdata_4,headerdata_5;

// sd1: packet is from master to slave
// sd2: packet is from slave to master
// [5:3] are source ID, [2:0] are destination ID
wire [5:0] sd1, sd2;

// new packet after modification by router, only header is modified, the last 4 phits are unchanged
reg [31:0] new_in_dout1, new_in_dout2, new_in_dout3,new_in_dout4,new_in_dout5;

// header counters used to capture the header, it is not hop counter!!!
reg [2:0] hcnt_1, hcnt_2, hcnt_3, hcnt_4, hcnt_5;

// look up table used to attach routing info when transaction come out of PE input buffer
reg [5:0] lut[0:63];

assign in_ready1 = in_fullbar1;
assign in_ready2 = in_fullbar2;
assign in_ready3 = in_fullbar3;
assign in_ready4 = in_fullbar4;
assign in_ready5 = in_fullbar5;

assign out_valid1 = out_emptybar1;
assign out_valid2 = out_emptybar2;
assign out_valid3 = out_emptybar3;
assign out_valid4 = out_emptybar4;
assign out_valid5 = out_emptybar5;

//-- Task 1: When to put data into input buffers; When to get data from output buffers?
//			Hint: Using hand shaking signals, valid, ready, fullbar, emptybar,etc.
// output buffer has something to send and input buffer has space to receive
assign in_put1 = in_valid1 & in_fullbar1;
assign in_put2 = in_valid2 & in_fullbar2;
assign in_put3 = in_valid3 & in_fullbar3;
assign in_put4 = in_valid4 & in_fullbar4;
assign in_put5 = in_valid5 & in_fullbar5;

assign out_get1 = out_ready1 & out_emptybar1;
assign out_get2 = out_ready2 & out_emptybar2;
assign out_get3 = out_ready3 & out_emptybar3;
assign out_get4 = out_ready4 & out_emptybar4;
assign out_get5 = out_ready5 & out_emptybar5;

// indicate if the phit is header or not
assign header_1 = (hcnt_1 == 3'b00 && in_emptybar1 == 1'b1) ? 1'b1 :1'b0;
assign header_2 = (hcnt_2 == 3'b00 && in_emptybar2 == 1'b1) ? 1'b1 :1'b0;
assign header_3 = (hcnt_3 == 3'b00 && in_emptybar3 == 1'b1) ? 1'b1 :1'b0;
assign header_4 = (hcnt_4 == 3'b00 && in_emptybar4 == 1'b1) ? 1'b1 :1'b0;
assign header_5 = (hcnt_5 == 3'b00 && in_emptybar5 == 1'b1) ? 1'b1 :1'b0;





// five input buffers
fifo #(.DEPTH(10), .DATA_WIDTH(32)) in_fifo_1 (
			.clk(clk), 
			.resetn(reset), 
			.put(in_put1), 
			.get(in_get1), 
			.data_in(in_din1),
			.empty_bar(in_emptybar1), 
			.full_bar(in_fullbar1), 
			.data_out(in_dout1)
			);
			
fifo #(.DEPTH(10), .DATA_WIDTH(32)) in_fifo_2 (
			.clk(clk), 
			.resetn(reset), 
			.put(in_put2), 
			.get(in_get2), 
			.data_in(in_din2),
			.empty_bar(in_emptybar2), 
			.full_bar(in_fullbar2), 
			.data_out(in_dout2)
			);			

fifo #(.DEPTH(10), .DATA_WIDTH(32)) in_fifo_3 (
			.clk(clk), 
			.resetn(reset), 
			.put(in_put3), 
			.get(in_get3), 
			.data_in(in_din3),
			.empty_bar(in_emptybar3), 
			.full_bar(in_fullbar3), 
			.data_out(in_dout3)
			);	

fifo #(.DEPTH(10), .DATA_WIDTH(32)) in_fifo_4 (
			.clk(clk), 
			.resetn(reset), 
			.put(in_put4), 
			.get(in_get4), 
			.data_in(in_din4),
			.empty_bar(in_emptybar4), 
			.full_bar(in_fullbar4), 
			.data_out(in_dout4)
			);	

PE_FIFO1 in_fifo_5(
			.clk(clk), 
			.reset(reset), 
			.put(in_put5), 
			.get(in_get5), 
			.data_in(in_din5), 
			.empty_bar(in_emptybar5), 
			.full_bar(in_fullbar5), 
			.data_out(in_dout5)
			);

// five output buffers
fifo #(.DEPTH(10), .DATA_WIDTH(32)) out_fifo_1 (
			.clk(clk), 
			.resetn(reset), 
			.put(out_put1), 
			.get(out_get1), 
			.data_in(out_din1),
			.empty_bar(out_emptybar1), 
			.full_bar(out_fullbar1), 
			.data_out(out_dout1)
			);
			
fifo #(.DEPTH(10), .DATA_WIDTH(32)) out_fifo_2 (
			.clk(clk), 
			.resetn(reset), 
			.put(out_put2), 
			.get(out_get2), 
			.data_in(out_din2),
			.empty_bar(out_emptybar2), 
			.full_bar(out_fullbar2), 
			.data_out(out_dout2)
			);

fifo #(.DEPTH(10), .DATA_WIDTH(32)) out_fifo_3 (
			.clk(clk), 
			.resetn(reset), 
			.put(out_put3), 
			.get(out_get3), 
			.data_in(out_din3),
			.empty_bar(out_emptybar3), 
			.full_bar(out_fullbar3), 
			.data_out(out_dout3)
			);
			
fifo #(.DEPTH(10), .DATA_WIDTH(32)) out_fifo_4 (
			.clk(clk), 
			.resetn(reset), 
			.put(out_put4), 
			.get(out_get4), 
			.data_in(out_din4),
			.empty_bar(out_emptybar4), 
			.full_bar(out_fullbar4), 
			.data_out(out_dout4)
			);

PE_FIFO2 out_fifo_5(
			.clk(clk), 
			.reset(reset), 
			.put(out_put5), 
			.get(out_get5), 
			.data_in(out_din5), 
			.empty_bar(out_emptybar5), 
			.full_bar(out_fullbar5), 
			.data_out(out_dout5)
			);

// routing logic module, including LRU arbitor
routing_logic r_logic (	
						.clk(clk), 
						.reset(reset),
						/*****input of routing logic*****/
						.header_1(headerdata_1),			// send header to routing logic
						.header_2(headerdata_2),
						.header_3(headerdata_3), 
						.header_4(headerdata_4),
						.header_5(headerdata_5), 
						.in_dout1(new_in_dout1),			// send modified packet to routing logic
						.in_dout2(new_in_dout2), 
						.in_dout3(new_in_dout3), 
						.in_dout4(new_in_dout4),
						.in_dout5(new_in_dout5), 
					  .in_emptybar1(in_emptybar1), 	// send in_emptybar and out_full_bar to routing logic to generate get and put signal
					  .in_emptybar2(in_emptybar2), 
					  .in_emptybar3(in_emptybar3),
					  .in_emptybar4(in_emptybar4), 
					  .in_emptybar5(in_emptybar5),
						.out_fullbar1(out_fullbar1),
					  .out_fullbar2(out_fullbar2),
					  .out_fullbar3(out_fullbar3),
					  .out_fullbar4(out_fullbar4),
					  .out_fullbar5(out_fullbar5),
						/*****output of routing logic*****/
					  .in_get1(in_get1), 
					  .in_get2(in_get2), 
					  .in_get3(in_get3), 
					  .in_get4(in_get4), 
					  .in_get5(in_get5),
					  .out_put1(out_put1), 
					  .out_put2(out_put2),
					  .out_put3(out_put3), 
					  .out_put4(out_put4),
					  .out_put5(out_put5),
					  .out_din1(out_din1),
					  .out_din2(out_din2),
					  .out_din3(out_din3), 
					  .out_din4(out_din4), 
					  .out_din5(out_din5)

							);


always@(posedge clk) begin
	
if (reset==1'b0)
	begin
	// hcnt used to find header
	hcnt_1 <= 3'd0;
	hcnt_2 <= 3'd0;
	hcnt_3 <= 3'd0;
	hcnt_4 <= 3'd0;
	hcnt_5 <= 3'd0;	
	
	// initiate the look up table
	/*
		eg:
		lut[6'b000_101] <= 6'b001_101;  // 0->5
		
		RHS: [6'b000_101]:
		000 -> source
		101 -> destination
		
		LHS: 6'b001_101
		001 -> MSB 0	: x direction is positive
					 LSB 01 : x_hct
		101 -> MSB 1	: y direction is negative
					 LSB 01	: y_hct
	
		this lut even includes master to master and slave to slave routing info (redundancy)
	*/
	
	//-- Task 2: What's in LUT (source is 0, destination is 1 to 7)
	//--		Hint: check the topology of eight routers in document and figure out x/y_direction and x/y_hct
	lut[6'b000001] <= 6'b001000;	// 0->1
	lut[6'b000010] <= 6'b010000;	// 0->2
	lut[6'b000011] <= 6'b011000;	// 0->3
	lut[6'b000100] <= 6'b000101;	// 0->4
	lut[6'b000101] <= 6'b001101;  	// 0->5
	lut[6'b000110] <= 6'b010101;  	// 0->6
	lut[6'b000111] <= 6'b011101;	// 0->7
	
	lut[6'b001000] <= 6'b101000;
	lut[6'b001010] <= 6'b001000;
	lut[6'b001011] <= 6'b010000;
	lut[6'b001100] <= 6'b101101;
	lut[6'b001101] <= 6'b000101;
	lut[6'b001110] <= 6'b001101;
	lut[6'b001111] <= 6'b010101;
	    
	lut[6'b010000] <= 6'b110000;
	lut[6'b010001] <= 6'b101000;
	lut[6'b010011] <= 6'b001000;
	lut[6'b010100] <= 6'b110101;
	lut[6'b010101] <= 6'b101101;
	lut[6'b010110] <= 6'b000101;
	lut[6'b010111] <= 6'b001101;
	   
	lut[6'b011000] <= 6'b111000;
	lut[6'b011001] <= 6'b110000;
	lut[6'b011010] <= 6'b101000;
	lut[6'b011100] <= 6'b111101;
	lut[6'b011101] <= 6'b110101;
	lut[6'b011110] <= 6'b101101;
	lut[6'b011111] <= 6'b000101;
	  
	lut[6'b100000] <= 6'b000001;
	lut[6'b100001] <= 6'b001001;
	lut[6'b100010] <= 6'b010001;
	lut[6'b100011] <= 6'b011001;
	lut[6'b100101] <= 6'b001000;
	lut[6'b100110] <= 6'b010000;
	lut[6'b100111] <= 6'b011000;
	   
	lut[6'b101000] <= 6'b101001;	// 5->0
	lut[6'b101001] <= 6'b000001;  // 5->1
	lut[6'b101010] <= 6'b001001;  // 5->2
	lut[6'b101011] <= 6'b010001;  // 5->3
	lut[6'b101100] <= 6'b101000;  // 5->4
	lut[6'b101110] <= 6'b001000;  // 5->6
	lut[6'b101111] <= 6'b010000;  // 5->7
	    
	lut[6'b110000] <= 6'b110001;
	lut[6'b110001] <= 6'b101001;
	lut[6'b110010] <= 6'b000001;
	lut[6'b110011] <= 6'b001001;
	lut[6'b110100] <= 6'b110000;
	lut[6'b110101] <= 6'b101000;
	lut[6'b110111] <= 6'b001000;
	    
	lut[6'b111000] <= 6'b111001;
	lut[6'b111001] <= 6'b110001;
	lut[6'b111010] <= 6'b101001;
	lut[6'b111011] <= 6'b000001;
	lut[6'b111100] <= 6'b111000;
	lut[6'b111101] <= 6'b110000;
	lut[6'b111110] <= 6'b101000;
	end

else
	begin // this part is used for capturing header

	if  (in_get1 == 1'b1 && hcnt_1 <3'd4)
		hcnt_1 <= hcnt_1 + 3'd1;
	else if (hcnt_1 ==3'd4)
		hcnt_1 <= 3'd0;
	
	if (in_get2 == 1'b1 && hcnt_2 <3'd4)
		hcnt_2 <= hcnt_2 + 3'd1;
	else if (hcnt_2 ==3'd4)
		hcnt_2 <= 3'd0;
	
	if  (in_get3 == 1'b1 && hcnt_3 <3'd4)
		hcnt_3 <= hcnt_3 + 3'd1;
	else if (hcnt_3 ==3'd4)
		hcnt_3 <= 3'd0;
	
	if  (in_get4 == 1'b1 && hcnt_4 <3'd4)
		hcnt_4 <= hcnt_4 + 3'd1;
	else if (hcnt_4 ==3'd4)
		hcnt_4 <= 3'd0;
		
	if((in_get5 == 1'b1 && hcnt_5 <3'd4))
		hcnt_5 <= hcnt_5 + 3'd1;
	else if (hcnt_5 ==3'd4)
		hcnt_5 <= 3'd0;
		
end // end of else for always@

end// end of always@	
	
// [25:23] master ID, [22:20] slave ID
assign sd1 = {in_dout5[25:23],in_dout5[22:20]} ;  	// source is master, destination is slave
assign sd2 = {in_dout5[22:20],in_dout5[25:23]} ;		// source is slave, destination is master

always@(*)

begin			// pay attention to BLOCKING assignment
	new_in_dout5 = in_dout5;
	new_in_dout1 = in_dout1;
	new_in_dout2 = in_dout2;
	new_in_dout3 = in_dout3;
	new_in_dout4 = in_dout4;
	
	// when packet comes out of PE input buffer, routing info is obtained by checking the look up table
	// then this routing info is filled to [15:10] of the header
	if (in_dout5[19:17] == 3'b000 || in_dout5[19:17] == 3'b001 || in_dout5[19:17] == 3'b010)
			hop_info = lut[sd1];	// WA/WD/RA is sent from master to slave
	else 
	    hop_info = lut[sd2];	// RD/WRESP is sent from slave to master
	    
	if (header_5 == 1'b1)begin
		new_in_dout5[15:10] = hop_info;
		end
	
	// if the packet come out of other input buffers other than PE, we should modify its header according to hct
	if(header_1 == 1'b1) 
		begin
			
		if(in_dout1[14:13] !=2'b00)
			new_in_dout1[14:13] = in_dout1[14:13] - 2'b01;
		
		else if (in_dout1[11:10] !=2'b00)
			new_in_dout1[11:10] = in_dout1[11:10] - 2'b01;
			
	
		end
		
	if(header_2 == 1'b1) 
			begin
		
			if(in_dout2[14:13] !=2'b00)
				new_in_dout2[14:13] = in_dout2[14:13] - 2'b01;
			
			else if (in_dout2[11:10] !=2'b00)
				new_in_dout2[11:10] = in_dout2[11:10] - 2'b01;
				
		
			end
			
	if(header_3 == 1'b1) 
			begin
			
			if(in_dout3[14:13] !=2'b00)
				new_in_dout3[14:13] = in_dout3[14:13] - 2'b01;
			
			else if (in_dout3[11:10] !=2'b00)
				new_in_dout3[11:10] = in_dout3[11:10] - 2'b01;
				
		
			end
			
	if(header_4 == 1'b1) 
			begin
	
			if(in_dout4[14:13] !=2'b00)
				new_in_dout4[14:13] = in_dout4[14:13] - 2'b01;
			
			else if (in_dout4[11:10] !=2'b00)
				new_in_dout4[11:10] = in_dout4[11:10] - 2'b01;
				
		
			end

			
	//Note: The header information needs to be valid for 5 clocks. 
	//Because this information is needed to route the header phit and the 4 data phits	
	//In this design this information is held in a latches. A better design is to uses
	//registers, But when when a register is used it will naturally incur a 1 clock delay.
	//Think about how this delay can be avoided. 
	if(header_1 == 1'b1) 
		headerdata_1 <= new_in_dout1;

	if(header_2 == 1'b1) 
		headerdata_2 <= new_in_dout2;

	if(header_3 == 1'b1) 
		headerdata_3 <= new_in_dout3;

	if(header_4 == 1'b1) 
		headerdata_4 <= new_in_dout4;

	if(header_5 == 1'b1) 
		headerdata_5 <= new_in_dout5;
				
end

endmodule 
	