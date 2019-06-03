/********************************************************************************
*
* Authors: Vinitha Baddam, Monika Sinduja Mullapudi, Zerin Fatima
* Date: 5/31/2019
*
* Description:	This bus functional module implements protocol to drive CPU. It will later be used 
*		for moniitors, scoreboard and coverage
*
*********************************************************************************/

//`timescale 1ns / 1ps
	import mesi_isc_pkg::*;
	`include "mesi_isc_pkg.sv"	

interface mesi_isc_bfm;

		  
	
   
/// Regs and wires
//================================
// System
reg                   clk;          // System clock
reg                   rst;          // Active high system reset

// Main buses
wire  [MBUS_CMD_WIDTH-1:0] mbus_cmd_array [3:0]; // Main bus3 command
wire  [MBUS_CMD_WIDTH-1:0] mbus_cmd3; // Main bus2 command
wire  [MBUS_CMD_WIDTH-1:0] mbus_cmd2; // Main bus2 command
wire  [MBUS_CMD_WIDTH-1:0] mbus_cmd1; // Main bus1 command
wire  [MBUS_CMD_WIDTH-1:0] mbus_cmd0; // Main bus0 command
// Coherence buses
wire  [ADDR_WIDTH-1:0]  mbus_addr_array [3:0];  // Main bus3 address
wire  [ADDR_WIDTH-1:0]  mbus_addr3;  // Main bus3 address
wire  [ADDR_WIDTH-1:0]  mbus_addr2;  // Main bus2 address
wire  [ADDR_WIDTH-1:0]  mbus_addr1;  // Main bus1 address
wire  [ADDR_WIDTH-1:0]  mbus_addr0;  // Main bus0 address
reg   [DATA_WIDTH-1:0]  mbus_data_rd;  // Main bus data read
wire  [DATA_WIDTH-1:0]  mbus_data_wr_array [3:0];  // Main bus data read
wire  [DATA_WIDTH-1:0]  mbus_data_wr3;  // Main bus data read
wire  [DATA_WIDTH-1:0]  mbus_data_wr2;  // Main bus data read
wire  [DATA_WIDTH-1:0]  mbus_data_wr1;  // Main bus data read
wire  [DATA_WIDTH-1:0]  mbus_data_wr0;  // Main bus data read

wire  [7:0]             mbus_data_rd_word_array [3:0]; // Bus data read in words
                                        // word

wire                    cbus_ack3;  // Coherence bus3 acknowledge
wire                    cbus_ack2;  // Coherence bus2 acknowledge
wire                    cbus_ack1;  // Coherence bus1 acknowledge
wire                    cbus_ack0;  // Coherence bus0 acknowledge
   

wire   [ADDR_WIDTH-1:0] cbus_addr;  // Coherence bus address. All busses have
                                      // the same address
wire   [CBUS_CMD_WIDTH-1:0] cbus_cmd3; // Coherence bus3 command
wire   [CBUS_CMD_WIDTH-1:0] cbus_cmd2; // Coherence bus2 command
wire   [CBUS_CMD_WIDTH-1:0] cbus_cmd1; // Coherence bus1 command
wire   [CBUS_CMD_WIDTH-1:0] cbus_cmd0; // Coherence bus0 command

wire   [3:0]            mbus_ack;  // Main bus3 acknowledge
reg    [3:0]            mbus_ack_memory;
wire   [3:0]            mbus_ack_mesi_isc;
reg    [3:0]            tb_ins_array [3:0];
wire   [3:0]            tb_ins3;
wire   [3:0]            tb_ins2;
wire   [3:0]            tb_ins1;
wire   [3:0]            tb_ins0;
reg    [3:0]            tb_ins_addr_array [3:0];
wire   [3:0]            tb_ins_addr3;
wire   [3:0]            tb_ins_addr2;
wire   [3:0]            tb_ins_addr1;
wire   [3:0]            tb_ins_addr0;
reg    [7:0]            tb_ins_nop_period [3:0];
wire   [7:0]            tb_ins_nop_period3;
wire   [7:0]            tb_ins_nop_period2;
wire   [7:0]            tb_ins_nop_period1;
wire   [7:0]            tb_ins_nop_period0;
wire   [3:0]            tb_ins_ack;
reg    [31:0]           mem   [9:0];  // Main memory
wire   [31:0]           mem0;
wire   [31:0]           mem1;
wire   [31:0]           mem2;
wire   [31:0]           mem3;
wire   [31:0]           mem4;
wire   [31:0]           mem5;
wire   [31:0]           mem6;
wire   [31:0]           mem7;
wire   [31:0]           mem8;
wire   [31:0]           mem9;
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
// For debug in GTKwave
wire   [ADDR_WIDTH+BROAD_TYPE_WIDTH+2+BROAD_ID_WIDTH:0] broad_fifo_entry0;
wire   [ADDR_WIDTH+BROAD_TYPE_WIDTH+2+BROAD_ID_WIDTH:0] broad_fifo_entry1;
wire   [ADDR_WIDTH+BROAD_TYPE_WIDTH+2+BROAD_ID_WIDTH:0] broad_fifo_entry2;
wire   [ADDR_WIDTH+BROAD_TYPE_WIDTH+2+BROAD_ID_WIDTH:0] broad_fifo_entry3;

wire   [5:0]            cache_state_valid_array [3:0];

integer                 i, j, k, l, m, n, p;

reg [31:0]              stat_cpu_access_nop [3:0];
reg [31:0]              stat_cpu_access_rd  [3:0];
reg [31:0]              stat_cpu_access_wr  [3:0];
   
// Statistic
//================================
always @(posedge clk or posedge rst)
if (rst)
  for (n = 0; n < 4; n = n + 1)
  begin
    stat_cpu_access_nop[n] = 0;
    stat_cpu_access_rd[n]  = 0;
    stat_cpu_access_wr[n]  = 0;
  end
else 
  for (p = 0; p < 4; p = p + 1)
    if (tb_ins_ack[p])
      begin
      case (tb_ins_array[p])
	`MESI_ISC_TB_INS_NOP: stat_cpu_access_nop[p] = stat_cpu_access_nop[p]+1;
	`MESI_ISC_TB_INS_WR:  stat_cpu_access_wr[p]  = stat_cpu_access_wr[p] +1;
        `MESI_ISC_TB_INS_RD:  stat_cpu_access_rd[p]  = stat_cpu_access_rd[p] +1;
      endcase // case (tb_ins_array[p])
    end
   
// clock and reset
//================================

   initial begin
      clk = 0;
      forever begin
         #10;
         clk = ~clk;
      end
   end

// Memory and matrix
//================================
always @(posedge clk or posedge rst)
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
       if ((mbus_cmd_array[cpu_priority+i] == `MESI_ISC_MBUS_CMD_WR |
            mbus_cmd_array[cpu_priority+i] == `MESI_ISC_MBUS_CMD_RD  ) &
            !mem_access)
    begin
                     mem_access      = 1;
                     cpu_selected    = cpu_priority+i;
                     mbus_ack_memory[cpu_priority+i] = 1;
      if (mbus_cmd_array[cpu_priority+i] == `MESI_ISC_MBUS_CMD_WR)
      // WR
      begin
                     //sanity_check_rule1_rule2(cpu_selected,
                                          //  mbus_addr_array[cpu_priority+i],
                                           // mbus_data_wr_array[cpu_priority+i]);
                     mem[mbus_addr_array[cpu_priority+i]] =
                                           mbus_data_wr_array[cpu_priority+i];
      end
      // RD
      else
                     mbus_data_rd =        mem[mbus_addr_array[cpu_priority+i]];
    end
  end
   
assign mbus_ack[3:0] = mbus_ack_memory[3:0] | mbus_ack_mesi_isc[3:0];

assign broad_fifo_entry0 = mesi_isc.mesi_isc_broad.broad_fifo.entry[0];
assign broad_fifo_entry1 = mesi_isc.mesi_isc_broad.broad_fifo.entry[1];
assign brroad_fifo_entry2 = mesi_isc.mesi_isc_broad.broad_fifo.entry[2];
assign brroad_fifo_entry3 = mesi_isc.mesi_isc_broad.broad_fifo.entry[3];
assign mbus_cmd3          = mbus_cmd_array[3];
assign mbus_cmd2          = mbus_cmd_array[2];
assign mbus_cmd1          = mbus_cmd_array[1];
assign mbus_cmd0          = mbus_cmd_array[0];
assign mbus_addr3         = mbus_addr_array[3];
assign mbus_addr2         = mbus_addr_array[2];
assign mbus_addr1         = mbus_addr_array[1];
assign mbus_addr0         = mbus_addr_array[0];
assign mbus_data_wr3      = mbus_data_wr_array[3];
assign mbus_data_wr2      = mbus_data_wr_array[2];
assign mbus_data_wr1      = mbus_data_wr_array[1];
assign mbus_data_wr0      = mbus_data_wr_array[0];
assign tb_ins3            = tb_ins_array[3];
assign tb_ins2            = tb_ins_array[2];
assign tb_ins1            = tb_ins_array[1];
assign tb_ins0            = tb_ins_array[0];
assign tb_ins_addr3       = tb_ins_addr_array[3];
assign tb_ins_addr2       = tb_ins_addr_array[2];
assign tb_ins_addr1       = tb_ins_addr_array[1];
assign tb_ins_addr0       = tb_ins_addr_array[0];
assign tb_ins_nop_period3 = tb_ins_nop_period[3];
assign tb_ins_nop_period2 = tb_ins_nop_period[2];
assign tb_ins_nop_period1 = tb_ins_nop_period[1];
assign tb_ins_nop_period0 = tb_ins_nop_period[0];
assign mem0 = mem[0];
assign mem1 = mem[1];
assign mem2 = mem[2];
assign mem3 = mem[3];
assign mem4 = mem[4];
assign mem5 = mem[5];
assign mem6 = mem[6];
assign mem7 = mem[7];
assign mem8 = mem[8];
assign mem9 = mem[9];
assign mbus_data_rd_word_array[3] = mbus_data_rd[31:24]; 
assign mbus_data_rd_word_array[2] = mbus_data_rd[23:16]; 
assign mbus_data_rd_word_array[1] = mbus_data_rd[15:8]; 
assign mbus_data_rd_word_array[0] = mbus_data_rd[7:0]; 

	task reset_bfm();
		 $display ("reset bfm\n");
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
		//@(negedge clk);
		 // @(negedge clk);
		 // rst = 1'b0;
	endtask : reset_bfm

	task send_ip_cpu(reg [3:0] tb_ins_array [3:0], reg [3:0] tb_ins_addr_array [3:0], reg [7:0] tb_ins_nop_period [3:0]);
		
		$display("send ip");
		//driving inputs to cpu task 
		//@(negedge clk);
		//@(negedge clk);
			begin 
				assign rst = 1'b0;
				//assign tb_ins_array = tb_ins_array;
				//assign tb_ins_addr_array = tb_ins_addr_array;
				//assign tb_ins_nop_period = tb_ins_nop_period;
			end
		@(posedge clk);
	endtask: send_ip_cpu 
	
	
task dispaly_end();
  $display ("Watchdog finish\n");
  $display ("Statistic\n");
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
endtask : dispaly_end

	
endinterface: mesi_isc_bfm