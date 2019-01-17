module Filter1 # (
	parameter FILTER_WIDTH = 2      // количество бит для фильтрации (2^n - 1)
) (
    input  wire in,   // вход
    output reg  out,  // выход

    input wire clk,   // тактовая частота
    input wire aclr   // сброс (активный 1)
);
    
    // начальное состояние регистров фильтра
    localparam FLT_DEFAULT = {FILTER_WIDTH{1'b1}};

    // регистры фильтра команд
    reg [FILTER_WIDTH - 1:0] in_buf = FLT_DEFAULT;
  
    //assign out = |{in_buf};
    assign out = (in_buf > 0) ? 1'b1 : 1'b0;

    always @ (posedge clk or posedge aclr) begin : in_filter
        if (aclr) begin
            in_buf <= FLT_DEFAULT;
        end
        else begin
        	if (in == 1'b1) begin
        		in_buf <= FLT_DEFAULT;
            end
        	else begin
        		if (in_buf > 0) begin
        			in_buf <= in_buf - 1;
        		end
        	end
        end
    end

endmodule