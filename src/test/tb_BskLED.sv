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
         #1;
         $display("Running test suite setup code");
      end

      // проверка индикации передатчика
      `TEST_CASE("test_led_prd") begin : test_led_prd
            
         iLedPrd = 16'hAAAA;
         iLedPrm = 16'h5555;

         // начальное состояние
         `CHECK_EQUAL(oLePrd, 1'b0);
         
         tick();
         `CHECK_EQUAL(oLePrd, 1'b0);
         `CHECK_EQUAL(oLed, iLedPrd);

         for(int i = 1; i < CNT_MAX; i++) begin
            tick();
            `CHECK_EQUAL(oLePrd, 1'b1);
            `CHECK_EQUAL(oLed, iLedPrd);
         end

         for(int i = 0; i < CNT_MAX; i++) begin
            tick();
            `CHECK_EQUAL(oLePrd, 1'b0);
            `CHECK_EQUAL(oLed, iLedPrm);
         end

         tick();
         `CHECK_EQUAL(oLePrd, 1'b0);
         `CHECK_EQUAL(oLed, iLedPrd);

         tick();
         `CHECK_EQUAL(oLePrd, 1'b1);
         `CHECK_EQUAL(oLed, iLedPrd);

         iLedPrd = 16'h1234;
         tick();
         `CHECK_EQUAL(oLed, iLedPrd);


      end

      // проверка индикации приемника
      `TEST_CASE("test_led_prm") begin : test_led_prm
         iLedPrd = 16'hAAAA;
         iLedPrm = 16'h5555;

         // начальное состояние
         `CHECK_EQUAL(oLePrm, 1'b0);

         // индикация команд передатчика
         for(int i = 0; i < CNT_MAX; i++) begin
            tick();
            `CHECK_EQUAL(oLePrm, 1'b0);
            `CHECK_EQUAL(oLed, iLedPrd);

         end

         tick();
         `CHECK_EQUAL(oLePrm, 1'b0);
         `CHECK_EQUAL(oLed, iLedPrm);

         // индикация команд приемника
         for(int i = 1; i < CNT_MAX; i++) begin
            $display("%d", i);
            tick();
            `CHECK_EQUAL(oLePrm, 1'b1);
            `CHECK_EQUAL(oLed, iLedPrm);
         end

         // индикация команд передатчика
         for(int i = 0; i < CNT_MAX; i++) begin
            tick();
            `CHECK_EQUAL(oLePrm, 1'b0);
            `CHECK_EQUAL(oLed, iLedPrd);
         end

         tick();
         `CHECK_EQUAL(oLePrm, 1'b0);
         `CHECK_EQUAL(oLed, iLedPrm);

         tick();
         `CHECK_EQUAL(oLePrm, 1'b1);
         `CHECK_EQUAL(oLed, iLedPrm);

         iLedPrm = 16'h1234;
         tick();
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