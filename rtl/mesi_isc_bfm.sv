/********************************************************************************
* Authors: Vinitha Baddam, Monika Sinduja Mullapudi, Zerin Fatima
* Reference: https://github.com/PrakashLuu/mesi_verification
* Reference: https://github.com/shruti2611/EE382M_project/blob/master/mesi_fifo/mesi_isc_define.v
* Reference: https://github.com/rdsalemi/uvmprimer/tree/master/16_Analysis_Ports_In_the_Testbench
* Last Modified: March 3, 2019
*
* Description:	This bus functional module implements protocol to drive CPU. It will later be used 
*					for moniitors and its subscribers- the scoreboard and the coverage
********************************Change Log******************************************************* 
* Srijana S. and Zeba K. R.			3/3/2019		Created
********************************************************************************/
`timescale 1ns / 1ps

`include "mesi_isc_command_monitor.svh"
`include "mesi_isc_result_monitor.svh"

interface mesi_isc_bfm;

	import mesi_isc_pkg::*;		

	command_monitor command_monitor_h;	
	result_monitor  result_monitor_h;				  
	
	//INPUT ports of the design 
	bit clk;
	bit rst = 0;
	
	//INPUTS TO CPU <not coming from the design outputs>
	logic   [DATA_WIDTH-1:0] mbus_data_rd;  		// Main bus data read
	logic   [3:0]            mbus_ack;  	 		// Main bus3 acknowledge
	logic   [3:0]            tb_ins_array [3:0];
	logic   [3:0]            tb_ins_addr_array [3:0];
	
	//OUTPUTS from CPU <not given to design>
	logic   [DATA_WIDTH-1:0] mbus_data_wr_array [3:0];  // Main bus data read
    logic   [3:0]            tb_ins_ack;
	//OUTPUTS from CPU <also given to design as inputs>
	logic                    cbus_ack3;  			  // Coherence bus3 acknowledge
	logic                    cbus_ack2;  			  // Coherence bus2 acknowledge
	logic                    cbus_ack1;  			  // Coherence bus1 acknowledge
	logic                    cbus_ack0;  			  // Coherence bus0 acknowledge
	logic  [MBUS_CMD_WIDTH-1:0] mbus_cmd_array [3:0];   // Main bus3 command
	logic  [ADDR_WIDTH-1:0]     mbus_addr_array [3:0];   // Main bus3 address
	
	//OUTPUT ports of the design <also inptus to CPU>
	logic   [ADDR_WIDTH-1:0] cbus_addr;  			  // Coherence bus address. All busses have
													  // the same address
	logic   [CBUS_CMD_WIDTH-1:0] cbus_cmd3; 		  // Coherence bus3 command//initializing with NOP cimmans
	logic   [CBUS_CMD_WIDTH-1:0] cbus_cmd2; 		  // Coherence bus2 command
	logic   [CBUS_CMD_WIDTH-1:0] cbus_cmd1; 		  // Coherence bus1 command
	logic   [CBUS_CMD_WIDTH-1:0] cbus_cmd0; 		  // Coherence bus0 command
	logic   [3:0]            mbus_ack_mesi_isc;		  //master acknowledge bus 
	
	//DEBUG
	logic   [ADDR_WIDTH-1:0] cbus_addr_cpu;  			  // Coherence bus address. All busses have
														// the same address
	logic   [CBUS_CMD_WIDTH-1:0] cbus_cmd3_cpu; 		  // Coherence bus3 command//initializing with NOP cimmans
	logic   [CBUS_CMD_WIDTH-1:0] cbus_cmd2_cpu; 		  // Coherence bus2 command
	logic   [CBUS_CMD_WIDTH-1:0] cbus_cmd1_cpu; 		  // Coherence bus1 command
	logic   [CBUS_CMD_WIDTH-1:0] cbus_cmd0_cpu; 		  // Coherence bus0 command
	
	
	
	//clock block
	initial 
		begin
			clk = 1;
			forever 
				begin
					#50;
					clk = !clk; 
				end 
		end 
	
	//initializing the o/p of design which goes as input to CPU 
	initial
		begin 
			cbus_addr_cpu = '0;
			cbus_cmd3_cpu = 3'd1;
			cbus_cmd2_cpu = 0;
			cbus_cmd1_cpu = 0;
			cbus_cmd0_cpu = 0;	
		
		end
	
	always @(cbus_addr || cbus_cmd3 || cbus_cmd2 || cbus_cmd1 || cbus_cmd0)
		begin
			cbus_addr_cpu = cbus_addr;
			cbus_cmd3_cpu = cbus_cmd3;
			cbus_cmd2_cpu = cbus_cmd2;
			cbus_cmd1_cpu = cbus_cmd1;
			cbus_cmd0_cpu = cbus_cmd0;
		end 
	
		
	always @(tb_ins_ack or tb_ins_array[3] or tb_ins_array[2] or tb_ins_array[1] or tb_ins_array[0])
		begin
			tb_ins_ack_pkg = tb_ins_ack;
			tb_ins_array_pkg[3] = tb_ins_array[3];
			tb_ins_array_pkg[2] = tb_ins_array[2];
			tb_ins_array_pkg[1] = tb_ins_array[1];
			tb_ins_array_pkg[0] = tb_ins_array[0];
		end 

	
	task assign_ip(input cpu_ip_s cpu_ip);
			//inputs to CPU 

		mbus_data_rd = cpu_ip.mbus_data_rd;
		mbus_ack[cpu_ip.cpu_id] = cpu_ip.mbus_ack;
		tb_ins_array[cpu_ip.cpu_id] = cpu_ip.tb_ins_array;
		tb_ins_addr_array[cpu_ip.cpu_id] = cpu_ip.tb_ins_addr_array;
	endtask
	
	//send INPUT to cpu3 
	task send_ip_cpu(input cpu_ip_s cpu_ip);
		
		$display("cpu id = %d\n",cpu_ip.cpu_id);
		//driving inputs to cpu task 
		@(posedge clk);
		if(cpu_ip.reset)
			begin 
				rst = 1;									//reset operation //will go to both design and cpu 
				//inputs for reset 
				assign_ip(cpu_ip);							//assigning the inputs to cpu 
				repeat (10) @(negedge clk);
				rst = 0;	
			end 
		else 
			begin 
				assign_ip(cpu_ip);							//assigining inputs to cpu 
			end
	endtask: send_ip_cpu 
	
	
	input_ports inport;
	//writing into the command monitor port
	always @(posedge mbus_ack[3] or posedge mbus_ack[2] or posedge mbus_ack[1] or posedge mbus_ack[0])
		begin : command_monitor_p
			//static bit in_command = 0;
				
			//collecting the command info of input port 
			inport.mbus_cmd3_i = mbus_cmd_array[3];
			inport.mbus_cmd2_i = mbus_cmd_array[2];
			inport.mbus_cmd1_i = mbus_cmd_array[1];
			inport.mbus_cmd0_i = mbus_cmd_array[0];
			
			//collecting the addr info of input port
			inport.mbus_addr3_i = mbus_addr_array[3];
			inport.mbus_addr2_i = mbus_addr_array[2];
			inport.mbus_addr1_i = mbus_addr_array[1];
			inport.mbus_addr0_i = mbus_addr_array[0];
			
			//collecting ack of coherence bus 
			inport.cbus_ack3_i = cbus_ack3;
			inport.cbus_ack2_i = cbus_ack2;
			inport.cbus_ack1_i = cbus_ack1;
			inport.cbus_ack0_i = cbus_ack0;
			
			command_monitor_h.write_to_monitor(inport);								//write into the analysis port 
		end : command_monitor_p 
	
	tired outport;
	//writing into result monitor port 
	always @(cbus_addr)
		begin: result_monitor_1 
			//tired outport;
			
			@(negedge clk);
			@(negedge clk);
			assign_outport(outport);									//assign the output values to struct
			result_monitor_h.write_to_monitor(outport);					//write into result analysis port
			
			@(negedge cbus_ack3 or negedge cbus_ack2 or negedge cbus_ack1 or negedge cbus_ack0);
			@(negedge clk);
			assign_outport(outport);									//assign the output values to struct
			result_monitor_h.write_to_monitor(outport);					//write into result analysis port

		end: result_monitor_1  

	//task being called in the above task 
	task assign_outport(input tired outport);
		//collect info of coherence addrs bus
		outport.cbus_addr_o = cbus_addr;
		//collect info of coherence cmnd bus
		outport.cbus_cmd3_o = cbus_cmd3;
		outport.cbus_cmd2_o = cbus_cmd2;
		outport.cbus_cmd1_o = cbus_cmd1;
		outport.cbus_cmd0_o = cbus_cmd0;
		//collect info of master bus ack
		outport.mbus_ack3_o = mbus_ack_mesi_isc[3];
		outport.mbus_ack2_o = mbus_ack_mesi_isc[2];
		outport.mbus_ack1_o = mbus_ack_mesi_isc[1];
		outport.mbus_ack0_o = mbus_ack_mesi_isc[0];
	endtask: assign_outport
	
endinterface: mesi_isc_bfm