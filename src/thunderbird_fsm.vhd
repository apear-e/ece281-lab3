--+----------------------------------------------------------------------------
--| 
--| COPYRIGHT 2017 United States Air Force Academy All rights reserved.
--| 
--| United States Air Force Academy     __  _______ ___    _________ 
--| Dept of Electrical &               / / / / ___//   |  / ____/   |
--| Computer Engineering              / / / /\__ \/ /| | / /_  / /| |
--| 2354 Fairchild Drive Ste 2F6     / /_/ /___/ / ___ |/ __/ / ___ |
--| USAF Academy, CO 80840           \____//____/_/  |_/_/   /_/  |_|
--| 
--| ---------------------------------------------------------------------------
--|
--| FILENAME      : thunderbird_fsm.vhd
--| AUTHOR(S)     : Capt Phillip Warner, Capt Dan Johnson
--| CREATED       : 03/2017 Last modified 06/25/2020
--| DESCRIPTION   : This file implements the ECE 281 Lab 2 Thunderbird tail lights
--|					FSM using enumerated types.  This was used to create the
--|					erroneous sim for GR1
--|
--|					Inputs:  i_clk 	 --> 100 MHz clock from FPGA
--|                          i_left  --> left turn signal
--|                          i_right --> right turn signal
--|                          i_reset --> FSM reset
--|
--|					Outputs:  o_lights_L (2:0) --> 3-bit left turn signal lights
--|					          o_lights_R (2:0) --> 3-bit right turn signal lights
--|
--|					Upon reset, the FSM by defaults has all lights off.
--|					Left ON - pattern of increasing lights to left
--|						(OFF, LA, LA/LB, LA/LB/LC, repeat)
--|					Right ON - pattern of increasing lights to right
--|						(OFF, RA, RA/RB, RA/RB/RC, repeat)
--|					L and R ON - hazard lights (OFF, ALL ON, repeat)
--|					A is LSB of lights output and C is MSB.
--|					Once a pattern starts, it finishes back at OFF before it 
--|					can be changed by the inputs
--|					
--|
--|                 One-Hot State Encoding key
--|                 --------------------
--|                  State | Encoding
--|                 --------------------
--|                  OFF   | 10000000
--|                  ON    | 01000000
--|                  R1    | 00100000
--|                  R2    | 00010000
--|                  R3    | 00001000
--|                  L1    | 00000100
--|                  L2    | 00000010
--|                  L3    | 00000001
--|                 --------------------
--|
--|
--+----------------------------------------------------------------------------
--|
--| REQUIRED FILES :
--|
--|    Libraries : ieee
--|    Packages  : std_logic_1164, numeric_std
--|    Files     : None
--|
--+----------------------------------------------------------------------------
--|
--| NAMING CONVENSIONS :
--|
--|    xb_<port name>           = off-chip bidirectional port ( _pads file )
--|    xi_<port name>           = off-chip input port         ( _pads file )
--|    xo_<port name>           = off-chip output port        ( _pads file )
--|    b_<port name>            = on-chip bidirectional port
--|    i_<port name>            = on-chip input port
--|    o_<port name>            = on-chip output port
--|    c_<signal name>          = combinatorial signal
--|    f_<signal name>          = synchronous signal
--|    ff_<signal name>         = pipeline stage (ff_, fff_, etc.)
--|    <signal name>_n          = active low signal
--|    w_<signal name>          = top level wiring signal
--|    g_<generic name>         = generic
--|    k_<constant name>        = constant
--|    v_<variable name>        = variable
--|    sm_<state machine type>  = state machine type definition
--|    s_<signal name>          = state name
--|
--+----------------------------------------------------------------------------
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
 
entity thunderbird_fsm is 
    port (
        i_clk, i_reset  : in    std_logic;
        i_left, i_right : in    std_logic;
        o_lights_L      : out   std_logic_vector(2 downto 0);
        o_lights_R      : out   std_logic_vector(2 downto 0)
          );
end thunderbird_fsm;

architecture thunderbird_fsm_arch of thunderbird_fsm is 
	signal f_S      : STD_LOGIC_VECTOR(7 downto 0) := "10000000";
	signal f_S_next : STD_LOGIC_VECTOR(7 downto 0) := "10000000";
-- CONSTANTS ------------------------------------------------------------------
  
begin

	-- CONCURRENT STATEMENTS --------------------------------------------------------
	--next state logic	
    f_S_next(7) <= (f_S(7) AND (NOT i_left) AND (NOT i_right)) OR f_S(6) OR f_S(3) OR f_S(0);
    f_S_next(6) <= f_S(7) AND i_left AND i_right;
    f_S_next(5) <= f_S(7) AND (NOT i_left) AND i_right;
    f_S_next(4) <= f_S(5);
    f_S_next(3) <= f_S(4);
    f_S_next(2) <= f_S(7) AND i_left AND (NOT i_right);
    f_S_next(1) <= f_S(2);
    f_S_next(0) <= f_S(1);
	
	--output logic
	o_lights_L(2) <= f_S(6) OR f_S(0);
	o_lights_L(1) <= f_S(6) OR f_S(1) OR f_S(0);
	o_lights_L(0) <= f_S(6) OR f_S(2) OR f_S(1) OR f_S(0);
	
	o_lights_R(2) <= f_S(6) OR f_S(3);
	o_lights_R(1) <= f_S(6) OR f_S(4) OR f_S(3);
	o_lights_R(0) <= f_S(6) OR f_S(5) OR f_S(4) OR f_S(3);
	
    ---------------------------------------------------------------------------------
	
	-- PROCESSES --------------------------------------------------------------------
    register_proc : process (i_clk, i_reset)
	begin
	   if i_reset = '1' then
            f_S <= "10000000";        -- reset state is yellow
        elsif (rising_edge(i_clk)) then
            f_S <= f_S_next;    -- next state becomes current state
        end if;
	end process register_proc;
	-----------------------------------------------------					   
				  
end thunderbird_fsm_arch;