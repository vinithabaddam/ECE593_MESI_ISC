/********************************************************************************
*
* Authors: Srijana Sapkota and Zeba Khan Rafi
* Reference: https://github.com/PrakashLuu/mesi_verification
* Reference: https://github.com/shruti2611/EE382M_project/blob/master/mesi_fifo/mesi_isc_define.v
* Reference: https://github.com/rdsalemi/uvmprimer/tree/master/16_Analysis_Ports_In_the_Testbench
* Reference: https://opencores.org/projects/mesi_isc
*
* Description:	This tester class provides commands to the master by using FIFO.
********************************Change Log******************************************************* 
* Srijana Sapkota	3/8/2019	Errors faced using uvm_macros. Commented for this version.
* Srijana Sapkota	3/10/2019	Fixed, include macros worked. 
********************************************************************************/
import uvm_pkg::*;
`include "uvm_macros.svh"
import mesi_isc_pkg::*;

`include "mesi_isc_pkg.sv"

class tester extends uvm_component;
	`uvm_component_utils(tester);
	
	virtual mesi_isc_bfm bfm; 
	
	// The following is aport for tester'd FIFO
	
	uvm_put_port #(cpu_ip_s) cpu_ip_port;			 			
	
	//internal variables 
	logic [3:0]   mbus_ack_memory;
	logic [31:0]  mem[9:0];  	//main memory								
	logic [3:0] tb_ins_nop_period;
	cpu_ip_s cpu_ip;

	function new (string name, uvm_component parent);
      super.new(name, parent);
    endfunction
	
    function void build_phase(uvm_phase phase);
		cpu_ip_port = new("cpu_ip_port", this);
	endfunction : build_phase
   
	function reset_op();
		cpu_ip.reset = 1;
		cpu_ip.tb_ins_array      = `MESI_ISC_TB_INS_NOP;		                                                              
		cpu_ip.tb_ins_addr_array = 0;
		tb_ins_nop_period = 4'b0;								
	endfunction
	
	function void gen_stimulus();
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
		for (m = 0; m < 9; m = m + 1)
			stimulus_rand_numb[m] = $random(seed);

			// For the current cycle check all the CPU starting in a random CPU ID 
			stimulus_rand_cpu_select = $unsigned(stimulus_rand_numb[0]) % 4; // The
																			 // random CPU ID
		for (l = 0; l < 4; l = l + 1)
			begin
				  // Start generate a request of CPU ID that equal to cur_stimulus_cpu
				  cur_stimulus_cpu = (stimulus_rand_cpu_select+l) % 4; 
				  //cur_stimulus_cpu=0;
				  cpu_ip.cpu_id = cur_stimulus_cpu;									//assign it to the structure defined in package
				  //give it to cpu id 
				  // This CPU is in NOP period
				  // ----------------------------
				  //DOUBT: should we use the structure one?
				 // if(0)
				  if(tb_ins_nop_period[cur_stimulus_cpu] > 0)  						//checking if NOP is required for the current one
					  begin
							cpu_ip.tb_ins_array[cur_stimulus_cpu] = `MESI_ISC_TB_INS_NOP;
							// Decrease the counter by 1. When the counter value is 0 the NOP period is finished
							tb_ins_nop_period[cur_stimulus_cpu] = tb_ins_nop_period[cur_stimulus_cpu] - 1;
					  end
				  // After last action's ACK from cpu, instruction changed back to nop.
				 else if (tb_ins_ack_pkg[cur_stimulus_cpu] == 1 )								       		  //when NOP is not required //checking the master's ack bus//defined in the package  
							cpu_ip.tb_ins_array[cur_stimulus_cpu] = `MESI_ISC_TB_INS_NOP;  	              		  //if there is an acknowledgement means an inst has been completed       
				           
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
								tb_ins_nop_period[cur_stimulus_cpu] = stimulus_nop_period;		  //NOP operation period
							else
								begin
									  cpu_ip.tb_ins_array[cur_stimulus_cpu] = stimulus_op; // 1 for wr, 2 for rd
									  cpu_ip.tb_ins_addr_array[cur_stimulus_cpu] = stimulus_addr;          
								end
					  end 
			end 
	
	endfunction
	
	function void gen_stimulus_matrix();
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
		
	task run_phase(uvm_phase phase);
		  
		  phase.raise_objection(this);
		  						//reset command 
		  reset_op(); 								    //generates stimulus for reset 
			
			cpu_ip_port.put(cpu_ip);			//put it into the fifo for the driver to pull it 
		  repeat (1000) begin : random_loop
			//assign cpu_ip by calling the tasks 
			 gen_stimulus;			   			    //generates stimulus and ssigns it to the structure 
			 //gen_stimulus_matrix;					//generates stimului for matrix and memory 
			 
			 //send_command(cpu_ip);		//calls the bfm task which puts the command into the fifo 
			 cpu_ip_port.put(cpu_ip);								//put it into the fifo for the driver to pull it 
		  end : random_loop
		  #500;
		  phase.drop_objection(this);
	endtask : run_phase

task assign_mbus_ack();
	cpu_ip.mbus_ack = mbus_ack_memory[3:0] | bfm.mbus_ack_mesi_isc[3:0];
endtask: assign_mbus_ack
	
endclass: tester 