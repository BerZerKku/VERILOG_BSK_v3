module clkdiv (
	input wire clk,
	
	output wire div2,
	output wire div4,
	output wire div8,
	output wire div16,
	output wire div32,
	output wire div64,
	output wire div128,
	output wire div256
);
		
	localparam CNT_WIDTH = 8;


	// счетчик 
	reg [CNT_WIDTH - 1:0] cnt;

	// выбор индикации команд передатчика (LED_PRD) или приемника (!LED_PRD)
	reg ind_prm_prd;

	//
	assign div2 = cnt[0];

	//
	assign div4 = cnt[1];

	// 
	assign div8 = cnt[2];

	//
	assign div16 = cnt[3];

	//
	assign div32 = cnt[4];

	//
	assign div64 = cnt[5];

	// 
	assign div128 = cnt[6];

	//
	assign div256 = cnt[7]; 

	initial begin
		cnt = 0;
	end 
	
	always @ (posedge clk) begin : main
		cnt <= cnt + 1;
	end

endmodule