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

module tb_BskLED;
   reg clk;             // 
   reg [15:0] iLedPrd;  // 
   reg [15:0] iLedPrm;  //  
   
   wire oLePrd;         //
   wire oLePrm;         //
   wire [15:0] oLed;    // 

   localparam CNT_MAX = 10;

   `TEST_SUITE begin
      
      `TEST_SUITE_SETUP begin
         clk = 1'b0;
         iLedPrd = 16'hFFFF;
         iLedPrm = 16'hFFFF;
         #1;
         $display("Running test suite setup code");
      end

      // проверка индикации передатчика
      `TEST_CASE("test_leds") begin : test_leds
            
         iLedPrd = 16'hAAAA;
         iLedPrm = 16'h5555;
         #1;

         // установка данных прд (начальное состояние)
         `CHECK_EQUAL(oLePrd, 1'b0);
         `CHECK_EQUAL(oLePrm, 1'b0);
         `CHECK_EQUAL(oLed, iLedPrd);
         
         // запись прд
         tick();
         `CHECK_EQUAL(oLePrd, 1'b1);
         `CHECK_EQUAL(oLePrm, 1'b0);
         `CHECK_EQUAL(oLed, iLedPrd);

         // установка данных прм
         tick();
         `CHECK_EQUAL(oLePrd, 1'b0);
         `CHECK_EQUAL(oLePrm, 1'b0);
         `CHECK_EQUAL(oLed, iLedPrm);

         // запись прм
         tick();
         `CHECK_EQUAL(oLePrd, 1'b0);
         `CHECK_EQUAL(oLePrm, 1'b1);
         `CHECK_EQUAL(oLed, iLedPrm);

         // установка данных прд
         tick();
         `CHECK_EQUAL(oLePrd, 1'b0);
         `CHECK_EQUAL(oLePrm, 1'b0);
         `CHECK_EQUAL(oLed, iLedPrd);

         // запись прд
         tick();
         `CHECK_EQUAL(oLePrd, 1'b1);
         `CHECK_EQUAL(oLePrm, 1'b0);
         `CHECK_EQUAL(oLed, iLedPrd);

         // установка данных прм
         tick();
         `CHECK_EQUAL(oLePrd, 1'b0);
         `CHECK_EQUAL(oLePrm, 1'b0);
         `CHECK_EQUAL(oLed, iLedPrm);

         // проверка установки данных, во время такта
         iLedPrm = 16'h1234;
         #1;
         `CHECK_EQUAL(oLed, iLedPrm);
        
      end

   end;

   task tick;
      begin
         clk = 1'b0; #1;
         clk = 1'b1; #1;
      end
   endtask

   `WATCHDOG(1ms);

   BskLED dut(.*);

endmodule