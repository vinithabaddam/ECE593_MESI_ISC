// Instantiations
//================================
`timescale 1ns / 1ps
`include "mesi_isc_define.v"
`include "mesi_isc_tb_define.v"
`include "testbench.svh"

module top;
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

// mesi_isc
mesi_isc #(CBUS_CMD_WIDTH,
           ADDR_WIDTH,
           BROAD_TYPE_WIDTH,
           BROAD_ID_WIDTH,
           BROAD_REQ_FIFO_SIZE,
           BROAD_REQ_FIFO_SIZE_LOG2,
           MBUS_CMD_WIDTH,
           BREQ_FIFO_SIZE,
           BREQ_FIFO_SIZE_LOG2
          )
  mesi_isc
    (
     // Inputs
     .clk              (bfm.clk),
     .rst              (bfm.rst),
     .mbus_cmd3_i      (bfm.mbus_cmd_array[3]),
     .mbus_cmd2_i      (bfm.mbus_cmd_array[2]),
     .mbus_cmd1_i      (bfm.mbus_cmd_array[1]),
     .mbus_cmd0_i      (bfm.mbus_cmd_array[0]),
     .mbus_addr3_i     (bfm.mbus_addr_array[3]),
     .mbus_addr2_i     (bfm.mbus_addr_array[2]),
     .mbus_addr1_i     (bfm.mbus_addr_array[1]),
     .mbus_addr0_i     (bfm.mbus_addr_array[0]),
     .cbus_ack3_i      (bfm.cbus_ack3),
     .cbus_ack2_i      (bfm.cbus_ack2),
     .cbus_ack1_i      (bfm.cbus_ack1),
     .cbus_ack0_i      (bfm.cbus_ack0),
     // Outputs
     .cbus_addr_o      (bfm.cbus_addr),
     .cbus_cmd3_o      (bfm.cbus_cmd3),
     .cbus_cmd2_o      (bfm.cbus_cmd2),
     .cbus_cmd1_o      (bfm.cbus_cmd1),
     .cbus_cmd0_o      (bfm.cbus_cmd0),
     .mbus_ack3_o      (bfm.mbus_ack_mesi_isc[3]),
     .mbus_ack2_o      (bfm.mbus_ack_mesi_isc[2]),
     .mbus_ack1_o      (bfm.mbus_ack_mesi_isc[1]),
     .mbus_ack0_o      (bfm.mbus_ack_mesi_isc[0])
    );

// mesi_isc_tb_cpu3
mesi_isc_tb_cpu  #(
       CBUS_CMD_WIDTH,
       ADDR_WIDTH,
       DATA_WIDTH,
       BROAD_TYPE_WIDTH,
       BROAD_ID_WIDTH,
       BROAD_REQ_FIFO_SIZE,
       BROAD_REQ_FIFO_SIZE_LOG2,
       MBUS_CMD_WIDTH,
       BREQ_FIFO_SIZE,
       BREQ_FIFO_SIZE_LOG2
      )
   //         \ /
   mesi_isc_tb_cpu3
    (
     // Inputs
     .clk              (bfm.clk),
     .rst              (bfm.rst),
     .cbus_addr_i      (bfm.cbus_addr),
     //                        \ /
     .cbus_cmd_i       (bfm.cbus_cmd3),
     //                             \ /
     .mbus_data_i      (bfm.mbus_data_rd),
     //                        \ /
     .mbus_ack_i       (bfm.mbus_ack[3]),
     //                   \ /
     .cpu_id_i         (2'd3),
     //                      \ /
     .tb_ins_i         (bfm.tb_ins_array[3]),
     //                           \ /
     .tb_ins_addr_i    (bfm.tb_ins_addr3),
     // Outputs                \ /
     .mbus_cmd_o       (bfm.mbus_cmd_array[3]),
      //                        \ /
     .mbus_addr_o      (bfm.mbus_addr_array[3]),
      //                        \ /
     .mbus_data_o      (bfm.mbus_data_wr_array[3]),
     //                        \ /
     .cbus_ack_o       (bfm.cbus_ack3),
     //                          \ /
     .tb_ins_ack_o     (bfm.tb_ins_ack[3])
 );


// mesi_isc_tb_cpu2
mesi_isc_tb_cpu  #(
       CBUS_CMD_WIDTH,
       ADDR_WIDTH,
       DATA_WIDTH,
       BROAD_TYPE_WIDTH,
       BROAD_ID_WIDTH,
       BROAD_REQ_FIFO_SIZE,
       BROAD_REQ_FIFO_SIZE_LOG2,
       MBUS_CMD_WIDTH,
       BREQ_FIFO_SIZE,
       BREQ_FIFO_SIZE_LOG2
      )
   //         \ /
   mesi_isc_tb_cpu2
    (
     // Inputs
     .clk              (bfm.clk),
     .rst              (bfm.rst),
     .cbus_addr_i      (bfm.cbus_addr),
     //                        \ /
     .cbus_cmd_i       (bfm.cbus_cmd2),
     //                             \ /
     .mbus_data_i      (bfm.mbus_data_rd),
     //                        \ /
     .mbus_ack_i       (bfm.mbus_ack[2]),
     //                   \ /
     .cpu_id_i         (2'd2),
     //                      \ /
     .tb_ins_i         (bfm.tb_ins_array[2]),
     //                           \ /
     .tb_ins_addr_i    (bfm.tb_ins_addr2),
     // Outputs                \ /
     .mbus_cmd_o       (bfm.mbus_cmd_array[2]),
      //                        \ /
     .mbus_addr_o      (bfm.mbus_addr_array[2]),
      //                        \ /
     .mbus_data_o      (bfm.mbus_data_wr_array[2]),
     //                        \ /
     .cbus_ack_o       (bfm.cbus_ack2),
     //                          \ /
     .tb_ins_ack_o     (bfm.tb_ins_ack[2])
 );

// mesi_isc_tb_cpu1
mesi_isc_tb_cpu  #(
       CBUS_CMD_WIDTH,
       ADDR_WIDTH,
       DATA_WIDTH,
       BROAD_TYPE_WIDTH,
       BROAD_ID_WIDTH,
       BROAD_REQ_FIFO_SIZE,
       BROAD_REQ_FIFO_SIZE_LOG2,
       MBUS_CMD_WIDTH,
       BREQ_FIFO_SIZE,
       BREQ_FIFO_SIZE_LOG2
      )
   //         \ /
   mesi_isc_tb_cpu1
    (
     // Inputs
     .clk              (bfm.clk),
     .rst              (bfm.rst),
     .cbus_addr_i      (bfm.cbus_addr),
     //                        \ /
     .cbus_cmd_i       (bfm.cbus_cmd1),
     //                             \ /
     .mbus_data_i      (bfm.mbus_data_rd),
     //                        \ /
     .mbus_ack_i       (bfm.mbus_ack[1]),
     //                   \ /
     .cpu_id_i         (2'd1),
     //                      \ /
     .tb_ins_i         (bfm.tb_ins_array[1]),
     //                           \ /
     .tb_ins_addr_i    (bfm.tb_ins_addr1),
     // Outputs                \ /
     .mbus_cmd_o       (bfm.mbus_cmd_array[1]),
      //                        \ /
     .mbus_addr_o      (bfm.mbus_addr_array[1]),
      //                        \ /
     .mbus_data_o      (bfm.mbus_data_wr_array[1]),
     //                        \ /
     .cbus_ack_o       (bfm.cbus_ack1),
     //                          \ /
     .tb_ins_ack_o     (bfm.tb_ins_ack[1])
 );

// mesi_isc_tb_cpu0
mesi_isc_tb_cpu  #(
       CBUS_CMD_WIDTH,
       ADDR_WIDTH,
       DATA_WIDTH,
       BROAD_TYPE_WIDTH,
       BROAD_ID_WIDTH,
       BROAD_REQ_FIFO_SIZE,
       BROAD_REQ_FIFO_SIZE_LOG2,
       MBUS_CMD_WIDTH,
       BREQ_FIFO_SIZE,
       BREQ_FIFO_SIZE_LOG2
      )
   //         \ /
   mesi_isc_tb_cpu0
    (
     // Inputs
     .clk              (bfm.clk),
     .rst              (bfm.rst),
     .cbus_addr_i      (bfm.cbus_addr),
     //                        \ /
     .cbus_cmd_i       (bfm.cbus_cmd0),
     //                             \ /
     .mbus_data_i      (bfm.mbus_data_rd),
     //                        \ /
     .mbus_ack_i       (bfm.mbus_ack[0]),
     //                   \ /
     .cpu_id_i         (2'd0),
     //                      \ /
     .tb_ins_i         (bfm.tb_ins_array[0]),
     //                           \ /
     .tb_ins_addr_i    (bfm.tb_ins_addr0),
     // Outputs                \ /
     .mbus_cmd_o       (bfm.mbus_cmd_array[0]),
      //                        \ /
     .mbus_addr_o      (bfm.mbus_addr_array[0]),
      //                        \ /
     .mbus_data_o      (bfm.mbus_data_wr_array[0]),
     //                        \ /
     .cbus_ack_o       (bfm.cbus_ack0),
     //                           \ /
     .tb_ins_ack_o     (bfm.tb_ins_ack[0])
 );

mesi_isc_bfm_mod  bfm();
	testbench    testbench_h;
	
	initial begin
		testbench_h = new(bfm);
		testbench_h.execute();
	end

endmodule : top
