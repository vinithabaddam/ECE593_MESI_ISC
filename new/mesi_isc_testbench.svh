/********************************************************************************
*
* Authors: Vinitha Baddam, Monika Sinduja Mullapudi, Zerin Fatima
* Date: 5/31/2019
*
* Description: testbanch class is used to instantiate  tester, coverage and scoreboard
*
********************************************************************************/

`include "mesi_isc_tester.svh"
`include "mesi_isc_coverage.svh"
`include "mesi_isc_scoreboard.svh"

class testbench;

   virtual mesi_isc_bfm bfm;

   tester tester_h;
   coverage coverage_h;
   scoreboard scoreboard_h;
   
   function new (virtual mesi_isc_bfm b);
       bfm = b;
   endfunction : new

   task execute();
      tester_h = new(bfm);
      coverage_h = new(bfm);
      scoreboard_h = new(bfm);

      fork
         tester_h.execute();
         coverage_h.execute();
         scoreboard_h.execute();
      join_none

   endtask : execute
endclass : testbench

     
   