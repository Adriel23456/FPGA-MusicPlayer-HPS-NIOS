// (C) 2001-2023 Intel Corporation. All rights reserved.
// Your use of Intel Corporation's design tools, logic functions and other 
// software and tools, and its AMPP partner logic functions, and any output 
// files from any of the foregoing (including device programming or simulation 
// files), and any associated documentation or information are expressly subject 
// to the terms and conditions of the Intel Program License Subscription 
// Agreement, Intel FPGA IP License Agreement, or other applicable 
// license agreement, including, without limitation, that your use is for the 
// sole purpose of programming logic devices manufactured by Intel and sold by 
// Intel or its authorized distributors.  Please refer to the applicable 
// agreement for further details.


// $Id: //acds/main/ip/sopc/components/verification/altera_tristate_conduit_bfm/altera_tristate_conduit_bfm.sv.terp#7 $
// $Revision: #7 $
// $Date: 2010/08/05 $
// $Author: klong $
//-----------------------------------------------------------------------------
// =head1 NAME
// altera_conduit_bfm
// =head1 SYNOPSIS
// Bus Functional Model (BFM) for a Standard Conduit BFM
//-----------------------------------------------------------------------------
// =head1 DESCRIPTION
// This is a Bus Functional Model (BFM) for a Standard Conduit Master.
// This BFM sampled the input/bidirection port value or driving user's value to 
// output ports when user call the API.  
// This BFM's HDL is been generated through terp file in Qsys/SOPC Builder.
// Generation parameters:
// output_name:                                       altera_conduit_bfm
// role:width:direction:                              SCLK:1:input,SDAT:1:bidir
// 0
//-----------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module altera_conduit_bfm
(
   sig_SCLK,
   sig_SDAT
);

   //--------------------------------------------------------------------------
   // =head1 PINS 
   // =head2 User defined interface
   //--------------------------------------------------------------------------
   input sig_SCLK;
   inout wire sig_SDAT;

   // synthesis translate_off
   import verbosity_pkg::*;
   
   typedef logic ROLE_SCLK_t;
   typedef logic ROLE_SDAT_t;

   logic [0 : 0] sig_SCLK_in;
   logic [0 : 0] sig_SCLK_local;
   logic sig_SDAT_oe;
   logic sig_SDAT_oe_temp = 0;
   reg sig_SDAT_temp;
   reg sig_SDAT_out;
   logic [0 : 0] sig_SDAT_in;
   logic [0 : 0] sig_SDAT_local;

   //--------------------------------------------------------------------------
   // =head1 Public Methods API
   // =pod
   // This section describes the public methods in the application programming
   // interface (API). The application program interface provides methods for 
   // a testbench which instantiates, controls and queries state in this BFM 
   // component. Test programs must only use these public access methods and 
   // events to communicate with this BFM component. The API and module pins
   // are the only interfaces of this component that are guaranteed to be
   // stable. The API will be maintained for the life of the product. 
   // While we cannot prevent a test program from directly accessing internal
   // tasks, functions, or data private to the BFM, there is no guarantee that
   // these will be present in the future. In fact, it is best for the user
   // to assume that the underlying implementation of this component can 
   // and will change.
   // =cut
   //--------------------------------------------------------------------------
   
   event signal_input_SCLK_change;
   event signal_input_SDAT_change;
   
   function automatic string get_version();  // public
      // Return BFM version string. For example, version 9.1 sp1 is "9.1sp1" 
      string ret_version = "22.1";
      return ret_version;
   endfunction

   // -------------------------------------------------------
   // SCLK
   // -------------------------------------------------------
   function automatic ROLE_SCLK_t get_SCLK();
   
      // Gets the SCLK input value.
      $sformat(message, "%m: called get_SCLK");
      print(VERBOSITY_DEBUG, message);
      return sig_SCLK_in;
      
   endfunction

   // -------------------------------------------------------
   // SDAT
   // -------------------------------------------------------
   function automatic ROLE_SDAT_t get_SDAT();
   
      // Gets the SDAT input value.
      $sformat(message, "%m: called get_SDAT");
      print(VERBOSITY_DEBUG, message);
      return sig_SDAT_in;
      
   endfunction

   function automatic void set_SDAT (
      ROLE_SDAT_t new_value
   );
      // Drive the new value to SDAT.
      
      $sformat(message, "%m: method called arg0 %0d", new_value); 
      print(VERBOSITY_DEBUG, message);
      
      sig_SDAT_temp = new_value;
   endfunction
   
   function automatic void set_SDAT_oe (
      bit enable
   );
      // bidir port SDAT will work as output port when set to 1.
      // bidir port SDAT will work as input port when set to 0.
      
      $sformat(message, "%m: method called arg0 %0d", enable); 
      print(VERBOSITY_DEBUG, message);
      
      sig_SDAT_oe_temp = enable;
   endfunction

   assign sig_SCLK_in = sig_SCLK;
   assign sig_SDAT_oe = sig_SDAT_oe_temp;
   assign sig_SDAT = (sig_SDAT_oe == 1)? sig_SDAT_temp:'z;
   assign sig_SDAT_in = (sig_SDAT_oe == 0)? sig_SDAT:'z;


   always @(sig_SCLK_in) begin
      if (sig_SCLK_local != sig_SCLK_in)
         -> signal_input_SCLK_change;
      sig_SCLK_local = sig_SCLK_in;
   end
   
   always @(sig_SDAT_in) begin
      if (sig_SDAT_oe == 0) begin
         if (sig_SDAT_local != sig_SDAT_in)
            -> signal_input_SDAT_change;
         sig_SDAT_local = sig_SDAT_in;
      end
   end
   


// synthesis translate_on

endmodule

