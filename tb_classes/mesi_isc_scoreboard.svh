/********************************************************************************
*
* Authors: Srijana Sapkota and Zeba Khan Rafi
* Reference: https://github.com/PrakashLuu/mesi_verification
* Reference: https://github.com/shruti2611/EE382M_project/blob/master/mesi_fifo/mesi_isc_define.v
* Reference: https://github.com/rdsalemi/uvmprimer/tree/master/16_Analysis_Ports_In_the_Testbench
* Reference: https://opencores.org/projects/mesi_isc
* Last Modified: March 12, 2019
*
* Description:	Scoreboard uses self-checking mechanism to check if MESI coherency protocol is 
*				followed by 4 CPUs and the master. 
*				Inputs: From Command monitor thorugh the FIFO
*				Outputs: From Result Monitor through the Analysis port
********************************Change Log******************************************************* 
* Srijana S. and Zeba K. R.			3/12/2019			Created
********************************************************************************/


import mesi_isc_pkg::*;	
import uvm_pkg::*;
`include "uvm_macros.svh"
`include "mesi_isc_pkg.sv"

class scoreboard extends uvm_subscriber #(tired);		// extending output struct called tired
	`uvm_component_utils(scoreboard);
	
virtual mesi_isc_bfm bfm;
uvm_tlm_analysis_fifo #(input_ports) command_fifo;		//fifo for pulling input information

function new (string name, uvm_component parent);
	super.new(name, parent);
endfunction: new

function void build_phase(uvm_phase phase);				// accepts input struct and sends commands
	command_fifo = new("command_fifo", this);			// into the testbench
endfunction: build_phase

  function void write(tired t);							// write method for the output struct 
    input_ports inputs_sb;								// declaring inputs using input struct
    
    do
	if (!command_fifo.try_get(inputs_sb))				// try_get reads commands out of the FIFO
		$fatal(1, "Missing Some Input");				// throw a fatal exception if the try_get
    while((((inputs_sb.mbus_cmd3_i)||					// method returns an empty FIFO
           	(inputs_sb.mbus_cmd2_i)||
            (inputs_sb.mbus_cmd1_i)||
            (inputs_sb.mbus_cmd0_i))==`MESI_ISC_MBUS_CMD_NOP)||	// for when cmd maybe NOP
          (((inputs_sb.mbus_cmd3_i)||
            (inputs_sb.mbus_cmd2_i)||
            (inputs_sb.mbus_cmd1_i)||
            (inputs_sb.mbus_cmd0_i))==`MESI_ISC_MBUS_CMD_WR_BROAD)||	// when cmd maybe write broadcast
          (((inputs_sb.mbus_cmd3_i)||
            (inputs_sb.mbus_cmd2_i)||
            (inputs_sb.mbus_cmd1_i)||
            (inputs_sb.mbus_cmd0_i))==`MESI_ISC_MBUS_CMD_RD_BROAD)|| 	// when cmd maybe read broadcast
		  (((inputs_sb.mbus_cmd3_i)||
            (inputs_sb.mbus_cmd2_i)||
            (inputs_sb.mbus_cmd1_i)||
            (inputs_sb.mbus_cmd0_i))==`MESI_ISC_MBUS_CMD_WR)||			// when cmd maybe write
		  (((inputs_sb.mbus_cmd3_i)||
            (inputs_sb.mbus_cmd2_i)||
            (inputs_sb.mbus_cmd1_i)||
            (inputs_sb.mbus_cmd0_i))==`MESI_ISC_MBUS_CMD_WR));			// when cmd maybe read 
			
			
			
    
    fork
      if((inputs_sb.mbus_cmd3_i != `MESI_ISC_MBUS_CMD_NOP) &&			// If master 3 is active and not NOP
         (inputs_sb.mbus_cmd2_i == `MESI_ISC_MBUS_CMD_NOP) &&			// Call self-checker task for Master 3 
         (inputs_sb.mbus_cmd1_i == `MESI_ISC_MBUS_CMD_NOP) &&
         (inputs_sb.mbus_cmd0_i == `MESI_ISC_MBUS_CMD_NOP)) begin
        master3(inputs_sb, t); end
      
      else if((inputs_sb.mbus_cmd2_i != `MESI_ISC_MBUS_CMD_NOP) &&		// If master 3 is active and not NOP
              (inputs_sb.mbus_cmd3_i == `MESI_ISC_MBUS_CMD_NOP) &&		// Call self-checker task for Master 2
              (inputs_sb.mbus_cmd1_i == `MESI_ISC_MBUS_CMD_NOP) &&
              (inputs_sb.mbus_cmd0_i == `MESI_ISC_MBUS_CMD_NOP)) begin
        master2(inputs_sb, t); end
      
      else if((inputs_sb.mbus_cmd1_i != `MESI_ISC_MBUS_CMD_NOP) &&		// If master 3 is active and not NOP
              (inputs_sb.mbus_cmd3_i == `MESI_ISC_MBUS_CMD_NOP) &&		// Call self-checker task for Master 1 
              (inputs_sb.mbus_cmd2_i == `MESI_ISC_MBUS_CMD_NOP) &&
              (inputs_sb.mbus_cmd0_i == `MESI_ISC_MBUS_CMD_NOP)) begin
        master1(inputs_sb, t); end
      
      else if((inputs_sb.mbus_cmd0_i != `MESI_ISC_MBUS_CMD_NOP) &&		// If master 3 is active and not NOP
              (inputs_sb.mbus_cmd3_i == `MESI_ISC_MBUS_CMD_NOP) &&		// Call self-checker task for Master 0
              (inputs_sb.mbus_cmd2_i == `MESI_ISC_MBUS_CMD_NOP) &&
              (inputs_sb.mbus_cmd1_i == `MESI_ISC_MBUS_CMD_NOP)) begin
        master0(inputs_sb, t); end
    join_none
    
  endfunction
    
/********************************** Task for Master 3 ******************************/        
    task master3(input_ports inputs_tk, tired outputs_tk); 		// Self checker task for Master 3
      tired predicted;
          forever begin: self_checker_master3
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
          end
      endtask: master3
 
/********************************** Task for Master 2 ******************************/       
      task master2(input_ports inputs_tk, tired outputs_tk);		// Self checker task for Master 2
      tired predicted;
          forever begin: self_checker_master2
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
          end
      endtask: master2
        
/********************************** Task for Master 1 ******************************/         
      task master1(input_ports inputs_tk, tired outputs_tk);		// Self checker task for Master 1
      tired predicted;
          forever begin: self_checker_master1
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
          end 
      endtask: master1
      
/********************************** Task for Master 0 ******************************/         
      task master0(input_ports inputs_tk, tired outputs_tk);		// Self checker task for Master 0
      tired predicted;
          forever begin: self_checker_master0
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
          end            
      endtask: master0
        
endclass: scoreboard