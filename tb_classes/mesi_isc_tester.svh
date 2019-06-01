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

class tester; 
	virtual mesi_isc_bfm bfm;

	function new (virtual mesi_isc_bfm b);
		bfm = b;
	endfunction : new		 			
	
	//internal variables 
	logic [3:0] mbus_ack_memory;
	logic [31:0] mem[9:0];  //main memory								
	logic [3:0] tb_ins_nop_period;
	cpu_input cpu_ip;
	
	protected function void reset_op();
		cpu_ip.reset = 1;
		cpu_ip.tb_ins_array = `MESI_ISC_TB_INS_NOP;		                                                              
		cpu_ip.tb_ins_addr_array = 0;
		tb_ins_nop_period = 4'b0;								
	endfunction
	
	protected function void gen_stimulus();
		integer  		cur_stimulus_cpu,m,l;
		integer                 stimulus_rand_numb [9:0];
		integer                 seed;
		logic  [1:0]            stimulus_rand_cpu_select;
		reg    [7:0]            tb_ins_nop_period [3:0];
		reg    [1:0]            stimulus_op;
		reg    [7:0]            stimulus_addr;
		reg    [7:0]            stimulus_nop_period;
		
		// Calculate the random numbers for this cycle. Use one $random command
		// to perform one series of random number depends on the seed.
		cpu_ip.reset = 0;
		for (m = 0; m < 9; m = m + 1)
			stimulus_rand_numb[m] = $random(seed);

			// For the current cycle check all the CPU starting in a random CPU ID 
			stimulus_rand_cpu_select = $unsigned(stimulus_rand_numb[0]) % 4; // The random CPU ID
		for (l = 0; l < 4; l = l + 1)
			begin
				  // Start generate a request of CPU ID that equal to cur_stimulus_cpu
				  cur_stimulus_cpu = (stimulus_rand_cpu_select+l) % 4; 
				  //cur_stimulus_cpu=0;
				  cpu_ip.cpu_id = cur_stimulus_cpu;			//assign it to the structure defined in package
				  //give it to cpu id 
				  // This CPU is in NOP period
				  // ----------------------------
				  //DOUBT: should we use the structure one?
				 // if(0)
				  if(tb_ins_nop_period[cur_stimulus_cpu] > 0)  		//checking if NOP is required for the current one
					  begin
							cpu_ip.tb_ins_array[cur_stimulus_cpu] = `MESI_ISC_TB_INS_NOP;
							// Decrease the counter by 1. When the counter value is 0 the NOP period is finished
							tb_ins_nop_period[cur_stimulus_cpu] = tb_ins_nop_period[cur_stimulus_cpu] - 1;
					  end
				  // After last action's ACK from cpu, instruction changed back to nop.
				 else if (tb_ins_ack_pkg[cur_stimulus_cpu] == 1 )								       		  //when NOP is not required //checking the master's ack bus//defined in the package  
							cpu_ip.tb_ins_array[cur_stimulus_cpu] = `MESI_ISC_TB_INS_NOP;	   //if there is an acknowledgement means an inst has been completed       
				           
				  // Generate the next instruction for the CPU 
				  else if(tb_ins_array_pkg[cur_stimulus_cpu] == `MESI_ISC_TB_INS_NOP)         		  //if no acknowledgement, inst array is checked
					  begin															          	  
							// Decide the next operation - nop (0), wr (1), or rd (2)
							stimulus_op         = $unsigned(stimulus_rand_numb[1+l]) % 20 ;
							// Ratio: 1 - nop     1 - wr 5 - rd
							if (stimulus_op > 1) stimulus_op = 2;								  
							// Decide the next address for operations 1 to 5
							stimulus_addr       = ($unsigned(stimulus_rand_numb[5+l]) % 5) + 1 ;  //random address
							// Decide the next  operation 1 to 10
							stimulus_nop_period = ($unsigned(stimulus_rand_numb[9]) % 10) + 1 ;   //random nop period
							// Next op is nop. Set the value of the counter
							if (stimulus_op == 0)
								tb_ins_nop_period[cur_stimulus_cpu] = stimulus_nop_period;    //NOP operation period
							else
								begin
									  cpu_ip.tb_ins_array[cur_stimulus_cpu] = stimulus_op; // 1 for wr, 2 for rd
									  cpu_ip.tb_ins_addr_array[cur_stimulus_cpu] = stimulus_addr;          
								end
					  end 
			end 
	
	endfunction
	
	/*protected function void gen_stimulus_matrix();
		reg	mem_access;
		reg [1:0]  cpu_priority;
		logic i;
	
	    if (bfm.rst)
			begin
				cpu_priority    = 0;
			end
	    else
		  begin
				mbus_ack_memory = 0;
				mem_access      = 0;
				assign_mbus_ack();
				for (i=0; i < 4; i=i+1 )
				   if ((bfm.mbus_cmd_array[cpu_priority+i] == `MESI_ISC_MBUS_CMD_WR |
						bfm.mbus_cmd_array[cpu_priority+i] == `MESI_ISC_MBUS_CMD_RD  ) &
						!mem_access)
						begin
							 mem_access = 1;
							 mbus_ack_memory[cpu_priority+i] = 1;
								assign_mbus_ack();
							 if (bfm.mbus_cmd_array[cpu_priority+i] == `MESI_ISC_MBUS_CMD_WR)
								  // WRITE
								  begin
										mem[bfm.mbus_addr_array[cpu_priority+i]] =
															   bfm.mbus_data_wr_array[cpu_priority+i];			
								  end
								// READ
							 else
									cpu_ip.mbus_data_rd =  mem[bfm.mbus_addr_array[cpu_priority+i]];		   
						end
			end
	endfunction
	*/	
	task execute();
		//reset command 
		reset_op();			//generates stimulus for reset 

		bfm.send_ip_cpu(cpu_ip);		//send it to bfm
		repeat (10) begin : random_loop
			//assign cpu_ip by calling the tasks 
			gen_stimulus;			   	//generates stimulus and ssigns it to the structure 
			//gen_stimulus_matrix;		//generates stimului for matrix and memory 
 
			$display("cpu_id = %d, reset = %b, mbus_data_rd = %d, mbus_ack=%d, tb_ins_array=%d, tb_ins_addr_array=%d\n",
				cpu_ip.cpu_id, cpu_ip.reset, cpu_ip.mbus_data_rd, cpu_ip.mbus_ack,cpu_ip.tb_ins_array,cpu_ip.tb_ins_addr_array);
			bfm.send_ip_cpu(cpu_ip);	//send it to bfm
		end : random_loop
		#50;
		$stop;
	endtask : execute
	/*
	task assign_mbus_ack();
		cpu_ip.mbus_ack = mbus_ack_memory[3:0] | bfm.mbus_ack_mesi_isc[3:0];
	endtask: assign_mbus_ack
	*/
	
endclass: tester 