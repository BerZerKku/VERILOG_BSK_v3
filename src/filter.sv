module Filter (
    input  wire [15:0] in,  // вход
    output wire [15:0] out, // выход

    input wire clk,         // тактовая частота
    input wire aclr         // сброс (активный 1)
);

    // количество ступеней в фильтре входной команды
    localparam NUM_COM_FILTER = 5;

    // состояние команд по умолчанию
    localparam COM_DEFAULT = 16'hFFFF;

    // регистры фильтра команд
    reg [15:0] icom_buf [NUM_COM_FILTER - 1:0];

    assign out = icom_buf[0];
        
    initial begin
        for(int index = 0; index < NUM_COM_FILTER; index = index + 1) begin
            icom_buf[index] <= COM_DEFAULT;
        end
    end

    always @ (posedge clk or posedge aclr) begin : com_in_filter
        if (aclr) begin         
            for(int index = 0; index < NUM_COM_FILTER; index = index + 1) begin
                icom_buf[index] <= COM_DEFAULT;
            end 
        end 
        else begin          
            icom_buf[NUM_COM_FILTER - 1] <= in;
            for(int index = NUM_COM_FILTER - 1; index > 0; index = index - 1) begin
                // Чей-то тут не то!!!
                icom_buf[index - 1] <= (in ^ icom_buf[index]) | in; 
            end
        end
    end

endmodule