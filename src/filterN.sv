module FilterN # (
    parameter NUM_SIGNALS  = 16,    // количество команд
    parameter FILTER_WIDTH = 2      // количество бит для фильтрации (2^n - 1)
) (
    input  wire [NUM_SIGNALS - 1:0] in,   // вход
    output wire  [NUM_SIGNALS - 1:0] out,  // выход

    input wire clk,     // тактовая частота
    input wire aclr     // сброс (активный 1)
);
	// Вариант стандартный
    // Filter1 # (.FILTER_WIDTH(FILTER_WIDTH)) ff [NUM_SIGNALS - 1:0] (in, out, clk, aclr);
    
    // Вариант через generate
    generate
        genvar i;
    	for(i = 0; i < NUM_SIGNALS; i = i + 1) begin : F
    		Filter1 # (.FILTER_WIDTH(FILTER_WIDTH)) f (in[i], out[i], clk, aclr);
    	end
    endgenerate

endmodule