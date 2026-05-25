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
// output_name:                                       altera_conduit_bfm_0007
// role:width:direction:                              B:8:input,BLANK:1:input,CLK:1:input,G:8:input,HS:1:input,R:8:input,SYNC:1:input,VS:1:input
// 0
//-----------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module altera_conduit_bfm_0007
(
   sig_B,
   sig_BLANK,
   sig_CLK,
   sig_G,
   sig_HS,
   sig_R,
   sig_SYNC,
   sig_VS
);

   //--------------------------------------------------------------------------
   // =head1 PINS 
   // =head2 User defined interface
   //--------------------------------------------------------------------------
   input [7 : 0] sig_B;
   input sig_BLANK;
   input sig_CLK;
   input [7 : 0] sig_G;
   input sig_HS;
   input [7 : 0] sig_R;
   input sig_SYNC;
   input sig_VS;

   // synthesis translate_off
   import verbosity_pkg::*;
   
   typedef logic [7 : 0] ROLE_B_t;
   typedef logic ROLE_BLANK_t;
   typedef logic ROLE_CLK_t;
   typedef logic [7 : 0] ROLE_G_t;
   typedef logic ROLE_HS_t;
   typedef logic [7 : 0] ROLE_R_t;
   typedef logic ROLE_SYNC_t;
   typedef logic ROLE_VS_t;

   logic [7 : 0] sig_B_in;
   logic [7 : 0] sig_B_local;
   logic [0 : 0] sig_BLANK_in;
   logic [0 : 0] sig_BLANK_local;
   logic [0 : 0] sig_CLK_in;
   logic [0 : 0] sig_CLK_local;
   logic [7 : 0] sig_G_in;
   logic [7 : 0] sig_G_local;
   logic [0 : 0] sig_HS_in;
   logic [0 : 0] sig_HS_local;
   logic [7 : 0] sig_R_in;
   logic [7 : 0] sig_R_local;
   logic [0 : 0] sig_SYNC_in;
   logic [0 : 0] sig_SYNC_local;
   logic [0 : 0] sig_VS_in;
   logic [0 : 0] sig_VS_local;

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
   
   event signal_input_B_change;
   event signal_input_BLANK_change;
   event signal_input_CLK_change;
   event signal_input_G_change;
   event signal_input_HS_change;
   event signal_input_R_change;
   event signal_input_SYNC_change;
   event signal_input_VS_change;
   
   function automatic string get_version();  // public
      // Return BFM version string. For example, version 9.1 sp1 is "9.1sp1" 
      string ret_version = "22.1";
      return ret_version;
   endfunction

   // -------------------------------------------------------
   // B
   // -------------------------------------------------------
   function automatic ROLE_B_t get_B();
   
      // Gets the B input value.
      $sformat(message, "%m: called get_B");
      print(VERBOSITY_DEBUG, message);
      return sig_B_in;
      
   endfunction

   // -------------------------------------------------------
   // BLANK
   // -------------------------------------------------------
   function automatic ROLE_BLANK_t get_BLANK();
   
      // Gets the BLANK input value.
      $sformat(message, "%m: called get_BLANK");
      print(VERBOSITY_DEBUG, message);
      return sig_BLANK_in;
      
   endfunction

   // -------------------------------------------------------
   // CLK
   // -------------------------------------------------------
   function automatic ROLE_CLK_t get_CLK();
   
      // Gets the CLK input value.
      $sformat(message, "%m: called get_CLK");
      print(VERBOSITY_DEBUG, message);
      return sig_CLK_in;
      
   endfunction

   // -------------------------------------------------------
   // G
   // -------------------------------------------------------
   function automatic ROLE_G_t get_G();
   
      // Gets the G input value.
      $sformat(message, "%m: called get_G");
      print(VERBOSITY_DEBUG, message);
      return sig_G_in;
      
   endfunction

   // -------------------------------------------------------
   // HS
   // -------------------------------------------------------
   function automatic ROLE_HS_t get_HS();
   
      // Gets the HS input value.
      $sformat(message, "%m: called get_HS");
      print(VERBOSITY_DEBUG, message);
      return sig_HS_in;
      
   endfunction

   // -------------------------------------------------------
   // R
   // -------------------------------------------------------
   function automatic ROLE_R_t get_R();
   
      // Gets the R input value.
      $sformat(message, "%m: called get_R");
      print(VERBOSITY_DEBUG, message);
      return sig_R_in;
      
   endfunction

   // -------------------------------------------------------
   // SYNC
   // -------------------------------------------------------
   function automatic ROLE_SYNC_t get_SYNC();
   
      // Gets the SYNC input value.
      $sformat(message, "%m: called get_SYNC");
      print(VERBOSITY_DEBUG, message);
      return sig_SYNC_in;
      
   endfunction

   // -------------------------------------------------------
   // VS
   // -------------------------------------------------------
   function automatic ROLE_VS_t get_VS();
   
      // Gets the VS input value.
      $sformat(message, "%m: called get_VS");
      print(VERBOSITY_DEBUG, message);
      return sig_VS_in;
      
   endfunction

   assign sig_B_in = sig_B;
   assign sig_BLANK_in = sig_BLANK;
   assign sig_CLK_in = sig_CLK;
   assign sig_G_in = sig_G;
   assign sig_HS_in = sig_HS;
   assign sig_R_in = sig_R;
   assign sig_SYNC_in = sig_SYNC;
   assign sig_VS_in = sig_VS;


   always @(sig_B_in) begin
      if (sig_B_local != sig_B_in)
         -> signal_input_B_change;
      sig_B_local = sig_B_in;
   end
   
   always @(sig_BLANK_in) begin
      if (sig_BLANK_local != sig_BLANK_in)
         -> signal_input_BLANK_change;
      sig_BLANK_local = sig_BLANK_in;
   end
   
   always @(sig_CLK_in) begin
      if (sig_CLK_local != sig_CLK_in)
         -> signal_input_CLK_change;
      sig_CLK_local = sig_CLK_in;
   end
   
   always @(sig_G_in) begin
      if (sig_G_local != sig_G_in)
         -> signal_input_G_change;
      sig_G_local = sig_G_in;
   end
   
   always @(sig_HS_in) begin
      if (sig_HS_local != sig_HS_in)
         -> signal_input_HS_change;
      sig_HS_local = sig_HS_in;
   end
   
   always @(sig_R_in) begin
      if (sig_R_local != sig_R_in)
         -> signal_input_R_change;
      sig_R_local = sig_R_in;
   end
   
   always @(sig_SYNC_in) begin
      if (sig_SYNC_local != sig_SYNC_in)
         -> signal_input_SYNC_change;
      sig_SYNC_local = sig_SYNC_in;
   end
   
   always @(sig_VS_in) begin
      if (sig_VS_local != sig_VS_in)
         -> signal_input_VS_change;
      sig_VS_local = sig_VS_in;
   end
   


// synthesis translate_on

endmodule

