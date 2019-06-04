/********************************************************************************
*
* Authors: Vinitha Baddam, Monika Sinduja Mullapudi, Zerin Fatima
* Date: 5/31/2019
*
* Description:	This bus functional module implements protocol to drive CPU. It will later be used 
*		for moniitors, scoreboard and coverage
*
*********************************************************************************/

import mesi_isc_pkg::*;
`include "mesi_isc_pkg.sv"	

interface mesi_isc_bfm;

	/// Regs and wires
	//================================
	// System
	reg	clk;          // System clock
	reg	rst;          // Active high system reset

	// Main buses
	wire  [MBUS_CMD_WIDTH-1:0] mbus_cmd_array [3:0]; // Main bus3 command
	
	// Coherence buses
	wire  [ADDR_WIDTH-1:0]  mbus_addr_array [3:0];  // Main bus3 address
	
	reg   [DATA_WIDTH-1:0]  mbus_data_rd;  // Main bus data read
	wire  [DATA_WIDTH-1:0]  mbus_data_wr_array [3:0];  // Main bus data read

	wire  cbus_ack3;  // Coherence bus3 acknowledge
	wire  cbus_ack2;  // Coherence bus2 acknowledge
	wire  cbus_ack1;  // Coherence bus1 acknowledge
	wire  cbus_ack0;  // Coherence bus0 acknowledge

	wire   [ADDR_WIDTH-1:0] cbus_addr;  // Coherence bus address. All busses have the same address
	wire   [CBUS_CMD_WIDTH-1:0] cbus_cmd3; // Coherence bus3 command
	wire   [CBUS_CMD_WIDTH-1:0] cbus_cmd2; // Coherence bus2 command
	wire   [CBUS_CMD_WIDTH-1:0] cbus_cmd1; // Coherence bus1 command
	wire   [CBUS_CMD_WIDTH-1:0] cbus_cmd0; // Coherence bus0 command

	wire   [3:0]            mbus_ack;  // Main bus3 acknowledge
	reg    [3:0]            mbus_ack_memory;
	wire   [3:0]            mbus_ack_mesi_isc;
	reg    [3:0]            tb_ins_array [3:0];
	reg    [3:0]            tb_ins_array_i [3:0];
	reg    [3:0]            tb_ins_addr_array [3:0];
	reg    [3:0]            tb_ins_addr_array_i [3:0];
	reg    [7:0]            tb_ins_nop_period_i [3:0];
	reg    [7:0]            tb_ins_nop_period [3:0];
	wire   [3:0]            tb_ins_ack;
	reg    [31:0]           mem   [9:0];  // Main memory
	reg    [1:0]            cpu_priority;
	reg    [3:0]            cpu_selected;   
	reg                     mem_access;
	integer                 stimulus_rand_numb [9:0];
	integer                 seed = 10;
	reg    [1:0]            stimulus_rand_cpu_select;
	reg    [1:0]            stimulus_op;
	reg    [7:0]            stimulus_addr;
	reg    [7:0]            stimulus_nop_period;
	integer                 cur_stimulus_cpu;

	wire   [5:0]            cache_state_valid_array [3:0];

	integer                 i, j, k, l, m, n, p;

	reg [31:0]              stat_cpu_access_nop [3:0];
	reg [31:0]              stat_cpu_access_rd  [3:0];
	reg [31:0]              stat_cpu_access_wr  [3:0];
   
	// Statistic
	//================================
	always @(posedge clk or posedge rst)
	begin
		if(rst)
		begin
			for (n = 0; n < 4; n = n + 1)
			begin
				stat_cpu_access_nop[n] = 0;
				stat_cpu_access_rd[n]  = 0;
				stat_cpu_access_wr[n]  = 0;
			end //for
		end //if
		else 
		begin
			for (p = 0; p < 4; p = p + 1)
			begin
				if(tb_ins_ack[p])
				begin
					case (tb_ins_array[p])
						`MESI_ISC_TB_INS_NOP: stat_cpu_access_nop[p] = stat_cpu_access_nop[p]+1;
						`MESI_ISC_TB_INS_WR:  stat_cpu_access_wr[p]  = stat_cpu_access_wr[p] +1;
						`MESI_ISC_TB_INS_RD:  stat_cpu_access_rd[p]  = stat_cpu_access_rd[p] +1;
					endcase // case 
				end
			end //for
		end //else
	end
   
	// clock and reset
	//================================
	initial begin
		clk = 0;
		rst = 0;
		forever begin
			#10;
			clk = ~clk;
		end
	end

	// Memory and matrix
	//================================
	always @(posedge clk or posedge rst)
	begin
		if (rst)
		begin
			cpu_priority    = 0;
			cpu_selected    = 0;
		end
		else
		begin
			mbus_ack_memory = 0;
			mem_access      = 0;
			for (i = 0; i < 4; i = i + 1)
			begin
				if ((mbus_cmd_array[cpu_priority+i] == `MESI_ISC_MBUS_CMD_WR |
					mbus_cmd_array[cpu_priority+i] == `MESI_ISC_MBUS_CMD_RD  ) & !mem_access)
				begin
					mem_access      = 1;
					cpu_selected    = cpu_priority+i;
					mbus_ack_memory[cpu_priority+i] = 1;
					// WR
					if (mbus_cmd_array[cpu_priority+i] == `MESI_ISC_MBUS_CMD_WR)
					begin
						mem[mbus_addr_array[cpu_priority+i]] = mbus_data_wr_array[cpu_priority+i];
					end
					// RD
					else
					begin
						mbus_data_rd = mem[mbus_addr_array[cpu_priority+i]];
					end
				end
			end //for
		end //else
	end
   
	assign mbus_ack[3:0] = mbus_ack_memory[3:0] | mbus_ack_mesi_isc[3:0];

	input_port inport;
	//assigning inputs to input struct			
	//collecting the command info of input port 
	assign	inport.mbus_cmd3_i = mbus_cmd_array[3];
	assign	inport.mbus_cmd2_i = mbus_cmd_array[2];
	assign	inport.mbus_cmd1_i = mbus_cmd_array[1];
	assign	inport.mbus_cmd0_i = mbus_cmd_array[0];
			
	//collecting the addr info of input port
	assign	inport.mbus_addr3_i = mbus_addr_array[3];
	assign	inport.mbus_addr2_i = mbus_addr_array[2];
	assign	inport.mbus_addr1_i = mbus_addr_array[1];
	assign	inport.mbus_addr0_i = mbus_addr_array[0];
			
	//collecting ack of coherence bus 
	assign	inport.cbus_ack3_i = cbus_ack3;
	assign	inport.cbus_ack2_i = cbus_ack2;
	assign	inport.cbus_ack1_i = cbus_ack1;
	assign	inport.cbus_ack0_i = cbus_ack0;
 

	output_port outport;
	//assigning outputs to output struct
	//collect info of coherence addrs bus
	assign outport.cbus_addr_o = cbus_addr;
	//collect info of coherence cmnd bus
	assign outport.cbus_cmd3_o = cbus_cmd3;
	assign outport.cbus_cmd2_o = cbus_cmd2;
	assign outport.cbus_cmd1_o = cbus_cmd1;
	assign outport.cbus_cmd0_o = cbus_cmd0;
	//collect info of master bus ack
	assign outport.mbus_ack3_o = mbus_ack_mesi_isc[3];
	assign outport.mbus_ack2_o = mbus_ack_mesi_isc[2];
	assign outport.mbus_ack1_o = mbus_ack_mesi_isc[1];
	assign outport.mbus_ack0_o = mbus_ack_mesi_isc[0];

	//reset task called from tester
	task reset_bfm();
		//$display ("reset bfm\n");
		rst = 1'b1;
		for (j = 0; j < 10; j = j + 1)
			mem[j] = 0;
			
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
		@(negedge clk);
	endtask : reset_bfm

	//This task get called from tester for passing random stimulus
	task send_ip_cpu(reg [3:0] tb_ins_array [3:0], reg [3:0] tb_ins_addr_array [3:0], reg [7:0] tb_ins_nop_period [3:0]);	
		//$display("send ip");
		//driving inputs to cpu task 
		begin 
			assign rst = 1'b0;
			assign tb_ins_array_i = tb_ins_array;
			assign tb_ins_addr_array_i = tb_ins_addr_array;
			assign tb_ins_nop_period_i = tb_ins_nop_period;
		end
		@(posedge clk);
	endtask: send_ip_cpu 
	
	
	task dispaly_stats();
	  $display ("Statistics:\n");
	  $display ("CPU 3. WR:%d RD:%d NOP:%d  \n", stat_cpu_access_wr[3],
												stat_cpu_access_rd[3],
												stat_cpu_access_nop[3]);
	  $display ("CPU 2. WR:%d RD:%d NOP:%d\n", stat_cpu_access_wr[2],
												stat_cpu_access_rd[2],
												stat_cpu_access_nop[2]);
	  $display ("CPU 1. WR:%d RD:%d NOP:%d\n", stat_cpu_access_wr[1],
												stat_cpu_access_rd[1],
												stat_cpu_access_nop[1]);
	  $display ("CPU 0. WR: %d RD:%d NOP:%d\n", stat_cpu_access_wr[0],
												stat_cpu_access_rd[0],
												stat_cpu_access_nop[0]);
	  $display ("Total rd and wr accesses: %d\n", stat_cpu_access_wr[3] +
												  stat_cpu_access_rd[3] +
												  stat_cpu_access_wr[2] +
												  stat_cpu_access_rd[2] +
												  stat_cpu_access_wr[1] +
												  stat_cpu_access_rd[1] +
												  stat_cpu_access_wr[0] +
												  stat_cpu_access_rd[0]);
	endtask : dispaly_stats

endinterface: mesi_isc_bfm