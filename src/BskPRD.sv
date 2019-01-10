module BskPRD (
    inout  wire [15:0] bD,      // шина данных
    input  wire iRd,            // сигнал чтения (активный 0)
    input  wire iWr,            // сигнал записи (активный 0)
    input  wire iRes,           // сигнал сброса (активный 0)
    input  wire iBl,            // сигнал блокирования (активный 0)
    input  wire iDevice,        // ! не используется
    input  wire clk,            // тактовая частота
    input  wire [1:0] iA,       // шина адреса
    input  wire [3:0] iCS,      // сигнал выбора микросхемы 
    input  wire  unit,          // сигнал выбора блока 
                                // - 0 -> 16_01 команды
                                // - 1 -> 32_17 команды   

    input  reg  [15:0] iCom,    // вход команд (активный 0)
    output wire [15:0] oComInd, // выход индикации команд (активный 0)
    output wire oCS,            // выход адреса микросхемы (активный 0)

    input  wire iTest,          // тестовый сигнал (вход) 
    output wire oTest,          // тестовый сигнал (выход)

    output wire [15:0] debug    // выход отладки
);
    // Версия прошивки
    localparam [6:0] VERSION = 7'h31;   
        
    // Код микросхемы (4'b1011 - 16_1 команды, 4'b1001 - 32_17 команды).    
    localparam [3:0] CS = 4'b1011;  
    
    // Код модуля (8'hA4 - 16_1 команды, 8'hA5 - 32_17 команды).
    localparam [7:0] UNIT_CODE = 8'hA4; 
    
    // начальное состояние регистра команд (активный 0)
    localparam COM_DEFAULT = 16'hFFFF;
    
    // начальное состояние регистра команд индикации (активный 1)
    localparam COM_IND_DEFAULT = 16'h0000;
    
    // разрешение передачи тестового сигнала (активный 1)
    reg test_en = 1'b0;  

    // шина чтения / записи
    wire [15:0] data_bus;
    
    // команды (активный 0).
    reg [15:0] com = COM_DEFAULT;

    // команды индикации (активный 1)
    reg [15:0] com_ind = COM_IND_DEFAULT;

    // сигнал сброса (активный 1)
    wire aclr = !iRes;  
    
    // сигнал выбора микросхемы (активный 1)
    wire cs = (iCS == {CS[3:2], !unit, CS[0]});
    
    // код модуля
    wire [7:0] unit_code  = UNIT_CODE + unit;     
    
    initial begin
        //
    end 
    
    // Тестовый сигнал
    assign oTest = (iBl && test_en) ? iTest : 1'b0; 
//    assign oTest = (test_en) ? iTest : 1'b0; 
    
    // сигнал выбора микросхемы (активный 0)
    assign oCS = !cs;

    // индикация команд 
    assign oComInd = ~com_ind;
    
    // сигналы отладки
//    assign debug = in3;
    assign debug = 16'h0000;
    
    // двунаправленная шина данных
    assign bD = (iRd || !cs) ? 16'bZ : data_bus; 
    
    // шина чтения
    assign data_bus = (iA == 2'b00) ? {~com[7:4],com[7:4],~com[3:0],com[3:0]}:
                      (iA == 2'b01) ? {~com[15:12],com[15:12],~com[11:8],com[11:8]}:
                      (iA == 2'b10) ? com_ind : 
                                      {unit_code, VERSION, test_en};  
                      
    // чтение данных 
    always @ (cs or iRd  or iA or aclr) begin : data_read
        if (aclr) begin
            com <= COM_DEFAULT;
        end
        else begin
            com <= iCom;
        end
    end

    // запись внутренних регистров
    always @ (posedge iWr or posedge aclr) begin : data_write
        if (aclr) begin
            com_ind <= COM_IND_DEFAULT;
            test_en <= 0;
        end
        else if (cs && iWr) begin
            case (iA)
                2'b10: com_ind <= bD;
                2'b11: test_en <= bD[0];
            endcase
        end
    end

endmodule