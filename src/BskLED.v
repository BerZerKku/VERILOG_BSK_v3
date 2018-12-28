module BskLED (
	input wire clk,
	input wire [15:0] iLedPrd,	// индикация команд передатчика
	input wire [15:0] iLedPrm,	// индикация команд приемника
								
										// (0 - хранение данных, 1 - запись нового значения)
	output reg oLePrd,			// сигнал управления буфером индикации команд передатчика 
	output reg oLePrm,			// сигнал управления буфером индикации команд приемника 

	output wire [15:0] oLed 	// выход индикации команд (активный 0)
);
	
	localparam LE_DATA 	= 1'b0;
	localparam LE_LATCH 	= 1'b1;
	
	reg latch;
	
	localparam SET_PRD 	= 1'b0;
	localparam SET_PRM	= 1'b1;
	
	reg state;

	initial begin
		state = SET_PRD;
		oLePrd = LE_DATA;
		oLePrm = LE_DATA;
	end 
	
	assign oLed = (state == SET_PRD) ? iLedPrd : iLedPrm;
//	assign oLed = (state == SET_PRD) ? 16'hFF00 : 16'h00FF;
	
	always @ (posedge clk) begin : main
	
		case(state)
		
			SET_PRD: begin
				oLePrd <= (oLePrd == LE_LATCH) ? LE_DATA : LE_LATCH;
				state  <= (oLePrd == LE_LATCH) ? SET_PRM : SET_PRD;			
			end
			
			SET_PRM: begin
				oLePrm <= (oLePrm == LE_LATCH) ? LE_DATA : LE_LATCH;
				state  <= (oLePrm == LE_LATCH) ? SET_PRD : SET_PRM;
			end
			
		endcase
	
	end

endmodule