/********************************************************************************
*
* Authors: Vinitha Baddam, Monika Sinduja Mullapudi, Zerin Fatima
* Date: 5/31/2019
*
* Description:	This is the main design midule
*
********************************************************************************/

import mesi_isc_pkg::*;
`include "mesi_isc_pkg.sv"

module mesi_isc_tb_cpu
    (
     // Inputs
     clk,
     rst,
     cbus_addr_i,
     cbus_cmd_i,
     mbus_data_i,
     mbus_ack_i,
     cpu_id_i,
     tb_ins_i,
     tb_ins_addr_i,
     // Outputs
     mbus_cmd_o,
     mbus_addr_o,
     mbus_data_o,
     cbus_ack_o,
     tb_ins_ack_o
   );
  
import mesi_isc_pkg::*;	  						  //importing the package
  
// Inputs
//================================
// System
input                   clk;          // System clock
input                   rst;          // Active high system reset
input [ADDR_WIDTH-1:0] cbus_addr_i;   // Coherence bus address. All busses have
                                      // the same address
input [CBUS_CMD_WIDTH-1:0] cbus_cmd_i; // Coherence bus3 command
input [DATA_WIDTH-1:0]  mbus_data_i; // Main bus read data
input                  mbus_ack_i;    // Main bus3 acknowledge
// tb
input [1:0]            cpu_id_i;
   
input [3:0]            tb_ins_i;      // Instruction for CPU to perform an
                                      // action
input [3:0]            tb_ins_addr_i; // Instruction address
// Outputs
//================================
// Main buses
output [MBUS_CMD_WIDTH-1:0] mbus_cmd_o; // Main bus3 command
output [ADDR_WIDTH-1:0]  mbus_addr_o;  // Coherence bus3 address
output [DATA_WIDTH-1:0]  mbus_data_o; // Main bus write data
// Coherence buses
output                   cbus_ack_o;  // Coherence bus3 acknowledge
// tb
output                   tb_ins_ack_o; // Acknowledge for the
                                      //  CPU instruction
   
   
// Regs & wires
//================================
reg                          tb_ins_ack_o;   

reg  [MBUS_CMD_WIDTH-1:0] mbus_cmd_o; // Main bus3 command
reg  [ADDR_WIDTH-1:0]    mbus_addr_o;  // Coherence bus3 address
reg  [2:0]               m_state;
reg  [7:0]               wr_data [5:0];
reg                      wr_proc_wait_for_en;
reg  [ADDR_WIDTH-1:0]    wr_proc_addr;
reg                      rd_proc_wait_for_en;
reg  [ADDR_WIDTH-1:0]    rd_proc_addr;
reg                      cbus_ack_o;  // Coherence bus3 acknowledge
reg                      m_state_c_state_priority;
reg  [3:0]               c_state;
reg  [ADDR_WIDTH-1:0]    m_addr;
reg  [31:0] cache [ADDR_WIDTH-1:0];
reg  [ADDR_WIDTH-1:0]    c_addr;
reg  [DATA_WIDTH-1:0]    mbus_data_o; // Main bus write data
integer                  m_state_send_wr_br_counter,m_state_send_rd_br_counter;
integer                  i,j,k;     // Loop index

// initial
//================================  
initial
  for (i = 0; i < 10; i = i + 1)
  begin
    c_state[i] = `MESI_ISC_TB_CPU_MESI_I; //all zeros //IDLE STATE 
  end
   
// m_state - Main bus state machine and
// c_state - Coherence bus state machine and
//================================  
//
//  m_state
//  ---------------------------------------------------
//  |                                                 |
//  -----> IDLE ----- m_state_c_state_priority == 0 ---
//          |
//          --------- m_state_c_state_priority == 1 ---
//                                                    |
//         Other states <------------------------------
//
//  c_state
//  ---------------------------------------------------
//  |                                                 |
//  -----> IDLE ----- m_state_c_state_priority == 1 ---
//          |
//          --------- m_state_c_state_priority == 0 ---
//                                                    |
//         Other states <------------------------------

// m_state_c_state_priority
//================================ 
// When set only m_state can start a process (move from IDLE state).   
// When clear only c_state can start a process (move from IDLE state).   
always @(posedge clk or posedge rst)
  if (rst) m_state_c_state_priority <= 0;
  else     m_state_c_state_priority <= ~m_state_c_state_priority;
   
// m_state    
// Main bus state machine
//================================  
//
//  -----------------------------------
//  | -------             |           |
//  | |     |             |           |
//  |----> IDLE --------> WR_CACHE    |
//          |                         |
//          |-----------> RD_CACHE ---|
//          |                         |
//          |        -------          |
//          |        |     |          |
//          |-----------> SEND_WR_BR -|
//          |                         |
//          |        -------          |
//          |        |     |          |
//          ------------> SEND_RD_BR -|

always @(posedge clk or posedge rst)
  if (rst)
	  begin
				m_state                    <= `MESI_ISC_TB_CPU_M_STATE_IDLE;
				tb_ins_ack_o               <= 0; 
				mbus_cmd_o                 <= `MESI_ISC_MBUS_CMD_NOP;
				wr_proc_wait_for_en        <= 0;
				wr_proc_addr               <= 0; 
				rd_proc_wait_for_en        <= 0;
				rd_proc_addr               <= 0; 
				m_state_send_wr_br_counter <= 0;
				m_state_send_rd_br_counter <= 0;
				for (k = 0; k < 6; k = k + 1)
				  wr_data[k]               <= 1;

	  end
  else case (m_state)						//check the master state 
		//master state IDLE 
		`MESI_ISC_TB_CPU_M_STATE_IDLE:
			//----------------------------------
			begin
					m_state_send_wr_br_counter <= 0; // Clear the counter
					m_state_send_rd_br_counter <= 0; // Clear the counter
					tb_ins_ack_o      <= 0;   // Send ack when an action is finished
				  // CBUS and MBUS can't be active in the same time. When CBUS is
				  // active - wait.
				  // If priority is not of m_state - stay on IDLE 
				  if (c_state !=`MESI_ISC_TB_CPU_M_STATE_IDLE | 
					  !m_state_c_state_priority)
					  begin
							m_state           <= `MESI_ISC_TB_CPU_M_STATE_IDLE;
					  end
				  // Start the action when instruction is received and when there is not a
				  // pending action - wait for en read or en wr
				  else if ((tb_ins_i == `MESI_ISC_TB_INS_WR |
							tb_ins_i == `MESI_ISC_TB_INS_RD)  &
						   ~wr_proc_wait_for_en               &
						   ~rd_proc_wait_for_en)
				  begin
						m_addr            <= tb_ins_addr_i; // Store the address of the
												  // instruction
						mbus_addr_o       <= tb_ins_addr_i; // Send the ins address for a
												  // case of an actual action.
						// Depends of the state of the cache line of the desired address,
						// define the action to perform
						case (c_state[tb_ins_addr_i])
							  // The cache state is Modify. Write to cache or read from cache.
							  `MESI_ISC_TB_CPU_MESI_M:
									if (tb_ins_i == `MESI_ISC_TB_INS_WR)
										begin
										   m_state        <= `MESI_ISC_TB_CPU_M_STATE_WR_CACHE;
										   mbus_cmd_o     <= `MESI_ISC_MBUS_CMD_NOP;
										end
									else
										begin
										   m_state        <= `MESI_ISC_TB_CPU_M_STATE_RD_CACHE;
										   mbus_cmd_o     <= `MESI_ISC_MBUS_CMD_NOP;
										end
							  // The memory state is Exclusive. Write to cache or read from cache.
							  `MESI_ISC_TB_CPU_MESI_E: 
									if (tb_ins_i == `MESI_ISC_TB_INS_WR)
										begin
										   m_state        <= `MESI_ISC_TB_CPU_M_STATE_WR_CACHE;
										   mbus_cmd_o     <= `MESI_ISC_MBUS_CMD_NOP;
										end
									else
										begin
										   m_state        <= `MESI_ISC_TB_CPU_M_STATE_RD_CACHE;
										   mbus_cmd_o     <= `MESI_ISC_MBUS_CMD_NOP;
										end
								// The memory state is Shared. 
							  `MESI_ISC_TB_CPU_MESI_S:
									if (tb_ins_i == `MESI_ISC_TB_INS_WR)
										begin // Send a wr broadcast and wait for wr enable.
										  wr_proc_wait_for_en <= 1;
										  wr_proc_addr      <= tb_ins_addr_i; 
										  m_state           <= `MESI_ISC_TB_CPU_M_STATE_SEND_WR_BR;
										  mbus_cmd_o        <= `MESI_ISC_MBUS_CMD_WR_BROAD;
										end
									else // Read from cache.
										begin
										  m_state           <= `MESI_ISC_TB_CPU_M_STATE_RD_CACHE;
										  mbus_cmd_o        <= `MESI_ISC_MBUS_CMD_NOP;
										end
							  // The memory state is Invalid. 
							  `MESI_ISC_TB_CPU_MESI_I:
									 if (tb_ins_i == `MESI_ISC_TB_INS_WR)
										begin // Send a wr broadcast and wait foo wr enable.  
										  wr_proc_wait_for_en <= 1;
										  wr_proc_addr      <= tb_ins_addr_i; 
										  m_state           <= `MESI_ISC_TB_CPU_M_STATE_SEND_WR_BR;
										  mbus_cmd_o        <= `MESI_ISC_MBUS_CMD_WR_BROAD;
										end
									else 
										begin // Send a rd broadcast and wait foe rd enable.
										  rd_proc_wait_for_en <= 1;
										  rd_proc_addr      <= tb_ins_addr_i; 
										  m_state           <= `MESI_ISC_TB_CPU_M_STATE_SEND_RD_BR; 
										  mbus_cmd_o        <= `MESI_ISC_MBUS_CMD_RD_BROAD;
										end
						endcase
				  end // if (tb_ins_i == `MESI_ISC_TB_INS_WR)
			end // case: `MESI_ISC_TB_CPU_M_STATE_IDLE
		
		// Write to the cache
		`MESI_ISC_TB_CPU_M_STATE_WR_CACHE:
		//----------------------------------
			begin
					// State was M or E. After writing it is M
					c_state[m_addr] <= `MESI_ISC_TB_CPU_MESI_M;
					// A write data to a line contains the incremental data to the
					// related word of the data, depends on the cpu_id_i (word 0 for CPU
					// 0, etc.)
					case (cpu_id_i)
						  0: cache[m_addr][ 7 :0] <= wr_data[m_addr];
						  1: cache[m_addr][15: 8] <= wr_data[m_addr];
						  2: cache[m_addr][23:16] <= wr_data[m_addr];
						  3: cache[m_addr][31:24] <= wr_data[m_addr];
					endcase // case (cpu_id_i)
					wr_data[m_addr]           <= wr_data[m_addr] + 1; // Increment the
											  // write data
					// After the write, send acknowledge to main tb and go to the idle
					// state 
					m_state           <= `MESI_ISC_TB_CPU_M_STATE_IDLE;
					tb_ins_ack_o      <= 1; 
			end // case: `MESI_ISC_TB_CPU_M_STATE_WR_CACHE
		// A cache read from a valid line is a symbolic action in this TB
		`MESI_ISC_TB_CPU_M_STATE_RD_CACHE:
		//----------------------------------
			begin
					m_state           <= `MESI_ISC_TB_CPU_M_STATE_IDLE;
					tb_ins_ack_o      <= 1; 
			end
		`MESI_ISC_TB_CPU_M_STATE_SEND_WR_BR:
			//----------------------------------
			 // Send the wr broadcast. After receiving acknowledge, send acknowledge to
			 // main tb and go to the idle
			begin
					mbus_addr_o       <= m_addr;
					// Counts the number of cycle which m_state in this state
					m_state_send_wr_br_counter = m_state_send_wr_br_counter + 1; 
			  if (mbus_ack_i)
				  begin
						m_state           <= `MESI_ISC_TB_CPU_M_STATE_IDLE;
						tb_ins_ack_o      <= 1;
						mbus_cmd_o        <= `MESI_ISC_MBUS_CMD_NOP;

				  end
			  // To prevent a dead lock, after 31 cycles without an acknowledge, go to
			  // the IDLE state and try again. It enables to the c_state to response to
			  //  broadcast requests in this time.
			  else if (m_state_send_wr_br_counter > 31)     
				  begin
						m_state           <= `MESI_ISC_TB_CPU_M_STATE_IDLE;
						tb_ins_ack_o      <= 0;
						mbus_cmd_o        <= `MESI_ISC_MBUS_CMD_NOP;

				  end
			  else // Wait for ack
				  begin
						m_state           <= `MESI_ISC_TB_CPU_M_STATE_SEND_WR_BR;
				  end
			end
		`MESI_ISC_TB_CPU_M_STATE_SEND_RD_BR:
		//----------------------------------
			// Send the rd broadcast. After receiving acknowledge, send acknowledge to
			// main tb and go to the idle
			begin
					mbus_addr_o       <= m_addr;
					// Counts the number of cycle which m_state in this state
					m_state_send_rd_br_counter = m_state_send_rd_br_counter + 1; 
			  if (mbus_ack_i)
				  begin     
						m_state           <= `MESI_ISC_TB_CPU_M_STATE_IDLE;
						tb_ins_ack_o      <= 1; 
						mbus_cmd_o        <= `MESI_ISC_MBUS_CMD_NOP;
				  end
			  // To prevent a dead lock, after 31 cycles without an acknowledge, go to
			  // the IDLE state and try again. It enables to the c_state to response to
			  // broadcast requests in this time.
			  else if (m_state_send_rd_br_counter > 31)     
				  begin
						m_state           <= `MESI_ISC_TB_CPU_M_STATE_IDLE;
						tb_ins_ack_o      <= 0;
						mbus_cmd_o        <= `MESI_ISC_MBUS_CMD_NOP;

				  end
			  else // Wait for ack
					m_state           <= `MESI_ISC_TB_CPU_M_STATE_SEND_RD_BR;
			end
  endcase // case state


// c_state
// Coherence bus state machine
//================================  
//
//  -----------------------------------------
//  | -------                               |
//  | |     |                               |
//  -----> IDLE --------> WR_SNOOP ---------|
//          |             |                 |
//          |          ----                 |
//          |          |                    |
//          |          -> EVICT_INVALIDATE -|
//          |                               |
//          |-----------> RD_SNOOP ---------|
//          |             |                 |
//          |          ----                 |
//          |          |                    |
//          |          -> EVICT ------------|
//          |                               |
//          |-----------> RD_LINE_WR--------|
//          |             |                 |
//          |          ----                 |
//          |          |                    |
//          |          -> WR_CACHE  --------|
//          |                               |
//          |-----------> RD_LINE_RD--------|
//
always @(posedge clk or posedge rst)
  if (rst)
	  begin
				c_state           <= `MESI_ISC_TB_CPU_C_STATE_IDLE;
				cbus_ack_o        <= 0; 
	  end
  else case (c_state)

    `MESI_ISC_TB_CPU_C_STATE_IDLE:
    //----------------------------------
		begin
				c_addr            <= cbus_addr_i; // Store the address of cbus
		  // 1. CBUS and MBUS can't be active in the same time. When MBUS is
		  //    active - wait.
		  // 2. If priority is not of c_state - stay on IDLE
		  // 3. If cbus_ack_o is asserted the last action is nor finished yet - wait
		  //     for its finish
		  if (m_state !=`MESI_ISC_TB_CPU_M_STATE_IDLE | // 1
			  m_state_c_state_priority |                // 2
			  cbus_ack_o)                               // 3
			  begin
					c_state           <= `MESI_ISC_TB_CPU_C_STATE_IDLE;
					cbus_ack_o        <= 0;
			  end
		  // Start the action when instruction is received.
		  else
			  begin
					mbus_cmd_o        <= `MESI_ISC_MBUS_CMD_NOP;
					case (cbus_cmd_i)
					  `MESI_ISC_CBUS_CMD_NOP:
						  begin
							c_state           <= `MESI_ISC_TB_CPU_C_STATE_IDLE;
							cbus_ack_o        <= 0;
						  end
					  `MESI_ISC_CBUS_CMD_WR_SNOOP:
						  begin
							c_state           <= `MESI_ISC_TB_CPU_C_STATE_WR_SNOOP;
							cbus_ack_o        <= 0;
						  end
					  `MESI_ISC_CBUS_CMD_RD_SNOOP:
						  begin
							c_state           <= `MESI_ISC_TB_CPU_C_STATE_RD_SNOOP;
							cbus_ack_o        <= 0;
						  end
					  `MESI_ISC_CBUS_CMD_EN_WR:
						  begin
							c_state           <= `MESI_ISC_TB_CPU_C_STATE_RD_LINE_WR;
							cbus_ack_o        <= 0;
						  end
					  `MESI_ISC_CBUS_CMD_EN_RD:
						  begin
							  c_state           <= `MESI_ISC_TB_CPU_C_STATE_RD_LINE_RD;
							  cbus_ack_o        <= 0;
						  end
					  default: $display ("Error 1. Wrong value - CPU:%d, cbus_cmd_i = %h,time=%d\n",
										  cpu_id_i,
										  cbus_cmd_i,
										  $time);
					endcase // case (cbus_cmd_i)
			  end // else: !if(m_state !=`MESI_ISC_TB_CPU_M_STATE_IDLE |...
		end // case: `MESI_ISC_TB_CPU_C_STATE_IDLE

    `MESI_ISC_TB_CPU_C_STATE_WR_SNOOP:
    //----------------------------------
		  if (c_state[c_addr] == `MESI_ISC_TB_CPU_MESI_M)
				   c_state           <= `MESI_ISC_TB_CPU_C_STATE_EVICT_INVALIDATE;
		  else
			  begin // Invalidate the line, send ack and finish the current process
					cbus_ack_o        <= 1;
					c_state           <= `MESI_ISC_TB_CPU_C_STATE_IDLE;
					c_state[c_addr] <= `MESI_ISC_TB_CPU_MESI_I;           
					cache[c_addr]     <= 0;           
			  end

    `MESI_ISC_TB_CPU_C_STATE_RD_SNOOP:
    //----------------------------------
		  if (c_state[c_addr] == `MESI_ISC_TB_CPU_MESI_M)
				c_state           <= `MESI_ISC_TB_CPU_C_STATE_EVICT_INVALIDATE;
		  else if (c_state[c_addr] == `MESI_ISC_TB_CPU_MESI_E)
			  begin // Change state from E to S
					cbus_ack_o        <= 1;
					c_state           <= `MESI_ISC_TB_CPU_C_STATE_IDLE;
					c_state[c_addr] <= `MESI_ISC_TB_CPU_MESI_S;           
			  end
		  else
			  begin // Do nothing send ack and finish the current process
					cbus_ack_o        <= 1;
					c_state           <= `MESI_ISC_TB_CPU_C_STATE_IDLE;
			  end

    `MESI_ISC_TB_CPU_C_STATE_EVICT_INVALIDATE:
    //----------------------------------
			begin
			  // Debug start ---	 
			  `ifdef messages // ifdef
				$display("Message: check err 2. time:%d", $time);
			  `endif          // endif
			  // Only a line in a M state can be EVICT_INVALIDATE
			  if (c_state[c_addr] != `MESI_ISC_TB_CPU_MESI_M)
				  begin
					$display("Error 2. c_state[c_addr] is not M.\n",
							  "  CPU:%d,c_addr=%h,c_state[c_addr]=%h,time:%d",
							  cpu_id_i,
							  c_addr,
							  c_state[c_addr],
							  $time);
					@(negedge clk) $finish();
				  end
			 // Debug end ---	 
			  else         
			  // Write line to memory. After receiving acknowledge, invalidate the line,
			  // send acknowledge to main cbus and go to idle
				  begin
						mbus_cmd_o        <= `MESI_ISC_MBUS_CMD_WR;
						mbus_addr_o       <= c_addr;
						mbus_data_o       <= cache[c_addr];
					if (mbus_ack_i)     
						begin
							c_state[c_addr] <= `MESI_ISC_TB_CPU_MESI_I;           
							c_state           <= `MESI_ISC_TB_CPU_C_STATE_IDLE;
							cbus_ack_o        <= 1; 
							mbus_cmd_o        <= `MESI_ISC_MBUS_CMD_NOP;
						end
					end
			end // case: `MESI_ISC_TB_CPU_C_STATE_EVICT_INVALIDATE

    `MESI_ISC_TB_CPU_C_STATE_EVICT:
    //----------------------------------
		begin
			`ifdef messages
				  $display("Message: check err 3. time:%d",$time);
			`endif               
			  // Only a line in a S or E state can be EVICT_INVALIDATE
			  if  (~(c_state[c_addr] == `MESI_ISC_TB_CPU_MESI_S |
					 c_state[c_addr] == `MESI_ISC_TB_CPU_MESI_E))
				begin
				  $display("Error 3. c_state[c_addr] is not S or E.\n");
				  $display("  CPU:%d,c_addr=%h,c_state[c_addr]=%h,time=%d",
						   cpu_id_i,
						   c_addr,
						   c_state[c_addr],
						   $time);
				  @(negedge clk) $finish();
				end
			  else         
					// Write line to memory. After receiving acknowledge, change state to S,
					// send acknowledge to main cbus and go to idle
				  begin
						mbus_cmd_o        <= `MESI_ISC_MBUS_CMD_WR;
						mbus_addr_o       <= c_addr;
						mbus_data_o       <= cache[c_addr];
					if (mbus_ack_i)     
						begin
							c_state[c_addr] <= `MESI_ISC_TB_CPU_MESI_S;
							c_state           <= `MESI_ISC_TB_CPU_C_STATE_IDLE;
							cbus_ack_o        <= 1; 
						end
				  end // else: !if(~(c_state[c_addr] == `MESI_ISC_TB_CPU_`MESI_S |...
		end // case: `MESI_ISC_TB_CPU_C_STATE_EVICT

    `MESI_ISC_TB_CPU_C_STATE_RD_LINE_WR:
    //----------------------------------
    // Read a line from memory and then go to WR_CACHE
    // and write to the cache.
		 begin
				`ifdef messages
				  $display("Message: check er 4.time:%d",$time);
				`endif               
				if (wr_proc_wait_for_en != 1 |
						wr_proc_addr    != c_addr)
					  begin
						$display("Error 4. Write to cache without early broadcast.\n",
									 "  CPU:%d,wr_proc_wait_for_en=%h,wr_proc_addr=%h,c_addr=%h, time:%d",
								 cpu_id_i,
								 wr_proc_wait_for_en,
								 wr_proc_addr,
								 c_addr,
								 $time);
						@(negedge clk) $finish();
					  end
				mbus_cmd_o        <= `MESI_ISC_MBUS_CMD_RD;
				mbus_addr_o       <= c_addr;
				if (mbus_ack_i)     
					begin
						// A write data to a line contains the incremental data to the
						// related word of the data, depends on the cpu_id_i (word 0 for CPU
						// 0, etc.)
						cache[m_addr]       <= mbus_data_i;
						c_state[m_addr] <= `MESI_ISC_TB_CPU_MESI_S;
						c_state             <= `MESI_ISC_TB_CPU_C_STATE_WR_CACHE;
						mbus_cmd_o          <= `MESI_ISC_MBUS_CMD_NOP;
					end
		  end

    `MESI_ISC_TB_CPU_C_STATE_RD_LINE_RD:
    //----------------------------------
    // Read a line from memory and then go back to IDLE.
      begin
			`ifdef messages
				$display("Message: check err 5. time:%d",$time);
			`endif               
			// EN_RD means that the line is not valid in the cache
			if (rd_proc_wait_for_en != 1 |
				rd_proc_addr      != c_addr)
				begin
				  $display("Error 5. Read to cache without early broadcast.\n",
						"  CPU:%d,rd_proc_wait_for_en=%h,rd_proc_addr=%h,c_addr=%h,time:%d\n",
						  cpu_id_i,
						  rd_proc_wait_for_en,
						  rd_proc_addr,
						  c_addr,
						  $time);
				  @(negedge clk) $finish();
				end
			mbus_cmd_o        <= `MESI_ISC_MBUS_CMD_RD;
			mbus_addr_o       <= c_addr;
			if (mbus_ack_i)     
				begin
					mbus_cmd_o        <= `MESI_ISC_MBUS_CMD_NOP;
					cache[m_addr]     <= mbus_data_i;
					c_state[m_addr] <= `MESI_ISC_TB_CPU_MESI_S;
					c_state           <= `MESI_ISC_TB_CPU_C_STATE_IDLE;
					cbus_ack_o        <= 1; 
					rd_proc_wait_for_en <= 0;
					mbus_cmd_o          <= `MESI_ISC_MBUS_CMD_NOP;
				end 
      end 

    `MESI_ISC_TB_CPU_C_STATE_WR_CACHE:
    //----------------------------------
		begin
		  case (cpu_id_i)
				0: cache[m_addr][ 7 :0] <= wr_data[m_addr];
				1: cache[m_addr][15: 8] <= wr_data[m_addr];
				2: cache[m_addr][23:16] <= wr_data[m_addr];
				3: cache[m_addr][31:24] <= wr_data[m_addr];
		  endcase // case (cpu_id_i)
				wr_data[m_addr]   <= wr_data[m_addr] + 1; // Increment the wr data
				c_state           <= `MESI_ISC_TB_CPU_C_STATE_IDLE;
				mbus_cmd_o        <= `MESI_ISC_MBUS_CMD_NOP;
				c_state[m_addr] <= `MESI_ISC_TB_CPU_MESI_M;
				cbus_ack_o        <= 1; 
				wr_proc_wait_for_en <= 0;
		 end 
   endcase 

endmodule
