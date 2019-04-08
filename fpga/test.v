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

	localparam baud_delay = 1000;

	reg clk = 0;
	wire [4:0] led;
	
	reg tx = 1;
	wire rx;
	
	// clock
	initial
	begin
		#42; forever #42 clk = !clk;
	end
	
	// uut
	Top uut (
		.clk(clk),
		.led(led)
	);

	task usart_send (
		input [7:0] data
	);
		integer i;
		begin
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
	initial
	begin
		$dumpfile("dump.lx2");
		$dumpvars;
		$display("start");

		repeat(10) @(posedge clk);
		//usart_send(8'h31);
		repeat(100) @(posedge clk);

		$display("done");
		$finish;
	end
endmodule
