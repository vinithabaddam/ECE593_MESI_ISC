/********************************************************************************
*
* Authors: Vinitha Baddam, Monika Sinduja Mullapudi, Zerin Fatima
* Date: 5/31/2019
*
* Description: This is the top module for driving besign by passing BFM inputs and to instantiate other modules
*
********************************************************************************/


`include "testbench.svh"

module top;

	import mesi_isc_pkg::*;
	   
	
	//command_monitor cmd_monitor;
   	//cpu instantiations
	mesi_isc_tb_cpu mesi_isc_tb_cpu3 
		(
		 .clk(bfm.clk),.rst(bfm.rst), 
		 .cbus_addr_i(bfm.cbus_addr_cpu),.cbus_cmd_i(bfm.cbus_cmd3_cpu),
		 .mbus_data_i(bfm.mbus_data_rd),.mbus_ack_i(bfm.mbus_ack[3]),.cpu_id_i(2'd3),.tb_ins_i(bfm.tb_ins_array[3]),
		 .tb_ins_addr_i(bfm.tb_ins_addr_array[3]),
		 .mbus_cmd_o(bfm.mbus_cmd_array[3]),.mbus_addr_o(bfm.mbus_addr_array[3]),.cbus_ack_o(bfm.cbus_ack3),
		 .mbus_data_o(bfm.mbus_data_wr_array[3]),.tb_ins_ack_o(bfm.tb_ins_ack[3])
		); 
	mesi_isc_tb_cpu mesi_isc_tb_cpu2
		(
		 .clk(bfm.clk),.rst(bfm.rst), 
		 .cbus_addr_i(bfm.cbus_addr_cpu),.cbus_cmd_i(bfm.cbus_cmd2_cpu),
		 .mbus_data_i(bfm.mbus_data_rd),.mbus_ack_i(bfm.mbus_ack[2]),.cpu_id_i(2'd2),.tb_ins_i(bfm.tb_ins_array[2]),
		 .tb_ins_addr_i(bfm.tb_ins_addr_array[2]),
		 .mbus_cmd_o(bfm.mbus_cmd_array[2]),.mbus_addr_o(bfm.mbus_addr_array[2]),.cbus_ack_o(bfm.cbus_ack2),
		 .mbus_data_o(bfm.mbus_data_wr_array[2]),.tb_ins_ack_o(bfm.tb_ins_ack[2])
		);
	mesi_isc_tb_cpu mesi_isc_tb_cpu1
		(
		 //common inputs 
		 .clk(bfm.clk),.rst(bfm.rst), 
		 //Inputs from the design o/p 
		 .cbus_addr_i(bfm.cbus_addr_cpu),.cbus_cmd_i(bfm.cbus_cmd1_cpu),
		 //inputs by the driver 
		 .mbus_data_i(bfm.mbus_data_rd),.mbus_ack_i(bfm.mbus_ack[1]),.cpu_id_i(2'd1),.tb_ins_i(bfm.tb_ins_array[1]),
		 .tb_ins_addr_i(bfm.tb_ins_addr_array[1]),
		 //Outputs 
		 //inputs to design from cpu 
		 .mbus_cmd_o(bfm.mbus_cmd_array[1]),.mbus_addr_o(bfm.mbus_addr_array[1]),.cbus_ack_o(bfm.cbus_ack1),
		 // from the cpu 
		 .mbus_data_o(bfm.mbus_data_wr_array[1]),.tb_ins_ack_o(bfm.tb_ins_ack[1])
		);
	mesi_isc_tb_cpu mesi_isc_tb_cpu0
		(
		 .clk(bfm.clk),.rst(bfm.rst), 
		 .cbus_addr_i(bfm.cbus_addr_cpu),.cbus_cmd_i(bfm.cbus_cmd0_cpu),
		 .mbus_data_i(bfm.mbus_data_rd),.mbus_ack_i(bfm.mbus_ack[0]),.cpu_id_i(2'd0),.tb_ins_i(bfm.tb_ins_array[0]),
		 .tb_ins_addr_i(bfm.tb_ins_addr_array[0]),
		 .mbus_cmd_o(bfm.mbus_cmd_array[0]),.mbus_addr_o(bfm.mbus_addr_array[0]),.cbus_ack_o(bfm.cbus_ack0),
		 .mbus_data_o(bfm.mbus_data_wr_array[0]),.tb_ins_ack_o(bfm.tb_ins_ack[0])
		);
   
  /* mesi_isc_bfm DUT (// Inputs
				 .clk(clk), .rst(rst), .mbus_cmd3_i(bfm.mbus_cmd_array[3]),.mbus_cmd2_i(bfm.mbus_cmd_array[2]),
				 .mbus_cmd1_i(bfm.mbus_cmd_array[1]),.mbus_cmd0_i(bfm.mbus_cmd_array[0]),.mbus_addr3_i(bfm.mbus_addr_array[3]),
				 .mbus_addr2_i(bfm.mbus_addr_array[2]),.mbus_addr1_i(bfm.mbus_addr_array[1]),.mbus_addr0_i(bfm.mbus_addr_array[0]),
				 .cbus_ack3_i(cbus_ack3),.cbus_ack2_i(cbus_ack2),.cbus_ack1_i(cbus_ack1),.cbus_ack0_i(cbus_ack0),
				 // Outputs
				 .cbus_addr_o(cbus_addr),.cbus_cmd3_o(cbus_cmd3),.cbus_cmd2_o(cbus_cmd2),.cbus_cmd1_o(cbus_cmd1),
				 .cbus_cmd0_o(cbus_cmd0),.mbus_ack3_o(bfm.mbus_ack_mesi_isc[3]),.mbus_ack2_o(bfm.mbus_ack_mesi_isc[2]),
				 .mbus_ack1_o(bfm.mbus_ack_mesi_isc[1]),.mbus_ack0_o(bfm.mbus_ack_mesi_isc[0])
                ); */
	mesi_isc_bfm  bfm();
	testbench    testbench_h;
	
	initial begin
		testbench_h = new(bfm);
		testbench_h.execute();
	end

endmodule : top