/** 
* @file			IOExpansion_uart.v
*
* @author		Fangzhou Wang
* @email		fangzhow@usc.edu
* @company		University of Southern California
* @date			May.30 2014
* @version		1.0.0
*
* @updates		@May.30 2014
*					File created.
* 
* Summary of File:
* 
*	This file contains code which simulates the behavior of Adept.
*	Note that only dwIn and dwOut are implemented. Led, LBar, Sw, Btn
*	are temporarily ignored.
*	uart module is based on Jizhe's work.
* 
*/

//   Name              Epp     Dir Explain
//                     Address 
// regVer(7 downto 0)  0x00    I/O returns the complement of written value
// Led(7 downto 0)     0x01    In  8 virtual LEDs on the PC I/O Ex GUI
// LBar(7 downto 0)    0x02    In  8 right lights on the PC I/O Ex GUI light bar
// LBar(15 downto 8)   0x03    In  8 middle lights on the PC I/O Ex GUI light bar
// LBar(23 downto 16)  0x04    In  8 left lights on the PC I/O Ex GUI light bar
// Sw(7 downto 0)      0x05    In  8 switches, bottom row on the PC I/O Ex GUI
// Sw(15 downto 8)     0x06    In  8 switches, top row on the PC I/O Ex GUI
// Btn(7 downto 0)     0x07    In  8 Buttons, bottom row on the PC I/O Ex GUI
// Btn(15 downto 8)    0x08    In  8 Buttons, top row on the PC I/O Ex GUI
// dwOut(7 downto 0)   0x09    Out 8 Bits in an output double word
// dwOut(15 downto 8)  0x0a    Out 8 Bits in an output double word
// dwOut(23 downto 16) 0x0b    Out 8 Bits in an output double word
// dwOut(31 downto 24) 0x0c    Out 8 Bits in an output double word
// dwIn(7 downto 0)    0x0d    In  8 Bits in an input double word
// dwIn(15 downto 8)   0x0e    In  8 Bits in an input double word
// dwIn(23 downto 16)  0x0f    In  8 Bits in an input double word
// dwIn(31 downto 24)  0x10    In  8 Bits in an input double word

module IOExpansion (
	clk_pin,		// Clock input (from pin)
	rst_pin,		// Active HIGH reset (from pin)

	// RS232 signals
	rxd_pin,		// RS232 RXD pin
	txd_pin,		// RS232 RXD pin
	
	//user extended signals
	Led,
	LBar,
	Sw,
	Btn,
	dwOut,
	dwIn
);

	parameter BAUD_RATE           = 115_200;   

	parameter CLOCK_RATE_RX       = 100_000_000;
	parameter CLOCK_RATE_TX       = 100_000_000;
	  
	input	clk_pin;
	input	rst_pin;

	input	rxd_pin;
	output	txd_pin;

	input	[7:0]	Led;
	input	[23:0]	LBar;
	input	[31:0]	dwIn;

	output	[15:0]	Sw;
	output	[15:0]	Btn;
	output	[31:0]	dwOut;

	// To/From IBUFG/OBUFG
	// No pin for clock - the IBUFG is internal to clk_gen
	wire        rst_i;          
	wire        rxd_i;         
	wire        txd_o;

	// From Clock Generator
	wire        clk_sys;         // Receive clock

	// From Reset Generator
	wire        rst_clk;     // Reset, synchronized to clk_rx

	// From the RS232 receiver
	wire        rxd_clk_rx;     // RXD signal synchronized to clk_rx
	wire        rx_data_rdy;    // New character is ready
	wire [7:0]  rx_data;        // New character
	wire        rx_lost_data;   // Rx data lost

	// From the UART transmitter
	wire        tx_fifo_full;  // Pop signal to the char FIFO

	// Given in the current module
	wire [7:0]    tx_din;     // data to be sent in tx
	wire          tx_write_en;    // send signal to tx
	wire          rx_read_en;     // pop an entry in the rx fifo
	
	function [3:0] to_val;
        input [6:0] char;
        begin
            if ((char >= 7'h30) && (char <= 7'h39)) // 0-9
            begin
                to_val[3:0] = char[3:0];
            end
            else if (((char >= 7'h41) && (char <= 7'h46)) || // A-F
                ((char >= 7'h61) && (char <= 7'h66)) )  // a-f
            begin
                to_val[3:0] = char[3:0] + 4'h9; // gives 10 - 15
            end
            else 
            begin
                to_val      = 4'b0000;
            end
        end
    endfunction
	
	function [7:0] to_char;
        input [3:0] val;
        begin
            if ((val >= 4'h0) && (val <= 4'h9)) // 0-9
            begin
                to_char = {4'h3, val};
            end
            else
            begin
                to_char = val + 8'h37; // gives 10 - 15
            end
        end
    endfunction

	// Instantiate input/output buffers
	// IBUF IBUF_rst_i0      (.I (rst_pin),      .O (rst_i));
	IBUF IBUF_rxd_i0      (.I (rxd_pin),      .O (rxd_i));

	OBUF OBUF_txd         (.I(txd_o),         .O(txd_pin));
	// IBUFG IBUFG_CLK       (.I(clk_pin),      .O(clk_sys));
	assign rst_i = ~rst_pin;
	assign clk_sys = clk_pin;
  
	// Instantiate the reset generator
	rst_gen rst_gen_i0 (
	.clk_i		(clk_sys),			// Receive clock
	.rst_i		(rst_i),			// Asynchronous input - from IBUF
	.rst_o		(rst_clk)			// Reset, synchronized to clk_rx
	);

	// Instantiate the UART receiver
	uart_rx #(
	.BAUD_RATE   (BAUD_RATE),
	.CLOCK_RATE  (CLOCK_RATE_RX)
	) uart_rx_i0 (
	//system configuration:
	.clk_rx      (clk_sys),              // Receive clock
	.rst_clk_rx  (rst_clk),				// Reset, synchronized to clk_rx 
	.rxd_i       (rxd_i),               // RS232 receive pin
	.rxd_clk_rx  (rxd_clk_rx),          // RXD pin after sync to clk_rx    

	//user interface:
	.read_en     (rx_read_en), 			// input to the module: pop an element from the internal fifo
	.rx_data_rdy (rx_data_rdy),         // New data is ready
	.rx_data     (rx_data),             // New data
	.lost_data   (rx_lost_data),		// fifo is full but new data still comes in, resulting in data lost
	.frm_err     ()                     // Framing error (unused)
	);

	// Instantiate the UART transmitter
	uart_tx #(
	.BAUD_RATE    (BAUD_RATE),
	.CLOCK_RATE   (CLOCK_RATE_TX)
	) uart_tx_i0 (
	//system configuration:
	.clk_tx             (clk_sys),		// Clock input
	.rst_clk_tx         (rst_clk),		// Reset - synchronous to clk_tx
	.txd_tx             (txd_o),		// The transmit serial signal

	//user interface:
	.write_en           (tx_write_en),	// signal to send to data out
	.tx_din             (tx_din),		// data to be sent
	.tx_fifo_full       (tx_fifo_full)	// the internal fifo is full, should stop sending data
	);
	
	reg	[3:0]	dwOutTemp [0:3];
	reg	[1:0]	dwOutCounter;
	reg 		dwOutState;
	reg	[31:0]	dwOut_reg;
	
	localparam 
    IDLE	= 1'b0,
    INPR	= 1'b1;
	
	assign rx_read_en	= rx_data_rdy;
	assign dwOut		= dwOut_reg;
	
	//dwOut controller
	always @ (posedge clk_sys)
	begin
		if(rst_clk)
		begin
			dwOutTemp[0]	<= 0;
			dwOutTemp[1]	<= 0;
			dwOutTemp[2]	<= 0;
			dwOutTemp[3]	<= 0;
			dwOutCounter	<= 0;
			dwOutState		<= 0;
		end
		else
		begin
			case(dwOutState)
			IDLE:
				begin
					if(rx_data_rdy)
					begin
						dwOutState				<= INPR;
						dwOutCounter			<= dwOutCounter + 1'b1;
						dwOutTemp[dwOutCounter]	<= to_val(rx_data[6:0]);
					end
					else
					begin
						dwOutCounter			<= 2'b00;
					end
				end
			INPR:
				begin
					if(rx_data_rdy)
					begin
						if(dwOutCounter == 2'b11)
						begin
							dwOutState			<= IDLE;
							dwOut_reg			<= {16'b0000_0000_0000_0000, 
													dwOutTemp[0], dwOutTemp[1], 
													dwOutTemp[2], to_val(rx_data[6:0])};
						end
						else
						begin
							dwOutCounter			<= dwOutCounter + 1'b1;
							dwOutTemp[dwOutCounter]	<= to_val(rx_data[6:0]);
						end
					end
				end
			endcase
		end
	end
	
	reg	[7:0]	dwInTemp [0:7];
	reg	[2:0]	dwInCounter;
	reg 		dwInState;
	reg	[7:0]	tx_din_reg;
	reg			tx_write_en_reg;
	reg	[31:0]	dwIn_reg;
	
	assign	tx_write_en	= tx_write_en_reg;
	assign	tx_din		= tx_din_reg;
	
	//dwIn controller
	always @ (posedge clk_sys)
	begin
		if(rst_clk)
		begin
			dwInTemp[0]			<= 0;
			dwInTemp[1]			<= 0;
			dwInTemp[2]			<= 0;
			dwInTemp[3]			<= 0;
			dwInTemp[4]			<= 0;
			dwInTemp[5]			<= 0;
			dwInTemp[6]			<= 0;
			dwInTemp[7]			<= 0;
			
			dwInCounter			<= 0;
			dwInState			<= 0;
			tx_din_reg			<= 0;
			tx_write_en_reg		<= 0;
			dwIn_reg			<= 0;
		end
		else
		begin
			case(dwInState)
			IDLE:
				begin
					if(dwIn != dwIn_reg)
					begin
						dwInTemp[3]		<= to_char(dwIn[3:0]);
						dwInTemp[2]		<= to_char(dwIn[7:4]);
						dwInTemp[1]		<= to_char(dwIn[11:8]);
						dwInTemp[0]		<= to_char(dwIn[15:12]);
						dwInTemp[7]		<= to_char(dwIn[19:16]);
						dwInTemp[6]		<= to_char(dwIn[23:20]);
						dwInTemp[5]		<= to_char(dwIn[27:24]);
						dwInTemp[4]		<= to_char(dwIn[31:28]);
						
						dwIn_reg		<= dwIn;
						
						dwInState		<= INPR;
						dwInCounter		<= 0;
					
						//Tell PC to clear current content
						tx_din_reg		<= 8'h07;
						tx_write_en_reg	<= 1'b1;
					end
					else
					begin
						dwInCounter		<= 3'b000;
						tx_write_en_reg	<= 1'b0;
					end
				end
			INPR:
				begin
					if(dwInCounter == 3'b011)
					begin
						dwInState		<= IDLE;
					end
					tx_din_reg			<= dwInTemp[dwInCounter];
					tx_write_en_reg		<= 1'b1;
					dwInCounter			<= dwInCounter + 1'b1;
				end
			endcase
		end
	end

endmodule
