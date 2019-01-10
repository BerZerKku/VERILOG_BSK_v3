module BskPRM (
	inout  wire [15:0] bD,		// шина данных
	input  wire iRd,			// сигнал чтения (активный 0)
	input  wire iWr,			// сигнал записи (активный 0)
	input  wire iRes,			// сигнал сброса (активный 0)
	input  wire iBl,			// сигнал блокирования (активный 0)
	input  wire iKEnable,		// сигнал работы клменника (активный 0)
	input  wire [1:0] iA,		// шина адреса
	input  wire [3:0] iCS,		// сигнал выбора микросхемы	
	input  wire  unit,          // сигнал выбора блока 
                                // - 0 -> 16_01 команды
                                // - 1 -> 32_17 команды  
	
	input  wire [15:0] iComT,	// вход теста команд
	output wire [15:0] oCom,	// выход команд (активный 0)
	output wire [15:0] oComInd,	// выход индикации команд (активный 0)

	output wire oCS,			// выход адреса микросхемы (активный 0)
	output wire oEnable,		// выход разрешения работы клеммника (активный 0)

	output wire [15:0] debug	// выход отладки
);
	
	// Версия прошивки
    localparam [5:0] VERSION = 7'h31;   

    // Код выбора микросхемы (4'b0111 - 16_1 команды, 4'b0101 - 32_17 команды).    
    localparam [3:0] CS = 4'b0111;

    // Код модуля (8'hA6 - 16_1 команды, 8'hA7 - 32_17 команды).
    localparam [7:0] UNIT_CODE = 8'hA6; 

	// код разрешения работы клеммника
	localparam [7:0] ENABLE  = 8'hE1; 

	// команды (активный 0)
	reg [15:0] com = 16'hFFFF;

	// флаг ошибки в командах
	reg [3:0] com_err = 4'b1111;

	// команды индикации  (активный 1)
	reg [15:0] com_ind = 16'h0000;

	// команда управления
	reg [7:0] control = 8'h00;	

	// шина чтения
	wire [15:0] data_bus;

	// код модуля
    wire [7:0] unit_code  = UNIT_CODE + unit; 

	initial begin
		//
	end
	
	// сигнал сброса (активный 1)
	assign aclr = !iRes;	

	// сигнал выбора микросхемы (активный 1)
    wire cs = (iCS == {CS[3:2], !unit, CS[0]});    

	// сигнал блокировки (активный 1)
	assign bl = !(iBl && iRes);

	// сигнал разрешения работы клеммника (активный 1)
	assign enable  = (control == ENABLE);

	// выход разрешения работы клеммника
	assign oEnable = !enable || bl; 

	// сигнал выбора микросхемы (активный)
	assign oCS = !cs;

	// индикация команд
	assign oComInd = ~com_ind;
	
	// выход команд
	assign oCom = (com_err || bl) ? 16'hFFFF : com;
	
	// шина чтения
	assign data_bus =	(iA == 2'b00) ? iComT : 
						(iA == 2'b01) ? com : 
						(iA == 2'b10) ? 16'h0000 :
										{UNIT_CODE, VERSION, iKEnable, enable};

	// двунаправленная шина данных
	assign bD = (iRd || !cs) ? 16'bZ : data_bus; 

	// тестовые сигналы
	assign debug = 16'h0000;

	// запись внутренних регистров
	always @ (posedge iWr or posedge aclr) begin : data_write
		if (aclr) begin
			control <=  8'h00;
			com <= 16'h0000;
			com_err <= 4'b1111;
			com_ind <= 16'h0000;	
		end
		else if (cs && iWr) begin
			case (iA)
				2'b00: begin 
					com[3:0] <= bD[7:4];
					com[7:4] <= bD[15:12];	
					com_err[0] <= !(bD[3:0] == ~bD[7:4]);
					com_err[1] <= !(bD[11:8] == ~bD[15:12]);
				end
				2'b01: begin
					com[11:8] <= bD[7:4];
					com[15:12] <= bD[15:12];
					com_err[2] <= !(bD[3:0] == ~bD[7:4]);
					com_err[3] <= !(bD[11:8] == ~bD[15:12]);
				end
				2'b10: begin
					com_ind <= bD;
				end
				2'b11: begin 
					control <= bD[7:0];
				end
			endcase
		end
	end

endmodule