/********************************************************************************
*
* Authors: Vinitha Baddam, Monika Sinduja Mullapudi, Zerin Fatima
* Date: 5/31/2019
*
* Description:	This class checks stimulus coverage. 
*		Command monitor provides inport port through bfm.
*
********************************************************************************/

import mesi_isc_pkg::*;	
`include "mesi_isc_pkg.sv"

class coverage;
	virtual mesi_isc_bfm bfm;
  
	// input ports struct
	input_port inputs_cv;
  
	covergroup cover_inputs;
		cmd3: coverpoint inputs_cv.mbus_cmd3_i{
			bins cmds[] = {`MESI_ISC_MBUS_CMD_NOP,		// cover all main bus
						 `MESI_ISC_MBUS_CMD_WR,			// commands for 
						 `MESI_ISC_MBUS_CMD_RD,			// master 3: nop, wr, rd
						 `MESI_ISC_MBUS_CMD_WR_BROAD,	// rd broadcast and wr
						 `MESI_ISC_MBUS_CMD_RD_BROAD};	// broadcast
			ignore_bins  others = {[5:$]}; 
		}

		cmd2: coverpoint inputs_cv.mbus_cmd2_i{
			bins cmds[] = {`MESI_ISC_MBUS_CMD_NOP,		// cover all main bus
						 `MESI_ISC_MBUS_CMD_WR,			// commands for 
						 `MESI_ISC_MBUS_CMD_RD,			// master 2: nop, wr, rd
						 `MESI_ISC_MBUS_CMD_WR_BROAD,	// rd broadcast and wr
						 `MESI_ISC_MBUS_CMD_RD_BROAD};	// broadcast
			ignore_bins others = {[5:$]}; 
		}

		cmd1: coverpoint inputs_cv.mbus_cmd1_i{
			bins cmds[] = {`MESI_ISC_MBUS_CMD_NOP,		// cover all main bus
						 `MESI_ISC_MBUS_CMD_WR,			// commands for 
						 `MESI_ISC_MBUS_CMD_RD,			// master 1: nop, wr, rd
						 `MESI_ISC_MBUS_CMD_WR_BROAD,	// rd broadcast and wr
						 `MESI_ISC_MBUS_CMD_RD_BROAD};	// broadcast
			ignore_bins others = {[5:$]}; 
		}

		cmd0: coverpoint inputs_cv.mbus_cmd0_i{			// cover all main bus
			bins cmds[] = {`MESI_ISC_MBUS_CMD_NOP,		// commands for 
						 `MESI_ISC_MBUS_CMD_WR,			// master 0: nop, wr, rd
						 `MESI_ISC_MBUS_CMD_RD,			// rd broadcast and wr
						 `MESI_ISC_MBUS_CMD_WR_BROAD,	// broadcast
						 `MESI_ISC_MBUS_CMD_RD_BROAD};
			ignore_bins others = {[5:$]}; 
		}

		addr3: coverpoint inputs_cv.mbus_addr3_i{		// cover all possible
			bins zeros 	= 	{'0};						// address values for
			bins others 	= 	{[32'd1:32'hFFFF_FFFE]};	// master 3: all zeroes,
			bins ones 	= 	{32'hFFFF_FFFF};			// all ones and all in between
		}

		addr2: coverpoint inputs_cv.mbus_addr2_i{		// cover all possible
			bins zeros 	= 	{'0};						// address values for
			bins others 	= 	{[32'd1:32'hFFFF_FFFE]};	// master 2: all zeroes,
			bins ones 	= 	{32'hFFFF_FFFF};			// all ones and all in between
		}

		addr1: coverpoint inputs_cv.mbus_addr1_i{		// cover all possible
			bins zeros 	= 	{'0};						// address values for
			bins others 	= 	{[32'd1:32'hFFFF_FFFE]};	// master 1: all zeroes,
			bins ones 	= 	{32'hFFFF_FFFF};			// all ones and all in between
		}

		addr0: coverpoint inputs_cv.mbus_addr0_i{		// cover all possible
			bins zeros 	= 	{'0};						// address values for
			bins others 	= 	{[32'd1:32'hFFFF_FFFE]};	// master 0: all zeroes,
			bins ones 	= 	{32'hFFFF_FFFF};			// all ones and all in between
		}

		ack3: coverpoint inputs_cv.cbus_ack3_i{			// cover all possible
			bins low		=	{0};						// values for cbus ack:
			bins high		=	{1};						// high and low for master 3
		}

		ack2: coverpoint inputs_cv.cbus_ack2_i{			// cover all possible
			bins low		=	{0};						// values for cbus ack:
			bins high		=	{1};						// high and low for master 2
		}

		ack1: coverpoint inputs_cv.cbus_ack1_i{			// cover all possible
			bins low		=	{0};						// values for cbus ack:
			bins high		=	{1};						// high and low for master 1
		}

		ack0: coverpoint inputs_cv.cbus_ack0_i{			// cover all possible
			bins low		=	{0};						// values for cbus ack:
			bins high		=	{1};						// high and low for master 0
		}

		cross_m3	:	cross cmd3, addr3;				// crossing commands and address 
		cross_m2	: 	cross cmd2, addr2;				// for Master 3, 2, 1 and 0
		cross_m1	:	cross cmd1, addr1;
		cross_m0	:	cross cmd0, addr0;
	endgroup
  
	// Sampling 
	function new (virtual mesi_isc_bfm b);
		bfm = b;
		cover_inputs = new();
	endfunction	
	
	// copy all inputs from the struct and 
	// sample the coverage
	task execute();
		input_port t;
		t = bfm.inport; 
		inputs_cv.mbus_cmd3_i 	= 	t.mbus_cmd3_i;
		inputs_cv.mbus_cmd2_i 	= 	t.mbus_cmd2_i;
		inputs_cv.mbus_cmd1_i 	= 	t.mbus_cmd1_i;
		inputs_cv.mbus_cmd0_i 	= 	t.mbus_cmd0_i;
		inputs_cv.mbus_addr3_i 	= 	t.mbus_addr3_i;
		inputs_cv.mbus_addr2_i 	= 	t.mbus_addr2_i;
		inputs_cv.mbus_addr1_i 	= 	t.mbus_addr1_i;
		inputs_cv.mbus_addr0_i 	= 	t.mbus_addr0_i;
		inputs_cv.cbus_ack3_i	=	t.cbus_ack3_i;
		inputs_cv.cbus_ack2_i	=	t.cbus_ack2_i;
		inputs_cv.cbus_ack1_i	=	t.cbus_ack1_i;
		inputs_cv.cbus_ack0_i	=	t.cbus_ack0_i;
		cover_inputs.sample();
	endtask: execute
  
endclass: coverage
    
