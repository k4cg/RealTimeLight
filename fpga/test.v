/*
	RealTimeLight
	Copyright (C) 2019  Christian Carlowitz <chca@cmesh.de>

	This program is free software: you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation, either version 3 of the License, or
	(at your option) any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

`timescale 1 ns / 1 ps


module test;

	localparam baud_delay = 500;

	reg clk = 0;
	wire [4:0] led;
	
	reg tx = 1;
	wire rx;
	reg rts = 0;
	wire cts;
	
	// clock
	initial
	begin
		#42; forever #42 clk = !clk;
	end
	
	// uut
	Top uut (
		.clk(clk),
		.led(led),
		.uart_rx(tx),
		.uart_tx(rx),
		.uart_rts(rts),
		.uart_cts(cts)
	);

	task usart_send (
		input [7:0] data
	);
		integer i;
		begin
			wait(cts == 0);
			tx <= 0;
			#baud_delay;
			for (i = 0; i < 8; i=i+1) begin
				tx <= data[i];
				#baud_delay;
			end
			tx <= 1;
			#baud_delay;
		end
	endtask
	
	task usart_recv (
		output [7:0] data
	);
		integer i;
		begin
			@(negedge rx);
			#(3*baud_delay/2);
			for (i = 0; i < 8; i=i+1) begin
				data[i] <= rx;
				#baud_delay;
			end
		end
	endtask

	// test procedure
	integer k;
	initial
	begin
		$dumpfile("dump.lx2");
		$dumpvars;
		$display("start");

		repeat(1000) @(posedge clk);
		for(k = 0; k < 3; k=k+1) begin
			usart_send(k);
		end
		#1000000;
		for(k = 0; k < 3; k=k+1) begin
			usart_send(k);
		end
		repeat(10000) @(posedge clk);

		$display("done");
		$finish;
	end
endmodule
