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

module Uart #(
	parameter div = 12 // 2 MBaud @ 12 MHz; CHECK: rxDiv/txDiv width!!!
)(
	input clk,
	
	input rx,
	output reg cts = 0,
	
	output reg tx = 1,
	input rts,
	
	input [7:0] dataSend,
	input dataSendCmd,
	input dataSendValid,
	output reg dataSendAck = 1,
	
	output reg [7:0] dataRecv = 0,
	output reg dataRecvCmd = 0,
	output reg dataRecvValid = 0,
	input dataRecvAck,
	input dataRecvThrottle
);

	localparam S_Idle = 0;
	localparam S_Start = 1;
	localparam S_Data = 2;
	localparam S_Stop = 3;
	
	//*** receiver ***
	
	reg [1:0] rxBuf = 2'b11;
	reg [7:0] rxData = 0;
	reg [2:0] rxBitCnt = 0;
	reg [2:0] rxDiv = 0;
	reg [1:0] rxState = S_Idle;
	reg rxNext = 0;
	reg rxCmd = 0;
	
	reg dataRecvAckLast = 0;
	
	always @(posedge clk)
	begin
		// clear signals
		dataRecvValid <= 0;
		
		// sample input signal
		rxBuf <= {rxBuf[0],rx};
		
		// clock divider
		if(rxDiv == (div/2-1)) begin
			rxDiv <= 0;
			rxNext <= 1;
		end else begin
			rxDiv <= rxDiv + 1;
			rxNext <= 0;
		end
		
		if(dataRecvThrottle) begin
			cts <= 1;
		end else begin
			cts <= 0;
		end

		// state machine
		dataRecvAckLast <= dataRecvAck;
		case(rxState)
			S_Idle: begin
				//if(rxNext && dataRecvAckLast) begin
				//	cts <= 0;
				//end
				if(rxBuf == 2'b10) begin
					rxDiv <= div/4;
					rxNext <= 0;
					rxState <= S_Start;
				end
			end
			
			S_Start: begin
				if(rxNext) begin
					rxState <= rxBuf[0] ? S_Idle : S_Data;
				end
			end
			
			S_Data: begin
				if(rxNext) begin
					rxData[rxBitCnt] <= rxBuf[0];
					if(rxBitCnt == 7) begin
						rxBitCnt <= 0;
						rxState <= S_Stop;
					end else begin
						rxBitCnt <= rxBitCnt + 1;
					end
				end
			end
			
			S_Stop: begin
				if(rxNext) begin
					if((rxBuf[0] == 1) && dataRecvAck) begin
						if(rxCmd) begin
							if(rxData == 8'h00) begin
								dataRecv <= 8'h2a;
								dataRecvValid <= 1;
								dataRecvCmd <= 0;
							end else begin
								dataRecv <= rxData;
								dataRecvValid <= 1;
								dataRecvCmd <= 1;
							end
							rxCmd <= 0;
						end else begin
							if(rxData == 8'h2a) begin
								rxCmd <= 1;
							end else begin
								dataRecv <= rxData;
								dataRecvValid <= 1;
								dataRecvCmd <= 0;
							end					
						end
						//cts <= 1;
					end
					rxState <= S_Idle;
				end
			end
		endcase
	end
	
	//*** transmitter ***
	
	reg [7:0] txData = 0;
	reg [2:0] txBitCnt = 0;
	reg [2:0] txDiv = 0;
	reg [1:0] txState = S_Idle;
	reg txNext = 0;
	
	always @(posedge clk)
	begin
		// clear signals
		dataSendAck <= 0;
		
		// clock divider
		if(txDiv == (div/2-1)) begin
			txDiv <= 0;
			txNext <= 1;
		end else begin
			txDiv <= txDiv + 1;
			txNext <= 0;
		end
		
		// state machine
		case(txState)
			S_Idle: begin
				tx <= 1;
				if(dataSendValid && !rts) begin
					txState <= S_Start;
					txData <= dataSend;
					dataSendAck <= 1;
				end
			end
			
			S_Start: begin
				if(txNext) begin
					tx <= 0;
					txState <= S_Data;
				end
			end
			
			S_Data: begin
				if(txNext) begin
					tx <= txData[txBitCnt];
					if(txBitCnt == 7) begin
						txBitCnt <= 0;
						txState <= S_Stop;
					end else begin
						txBitCnt <= txBitCnt + 1;
					end
				end
			end
			
			S_Stop: begin
				if(txNext) begin
					tx <= 1;
					txState <= S_Idle;
				end
			end
			
		endcase
	end

endmodule
