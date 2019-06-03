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
`include "mesi_isc_define.v"
`include "mesi_isc_tb_define.v"

interface mesi_isc_bfm_mod;
   parameter
  CBUS_CMD_WIDTH           = 3,
  ADDR_WIDTH               = 32,
  DATA_WIDTH               = 32,
  BROAD_TYPE_WIDTH         = 2,  
  BROAD_ID_WIDTH           = 5,  
  BROAD_REQ_FIFO_SIZE      = 4,
  BROAD_REQ_FIFO_SIZE_LOG2 = 2,
  MBUS_CMD_WIDTH           = 3,
  BREQ_FIFO_SIZE           = 2,
  BREQ_FIFO_SIZE_LOG2      = 1;

   
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

logic   [3:0]            mbus_ack;  // Main bus3 acknowledge
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

// For debug in GTKwave
wire   [ADDR_WIDTH+BROAD_TYPE_WIDTH+2+BROAD_ID_WIDTH:0] broad_fifo_entry0;
wire   [ADDR_WIDTH+BROAD_TYPE_WIDTH+2+BROAD_ID_WIDTH:0] broad_fifo_entry1;
wire   [ADDR_WIDTH+BROAD_TYPE_WIDTH+2+BROAD_ID_WIDTH:0] broad_fifo_entry2;
wire   [ADDR_WIDTH+BROAD_TYPE_WIDTH+2+BROAD_ID_WIDTH:0] broad_fifo_entry3;

wire   [5:0]            cache_state_valid_array [3:0];

//integer                 i, j, k, l, m, n, p;


	
	
	
// Assigns
//================================
// GTKwave can't see arrays. points to array so GTKwave can see these signals
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

//================================
initial
begin
  // Reset the memory
  for (j = 0; j < 10; j = j + 1)
    bfm.mem[j] = 0;
  clk = 1;
  rst = 1;
  repeat (10) @(negedge clk);
  rst = 0;
  repeat (20000) @(negedge clk);   // Watchdog
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
  $finish;
end

// clock and reset
//================================
always #50
       clk = !clk;

/*function void assign_mbus_ack();
		assign mbus_ack[3:0] = mbus_ack_memory[3:0] | mbus_ack_mesi_isc[3:0];
	endfunction: assign_mbus_ack*/
	
endinterface: mesi_isc_bfm_mod
