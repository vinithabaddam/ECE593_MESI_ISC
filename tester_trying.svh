`timescale 1ns / 1ps
`include "mesi_isc_define.v"
`include "mesi_isc_tb_define.v"


class tester; 
	virtual mesi_isc_bfm_mod bfm;

	function new (virtual mesi_isc_bfm_mod b);
		bfm = b;
	endfunction : new	

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


reg    [1:0]            cpu_priority;
reg    [3:0]            cpu_selected;   
reg                     mem_access;

integer                 stimulus_rand_numb [9:0];
integer                 seed;
reg    [1:0]            stimulus_rand_cpu_select;
reg    [1:0]            stimulus_op;
reg    [7:0]            stimulus_addr;
reg    [7:0]            stimulus_nop_period;
integer                 cur_stimulus_cpu;
integer                 i, j, k, l, m, n, p;
reg [31:0]              stat_cpu_access_nop [3:0];
reg [31:0]              stat_cpu_access_rd  [3:0];
reg [31:0]              stat_cpu_access_wr  [3:0];

//always @(posedge bfm.clk or posedge bfm.rst)
function void gen_stimulus();
  if (bfm.rst)
  begin
   bfm.tb_ins_array[3]      = `MESI_ISC_TB_INS_NOP;
   bfm.tb_ins_array[2]      = `MESI_ISC_TB_INS_NOP;
   bfm.tb_ins_array[1]      = `MESI_ISC_TB_INS_NOP;
   bfm.tb_ins_array[0]      = `MESI_ISC_TB_INS_NOP;
   bfm.tb_ins_addr_array[3] = 0;
   bfm.tb_ins_addr_array[2] = 0;
   bfm.tb_ins_addr_array[1] = 0;
   bfm.tb_ins_addr_array[0] = 0;
   bfm.tb_ins_nop_period[3] = 0;
   bfm.tb_ins_nop_period[2] = 0;
   bfm.tb_ins_nop_period[1] = 0;
   bfm.tb_ins_nop_period[0] = 0;
  end
  else
  begin
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
      // This CPU is in NOP period
      // ----------------------------
      if(bfm.tb_ins_nop_period[cur_stimulus_cpu] > 0) 
      begin
        bfm.tb_ins_array[cur_stimulus_cpu] = `MESI_ISC_TB_INS_NOP;
        // Decrease the counter by 1. When the counter value is 0 the NOP period
        // is finished
        bfm.tb_ins_nop_period[cur_stimulus_cpu] =
                                    bfm.tb_ins_nop_period[cur_stimulus_cpu] - 1;
      end
      // The CPU is return acknowledge for the last action. Change the 
      // instruction back to nop.
      // ----------------------------
     else if (bfm.tb_ins_ack[cur_stimulus_cpu])
        bfm.tb_ins_array[cur_stimulus_cpu] = `MESI_ISC_TB_INS_NOP;        
      // Generate the next instruction for the CPU 
      // ----------------------------
      else if(bfm.tb_ins_array[cur_stimulus_cpu] == `MESI_ISC_TB_INS_NOP)
      begin
        // Decide the next operation - nop (0), wr (1), or rd (2)
        stimulus_op         = $unsigned(stimulus_rand_numb[1+l]) % 20 ;
        // Ratio: 1 - nop     1 - wr 5 - rd
        if (stimulus_op > 1) stimulus_op = 2;
        // Decide the next address operation 1 to 5
        stimulus_addr       = ($unsigned(stimulus_rand_numb[5+l]) % 5) + 1 ;  
        // Decide the next  operation 1 to 10
        stimulus_nop_period = ($unsigned(stimulus_rand_numb[9]) % 10) + 1 ;  
        // Next op is nop. Set the value of the counter
        if (stimulus_op == 0)
          bfm.tb_ins_nop_period[cur_stimulus_cpu] = stimulus_nop_period;
        else
        begin
          bfm.tb_ins_array[cur_stimulus_cpu] = stimulus_op; // 1 for wr, 2 for rd
          bfm.tb_ins_addr_array[cur_stimulus_cpu] = stimulus_addr;          
        end
      end // if (tb_ins_array[cur_stimulus_cpu] == `MESI_ISC_TB_INS_NOP)
    end // for (l = 0; l < 4; l = l + 1)
     
  end // else: !
endfunction

// Memory and matrix
//================================
//always @(posedge bfm.clk or posedge bfm.rst)
function void gen_stimulus_matrix();
  if (bfm.rst)
  begin
                     cpu_priority    = 0;
                     cpu_selected    = 0;
  end
  else
  begin
                     bfm.mbus_ack_memory = 0;
                     mem_access      = 0;
		    
    for (i = 0; i < 4; i = i + 1)
       if ((bfm.mbus_cmd_array[cpu_priority+i] == `MESI_ISC_MBUS_CMD_WR |
            bfm.mbus_cmd_array[cpu_priority+i] == `MESI_ISC_MBUS_CMD_RD  ) &
            !mem_access)
    begin
                     mem_access      = 1;
			
                     cpu_selected    = cpu_priority+i;
                     bfm.mbus_ack_memory[cpu_priority+i] = 1;
      if (bfm.mbus_cmd_array[cpu_priority+i] == `MESI_ISC_MBUS_CMD_WR)
      // WR
      begin
                  /*   sanity_check_rule1_rule2(cpu_selected,
                                            mbus_addr_array[cpu_priority+i],
                                            mbus_data_wr_array[cpu_priority+i]);*/
                     bfm.mem[bfm.mbus_addr_array[cpu_priority+i]] =
                                           bfm.mbus_data_wr_array[cpu_priority+i];
      end
      // RD
      else
                     bfm.mbus_data_rd =        bfm.mem[bfm.mbus_addr_array[cpu_priority+i]];
    end
  end
// assign_mbus_ack();
 endfunction
 
function void assign_mbus_ack();
		bfm.mbus_ack[3:0] = bfm.mbus_ack_memory[3:0] | bfm.mbus_ack_mesi_isc[3:0];
	endfunction: assign_mbus_ack

task execute();
//repeat (20000) @(posedge bfm.clk or posedge bfm.rst)
repeat (20000) @(negedge bfm.clk) begin:random_loop
	gen_stimulus;			   	//generates stimulus and ssigns it to the structure 
	gen_stimulus_matrix;	
	assign_mbus_ack();
end : random_loop

endtask : execute

endclass: tester
