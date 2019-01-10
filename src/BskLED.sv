module BskLED (
	input wire clk,
	input wire [15:0] iLedPrd,	// индикация команд передатчика
	input wire [15:0] iLedPrm,	// индикация команд приемника
								
								// (0 - хранение данных, 1 - запись нового значения)
	output reg oLePrd,			// сигнал управления буфером индикации команд передатчика 
	output reg oLePrm,			// сигнал управления буфером индикации команд приемника 

	output wire [15:0] oLed 	// выход индикации команд (активный 0)
);
	
	// хранение данных
	localparam LE_DATA 	= 1'b0;
	// установка нового значения
	localparam LE_LATCH = 1'b1;
	
	// индикация команд передатчика
	localparam SET_PRD 	= 1'b0;
	// индикация команд приемника
	localparam SET_PRM	= 1'b1;
	
	reg state;

	initial begin
		state = SET_PRD;
		oLePrd = LE_DATA;
		oLePrm = LE_DATA;
	end 
	
	assign oLed = (state == SET_PRD) ? iLedPrd : iLedPrm;
	
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