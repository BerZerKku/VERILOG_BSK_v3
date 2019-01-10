// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this file,
// You can obtain one at http://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2015-2016, Lars Asplund lars.anders.asplund@gmail.com

// You do not need to worry about adding vunit_defines.svh to your
// include path, VUnit will automatically do that for you if VUnit is
// correctly installed (and your python run-script is correct).
`include "vunit_defines.svh"

`timescale 100ps/100ps

module tb_BskPRM;
   localparam integer CLK_PERIOD = 500; // ns
   localparam integer DATA_BUS_DEF = 16'h1234;

   localparam VERSION = 7'h31;
   localparam PASSWORD = 8'hA6;
   localparam CS_16_01 = 4'b0111;
   localparam CS_32_17 = 4'b0101;
   localparam UNIT = 1'b0;


   wire [15:0] bD;      // шина данных
   reg iRd;             // сигнал чтения (активный 0)
   reg iWr;             // сигнал записи (активный 0)
   reg iRes;            // сигнал сброса (активный 0)
   reg iBl;             // сигнал блокирования (активный 0)
   reg iKEnable;        // ???
   reg [1:0] iA;        // шина адреса
   reg [3:0] iCS;       // сигнал выбора микросхемы  
   reg unit; 
   
   reg  [15:0] iComT;   // вход теста команд
   wire [15:0] oCom;    // выход команд (активный 0)
   wire [15:0] oComInd; // выход индикации команд (активный 0)
   wire oCS;            // выход адреса микросхемы (активный 0)
   wire oEnable;        // выход разрешения работы клеммника (активный 0)
   wire [15:0] debug;   // выход отладки

   reg [15:0] data_bus = DATA_BUS_DEF;

   assign bD = (iRd == 0'b0) ? 16'hZZZZ : data_bus; 

   reg [15:0] tmp;

   int a;

   `TEST_SUITE begin
      
      `TEST_SUITE_SETUP begin
         iCS = ~CS_16_01;
         iA = 2'b00;
         iBl = 1'b0;
         iRes = 1'b0;
         iWr = 1'b1;
         iRd = 1'b1;
         iComT = 16'h1331;
         iKEnable = 1'b1;
         unit = 1'b0;
         #1
         $display("Running test suite setup code");
      end

      // проверка CS
      `TEST_CASE("test_cs") begin : test_cs
         iCS = 4'b0000; #1;
         `CHECK_EQUAL(oCS, 1);

         iCS = 4'b1111; #1;
         `CHECK_EQUAL(oCS, 1);

         iCS = CS_16_01; #1;
         `CHECK_EQUAL(oCS, 0);

         unit = 1'b1; #1;
         `CHECK_EQUAL(oCS, 1);

         iCS = CS_32_17; #1;
         `CHECK_EQUAL(oCS, 0);

         // нужна ли эта проверка ?!
         unit = 1'bx; #1;
         `CHECK_EQUAL(oCS, 1'bx);

         // нужна ли эта проверка ?!
         unit = 1'bz; #1;
         `CHECK_EQUAL(oCS, 1'bx);

         unit = 1'b0; #1;  
         `CHECK_EQUAL(oCS, 1);

         iCS = CS_16_01; #1;
         `CHECK_EQUAL(oCS, 0);

         iCS = 4'b1111; #1;
         `CHECK_EQUAL(oCS, 1);
      end

      // проверка чтения 
      `TEST_CASE("test_read") begin : test_read  
         // начальные установки
         iCS = CS_16_01;
         iRd = 1'b0;
         iRes = 1'b1;

         // проверка регистра 00 
         iA = 2'b00; #1;
         $display("iComT = %h, bD = %h", iComT, bD);               
         `CHECK_EQUAL(bD, 16'h1331); 

         // проверка регистра 01
         iA = 2'b01;
         #1;
         `CHECK_EQUAL(bD, 16'h0000); 

         // проверка регистра 10
         iA = 2'b10;
         #1;
         `CHECK_EQUAL(bD, 16'h0000); 

          // проверка регистра 11
         iA = 2'b11;
         #1;
         tmp = (PASSWORD << 8) + (VERSION << 2) + 2'b10;
         `CHECK_EQUAL(bD, tmp); 

         // проверка корректного считывания во время сброса 
         iRes = 1'b0;
         #1;
         `CHECK_EQUAL(bD, tmp); 

         // проверка корректного считывания при наличии сигнала записи
         iWr = 1'b0;
         #1;
         `CHECK_EQUAL(bD, tmp); 

         // проверка на отсутсвие сигнала чтения
         iRd = 1'b1;
         #1;
         `CHECK_EQUAL(bD, DATA_BUS_DEF); 

         // проверка при неактивном CS
         iRd = 1'b0;
         iCS = ~iCS;
         #1;
         `CHECK_EQUAL(bD, 16'hZZZZ); 

         // проверка корректного считывания еще раз
         // проверка регистра 11
         iCS = CS_16_01;
         #1;
         `CHECK_EQUAL(bD, tmp); 

         // проверка влияния управляющих сигналов на чтение 
         iA = 2'b00; 
         iComT = 16'h1331; #1;
         `CHECK_EQUAL(bD, 16'h1331); 
         iComT = 16'h987F; #1;         
         `CHECK_EQUAL(bD, 16'h987F); 
         iCS = ~iCS; #1; 
         `CHECK_EQUAL(bD, 16'hZZZZ); // 3-е состояние
         iCS = CS_16_01; #1;
         `CHECK_EQUAL(bD, 16'h987F); //  
         iComT = 16'h1234; #1;
         `CHECK_EQUAL(bD, 16'h1234); // 
         iRd = 1'b1; #1;               
         `CHECK_EQUAL(bD, DATA_BUS_DEF);  // сигнал на входе шины 
         iRd = 1'b0; #1;
         `CHECK_EQUAL(bD, 16'h1234); // 
         iComT = 16'h7893; #1;
         `CHECK_EQUAL(bD, 16'h7893); //     
         iA = 2'b01; #1; 
         iA = 2'b00; #1;
         `CHECK_EQUAL(bD, 16'h7893); // 
      end

       // проверка записи
      `TEST_CASE("test_write") begin : test_write
         // начальные установки
         iCS = CS_16_01;
         iRes = 1'b1;
        
         // проверка начального состояния регистров
         iRd = 1'b0;
         iA = 2'b00; #1;
         `CHECK_EQUAL(bD, 16'h1331); 
         iA = 2'b01; #1;
         `CHECK_EQUAL(bD, 16'h0000); 
         iA = 2'b10; #1;
         `CHECK_EQUAL(bD, 16'h0000); 
         iA = 2'b11; #1; 
         tmp = (PASSWORD << 8) + (VERSION << 2) + 2'b10;
         `CHECK_EQUAL(bD, tmp);

         // проверка записи данных в регистры 00 и 01
         iA = 2'b00;
         iRd = 1'b1; #1;
         data_bus = 16'hA5C3;
         iWr = 1'b0; #1; iWr = 1'b1; #1;
         data_bus = 16'h8769;
         iA = 2'b01; #1;
         iWr = 1'b0; #1; iWr = 1'b1; #1;
         iRd = 1'b0; #1;
         `CHECK_EQUAL(bD, 16'h86AC);
            
         // проверка записи данных в регистр 10
         data_bus = 16'h1234;
         iA = 2'b10; 
         iRd = 1'b1; #1;
         iWr = 1'b0; #1;
         `CHECK_EQUAL(oComInd, 16'hFFFF);
         iWr = 1'b1; #1;
         `CHECK_EQUAL(oComInd, ~16'h1234);

         // проверка записи данных в регистр 11
         data_bus = 8'hE1;
         iA = 2'b11; 
         iRd = 1'b1; #1;
         iWr = 1'b0; #1; iWr = 1'b1; #1;
         iRd = 1'b0; #1;
         tmp = (PASSWORD << 8) + (VERSION << 2) + 2'b11;
         `CHECK_EQUAL(bD, tmp);
         data_bus = 8'h11;
         iRd = 1'b1; 
         iWr = 1'b0; #1; iWr = 1'b1; #1;
         iRd = 1'b0; #1;
         tmp = (PASSWORD << 8) + (VERSION << 2) + 2'b10;
         `CHECK_EQUAL(bD, tmp);
         
         // проверка при неактивном CS
         data_bus  = 16'h1516; 
         iA = 2'b10; 
         iRd = 1'b1; #1;
         iWr = 1'b0; #1; iWr = 1'b1; #1;
         `CHECK_EQUAL(oComInd, ~16'h1516);
         iCS = ~iCS; #1;
         `CHECK_EQUAL(oComInd, ~16'h1516);
         data_bus  = 16'h3456;
         iWr = 1'b0; #1; iWr = 1'b1; #1;
         `CHECK_EQUAL(oComInd, ~16'h1516);
         iCS = CS_16_01; #1;

         // проверка очистки регистров при сбросе
         iRes = 1'b0; iRd = 1'b0; #1;
         iA = 2'b00; #1;
         `CHECK_EQUAL(oComInd, ~16'h0000);
         iA = 2'b01; #1;
         `CHECK_EQUAL(bD, 16'h0000); 
         iA = 2'b11; #1;
         tmp = (PASSWORD << 8) + (VERSION << 2) + 2'b10;
         `CHECK_EQUAL(bD, tmp);
      end

      // проверка команд индикации
      `TEST_CASE("test_com_ind") begin : test_com_ind
         // проверка начального состояния
         `CHECK_EQUAL(oComInd, 16'hFFFF);

         // начальные установки
         data_bus = 16'h9231;
         iCS = CS_16_01;
         iA = 2'b10;
         

         // проверка записи при наличии сигнала сброса
         iWr = 1'b0; #1; iWr = 1'b1; #1;
         `CHECK_EQUAL(oComInd, 16'hFFFF);

         // проверка записи
         iRes = 1'b1; #1;
         iWr = 1'b0; #1; iWr = 1'b1; #1;
         `CHECK_EQUAL(oComInd, ~data_bus);
         
         // проверка в остутсвтии сигнала CS
         iCS = ~iCS; #1;
         `CHECK_EQUAL(oComInd, ~data_bus);

         // проверка влияния сигнала блокировки
         iBl = 1'b1; #1;
         `CHECK_EQUAL(oComInd, ~data_bus);
         iBl = 1'b0; #1;
         `CHECK_EQUAL(oComInd, ~data_bus);

         // проверка сигнала сброса
         iRes = 1'b0; #1;
         `CHECK_EQUAL(oComInd, 16'hFFFF);

      end

      // проверка команд 
      `TEST_CASE("test_com") begin : test_com
         // проверка начального состояния
         `CHECK_EQUAL(oCom, 16'hFFFF);

         iRes = 1'b1;
         iCS = CS_16_01;
         iBl = 1'b1;
         iRes = 1'b1; #1;

         // запись корректного значения 1-8 команд
         data_bus = 16'hA55A;
         iA = 2'b00; 
         iWr = 1'b0; #1; iWr = 1'b1; #1;
         `CHECK_EQUAL(oCom, 16'hFFFF);
         // запись корректного значения 16-9 команд
         data_bus = 16'hF078;
         iA = 2'b01;
         iWr = 1'b0; #1; iWr = 1'b1; #1;
         `CHECK_EQUAL(oCom, 16'hF7A5);

         // проверка на ошибку в переданных командах 1-8
         iA = 2'b00;
         for(int count = 0; count < 16; count += 1) begin
            tmp = 16'hA55A;
            data_bus = tmp;
            data_bus[count] = !data_bus[count];
            iWr = 1'b0; #1; iWr = 1'b1; #1;
            `CHECK_EQUAL(oCom, 16'hFFFF);
            data_bus = tmp;
            iWr = 1'b0; #1; iWr = 1'b1; #1;
            `CHECK_EQUAL(oCom, 16'hF7A5);
         end

         // проверка на ошибку в переданных командах 16-9
         iA = 2'b01;
         for(int count = 0; count < 16; count += 1) begin
            tmp = 16'hF078;
            data_bus = tmp;
            data_bus[count] = !data_bus[count];
            iWr = 1'b0; #1; iWr = 1'b1; #1;
            `CHECK_EQUAL(oCom, 16'hFFFF);
            data_bus = tmp;
            iWr = 1'b0; #1; iWr = 1'b1; #1;
            `CHECK_EQUAL(oCom, 16'hF7A5);
         end
         
         iBl = 1'b0; #1;
         `CHECK_EQUAL(oCom, 16'hFFFF);
         iBl = 1'b1;
         iRes = 1'b0; #1;
         `CHECK_EQUAL(oCom, 16'hFFFF);
      end

      // проверка сигнала разрешения работы клеммника
      `TEST_CASE("test_enable_signal") begin : test_enable_signal
         `CHECK_EQUAL(oEnable, 1'b1);
         
         iBl = 1'b1;
         iRes = 1'b1;
         iCS = CS_16_01;
         `CHECK_EQUAL(oEnable, 1'b1);
         data_bus = 8'hE1;
         iA = 2'b11; 
         iWr = 1'b0; #1; iWr = 1'b1; #1;
         `CHECK_EQUAL(oEnable, 1'b0);
         iCS = ~iCS; #1;
         `CHECK_EQUAL(oEnable, 1'b0);
         iBl = 1'b0; #1;
         `CHECK_EQUAL(oEnable, 1'b1);
         iBl = 1'b1;
         iRes = 1'b0; #1;
         `CHECK_EQUAL(oEnable, 1'b1);
      end

   end;

   `WATCHDOG(1ms);

   BskPRM  dut(.*);

endmodule