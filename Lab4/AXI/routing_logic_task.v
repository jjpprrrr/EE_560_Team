////////////////////////////////////////////////////////////
//// File: routing_logic.v
//// Author: Aparna Srinivasan
//// Version: 0.0
//// Date: 23rd April 2014
//// Description: This module is the key part in router. It generates routing requests 	
////							according to input/output buffer's empty/full signals, then send these
////							requests to Arbiter. According to grant signal, it routes packet from
////							input buffer to output buffer.
//// Updated by Yiheng Guo, 04/2015
//////////////////////////////////////////////////////////////



module routing_logic (	clk, 
						reset, 
						header_1, 
						header_2, 
						header_3, 
						header_4, 
						header_5, 
						in_dout1, 
						in_dout2, 
						in_dout3, 
						in_dout4,
						in_dout5, 
						in_emptybar1,
						in_emptybar2,
						in_emptybar3, 
						in_emptybar4, 
						in_emptybar5, 
						in_get1, 
						in_get2, 
						in_get3, 
						in_get4,
						in_get5,
						out_fullbar1,
					 	out_fullbar2,
					 	out_fullbar3,
					 	out_fullbar4,
					 	out_fullbar5,
						
					 	out_put1, 
					 	out_put2, 
					 	out_put3, 
					 	out_put4, 
					 	out_put5,
					 	out_din1, 
					 	out_din2, 
					 	out_din3, 
					 	out_din4, 
					 	out_din5
						);

input clk, reset;
input [31:0] header_1, header_2, header_3, header_4, header_5;		// header from input buffer
input [31:0] in_dout1, in_dout2, in_dout3,in_dout4,in_dout5;			// output of the input buffer
input in_emptybar1, in_emptybar2, in_emptybar3, in_emptybar4, in_emptybar5;
input out_fullbar1, out_fullbar2, out_fullbar3, out_fullbar4, out_fullbar5;

output in_get1, in_get2, in_get3, in_get4, in_get5;
output out_put1, out_put2, out_put3, out_put4, out_put5;
output [31:0] out_din1, out_din2, out_din3, out_din4;
output [31:0] out_din5;

reg [31:0] out_din1, out_din2, out_din3, out_din4;
reg [31:0] out_din5;

// reqx_y, request from x to y
reg req2_1, req5_1; 									// requests for output buffer 1
reg req1_2, req5_2; 									// requests for output buffer 2
reg req1_3, req2_3, req5_3; 		// requests for output buffer 3
reg req1_4, req2_4, req5_4; 	// requests for output buffer 4
reg req3_5,req4_5;					 					// requests for output buffer 5

// grantx_y, grant the request from x to y
wire grant2_1, grant5_1;
wire grant1_2 , grant5_2;
wire grant1_3 , grant2_3, grant4_3, grant5_3;
wire grant1_4 , grant2_4, grant3_4, grant5_4;
wire grant3_5, grant4_5;


wire [1:0] xhop_1, xhop_2, xhop_3, xhop_4, xhop_5;
wire [1:0] yhop_1, yhop_2, yhop_3, yhop_4, yhop_5;
wire xdir_1, xdir_2, xdir_3,  xdir_4, xdir_5;
wire ydir_1, ydir_2, ydir_3,  ydir_4, ydir_5;
wire valid_1, valid_2, valid_3, valid_4, valid_5;

assign valid_1 = header_1[16];
assign valid_2 = header_2[16];
assign valid_3 = header_3[16];
assign valid_4 = header_4[16];
assign valid_5 = header_5[16];

assign xhop_1 = header_1[14:13];
assign xhop_2 = header_2[14:13];
assign xhop_3 = header_3[14:13];
assign xhop_4 = header_4[14:13];
assign xhop_5 = header_5[14:13];


assign yhop_1 = header_1[11:10];
assign yhop_2 = header_2[11:10];
assign yhop_3 = header_3[11:10];
assign yhop_4 = header_4[11:10];
assign yhop_5 = header_5[11:10];


assign xdir_1 = header_1[15];
assign xdir_2 = header_2[15];
assign xdir_3 = header_3[15];
assign xdir_4 = header_4[15];
assign xdir_5 = header_5[15];

assign ydir_1 = header_1[12];
assign ydir_2 = header_2[12];
assign ydir_3 = header_3[12];
assign ydir_4 = header_4[12];
assign ydir_5 = header_5[12];

always@(*)
begin

req2_1 <= 1'b0;
req5_1 <= 1'b0;

req1_2 <= 1'b0;
req5_2 <= 1'b0;

req1_3 <= 1'b0;
req2_3 <= 1'b0;
req5_3 <= 1'b0;

req1_4 <= 1'b0;
req2_4 <= 1'b0;
req5_4 <= 1'b0;

req3_5 <= 1'b0;
req4_5 <= 1'b0;

// input buffer has valid packet to send to the corresponding output buffer
// requests are generated according to routing info (hop, dir), input/output buffer and valid bit
req2_1 <=  (xhop_2 != 2'b00) && (xdir_2 == 1'b0) && (in_emptybar2 == 1'b1) && (out_fullbar1 == 1'b1) && (valid_2 == 1'b1);
req5_1 <=  (xhop_5 != 2'b00) && (xdir_5 == 1'b0) && (in_emptybar5 == 1'b1) && (out_fullbar1 == 1'b1) && (valid_5 == 1'b1);
       
req1_2 <=  (xhop_1 != 2'b00) && (xdir_1 == 1'b1) && (in_emptybar1 == 1'b1) && (out_fullbar2 == 1'b1) && (valid_1 == 1'b1);
req5_2 <=  (xhop_5 != 2'b00) && (xdir_5 == 1'b1) && (in_emptybar5 == 1'b1) && (out_fullbar2 == 1'b1) && (valid_5 == 1'b1);
     
req1_3 <=  (yhop_1 != 2'b00) && (ydir_1 == 1'b0) && (xhop_1 == 2'b00) && (in_emptybar1 == 1'b1) && (out_fullbar3 == 1'b1) && (valid_1 == 1'b1);
req2_3 <=  (yhop_2 != 2'b00) && (ydir_2 == 1'b0) && (xhop_2 == 2'b00) && (in_emptybar2 == 1'b1) && (out_fullbar3 == 1'b1) && (valid_2 == 1'b1);
req5_3 <=  (yhop_5 != 2'b00) && (ydir_5 == 1'b0) && (xhop_5 == 2'b00) && (in_emptybar5 == 1'b1) && (out_fullbar3 == 1'b1) && (valid_5 == 1'b1);
       
req1_4 <=  (yhop_1 != 2'b00) && (ydir_1 == 1'b1) && (xhop_1 == 2'b00) && (in_emptybar1 == 1'b1) && (out_fullbar4 == 1'b1) && (valid_1 == 1'b1);
req2_4 <=  (yhop_2 != 2'b00) && (ydir_2 == 1'b1) && (xhop_2 == 2'b00) && (in_emptybar2 == 1'b1) && (out_fullbar4 == 1'b1) && (valid_2 == 1'b1);
req5_4 <=  (yhop_5 != 2'b00) && (ydir_5 == 1'b1) && (xhop_5 == 2'b00) && (in_emptybar5 == 1'b1) && (out_fullbar4 == 1'b1) && (valid_5 == 1'b1);

req3_5 <=  (xhop_3 == 2'b00) && (yhop_3 == 2'b00) && (in_emptybar3 == 1'b1) && (out_fullbar5 == 1'b1) && (valid_3 == 1'b1);
req4_5 <=  (xhop_4 == 2'b00) && (yhop_4 == 2'b00) && (in_emptybar4 == 1'b1) && (out_fullbar5 == 1'b1) && (valid_4 == 1'b1);

end

//-- Task 1: Generate in_get and out_put
//--		Hint: 1. figure out which requests and grants should be used; choose requests carefully
//--					2. for example in_get1 = (req1_2 && grant1_2)||.........; 
assign in_get1 = (req1_2 && grant1_2) || (req1_3 && grant1_3) || (req1_4 && grant1_4);
assign in_get2 = (req2_1 && grant2_1) || (req2_3 && grant2_3) || (req2_4 && grant2_4);
assign in_get3 = (req3_5 && grant3_5);
assign in_get4 = (req4_5 && grant4_5);
assign in_get5 = (req5_1 && grant5_1) || (req5_2 && grant5_2) || (req5_3 && grant5_3) || (req5_4 && grant5_4);


assign out_put1 = (req2_1 && grant2_1) || (req5_1 && grant5_1);
assign out_put2 = (req1_2 && grant1_2) || (req5_2 && grant5_2);
assign out_put3 = (req1_3 && grant1_3) || (req2_3 && grant2_3) || (req5_3 && grant5_3);
assign out_put4 = (req1_4 && grant1_4) || (req2_4 && grant2_4) || (req5_4 && grant5_4);
assign out_put5 = (req3_5 && grant3_5) || (req4_5 && grant4_5);


// arbiter modules instantiation, send requests to arbiter
//-- Task 2: Different arbiters should receive different requests.
//-- 		Hint: different arbiters can receive different number of requests, so some of the ports can be left unconnected here
// 			Multiple input buffers can send to one output buffer. The arbitration logic is used to select one of the 
//			input buffers to connect to the output buffer
Arbiter arbiter_xp (.clk(clk),.reset(reset),.Req1(req2_1),.Req2(req5_1),.Req3(),.Req4(),.Gnt1(grant2_1),.Gnt2(grant5_1),.Gnt3(),.Gnt4() );
Arbiter arbiter_xn (.clk(clk),.reset(reset),.Req1(req1_2),.Req2(req5_2),.Req3(),.Req4(),.Gnt1(grant1_2),.Gnt2(grant5_2),.Gnt3(),.Gnt4() );
Arbiter arbiter_yp (.clk(clk),.reset(reset),.Req1(req1_3),.Req2(req2_3),.Req3(req5_3),.Req4(),.Gnt1(grant1_3),.Gnt2(grant2_3),.Gnt3(grant5_3),.Gnt4() );
Arbiter arbiter_yn (.clk(clk),.reset(reset),.Req1(req1_4),.Req2(req2_4),.Req3(req5_4),.Req4(),.Gnt1(grant1_4),.Gnt2(grant2_4),.Gnt3(grant5_4),.Gnt4());
Arbiter ariter_pe  (.clk(clk),.reset(reset),.Req1(req3_5),.Req2(req4_5),.Req3(),.Req4(),.Gnt1(grant3_5),.Gnt2(grant4_5),.Gnt3(),.Gnt4() );


always@(*) 
begin

// for output buffer_1
if (grant2_1 == 1'b1)
	out_din1 = in_dout2;
else if (grant5_1 == 1'b1)
	out_din1 = in_dout5;
else
	out_din1 = 0;
	
// for output buffer_2
if (grant1_2 == 1'b1)
	out_din2 = in_dout1;
else if (grant5_2 == 1'b1)
	out_din2 = in_dout5;
else
	out_din2 = 0;

// for output buffer_3
if (grant1_3 == 1'b1)
	out_din3 = in_dout1;
else if (grant2_3 == 1'b1)
	out_din3 = in_dout2;
else if (grant4_3 == 1'b1)
	out_din3 = in_dout4;
else if (grant5_3 == 1'b1)
	out_din3 = in_dout5;
else
	out_din3 = 0;

//for output buffer_4
if (grant1_4 == 1'b1)
	out_din4 = in_dout1;
else if (grant2_4 == 1'b1)
	out_din4 = in_dout2;
else if (grant3_4 == 1'b1)
	out_din4 = in_dout3;
else if (grant5_4 == 1'b1)
	out_din4 = in_dout5;
else 
	out_din4 = 0;

// for output buffer_5
if (grant3_5 == 1'b1)
	out_din5 = in_dout3;
else if (grant4_5 == 1'b1)
	out_din5 = in_dout4;
else
	out_din5 = 0;

end
	
	
endmodule	