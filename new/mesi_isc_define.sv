/********************************************************************************
*
* Authors: Vinitha Baddam, Monika Sinduja Mullapudi, Zerin Fatima
* Date: 5/31/2019
*
* Description: This defines all parameters, 'defines to be used 
* throughout this project design 
*
********************************************************************************/



//////////////////////////////////////////////////////////////////////
////                                                              ////
////  MESI_ISC Project                                            ////
////                                                              ////
////  Author(s):                                                  ////
////      - Yair Amitay       yair.amitay@yahoo.com               ////
////                          www.linkedin.com/in/yairamitay      ////
////                                                              ////
////  Description                                                 ////
////  mesi_isc_define                                             ////
////  -------------------                                         ////
////  Contains the define declaration of the block		  ////
////                                                        	  ////
//////////////////////////////////////////////////////////////////////


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