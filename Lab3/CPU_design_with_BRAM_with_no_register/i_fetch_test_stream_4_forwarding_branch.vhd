-- file: i_fetch_test_stream_instr_stream_pkg.vhd (version: i_fetch_test_stream_instr_stream_pkg_non_aligned_branches.vhd)
-- Written by Gandhi Puvvada
-- date of last rivision: 7/23/2008 
--
-- A package file to define the instruction stream to be placed in the instr_cache.
-- This package, "instr_stream_pkg", is refered in a use clause in the inst_cache_sprom module.
-- We will use several files similar to this containining different instruction streams.
-- The package name will remain the same, namely instr_stream_pkg.
-- Only the file name changes from, say  i_fetch_test_stream_instr_stream_pkg.vhd
-- to say mult_test_stream_instr_stream_pkg.vhd.
-- Depending on which instr_stream_pkg file was analysed/compiled  most recently,
-- that stream will be used for simulation/synthesis.
----------------------------------------------------------
library std, ieee;
use ieee.std_logic_1164.all;

package instr_stream_pkg is

    constant DATA_WIDTH_CONSTANT     : integer := 32; -- data width of of our cache
    constant ADDR_WIDTH_CONSTANT     : integer :=   8; -- address width of our cache

	-- type declarations
	type mem_type is array (0 to (2**ADDR_WIDTH_CONSTANT)-1) of std_logic_vector((DATA_WIDTH_CONSTANT-1) downto 0); 

    ---------------------------------------------------    
    ---------------------------------------------------    
--00422825 --or	$5, $2, $2  ---Instruction with lable Loop1	0000	0000	0100	0010	0010	1000	0010	0101
--1085FFFE --BEQ	$4, $5, Loop1	0001	0000	1000	0101	1111	1111	1111	1110
--00842020 --ADD	$4, $4, $4
    ---------------------------------------------------    
    ---------------------------------------------------    
	signal mem          : mem_type := (X"00422825", X"1085FFFE", X"00842020", X"00000020",X"00000020", X"00000020",X"00000020", X"00000020", X"00000020", X"00000020", X"00000020", X"00000020", X"00000020", X"00000020", X"00000020",X"0000000F",
                                   X"00000010", X"00000011", X"00000012", X"00000013",X"00000014", X"00000015",X"00000016", X"00000017", X"00000018", X"00000019", X"0000001A", X"0000001B", X"0000001C", X"0000001D", X"0000001E",X"0000001F",
											  X"00000020", X"00000021", X"00000022", X"00000023",X"00000024", X"00000025",X"00000026", X"00000027", X"00000028", X"00000029", X"0000002A", X"0000002B", X"0000002C", X"0000002D", X"0000002E",X"0000002F",
											  X"00000030", X"00000031", X"00000032", X"00000033",X"00000034", X"00000035",X"00000036", X"00000037", X"00000038", X"00000039", X"0000003A", X"0000003B", X"0000003C", X"0000003D", X"0000003E",X"0000003F",
											  X"00000040", X"00000041", X"00000042", X"00000043",X"00000044", X"00000045",X"00000046", X"00000047", X"00000048", X"00000049", X"0000004A", X"0000004B", X"0000004C", X"0000004D", X"0000004E",X"0000004F",
											  X"00000050", X"00000051", X"00000052", X"00000053",X"00000054", X"00000055",X"00000056", X"00000057", X"00000058", X"00000059", X"0000005A", X"0000005B", X"0000005C", X"0000005D", X"0000005E",X"0000005F",
											  X"00000060", X"00000061", X"00000062", X"00000063",X"00000064", X"00000065",X"00000066", X"00000067", X"00000068", X"00000069", X"0000006A", X"0000006B", X"0000006C", X"0000006D", X"0000006E",X"0000006F",
											  X"00000070", X"00000071", X"00000072", X"00000073",X"00000074", X"00000075",X"00000076", X"00000077", X"00000078", X"00000079", X"0000007A", X"0000007B", X"0000007C", X"0000007D", X"0000007E",X"0000007F",
											  X"00000080", X"00000081", X"00000082", X"00000083",X"00000084", X"00000085",X"00000086", X"00000087", X"00000088", X"00000089", X"0000008A", X"0000008B", X"0000008C", X"0000008D", X"0000008E",X"0000008F",
											  X"00000090", X"00000091", X"00000092", X"00000093",X"00000094", X"00000095",X"00000096", X"00000097", X"00000098", X"00000099", X"0000009A", X"0000009B", X"0000009C", X"0000009D", X"0000009E",X"0000009F",
											  X"000000A0", X"000000A1", X"000000A2", X"000000A3",X"000000A4", X"000000A5",X"000000A6", X"000000A7", X"000000A8", X"000000A9", X"000000AA", X"000000AB", X"000000AC", X"000000AD", X"000000AE",X"000000AF",
											  X"000000B0", X"000000B1", X"000000B2", X"000000B3",X"000000B4", X"000000B5",X"000000B6", X"000000B7", X"000000B8", X"000000B9", X"000000BA", X"000000BB", X"000000BC", X"000000BD", X"000000BE",X"000000BF",
											  X"000000C0", X"000000C1", X"000000C2", X"000000C3",X"000000C4", X"000000C5",X"000000C6", X"000000C7", X"000000C8", X"000000C9", X"000000CA", X"000000CB", X"000000CC", X"000000CD", X"000000CE",X"000000CF",
											  X"000000D0", X"000000D1", X"000000D2", X"000000D3",X"000000D4", X"000000D5",X"000000D6", X"000000D7", X"000000D8", X"000000D9", X"000000DA", X"000000DB", X"000000DC", X"000000DD", X"000000DE",X"000000DF",
											  X"000000E0", X"000000E1", X"000000E2", X"000000E3",X"000000E4", X"000000E5",X"000000E6", X"000000E7", X"000000E8", X"000000E9", X"000000EA", X"000000EB", X"000000EC", X"000000ED", X"000000EE",X"000000EF",
											  X"000000F0", X"000000F1", X"000000F2", X"000000F3",X"000000F4", X"000000F5",X"000000F6", X"000000F7", X"000000F8", X"000000F9", X"000000FA", X"000000FB", X"000000FC", X"000000FD", X"000000FE",X"000000FF") ;


end package instr_stream_pkg;

-- -- No need for s package body here
-- package body instr_stream_pkg is
--
-- end package body instr_stream_pkg;  
