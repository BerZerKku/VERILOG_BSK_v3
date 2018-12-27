module BskLED (
	input wire clk,
	input wire [15:0] iLedPrd,	// индикация команд передатчика
	input wire [15:0] iLedPrm,	// индикация команд приемника
								
										// (0 - хранение данных, 1 - запись нового значения)
	output wire oLePrd,			// сигнал управления буфером индикации команд передатчика 
	output wire oLePrm,			// сигнал управления буфером индикации команд приемника 

	output wire [15:0] oLed 	// выход индикации команд (активный 0)
);
		
	// максимальное значение счетчика
	localparam CNT_MAX = 10;

	// количество бит для счетчика 
	localparam CNT_WIDTH = $clog2(CNT_MAX);	

	// 
	localparam LED_PRD = 1'b0;

	// 
	localparam LED_PRM = 1'b1;

	// счетчик 
	reg [CNT_WIDTH-1:0] cnt;

	// выбор индикации команд передатчика (LED_PRD) или приемника (LED_PRM)
	reg ind_prm_prd;

	// выход индикации команд 
	assign oLed = (ind_prm_prd == LED_PRD) ? iLedPrd : iLedPrm;

	// сигнал управления буфером индикации команд передатчика 
	assign oLePrd = ((ind_prm_prd == LED_PRD) && (cnt > 1'b1)) ? 1'b1 : 1'b0;

	// сигнал управления буфером индикации команд приемника 
	assign oLePrm = ((ind_prm_prd == LED_PRM) && (cnt > 1'b1)) ? 1'b1 : 1'b0;

	initial begin
		cnt <= 1'b0;
		ind_prm_prd <= LED_PRD;
	end 
	
	always @ (posedge clk) begin : main
		if (cnt >= CNT_MAX) begin
			cnt <= 1'b1;
			ind_prm_prd <= (ind_prm_prd == LED_PRD) ? LED_PRM : LED_PRD;
		end
		else begin
			cnt <= cnt + 1;
		end
	end

endmodule