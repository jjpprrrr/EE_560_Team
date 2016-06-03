////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 1995-2003 Xilinx, Inc.
// All Right Reserved.
////////////////////////////////////////////////////////////////////////////////
//   ____  ____ 
//  /   /\/   / 
// /___/  \  /    Vendor: Xilinx 
// \   \   \/     Version : 10.1.03
//  \   \         Application : ISE
//  /   /         Filename : parity_tb.v
// /___/   /\     Timestamp : Mon May 20 21:59:20 2013
// \   \  /  \ 
//  \___\/\___\ 
//
//Command: 
//Design Name: parity_tb
//Device: Xilinx
//
`timescale 1ns/1ps

module parity_tb;
    reg [31:0] in_data = 32'b00000000000000000000000000000001;
    wire parity;


    parity UUT (
        .in_data(in_data),
        .parity(parity));

    integer TX_ERROR = 0;
    
    initial begin  // Open the results file...
        #1000 // Final time:  1000 ns
        if (TX_ERROR == 0) begin
            $display("No errors or warnings.");
        end else begin
            $display("%d errors found in simulation.", TX_ERROR);
        end
        $stop;
    end

    initial begin
        // -------------  Current Time:  100ns
        #100;
        in_data = 32'b00000000000000000000000000000010;
        // -------------------------------------
        // -------------  Current Time:  200ns
        #100;
        in_data = 32'b00000000000000000000000000000011;
        // -------------------------------------
        // -------------  Current Time:  250ns
        #50;
        CHECK_parity(1'b0);
        // -------------------------------------
        // -------------  Current Time:  300ns
        #50;
        in_data = 32'b00000000000000000000000000000100;
        // -------------------------------------
        // -------------  Current Time:  350ns
        #50;
        CHECK_parity(1'b1);
        // -------------------------------------
        // -------------  Current Time:  400ns
        #50;
        in_data = 32'b00000000000000000000000000000101;
        // -------------------------------------
        // -------------  Current Time:  450ns
        #50;
        CHECK_parity(1'b0);
        // -------------------------------------
        // -------------  Current Time:  500ns
        #50;
        in_data = 32'b00001111111111111111111111111110;
        // -------------------------------------
        // -------------  Current Time:  550ns
        #50;
        CHECK_parity(1'b1);
        // -------------------------------------
        // -------------  Current Time:  600ns
        #50;
        in_data = 32'b11111111111111111111111111111111;
        // -------------------------------------
        // -------------  Current Time:  650ns
        #50;
        CHECK_parity(1'b0);
    end

    task CHECK_parity;
        input NEXT_parity;

        #0 begin
            if (NEXT_parity !== parity) begin
                $display("Error at time=%dns parity=%b, expected=%b", $time, parity, NEXT_parity);
                TX_ERROR = TX_ERROR + 1;
            end
        end
    endtask

endmodule

