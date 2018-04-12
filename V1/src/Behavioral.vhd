library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--
entity Encryption is
	port
	(clk	: in std_logic;
	start	: in std_logic;
	input_key:	in std_logic_vector; -- 32 bit input bus
	input_txt:	in std_logic_vector; -- 32bit input bus
--	Rcon	: constant std_logic_vector(); -- is this needed 
--	Sbox	: constant std_logic_vector();
	Key_Round	: inout integer; 
	txt_round	: inout integer;
	Key		: std_logic_vector(0 to 127)  -- will change to conform to the number of pins allowed
	);
end encryption;


	
  
Architecture Behavioral of Encryption is 

shared variable Row1_Key	: std_logic_vector(0 to 31);
shared variable Row2_Key	: std_logic_vector(0 to 31);
shared variable Row3_Key	: std_logic_vector(0 to 31);
shared variable Row4_Key	: std_logic_vector(0 to 31);
shared variable key_expansion : std_logic = '0';

shared variable Row1_txt	: std_logic_vector(0 to 31);
shared variable Row2_txt	: std_logic_vector(0 to 31);
shared variable Row3_txt	: std_logic_vector(0 to 31);
shared variable Row4_txt	: std_logic_vector(0 to 31);
shared variable plaintxt	: std_logic_vector(0 to 127);

type array_256 is array (0 to 255) of std_logic_vector(7 downto 0);		-- used for sbox and rcon
type array_16 is array (0 to 15) of std_logic_vector(7 downto 0);		-- used for the mixed columns


	Constant rcon : array_256 := (
    X"B1",X"01",X"02",X"04",X"08",X"10",X"20",X"40",X"80",X"63",X"C6",X"EF",X"BD",X"19",X"32",X"64",
    X"C8",X"F3",X"85",X"69",X"D2",X"C7",X"ED",X"B9",X"11",X"22",X"44",X"88",X"73",X"E6",X"AF",X"3D",
    X"7A",X"F4",X"8B",X"75",X"EA",X"B7",X"0D",X"1A",X"34",X"68",X"D0",X"C3",X"E5",X"A9",X"31",X"62",
    X"C4",X"EB",X"B5",X"09",X"12",X"24",X"48",X"90",X"43",X"86",X"6F",X"DE",X"DF",X"DD",X"D9",X"D1",
    X"C1",X"E1",X"A1",X"21",X"42",X"84",X"6B",X"D6",X"CF",X"FD",X"99",X"51",X"A2",X"27",X"4E",X"9C",
    X"5B",X"B6",X"0F",X"1E",X"3C",X"78",X"F0",X"83",X"65",X"CA",X"F7",X"8D",X"79",X"F2",X"87",X"6D",
    X"DA",X"D7",X"CD",X"F9",X"91",X"41",X"82",X"67",X"CE",X"FF",X"9D",X"59",X"B2",X"07",X"0E",X"1C",
    X"38",X"70",X"E0",X"A3",X"25",X"4A",X"94",X"4B",X"96",X"4F",X"9E",X"5F",X"BE",X"1F",X"3E",X"7C",
    X"F8",X"93",X"45",X"8A",X"77",X"EE",X"BF",X"1D",X"3A",X"74",X"E8",X"B3",X"05",X"0A",X"14",X"28",
    X"50",X"A0",X"23",X"46",X"8C",X"7B",X"F6",X"8F",X"7D",X"FA",X"97",X"4D",X"9A",X"57",X"AE",X"3F",
    X"7E",X"FC",X"9B",X"55",X"AA",X"37",X"6E",X"DC",X"DB",X"D5",X"C9",X"F1",X"81",X"61",X"C2",X"E7",
    X"AD",X"39",X"72",X"E4",X"AB",X"35",X"6A",X"D4",X"CB",X"F5",X"89",X"71",X"E2",X"A7",X"2D",X"5A",
    X"B4",X"0B",X"16",X"2C",X"58",X"B0",X"03",X"06",X"0C",X"18",X"30",X"60",X"C0",X"E3",X"A5",X"29",
    X"52",X"A4",X"2B",X"56",X"AC",X"3B",X"76",X"EC",X"BB",X"15",X"2A",X"54",X"A8",X"33",X"66",X"CC",
    X"FB",X"95",X"49",X"92",X"47",X"8E",X"7F",X"FE",X"9F",X"5D",X"BA",X"17",X"2E",X"5C",X"B8",X"13",
    X"26",X"4C",X"98",X"53",X"A6",X"2F",X"5E",X"BC",X"1B",X"36",X"6C",X"D8",X"D3",X"C5",X"E9",X"B1");
	
	
	
	constant sbox : array_256 := (
    X"63",X"7C",X"E1",X"60",X"2F",X"62",X"E2",X"68",X"48",X"6C",X"E3",X"34",X"AE",X"29",X"E6",X"95",
    X"FB",X"CE",X"E9",X"8F",X"2E",X"0D",X"C5",X"53",X"85",X"4D",X"46",X"66",X"A1",X"A7",X"15",X"EB",
    X"22",X"1B",X"B8",X"16",X"2B",X"A5",X"18",X"D6",X"C8",X"9D",X"54",X"79",X"3D",X"9F",X"76",X"65",
    X"1D",X"17",X"74",X"0E",X"F1",X"31",X"EC",X"51",X"0F",X"8C",X"01",X"AB",X"58",X"43",X"2A",X"B0",
    X"C3",X"DB",X"52",X"6A",X"83",X"32",X"D9",X"8A",X"47",X"EA",X"00",X"30",X"D3",X"D2",X"B4",X"B7",
    X"B6",X"81",X"11",X"4F",X"F8",X"B1",X"6E",X"02",X"41",X"7B",X"10",X"96",X"E4",X"8D",X"6D",X"5B",
    X"5C",X"F5",X"59",X"4B",X"E5",X"B9",X"D5",X"40",X"27",X"06",X"4A",X"A9",X"A4",X"C4",X"77",X"21",
    X"55",X"9E",X"99",X"56",X"5F",X"05",X"0A",X"37",X"F3",X"2C",X"7E",X"C0",X"C7",X"9C",X"87",X"14",
    X"33",X"4E",X"3F",X"CC",X"F6",X"B3",X"E7",X"36",X"13",X"98",X"CB",X"AF",X"3E",X"FD",X"97",X"86",
    X"71",X"08",X"AA",X"C1",X"DF",X"70",X"CA",X"1A",X"3B",X"A6",X"BB",X"DC",X"88",X"49",X"09",X"BE",
    X"89",X"93",X"12",X"EE",X"57",X"84",X"75",X"9A",X"A3",X"8B",X"07",X"DD",X"E8",X"BC",X"DE",X"23",
    X"7F",X"5D",X"6F",X"61",X"D7",X"67",X"94",X"F7",X"A0",X"38",X"19",X"BF",X"69",X"25",X"72",X"F0",
    X"FC",X"BA",X"28",X"F4",X"73",X"9B",X"7A",X"3A",X"20",X"CD",X"03",X"A2",X"35",X"D4",X"FF",X"5A",
    X"4C",X"D0",X"D1",X"92",X"FA",X"24",X"0B",X"0C",X"80",X"04",X"BD",X"ED",X"64",X"AD",X"42",X"FE",
    X"78",X"82",X"90",X"AC",X"1E",X"A8",X"F9",X"C6",X"7D",X"1F",X"50",X"6B",X"DA",X"CF",X"44",X"EF",
    X"26",X"39",X"C9",X"C2",X"E0",X"8E",X"B2",X"5E",X"3C",X"B5",X"91",X"45",X"1C",X"F2",X"D8",X"2D"
  ); 
 
  	constant MC : array_16 := (
  	X"3",X"4",X"1",X"7",
 	X"7",X"3",X"4",X"1",
  	X"1",X"7",X"3",X"4",
  	X"4",X"1",X"7",X"3");		 
	  
	
-- Key expansion  sudo/ how to
	-- Rotate row4
	-- Rcon XOR key with the RCON constant LUT
	-- SBOX substitution
	-- finite field XOR ?????
 
	begin	-- begins the architecture 

Process (clk, start, key_process) -- input process

	variable feedkey	: std_logic_vector(0 to 31);	-- feed in the key by 32 bit bus
	variable feedtxt	: std_logic_vector(0 to 31);	-- feed in the txt by 32 bit bus
begin
	
	if (clk'event and start = '1')	   -- issue with this is that how will we update the inputs in the loop????
		for i in 1 to 4 loop
			case i is
				when 1 =>	Row1_key := input_key;
							Row1_txt := input_txt; 
				
				when 2 =>	Row2_key := input_key;
							Row2_txt := input_txt;
				
				when 3 => 	Row3_key := input_key;
							Row3_txt := input_txt;
							
				when 4 =>	Row4_key := input_key;
							Row4_txt := input_txt;
				
			end case;
		end loop;
	end if;
end process;	-- for the inputs
	
	
				
process (clk, init_Expansion, round)
	
	variable init_Expansion : std_logic;	-- initialize the encryption
--	variable Row1_Key	: std_logic_vector(0 to 31);
--	variable Row2_Key	: std_logic_vector(0 to 31);		 -- changed these to shared variables
--	variable Row3_Key	: std_logic_vector(0 to 31);
--	variable Row4_Key	: std_logic_vector(0 to 31);	 
	Variable Temp_Sbox_Key	: std_logic_vector(0 to 127);


	begin	-- begin the process for key expansion
	
	-- creating rows from the original key	
		if (init_Expansion = '1' and key_round <= 12) then	   -- if condition to verify that we are still in each round

			
			
-- Rotate Row 4 and creating the bytes.		
									-- bytes			(0-7) (8-15) (16-23) (24-31)
									-- rotate to left	(8-15) (16-23) (24-31) (0-7)
	
		  Row4_Key_byte1	:= Row4_Key(15 downto 8);
		  Row4_Key_byte2	:= Row4_Key(23 downto 16);
		  Row4_Key_byte3	:= Row4_Key(31 downto 24);
		  Row4_Key_byte4	:= Row4_Key(7 downto 8);  

		  
		  Row4_Key := Row4_Key_byte2 & Row4_Key_byte3 & Row4_Key_byte4;	  -- combine to create a single array
		

		
-- Rcon XOR
			
			for i in 0 to 31 loop
				Key(i) := Row4_key(i) xor Rcon(Key_round) 	-- or is it rcon(round +1)??
			end loop; 
			
		-- convert to a bytwise word
			tempbyte1	:= Row4_Key(15 downto 8);
			tempbyte2	:= Row4_Key(23 downto 16);
		  	tempbyte3	:= Row4_Key(31 downto 24);
		  	tempbyte4	:= Row4_Key(7 downto 8);	
			
-- Sbox

			Row_key_byte1	:= sbox(tempbyte1);
			Row_key_byte2	:= sbox(tempbyte2);
			Row_key_byte3	:= sbox(tempbyte3);
			Row_key_byte4	:= sbox(tempbyte4);	
			
			-- combine to create a single array
			Row4_Key := Row4_Key_byte2 & Row4_Key_byte3 & Row4_Key_byte4;	  
			
--		for i in 0 to 31 loop	-- redefine the row values
--				Row1_Key(i) := Temp_Sbox_key(i);
--			 	Row2_Key(i) := Temp_Sbox_key(32+i);
--				Row3_Key(i) := Temp_Sbox_key(64+i);
--				Row4_Key(i) := Temp_Sbox_key(96+i);
--			end loop;				

			CipherKey 	:= Row1_key & Row2_key & Row3_key & Row4_key; 

-- key schedule Core		  

		for i in 0 to 127 loop
			Key_Schedule(i) := rcon(key_round) xor CipherKey(i);
		end loop;
	

--		for i in 0 to 31 loop	-- redefine the row values
--				Row1_Key(i) := Temp_Sbox_key(i);
--			 	Row2_Key(i) := Temp_Sbox_key(32+i);
--				Row3_Key(i) := Temp_Sbox_key(64+i);
--				Row4_Key(i) := Temp_Sbox_key(96+i);
--			end loop;
			
			
			CipherKey := Key_Schedule;
			
		Key_round := Key_round + 1;	-- add to round key
		
		elsif round_key = 12 then
			key_expansion = '1';
			
		end if;	-- if round_key < 12
		
	end process; -- key expansion process
	
	
---------------------------------------------------------------------------------------------------------	
	
-- process for the Encryption
-- debating on one process or two?
-- 1. organize into 4x4 matrix in column major
-- b0 b4 b8
-- b1 b5 ...

-- 2. sbox trans per byte
-- 3. rotate rows
-- 4. mixed columns
-- 5a. turn back to 128 bit vector
-- 5b. result 5a xor with encryption for rounds 1-11
	
	
Process(clk, round)

variable Row1_Key_cipher	: std_logic_vector(0 to 31);
variable Row2_Key_cipher	: std_logic_vector(0 to 31);
variable Row3_Key_cipher	: std_logic_vector(0 to 31);
variable Row4_Key_cipher	: std_logic_vector(0 to 31);	 
Variable Temp_Sbox_cipher	: std_logic_vector(0 to 127);	
byte : array_16;

begin
	
	
	if round = 0 then
		plaintxt 	:= Row1_txt & Row2_txt & Row3_txt & Row4_txt;
		
		for i in 0 to 127 loop
			Encrypted_txt(i) := CipherKey(i) xor Plaintxt(i);
		end loop; 
		
	elsif round < 12 then
		
		-- organize into column major
--			Row1_txt(0 to 31) := plaintxt(0 to 7)   & plaintxt(32 to 39) & plaintxt(64 to 71) & plaintxt(96 to 103);
--		 	Row2_txt(0 to 31) := plaintxt(8 to 15)  & plaintxt(40 to 47) & plaintxt(72 to 79) & plaintxt(104 to 111);
--			Row3_txt(0 to 31) := plaintxt(16 to 23) & plaintxt(48 to 55) & plaintxt(80 to 87) & plaintxt(112 to 119);
--			Row4_txt(0 to 31) := plaintxt(24 to 31) & plaintxt(56 to 63) & plaintxt(88 to 95) & plaintxt(120 to 127);

			
			Byte(0) := plaintxt(0 to 7)		-- attempt at a 2d array
			Byte(1) := plaintxt(8 to 15)
			Byte(2) := plaintxt(16 to 23)
			Byte(3) := plaintxt(24 to 31)
			Byte(4) := plaintxt(32 to 39)
			Byte(5) := plaintxt(40 to 47)
			Byte(6) := plaintxt(48 to 55)
			Byte(7) := plaintxt(56 to 63)
			Byte(8) := plaintxt(64 to 71)
			Byte(9) := plaintxt(72 to 79)
			Byte(10) := plaintxt(80 to 87)
			Byte(11) := plaintxt(88 to 95)
			Byte(12) := plaintxt(96 to 103)
			Byte(13) := plaintxt(104 to 111)
			Byte(14) := plaintxt(112 to 119)
			Byte(15) := plaintxt(120 to 127)
			
			
-- do the sbox substitution		  -- how to do this with hexadecimal
			for i in 0 to 15 loop
					Temp:= B(i);
					Temp_Sbox_txt(i) := sbox(temp);
			end loop;
			
-- rotate the rows

			Row1_txt(0 to 31) := B(0)  & B(4)  & B(8)  & B(12);	
			Row2_txt(0 to 31) := B(5)  & B(9)  & B(13) & B(1);
			Row3_txt(0 to 31) := B(10) & B(14) & B(2)  & B(6);
			Row4_txt(0 to 31) := B(15) & B(3)  & B(7)  & B(11);
			
-- mix columns
-- use the LUT to do the single byte multiplication
-- xor the result to create the new element within the array. should be about 3 nested loops



-- turn back into a 128 bit vector


-- take bit vector and xor with current round key
			
-- 
	elsif round = 12 then
	
	else -- stop program.
	
	
	end if;
	
end process;

end Behavioral;
	
	
	



	
	