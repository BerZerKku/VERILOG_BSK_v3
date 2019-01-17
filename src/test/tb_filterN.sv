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

module tb_FilterN;

   // Количество используемых сигналов.
   localparam NUM_SIGNALS = 16;
   // Количество бит в регистрых фильрации. 
   localparam FILTER_WIDTH = 4;
   // Количество шагов фильрации (2^n - 1).
   localparam NUM_STEP_FILTER = FILTER_WIDTH ** 2 - 1;   
   // Значение выхода по умолчанию.
   localparam OUT_DEFAULT = {NUM_SIGNALS{1'b1}}; 
   
   reg  [NUM_SIGNALS-1:0] in;   // вход
   wire [NUM_SIGNALS-1:0] out;  // выход
   
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
         for(int i = 1; i < NUM_STEP_FILTER; i = i + 1) begin
            tick(); 
            `CHECK_EQUAL(out, OUT_DEFAULT);    
         end
         tick();
         `CHECK_EQUAL(out, in); 

         // reset out
         aclr = 1'b1; #1;
         `CHECK_EQUAL(out, OUT_DEFAULT); 
         aclr = 1'b0; #1;
         `CHECK_EQUAL(out, OUT_DEFAULT); 

         // проверка по всех команд по одной
         for(int i = 0; i < NUM_SIGNALS; i = i + 1 ) begin
            in = OUT_DEFAULT ^ (1'b1 << i); #1;
            $display("in = %h", in);
            for(int i = 1; i < NUM_STEP_FILTER; i = i + 1) begin
               tick();  
               `CHECK_EQUAL(out, OUT_DEFAULT);  
            end
            tick();
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

         // Тест рассчитан на 16 сигналов
         if (NUM_SIGNALS != 16) begin
            `CHECK_EQUAL(1, 0);
         end

         for(int step_err = 1; step_err < NUM_STEP_FILTER; step_err = step_err + 1) begin
            $display("Step error = %d", step_err);
            // формирование ошибки на шаге step_err
            $display("Create error");

            for(int step = 0; step < NUM_STEP_FILTER; step = step + 1) begin
               in = (step == step_err) ? com_err : com_in; #1;
               tick();
               $display("step = %d, in = %h, out = %h", step, in, out);
               if (step == NUM_STEP_FILTER - 1) begin
                  `CHECK_EQUAL(out, com_out); 
               end
               else begin
                  `CHECK_EQUAL(out, OUT_DEFAULT);
               end
            end
            
            // добавочные шаги для формирования команды с учетом ошибки на шаге step_err
            $display("Create out");
            for(int step = 0; step < step_err; step = step + 1) begin 
               in = com_in; #1;
               tick();
               $display("step = %d, in = %h, out = %h", step, in, out);
               `CHECK_EQUAL(out, com_out);
            end

            tick();
            // $display("out = %h", out);
            $display("out = %h", out);
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

   FilterN # (.NUM_SIGNALS(NUM_SIGNALS), .FILTER_WIDTH(FILTER_WIDTH)) dut(.*);

endmodule