/********************************************************************************
*
* Authors: Vinitha Baddam, Monika Sinduja Mullapudi, Zerin Fatima
* Date: 5/31/2019
*
* Description:	Command Monitor class. BFM writes input ports info to command monitor
*
********************************************************************************/


import mesi_isc_pkg::*;	

class command_monitor;


	function void write_to_monitor(input_port inport);
		$display("COMMAND MONITOR: Cmd_M3:%d	Cmd_M2:%d	Cmd_M1:%d	Cmd_M0:%d" ,
				 inport.mbus_cmd3_i, inport.mbus_cmd2_i, inport.mbus_cmd1_i, inport.mbus_cmd0_i);
		$display("COMMAND MONITOR: Addr_M3:%0h	Addr_M2:%0h	Addr_M1:%0h	Addr_M0:%0h" ,
				 inport.mbus_addr3_i, inport.mbus_addr2_i, inport.mbus_addr1_i, inport.mbus_addr0_i);
		$display("COMMAND MONITOR: CBUS_ack_M3:%d	CBUS_ack_M2:%d	CBUS_ack_M1:%d	CBUS_ack_M0:%d" ,
				 inport.cbus_ack3_i, inport.cbus_ack2_i, inport.cbus_ack1_i, inport.cbus_ack0_i);
	endfunction: write_to_monitor
  
endclass: command_monitor
  
            
    