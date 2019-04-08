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

module Top
(
	input clk,
	
	output reg dat,

	// debug	
	output [4:0] led
);

	// ws2812 driver
	reg [23:0] testdat = 24'hFF22FD;
	reg [9:0] rstcnt = 0;
	reg [3:0] symcnt = 0;
	reg [4:0] bitcnt = 0;
	reg [1:0] state = 0;
	
	always @(posedge clk)
	begin
		case(state)
			0: begin
				if (rstcnt == 10'b1111111111) begin
					rstcnt <= 0;
					bitcnt <= 23;
					state <= 1;
					dat <= 1;
				end else begin
					rstcnt <= rstcnt + 1;
					dat <= 0;
				end
			end
			
			1: begin
				if((testdat[bitcnt] && (symcnt == 10)) ||
					(!testdat[bitcnt] && (symcnt == 5)))
				begin
					dat <= 0;
				end
			
				if (symcnt == 15) begin
					symcnt <= 0;
					if (bitcnt == 0) begin
						state <= 0;
					end else begin
						bitcnt <= bitcnt - 1;
						dat <= 1;
					end
				end else begin
					symcnt <= symcnt + 1;
				end
			end
		endcase
	end

	// debug
	reg [24:0] cnt = 0;

	always @(posedge clk)
	begin
		cnt <= cnt + 1;
	end

	assign led = cnt[24:20];

endmodule
