module Filter # (
    parameter NUM_SIGNALS  = 16,    // количество команд
    parameter FILTER_WIDTH = 2      // количество бит для фильтрации (2^n - 1)
) (
    input  wire [NUM_SIGNALS - 1:0] in,   // вход
    output reg  [NUM_SIGNALS - 1:0] out,  // выход

    input wire clk,         // тактовая частота
    input wire aclr         // сброс (активный 1)
);

    // состояние команд по умолчанию
    localparam OUT_DEFAULT = {NUM_SIGNALS{1'b1}}; 

    // начальное состояние регистров фильтра
    localparam FLT_DEFAULT = {FILTER_WIDTH{1'b1}};

    // регистры фильтра команд
    reg [FILTER_WIDTH - 1:0] icom_buf [NUM_SIGNALS - 1:0];

    initial begin
        for(int i = 0; i < 16; i = i + 1) begin
            icom_buf[i] <= FLT_DEFAULT;
        end
        out <= OUT_DEFAULT;
    end

    always @ (posedge clk or posedge aclr) begin : com_in_filter
        if (aclr) begin
            for(int i = 0; i < 16; i = i + 1) begin
                icom_buf[i] <= FLT_DEFAULT;
            end
            out <= OUT_DEFAULT;
        end
        else begin
            for(int i = 0; i < 16; i = i + 1) begin
                if (in[i] == 1'b1) begin
                    icom_buf[i] <= FLT_DEFAULT;
                end 
                else begin 
                    if (icom_buf[i] > 0) begin
                        icom_buf[i] <= icom_buf[i] - 1'b1;
                    end
                end
            
                out[i] <= (icom_buf[i] == 0) ? 1'b0 : 1'b1; 
            end
        end
    end

endmodule