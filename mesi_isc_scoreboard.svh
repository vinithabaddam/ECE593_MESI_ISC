/********************************************************************************
*
* Authors: Vinitha Baddam, Monika Sinduja Mullapudi, Zerin Fatima
* Date: 5/31/2019
*
* Description:	Scoreboard uses self-checking mechanism to check if MESI coherency protocol is 
*		followed by 4 CPUs and the master. 
*
********************************************************************************/


import mesi_isc_pkg::*;	
`include "mesi_isc_pkg.sv"

class scoreboard;
	virtual mesi_isc_bfm bfm;

	function new (virtual mesi_isc_bfm b);
		bfm = b;
	endfunction : new

  	//score board execute task						
	task execute();
		input_port input_sb;	// declaring score board inputs using input struct
		output_port output_tb;	// declaring design outputs using output struct		
		forever begin : self_checker			
			input_sb = bfm.inport;							
			output_tb = bfm.outport;
			$display("scoreboard");
			@(posedge input_sb.mbus_cmd3_i or input_sb.mbus_cmd2_i or input_sb.mbus_cmd1_i  or input_sb.mbus_cmd0_i); 	
			//fork
				if((input_sb.mbus_cmd3_i != `MESI_ISC_MBUS_CMD_NOP) &&			// If master 3 is active and not NOP
				 (input_sb.mbus_cmd2_i == `MESI_ISC_MBUS_CMD_NOP) &&			// Call self-checker task for Master 3 
				 (input_sb.mbus_cmd1_i == `MESI_ISC_MBUS_CMD_NOP) &&
				 (input_sb.mbus_cmd0_i == `MESI_ISC_MBUS_CMD_NOP)) begin
					master3(input_sb, output_tb);
				end

				else if((input_sb.mbus_cmd2_i != `MESI_ISC_MBUS_CMD_NOP) &&		// If master 3 is active and not NOP
					  (input_sb.mbus_cmd3_i == `MESI_ISC_MBUS_CMD_NOP) &&		// Call self-checker task for Master 2
					  (input_sb.mbus_cmd1_i == `MESI_ISC_MBUS_CMD_NOP) &&
					  (input_sb.mbus_cmd0_i == `MESI_ISC_MBUS_CMD_NOP)) begin
					master2(input_sb, output_tb); 
				end

				else if((input_sb.mbus_cmd1_i != `MESI_ISC_MBUS_CMD_NOP) &&		// If master 3 is active and not NOP
					  (input_sb.mbus_cmd3_i == `MESI_ISC_MBUS_CMD_NOP) &&		// Call self-checker task for Master 1 
					  (input_sb.mbus_cmd2_i == `MESI_ISC_MBUS_CMD_NOP) &&
					  (input_sb.mbus_cmd0_i == `MESI_ISC_MBUS_CMD_NOP)) begin
					master1(input_sb, output_tb);
				end

				else if((input_sb.mbus_cmd0_i != `MESI_ISC_MBUS_CMD_NOP) &&		// If master 3 is active and not NOP
					  (input_sb.mbus_cmd3_i == `MESI_ISC_MBUS_CMD_NOP) &&		// Call self-checker task for Master 0
					  (input_sb.mbus_cmd2_i == `MESI_ISC_MBUS_CMD_NOP) &&
					  (input_sb.mbus_cmd1_i == `MESI_ISC_MBUS_CMD_NOP)) begin
					master0(input_sb, output_tb); 
				end
			//join_none
    		end : self_checker
	endtask : execute
    
/********************************** Task for Master 3 ******************************/        
    task master3(input_port inputs_tk, output_port outputs_tk); 		// Self checker task for Master 3
		output_port predicted;
		//forever begin: self_checker_master3
		@(posedge bfm.clk) 
		begin
			predicted.cbus_addr_o = inputs_tk.mbus_addr3_i;

			if(inputs_tk.mbus_cmd3_i == `MESI_ISC_MBUS_CMD_WR_BROAD)		// When write broadcast on Master 3
			begin
				predicted.cbus_cmd3_o = `MESI_ISC_CBUS_CMD_EN_WR;			// predicted CBUS cmd for Master 3 is write enable after snoop is complete
				predicted.cbus_cmd2_o = `MESI_ISC_CBUS_CMD_WR_SNOOP;			// predicted CBUS cmd for Master 2 is write snoop
				predicted.cbus_cmd1_o = `MESI_ISC_CBUS_CMD_WR_SNOOP;			// predicted CBUS cmd for Master 1 is write snoop
				predicted.cbus_cmd0_o = `MESI_ISC_CBUS_CMD_WR_SNOOP;			// predicted CBUS cmd for Master 0 is write snoop
			end
			else if (inputs_tk.mbus_cmd3_i == `MESI_ISC_MBUS_CMD_RD_BROAD)	// When read broadcast on Master 3
			begin
				predicted.cbus_cmd3_o = `MESI_ISC_CBUS_CMD_EN_RD;			// predicted CBUS cmd for Master 3 is read enable after snoop is complete
				predicted.cbus_cmd2_o = `MESI_ISC_CBUS_CMD_RD_SNOOP;			// predicted CBUS cmd for Master 2 is read snoop
				predicted.cbus_cmd1_o = `MESI_ISC_CBUS_CMD_RD_SNOOP;			// predicted CBUS cmd for Master 1 is read snoop
				predicted.cbus_cmd0_o = `MESI_ISC_CBUS_CMD_RD_SNOOP;			// predicted CBUS cmd for Master 0 is read snoop
			end
		end

		@(posedge bfm.clk);
		@(posedge bfm.clk);
		@(posedge bfm.clk) 
		begin
		if(predicted.cbus_addr_o != outputs_tk.cbus_addr_o)
			$error ("FAILED TO GET ADDRESS %0h FOR CBUS!", outputs_tk.cbus_addr_o);	// Compare predicted with actual
		end																			// throw error actual output for cbus cmd 
																					// for M3 is not write enable at this point
		@(posedge bfm.clk)
		begin
			if(inputs_tk.mbus_cmd3_i == `MESI_ISC_MBUS_CMD_WR_BROAD)			// if Master 3 is write broadcast
			begin
				if((predicted.cbus_cmd2_o != outputs_tk.cbus_cmd2_o) &&		// Compare predicted CBUS commands for other Masters
				 (predicted.cbus_cmd1_o != outputs_tk.cbus_cmd1_o) &&		// At this point all should be write snooping
				 (predicted.cbus_cmd0_o != outputs_tk.cbus_cmd0_o))			// throw error if not
					$error ("FAILED TO DO A WRITE SNOOP ON CBUS FOR M3 WRITE!");            
				end
			else if (inputs_tk.mbus_cmd3_i == `MESI_ISC_MBUS_CMD_RD_BROAD)	// if Master 3 is read broadcast
			begin
				if((predicted.cbus_cmd2_o != outputs_tk.cbus_cmd2_o) &&		// Compare predicted CBUS commands for other Masters
				 (predicted.cbus_cmd1_o != outputs_tk.cbus_cmd1_o) &&		// At this point all should be read snooping
				 (predicted.cbus_cmd0_o != outputs_tk.cbus_cmd0_o))			// throw error if not
					$error ("FAILED TO DO A READ SNOOP ON CBUS FOR M3 READ!");            
			end
		end

		@(negedge inputs_tk.cbus_ack2_i);		// upon negedge of CBUS ack of all other masters
		@(negedge inputs_tk.cbus_ack1_i);		
		@(negedge inputs_tk.cbus_ack0_i);
		begin
			if(inputs_tk.mbus_cmd3_i == `MESI_ISC_MBUS_CMD_WR_BROAD)		// If write broadcast
			begin
				if(predicted.cbus_cmd3_o != outputs_tk.cbus_cmd3_o)		// compare predicted cmd for M3
					$error ("FAILED TO DO ENABLE WRITE ON CBUS FOR M3!"); 	// error if write not enabled at this point
			end
			else if (inputs_tk.mbus_cmd3_i == `MESI_ISC_MBUS_CMD_RD_BROAD)// If read broadcast
			begin
				if(predicted.cbus_cmd3_o != outputs_tk.cbus_cmd3_o)		// compare predicted cmd for M3
					$error ("FAILED TO DO ENABLE READ ON CBUS FOR M3!");    // error if read not enabled at this point
			end
		end
		//end
    endtask: master3
 
/********************************** Task for Master 2 ******************************/       
     task master2(input_port inputs_tk, output_port outputs_tk);		// Self checker task for Master 2
		output_port predicted;
        	//forever begin: self_checker_master2
        	@(posedge bfm.clk) 
		begin
			predicted.cbus_addr_o = inputs_tk.mbus_addr2_i;
		  
			if(inputs_tk.mbus_cmd2_i == `MESI_ISC_MBUS_CMD_WR_BROAD)		// When write broadcast on Master 2
			  begin
			   predicted.cbus_cmd3_o = `MESI_ISC_CBUS_CMD_WR_SNOOP;			// predicted CBUS cmd for Master 3 is write snoop
			   predicted.cbus_cmd2_o = `MESI_ISC_CBUS_CMD_EN_WR;			// predicted CBUS cmd for Master 2 is write enable after snoop is complete
			   predicted.cbus_cmd1_o = `MESI_ISC_CBUS_CMD_WR_SNOOP;			// predicted CBUS cmd for Master 1 is write snoop
			   predicted.cbus_cmd0_o = `MESI_ISC_CBUS_CMD_WR_SNOOP;			// predicted CBUS cmd for Master 0 is write snoop
			  end
			else if (inputs_tk.mbus_cmd2_i == `MESI_ISC_MBUS_CMD_RD_BROAD)	// When read broadcast on Master 2
			  begin
			   predicted.cbus_cmd3_o = `MESI_ISC_CBUS_CMD_RD_SNOOP;			// predicted CBUS cmd for Master 3 is read snoop
			   predicted.cbus_cmd2_o = `MESI_ISC_CBUS_CMD_EN_RD;			// predicted CBUS cmd for Master 2 is read enable after snoop is complete
			   predicted.cbus_cmd1_o = `MESI_ISC_CBUS_CMD_RD_SNOOP;			// predicted CBUS cmd for Master 1 is read snoop
			   predicted.cbus_cmd0_o = `MESI_ISC_CBUS_CMD_RD_SNOOP;			// predicted CBUS cmd for Master 0 is read snoop
			  end
		end
		
		@(posedge bfm.clk);
		@(posedge bfm.clk);
		@(posedge bfm.clk) 
		begin
			if(predicted.cbus_addr_o != outputs_tk.cbus_addr_o)						
				$error ("FAILED TO GET ADDRESS %0h FOR CBUS!", outputs_tk.cbus_addr_o);	// Compare predicted with actual
		end																			// throw error actual output for cbus cmd 
																					// for M2 is not write enable at this point
		@(posedge bfm.clk)
		begin
			if(inputs_tk.mbus_cmd2_i == `MESI_ISC_MBUS_CMD_WR_BROAD)				// if Master 2 is write broadcast
			begin
				if((predicted.cbus_cmd3_o != outputs_tk.cbus_cmd3_o) &&			// Compare predicted CBUS commands for other Masters
				 (predicted.cbus_cmd1_o != outputs_tk.cbus_cmd1_o) &&			// At this point all should be write snooping
				 (predicted.cbus_cmd0_o != outputs_tk.cbus_cmd0_o))				// throw error if not
					$error ("FAILED TO DO A WRITE SNOOP ON CBUS FOR M2 WRITE!");            
			 end
			else if (inputs_tk.mbus_cmd2_i == `MESI_ISC_MBUS_CMD_RD_BROAD)		// if Master 2 is read broadcast
			begin	
				if((predicted.cbus_cmd3_o != outputs_tk.cbus_cmd3_o) &&			// Compare predicted CBUS commands for other Masters
				 (predicted.cbus_cmd1_o != outputs_tk.cbus_cmd1_o) &&			// At this point all should be read snooping
				 (predicted.cbus_cmd0_o != outputs_tk.cbus_cmd0_o))				// throw error if not
					$error ("FAILED TO DO A READ SNOOP ON CBUS FOR M2 READ!");            
			end
		end
	   
		@(negedge inputs_tk.cbus_ack2_i);		// upon negedge of CBUS ack of all other masters
		@(negedge inputs_tk.cbus_ack1_i);		
		@(negedge inputs_tk.cbus_ack0_i);
		begin
			if(inputs_tk.mbus_cmd2_i == `MESI_ISC_MBUS_CMD_WR_BROAD)			// If write broadcast
			begin
				if(predicted.cbus_cmd2_o != outputs_tk.cbus_cmd2_o)			// compare predicted cmd for M2
					$error ("FAILED TO DO ENABLE WRITE ON CBUS FOR M2!");       // error if write not enabled at this point
			 end
			else if (inputs_tk.mbus_cmd2_i == `MESI_ISC_MBUS_CMD_RD_BROAD)	// If read broadcast
			begin
				if(predicted.cbus_cmd2_o != outputs_tk.cbus_cmd2_o)			// compare predicted cmd for M2
					$error ("FAILED TO DO ENABLE READ ON CBUS FOR M2!");        // error if read not enabled at this point
			end
		end
		//end
     endtask: master2
        
/********************************** Task for Master 1 ******************************/         
    task master1(input_port inputs_tk, output_port outputs_tk);		// Self checker task for Master 1
		output_port predicted;
		//forever begin: self_checker_master1
		@(posedge bfm.clk) 
		begin
			predicted.cbus_addr_o = inputs_tk.mbus_addr1_i;
		  
			if(inputs_tk.mbus_cmd1_i == `MESI_ISC_MBUS_CMD_WR_BROAD)			// When write broadcast on Master 1
			begin
				predicted.cbus_cmd3_o = `MESI_ISC_CBUS_CMD_WR_SNOOP;			// predicted CBUS cmd for Master 3 is write snoop
				predicted.cbus_cmd2_o = `MESI_ISC_CBUS_CMD_WR_SNOOP;			// predicted CBUS cmd for Master 2 is write snoop
				predicted.cbus_cmd1_o = `MESI_ISC_CBUS_CMD_EN_WR;				// predicted CBUS cmd for Master 1 is write enable after snoop is complete
				predicted.cbus_cmd0_o = `MESI_ISC_CBUS_CMD_WR_SNOOP;			// predicted CBUS cmd for Master 0 is write snoop
			end
			else if (inputs_tk.mbus_cmd1_i == `MESI_ISC_MBUS_CMD_RD_BROAD)	// When read broadcast on Master 1
			begin
				predicted.cbus_cmd3_o = `MESI_ISC_CBUS_CMD_RD_SNOOP;			// predicted CBUS cmd for Master 3 is read snoop
				predicted.cbus_cmd2_o = `MESI_ISC_CBUS_CMD_RD_SNOOP;			// predicted CBUS cmd for Master 2 is read snoop
				predicted.cbus_cmd1_o = `MESI_ISC_CBUS_CMD_EN_RD;				// predicted CBUS cmd for Master 1 is read enable after snoop is complete
				predicted.cbus_cmd0_o = `MESI_ISC_CBUS_CMD_RD_SNOOP;			// predicted CBUS cmd for Master 0 is read snoop
			end
		end
		
		@(posedge bfm.clk);
		@(posedge bfm.clk);
		@(posedge bfm.clk) 
		begin
			if(predicted.cbus_addr_o != outputs_tk.cbus_addr_o)
				$error ("FAILED TO GET ADDRESS %0h FOR CBUS!", outputs_tk.cbus_addr_o);	// Compare predicted with actual
		end																			// throw error actual output for cbus cmd 
																					// for M1 is not write enable at this point
		@(posedge bfm.clk)
		begin
			if(inputs_tk.mbus_cmd1_i == `MESI_ISC_MBUS_CMD_WR_BROAD)			// if Master 1 is write broadcast
			begin
				if((predicted.cbus_cmd3_o != outputs_tk.cbus_cmd3_o) &&		// Compare predicted CBUS commands for other Masters
				 (predicted.cbus_cmd2_o != outputs_tk.cbus_cmd2_o) &&		// At this point all should be write snooping
				 (predicted.cbus_cmd0_o != outputs_tk.cbus_cmd0_o))			// throw error if not
					$error ("FAILED TO DO A WRITE SNOOP ON CBUS FOR M1 WRITE!");            
			end
			else if (inputs_tk.mbus_cmd1_i == `MESI_ISC_MBUS_CMD_RD_BROAD)	// if Master 1 is read broadcast
			begin
				if((predicted.cbus_cmd3_o != outputs_tk.cbus_cmd3_o) &&		// Compare predicted CBUS commands for other Masters
				 (predicted.cbus_cmd2_o != outputs_tk.cbus_cmd2_o) &&		// At this point all should be read snooping
				 (predicted.cbus_cmd0_o != outputs_tk.cbus_cmd0_o))			// throw error if not
					$error ("FAILED TO DO A READ SNOOP ON CBUS FOR M1 READ!");            
			end
		end

		@(negedge inputs_tk.cbus_ack2_i);		// upon negedge of CBUS ack of all other masters
		@(negedge inputs_tk.cbus_ack1_i);		
		@(negedge inputs_tk.cbus_ack0_i);
		begin
			if(inputs_tk.mbus_cmd1_i == `MESI_ISC_MBUS_CMD_WR_BROAD)		// If write broadcast
			begin
				if(predicted.cbus_cmd1_o != outputs_tk.cbus_cmd1_o)		// compare predicted cmd for M1
					$error ("FAILED TO DO ENABLE WRITE ON CBUS FOR M1!");  	// error if write not enabled at this point          
			end
			else if (inputs_tk.mbus_cmd1_i == `MESI_ISC_MBUS_CMD_RD_BROAD)// If read broadcast
			begin
				if(predicted.cbus_cmd1_o != outputs_tk.cbus_cmd1_o)		// compare predicted cmd for M1
					$error ("FAILED TO DO ENABLE READ ON CBUS FOR M1!");    // error if read not enabled at this point    
			end
		end
        	//end 
    endtask: master1
      
/********************************** Task for Master 0 ******************************/         
      task master0(input_port inputs_tk, output_port outputs_tk);		// Self checker task for Master 0
		output_port predicted;
        	//forever begin: self_checker_master0
        	@(posedge bfm.clk) 
		begin
			predicted.cbus_addr_o = inputs_tk.mbus_addr0_i;
		  
			if(inputs_tk.mbus_cmd0_i == `MESI_ISC_MBUS_CMD_WR_BROAD)		// When write broadcast on Master 0
			begin
				predicted.cbus_cmd3_o = `MESI_ISC_CBUS_CMD_WR_SNOOP;			// predicted CBUS cmd for Master 3 is write snoop
				predicted.cbus_cmd2_o = `MESI_ISC_CBUS_CMD_WR_SNOOP;			// predicted CBUS cmd for Master 2 is write snoop
				predicted.cbus_cmd1_o = `MESI_ISC_CBUS_CMD_WR_SNOOP;			// predicted CBUS cmd for Master 1 is write snoop
				predicted.cbus_cmd0_o = `MESI_ISC_CBUS_CMD_EN_WR;			// predicted CBUS cmd for Master 0 is write enable after snoop is complete
			end
			else if (inputs_tk.mbus_cmd0_i == `MESI_ISC_MBUS_CMD_RD_BROAD)	// When read broadcast on Master 0
			begin
				predicted.cbus_cmd3_o = `MESI_ISC_CBUS_CMD_RD_SNOOP;			// predicted CBUS cmd for Master 3 is read snoop
				predicted.cbus_cmd2_o = `MESI_ISC_CBUS_CMD_RD_SNOOP;			// predicted CBUS cmd for Master 2 is read snoop
				predicted.cbus_cmd1_o = `MESI_ISC_CBUS_CMD_RD_SNOOP;			// predicted CBUS cmd for Master 1 is read snoop
				predicted.cbus_cmd0_o = `MESI_ISC_CBUS_CMD_EN_RD;			// predicted CBUS cmd for Master 0 is read enable after snoop is complete
			end
		end
		
		@(posedge bfm.clk);
		@(posedge bfm.clk);
		@(posedge bfm.clk) 
		begin
			if(predicted.cbus_addr_o != outputs_tk.cbus_addr_o)
				$error ("FAILED TO GET ADDRESS %0h FOR CBUS!", outputs_tk.cbus_addr_o);	// Compare predicted with actual
		end																			// throw error actual output for cbus cmd 
																					// for M0 is not write enable at this point
		@(posedge bfm.clk)
		begin
			if(inputs_tk.mbus_cmd0_i == `MESI_ISC_MBUS_CMD_WR_BROAD)				// if Master 0 is write broadcast
			begin
				if((predicted.cbus_cmd3_o != outputs_tk.cbus_cmd3_o) &&			// Compare predicted CBUS commands for other Masters
				 (predicted.cbus_cmd2_o != outputs_tk.cbus_cmd2_o) &&			// At this point all should be write snooping
				 (predicted.cbus_cmd1_o != outputs_tk.cbus_cmd1_o))				// throw error if not
					$error ("FAILED TO DO A WRITE SNOOP ON CBUS FOR M0 WRITE!");            
				end
			else if (inputs_tk.mbus_cmd0_i == `MESI_ISC_MBUS_CMD_RD_BROAD)		// if Master 0 is read broadcast
			begin	
				if((predicted.cbus_cmd3_o != outputs_tk.cbus_cmd3_o) &&			// Compare predicted CBUS commands for other Masters
				 (predicted.cbus_cmd2_o != outputs_tk.cbus_cmd2_o) &&			// At this point all should be read snooping
				 (predicted.cbus_cmd1_o != outputs_tk.cbus_cmd1_o))				// throw error if not
					$error ("FAILED TO DO A READ SNOOP ON CBUS FOR M0 READ!");            
			end
		end
	   
		@(negedge inputs_tk.cbus_ack2_i);		// upon negedge of CBUS ack of all other masters
		@(negedge inputs_tk.cbus_ack1_i);		
		@(negedge inputs_tk.cbus_ack0_i);
		begin
			if(inputs_tk.mbus_cmd0_i == `MESI_ISC_MBUS_CMD_WR_BROAD)			// If write broadcast
			begin
				if(predicted.cbus_cmd0_o != outputs_tk.cbus_cmd0_o)			// compare predicted cmd for M2
					$error ("FAILED TO DO ENABLE WRITE ON CBUS FOR M0!");       // error if write not enabled at this point    
			end
			else if (inputs_tk.mbus_cmd0_i == `MESI_ISC_MBUS_CMD_RD_BROAD)	// If read broadcast
			begin
				if(predicted.cbus_cmd0_o != outputs_tk.cbus_cmd0_o)			// compare predicted cmd for M2
					$error ("FAILED TO DO ENABLE READ ON CBUS FOR M0!");        // error if read not enabled at this point  
			end
		end
		//end            
    endtask: master0
        
endclass: scoreboard