/********************************************************************************
*
* Authors: Vinitha Baddam, Monika Sinduja Mullapudi, Zerin Fatima
* Date: 5/31/2019
*
* Description: This package defines all parameters, 'defines, structure to be used throughout this project
*
********************************************************************************/

package mesi_isc_pkg;
 
	 //parameters 
	parameter	CBUS_CMD_WIDTH           = 3;
	parameter	ADDR_WIDTH               = 32;
	parameter	DATA_WIDTH               = 32;
	parameter	BROAD_TYPE_WIDTH         = 2;  
	parameter	BROAD_ID_WIDTH           = 5; 
	parameter 	BROAD_REQ_FIFO_SIZE      = 4;
	parameter	BROAD_REQ_FIFO_SIZE_LOG2 = 2;
	parameter	MBUS_CMD_WIDTH           = 3;
	parameter	BREQ_FIFO_SIZE           = 2;
	parameter	BREQ_FIFO_SIZE_LOG2      = 1;

	// CPU instructions
	`define MESI_ISC_TB_INS_NOP 4'd0
	`define MESI_ISC_TB_INS_WR  4'd1
	`define MESI_ISC_TB_INS_RD  4'd2

	`define MESI_ISC_TB_CPU_M_STATE_IDLE        0
	`define MESI_ISC_TB_CPU_M_STATE_WR_CACHE    1
	`define MESI_ISC_TB_CPU_M_STATE_RD_CACHE    2
	`define MESI_ISC_TB_CPU_M_STATE_SEND_WR_BR  3
	`define MESI_ISC_TB_CPU_M_STATE_SEND_RD_BR  4
	
	`define MESI_ISC_TB_CPU_C_STATE_IDLE        0
	`define MESI_ISC_TB_CPU_C_STATE_WR_SNOOP    1
	`define MESI_ISC_TB_CPU_C_STATE_RD_SNOOP    2
	`define MESI_ISC_TB_CPU_C_STATE_EVICT_INVALIDATE 3
	`define MESI_ISC_TB_CPU_C_STATE_EVICT       4
	`define MESI_ISC_TB_CPU_C_STATE_RD_LINE_WR  5
	`define MESI_ISC_TB_CPU_C_STATE_RD_LINE_RD  6
	`define MESI_ISC_TB_CPU_C_STATE_RD_CACHE    7
	`define MESI_ISC_TB_CPU_C_STATE_WR_CACHE    8


	`define MESI_ISC_TB_CPU_MESI_M              4'b1001
	`define MESI_ISC_TB_CPU_MESI_E              4'b0101
	`define MESI_ISC_TB_CPU_MESI_S              4'b0011
	`define MESI_ISC_TB_CPU_MESI_I              4'b0000
	
	//`defines of the design  
	// Main Bus commands
	`define MESI_ISC_MBUS_CMD_NOP      3'd0
	`define MESI_ISC_MBUS_CMD_WR       3'd1
	`define MESI_ISC_MBUS_CMD_RD       3'd2
	`define MESI_ISC_MBUS_CMD_WR_BROAD 3'd3
	`define MESI_ISC_MBUS_CMD_RD_BROAD 3'd4

	// Coherence Bus commands
	`define MESI_ISC_CBUS_CMD_NOP      3'd0
	`define MESI_ISC_CBUS_CMD_WR_SNOOP 3'd1
	`define MESI_ISC_CBUS_CMD_RD_SNOOP 3'd2
	`define MESI_ISC_CBUS_CMD_EN_WR    3'd3
	`define MESI_ISC_CBUS_CMD_EN_RD    3'd4
	  
	// BREQ_TYPE  
	`define MESI_ISC_BREQ_TYPE_NOP 2'd0
	`define MESI_ISC_BREQ_TYPE_WR  2'd1
	`define MESI_ISC_BREQ_TYPE_RD  2'd2

	logic [3:0] tb_ins_array_pkg [3:0];
	logic [3:0] tb_ins_ack_pkg;
	
  
	typedef struct{
				//INTERNAL VARIABLES 
				//connected to input of cpu 
				logic   [DATA_WIDTH-1:0] mbus_data_rd;  	// Main bus data read
				logic   [3:0]            mbus_ack;  	 	// Main bus3 acknowledge
				integer			 cpu_id; 
				logic   [3:0]            tb_ins_array;
				logic   [3:0]            tb_ins_addr_array;
				bit 					 reset; 
				} cpu_input; 	//used by the tester to pass it to bfm 
				
	typedef struct{	// inputs
				logic [MBUS_CMD_WIDTH-1:0]	mbus_cmd3_i;
				logic [MBUS_CMD_WIDTH-1:0] 	mbus_cmd2_i;
				logic [MBUS_CMD_WIDTH-1:0] 	mbus_cmd1_i;
				logic [MBUS_CMD_WIDTH-1:0] 	mbus_cmd0_i;
				logic [ADDR_WIDTH-1:0] 		mbus_addr3_i;
				logic [ADDR_WIDTH-1:0] 		mbus_addr2_i;
				logic [ADDR_WIDTH-1:0] 		mbus_addr1_i;
				logic [ADDR_WIDTH-1:0] 		mbus_addr0_i;
				logic 				cbus_ack3_i;
				logic 				cbus_ack2_i;
				logic 				cbus_ack1_i;
				logic 				cbus_ack0_i;
      				} input_port;
				  
	typedef struct{ // outputs
				logic [ADDR_WIDTH-1:0] 		cbus_addr_o;
				logic [CBUS_CMD_WIDTH-1:0] 	cbus_cmd3_o;
				logic [CBUS_CMD_WIDTH-1:0] 	cbus_cmd2_o;
				logic [CBUS_CMD_WIDTH-1:0] 	cbus_cmd1_o;
				logic [CBUS_CMD_WIDTH-1:0] 	cbus_cmd0_o;
				logic 				mbus_ack3_o;
				logic 				mbus_ack2_o;
				logic 				mbus_ack1_o;
				logic 				mbus_ack0_o;
				} output_port;

/*
`include "mesi_isc_coverage.svh"
`include "mesi_isc_tester.svh"
`inlcude "mesi_isc_scoreboard.svh"
*/

endpackage : mesi_isc_pkg