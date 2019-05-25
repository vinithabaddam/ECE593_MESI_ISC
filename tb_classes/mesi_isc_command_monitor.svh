/********************************************************************************
*
* Authors: Srijana Sapkota and Zeba Khan Rafi
* Reference: https://github.com/PrakashLuu/mesi_verification
* Reference: https://github.com/shruti2611/EE382M_project/blob/master/mesi_fifo/mesi_isc_define.v
* Reference: https://github.com/rdsalemi/uvmprimer/tree/master/16_Analysis_Ports_In_the_Testbench
* Reference: https://opencores.org/projects/mesi_isc
* Last Modified: March 6, 2019
*
* Description:	Command Monitor class.BFM writes input ports info to the analysis port 
*				which is then shared to command monitor's subscribers - coverage and scoreboard
********************************Change Log******************************************************* 
* Srijana S. and Zeba K. R.			3/6/2019			Created
********************************************************************************/


import uvm_pkg::*;
`include "uvm_macros.svh"
import mesi_isc_pkg::*;	

class command_monitor extends uvm_component;

  `uvm_component_utils(command_monitor);
  
  uvm_analysis_port #(input_ports) command_ap;											//declaring the analysis port 
  
  function void build_phase(uvm_phase phase);
		virtual mesi_isc_bfm bfm;
		
		if(!uvm_config_db #(virtual mesi_isc_bfm)::get(null, "*", "bfm", bfm))		//bfm handle
		  $fatal("Failed to get BFM");
		
		bfm.command_monitor_h = this;
		
		command_ap = new("command_ap", this);
  endfunction: build_phase
  
  function void write_to_monitor(input_ports inport);
    $display("COMMAND MONITOR: Cmd_M3:%d	Cmd_M2:%d	Cmd_M1:%d	Cmd_M0:%d" ,
             inport.mbus_cmd3_i, inport.mbus_cmd2_i, inport.mbus_cmd1_i, inport.mbus_cmd0_i);
    $display("COMMAND MONITOR: Addr_M3:%0h	Addr_M2:%0h	Addr_M1:%0h	Addr_M0:%0h" ,
             inport.mbus_addr3_i, inport.mbus_addr2_i, inport.mbus_addr1_i, inport.mbus_addr0_i);
    $display("COMMAND MONITOR: CBUS_ack_M3:%d	CBUS_ack_M2:%d	CBUS_ack_M1:%d	CBUS_ack_M0:%d" ,
             inport.cbus_ack3_i, inport.cbus_ack2_i, inport.cbus_ack1_i, inport.cbus_ack0_i);
    command_ap.write(inport);															//writing the input information in the port 
																				//for the scoreboard and coverage to pull it
  endfunction: write_to_monitor
  
  function new(string name, uvm_component parent);
    super.new(name,parent);
  endfunction
  
endclass: command_monitor
  
            
    
