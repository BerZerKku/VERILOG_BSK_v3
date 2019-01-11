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

module tb_Filter;

   // количество циклов фильтрации
   localparam NUM_COM_FILTER = 5;
   // выход по умолчанию
   localparam OUT_DEFAULT = 16'hFFFF;

   reg  [15:0] in;   // вход
   wire [15:0] out;  // выход
   
   reg clk;          // тактовая частота
   reg aclr;         // сброс (активный 1)

   `TEST_SUITE begin
      
      `TEST_SUITE_SETUP begin
         in = OUT_DEFAULT;
         clk = 1'b0;
         aclr = 1'b0;
         #1;
         $display("Running test suite setup code");  
      end

      // проверка фильтрации команд
      `TEST_CASE("test_filter") begin : test_filter
         `CHECK_EQUAL(out, OUT_DEFAULT); 

         // check all command simultaneously
         in = 16'h0000; #1;
         for(int i = 0; i < NUM_COM_FILTER ; i = i + 1) begin
            `CHECK_EQUAL(out, OUT_DEFAULT); 
            tick();            
         end
         `CHECK_EQUAL(out, in); 

         // reset out
         aclr = 1'b1; #1;
         `CHECK_EQUAL(out, OUT_DEFAULT); 
         aclr = 1'b0; #1;
         `CHECK_EQUAL(out, OUT_DEFAULT); 

         // проверка по всех команд по одной
         for(int i = 0; i < 16; i = i + 1 ) begin
            in = OUT_DEFAULT ^ (1'b1 << i); #1;
            for(int i = 0; i < NUM_COM_FILTER ; i = i + 1) begin
               `CHECK_EQUAL(out, OUT_DEFAULT); 
               tick();            
            end
            `CHECK_EQUAL(out, in); 

            // reset out
            aclr = 1'b1; #1;
            `CHECK_EQUAL(out, OUT_DEFAULT); 
            aclr = 1'b0; #1;
            `CHECK_EQUAL(out, OUT_DEFAULT); 
         end

      end

      // проверка фильтрации команд при наличии ошибки
      `TEST_CASE("test_filter_com_error") begin : test_filter_com_error
         automatic int com_in  = 16'h1234; // b 0001 0010 0011 0100
         automatic int com_err = 16'h466D; // b 0100 0110 0110 1101   
         automatic int com_out = 16'h567D; // b 0101 0110 0111 1101
         
         for(int step_err = 1; step_err < NUM_COM_FILTER; step_err = step_err + 1) begin
            // формирование ошибки на шаге step_err
            for(int step = 0; step < NUM_COM_FILTER; step = step + 1) begin
               in = (step == step_err) ? com_err : com_in; #1;
               `CHECK_EQUAL(out, OUT_DEFAULT); 
               tick();
            end
            
            // добавочные шаги для формирования команды с учетом ошибки на шаге step_err
            for(int step = 0; step <= step_err; step = step + 1) begin 
               in = com_in; #1;
               // $display("step = %d, out = %h", step, out);
               `CHECK_EQUAL(out, com_out);
               tick();
            end
            // $display("out = %h", out);
            `CHECK_EQUAL(out, com_in);

            // reset out
            aclr = 1'b1; #1;
            `CHECK_EQUAL(out, OUT_DEFAULT); 
            aclr = 1'b0; #1;
            `CHECK_EQUAL(out, OUT_DEFAULT);  
         end

      end


   end;

   task tick;
      begin
         clk = 1'b0; #1;
         clk = 1'b1; #1;
      end
   endtask

   `WATCHDOG(1ms);

   Filter dut(.*);

endmodule