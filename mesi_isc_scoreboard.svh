/********************************************************************************
*
* Authors: Vinitha Baddam, Monika Sinduja Mullapudi, Zerin Fatima
* Reference: https://github.com/PrakashLuu/mesi_verification
* Reference: https://github.com/shruti2611/EE382M_project/blob/master/mesi_fifo/mesi_isc_define.v
* Reference: https://github.com/rdsalemi/uvmprimer/tree/master/16_Analysis_Ports_In_the_Testbench
* Reference: https://opencores.org/projects/mesi_isc
* Last Modified: March 12, 2019
*
* Description:	Scoreboard uses self-checking mechanism to check if MESI coherency protocol is 
*				followed by 4 CPUs and the master. 

********************************************************************************/


import mesi_isc_pkg::*;	
`include "mesi_isc_pkg.sv"

class scoreboard;
	virtual mesi_isc_bfm bfm;

	function new (virtual mesi_isc_bfm b);
		bfm = b;
	endfunction : new
						// write method for the output struct 
	task execute();
	$display ("scoreboard\n");	
  
	$display("check");	
	$display("bfm.mbus_cmd_array:%p, bfm.mbus_addr_array:%p",bfm.mbus_cmd_array, bfm.mbus_addr_array);
		forever begin: self_checker	
		@(posedge bfm.clk)
    
		fork
			if((bfm.mbus_cmd_array[3] != `MESI_ISC_MBUS_CMD_NOP) &&			// If master 3 is active and not NOP
			 (bfm.mbus_cmd_array[2] == `MESI_ISC_MBUS_CMD_NOP) &&			// Call self-checker task for Master 3 
			 (bfm.mbus_cmd_array[1] == `MESI_ISC_MBUS_CMD_NOP) &&
			 (bfm.mbus_cmd_array[0] == `MESI_ISC_MBUS_CMD_NOP)) begin
				master3();
				$display("check_fork");
			end

			else if((bfm.mbus_cmd_array[2] != `MESI_ISC_MBUS_CMD_NOP) &&		// If master 3 is active and not NOP
				  (bfm.mbus_cmd_array[3] == `MESI_ISC_MBUS_CMD_NOP) &&		// Call self-checker task for Master 2
				  (bfm.mbus_cmd_array[1] == `MESI_ISC_MBUS_CMD_NOP) &&
				  (bfm.mbus_cmd_array[0] == `MESI_ISC_MBUS_CMD_NOP)) begin
				master2(); 
			end

			else if((bfm.mbus_cmd_array[1] != `MESI_ISC_MBUS_CMD_NOP) &&		// If master 3 is active and not NOP
				  (bfm.mbus_cmd_array[3] == `MESI_ISC_MBUS_CMD_NOP) &&		// Call self-checker task for Master 1 
				  (bfm.mbus_cmd_array[2] == `MESI_ISC_MBUS_CMD_NOP) &&
				  (bfm.mbus_cmd_array[0] == `MESI_ISC_MBUS_CMD_NOP)) begin
				master1();
			end

			else if((bfm.mbus_cmd_array[0] != `MESI_ISC_MBUS_CMD_NOP) &&		// If master 3 is active and not NOP
				  (bfm.mbus_cmd_array[3] == `MESI_ISC_MBUS_CMD_NOP) &&		// Call self-checker task for Master 0
				  (bfm.mbus_cmd_array[2] == `MESI_ISC_MBUS_CMD_NOP) &&
				  (bfm.mbus_cmd_array[1] == `MESI_ISC_MBUS_CMD_NOP)) begin
				master0(); 
			end
		join_none
    	end: self_checker
	endtask : execute
    
/********************************** Task for Master 3 ******************************/        
    task master3(); 		// Self checker task for Master 3
	
	logic   [ADDR_WIDTH-1:0] predicted_cbus_addr;
	logic   [CBUS_CMD_WIDTH-1:0] predicted_cbus_cmd3;
	logic   [CBUS_CMD_WIDTH-1:0] predicted_cbus_cmd2;
	logic   [CBUS_CMD_WIDTH-1:0] predicted_cbus_cmd1;
	logic   [CBUS_CMD_WIDTH-1:0] predicted_cbus_cmd0;
	$display ("master3\n");
		//forever begin: self_checker_master3
		@(posedge bfm.clk) 
		begin
			predicted_cbus_addr = bfm.mbus_addr_array[3];

			if(bfm.mbus_cmd_array[3] == `MESI_ISC_MBUS_CMD_WR_BROAD)		// When write broadcast on Master 3
			begin
				predicted_cbus_cmd3 = `MESI_ISC_CBUS_CMD_EN_WR;			// predicted CBUS cmd for Master 3 is write enable after snoop is complete
				predicted_cbus_cmd2 = `MESI_ISC_CBUS_CMD_WR_SNOOP;			// predicted CBUS cmd for Master 2 is write snoop
				predicted_cbus_cmd1 = `MESI_ISC_CBUS_CMD_WR_SNOOP;			// predicted CBUS cmd for Master 1 is write snoop
				predicted_cbus_cmd0 = `MESI_ISC_CBUS_CMD_WR_SNOOP;			// predicted CBUS cmd for Master 0 is write snoop
			end
			else if (bfm.mbus_cmd_array[3] == `MESI_ISC_MBUS_CMD_RD_BROAD)	// When read broadcast on Master 3
			begin
				predicted_cbus_cmd3 = `MESI_ISC_CBUS_CMD_EN_RD;			// predicted CBUS cmd for Master 3 is read enable after snoop is complete
				predicted_cbus_cmd2 = `MESI_ISC_CBUS_CMD_RD_SNOOP;			// predicted CBUS cmd for Master 2 is read snoop
				predicted_cbus_cmd1 = `MESI_ISC_CBUS_CMD_RD_SNOOP;			// predicted CBUS cmd for Master 1 is read snoop
				predicted_cbus_cmd0 = `MESI_ISC_CBUS_CMD_RD_SNOOP;			// predicted CBUS cmd for Master 0 is read snoop
			end
		end
																			// throw error actual output for cbus cmd 
																					// for M3 is not write enable at this point
		@(posedge bfm.clk)
		begin
			if(bfm.mbus_cmd_array[3] == `MESI_ISC_MBUS_CMD_WR_BROAD)			// if Master 3 is write broadcast
			begin
				if((predicted_cbus_cmd2 != bfm.cbus_cmd2) &&		// Compare predicted CBUS commands for other Masters
				 (predicted_cbus_cmd1 != bfm.cbus_cmd1) &&		// At this point all should be write snooping
				 (predicted_cbus_cmd0 != bfm.cbus_cmd0))			// throw error if not
					$error ("FAILED TO DO A WRITE SNOOP ON CBUS FOR M3 WRITE!");            
				end
			else if (bfm.mbus_cmd_array[3] == `MESI_ISC_MBUS_CMD_RD_BROAD)	// if Master 3 is read broadcast
			begin
				if((predicted_cbus_cmd2 != bfm.cbus_cmd2) &&		// Compare predicted CBUS commands for other Masters
				 (predicted_cbus_cmd1 != bfm.cbus_cmd1) &&		// At this point all should be read snooping
				 (predicted_cbus_cmd0 != bfm.cbus_cmd0))			// throw error if not
					$error ("FAILED TO DO A READ SNOOP ON CBUS FOR M3 READ!");            
			end
		end

		@(negedge bfm.cbus_ack2);		// upon negedge of CBUS ack of all other masters
		@(negedge bfm.cbus_ack1);		
		@(negedge bfm.cbus_ack0);
		begin
			if(bfm.mbus_cmd_array[3] == `MESI_ISC_MBUS_CMD_WR_BROAD)		// If write broadcast
			begin
				if(predicted_cbus_cmd3 != bfm.cbus_cmd3)		// compare predicted cmd for M3
					$error ("FAILED TO DO ENABLE WRITE ON CBUS FOR M3!"); 	// error if write not enabled at this point
			end
			else if (bfm.mbus_cmd_array[3] == `MESI_ISC_MBUS_CMD_RD_BROAD)// If read broadcast
			begin
				if(predicted_cbus_cmd3 != bfm.cbus_cmd3)		// compare predicted cmd for M3
					$error ("FAILED TO DO ENABLE READ ON CBUS FOR M3!");    // error if read not enabled at this point
			end
		end
		//end
    endtask: master3
 
/********************************** Task for Master 2 ******************************/       
     task master2();		// Self checker task for Master 2
	logic   [ADDR_WIDTH-1:0] predicted_cbus_addr;
	logic   [CBUS_CMD_WIDTH-1:0] predicted_cbus_cmd3;
	logic   [CBUS_CMD_WIDTH-1:0] predicted_cbus_cmd2;
	logic   [CBUS_CMD_WIDTH-1:0] predicted_cbus_cmd1;
	logic   [CBUS_CMD_WIDTH-1:0] predicted_cbus_cmd0;
	$display ("master2\n");
      //  forever begin: self_checker_master2
       @(posedge bfm.clk) 
		begin
			predicted_cbus_addr = bfm.mbus_addr_array[2];
		  
			if(bfm.mbus_cmd_array[2] == `MESI_ISC_MBUS_CMD_WR_BROAD)		// When write broadcast on Master 2
			  begin
			   predicted_cbus_cmd3 = `MESI_ISC_CBUS_CMD_WR_SNOOP;			// predicted CBUS cmd for Master 3 is write snoop
			   predicted_cbus_cmd2 = `MESI_ISC_CBUS_CMD_EN_WR;			// predicted CBUS cmd for Master 2 is write enable after snoop is complete
			   predicted_cbus_cmd1 = `MESI_ISC_CBUS_CMD_WR_SNOOP;			// predicted CBUS cmd for Master 1 is write snoop
			   predicted_cbus_cmd0 = `MESI_ISC_CBUS_CMD_WR_SNOOP;			// predicted CBUS cmd for Master 0 is write snoop
			  end
			else if (bfm.mbus_cmd_array[2] == `MESI_ISC_MBUS_CMD_RD_BROAD)	// When read broadcast on Master 2
			  begin
			    predicted_cbus_cmd3 = `MESI_ISC_CBUS_CMD_RD_SNOOP;			// predicted CBUS cmd for Master 3 is read snoop
			    predicted_cbus_cmd2 = `MESI_ISC_CBUS_CMD_EN_RD;			// predicted CBUS cmd for Master 2 is read enable after snoop is complete
			    predicted_cbus_cmd1 = `MESI_ISC_CBUS_CMD_RD_SNOOP;			// predicted CBUS cmd for Master 1 is read snoop
			    predicted_cbus_cmd0 = `MESI_ISC_CBUS_CMD_RD_SNOOP;			// predicted CBUS cmd for Master 0 is read snoop
			  end
		end
		
																				// throw error actual output for cbus cmd 
																					// for M2 is not write enable at this point
		@(posedge bfm.clk)
		begin
			if(bfm.mbus_cmd_array[2] == `MESI_ISC_MBUS_CMD_WR_BROAD)				// if Master 2 is write broadcast
			begin
				if((predicted_cbus_cmd3 != bfm.cbus_cmd3) &&			// Compare predicted CBUS commands for other Masters
				 (predicted_cbus_cmd1 != bfm.cbus_cmd1) &&			// At this point all should be write snooping
				 (predicted_cbus_cmd0 !=bfm.cbus_cmd0))				// throw error if not
					$error ("FAILED TO DO A WRITE SNOOP ON CBUS FOR M2 WRITE!");            
			 end
			else if (bfm.mbus_cmd_array[2] == `MESI_ISC_MBUS_CMD_RD_BROAD)		// if Master 2 is read broadcast
			begin	
				if((predicted_cbus_cmd3 != bfm.cbus_cmd3) &&			// Compare predicted CBUS commands for other Masters
				 (predicted_cbus_cmd1 != bfm.cbus_cmd1) &&			// At this point all should be read snooping
				 (predicted_cbus_cmd0 != bfm.cbus_cmd0))				// throw error if not
					$error ("FAILED TO DO A READ SNOOP ON CBUS FOR M2 READ!");            
			end
		end
	   
		@(negedge bfm.cbus_ack2);		// upon negedge of CBUS ack of all other masters
		@(negedge bfm.cbus_ack1);		
		@(negedge bfm.cbus_ack0);
		begin
			if(bfm.mbus_cmd_array[2] == `MESI_ISC_MBUS_CMD_WR_BROAD)			// If write broadcast
			begin
				if(predicted_cbus_cmd2 != bfm.cbus_cmd2)			// compare predicted cmd for M2
					$error ("FAILED TO DO ENABLE WRITE ON CBUS FOR M2!");       // error if write not enabled at this point
			 end
			else if (bfm.mbus_cmd_array[2] == `MESI_ISC_MBUS_CMD_RD_BROAD)	// If read broadcast
			begin
				if(predicted_cbus_cmd2 != bfm.cbus_cmd2)			// compare predicted cmd for M2
					$error ("FAILED TO DO ENABLE READ ON CBUS FOR M2!");        // error if read not enabled at this point
			end
		end
		//end
     endtask: master2
        
/********************************** Task for Master 1 ******************************/         
    task master1();		// Self checker task for Master 1
	logic   [ADDR_WIDTH-1:0] predicted_cbus_addr;
	logic   [CBUS_CMD_WIDTH-1:0] predicted_cbus_cmd3;
	logic   [CBUS_CMD_WIDTH-1:0] predicted_cbus_cmd2;
	logic   [CBUS_CMD_WIDTH-1:0] predicted_cbus_cmd1;
	logic   [CBUS_CMD_WIDTH-1:0] predicted_cbus_cmd0;
	$display ("master1\n");
		//forever begin: self_checker_master1
		@(posedge bfm.clk) 
		begin
			predicted_cbus_addr = bfm.mbus_addr_array[1];
		  
			if(bfm.mbus_cmd_array[1] == `MESI_ISC_MBUS_CMD_WR_BROAD)			// When write broadcast on Master 1
			begin
				predicted_cbus_cmd3 = `MESI_ISC_CBUS_CMD_WR_SNOOP;			// predicted CBUS cmd for Master 3 is write snoop
				predicted_cbus_cmd2 = `MESI_ISC_CBUS_CMD_WR_SNOOP;			// predicted CBUS cmd for Master 2 is write snoop
				predicted_cbus_cmd1 = `MESI_ISC_CBUS_CMD_EN_WR;				// predicted CBUS cmd for Master 1 is write enable after snoop is complete
				predicted_cbus_cmd0 = `MESI_ISC_CBUS_CMD_WR_SNOOP;			// predicted CBUS cmd for Master 0 is write snoop
			end
			else if (bfm.mbus_cmd_array[1] == `MESI_ISC_MBUS_CMD_RD_BROAD)	// When read broadcast on Master 1
			begin
				predicted_cbus_cmd3 = `MESI_ISC_CBUS_CMD_RD_SNOOP;			// predicted CBUS cmd for Master 3 is read snoop
				predicted_cbus_cmd2 = `MESI_ISC_CBUS_CMD_RD_SNOOP;			// predicted CBUS cmd for Master 2 is read snoop
				predicted_cbus_cmd1 = `MESI_ISC_CBUS_CMD_EN_RD;				// predicted CBUS cmd for Master 1 is read enable after snoop is complete
				predicted_cbus_cmd0 = `MESI_ISC_CBUS_CMD_RD_SNOOP;			// predicted CBUS cmd for Master 0 is read snoop
			end
		end
		
																			// for M1 is not write enable at this point
		@(posedge bfm.clk)
		begin
			if(bfm.mbus_cmd_array[1] == `MESI_ISC_MBUS_CMD_WR_BROAD)			// if Master 1 is write broadcast
			begin
				if((predicted_cbus_cmd3 !=  bfm.cbus_cmd3) &&		// Compare predicted CBUS commands for other Masters
				 (predicted_cbus_cmd2 !=  bfm.cbus_cmd2) &&		// At this point all should be write snooping
				 (predicted_cbus_cmd0 !=  bfm.cbus_cmd0))			// throw error if not
					$error ("FAILED TO DO A WRITE SNOOP ON CBUS FOR M1 WRITE!");            
			end
			else if (bfm.mbus_cmd_array[1] == `MESI_ISC_MBUS_CMD_RD_BROAD)	// if Master 1 is read broadcast
			begin
				if((predicted_cbus_cmd3 != bfm.cbus_cmd3) &&		// Compare predicted CBUS commands for other Masters
				 (predicted_cbus_cmd2 != bfm.cbus_cmd2) &&		// At this point all should be read snooping
				 (predicted_cbus_cmd0 != bfm.cbus_cmd0))			// throw error if not
					$error ("FAILED TO DO A READ SNOOP ON CBUS FOR M1 READ!");            
			end
		end

		@(negedge bfm.cbus_ack2);		// upon negedge of CBUS ack of all other masters
		@(negedge bfm.cbus_ack1);		
		@(negedge bfm.cbus_ack0);
		begin
			if(bfm.mbus_cmd_array[1] == `MESI_ISC_MBUS_CMD_WR_BROAD)		// If write broadcast
			begin
				if(predicted_cbus_cmd1 != bfm.cbus_cmd1)		// compare predicted cmd for M1
					$error ("FAILED TO DO ENABLE WRITE ON CBUS FOR M1!");  	// error if write not enabled at this point          
			end
			else if (bfm.mbus_cmd_array[1] == `MESI_ISC_MBUS_CMD_RD_BROAD)// If read broadcast
			begin
				if(predicted_cbus_cmd1 != bfm.cbus_cmd1)		// compare predicted cmd for M1
					$error ("FAILED TO DO ENABLE READ ON CBUS FOR M1!");    // error if read not enabled at this point    
			end
		end
      //  end 
    endtask: master1
      
/********************************** Task for Master 0 ******************************/         
      task master0();		// Self checker task for Master 0
	logic   [ADDR_WIDTH-1:0] predicted_cbus_addr;
	logic   [CBUS_CMD_WIDTH-1:0] predicted_cbus_cmd3;
	logic   [CBUS_CMD_WIDTH-1:0] predicted_cbus_cmd2;
	logic   [CBUS_CMD_WIDTH-1:0] predicted_cbus_cmd1;
	logic   [CBUS_CMD_WIDTH-1:0] predicted_cbus_cmd0;
	$display ("master0\n");

       // forever begin: self_checker_master0
        @(posedge bfm.clk) 
		begin
			predicted_cbus_addr = bfm.mbus_addr_array[0];
		  
			if(bfm.mbus_cmd_array[0] == `MESI_ISC_MBUS_CMD_WR_BROAD)		// When write broadcast on Master 0
			begin
				predicted_cbus_cmd3 = `MESI_ISC_CBUS_CMD_WR_SNOOP;			// predicted CBUS cmd for Master 3 is write snoop
				predicted_cbus_cmd2 = `MESI_ISC_CBUS_CMD_WR_SNOOP;			// predicted CBUS cmd for Master 2 is write snoop
				predicted_cbus_cmd1 = `MESI_ISC_CBUS_CMD_WR_SNOOP;			// predicted CBUS cmd for Master 1 is write snoop
				predicted_cbus_cmd0 = `MESI_ISC_CBUS_CMD_EN_WR;			// predicted CBUS cmd for Master 0 is write enable after snoop is complete
			end
			else if (bfm.mbus_cmd_array[0] == `MESI_ISC_MBUS_CMD_RD_BROAD)	// When read broadcast on Master 0
			begin
				predicted_cbus_cmd3 = `MESI_ISC_CBUS_CMD_RD_SNOOP;			// predicted CBUS cmd for Master 3 is read snoop
				predicted_cbus_cmd2 = `MESI_ISC_CBUS_CMD_RD_SNOOP;			// predicted CBUS cmd for Master 2 is read snoop
				predicted_cbus_cmd1 = `MESI_ISC_CBUS_CMD_RD_SNOOP;			// predicted CBUS cmd for Master 1 is read snoop
				predicted_cbus_cmd0 = `MESI_ISC_CBUS_CMD_EN_RD;			// predicted CBUS cmd for Master 0 is read enable after snoop is complete
			end
		end
		
																			// throw error actual output for cbus cmd 
																					// for M0 is not write enable at this point
		@(posedge bfm.clk)
		begin
			if(bfm.mbus_cmd_array[0] == `MESI_ISC_MBUS_CMD_WR_BROAD)				// if Master 0 is write broadcast
			begin
				if((predicted_cbus_cmd3 != bfm.cbus_cmd3) &&			// Compare predicted CBUS commands for other Masters
				 (predicted_cbus_cmd2 != bfm.cbus_cmd2) &&			// At this point all should be write snooping
				 (predicted_cbus_cmd1 != bfm.cbus_cmd1))				// throw error if not
					$error ("FAILED TO DO A WRITE SNOOP ON CBUS FOR M0 WRITE!");            
				end
			else if (bfm.mbus_cmd_array[0] == `MESI_ISC_MBUS_CMD_RD_BROAD)		// if Master 0 is read broadcast
			begin	
				if((predicted_cbus_cmd3 != bfm.cbus_cmd3) &&			// Compare predicted CBUS commands for other Masters
				 (predicted_cbus_cmd2 != bfm.cbus_cmd2) &&			// At this point all should be read snooping
				 (predicted_cbus_cmd1 != bfm.cbus_cmd1))				// throw error if not
					$error ("FAILED TO DO A READ SNOOP ON CBUS FOR M0 READ!");            
			end
		end
	   
		@(negedge bfm.cbus_ack2);		// upon negedge of CBUS ack of all other masters
		@(negedge bfm.cbus_ack1);		
		@(negedge bfm.cbus_ack0);
		begin
			if(bfm.mbus_cmd_array[0] == `MESI_ISC_MBUS_CMD_WR_BROAD)			// If write broadcast
			begin
				if(predicted_cbus_cmd0 != bfm.cbus_cmd0)			// compare predicted cmd for M2
					$error ("FAILED TO DO ENABLE WRITE ON CBUS FOR M0!");       // error if write not enabled at this point    
			end
			else if (bfm.mbus_cmd_array[0] == `MESI_ISC_MBUS_CMD_RD_BROAD)	// If read broadcast
			begin
				if(predicted_cbus_cmd0 == bfm.cbus_cmd0)			// compare predicted cmd for M2
					$error ("FAILED TO DO ENABLE READ ON CBUS FOR M0!");        // error if read not enabled at this point  
			end
		end
		//end            
    endtask: master0
        
endclass: scoreboard