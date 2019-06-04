/********************************************************************************
*
* Authors: Vinitha Baddam, Monika Sinduja Mullapudi, Zerin Fatima
* Date: 5/31/2019
*
* Description:	This tester class provides commands to the design through bfm
*
*********************************************************************************/

import mesi_isc_pkg::*;
`include "mesi_isc_pkg.sv"

//================================
// The stimulus drives instruction to the CPU. There are three possible 
// instructions:
// 1. NOP - Do nothing for a random cycles.   
// 2. RD - Read a memory address line with a random address. If the line address
//    is valid on the cache read it from there, if not bring the line according
//    to the the MESI protocol.
// 3. WR - Write a memory address line with a random address. If the line address
//    is valid on the cache write to it according to the MESI protocol. If it is
//    not valid, bring it from the memory according to the the MESI protocol.
//================================

class tester; 
	virtual mesi_isc_bfm bfm;

	function new (virtual mesi_isc_bfm b);
		bfm = b;
	endfunction : new		 		
	
	integer                 stimulus_rand_numb [9:0];
	integer                 seed = 10;
	reg    [1:0]            stimulus_rand_cpu_select;
	reg    [1:0]            stimulus_op;
	reg    [7:0]            stimulus_addr;
	reg    [7:0]            stimulus_nop_period;
	integer                 cur_stimulus_cpu;
	reg    [3:0]            tb_ins_addr_array [3:0];
	reg    [3:0]            tb_ins_array [3:0];
	reg    [7:0]            tb_ins_nop_period [3:0];
	integer                 i, j, k, l, m, n, p;
	
	//for tester reset
	protected function void reset_tester();
		//$display("reset_tester");
		tb_ins_array[3]      = `MESI_ISC_TB_INS_NOP;
		tb_ins_array[2]      = `MESI_ISC_TB_INS_NOP;
		tb_ins_array[1]      = `MESI_ISC_TB_INS_NOP;
		tb_ins_array[0]      = `MESI_ISC_TB_INS_NOP;
		tb_ins_addr_array[3] = 0;
		tb_ins_addr_array[2] = 0;
		tb_ins_addr_array[1] = 0;
		tb_ins_addr_array[0] = 0;
		tb_ins_nop_period[3] = 0;
		tb_ins_nop_period[2] = 0;
		tb_ins_nop_period[1] = 0;
		tb_ins_nop_period[0] = 0;								
	endfunction
	
	//for generating stimulus
	protected function void gen_stimulus();
		//$display("get_stimulus");
		// Calculate the random numbers for this cycle. Use one $random command
		// to perform one series of random number depends on the seed.
		for (m = 0; m < 9; m = m + 1)
			stimulus_rand_numb[m] = $urandom;

		// For the current cycle check all the CPU starting in a random CPU ID 
		stimulus_rand_cpu_select = $unsigned(stimulus_rand_numb[0]) % 4; // The
										  // random CPU ID
		for (l = 0; l < 4; l = l + 1)
		begin
			// Start generate a request of CPU ID that equal to cur_stimulus_cpu
			cur_stimulus_cpu = (stimulus_rand_cpu_select+l) % 4;
			// This CPU is in NOP period
			// ----------------------------
			if(bfm.tb_ins_nop_period[cur_stimulus_cpu] > 0) 
			begin
				bfm.tb_ins_array[cur_stimulus_cpu] = `MESI_ISC_TB_INS_NOP;
				// Decrease the counter by 1. When the counter value is 0 the NOP period is finished
				bfm.tb_ins_nop_period[cur_stimulus_cpu] = bfm.tb_ins_nop_period[cur_stimulus_cpu] - 1;
			end
		  // The CPU is return acknowledge for the last action. Change the 
		  // instruction back to nop.
		  // ----------------------------
			else if (bfm.tb_ins_ack[cur_stimulus_cpu])
				bfm.tb_ins_array[cur_stimulus_cpu] = `MESI_ISC_TB_INS_NOP;        
			// Generate the next instruction for the CPU 
			else if(bfm.tb_ins_array[cur_stimulus_cpu] == `MESI_ISC_TB_INS_NOP)
			begin
				// Decide the next operation - nop (0), wr (1), or rd (2)
				stimulus_op         = $unsigned(stimulus_rand_numb[1+l]) % 20 ;
				// Ratio: 1 - nop     1 - wr 5 - rd
				if (stimulus_op > 1) 
					stimulus_op = 2;
				// Decide the next address operation 1 to 5
				stimulus_addr       = ($unsigned(stimulus_rand_numb[5+l]) % 5) + 1 ;  
				// Decide the next  operation 1 to 10
				stimulus_nop_period = ($unsigned(stimulus_rand_numb[9]) % 10) + 1 ;  
				// Next op is nop. Set the value of the counter
				if (stimulus_op == 0)
					bfm.tb_ins_nop_period[cur_stimulus_cpu] = stimulus_nop_period;
				else
				begin
					bfm.tb_ins_array[cur_stimulus_cpu] = stimulus_op; // 1 for wr, 2 for rd
					bfm.tb_ins_addr_array[cur_stimulus_cpu] = stimulus_addr;          
				end
			end // if (tb_ins_array[cur_stimulus_cpu] == `MESI_ISC_TB_INS_NOP)
		end // for (l = 0; l < 4; l = l + 1)	 
	endfunction
		
	// tester execute task called from testbench
	task execute();
		//reset command 
		//$display("tester");
		reset_tester(); //generates stimulus for reset 
		repeat (10)
		bfm.reset_bfm(); //reset bfm
		repeat (10000) begin : random_loop
			gen_stimulus();	//generates stimulus and ssigns it to the structure 
			bfm.send_ip_cpu(tb_ins_array, tb_ins_addr_array, tb_ins_nop_period); //send it to bfm
		end : random_loop
		#50;
		bfm.dispaly_stats(); //display statistics
		#10;
		$stop;
	endtask : execute
	
endclass: tester 