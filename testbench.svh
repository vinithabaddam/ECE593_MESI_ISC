`include "mesi_isc_define.v"
`include "mesi_isc_tb_define.v"
`include "tester_trying.svh"
class testbench;

   virtual mesi_isc_bfm_mod bfm;

  tester    tester_h;
   //coverage  coverage_h;
  // scoreboard scoreboard_h;
 //  command_monitor command_monitor_h;	
//   result_monitor  result_monitor_h;	

   function new (virtual mesi_isc_bfm_mod b);
       bfm = b;
   endfunction : new

   task execute();
      tester_h    = new(bfm);
     // coverage_h   = new(bfm);
    //  scoreboard_h = new(bfm);
     // result_monitor_h = new(bfm);
     // command_monitor_h = new(bfm);

      fork
         tester_h.execute();
      //   coverage_h.execute();
       //  scoreboard_h.execute();
	//result_monitor_h.execute();
	//command_monitor_h.execute();

      join_none
   endtask : execute
endclass : testbench
