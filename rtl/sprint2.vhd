-- Top level file for Kee Games Sprint 2 
-- (c) 2017 James Sweet
--
-- This is free software: you can redistribute
-- it and/or modify it under the terms of the GNU General
-- Public License as published by the Free Software
-- Foundation, either version 3 of the License, or (at your
-- option) any later version.
--
-- This is distributed in the hope that it will
-- be useful, but WITHOUT ANY WARRANTY; without even the
-- implied warranty of MERCHANTABILITY or FITNESS FOR A
-- PARTICULAR PURPOSE. See the GNU General Public License
-- for more details.

-- Targeted to EP2C5T144C8 mini board but porting to nearly any FPGA should be fairly simple
-- See Sprint 2 manual for video output details. Resistor values listed here have been scaled 
-- for 3.3V logic. 
-- R48 1k Ohm
-- R49 1k Ohm
-- R50 680R
-- R51 330R

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_ARITH.all;
use IEEE.STD_LOGIC_UNSIGNED.all;


entity sprint2 is 
port(		
			Clk_50_I		: in	std_logic;	-- 50MHz input clock
			Reset_n		: in	std_logic;	-- Reset button (Active low)
			VideoW_O		: out std_logic;  -- White video output (680 Ohm)
			VideoB_O		: out std_logic;	-- Black video output (1.2k)
			VideoRGB_O	: out std_logic_vector(2 downto 0); --RGB color MOD			
			Sync_O		: out std_logic;  -- Composite sync output (1.2k)
			Audio1_O			: out std_logic_vector(6 downto 0);
			Audio2_O			: out std_logic_vector(6 downto 0);

			--Audio1_O		: out std_logic;  -- Ideally this should have a simple low pass filter
			--Audio2_O		: out std_logic;
			Coin1_I		: in  std_logic;  -- Coin switches (Active low)
			Coin2_I		: in  std_logic;
			Start1_I		: in  std_logic;  -- Start buttons
			Start2_I		: in  std_logic;
			Trak_Sel_I	: in  std_logic;  -- Track select button 
			Gas1_I		: in  std_logic;	-- Gas pedals 
			Gas2_I		: in  std_logic;
			Gear1_1_I	: in  std_logic;  -- Gear shifters, 4th gear = no other gear selected
			Gear1_2_I	: in  std_logic;
			Gear2_1_I	: in  std_logic;
			Gear2_2_I	: in  std_logic;
			Gear3_1_I	: in  std_logic;
			Gear3_2_I	: in  std_logic;
			Gear_Shift_1_I	: in std_logic_vector(2 downto 0);
			Gear_Shift_2_I	: in std_logic_vector(2 downto 0);

			Test_I		: in  std_logic;  -- Self-test switch
			Steer_1A_I	: in  std_logic;	-- Steering wheel inputs, these are quadrature encoders
			Steer_1B_I	: in	std_logic;
			Steer_2A_I	: in	std_logic;
			Steer_2B_I	: in 	std_logic;
			Lamp1_O		: out std_logic;	-- Player 1 and 2 start button LEDs
			Lamp2_O		: out std_logic;
			
			SW1_I			: in std_logic_vector(7 downto 0);
			
			
			hs_O			: out std_logic;
			vs_O			: out std_logic;
			hblank_O		: out std_logic;
			vblank_O		: out std_logic;

			clk_12		: in std_logic;
			clk_6_O		: out std_logic;

			-- signals that carry the ROM data from the MiSTer disk
			dn_addr        : in  std_logic_vector(15 downto 0);
			dn_data        : in  std_logic_vector(7 downto 0);
			dn_wr          : in  std_logic
			
			

			);
end sprint2;

architecture rtl of sprint2 is

--signal clk_12			: std_logic;
signal clk_6			: std_logic;
signal phi1 			: std_logic;
signal phi2				: std_logic;

signal Hcount		   : std_logic_vector(8 downto 0) := (others => '0');
signal H256				: std_logic;
signal H256_s			: std_logic;
signal H256_n			: std_logic;
signal H128				: std_logic;
signal H64				: std_logic;
signal H32				: std_logic;
signal H16				: std_logic;
signal H8				: std_logic;
signal H8_n				: std_logic;
signal H4				: std_logic;
signal H4_n				: std_logic;
signal H2				: std_logic;
signal H1				: std_logic;

signal Hsync			: std_logic;
signal Vsync			: std_logic;

signal Vcount  		: std_logic_vector(7 downto 0) := (others => '0');
signal V128				: std_logic;
signal V64				: std_logic;
signal V32				: std_logic;
signal V16				: std_logic;
signal V8				: std_logic;
signal V4				: std_logic;
signal V2				: std_logic;
signal V1				: std_logic;

signal Vblank			: std_logic;
signal Vreset			: std_logic;
signal Vblank_s		: std_logic;
signal Vblank_n_s		: std_logic;
signal HBlank			: std_logic;

signal CompBlank_s	: std_logic;
signal CompSync_n_s	: std_logic;

signal WhitePF_n		: std_logic;
signal BlackPF_n		: std_logic;

signal Display			: std_logic_vector(7 downto 0);


-- Address decoder
signal addec_bus		: std_logic_vector(7 downto 0);
signal RnW				: std_logic;
signal Write_n			: std_logic;
signal ROM1				: std_logic;
signal ROM2				: std_logic;
signal ROM3				: std_logic;
signal WRAM				: std_logic;
signal RAM_n			: std_logic;
signal Sync_n			: std_logic;
signal Switch_n		: std_logic;
signal Collision1_n	: std_logic;
signal Collision2_n	: std_logic;
signal Display_n		: std_logic;
signal TimerReset_n	: std_logic;
signal CollRst1_n		: std_logic;
signal CollRst2_n		: std_logic;
signal SteerRst1_n	: std_logic;
signal SteerRst2_n	: std_logic;
signal NoiseRst_n		: std_logic;
signal Attract			: std_logic := '1';	
signal Skid1			: std_logic;
signal Skid2			: std_logic;
signal Lamp1			: std_logic;
signal Lamp2			: std_logic;

signal Crash_n			: std_logic;
signal Motor1_n 		: std_logic;
signal Motor2_n		: std_logic;
signal Car1				: std_logic;
signal Car1_n			: std_logic;
signal Car2				: std_logic;
signal Car2_n			: std_logic;
signal Car3_4_n		: std_logic;	

signal NMI_n			: std_logic;

signal Adr				: std_logic_vector(9 downto 0);

--signal SW1				: std_logic_vector(7 downto 0);

signal Inputs			: std_logic_vector(1 downto 0);
signal Collisions1	: std_logic_vector(1 downto 0);
signal Collisions2	: std_logic_vector(1 downto 0);

-- logic to load roms from disk
signal rom1_cs   			: std_logic;
signal rom2_cs   			: std_logic;
signal rom3_cs   			: std_logic;
signal rom4_cs   			: std_logic;
signal rom_LSB_cs   		: std_logic;
signal rom_MSB_cs   		: std_logic;
signal rom_car_k6_cs   	: std_logic;
signal rom_car_j6_cs   	: std_logic;
signal rom_sync_prom_cs : std_logic;
signal rom_32_cs   		: std_logic;

begin
-- Configuration DIP switches, these can be brought out to external switches if desired
-- See Sprint 2 manual page 11 for complete information. Active low (0 = On, 1 = Off)
--    1 								Oil slicks			(0 - Oil slicks enabled)
--			2							Cycle tracks      (1 - Cycle through all tracks in attract mode)
--   			3	4					Coins per play		(00 - 1 Coin per player) 
--						5				Extended Play		(0 - Extended Play enabled)
--							6			Not used				(X - Don't care)
--								7	8	Game time			(01 - 120 Seconds)
--SW1 <= "01000101"; -- Config dip switches
--                          13
-- 
--     2048     6290-01.b1  00 0000 0000 0000   prog_rom1	8 bit wide
--     2048     6291-01.c1  00 1000 0000 0000   prog_rom2	8 bit wide
--     2048     6442-01.d1  01 0000 0000 0000   prog_rom3	8 bit wide
--     2048     6443-01.e1  01 1000 0000 0000   prog_rom4	8 bit wide
--      512     6396-01.p4  10 0000 0000 0000  - LSB	4 bit wide
--      512     6397-01.r4  10 0010 0000 0000  - MSB	4 bit wide
--      512     6398-01.k6  10 0100 0000 0000  - cars k6	4 bit wide
--      512     6399-01.j6  10 0110 0000 0000  - cars j6	4 bit wide
--      256     6400-01.m2  10 1000 0000 0000  - sync_prom	4 bit wide
--       32     6401-01.e2  10 1001 0000 0000					8 bit wide

rom1_cs <= '1' when dn_addr(13 downto 11) = "000"     else '0';
rom2_cs <= '1' when dn_addr(13 downto 11) = "001"     else '0';
rom3_cs <= '1' when dn_addr(13 downto 11) = "010"     else '0';
rom4_cs <= '1' when dn_addr(13 downto 11) = "011"     else '0';
rom_LSB_cs <= '1' when dn_addr(13 downto 9) =  "10000"   else '0';
rom_MSB_cs <= '1' when dn_addr(13 downto 9) =  "10001"   else '0';
rom_car_k6_cs <= '1' when dn_addr(13 downto 9) =  "10010"   else '0';
rom_car_j6_cs <= '1' when dn_addr(13 downto 9) =  "10011"   else '0';
rom_sync_prom_cs <= '1' when dn_addr(13 downto 8) =  "101000"   else '0';
rom_32_cs <= '1' when dn_addr(13 downto 8) =  "101001"   else '0';

-- PLL to generate 12.096 MHz clock
--PLL: entity work.clk_pll
--port map(
--		inclk0 => Clk_50_I,
--		c0 => clk_12
--		);
		
		
Vid_sync: entity work.synchronizer
port map(
		clk_12 => clk_12,
		clk_6 => clk_6,
		hcount => hcount,
		vcount => vcount,
		hsync => hsync,
		hblank => hblank,
		vblank_s => vblank_s,
		vblank_n_s => vblank_n_s,
		vblank => vblank,
		vsync => vsync,
		vreset => vreset,

		dn_wr => dn_wr,
		dn_addr=>dn_addr,
		dn_data=>dn_data,
		
		rom_sync_prom_cs=>rom_sync_prom_cs
		
		);


Background: entity work.playfield
port map( 
		clk6 => clk_6,
		clk12 => clk_12,
		display => display,
		HCount => HCount,
		VCount => VCount,
		
		Gear_Shift_1=> Gear_Shift_1_I,
		Gear_Shift_2=> Gear_Shift_2_I,
		
		HBlank => HBlank,		
		H256_s => H256_s,
		VBlank => VBlank,
		VBlank_n_s => Vblank_n_s,
		HSync => Hsync,
		VSync => VSync,
		CompSync_n_s => CompSync_n_s,
		CompBlank_s => CompBlank_s,
		WhitePF_n => WhitePF_n,
		BlackPF_n => BlackPF_n,

		dn_wr => dn_wr,
		dn_addr=>dn_addr,
		dn_data=>dn_data,
		
		rom_LSB_cs=>rom_LSB_cs,
		rom_MSB_cs=>rom_MSB_cs
		
		
		);

		
Cars: entity work.motion
port map(
		CLK6 => clk_6,
		CLK12 => clk_12,
		PHI2 => phi2,
		DISPLAY => Display,
		H256_s => H256_s,
		VCount => VCount,
		HCount => HCount,
		Crash_n => Crash_n,
		Motor1_n => Motor1_n,
		Motor2_n => Motor2_n,
		Car1 => Car1,
		Car1_n => Car1_n,
		Car2 => Car2,
		Car2_n => Car2_n,
		Car3_4_n => Car3_4_n,

		dn_wr => dn_wr,
		dn_addr=>dn_addr,
		dn_data=>dn_data,
		
		rom_car_j6_cs=>rom_car_j6_cs,
		rom_car_k6_cs=>rom_car_k6_cs
		
		);
		
		
PF_Comparator: entity work.collision_detect
port map(	
		Clk6 => clk_6,
		Car1 => Car1,
		Car1_n => Car1_n,
		Car2 => Car2,
		Car2_n => Car2_n,
		Car3_4_n	=> Car3_4_n,
		WhitePF_n => WhitePF_n,
		BlackPF_n => BlackPF_n,
		CollRst1_n => CollRst1_n,
		CollRst2_n => CollRst2_n,
		Collisions1 => Collisions1,
		Collisions2 => Collisions2
		);
	
	
CPU: entity work.cpu_mem
port map(
		Clk12 => clk_12,
		Clk6 => clk_6,
		Reset_n => reset_n,
		VCount => VCount,
		HCount => HCount,
		Hsync_n => not Hsync,
		Vblank_s => Vblank_s,
		Vreset => Vreset,
		Test_n => not Test_I,
		Attract => Attract,
		Skid1 => Skid1,
		Skid2 => Skid2,
		NoiseReset_n => NoiseRst_n,
		CollRst1_n => CollRst1_n,
		CollRst2_n => CollRst2_n,
		SteerRst1_n => SteerRst1_n,
		SteerRst2_n => SteerRst2_n,
		Lamp1 => Lamp1_O,
		Lamp2 => Lamp2_O,
		Phi1_o => Phi1,
		Phi2_o => Phi2,
		Display => Display,
		IO_Adr => Adr,
		Collisions1 => Collisions1,
		Collisions2 => Collisions2,
		Inputs => Inputs,
		
		dn_wr => dn_wr,
		dn_addr=>dn_addr,
		dn_data=>dn_data,
		
		rom1_cs=>rom1_cs,
		rom2_cs=>rom2_cs,
		rom3_cs=>rom3_cs,
		rom4_cs=>rom4_cs,
		rom_32_cs=>rom_32_cs

		);


Input: entity work.Control_Inputs
port map(
		clk6 => clk_6,
		SW1 => SW1_I, -- DIP switches
		Coin1_n => Coin1_I,
		Coin2_n => Coin2_I,
		Start1 => not Start1_I, -- Active high in real hardware, inverting these makes more sense with the FPGA
		Start2 => not Start2_I,
		Trak_Sel => not Trak_Sel_I,
		Gas1 => not Gas1_I,
		Gas2 => not Gas2_I,
		Gear1_1 => not Gear1_1_I,
		Gear1_2 => not Gear1_2_I,
		Gear2_1 => not Gear2_1_I,
		Gear2_2 => not Gear2_2_I,
		Gear3_1 => not Gear3_1_I,
		Gear3_2 => not Gear3_2_I,
		Self_Test => not Test_I,
		Steering1A_n => Steer_1A_I,
		Steering1B_n => Steer_1B_I,
		Steering2A_n => Steer_2A_I,
		Steering2B_n => Steer_2B_I,
		SteerRst1_n => SteerRst1_n,
		SteerRst2_n => SteerRst2_n,
		Adr => Adr,
		Inputs => Inputs
	);	

	
Sound: entity work.audio
port map( 
		Clk_50 => Clk_50_I,
		Clk_6 => Clk_6,
		Reset_n => Reset_n,
		Motor1_n => Motor1_n,
		Motor2_n => Motor2_n,
		Skid1 => Skid1,
		Skid2 => Skid2,
		Crash_n => Crash_n,
		NoiseReset_n => NoiseRst_n,
		Attract => Attract,
		Display => Display,
		HCount => HCount,
		VCount => VCount,
		Audio1 => Audio1_O,
		Audio2 => Audio2_O
		);

-- Video mixing	
VideoB_O <= (not(BlackPF_n and Car2_n and Car3_4_n)) nor CompBlank_s;	
VideoW_O <= not(WhitePF_n and Car1_n and Car3_4_n);  
VideoRGB_O <= "111" when WhitePF_n = '0' else 
			  "100" when BlackPF_n = '0' else 
			  "010" when Car1_n    = '0' else 
			  "011" when Car2_n    = '0' else 
			  "110" when Car3_4_n  = '0' else  "000";
Sync_O <= CompSync_n_s;
hs_O<= hsync;
hblank_O <= HBlank;
vblank_O <= VBlank;
vs_O <=vsync;
clk_6_O<=clk_6;

end rtl;