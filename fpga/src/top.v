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

	output uart_tx,
	input uart_rx,
	input uart_rts,
	output uart_cts,
	
	output ndat,

	// debug	
	output [4:0] led,
	output reg debug
);


	// UART
	reg [7:0] dataSend = 8'h00;
	reg dataSendCmd = 0;
	reg dataSendValid = 0;
	wire dataSendValid_b;
	wire dataSendAck;
	wire [7:0] dataRecv;
	wire dataRecvCmd;
	wire dataRecvValid;
	reg dataRecvAck = 0;
	reg dataRecvThrottle = 0;

	Uart u0 (
		.clk(clk),
		.rx(uart_rx),
		.cts(uart_cts),
		.tx(uart_tx),
		.rts(uart_rts),
		.dataSend(dataSend),
		.dataSendCmd(dataSendCmd),
		.dataSendValid(dataSendValid_b),
		.dataSendAck(dataSendAck),
		.dataRecv(dataRecv),
		.dataRecvCmd(dataRecvCmd),
		.dataRecvValid(dataRecvValid),
		.dataRecvAck(dataRecvAck),
		.dataRecvThrottle(dataRecvThrottle)
	);
	
	// buffer
	reg [7:0] mem [31:0];
	reg [4:0] memW = 0;
	reg [4:0] memR = 0;
	reg [4:0] memBufLen = 0;
	reg next = 1;
	reg nextBak = 0;
	reg [7:0] nextDat = 0;
	reg nextDatValid = 0;
	
	// state machine
	always @(posedge clk)
	begin
		debug <= 0;
		dataRecvAck <= 1;
		if(dataRecvValid) begin
			if(next) begin
				nextBak <= 1;
			end
			mem[memW] = dataRecv;
			memW <= memW + 1;
			memBufLen <= memBufLen + 1;
			dataRecvAck <= 1;
		end else if((next || nextBak) && (memBufLen > 0)) begin
			nextDat <= mem[memR];
			nextDatValid <= 1;
			memR <= memR + 1;
			memBufLen <= memBufLen - 1;
			nextBak <= 0;
		end else if(next || nextBak) begin
			nextDatValid <= 0;
			nextBak <= 1;
		end
		
		if(memBufLen > 20) begin
			dataRecvThrottle <= 1;
		end else if (memBufLen < 10) begin
			dataRecvThrottle <= 0;
		end

	end

	// ws2812 driver
	reg [23:0] testdat = 24'hFF22FD; // GGRRBB
	reg [9:0] rstcnt = 0;
	reg [3:0] symcnt = 0;
	reg [4:0] bitcnt = 0;
	reg [1:0] state = 0;
	
	reg dat = 0;
	
	always @(posedge clk)
	begin
		next <= 0;
		
		case(state)
			0: begin
				if (rstcnt == 10'b1111111111) begin
					if(nextDatValid) begin
						rstcnt <= 0;
						bitcnt <= 7;
						state <= 1;
						dat <= 1;
					end
				end else begin
					rstcnt <= rstcnt + 1;
					dat <= 0;
				end
			end
			
			1: begin
				if((nextDat[bitcnt] && (symcnt == 10)) ||
					(!nextDat[bitcnt] && (symcnt == 5)))
				begin
					dat <= 0;
				end
			
				if (symcnt == 15) begin
					symcnt <= 0;
					if (bitcnt == 0) begin
						if(!nextDatValid) begin
							state <= 0;
						end else begin
							bitcnt <= 7;
							dat <= 1;
						end
					end else begin
						bitcnt <= bitcnt - 1;
						dat <= 1;
					end
				end else begin
					if((bitcnt == 0) && (symcnt == 12)) begin
						next <= 1;
					end
					symcnt <= symcnt + 1;
				end
			end
		endcase
	end
	
	assign ndat = !dat;

	// debug
	reg [24:0] cnt = 0;

	always @(posedge clk)
	begin
		cnt <= cnt + 1;
	end

	assign led = cnt[24:20];

endmodule
