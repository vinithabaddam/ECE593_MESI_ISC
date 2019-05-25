/********************************************************************************
*
* Authors: Srijana Sapkota and Zeba Khan Rafi
* Reference: https://github.com/PrakashLuu/mesi_verification
* Reference: https://github.com/shruti2611/EE382M_project/blob/master/mesi_fifo/mesi_isc_define.v
* Reference: https://github.com/rdsalemi/uvmprimer/tree/master/16_Analysis_Ports_In_the_Testbench
* Reference: https://opencores.org/projects/mesi_isc
* Last Modified: March 12, 2019
*
* Description:	Environment class to integrate all components
*				
********************************Change Log******************************************************* 
* Srijana S. and Zeba K. R.			3/12/2019			Created
********************************************************************************/

import mesi_isc_pkg::*;
import uvm_pkg::*;
`include "uvm_macros.svh"
`include "mesi_isc_tester.svh"
`include "mesi_isc_driver.svh"
`include "mesi_isc_coverage.svh"
`include "mesi_isc_scoreboard.svh"
`include "mesi_isc_result_monitor.svh"



class env extends uvm_env;
	`uvm_component_utils(env);
	
	tester tester_h;
	driver driver_h;
	
	coverage   coverage_h;
	scoreboard scoreboard_h;
	
	command_monitor command_monitor_h;
	result_monitor  result_monitor_h;
	
	uvm_tlm_fifo#(cpu_ip_s) cpu_ip_port;
	
	function void build_phase(uvm_phase phase);
	
		cpu_ip_port = new("cpu_ip_port", this);
		
		tester_h = tester::type_id::create("tester_h",this);
		driver_h = driver::type_id::create("driver_h",this);
		
		coverage_h      =  coverage::type_id::create ("coverage_h",this);
		scoreboard_h    =  scoreboard::type_id::create("scoreboard_h",this);
		
		command_monitor_h = command_monitor::type_id::create("command_monitor_h",this);
		result_monitor_h  = result_monitor::type_id::create("result_monitor_h",this);   
	
	endfunction : build_phase
	
	function void connect_phase(uvm_phase phase);
	
		driver_h.cpu_ip_port.connect(cpu_ip_port.get_export);
		tester_h.cpu_ip_port.connect(cpu_ip_port.put_export);
		
		result_monitor_h.result_ap.connect(scoreboard_h.analysis_export);
      
        command_monitor_h.command_ap.connect(scoreboard_h.command_fifo.analysis_export);
	    command_monitor_h.command_ap.connect(coverage_h.analysis_export);
		  
    endfunction : connect_phase
   
	function new (string name, uvm_component parent);
		super.new(name,parent);
	endfunction
	
endclass 