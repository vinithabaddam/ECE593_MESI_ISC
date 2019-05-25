
/********************************************************************************
*
* Authors: Srijana Sapkota and Zeba Khan Rafi
* Reference: https://github.com/PrakashLuu/mesi_verification
* Reference: https://github.com/shruti2611/EE382M_project/blob/master/mesi_fifo/mesi_isc_define.v
* Reference: https://github.com/rdsalemi/uvmprimer/tree/master/16_Analysis_Ports_In_the_Testbench
* Reference: https://opencores.org/projects/mesi_isc
* Last Modified: March 3, 2019
*
* Description:	This package defines all parameters, 'defines, structure to be used throughout this project
********************************Change Log******************************************************* 
* Srijana S& Zeba	3/3/2019	To instantiate the environment class
********************************************************************************/
//import uvm_pkg::*;
import uvm_pkg::*;
`include "uvm_macros.svh"

`include "mesi_isc_env.svh"

class test extends uvm_test;
 `uvm_component_utils(test);

   env       env_h;
   
   function new (string name, uvm_component parent);
      super.new(name,parent);
   endfunction

   function void build_phase(uvm_phase phase);
      env_h = env::type_id::create("env_h",this);
   endfunction : build_phase

endclass