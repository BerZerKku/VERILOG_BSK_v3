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

module tb_BskPRD;
   localparam integer CLK_PERIOD = 500; // ns
   localparam integer DATA_BUS_DEF = 16'h1234;

   localparam VERSION = 7'h25;
   localparam PASSWORD = 8'hA4;
   localparam CS = 4'b1011;


   wire [15:0] bD;      // шина данных
   reg iRd;             // сигнал чтения (активный 0)
   reg iWr;             // сигнал записи (активный 0)
   reg iRes;            // сигнал сброса (активный 0)
   reg iBl;             // сигнал блокирования (активный 0)
   reg iDevice;         // ???
   reg clk;             // тактовая частота
   reg [1:0] iA;        // шина адреса
   reg [3:0] iCS;       // сигнал выбора микросхемы   
   
   reg  [15:0] iCom;    // вход команд
   wire [15:0] oComInd; // выход индикации команд (активный 0)
   wire oCS;            // выход адреса микросхемы (активный 0)
   wire oTest;          // тестовый сигнал (частота)
   wire [15:0] debug;   // выход отладки


   reg [15:0] data_bus = DATA_BUS_DEF;

   assign bD = (iRd == 0'b0) ? 16'hZZZZ : data_bus; 

   reg [15:0] tmp;
   integer cnt;


   `TEST_SUITE begin
      
      `TEST_SUITE_SETUP begin
         iCS = ~CS;
         iA = 2'b00;
         iBl = 1'b0;
         iRes = 1'b0;
         iWr = 1'b1;
         iRd = 1'b1;
         iCom = 16'h1331;
         clk = 1'b0;
         #1;
         $display("Running test suite setup code");
      end

      // проверка CS
      `TEST_CASE("test_cs") begin : test_cs
         iCS = 4'b0000; #1;
         `CHECK_EQUAL(oCS, 1);

         iCS = 4'b1111; #1;
         `CHECK_EQUAL(oCS, 1);

         iCS = CS; #1;
         `CHECK_EQUAL(oCS, 0);

         iCS = 4'b1111; #1;
         `CHECK_EQUAL(oCS, 1);
      end

      // проверка чтения 
      `TEST_CASE("test_read") begin : test_read  
         // начальные установки
         iCS = CS;
         iRd = 1'b0;
         iRes = 1'b1;

         // проверка регистра 00
         iA = 2'b00; #1;
         `CHECK_EQUAL(bD, 16'hC3E1); 

          // проверка регистра 01
         iA = 2'b01; #1;
         `CHECK_EQUAL(bD, 16'hE1C3); 

         // проверка регистра 10
         iA = 2'b10; #1;
         `CHECK_EQUAL(bD, 16'h0000); 

          // проверка регистра 11
         iA = 2'b11; #1;
         tmp = (PASSWORD << 8) + (VERSION << 1) + 1'b0;
         `CHECK_EQUAL(bD, tmp); 

         // проверка влияния сигнала iA на чтение команд
         iA = 2'b00; #1; 
         iCom = 16'h0000; #1;
         `CHECK_EQUAL(bD, 16'hC3E1); 
         iA = 2'b01; #1;
         `CHECK_EQUAL(bD, 16'hF0F0);

         // проверка влияния сигнала iRd на чтение команд 
         iCom = 16'hFFFF; #1;
         `CHECK_EQUAL(bD, 16'hF0F0);
         iRd = 1'b1; #1;
         `CHECK_EQUAL(bD, data_bus);
         iRd = 1'b0; #1;
         `CHECK_EQUAL(bD, 16'h0F0F);

         // проверка влияния сигнала iCS на чтение команд
         iCom = 16'h1111; #1; 
         `CHECK_EQUAL(bD, 16'h0F0F);
         iCS = ~CS; #1;
         `CHECK_EQUAL(bD, 16'hZZZZ);
         iCS = CS; #1;
         `CHECK_EQUAL(bD, 16'hE1E1);

         // проверка влияния сигнала iRes на чтение команд
         iCom = 16'h7384; #1;
         `CHECK_EQUAL(bD, 16'hE1E1);
         iRes = 1'b0; #1; 
         `CHECK_EQUAL(bD, 16'hF0F0); 
         iCom = 16'h1111; #1
         `CHECK_EQUAL(bD, 16'hF0F0); 
         iRes = 1'b1; #1;
         `CHECK_EQUAL(bD, 16'hE1E1); 

         // проверка влияния сигнала iWr на чтение команд
         iCom = 16'h7384; #1;
         `CHECK_EQUAL(bD, 16'hE1E1);
         iWr = 1'b0; #1;
         `CHECK_EQUAL(bD, 16'hE1E1);
         iWr = 1'b1; #1;
         `CHECK_EQUAL(bD, 16'hE1E1);
      end

      `TEST_CASE("test_write") begin : test_write
         // начальные установки
         iCS = CS;
         iRes = 1'b1;
        
         // проверка начального состояния регистров
         iRd = 1'b0;
         iA = 2'b10; #1;
         `CHECK_EQUAL(bD, 16'h0000); 
         iA = 2'b11; #1;
         `CHECK_EQUAL(bD[0], 1'b0); 

         // проверка записи данных по адресу 2'b10 + проверка записи пр фронту iWr
         iA = 2'b10;
         tmp = 16'h1111;
         data_bus = tmp;
         iRd = 1'b1;
         iWr = 1'b0; #1; 
         `CHECK_EQUAL(oComInd, 16'hFFFF); 
         iWr = 1'b1; #1;   
         `CHECK_EQUAL(oComInd, ~tmp); 
         iRd = 1'b0; #1;
         `CHECK_EQUAL(bD, tmp);

         // проверка записи данных по адресу 2'b11
         iA = 2'b11;
         data_bus = 16'h0001;
         iRd = 1'b1;
         iWr = 1'b0; #1; 
         iWr = 1'b1; #1;
         iRd = 1'b0; #1;
         `CHECK_EQUAL(bD, (PASSWORD << 8) + (VERSION << 1) + 1'b1); 
         
         // проверка при неактивном CS
         data_bus  = 0'h1516; 
         iA = 2'b10; #1;
         iRd = 1'b1; iWr = 1'b0; 
         iCS = ~CS; #1;
         iWr = 1'b1; #1; 
         iCS = CS; #1;
         iRd = 1'b0; #1;
         `CHECK_EQUAL(bD, tmp);

         // проверка очистки регистров при сбросе
         iRes = 1'b0; #1;
         `CHECK_EQUAL(bD, 16'h0000); 
         iA = 2'b11; #1;
         `CHECK_EQUAL(bD, (PASSWORD << 8) + (VERSION << 1) + 1'b0);
      end

      `TEST_CASE("test_com_ind") begin : test_com_ind
         // проверка начального состояния
         `CHECK_EQUAL(oComInd, 16'hFFFF);

         // начальные установки
         tmp = 16'h9231;
         data_bus = tmp;
         iCS = CS;
         iA = 2'b10; 

         // проверка сброса
         // проверка при установленном сигнале сброса
         iWr = 1'b0; #1;
         `CHECK_EQUAL(oComInd, 16'hFFFF);
         iWr = 1'b1; #1;
         `CHECK_EQUAL(oComInd, 16'hFFFF);

         // проверка в отсутсвии сигнала сброса
         iRes = 1'b1; #1;
         iWr = 1'b0; #1;
         `CHECK_EQUAL(oComInd, 16'hFFFF);
         iWr = 1'b1; #1;
         `CHECK_EQUAL(oComInd, ~data_bus);

         // проверка в остутсвтии сигнала CS
         iCS = ~CS; #1;
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

      `TEST_CASE("test_test_signal") begin : test_test_signal
         // проверка начального состояния
         `CHECK_EQUAL(oTest, 1'b0); 
         check_freq(tmp[0]);
         `CHECK_EQUAL(tmp[0], 1'b0);

         // проверка при отсутствии сигнала сброса
         iRes = 1'b1; #1;
         check_freq(tmp[0]);
         `CHECK_EQUAL(oTest, 1'b0); 
         `CHECK_EQUAL(tmp[0], 1'b0);

         // проверка при сигнале блокировки
         iBl = 1'b1; #1;
         check_freq(tmp[0]);
         `CHECK_EQUAL(oTest, 1'b0); 
         `CHECK_EQUAL(tmp[0], 1'b0);

         // проверка при установленном бите test_en
         data_bus = 16'h0001;
         iCS = CS;
         iA = 2'b11;
         iWr = 1'b0; #1;
         iWr = 1'b1; #1;
         check_freq(tmp[0]);
         `CHECK_EQUAL(oTest, 1'b1); 
         `CHECK_EQUAL(tmp[0], 1'b1);

         // проверка при сигнале блокировки
         iBl = 1'b0; #1;
         check_freq(tmp[0]);
         `CHECK_EQUAL(oTest, 1'b0); 
         `CHECK_EQUAL(tmp[0], 1'b0);

         // проверка при снятии сигнала блокировки
         iBl = 1'b1; #1;
         check_freq(tmp[0]);
         `CHECK_EQUAL(oTest, 1'b1); 
         `CHECK_EQUAL(tmp[0], 1'b1);

         // проверка при подаче сигнала сброса
         iRes = 1'b0; #1;
         check_freq(tmp[0]);
         `CHECK_EQUAL(oTest, 1'b0); 
         `CHECK_EQUAL(tmp[0], 1'b0);
      end

   end;

   `WATCHDOG(1ms);

   // проверка делителя частоты
   task check_freq;
   output state;
   begin
      integer old;
      integer cycle; 
      integer div;

      cnt = 0;
      cycle = 24; // количество циклов проверки
      div = 8;    // необходимый делитель частоты
      for(integer i = 0; i < cycle; i++) begin
         clk = ~clk;
         old = oTest; #1;
         cnt += (oTest != old);
      end 
      $display("%d", cnt);
      state = (cnt == cycle/8);  
   end
   endtask

   BskPRD #(.VERSION(VERSION), .PASSWORD(PASSWORD), .CS(CS)) dut(.*);

endmodule