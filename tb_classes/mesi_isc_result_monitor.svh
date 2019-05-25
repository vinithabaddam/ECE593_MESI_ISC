/********************************************************************************
*
* Authors: Srijana Sapkota and Zeba Khan Rafi
* Reference: https://github.com/PrakashLuu/mesi_verification
* Reference: https://github.com/shruti2611/EE382M_project/blob/master/mesi_fifo/mesi_isc_define.v
* Reference: https://github.com/rdsalemi/uvmprimer/tree/master/16_Analysis_Ports_In_the_Testbench
* Reference: https://opencores.org/projects/mesi_isc
* Last Modified: March 10, 2019
*
* Description:	Result monitor class collects output information.
*				Shared to the subscriber - scoreboard viad the host : result monitor
*				
********************************Change Log******************************************************* 
* Srijana S. and Zeba K. R.			3/10/2019			Created
********************************************************************************/

import mesi_isc_pkg::*;import uvm_pkg::*;
`include "uvm_macros.svh" 

class result_monitor extends uvm_component;
  `uvm_component_utils(result_monitor);
  
  uvm_analysis_port #(tired) result_ap;
  
  function void build_phase(uvm_phase phase);
    virtual mesi_isc_bfm bfm;
    if(!uvm_config_db #(virtual mesi_isc_bfm)::get(null, "*", "bfm", bfm))
      $fatal("Failed to get BFM");
    bfm.result_monitor_h = this;
    result_ap = new("result_ap",this);
  endfunction: build_phase
  
  function void write_to_monitor(tired outport);
      $display("cbus_addr_o = %h\n",outport.cbus_addr_o);
	  $display("cbus_cmd3_o = %d, cbus_cmd2_o=%d, cbus_cmd1_o=%d, cbus_cmd0_o=%d\n",
				outport.cbus_cmd3_o, outport.cbus_cmd2_o,outport.cbus_cmd1_o,outport.cbus_cmd0_o);
	  $display("mbus_ack3_o = %d, mbus_ack2_o=%d,mbus_ack1_o=%d,mbus_ack0_o=%d\n",
				outport.mbus_ack3_o,outport.mbus_ack2_o,outport.mbus_ack1_o,outport.mbus_ack0_o);			
      result_ap.write(outport);
  endfunction : write_to_monitor
  
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction: new
  
endclass: result_monitor
