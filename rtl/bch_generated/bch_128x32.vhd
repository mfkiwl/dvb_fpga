--    /*  -------------------------------------------------------------------------
--    This program is free software: you can redistribute it and/or modify
--    it under the terms of the GNU General Public License as published by
--    the Free Software Foundation, either version 3 of the License, or
--    any later version.
--
--    This program is distributed in the hope that it will be useful,
--    but WITHOUT ANY WARRANTY; without even the implied warranty of
--    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--    GNU General Public License for more details.
--    
--    You should have received a copy of the GNU General Public License
--    along with this program.  If not, see <http://www.gnu.org/licenses/>.
--    
--    Copyright: Levent Ozturk crc@leventozturk.com
--    https://leventozturk.com/engineering/crc/
--    Polynomial: x128+x124+x123+x122+x114+x113+x112+x109+x106+x104+x102+x100+x99+x98+x97+x96+x94+x93+x92+x88+x85+x82+x81+x80+x79+x76+x74+x73+x72+x71+x69+x68+x67+x66+x64+x60+x59+x56+x55+x54+x53+x52+x51+x50+x46+x45+x43+x42+x40+x38+x37+x36+x34+x32+x26+x23+x22+x21+x20+x19+x16+x14+x13+x10+x9+x5+x3+x1+1
--    d31 is the first data processed

--    c is internal LFSR state and the CRC output. Not needed for other modules than CRC.
--    c width is always same as polynomial width.
--    o is the output of all modules except CRC. Not needed for CRC.
--    o width is always same as data width width
-------------------------------------------------------------------------*/

-- Based on https://leventozturk.com/engineering/crc/

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity bch_128x32 is
generic  (
	SEED : in std_ulogic_vector(127 downto 0) := (others => '0')
);
port (
	clk   :  in std_ulogic;
	reset :  in std_ulogic;
	fd    :  in std_ulogic; -- First data. 1: SEED is used (initialise and calculate), 0: Previous CRC is used (continue and calculate)
	nd    :  in std_ulogic; -- New Data. d input has a valid data. Calculate new CRC
	rdy   : out std_ulogic;
	d    :  in std_ulogic_vector( 31 downto 0);  -- Data in
	c    : out std_ulogic_vector(127 downto 0);
 -- CRC output
	o    : out std_ulogic_vector( 31 downto 0) -- Data output
);
end entity bch_128x32;

architecture bch_128x32 of bch_128x32 is
	signal                       nd_q : std_ulogic;
	signal                       fd_q : std_ulogic;
	signal                       dq : std_ulogic_vector (127 downto 0);
	signal                       ca : std_ulogic_vector(127 downto 0);
	signal                       oa : std_ulogic_vector( 31 downto 0);
begin
	process (clk)
	begin
		if (rising_edge(clk)) then
			nd_q <= nd;
			fd_q <= fd;
			dq(  0) <= d( 28) xor d( 26) xor d( 23) xor d( 22) xor d( 21) xor d( 19) xor d( 18) xor d( 17) xor d( 14) xor d( 13) xor d( 10) xor d(  8) xor d(  6) xor d(  5) xor d(  4) xor d(  0);
			dq(  1) <= d( 29) xor d( 28) xor d( 27) xor d( 26) xor d( 24) xor d( 21) xor d( 20) xor d( 17) xor d( 15) xor d( 13) xor d( 11) xor d( 10) xor d(  9) xor d(  8) xor d(  7) xor d(  4) xor d(  1) xor d(  0);
			dq(  2) <= d( 30) xor d( 29) xor d( 28) xor d( 27) xor d( 25) xor d( 22) xor d( 21) xor d( 18) xor d( 16) xor d( 14) xor d( 12) xor d( 11) xor d( 10) xor d(  9) xor d(  8) xor d(  5) xor d(  2) xor d(  1);
			dq(  3) <= d( 31) xor d( 30) xor d( 29) xor d( 21) xor d( 18) xor d( 15) xor d( 14) xor d( 12) xor d( 11) xor d(  9) xor d(  8) xor d(  5) xor d(  4) xor d(  3) xor d(  2) xor d(  0);
			dq(  4) <= d( 31) xor d( 30) xor d( 22) xor d( 19) xor d( 16) xor d( 15) xor d( 13) xor d( 12) xor d( 10) xor d(  9) xor d(  6) xor d(  5) xor d(  4) xor d(  3) xor d(  1);
			dq(  5) <= d( 31) xor d( 28) xor d( 26) xor d( 22) xor d( 21) xor d( 20) xor d( 19) xor d( 18) xor d( 16) xor d( 11) xor d(  8) xor d(  7) xor d(  2) xor d(  0);
			dq(  6) <= d( 29) xor d( 27) xor d( 23) xor d( 22) xor d( 21) xor d( 20) xor d( 19) xor d( 17) xor d( 12) xor d(  9) xor d(  8) xor d(  3) xor d(  1);
			dq(  7) <= d( 30) xor d( 28) xor d( 24) xor d( 23) xor d( 22) xor d( 21) xor d( 20) xor d( 18) xor d( 13) xor d( 10) xor d(  9) xor d(  4) xor d(  2);
			dq(  8) <= d( 31) xor d( 29) xor d( 25) xor d( 24) xor d( 23) xor d( 22) xor d( 21) xor d( 19) xor d( 14) xor d( 11) xor d( 10) xor d(  5) xor d(  3);
			dq(  9) <= d( 30) xor d( 28) xor d( 25) xor d( 24) xor d( 21) xor d( 20) xor d( 19) xor d( 18) xor d( 17) xor d( 15) xor d( 14) xor d( 13) xor d( 12) xor d( 11) xor d( 10) xor d(  8) xor d(  5) xor d(  0);
			dq( 10) <= d( 31) xor d( 29) xor d( 28) xor d( 25) xor d( 23) xor d( 20) xor d( 17) xor d( 16) xor d( 15) xor d( 12) xor d( 11) xor d( 10) xor d(  9) xor d(  8) xor d(  5) xor d(  4) xor d(  1) xor d(  0);
			dq( 11) <= d( 30) xor d( 29) xor d( 26) xor d( 24) xor d( 21) xor d( 18) xor d( 17) xor d( 16) xor d( 13) xor d( 12) xor d( 11) xor d( 10) xor d(  9) xor d(  6) xor d(  5) xor d(  2) xor d(  1);
			dq( 12) <= d( 31) xor d( 30) xor d( 27) xor d( 25) xor d( 22) xor d( 19) xor d( 18) xor d( 17) xor d( 14) xor d( 13) xor d( 12) xor d( 11) xor d( 10) xor d(  7) xor d(  6) xor d(  3) xor d(  2);
			dq( 13) <= d( 31) xor d( 22) xor d( 21) xor d( 20) xor d( 17) xor d( 15) xor d( 12) xor d( 11) xor d( 10) xor d(  7) xor d(  6) xor d(  5) xor d(  3) xor d(  0);
			dq( 14) <= d( 28) xor d( 26) xor d( 19) xor d( 17) xor d( 16) xor d( 14) xor d( 12) xor d( 11) xor d( 10) xor d(  7) xor d(  5) xor d(  1) xor d(  0);
			dq( 15) <= d( 29) xor d( 27) xor d( 20) xor d( 18) xor d( 17) xor d( 15) xor d( 13) xor d( 12) xor d( 11) xor d(  8) xor d(  6) xor d(  2) xor d(  1);
			dq( 16) <= d( 30) xor d( 26) xor d( 23) xor d( 22) xor d( 17) xor d( 16) xor d( 12) xor d( 10) xor d(  9) xor d(  8) xor d(  7) xor d(  6) xor d(  5) xor d(  4) xor d(  3) xor d(  2) xor d(  0);
			dq( 17) <= d( 31) xor d( 27) xor d( 24) xor d( 23) xor d( 18) xor d( 17) xor d( 13) xor d( 11) xor d( 10) xor d(  9) xor d(  8) xor d(  7) xor d(  6) xor d(  5) xor d(  4) xor d(  3) xor d(  1);
			dq( 18) <= d( 28) xor d( 25) xor d( 24) xor d( 19) xor d( 18) xor d( 14) xor d( 12) xor d( 11) xor d( 10) xor d(  9) xor d(  8) xor d(  7) xor d(  6) xor d(  5) xor d(  4) xor d(  2);
			dq( 19) <= d( 29) xor d( 28) xor d( 25) xor d( 23) xor d( 22) xor d( 21) xor d( 20) xor d( 18) xor d( 17) xor d( 15) xor d( 14) xor d( 12) xor d( 11) xor d(  9) xor d(  7) xor d(  4) xor d(  3) xor d(  0);
			dq( 20) <= d( 30) xor d( 29) xor d( 28) xor d( 24) xor d( 17) xor d( 16) xor d( 15) xor d( 14) xor d( 12) xor d(  6) xor d(  1) xor d(  0);
			dq( 21) <= d( 31) xor d( 30) xor d( 29) xor d( 28) xor d( 26) xor d( 25) xor d( 23) xor d( 22) xor d( 21) xor d( 19) xor d( 16) xor d( 15) xor d( 14) xor d( 10) xor d(  8) xor d(  7) xor d(  6) xor d(  5) xor d(  4) xor d(  2) xor d(  1) xor d(  0);
			dq( 22) <= d( 31) xor d( 30) xor d( 29) xor d( 28) xor d( 27) xor d( 24) xor d( 21) xor d( 20) xor d( 19) xor d( 18) xor d( 16) xor d( 15) xor d( 14) xor d( 13) xor d( 11) xor d( 10) xor d(  9) xor d(  7) xor d(  4) xor d(  3) xor d(  2) xor d(  1) xor d(  0);
			dq( 23) <= d( 31) xor d( 30) xor d( 29) xor d( 26) xor d( 25) xor d( 23) xor d( 20) xor d( 18) xor d( 16) xor d( 15) xor d( 13) xor d( 12) xor d( 11) xor d(  6) xor d(  3) xor d(  2) xor d(  1) xor d(  0);
			dq( 24) <= d( 31) xor d( 30) xor d( 27) xor d( 26) xor d( 24) xor d( 21) xor d( 19) xor d( 17) xor d( 16) xor d( 14) xor d( 13) xor d( 12) xor d(  7) xor d(  4) xor d(  3) xor d(  2) xor d(  1);
			dq( 25) <= d( 31) xor d( 28) xor d( 27) xor d( 25) xor d( 22) xor d( 20) xor d( 18) xor d( 17) xor d( 15) xor d( 14) xor d( 13) xor d(  8) xor d(  5) xor d(  4) xor d(  3) xor d(  2);
			dq( 26) <= d( 29) xor d( 22) xor d( 17) xor d( 16) xor d( 15) xor d( 13) xor d( 10) xor d(  9) xor d(  8) xor d(  3) xor d(  0);
			dq( 27) <= d( 30) xor d( 23) xor d( 18) xor d( 17) xor d( 16) xor d( 14) xor d( 11) xor d( 10) xor d(  9) xor d(  4) xor d(  1);
			dq( 28) <= d( 31) xor d( 24) xor d( 19) xor d( 18) xor d( 17) xor d( 15) xor d( 12) xor d( 11) xor d( 10) xor d(  5) xor d(  2);
			dq( 29) <= d( 25) xor d( 20) xor d( 19) xor d( 18) xor d( 16) xor d( 13) xor d( 12) xor d( 11) xor d(  6) xor d(  3);
			dq( 30) <= d( 26) xor d( 21) xor d( 20) xor d( 19) xor d( 17) xor d( 14) xor d( 13) xor d( 12) xor d(  7) xor d(  4);
			dq( 31) <= d( 27) xor d( 22) xor d( 21) xor d( 20) xor d( 18) xor d( 15) xor d( 14) xor d( 13) xor d(  8) xor d(  5);
			dq( 32) <= d( 26) xor d( 18) xor d( 17) xor d( 16) xor d( 15) xor d( 13) xor d( 10) xor d(  9) xor d(  8) xor d(  5) xor d(  4) xor d(  0);
			dq( 33) <= d( 27) xor d( 19) xor d( 18) xor d( 17) xor d( 16) xor d( 14) xor d( 11) xor d( 10) xor d(  9) xor d(  6) xor d(  5) xor d(  1);
			dq( 34) <= d( 26) xor d( 23) xor d( 22) xor d( 21) xor d( 20) xor d( 15) xor d( 14) xor d( 13) xor d( 12) xor d( 11) xor d(  8) xor d(  7) xor d(  5) xor d(  4) xor d(  2) xor d(  0);
			dq( 35) <= d( 27) xor d( 24) xor d( 23) xor d( 22) xor d( 21) xor d( 16) xor d( 15) xor d( 14) xor d( 13) xor d( 12) xor d(  9) xor d(  8) xor d(  6) xor d(  5) xor d(  3) xor d(  1);
			dq( 36) <= d( 26) xor d( 25) xor d( 24) xor d( 21) xor d( 19) xor d( 18) xor d( 16) xor d( 15) xor d(  9) xor d(  8) xor d(  7) xor d(  5) xor d(  2) xor d(  0);
			dq( 37) <= d( 28) xor d( 27) xor d( 25) xor d( 23) xor d( 21) xor d( 20) xor d( 18) xor d( 16) xor d( 14) xor d( 13) xor d(  9) xor d(  5) xor d(  4) xor d(  3) xor d(  1) xor d(  0);
			dq( 38) <= d( 29) xor d( 24) xor d( 23) xor d( 18) xor d( 15) xor d( 13) xor d(  8) xor d(  2) xor d(  1) xor d(  0);
			dq( 39) <= d( 30) xor d( 25) xor d( 24) xor d( 19) xor d( 16) xor d( 14) xor d(  9) xor d(  3) xor d(  2) xor d(  1);
			dq( 40) <= d( 31) xor d( 28) xor d( 25) xor d( 23) xor d( 22) xor d( 21) xor d( 20) xor d( 19) xor d( 18) xor d( 15) xor d( 14) xor d( 13) xor d(  8) xor d(  6) xor d(  5) xor d(  3) xor d(  2) xor d(  0);
			dq( 41) <= d( 29) xor d( 26) xor d( 24) xor d( 23) xor d( 22) xor d( 21) xor d( 20) xor d( 19) xor d( 16) xor d( 15) xor d( 14) xor d(  9) xor d(  7) xor d(  6) xor d(  4) xor d(  3) xor d(  1);
			dq( 42) <= d( 30) xor d( 28) xor d( 27) xor d( 26) xor d( 25) xor d( 24) xor d( 20) xor d( 19) xor d( 18) xor d( 16) xor d( 15) xor d( 14) xor d( 13) xor d(  7) xor d(  6) xor d(  2) xor d(  0);
			dq( 43) <= d( 31) xor d( 29) xor d( 27) xor d( 25) xor d( 23) xor d( 22) xor d( 20) xor d( 18) xor d( 16) xor d( 15) xor d( 13) xor d( 10) xor d(  7) xor d(  6) xor d(  5) xor d(  4) xor d(  3) xor d(  1) xor d(  0);
			dq( 44) <= d( 30) xor d( 28) xor d( 26) xor d( 24) xor d( 23) xor d( 21) xor d( 19) xor d( 17) xor d( 16) xor d( 14) xor d( 11) xor d(  8) xor d(  7) xor d(  6) xor d(  5) xor d(  4) xor d(  2) xor d(  1);
			dq( 45) <= d( 31) xor d( 29) xor d( 28) xor d( 27) xor d( 26) xor d( 25) xor d( 24) xor d( 23) xor d( 21) xor d( 20) xor d( 19) xor d( 15) xor d( 14) xor d( 13) xor d( 12) xor d( 10) xor d(  9) xor d(  7) xor d(  4) xor d(  3) xor d(  2) xor d(  0);
			dq( 46) <= d( 30) xor d( 29) xor d( 27) xor d( 25) xor d( 24) xor d( 23) xor d( 20) xor d( 19) xor d( 18) xor d( 17) xor d( 16) xor d( 15) xor d( 11) xor d(  6) xor d(  3) xor d(  1) xor d(  0);
			dq( 47) <= d( 31) xor d( 30) xor d( 28) xor d( 26) xor d( 25) xor d( 24) xor d( 21) xor d( 20) xor d( 19) xor d( 18) xor d( 17) xor d( 16) xor d( 12) xor d(  7) xor d(  4) xor d(  2) xor d(  1);
			dq( 48) <= d( 31) xor d( 29) xor d( 27) xor d( 26) xor d( 25) xor d( 22) xor d( 21) xor d( 20) xor d( 19) xor d( 18) xor d( 17) xor d( 13) xor d(  8) xor d(  5) xor d(  3) xor d(  2);
			dq( 49) <= d( 30) xor d( 28) xor d( 27) xor d( 26) xor d( 23) xor d( 22) xor d( 21) xor d( 20) xor d( 19) xor d( 18) xor d( 14) xor d(  9) xor d(  6) xor d(  4) xor d(  3);
			dq( 50) <= d( 31) xor d( 29) xor d( 27) xor d( 26) xor d( 24) xor d( 20) xor d( 18) xor d( 17) xor d( 15) xor d( 14) xor d( 13) xor d(  8) xor d(  7) xor d(  6) xor d(  0);
			dq( 51) <= d( 30) xor d( 27) xor d( 26) xor d( 25) xor d( 23) xor d( 22) xor d( 17) xor d( 16) xor d( 15) xor d( 13) xor d( 10) xor d(  9) xor d(  7) xor d(  6) xor d(  5) xor d(  4) xor d(  1) xor d(  0);
			dq( 52) <= d( 31) xor d( 27) xor d( 24) xor d( 22) xor d( 21) xor d( 19) xor d( 16) xor d( 13) xor d( 11) xor d(  7) xor d(  4) xor d(  2) xor d(  1) xor d(  0);
			dq( 53) <= d( 26) xor d( 25) xor d( 21) xor d( 20) xor d( 19) xor d( 18) xor d( 13) xor d( 12) xor d( 10) xor d(  6) xor d(  4) xor d(  3) xor d(  2) xor d(  1) xor d(  0);
			dq( 54) <= d( 28) xor d( 27) xor d( 23) xor d( 20) xor d( 18) xor d( 17) xor d( 11) xor d( 10) xor d(  8) xor d(  7) xor d(  6) xor d(  3) xor d(  2) xor d(  1) xor d(  0);
			dq( 55) <= d( 29) xor d( 26) xor d( 24) xor d( 23) xor d( 22) xor d( 17) xor d( 14) xor d( 13) xor d( 12) xor d( 11) xor d( 10) xor d(  9) xor d(  7) xor d(  6) xor d(  5) xor d(  3) xor d(  2) xor d(  1) xor d(  0);
			dq( 56) <= d( 30) xor d( 28) xor d( 27) xor d( 26) xor d( 25) xor d( 24) xor d( 22) xor d( 21) xor d( 19) xor d( 17) xor d( 15) xor d( 12) xor d( 11) xor d(  7) xor d(  5) xor d(  3) xor d(  2) xor d(  1) xor d(  0);
			dq( 57) <= d( 31) xor d( 29) xor d( 28) xor d( 27) xor d( 26) xor d( 25) xor d( 23) xor d( 22) xor d( 20) xor d( 18) xor d( 16) xor d( 13) xor d( 12) xor d(  8) xor d(  6) xor d(  4) xor d(  3) xor d(  2) xor d(  1);
			dq( 58) <= d( 30) xor d( 29) xor d( 28) xor d( 27) xor d( 26) xor d( 24) xor d( 23) xor d( 21) xor d( 19) xor d( 17) xor d( 14) xor d( 13) xor d(  9) xor d(  7) xor d(  5) xor d(  4) xor d(  3) xor d(  2);
			dq( 59) <= d( 31) xor d( 30) xor d( 29) xor d( 27) xor d( 26) xor d( 25) xor d( 24) xor d( 23) xor d( 21) xor d( 20) xor d( 19) xor d( 17) xor d( 15) xor d( 13) xor d(  3) xor d(  0);
			dq( 60) <= d( 31) xor d( 30) xor d( 27) xor d( 25) xor d( 24) xor d( 23) xor d( 20) xor d( 19) xor d( 17) xor d( 16) xor d( 13) xor d( 10) xor d(  8) xor d(  6) xor d(  5) xor d(  1) xor d(  0);
			dq( 61) <= d( 31) xor d( 28) xor d( 26) xor d( 25) xor d( 24) xor d( 21) xor d( 20) xor d( 18) xor d( 17) xor d( 14) xor d( 11) xor d(  9) xor d(  7) xor d(  6) xor d(  2) xor d(  1);
			dq( 62) <= d( 29) xor d( 27) xor d( 26) xor d( 25) xor d( 22) xor d( 21) xor d( 19) xor d( 18) xor d( 15) xor d( 12) xor d( 10) xor d(  8) xor d(  7) xor d(  3) xor d(  2);
			dq( 63) <= d( 30) xor d( 28) xor d( 27) xor d( 26) xor d( 23) xor d( 22) xor d( 20) xor d( 19) xor d( 16) xor d( 13) xor d( 11) xor d(  9) xor d(  8) xor d(  4) xor d(  3);
			dq( 64) <= d( 31) xor d( 29) xor d( 27) xor d( 26) xor d( 24) xor d( 22) xor d( 20) xor d( 19) xor d( 18) xor d( 13) xor d( 12) xor d(  9) xor d(  8) xor d(  6) xor d(  0);
			dq( 65) <= d( 30) xor d( 28) xor d( 27) xor d( 25) xor d( 23) xor d( 21) xor d( 20) xor d( 19) xor d( 14) xor d( 13) xor d( 10) xor d(  9) xor d(  7) xor d(  1);
			dq( 66) <= d( 31) xor d( 29) xor d( 24) xor d( 23) xor d( 20) xor d( 19) xor d( 18) xor d( 17) xor d( 15) xor d( 13) xor d( 11) xor d(  6) xor d(  5) xor d(  4) xor d(  2) xor d(  0);
			dq( 67) <= d( 30) xor d( 28) xor d( 26) xor d( 25) xor d( 24) xor d( 23) xor d( 22) xor d( 20) xor d( 17) xor d( 16) xor d( 13) xor d( 12) xor d( 10) xor d(  8) xor d(  7) xor d(  4) xor d(  3) xor d(  1) xor d(  0);
			dq( 68) <= d( 31) xor d( 29) xor d( 28) xor d( 27) xor d( 25) xor d( 24) xor d( 22) xor d( 19) xor d( 11) xor d( 10) xor d(  9) xor d(  6) xor d(  2) xor d(  1) xor d(  0);
			dq( 69) <= d( 30) xor d( 29) xor d( 25) xor d( 22) xor d( 21) xor d( 20) xor d( 19) xor d( 18) xor d( 17) xor d( 14) xor d( 13) xor d( 12) xor d( 11) xor d(  8) xor d(  7) xor d(  6) xor d(  5) xor d(  4) xor d(  3) xor d(  2) xor d(  1) xor d(  0);
			dq( 70) <= d( 31) xor d( 30) xor d( 26) xor d( 23) xor d( 22) xor d( 21) xor d( 20) xor d( 19) xor d( 18) xor d( 15) xor d( 14) xor d( 13) xor d( 12) xor d(  9) xor d(  8) xor d(  7) xor d(  6) xor d(  5) xor d(  4) xor d(  3) xor d(  2) xor d(  1);
			dq( 71) <= d( 31) xor d( 28) xor d( 27) xor d( 26) xor d( 24) xor d( 20) xor d( 18) xor d( 17) xor d( 16) xor d( 15) xor d(  9) xor d(  7) xor d(  3) xor d(  2) xor d(  0);
			dq( 72) <= d( 29) xor d( 27) xor d( 26) xor d( 25) xor d( 23) xor d( 22) xor d( 16) xor d( 14) xor d( 13) xor d(  6) xor d(  5) xor d(  3) xor d(  1) xor d(  0);
			dq( 73) <= d( 30) xor d( 27) xor d( 24) xor d( 22) xor d( 21) xor d( 19) xor d( 18) xor d( 15) xor d( 13) xor d( 10) xor d(  8) xor d(  7) xor d(  5) xor d(  2) xor d(  1) xor d(  0);
			dq( 74) <= d( 31) xor d( 26) xor d( 25) xor d( 21) xor d( 20) xor d( 18) xor d( 17) xor d( 16) xor d( 13) xor d( 11) xor d( 10) xor d(  9) xor d(  5) xor d(  4) xor d(  3) xor d(  2) xor d(  1) xor d(  0);
			dq( 75) <= d( 27) xor d( 26) xor d( 22) xor d( 21) xor d( 19) xor d( 18) xor d( 17) xor d( 14) xor d( 12) xor d( 11) xor d( 10) xor d(  6) xor d(  5) xor d(  4) xor d(  3) xor d(  2) xor d(  1);
			dq( 76) <= d( 27) xor d( 26) xor d( 21) xor d( 20) xor d( 17) xor d( 15) xor d( 14) xor d( 12) xor d( 11) xor d( 10) xor d(  8) xor d(  7) xor d(  3) xor d(  2) xor d(  0);
			dq( 77) <= d( 28) xor d( 27) xor d( 22) xor d( 21) xor d( 18) xor d( 16) xor d( 15) xor d( 13) xor d( 12) xor d( 11) xor d(  9) xor d(  8) xor d(  4) xor d(  3) xor d(  1);
			dq( 78) <= d( 29) xor d( 28) xor d( 23) xor d( 22) xor d( 19) xor d( 17) xor d( 16) xor d( 14) xor d( 13) xor d( 12) xor d( 10) xor d(  9) xor d(  5) xor d(  4) xor d(  2);
			dq( 79) <= d( 30) xor d( 29) xor d( 28) xor d( 26) xor d( 24) xor d( 22) xor d( 21) xor d( 20) xor d( 19) xor d( 15) xor d( 11) xor d(  8) xor d(  4) xor d(  3) xor d(  0);
			dq( 80) <= d( 31) xor d( 30) xor d( 29) xor d( 28) xor d( 27) xor d( 26) xor d( 25) xor d( 20) xor d( 19) xor d( 18) xor d( 17) xor d( 16) xor d( 14) xor d( 13) xor d( 12) xor d( 10) xor d(  9) xor d(  8) xor d(  6) xor d(  1) xor d(  0);
			dq( 81) <= d( 31) xor d( 30) xor d( 29) xor d( 27) xor d( 23) xor d( 22) xor d( 20) xor d( 15) xor d( 11) xor d(  9) xor d(  8) xor d(  7) xor d(  6) xor d(  5) xor d(  4) xor d(  2) xor d(  1) xor d(  0);
			dq( 82) <= d( 31) xor d( 30) xor d( 26) xor d( 24) xor d( 22) xor d( 19) xor d( 18) xor d( 17) xor d( 16) xor d( 14) xor d( 13) xor d( 12) xor d(  9) xor d(  7) xor d(  4) xor d(  3) xor d(  2) xor d(  1) xor d(  0);
			dq( 83) <= d( 31) xor d( 27) xor d( 25) xor d( 23) xor d( 20) xor d( 19) xor d( 18) xor d( 17) xor d( 15) xor d( 14) xor d( 13) xor d( 10) xor d(  8) xor d(  5) xor d(  4) xor d(  3) xor d(  2) xor d(  1);
			dq( 84) <= d( 28) xor d( 26) xor d( 24) xor d( 21) xor d( 20) xor d( 19) xor d( 18) xor d( 16) xor d( 15) xor d( 14) xor d( 11) xor d(  9) xor d(  6) xor d(  5) xor d(  4) xor d(  3) xor d(  2);
			dq( 85) <= d( 29) xor d( 28) xor d( 27) xor d( 26) xor d( 25) xor d( 23) xor d( 20) xor d( 18) xor d( 16) xor d( 15) xor d( 14) xor d( 13) xor d( 12) xor d(  8) xor d(  7) xor d(  3) xor d(  0);
			dq( 86) <= d( 30) xor d( 29) xor d( 28) xor d( 27) xor d( 26) xor d( 24) xor d( 21) xor d( 19) xor d( 17) xor d( 16) xor d( 15) xor d( 14) xor d( 13) xor d(  9) xor d(  8) xor d(  4) xor d(  1);
			dq( 87) <= d( 31) xor d( 30) xor d( 29) xor d( 28) xor d( 27) xor d( 25) xor d( 22) xor d( 20) xor d( 18) xor d( 17) xor d( 16) xor d( 15) xor d( 14) xor d( 10) xor d(  9) xor d(  5) xor d(  2);
			dq( 88) <= d( 31) xor d( 30) xor d( 29) xor d( 22) xor d( 16) xor d( 15) xor d( 14) xor d( 13) xor d( 11) xor d(  8) xor d(  5) xor d(  4) xor d(  3) xor d(  0);
			dq( 89) <= d( 31) xor d( 30) xor d( 23) xor d( 17) xor d( 16) xor d( 15) xor d( 14) xor d( 12) xor d(  9) xor d(  6) xor d(  5) xor d(  4) xor d(  1);
			dq( 90) <= d( 31) xor d( 24) xor d( 18) xor d( 17) xor d( 16) xor d( 15) xor d( 13) xor d( 10) xor d(  7) xor d(  6) xor d(  5) xor d(  2);
			dq( 91) <= d( 25) xor d( 19) xor d( 18) xor d( 17) xor d( 16) xor d( 14) xor d( 11) xor d(  8) xor d(  7) xor d(  6) xor d(  3);
			dq( 92) <= d( 28) xor d( 23) xor d( 22) xor d( 21) xor d( 20) xor d( 15) xor d( 14) xor d( 13) xor d( 12) xor d( 10) xor d(  9) xor d(  7) xor d(  6) xor d(  5) xor d(  0);
			dq( 93) <= d( 29) xor d( 28) xor d( 26) xor d( 24) xor d( 19) xor d( 18) xor d( 17) xor d( 16) xor d( 15) xor d( 11) xor d(  7) xor d(  5) xor d(  4) xor d(  1) xor d(  0);
			dq( 94) <= d( 30) xor d( 29) xor d( 28) xor d( 27) xor d( 26) xor d( 25) xor d( 23) xor d( 22) xor d( 21) xor d( 20) xor d( 16) xor d( 14) xor d( 13) xor d( 12) xor d( 10) xor d(  4) xor d(  2) xor d(  1) xor d(  0);
			dq( 95) <= d( 31) xor d( 30) xor d( 29) xor d( 28) xor d( 27) xor d( 26) xor d( 24) xor d( 23) xor d( 22) xor d( 21) xor d( 17) xor d( 15) xor d( 14) xor d( 13) xor d( 11) xor d(  5) xor d(  3) xor d(  2) xor d(  1);
			dq( 96) <= d( 31) xor d( 30) xor d( 29) xor d( 27) xor d( 26) xor d( 25) xor d( 24) xor d( 21) xor d( 19) xor d( 17) xor d( 16) xor d( 15) xor d( 13) xor d( 12) xor d( 10) xor d(  8) xor d(  5) xor d(  3) xor d(  2) xor d(  0);
			dq( 97) <= d( 31) xor d( 30) xor d( 27) xor d( 25) xor d( 23) xor d( 21) xor d( 20) xor d( 19) xor d( 16) xor d( 11) xor d( 10) xor d(  9) xor d(  8) xor d(  5) xor d(  3) xor d(  1) xor d(  0);
			dq( 98) <= d( 31) xor d( 24) xor d( 23) xor d( 20) xor d( 19) xor d( 18) xor d( 14) xor d( 13) xor d( 12) xor d( 11) xor d(  9) xor d(  8) xor d(  5) xor d(  2) xor d(  1) xor d(  0);
			dq( 99) <= d( 28) xor d( 26) xor d( 25) xor d( 24) xor d( 23) xor d( 22) xor d( 20) xor d( 18) xor d( 17) xor d( 15) xor d( 12) xor d(  9) xor d(  8) xor d(  5) xor d(  4) xor d(  3) xor d(  2) xor d(  1) xor d(  0);
			dq(100) <= d( 29) xor d( 28) xor d( 27) xor d( 25) xor d( 24) xor d( 22) xor d( 17) xor d( 16) xor d( 14) xor d(  9) xor d(  8) xor d(  3) xor d(  2) xor d(  1) xor d(  0);
			dq(101) <= d( 30) xor d( 29) xor d( 28) xor d( 26) xor d( 25) xor d( 23) xor d( 18) xor d( 17) xor d( 15) xor d( 10) xor d(  9) xor d(  4) xor d(  3) xor d(  2) xor d(  1);
			dq(102) <= d( 31) xor d( 30) xor d( 29) xor d( 28) xor d( 27) xor d( 24) xor d( 23) xor d( 22) xor d( 21) xor d( 17) xor d( 16) xor d( 14) xor d( 13) xor d( 11) xor d(  8) xor d(  6) xor d(  3) xor d(  2) xor d(  0);
			dq(103) <= d( 31) xor d( 30) xor d( 29) xor d( 28) xor d( 25) xor d( 24) xor d( 23) xor d( 22) xor d( 18) xor d( 17) xor d( 15) xor d( 14) xor d( 12) xor d(  9) xor d(  7) xor d(  4) xor d(  3) xor d(  1);
			dq(104) <= d( 31) xor d( 30) xor d( 29) xor d( 28) xor d( 25) xor d( 24) xor d( 22) xor d( 21) xor d( 17) xor d( 16) xor d( 15) xor d( 14) xor d(  6) xor d(  2) xor d(  0);
			dq(105) <= d( 31) xor d( 30) xor d( 29) xor d( 26) xor d( 25) xor d( 23) xor d( 22) xor d( 18) xor d( 17) xor d( 16) xor d( 15) xor d(  7) xor d(  3) xor d(  1);
			dq(106) <= d( 31) xor d( 30) xor d( 28) xor d( 27) xor d( 24) xor d( 22) xor d( 21) xor d( 16) xor d( 14) xor d( 13) xor d( 10) xor d(  6) xor d(  5) xor d(  2) xor d(  0);
			dq(107) <= d( 31) xor d( 29) xor d( 28) xor d( 25) xor d( 23) xor d( 22) xor d( 17) xor d( 15) xor d( 14) xor d( 11) xor d(  7) xor d(  6) xor d(  3) xor d(  1);
			dq(108) <= d( 30) xor d( 29) xor d( 26) xor d( 24) xor d( 23) xor d( 18) xor d( 16) xor d( 15) xor d( 12) xor d(  8) xor d(  7) xor d(  4) xor d(  2);
			dq(109) <= d( 31) xor d( 30) xor d( 28) xor d( 27) xor d( 26) xor d( 25) xor d( 24) xor d( 23) xor d( 22) xor d( 21) xor d( 18) xor d( 16) xor d( 14) xor d( 10) xor d(  9) xor d(  6) xor d(  4) xor d(  3) xor d(  0);
			dq(110) <= d( 31) xor d( 29) xor d( 28) xor d( 27) xor d( 26) xor d( 25) xor d( 24) xor d( 23) xor d( 22) xor d( 19) xor d( 17) xor d( 15) xor d( 11) xor d( 10) xor d(  7) xor d(  5) xor d(  4) xor d(  1);
			dq(111) <= d( 30) xor d( 29) xor d( 28) xor d( 27) xor d( 26) xor d( 25) xor d( 24) xor d( 23) xor d( 20) xor d( 18) xor d( 16) xor d( 12) xor d( 11) xor d(  8) xor d(  6) xor d(  5) xor d(  2);
			dq(112) <= d( 31) xor d( 30) xor d( 29) xor d( 27) xor d( 25) xor d( 24) xor d( 23) xor d( 22) xor d( 18) xor d( 14) xor d( 12) xor d( 10) xor d(  9) xor d(  8) xor d(  7) xor d(  5) xor d(  4) xor d(  3) xor d(  0);
			dq(113) <= d( 31) xor d( 30) xor d( 25) xor d( 24) xor d( 22) xor d( 21) xor d( 18) xor d( 17) xor d( 15) xor d( 14) xor d( 11) xor d(  9) xor d(  1) xor d(  0);
			dq(114) <= d( 31) xor d( 28) xor d( 25) xor d( 21) xor d( 17) xor d( 16) xor d( 15) xor d( 14) xor d( 13) xor d( 12) xor d(  8) xor d(  6) xor d(  5) xor d(  4) xor d(  2) xor d(  1) xor d(  0);
			dq(115) <= d( 29) xor d( 26) xor d( 22) xor d( 18) xor d( 17) xor d( 16) xor d( 15) xor d( 14) xor d( 13) xor d(  9) xor d(  7) xor d(  6) xor d(  5) xor d(  3) xor d(  2) xor d(  1);
			dq(116) <= d( 30) xor d( 27) xor d( 23) xor d( 19) xor d( 18) xor d( 17) xor d( 16) xor d( 15) xor d( 14) xor d( 10) xor d(  8) xor d(  7) xor d(  6) xor d(  4) xor d(  3) xor d(  2);
			dq(117) <= d( 31) xor d( 28) xor d( 24) xor d( 20) xor d( 19) xor d( 18) xor d( 17) xor d( 16) xor d( 15) xor d( 11) xor d(  9) xor d(  8) xor d(  7) xor d(  5) xor d(  4) xor d(  3);
			dq(118) <= d( 29) xor d( 25) xor d( 21) xor d( 20) xor d( 19) xor d( 18) xor d( 17) xor d( 16) xor d( 12) xor d( 10) xor d(  9) xor d(  8) xor d(  6) xor d(  5) xor d(  4);
			dq(119) <= d( 30) xor d( 26) xor d( 22) xor d( 21) xor d( 20) xor d( 19) xor d( 18) xor d( 17) xor d( 13) xor d( 11) xor d( 10) xor d(  9) xor d(  7) xor d(  6) xor d(  5);
			dq(120) <= d( 31) xor d( 27) xor d( 23) xor d( 22) xor d( 21) xor d( 20) xor d( 19) xor d( 18) xor d( 14) xor d( 12) xor d( 11) xor d( 10) xor d(  8) xor d(  7) xor d(  6);
			dq(121) <= d( 28) xor d( 24) xor d( 23) xor d( 22) xor d( 21) xor d( 20) xor d( 19) xor d( 15) xor d( 13) xor d( 12) xor d( 11) xor d(  9) xor d(  8) xor d(  7);
			dq(122) <= d( 29) xor d( 28) xor d( 26) xor d( 25) xor d( 24) xor d( 20) xor d( 19) xor d( 18) xor d( 17) xor d( 16) xor d( 12) xor d(  9) xor d(  6) xor d(  5) xor d(  4) xor d(  0);
			dq(123) <= d( 30) xor d( 29) xor d( 28) xor d( 27) xor d( 25) xor d( 23) xor d( 22) xor d( 20) xor d( 14) xor d(  8) xor d(  7) xor d(  4) xor d(  1) xor d(  0);
			dq(124) <= d( 31) xor d( 30) xor d( 29) xor d( 24) xor d( 22) xor d( 19) xor d( 18) xor d( 17) xor d( 15) xor d( 14) xor d( 13) xor d( 10) xor d(  9) xor d(  6) xor d(  4) xor d(  2) xor d(  1) xor d(  0);
			dq(125) <= d( 31) xor d( 30) xor d( 25) xor d( 23) xor d( 20) xor d( 19) xor d( 18) xor d( 16) xor d( 15) xor d( 14) xor d( 11) xor d( 10) xor d(  7) xor d(  5) xor d(  3) xor d(  2) xor d(  1);
			dq(126) <= d( 31) xor d( 26) xor d( 24) xor d( 21) xor d( 20) xor d( 19) xor d( 17) xor d( 16) xor d( 15) xor d( 12) xor d( 11) xor d(  8) xor d(  6) xor d(  4) xor d(  3) xor d(  2);
			dq(127) <= d( 27) xor d( 25) xor d( 22) xor d( 21) xor d( 20) xor d( 18) xor d( 17) xor d( 16) xor d( 13) xor d( 12) xor d(  9) xor d(  7) xor d(  5) xor d(  4) xor d(  3);

		end if;
	end process;

	process (clk, reset)
	begin
		if (reset= '1') then
			ca <= SEED;
			rdy <= '0';
		elsif (rising_edge(clk)) then
			rdy <= nd_q;
			if(nd_q= '1') then
				if (fd_q= '1') then
					ca(  0) <= SEED( 96) xor SEED(100) xor SEED(101) xor SEED(102) xor SEED(104) xor SEED(106) xor SEED(109) xor SEED(110) xor SEED(113) xor SEED(114) xor SEED(115) xor SEED(117) xor SEED(118) xor SEED(119) xor SEED(122) xor SEED(124) xor dq(  0);
					ca(  1) <= SEED( 96) xor SEED( 97) xor SEED(100) xor SEED(103) xor SEED(104) xor SEED(105) xor SEED(106) xor SEED(107) xor SEED(109) xor SEED(111) xor SEED(113) xor SEED(116) xor SEED(117) xor SEED(120) xor SEED(122) xor SEED(123) xor SEED(124) xor SEED(125) xor dq(  1);
					ca(  2) <= SEED( 97) xor SEED( 98) xor SEED(101) xor SEED(104) xor SEED(105) xor SEED(106) xor SEED(107) xor SEED(108) xor SEED(110) xor SEED(112) xor SEED(114) xor SEED(117) xor SEED(118) xor SEED(121) xor SEED(123) xor SEED(124) xor SEED(125) xor SEED(126) xor dq(  2);
					ca(  3) <= SEED( 96) xor SEED( 98) xor SEED( 99) xor SEED(100) xor SEED(101) xor SEED(104) xor SEED(105) xor SEED(107) xor SEED(108) xor SEED(110) xor SEED(111) xor SEED(114) xor SEED(117) xor SEED(125) xor SEED(126) xor SEED(127) xor dq(  3);
					ca(  4) <= SEED( 97) xor SEED( 99) xor SEED(100) xor SEED(101) xor SEED(102) xor SEED(105) xor SEED(106) xor SEED(108) xor SEED(109) xor SEED(111) xor SEED(112) xor SEED(115) xor SEED(118) xor SEED(126) xor SEED(127) xor dq(  4);
					ca(  5) <= SEED( 96) xor SEED( 98) xor SEED(103) xor SEED(104) xor SEED(107) xor SEED(112) xor SEED(114) xor SEED(115) xor SEED(116) xor SEED(117) xor SEED(118) xor SEED(122) xor SEED(124) xor SEED(127) xor dq(  5);
					ca(  6) <= SEED( 97) xor SEED( 99) xor SEED(104) xor SEED(105) xor SEED(108) xor SEED(113) xor SEED(115) xor SEED(116) xor SEED(117) xor SEED(118) xor SEED(119) xor SEED(123) xor SEED(125) xor dq(  6);
					ca(  7) <= SEED( 98) xor SEED(100) xor SEED(105) xor SEED(106) xor SEED(109) xor SEED(114) xor SEED(116) xor SEED(117) xor SEED(118) xor SEED(119) xor SEED(120) xor SEED(124) xor SEED(126) xor dq(  7);
					ca(  8) <= SEED( 99) xor SEED(101) xor SEED(106) xor SEED(107) xor SEED(110) xor SEED(115) xor SEED(117) xor SEED(118) xor SEED(119) xor SEED(120) xor SEED(121) xor SEED(125) xor SEED(127) xor dq(  8);
					ca(  9) <= SEED( 96) xor SEED(101) xor SEED(104) xor SEED(106) xor SEED(107) xor SEED(108) xor SEED(109) xor SEED(110) xor SEED(111) xor SEED(113) xor SEED(114) xor SEED(115) xor SEED(116) xor SEED(117) xor SEED(120) xor SEED(121) xor SEED(124) xor SEED(126) xor dq(  9);
					ca( 10) <= SEED( 96) xor SEED( 97) xor SEED(100) xor SEED(101) xor SEED(104) xor SEED(105) xor SEED(106) xor SEED(107) xor SEED(108) xor SEED(111) xor SEED(112) xor SEED(113) xor SEED(116) xor SEED(119) xor SEED(121) xor SEED(124) xor SEED(125) xor SEED(127) xor dq( 10);
					ca( 11) <= SEED( 97) xor SEED( 98) xor SEED(101) xor SEED(102) xor SEED(105) xor SEED(106) xor SEED(107) xor SEED(108) xor SEED(109) xor SEED(112) xor SEED(113) xor SEED(114) xor SEED(117) xor SEED(120) xor SEED(122) xor SEED(125) xor SEED(126) xor dq( 11);
					ca( 12) <= SEED( 98) xor SEED( 99) xor SEED(102) xor SEED(103) xor SEED(106) xor SEED(107) xor SEED(108) xor SEED(109) xor SEED(110) xor SEED(113) xor SEED(114) xor SEED(115) xor SEED(118) xor SEED(121) xor SEED(123) xor SEED(126) xor SEED(127) xor dq( 12);
					ca( 13) <= SEED( 96) xor SEED( 99) xor SEED(101) xor SEED(102) xor SEED(103) xor SEED(106) xor SEED(107) xor SEED(108) xor SEED(111) xor SEED(113) xor SEED(116) xor SEED(117) xor SEED(118) xor SEED(127) xor dq( 13);
					ca( 14) <= SEED( 96) xor SEED( 97) xor SEED(101) xor SEED(103) xor SEED(106) xor SEED(107) xor SEED(108) xor SEED(110) xor SEED(112) xor SEED(113) xor SEED(115) xor SEED(122) xor SEED(124) xor dq( 14);
					ca( 15) <= SEED( 97) xor SEED( 98) xor SEED(102) xor SEED(104) xor SEED(107) xor SEED(108) xor SEED(109) xor SEED(111) xor SEED(113) xor SEED(114) xor SEED(116) xor SEED(123) xor SEED(125) xor dq( 15);
					ca( 16) <= SEED( 96) xor SEED( 98) xor SEED( 99) xor SEED(100) xor SEED(101) xor SEED(102) xor SEED(103) xor SEED(104) xor SEED(105) xor SEED(106) xor SEED(108) xor SEED(112) xor SEED(113) xor SEED(118) xor SEED(119) xor SEED(122) xor SEED(126) xor dq( 16);
					ca( 17) <= SEED( 97) xor SEED( 99) xor SEED(100) xor SEED(101) xor SEED(102) xor SEED(103) xor SEED(104) xor SEED(105) xor SEED(106) xor SEED(107) xor SEED(109) xor SEED(113) xor SEED(114) xor SEED(119) xor SEED(120) xor SEED(123) xor SEED(127) xor dq( 17);
					ca( 18) <= SEED( 98) xor SEED(100) xor SEED(101) xor SEED(102) xor SEED(103) xor SEED(104) xor SEED(105) xor SEED(106) xor SEED(107) xor SEED(108) xor SEED(110) xor SEED(114) xor SEED(115) xor SEED(120) xor SEED(121) xor SEED(124) xor dq( 18);
					ca( 19) <= SEED( 96) xor SEED( 99) xor SEED(100) xor SEED(103) xor SEED(105) xor SEED(107) xor SEED(108) xor SEED(110) xor SEED(111) xor SEED(113) xor SEED(114) xor SEED(116) xor SEED(117) xor SEED(118) xor SEED(119) xor SEED(121) xor SEED(124) xor SEED(125) xor dq( 19);
					ca( 20) <= SEED( 96) xor SEED( 97) xor SEED(102) xor SEED(108) xor SEED(110) xor SEED(111) xor SEED(112) xor SEED(113) xor SEED(120) xor SEED(124) xor SEED(125) xor SEED(126) xor dq( 20);
					ca( 21) <= SEED( 96) xor SEED( 97) xor SEED( 98) xor SEED(100) xor SEED(101) xor SEED(102) xor SEED(103) xor SEED(104) xor SEED(106) xor SEED(110) xor SEED(111) xor SEED(112) xor SEED(115) xor SEED(117) xor SEED(118) xor SEED(119) xor SEED(121) xor SEED(122) xor SEED(124) xor SEED(125) xor SEED(126) xor SEED(127) xor dq( 21);
					ca( 22) <= SEED( 96) xor SEED( 97) xor SEED( 98) xor SEED( 99) xor SEED(100) xor SEED(103) xor SEED(105) xor SEED(106) xor SEED(107) xor SEED(109) xor SEED(110) xor SEED(111) xor SEED(112) xor SEED(114) xor SEED(115) xor SEED(116) xor SEED(117) xor SEED(120) xor SEED(123) xor SEED(124) xor SEED(125) xor SEED(126) xor SEED(127) xor dq( 22);
					ca( 23) <= SEED( 96) xor SEED( 97) xor SEED( 98) xor SEED( 99) xor SEED(102) xor SEED(107) xor SEED(108) xor SEED(109) xor SEED(111) xor SEED(112) xor SEED(114) xor SEED(116) xor SEED(119) xor SEED(121) xor SEED(122) xor SEED(125) xor SEED(126) xor SEED(127) xor dq( 23);
					ca( 24) <= SEED( 97) xor SEED( 98) xor SEED( 99) xor SEED(100) xor SEED(103) xor SEED(108) xor SEED(109) xor SEED(110) xor SEED(112) xor SEED(113) xor SEED(115) xor SEED(117) xor SEED(120) xor SEED(122) xor SEED(123) xor SEED(126) xor SEED(127) xor dq( 24);
					ca( 25) <= SEED( 98) xor SEED( 99) xor SEED(100) xor SEED(101) xor SEED(104) xor SEED(109) xor SEED(110) xor SEED(111) xor SEED(113) xor SEED(114) xor SEED(116) xor SEED(118) xor SEED(121) xor SEED(123) xor SEED(124) xor SEED(127) xor dq( 25);
					ca( 26) <= SEED( 96) xor SEED( 99) xor SEED(104) xor SEED(105) xor SEED(106) xor SEED(109) xor SEED(111) xor SEED(112) xor SEED(113) xor SEED(118) xor SEED(125) xor dq( 26);
					ca( 27) <= SEED( 97) xor SEED(100) xor SEED(105) xor SEED(106) xor SEED(107) xor SEED(110) xor SEED(112) xor SEED(113) xor SEED(114) xor SEED(119) xor SEED(126) xor dq( 27);
					ca( 28) <= SEED( 98) xor SEED(101) xor SEED(106) xor SEED(107) xor SEED(108) xor SEED(111) xor SEED(113) xor SEED(114) xor SEED(115) xor SEED(120) xor SEED(127) xor dq( 28);
					ca( 29) <= SEED( 99) xor SEED(102) xor SEED(107) xor SEED(108) xor SEED(109) xor SEED(112) xor SEED(114) xor SEED(115) xor SEED(116) xor SEED(121) xor dq( 29);
					ca( 30) <= SEED(100) xor SEED(103) xor SEED(108) xor SEED(109) xor SEED(110) xor SEED(113) xor SEED(115) xor SEED(116) xor SEED(117) xor SEED(122) xor dq( 30);
					ca( 31) <= SEED(101) xor SEED(104) xor SEED(109) xor SEED(110) xor SEED(111) xor SEED(114) xor SEED(116) xor SEED(117) xor SEED(118) xor SEED(123) xor dq( 31);
					ca( 32) <= SEED(  0) xor SEED( 96) xor SEED(100) xor SEED(101) xor SEED(104) xor SEED(105) xor SEED(106) xor SEED(109) xor SEED(111) xor SEED(112) xor SEED(113) xor SEED(114) xor SEED(122) xor dq( 32);
					ca( 33) <= SEED(  1) xor SEED( 97) xor SEED(101) xor SEED(102) xor SEED(105) xor SEED(106) xor SEED(107) xor SEED(110) xor SEED(112) xor SEED(113) xor SEED(114) xor SEED(115) xor SEED(123) xor dq( 33);
					ca( 34) <= SEED(  2) xor SEED( 96) xor SEED( 98) xor SEED(100) xor SEED(101) xor SEED(103) xor SEED(104) xor SEED(107) xor SEED(108) xor SEED(109) xor SEED(110) xor SEED(111) xor SEED(116) xor SEED(117) xor SEED(118) xor SEED(119) xor SEED(122) xor dq( 34);
					ca( 35) <= SEED(  3) xor SEED( 97) xor SEED( 99) xor SEED(101) xor SEED(102) xor SEED(104) xor SEED(105) xor SEED(108) xor SEED(109) xor SEED(110) xor SEED(111) xor SEED(112) xor SEED(117) xor SEED(118) xor SEED(119) xor SEED(120) xor SEED(123) xor dq( 35);
					ca( 36) <= SEED(  4) xor SEED( 96) xor SEED( 98) xor SEED(101) xor SEED(103) xor SEED(104) xor SEED(105) xor SEED(111) xor SEED(112) xor SEED(114) xor SEED(115) xor SEED(117) xor SEED(120) xor SEED(121) xor SEED(122) xor dq( 36);
					ca( 37) <= SEED(  5) xor SEED( 96) xor SEED( 97) xor SEED( 99) xor SEED(100) xor SEED(101) xor SEED(105) xor SEED(109) xor SEED(110) xor SEED(112) xor SEED(114) xor SEED(116) xor SEED(117) xor SEED(119) xor SEED(121) xor SEED(123) xor SEED(124) xor dq( 37);
					ca( 38) <= SEED(  6) xor SEED( 96) xor SEED( 97) xor SEED( 98) xor SEED(104) xor SEED(109) xor SEED(111) xor SEED(114) xor SEED(119) xor SEED(120) xor SEED(125) xor dq( 38);
					ca( 39) <= SEED(  7) xor SEED( 97) xor SEED( 98) xor SEED( 99) xor SEED(105) xor SEED(110) xor SEED(112) xor SEED(115) xor SEED(120) xor SEED(121) xor SEED(126) xor dq( 39);
					ca( 40) <= SEED(  8) xor SEED( 96) xor SEED( 98) xor SEED( 99) xor SEED(101) xor SEED(102) xor SEED(104) xor SEED(109) xor SEED(110) xor SEED(111) xor SEED(114) xor SEED(115) xor SEED(116) xor SEED(117) xor SEED(118) xor SEED(119) xor SEED(121) xor SEED(124) xor SEED(127) xor dq( 40);
					ca( 41) <= SEED(  9) xor SEED( 97) xor SEED( 99) xor SEED(100) xor SEED(102) xor SEED(103) xor SEED(105) xor SEED(110) xor SEED(111) xor SEED(112) xor SEED(115) xor SEED(116) xor SEED(117) xor SEED(118) xor SEED(119) xor SEED(120) xor SEED(122) xor SEED(125) xor dq( 41);
					ca( 42) <= SEED( 10) xor SEED( 96) xor SEED( 98) xor SEED(102) xor SEED(103) xor SEED(109) xor SEED(110) xor SEED(111) xor SEED(112) xor SEED(114) xor SEED(115) xor SEED(116) xor SEED(120) xor SEED(121) xor SEED(122) xor SEED(123) xor SEED(124) xor SEED(126) xor dq( 42);
					ca( 43) <= SEED( 11) xor SEED( 96) xor SEED( 97) xor SEED( 99) xor SEED(100) xor SEED(101) xor SEED(102) xor SEED(103) xor SEED(106) xor SEED(109) xor SEED(111) xor SEED(112) xor SEED(114) xor SEED(116) xor SEED(118) xor SEED(119) xor SEED(121) xor SEED(123) xor SEED(125) xor SEED(127) xor dq( 43);
					ca( 44) <= SEED( 12) xor SEED( 97) xor SEED( 98) xor SEED(100) xor SEED(101) xor SEED(102) xor SEED(103) xor SEED(104) xor SEED(107) xor SEED(110) xor SEED(112) xor SEED(113) xor SEED(115) xor SEED(117) xor SEED(119) xor SEED(120) xor SEED(122) xor SEED(124) xor SEED(126) xor dq( 44);
					ca( 45) <= SEED( 13) xor SEED( 96) xor SEED( 98) xor SEED( 99) xor SEED(100) xor SEED(103) xor SEED(105) xor SEED(106) xor SEED(108) xor SEED(109) xor SEED(110) xor SEED(111) xor SEED(115) xor SEED(116) xor SEED(117) xor SEED(119) xor SEED(120) xor SEED(121) xor SEED(122) xor SEED(123) xor SEED(124) xor SEED(125) xor SEED(127) xor dq( 45);
					ca( 46) <= SEED( 14) xor SEED( 96) xor SEED( 97) xor SEED( 99) xor SEED(102) xor SEED(107) xor SEED(111) xor SEED(112) xor SEED(113) xor SEED(114) xor SEED(115) xor SEED(116) xor SEED(119) xor SEED(120) xor SEED(121) xor SEED(123) xor SEED(125) xor SEED(126) xor dq( 46);
					ca( 47) <= SEED( 15) xor SEED( 97) xor SEED( 98) xor SEED(100) xor SEED(103) xor SEED(108) xor SEED(112) xor SEED(113) xor SEED(114) xor SEED(115) xor SEED(116) xor SEED(117) xor SEED(120) xor SEED(121) xor SEED(122) xor SEED(124) xor SEED(126) xor SEED(127) xor dq( 47);
					ca( 48) <= SEED( 16) xor SEED( 98) xor SEED( 99) xor SEED(101) xor SEED(104) xor SEED(109) xor SEED(113) xor SEED(114) xor SEED(115) xor SEED(116) xor SEED(117) xor SEED(118) xor SEED(121) xor SEED(122) xor SEED(123) xor SEED(125) xor SEED(127) xor dq( 48);
					ca( 49) <= SEED( 17) xor SEED( 99) xor SEED(100) xor SEED(102) xor SEED(105) xor SEED(110) xor SEED(114) xor SEED(115) xor SEED(116) xor SEED(117) xor SEED(118) xor SEED(119) xor SEED(122) xor SEED(123) xor SEED(124) xor SEED(126) xor dq( 49);
					ca( 50) <= SEED( 18) xor SEED( 96) xor SEED(102) xor SEED(103) xor SEED(104) xor SEED(109) xor SEED(110) xor SEED(111) xor SEED(113) xor SEED(114) xor SEED(116) xor SEED(120) xor SEED(122) xor SEED(123) xor SEED(125) xor SEED(127) xor dq( 50);
					ca( 51) <= SEED( 19) xor SEED( 96) xor SEED( 97) xor SEED(100) xor SEED(101) xor SEED(102) xor SEED(103) xor SEED(105) xor SEED(106) xor SEED(109) xor SEED(111) xor SEED(112) xor SEED(113) xor SEED(118) xor SEED(119) xor SEED(121) xor SEED(122) xor SEED(123) xor SEED(126) xor dq( 51);
					ca( 52) <= SEED( 20) xor SEED( 96) xor SEED( 97) xor SEED( 98) xor SEED(100) xor SEED(103) xor SEED(107) xor SEED(109) xor SEED(112) xor SEED(115) xor SEED(117) xor SEED(118) xor SEED(120) xor SEED(123) xor SEED(127) xor dq( 52);
					ca( 53) <= SEED( 21) xor SEED( 96) xor SEED( 97) xor SEED( 98) xor SEED( 99) xor SEED(100) xor SEED(102) xor SEED(106) xor SEED(108) xor SEED(109) xor SEED(114) xor SEED(115) xor SEED(116) xor SEED(117) xor SEED(121) xor SEED(122) xor dq( 53);
					ca( 54) <= SEED( 22) xor SEED( 96) xor SEED( 97) xor SEED( 98) xor SEED( 99) xor SEED(102) xor SEED(103) xor SEED(104) xor SEED(106) xor SEED(107) xor SEED(113) xor SEED(114) xor SEED(116) xor SEED(119) xor SEED(123) xor SEED(124) xor dq( 54);
					ca( 55) <= SEED( 23) xor SEED( 96) xor SEED( 97) xor SEED( 98) xor SEED( 99) xor SEED(101) xor SEED(102) xor SEED(103) xor SEED(105) xor SEED(106) xor SEED(107) xor SEED(108) xor SEED(109) xor SEED(110) xor SEED(113) xor SEED(118) xor SEED(119) xor SEED(120) xor SEED(122) xor SEED(125) xor dq( 55);
					ca( 56) <= SEED( 24) xor SEED( 96) xor SEED( 97) xor SEED( 98) xor SEED( 99) xor SEED(101) xor SEED(103) xor SEED(107) xor SEED(108) xor SEED(111) xor SEED(113) xor SEED(115) xor SEED(117) xor SEED(118) xor SEED(120) xor SEED(121) xor SEED(122) xor SEED(123) xor SEED(124) xor SEED(126) xor dq( 56);
					ca( 57) <= SEED( 25) xor SEED( 97) xor SEED( 98) xor SEED( 99) xor SEED(100) xor SEED(102) xor SEED(104) xor SEED(108) xor SEED(109) xor SEED(112) xor SEED(114) xor SEED(116) xor SEED(118) xor SEED(119) xor SEED(121) xor SEED(122) xor SEED(123) xor SEED(124) xor SEED(125) xor SEED(127) xor dq( 57);
					ca( 58) <= SEED( 26) xor SEED( 98) xor SEED( 99) xor SEED(100) xor SEED(101) xor SEED(103) xor SEED(105) xor SEED(109) xor SEED(110) xor SEED(113) xor SEED(115) xor SEED(117) xor SEED(119) xor SEED(120) xor SEED(122) xor SEED(123) xor SEED(124) xor SEED(125) xor SEED(126) xor dq( 58);
					ca( 59) <= SEED( 27) xor SEED( 96) xor SEED( 99) xor SEED(109) xor SEED(111) xor SEED(113) xor SEED(115) xor SEED(116) xor SEED(117) xor SEED(119) xor SEED(120) xor SEED(121) xor SEED(122) xor SEED(123) xor SEED(125) xor SEED(126) xor SEED(127) xor dq( 59);
					ca( 60) <= SEED( 28) xor SEED( 96) xor SEED( 97) xor SEED(101) xor SEED(102) xor SEED(104) xor SEED(106) xor SEED(109) xor SEED(112) xor SEED(113) xor SEED(115) xor SEED(116) xor SEED(119) xor SEED(120) xor SEED(121) xor SEED(123) xor SEED(126) xor SEED(127) xor dq( 60);
					ca( 61) <= SEED( 29) xor SEED( 97) xor SEED( 98) xor SEED(102) xor SEED(103) xor SEED(105) xor SEED(107) xor SEED(110) xor SEED(113) xor SEED(114) xor SEED(116) xor SEED(117) xor SEED(120) xor SEED(121) xor SEED(122) xor SEED(124) xor SEED(127) xor dq( 61);
					ca( 62) <= SEED( 30) xor SEED( 98) xor SEED( 99) xor SEED(103) xor SEED(104) xor SEED(106) xor SEED(108) xor SEED(111) xor SEED(114) xor SEED(115) xor SEED(117) xor SEED(118) xor SEED(121) xor SEED(122) xor SEED(123) xor SEED(125) xor dq( 62);
					ca( 63) <= SEED( 31) xor SEED( 99) xor SEED(100) xor SEED(104) xor SEED(105) xor SEED(107) xor SEED(109) xor SEED(112) xor SEED(115) xor SEED(116) xor SEED(118) xor SEED(119) xor SEED(122) xor SEED(123) xor SEED(124) xor SEED(126) xor dq( 63);
					ca( 64) <= SEED( 32) xor SEED( 96) xor SEED(102) xor SEED(104) xor SEED(105) xor SEED(108) xor SEED(109) xor SEED(114) xor SEED(115) xor SEED(116) xor SEED(118) xor SEED(120) xor SEED(122) xor SEED(123) xor SEED(125) xor SEED(127) xor dq( 64);
					ca( 65) <= SEED( 33) xor SEED( 97) xor SEED(103) xor SEED(105) xor SEED(106) xor SEED(109) xor SEED(110) xor SEED(115) xor SEED(116) xor SEED(117) xor SEED(119) xor SEED(121) xor SEED(123) xor SEED(124) xor SEED(126) xor dq( 65);
					ca( 66) <= SEED( 34) xor SEED( 96) xor SEED( 98) xor SEED(100) xor SEED(101) xor SEED(102) xor SEED(107) xor SEED(109) xor SEED(111) xor SEED(113) xor SEED(114) xor SEED(115) xor SEED(116) xor SEED(119) xor SEED(120) xor SEED(125) xor SEED(127) xor dq( 66);
					ca( 67) <= SEED( 35) xor SEED( 96) xor SEED( 97) xor SEED( 99) xor SEED(100) xor SEED(103) xor SEED(104) xor SEED(106) xor SEED(108) xor SEED(109) xor SEED(112) xor SEED(113) xor SEED(116) xor SEED(118) xor SEED(119) xor SEED(120) xor SEED(121) xor SEED(122) xor SEED(124) xor SEED(126) xor dq( 67);
					ca( 68) <= SEED( 36) xor SEED( 96) xor SEED( 97) xor SEED( 98) xor SEED(102) xor SEED(105) xor SEED(106) xor SEED(107) xor SEED(115) xor SEED(118) xor SEED(120) xor SEED(121) xor SEED(123) xor SEED(124) xor SEED(125) xor SEED(127) xor dq( 68);
					ca( 69) <= SEED( 37) xor SEED( 96) xor SEED( 97) xor SEED( 98) xor SEED( 99) xor SEED(100) xor SEED(101) xor SEED(102) xor SEED(103) xor SEED(104) xor SEED(107) xor SEED(108) xor SEED(109) xor SEED(110) xor SEED(113) xor SEED(114) xor SEED(115) xor SEED(116) xor SEED(117) xor SEED(118) xor SEED(121) xor SEED(125) xor SEED(126) xor dq( 69);
					ca( 70) <= SEED( 38) xor SEED( 97) xor SEED( 98) xor SEED( 99) xor SEED(100) xor SEED(101) xor SEED(102) xor SEED(103) xor SEED(104) xor SEED(105) xor SEED(108) xor SEED(109) xor SEED(110) xor SEED(111) xor SEED(114) xor SEED(115) xor SEED(116) xor SEED(117) xor SEED(118) xor SEED(119) xor SEED(122) xor SEED(126) xor SEED(127) xor dq( 70);
					ca( 71) <= SEED( 39) xor SEED( 96) xor SEED( 98) xor SEED( 99) xor SEED(103) xor SEED(105) xor SEED(111) xor SEED(112) xor SEED(113) xor SEED(114) xor SEED(116) xor SEED(120) xor SEED(122) xor SEED(123) xor SEED(124) xor SEED(127) xor dq( 71);
					ca( 72) <= SEED( 40) xor SEED( 96) xor SEED( 97) xor SEED( 99) xor SEED(101) xor SEED(102) xor SEED(109) xor SEED(110) xor SEED(112) xor SEED(118) xor SEED(119) xor SEED(121) xor SEED(122) xor SEED(123) xor SEED(125) xor dq( 72);
					ca( 73) <= SEED( 41) xor SEED( 96) xor SEED( 97) xor SEED( 98) xor SEED(101) xor SEED(103) xor SEED(104) xor SEED(106) xor SEED(109) xor SEED(111) xor SEED(114) xor SEED(115) xor SEED(117) xor SEED(118) xor SEED(120) xor SEED(123) xor SEED(126) xor dq( 73);
					ca( 74) <= SEED( 42) xor SEED( 96) xor SEED( 97) xor SEED( 98) xor SEED( 99) xor SEED(100) xor SEED(101) xor SEED(105) xor SEED(106) xor SEED(107) xor SEED(109) xor SEED(112) xor SEED(113) xor SEED(114) xor SEED(116) xor SEED(117) xor SEED(121) xor SEED(122) xor SEED(127) xor dq( 74);
					ca( 75) <= SEED( 43) xor SEED( 97) xor SEED( 98) xor SEED( 99) xor SEED(100) xor SEED(101) xor SEED(102) xor SEED(106) xor SEED(107) xor SEED(108) xor SEED(110) xor SEED(113) xor SEED(114) xor SEED(115) xor SEED(117) xor SEED(118) xor SEED(122) xor SEED(123) xor dq( 75);
					ca( 76) <= SEED( 44) xor SEED( 96) xor SEED( 98) xor SEED( 99) xor SEED(103) xor SEED(104) xor SEED(106) xor SEED(107) xor SEED(108) xor SEED(110) xor SEED(111) xor SEED(113) xor SEED(116) xor SEED(117) xor SEED(122) xor SEED(123) xor dq( 76);
					ca( 77) <= SEED( 45) xor SEED( 97) xor SEED( 99) xor SEED(100) xor SEED(104) xor SEED(105) xor SEED(107) xor SEED(108) xor SEED(109) xor SEED(111) xor SEED(112) xor SEED(114) xor SEED(117) xor SEED(118) xor SEED(123) xor SEED(124) xor dq( 77);
					ca( 78) <= SEED( 46) xor SEED( 98) xor SEED(100) xor SEED(101) xor SEED(105) xor SEED(106) xor SEED(108) xor SEED(109) xor SEED(110) xor SEED(112) xor SEED(113) xor SEED(115) xor SEED(118) xor SEED(119) xor SEED(124) xor SEED(125) xor dq( 78);
					ca( 79) <= SEED( 47) xor SEED( 96) xor SEED( 99) xor SEED(100) xor SEED(104) xor SEED(107) xor SEED(111) xor SEED(115) xor SEED(116) xor SEED(117) xor SEED(118) xor SEED(120) xor SEED(122) xor SEED(124) xor SEED(125) xor SEED(126) xor dq( 79);
					ca( 80) <= SEED( 48) xor SEED( 96) xor SEED( 97) xor SEED(102) xor SEED(104) xor SEED(105) xor SEED(106) xor SEED(108) xor SEED(109) xor SEED(110) xor SEED(112) xor SEED(113) xor SEED(114) xor SEED(115) xor SEED(116) xor SEED(121) xor SEED(122) xor SEED(123) xor SEED(124) xor SEED(125) xor SEED(126) xor SEED(127) xor dq( 80);
					ca( 81) <= SEED( 49) xor SEED( 96) xor SEED( 97) xor SEED( 98) xor SEED(100) xor SEED(101) xor SEED(102) xor SEED(103) xor SEED(104) xor SEED(105) xor SEED(107) xor SEED(111) xor SEED(116) xor SEED(118) xor SEED(119) xor SEED(123) xor SEED(125) xor SEED(126) xor SEED(127) xor dq( 81);
					ca( 82) <= SEED( 50) xor SEED( 96) xor SEED( 97) xor SEED( 98) xor SEED( 99) xor SEED(100) xor SEED(103) xor SEED(105) xor SEED(108) xor SEED(109) xor SEED(110) xor SEED(112) xor SEED(113) xor SEED(114) xor SEED(115) xor SEED(118) xor SEED(120) xor SEED(122) xor SEED(126) xor SEED(127) xor dq( 82);
					ca( 83) <= SEED( 51) xor SEED( 97) xor SEED( 98) xor SEED( 99) xor SEED(100) xor SEED(101) xor SEED(104) xor SEED(106) xor SEED(109) xor SEED(110) xor SEED(111) xor SEED(113) xor SEED(114) xor SEED(115) xor SEED(116) xor SEED(119) xor SEED(121) xor SEED(123) xor SEED(127) xor dq( 83);
					ca( 84) <= SEED( 52) xor SEED( 98) xor SEED( 99) xor SEED(100) xor SEED(101) xor SEED(102) xor SEED(105) xor SEED(107) xor SEED(110) xor SEED(111) xor SEED(112) xor SEED(114) xor SEED(115) xor SEED(116) xor SEED(117) xor SEED(120) xor SEED(122) xor SEED(124) xor dq( 84);
					ca( 85) <= SEED( 53) xor SEED( 96) xor SEED( 99) xor SEED(103) xor SEED(104) xor SEED(108) xor SEED(109) xor SEED(110) xor SEED(111) xor SEED(112) xor SEED(114) xor SEED(116) xor SEED(119) xor SEED(121) xor SEED(122) xor SEED(123) xor SEED(124) xor SEED(125) xor dq( 85);
					ca( 86) <= SEED( 54) xor SEED( 97) xor SEED(100) xor SEED(104) xor SEED(105) xor SEED(109) xor SEED(110) xor SEED(111) xor SEED(112) xor SEED(113) xor SEED(115) xor SEED(117) xor SEED(120) xor SEED(122) xor SEED(123) xor SEED(124) xor SEED(125) xor SEED(126) xor dq( 86);
					ca( 87) <= SEED( 55) xor SEED( 98) xor SEED(101) xor SEED(105) xor SEED(106) xor SEED(110) xor SEED(111) xor SEED(112) xor SEED(113) xor SEED(114) xor SEED(116) xor SEED(118) xor SEED(121) xor SEED(123) xor SEED(124) xor SEED(125) xor SEED(126) xor SEED(127) xor dq( 87);
					ca( 88) <= SEED( 56) xor SEED( 96) xor SEED( 99) xor SEED(100) xor SEED(101) xor SEED(104) xor SEED(107) xor SEED(109) xor SEED(110) xor SEED(111) xor SEED(112) xor SEED(118) xor SEED(125) xor SEED(126) xor SEED(127) xor dq( 88);
					ca( 89) <= SEED( 57) xor SEED( 97) xor SEED(100) xor SEED(101) xor SEED(102) xor SEED(105) xor SEED(108) xor SEED(110) xor SEED(111) xor SEED(112) xor SEED(113) xor SEED(119) xor SEED(126) xor SEED(127) xor dq( 89);
					ca( 90) <= SEED( 58) xor SEED( 98) xor SEED(101) xor SEED(102) xor SEED(103) xor SEED(106) xor SEED(109) xor SEED(111) xor SEED(112) xor SEED(113) xor SEED(114) xor SEED(120) xor SEED(127) xor dq( 90);
					ca( 91) <= SEED( 59) xor SEED( 99) xor SEED(102) xor SEED(103) xor SEED(104) xor SEED(107) xor SEED(110) xor SEED(112) xor SEED(113) xor SEED(114) xor SEED(115) xor SEED(121) xor dq( 91);
					ca( 92) <= SEED( 60) xor SEED( 96) xor SEED(101) xor SEED(102) xor SEED(103) xor SEED(105) xor SEED(106) xor SEED(108) xor SEED(109) xor SEED(110) xor SEED(111) xor SEED(116) xor SEED(117) xor SEED(118) xor SEED(119) xor SEED(124) xor dq( 92);
					ca( 93) <= SEED( 61) xor SEED( 96) xor SEED( 97) xor SEED(100) xor SEED(101) xor SEED(103) xor SEED(107) xor SEED(111) xor SEED(112) xor SEED(113) xor SEED(114) xor SEED(115) xor SEED(120) xor SEED(122) xor SEED(124) xor SEED(125) xor dq( 93);
					ca( 94) <= SEED( 62) xor SEED( 96) xor SEED( 97) xor SEED( 98) xor SEED(100) xor SEED(106) xor SEED(108) xor SEED(109) xor SEED(110) xor SEED(112) xor SEED(116) xor SEED(117) xor SEED(118) xor SEED(119) xor SEED(121) xor SEED(122) xor SEED(123) xor SEED(124) xor SEED(125) xor SEED(126) xor dq( 94);
					ca( 95) <= SEED( 63) xor SEED( 97) xor SEED( 98) xor SEED( 99) xor SEED(101) xor SEED(107) xor SEED(109) xor SEED(110) xor SEED(111) xor SEED(113) xor SEED(117) xor SEED(118) xor SEED(119) xor SEED(120) xor SEED(122) xor SEED(123) xor SEED(124) xor SEED(125) xor SEED(126) xor SEED(127) xor dq( 95);
					ca( 96) <= SEED( 64) xor SEED( 96) xor SEED( 98) xor SEED( 99) xor SEED(101) xor SEED(104) xor SEED(106) xor SEED(108) xor SEED(109) xor SEED(111) xor SEED(112) xor SEED(113) xor SEED(115) xor SEED(117) xor SEED(120) xor SEED(121) xor SEED(122) xor SEED(123) xor SEED(125) xor SEED(126) xor SEED(127) xor dq( 96);
					ca( 97) <= SEED( 65) xor SEED( 96) xor SEED( 97) xor SEED( 99) xor SEED(101) xor SEED(104) xor SEED(105) xor SEED(106) xor SEED(107) xor SEED(112) xor SEED(115) xor SEED(116) xor SEED(117) xor SEED(119) xor SEED(121) xor SEED(123) xor SEED(126) xor SEED(127) xor dq( 97);
					ca( 98) <= SEED( 66) xor SEED( 96) xor SEED( 97) xor SEED( 98) xor SEED(101) xor SEED(104) xor SEED(105) xor SEED(107) xor SEED(108) xor SEED(109) xor SEED(110) xor SEED(114) xor SEED(115) xor SEED(116) xor SEED(119) xor SEED(120) xor SEED(127) xor dq( 98);
					ca( 99) <= SEED( 67) xor SEED( 96) xor SEED( 97) xor SEED( 98) xor SEED( 99) xor SEED(100) xor SEED(101) xor SEED(104) xor SEED(105) xor SEED(108) xor SEED(111) xor SEED(113) xor SEED(114) xor SEED(116) xor SEED(118) xor SEED(119) xor SEED(120) xor SEED(121) xor SEED(122) xor SEED(124) xor dq( 99);
					ca(100) <= SEED( 68) xor SEED( 96) xor SEED( 97) xor SEED( 98) xor SEED( 99) xor SEED(104) xor SEED(105) xor SEED(110) xor SEED(112) xor SEED(113) xor SEED(118) xor SEED(120) xor SEED(121) xor SEED(123) xor SEED(124) xor SEED(125) xor dq(100);
					ca(101) <= SEED( 69) xor SEED( 97) xor SEED( 98) xor SEED( 99) xor SEED(100) xor SEED(105) xor SEED(106) xor SEED(111) xor SEED(113) xor SEED(114) xor SEED(119) xor SEED(121) xor SEED(122) xor SEED(124) xor SEED(125) xor SEED(126) xor dq(101);
					ca(102) <= SEED( 70) xor SEED( 96) xor SEED( 98) xor SEED( 99) xor SEED(102) xor SEED(104) xor SEED(107) xor SEED(109) xor SEED(110) xor SEED(112) xor SEED(113) xor SEED(117) xor SEED(118) xor SEED(119) xor SEED(120) xor SEED(123) xor SEED(124) xor SEED(125) xor SEED(126) xor SEED(127) xor dq(102);
					ca(103) <= SEED( 71) xor SEED( 97) xor SEED( 99) xor SEED(100) xor SEED(103) xor SEED(105) xor SEED(108) xor SEED(110) xor SEED(111) xor SEED(113) xor SEED(114) xor SEED(118) xor SEED(119) xor SEED(120) xor SEED(121) xor SEED(124) xor SEED(125) xor SEED(126) xor SEED(127) xor dq(103);
					ca(104) <= SEED( 72) xor SEED( 96) xor SEED( 98) xor SEED(102) xor SEED(110) xor SEED(111) xor SEED(112) xor SEED(113) xor SEED(117) xor SEED(118) xor SEED(120) xor SEED(121) xor SEED(124) xor SEED(125) xor SEED(126) xor SEED(127) xor dq(104);
					ca(105) <= SEED( 73) xor SEED( 97) xor SEED( 99) xor SEED(103) xor SEED(111) xor SEED(112) xor SEED(113) xor SEED(114) xor SEED(118) xor SEED(119) xor SEED(121) xor SEED(122) xor SEED(125) xor SEED(126) xor SEED(127) xor dq(105);
					ca(106) <= SEED( 74) xor SEED( 96) xor SEED( 98) xor SEED(101) xor SEED(102) xor SEED(106) xor SEED(109) xor SEED(110) xor SEED(112) xor SEED(117) xor SEED(118) xor SEED(120) xor SEED(123) xor SEED(124) xor SEED(126) xor SEED(127) xor dq(106);
					ca(107) <= SEED( 75) xor SEED( 97) xor SEED( 99) xor SEED(102) xor SEED(103) xor SEED(107) xor SEED(110) xor SEED(111) xor SEED(113) xor SEED(118) xor SEED(119) xor SEED(121) xor SEED(124) xor SEED(125) xor SEED(127) xor dq(107);
					ca(108) <= SEED( 76) xor SEED( 98) xor SEED(100) xor SEED(103) xor SEED(104) xor SEED(108) xor SEED(111) xor SEED(112) xor SEED(114) xor SEED(119) xor SEED(120) xor SEED(122) xor SEED(125) xor SEED(126) xor dq(108);
					ca(109) <= SEED( 77) xor SEED( 96) xor SEED( 99) xor SEED(100) xor SEED(102) xor SEED(105) xor SEED(106) xor SEED(110) xor SEED(112) xor SEED(114) xor SEED(117) xor SEED(118) xor SEED(119) xor SEED(120) xor SEED(121) xor SEED(122) xor SEED(123) xor SEED(124) xor SEED(126) xor SEED(127) xor dq(109);
					ca(110) <= SEED( 78) xor SEED( 97) xor SEED(100) xor SEED(101) xor SEED(103) xor SEED(106) xor SEED(107) xor SEED(111) xor SEED(113) xor SEED(115) xor SEED(118) xor SEED(119) xor SEED(120) xor SEED(121) xor SEED(122) xor SEED(123) xor SEED(124) xor SEED(125) xor SEED(127) xor dq(110);
					ca(111) <= SEED( 79) xor SEED( 98) xor SEED(101) xor SEED(102) xor SEED(104) xor SEED(107) xor SEED(108) xor SEED(112) xor SEED(114) xor SEED(116) xor SEED(119) xor SEED(120) xor SEED(121) xor SEED(122) xor SEED(123) xor SEED(124) xor SEED(125) xor SEED(126) xor dq(111);
					ca(112) <= SEED( 80) xor SEED( 96) xor SEED( 99) xor SEED(100) xor SEED(101) xor SEED(103) xor SEED(104) xor SEED(105) xor SEED(106) xor SEED(108) xor SEED(110) xor SEED(114) xor SEED(118) xor SEED(119) xor SEED(120) xor SEED(121) xor SEED(123) xor SEED(125) xor SEED(126) xor SEED(127) xor dq(112);
					ca(113) <= SEED( 81) xor SEED( 96) xor SEED( 97) xor SEED(105) xor SEED(107) xor SEED(110) xor SEED(111) xor SEED(113) xor SEED(114) xor SEED(117) xor SEED(118) xor SEED(120) xor SEED(121) xor SEED(126) xor SEED(127) xor dq(113);
					ca(114) <= SEED( 82) xor SEED( 96) xor SEED( 97) xor SEED( 98) xor SEED(100) xor SEED(101) xor SEED(102) xor SEED(104) xor SEED(108) xor SEED(109) xor SEED(110) xor SEED(111) xor SEED(112) xor SEED(113) xor SEED(117) xor SEED(121) xor SEED(124) xor SEED(127) xor dq(114);
					ca(115) <= SEED( 83) xor SEED( 97) xor SEED( 98) xor SEED( 99) xor SEED(101) xor SEED(102) xor SEED(103) xor SEED(105) xor SEED(109) xor SEED(110) xor SEED(111) xor SEED(112) xor SEED(113) xor SEED(114) xor SEED(118) xor SEED(122) xor SEED(125) xor dq(115);
					ca(116) <= SEED( 84) xor SEED( 98) xor SEED( 99) xor SEED(100) xor SEED(102) xor SEED(103) xor SEED(104) xor SEED(106) xor SEED(110) xor SEED(111) xor SEED(112) xor SEED(113) xor SEED(114) xor SEED(115) xor SEED(119) xor SEED(123) xor SEED(126) xor dq(116);
					ca(117) <= SEED( 85) xor SEED( 99) xor SEED(100) xor SEED(101) xor SEED(103) xor SEED(104) xor SEED(105) xor SEED(107) xor SEED(111) xor SEED(112) xor SEED(113) xor SEED(114) xor SEED(115) xor SEED(116) xor SEED(120) xor SEED(124) xor SEED(127) xor dq(117);
					ca(118) <= SEED( 86) xor SEED(100) xor SEED(101) xor SEED(102) xor SEED(104) xor SEED(105) xor SEED(106) xor SEED(108) xor SEED(112) xor SEED(113) xor SEED(114) xor SEED(115) xor SEED(116) xor SEED(117) xor SEED(121) xor SEED(125) xor dq(118);
					ca(119) <= SEED( 87) xor SEED(101) xor SEED(102) xor SEED(103) xor SEED(105) xor SEED(106) xor SEED(107) xor SEED(109) xor SEED(113) xor SEED(114) xor SEED(115) xor SEED(116) xor SEED(117) xor SEED(118) xor SEED(122) xor SEED(126) xor dq(119);
					ca(120) <= SEED( 88) xor SEED(102) xor SEED(103) xor SEED(104) xor SEED(106) xor SEED(107) xor SEED(108) xor SEED(110) xor SEED(114) xor SEED(115) xor SEED(116) xor SEED(117) xor SEED(118) xor SEED(119) xor SEED(123) xor SEED(127) xor dq(120);
					ca(121) <= SEED( 89) xor SEED(103) xor SEED(104) xor SEED(105) xor SEED(107) xor SEED(108) xor SEED(109) xor SEED(111) xor SEED(115) xor SEED(116) xor SEED(117) xor SEED(118) xor SEED(119) xor SEED(120) xor SEED(124) xor dq(121);
					ca(122) <= SEED( 90) xor SEED( 96) xor SEED(100) xor SEED(101) xor SEED(102) xor SEED(105) xor SEED(108) xor SEED(112) xor SEED(113) xor SEED(114) xor SEED(115) xor SEED(116) xor SEED(120) xor SEED(121) xor SEED(122) xor SEED(124) xor SEED(125) xor dq(122);
					ca(123) <= SEED( 91) xor SEED( 96) xor SEED( 97) xor SEED(100) xor SEED(103) xor SEED(104) xor SEED(110) xor SEED(116) xor SEED(118) xor SEED(119) xor SEED(121) xor SEED(123) xor SEED(124) xor SEED(125) xor SEED(126) xor dq(123);
					ca(124) <= SEED( 92) xor SEED( 96) xor SEED( 97) xor SEED( 98) xor SEED(100) xor SEED(102) xor SEED(105) xor SEED(106) xor SEED(109) xor SEED(110) xor SEED(111) xor SEED(113) xor SEED(114) xor SEED(115) xor SEED(118) xor SEED(120) xor SEED(125) xor SEED(126) xor SEED(127) xor dq(124);
					ca(125) <= SEED( 93) xor SEED( 97) xor SEED( 98) xor SEED( 99) xor SEED(101) xor SEED(103) xor SEED(106) xor SEED(107) xor SEED(110) xor SEED(111) xor SEED(112) xor SEED(114) xor SEED(115) xor SEED(116) xor SEED(119) xor SEED(121) xor SEED(126) xor SEED(127) xor dq(125);
					ca(126) <= SEED( 94) xor SEED( 98) xor SEED( 99) xor SEED(100) xor SEED(102) xor SEED(104) xor SEED(107) xor SEED(108) xor SEED(111) xor SEED(112) xor SEED(113) xor SEED(115) xor SEED(116) xor SEED(117) xor SEED(120) xor SEED(122) xor SEED(127) xor dq(126);
					ca(127) <= SEED( 95) xor SEED( 99) xor SEED(100) xor SEED(101) xor SEED(103) xor SEED(105) xor SEED(108) xor SEED(109) xor SEED(112) xor SEED(113) xor SEED(114) xor SEED(116) xor SEED(117) xor SEED(118) xor SEED(121) xor SEED(123) xor dq(127);


					oa( 31) <= SEED(127) xor dq(  0);
					oa( 30) <= SEED(126) xor dq(  1);
					oa( 29) <= SEED(125) xor dq(  2);
					oa( 28) <= SEED(124) xor dq(  3);
					oa( 27) <= SEED(123) xor SEED(127) xor dq(  4);
					oa( 26) <= SEED(122) xor SEED(126) xor SEED(127) xor dq(  5);
					oa( 25) <= SEED(121) xor SEED(125) xor SEED(126) xor SEED(127) xor dq(  6);
					oa( 24) <= SEED(120) xor SEED(124) xor SEED(125) xor SEED(126) xor dq(  7);
					oa( 23) <= SEED(119) xor SEED(123) xor SEED(124) xor SEED(125) xor SEED(127) xor dq(  8);
					oa( 22) <= SEED(118) xor SEED(122) xor SEED(123) xor SEED(124) xor SEED(126) xor dq(  9);
					oa( 21) <= SEED(117) xor SEED(121) xor SEED(122) xor SEED(123) xor SEED(125) xor SEED(127) xor dq( 10);
					oa( 20) <= SEED(116) xor SEED(120) xor SEED(121) xor SEED(122) xor SEED(124) xor SEED(126) xor dq( 11);
					oa( 19) <= SEED(115) xor SEED(119) xor SEED(120) xor SEED(121) xor SEED(123) xor SEED(125) xor dq( 12);
					oa( 18) <= SEED(114) xor SEED(118) xor SEED(119) xor SEED(120) xor SEED(122) xor SEED(124) xor SEED(127) xor dq( 13);
					oa( 17) <= SEED(113) xor SEED(117) xor SEED(118) xor SEED(119) xor SEED(121) xor SEED(123) xor SEED(126) xor SEED(127) xor dq( 14);
					oa( 16) <= SEED(112) xor SEED(116) xor SEED(117) xor SEED(118) xor SEED(120) xor SEED(122) xor SEED(125) xor SEED(126) xor dq( 15);
					oa( 15) <= SEED(111) xor SEED(115) xor SEED(116) xor SEED(117) xor SEED(119) xor SEED(121) xor SEED(124) xor SEED(125) xor dq( 16);
					oa( 14) <= SEED(110) xor SEED(114) xor SEED(115) xor SEED(116) xor SEED(118) xor SEED(120) xor SEED(123) xor SEED(124) xor SEED(127) xor dq( 17);
					oa( 13) <= SEED(109) xor SEED(113) xor SEED(114) xor SEED(115) xor SEED(117) xor SEED(119) xor SEED(122) xor SEED(123) xor SEED(126) xor SEED(127) xor dq( 18);
					oa( 12) <= SEED(108) xor SEED(112) xor SEED(113) xor SEED(114) xor SEED(116) xor SEED(118) xor SEED(121) xor SEED(122) xor SEED(125) xor SEED(126) xor SEED(127) xor dq( 19);
					oa( 11) <= SEED(107) xor SEED(111) xor SEED(112) xor SEED(113) xor SEED(115) xor SEED(117) xor SEED(120) xor SEED(121) xor SEED(124) xor SEED(125) xor SEED(126) xor dq( 20);
					oa( 10) <= SEED(106) xor SEED(110) xor SEED(111) xor SEED(112) xor SEED(114) xor SEED(116) xor SEED(119) xor SEED(120) xor SEED(123) xor SEED(124) xor SEED(125) xor SEED(127) xor dq( 21);
					oa(  9) <= SEED(105) xor SEED(109) xor SEED(110) xor SEED(111) xor SEED(113) xor SEED(115) xor SEED(118) xor SEED(119) xor SEED(122) xor SEED(123) xor SEED(124) xor SEED(126) xor SEED(127) xor dq( 22);
					oa(  8) <= SEED(104) xor SEED(108) xor SEED(109) xor SEED(110) xor SEED(112) xor SEED(114) xor SEED(117) xor SEED(118) xor SEED(121) xor SEED(122) xor SEED(123) xor SEED(125) xor SEED(126) xor SEED(127) xor dq( 23);
					oa(  7) <= SEED(103) xor SEED(107) xor SEED(108) xor SEED(109) xor SEED(111) xor SEED(113) xor SEED(116) xor SEED(117) xor SEED(120) xor SEED(121) xor SEED(122) xor SEED(124) xor SEED(125) xor SEED(126) xor dq( 24);
					oa(  6) <= SEED(102) xor SEED(106) xor SEED(107) xor SEED(108) xor SEED(110) xor SEED(112) xor SEED(115) xor SEED(116) xor SEED(119) xor SEED(120) xor SEED(121) xor SEED(123) xor SEED(124) xor SEED(125) xor dq( 25);
					oa(  5) <= SEED(101) xor SEED(105) xor SEED(106) xor SEED(107) xor SEED(109) xor SEED(111) xor SEED(114) xor SEED(115) xor SEED(118) xor SEED(119) xor SEED(120) xor SEED(122) xor SEED(123) xor SEED(124) xor SEED(127) xor dq( 26);
					oa(  4) <= SEED(100) xor SEED(104) xor SEED(105) xor SEED(106) xor SEED(108) xor SEED(110) xor SEED(113) xor SEED(114) xor SEED(117) xor SEED(118) xor SEED(119) xor SEED(121) xor SEED(122) xor SEED(123) xor SEED(126) xor dq( 27);
					oa(  3) <= SEED( 99) xor SEED(103) xor SEED(104) xor SEED(105) xor SEED(107) xor SEED(109) xor SEED(112) xor SEED(113) xor SEED(116) xor SEED(117) xor SEED(118) xor SEED(120) xor SEED(121) xor SEED(122) xor SEED(125) xor SEED(127) xor dq( 28);
					oa(  2) <= SEED( 98) xor SEED(102) xor SEED(103) xor SEED(104) xor SEED(106) xor SEED(108) xor SEED(111) xor SEED(112) xor SEED(115) xor SEED(116) xor SEED(117) xor SEED(119) xor SEED(120) xor SEED(121) xor SEED(124) xor SEED(126) xor dq( 29);
					oa(  1) <= SEED( 97) xor SEED(101) xor SEED(102) xor SEED(103) xor SEED(105) xor SEED(107) xor SEED(110) xor SEED(111) xor SEED(114) xor SEED(115) xor SEED(116) xor SEED(118) xor SEED(119) xor SEED(120) xor SEED(123) xor SEED(125) xor dq( 30);
					oa(  0) <= SEED( 96) xor SEED(100) xor SEED(101) xor SEED(102) xor SEED(104) xor SEED(106) xor SEED(109) xor SEED(110) xor SEED(113) xor SEED(114) xor SEED(115) xor SEED(117) xor SEED(118) xor SEED(119) xor SEED(122) xor SEED(124) xor dq( 31);
				else
					ca(  0) <= ca( 96) xor ca(100) xor ca(101) xor ca(102) xor ca(104) xor ca(106) xor ca(109) xor ca(110) xor ca(113) xor ca(114) xor ca(115) xor ca(117) xor ca(118) xor ca(119) xor ca(122) xor ca(124) xor dq(  0);
					ca(  1) <= ca( 96) xor ca( 97) xor ca(100) xor ca(103) xor ca(104) xor ca(105) xor ca(106) xor ca(107) xor ca(109) xor ca(111) xor ca(113) xor ca(116) xor ca(117) xor ca(120) xor ca(122) xor ca(123) xor ca(124) xor ca(125) xor dq(  1);
					ca(  2) <= ca( 97) xor ca( 98) xor ca(101) xor ca(104) xor ca(105) xor ca(106) xor ca(107) xor ca(108) xor ca(110) xor ca(112) xor ca(114) xor ca(117) xor ca(118) xor ca(121) xor ca(123) xor ca(124) xor ca(125) xor ca(126) xor dq(  2);
					ca(  3) <= ca( 96) xor ca( 98) xor ca( 99) xor ca(100) xor ca(101) xor ca(104) xor ca(105) xor ca(107) xor ca(108) xor ca(110) xor ca(111) xor ca(114) xor ca(117) xor ca(125) xor ca(126) xor ca(127) xor dq(  3);
					ca(  4) <= ca( 97) xor ca( 99) xor ca(100) xor ca(101) xor ca(102) xor ca(105) xor ca(106) xor ca(108) xor ca(109) xor ca(111) xor ca(112) xor ca(115) xor ca(118) xor ca(126) xor ca(127) xor dq(  4);
					ca(  5) <= ca( 96) xor ca( 98) xor ca(103) xor ca(104) xor ca(107) xor ca(112) xor ca(114) xor ca(115) xor ca(116) xor ca(117) xor ca(118) xor ca(122) xor ca(124) xor ca(127) xor dq(  5);
					ca(  6) <= ca( 97) xor ca( 99) xor ca(104) xor ca(105) xor ca(108) xor ca(113) xor ca(115) xor ca(116) xor ca(117) xor ca(118) xor ca(119) xor ca(123) xor ca(125) xor dq(  6);
					ca(  7) <= ca( 98) xor ca(100) xor ca(105) xor ca(106) xor ca(109) xor ca(114) xor ca(116) xor ca(117) xor ca(118) xor ca(119) xor ca(120) xor ca(124) xor ca(126) xor dq(  7);
					ca(  8) <= ca( 99) xor ca(101) xor ca(106) xor ca(107) xor ca(110) xor ca(115) xor ca(117) xor ca(118) xor ca(119) xor ca(120) xor ca(121) xor ca(125) xor ca(127) xor dq(  8);
					ca(  9) <= ca( 96) xor ca(101) xor ca(104) xor ca(106) xor ca(107) xor ca(108) xor ca(109) xor ca(110) xor ca(111) xor ca(113) xor ca(114) xor ca(115) xor ca(116) xor ca(117) xor ca(120) xor ca(121) xor ca(124) xor ca(126) xor dq(  9);
					ca( 10) <= ca( 96) xor ca( 97) xor ca(100) xor ca(101) xor ca(104) xor ca(105) xor ca(106) xor ca(107) xor ca(108) xor ca(111) xor ca(112) xor ca(113) xor ca(116) xor ca(119) xor ca(121) xor ca(124) xor ca(125) xor ca(127) xor dq( 10);
					ca( 11) <= ca( 97) xor ca( 98) xor ca(101) xor ca(102) xor ca(105) xor ca(106) xor ca(107) xor ca(108) xor ca(109) xor ca(112) xor ca(113) xor ca(114) xor ca(117) xor ca(120) xor ca(122) xor ca(125) xor ca(126) xor dq( 11);
					ca( 12) <= ca( 98) xor ca( 99) xor ca(102) xor ca(103) xor ca(106) xor ca(107) xor ca(108) xor ca(109) xor ca(110) xor ca(113) xor ca(114) xor ca(115) xor ca(118) xor ca(121) xor ca(123) xor ca(126) xor ca(127) xor dq( 12);
					ca( 13) <= ca( 96) xor ca( 99) xor ca(101) xor ca(102) xor ca(103) xor ca(106) xor ca(107) xor ca(108) xor ca(111) xor ca(113) xor ca(116) xor ca(117) xor ca(118) xor ca(127) xor dq( 13);
					ca( 14) <= ca( 96) xor ca( 97) xor ca(101) xor ca(103) xor ca(106) xor ca(107) xor ca(108) xor ca(110) xor ca(112) xor ca(113) xor ca(115) xor ca(122) xor ca(124) xor dq( 14);
					ca( 15) <= ca( 97) xor ca( 98) xor ca(102) xor ca(104) xor ca(107) xor ca(108) xor ca(109) xor ca(111) xor ca(113) xor ca(114) xor ca(116) xor ca(123) xor ca(125) xor dq( 15);
					ca( 16) <= ca( 96) xor ca( 98) xor ca( 99) xor ca(100) xor ca(101) xor ca(102) xor ca(103) xor ca(104) xor ca(105) xor ca(106) xor ca(108) xor ca(112) xor ca(113) xor ca(118) xor ca(119) xor ca(122) xor ca(126) xor dq( 16);
					ca( 17) <= ca( 97) xor ca( 99) xor ca(100) xor ca(101) xor ca(102) xor ca(103) xor ca(104) xor ca(105) xor ca(106) xor ca(107) xor ca(109) xor ca(113) xor ca(114) xor ca(119) xor ca(120) xor ca(123) xor ca(127) xor dq( 17);
					ca( 18) <= ca( 98) xor ca(100) xor ca(101) xor ca(102) xor ca(103) xor ca(104) xor ca(105) xor ca(106) xor ca(107) xor ca(108) xor ca(110) xor ca(114) xor ca(115) xor ca(120) xor ca(121) xor ca(124) xor dq( 18);
					ca( 19) <= ca( 96) xor ca( 99) xor ca(100) xor ca(103) xor ca(105) xor ca(107) xor ca(108) xor ca(110) xor ca(111) xor ca(113) xor ca(114) xor ca(116) xor ca(117) xor ca(118) xor ca(119) xor ca(121) xor ca(124) xor ca(125) xor dq( 19);
					ca( 20) <= ca( 96) xor ca( 97) xor ca(102) xor ca(108) xor ca(110) xor ca(111) xor ca(112) xor ca(113) xor ca(120) xor ca(124) xor ca(125) xor ca(126) xor dq( 20);
					ca( 21) <= ca( 96) xor ca( 97) xor ca( 98) xor ca(100) xor ca(101) xor ca(102) xor ca(103) xor ca(104) xor ca(106) xor ca(110) xor ca(111) xor ca(112) xor ca(115) xor ca(117) xor ca(118) xor ca(119) xor ca(121) xor ca(122) xor ca(124) xor ca(125) xor ca(126) xor ca(127) xor dq( 21);
					ca( 22) <= ca( 96) xor ca( 97) xor ca( 98) xor ca( 99) xor ca(100) xor ca(103) xor ca(105) xor ca(106) xor ca(107) xor ca(109) xor ca(110) xor ca(111) xor ca(112) xor ca(114) xor ca(115) xor ca(116) xor ca(117) xor ca(120) xor ca(123) xor ca(124) xor ca(125) xor ca(126) xor ca(127) xor dq( 22);
					ca( 23) <= ca( 96) xor ca( 97) xor ca( 98) xor ca( 99) xor ca(102) xor ca(107) xor ca(108) xor ca(109) xor ca(111) xor ca(112) xor ca(114) xor ca(116) xor ca(119) xor ca(121) xor ca(122) xor ca(125) xor ca(126) xor ca(127) xor dq( 23);
					ca( 24) <= ca( 97) xor ca( 98) xor ca( 99) xor ca(100) xor ca(103) xor ca(108) xor ca(109) xor ca(110) xor ca(112) xor ca(113) xor ca(115) xor ca(117) xor ca(120) xor ca(122) xor ca(123) xor ca(126) xor ca(127) xor dq( 24);
					ca( 25) <= ca( 98) xor ca( 99) xor ca(100) xor ca(101) xor ca(104) xor ca(109) xor ca(110) xor ca(111) xor ca(113) xor ca(114) xor ca(116) xor ca(118) xor ca(121) xor ca(123) xor ca(124) xor ca(127) xor dq( 25);
					ca( 26) <= ca( 96) xor ca( 99) xor ca(104) xor ca(105) xor ca(106) xor ca(109) xor ca(111) xor ca(112) xor ca(113) xor ca(118) xor ca(125) xor dq( 26);
					ca( 27) <= ca( 97) xor ca(100) xor ca(105) xor ca(106) xor ca(107) xor ca(110) xor ca(112) xor ca(113) xor ca(114) xor ca(119) xor ca(126) xor dq( 27);
					ca( 28) <= ca( 98) xor ca(101) xor ca(106) xor ca(107) xor ca(108) xor ca(111) xor ca(113) xor ca(114) xor ca(115) xor ca(120) xor ca(127) xor dq( 28);
					ca( 29) <= ca( 99) xor ca(102) xor ca(107) xor ca(108) xor ca(109) xor ca(112) xor ca(114) xor ca(115) xor ca(116) xor ca(121) xor dq( 29);
					ca( 30) <= ca(100) xor ca(103) xor ca(108) xor ca(109) xor ca(110) xor ca(113) xor ca(115) xor ca(116) xor ca(117) xor ca(122) xor dq( 30);
					ca( 31) <= ca(101) xor ca(104) xor ca(109) xor ca(110) xor ca(111) xor ca(114) xor ca(116) xor ca(117) xor ca(118) xor ca(123) xor dq( 31);
					ca( 32) <= ca(  0) xor ca( 96) xor ca(100) xor ca(101) xor ca(104) xor ca(105) xor ca(106) xor ca(109) xor ca(111) xor ca(112) xor ca(113) xor ca(114) xor ca(122) xor dq( 32);
					ca( 33) <= ca(  1) xor ca( 97) xor ca(101) xor ca(102) xor ca(105) xor ca(106) xor ca(107) xor ca(110) xor ca(112) xor ca(113) xor ca(114) xor ca(115) xor ca(123) xor dq( 33);
					ca( 34) <= ca(  2) xor ca( 96) xor ca( 98) xor ca(100) xor ca(101) xor ca(103) xor ca(104) xor ca(107) xor ca(108) xor ca(109) xor ca(110) xor ca(111) xor ca(116) xor ca(117) xor ca(118) xor ca(119) xor ca(122) xor dq( 34);
					ca( 35) <= ca(  3) xor ca( 97) xor ca( 99) xor ca(101) xor ca(102) xor ca(104) xor ca(105) xor ca(108) xor ca(109) xor ca(110) xor ca(111) xor ca(112) xor ca(117) xor ca(118) xor ca(119) xor ca(120) xor ca(123) xor dq( 35);
					ca( 36) <= ca(  4) xor ca( 96) xor ca( 98) xor ca(101) xor ca(103) xor ca(104) xor ca(105) xor ca(111) xor ca(112) xor ca(114) xor ca(115) xor ca(117) xor ca(120) xor ca(121) xor ca(122) xor dq( 36);
					ca( 37) <= ca(  5) xor ca( 96) xor ca( 97) xor ca( 99) xor ca(100) xor ca(101) xor ca(105) xor ca(109) xor ca(110) xor ca(112) xor ca(114) xor ca(116) xor ca(117) xor ca(119) xor ca(121) xor ca(123) xor ca(124) xor dq( 37);
					ca( 38) <= ca(  6) xor ca( 96) xor ca( 97) xor ca( 98) xor ca(104) xor ca(109) xor ca(111) xor ca(114) xor ca(119) xor ca(120) xor ca(125) xor dq( 38);
					ca( 39) <= ca(  7) xor ca( 97) xor ca( 98) xor ca( 99) xor ca(105) xor ca(110) xor ca(112) xor ca(115) xor ca(120) xor ca(121) xor ca(126) xor dq( 39);
					ca( 40) <= ca(  8) xor ca( 96) xor ca( 98) xor ca( 99) xor ca(101) xor ca(102) xor ca(104) xor ca(109) xor ca(110) xor ca(111) xor ca(114) xor ca(115) xor ca(116) xor ca(117) xor ca(118) xor ca(119) xor ca(121) xor ca(124) xor ca(127) xor dq( 40);
					ca( 41) <= ca(  9) xor ca( 97) xor ca( 99) xor ca(100) xor ca(102) xor ca(103) xor ca(105) xor ca(110) xor ca(111) xor ca(112) xor ca(115) xor ca(116) xor ca(117) xor ca(118) xor ca(119) xor ca(120) xor ca(122) xor ca(125) xor dq( 41);
					ca( 42) <= ca( 10) xor ca( 96) xor ca( 98) xor ca(102) xor ca(103) xor ca(109) xor ca(110) xor ca(111) xor ca(112) xor ca(114) xor ca(115) xor ca(116) xor ca(120) xor ca(121) xor ca(122) xor ca(123) xor ca(124) xor ca(126) xor dq( 42);
					ca( 43) <= ca( 11) xor ca( 96) xor ca( 97) xor ca( 99) xor ca(100) xor ca(101) xor ca(102) xor ca(103) xor ca(106) xor ca(109) xor ca(111) xor ca(112) xor ca(114) xor ca(116) xor ca(118) xor ca(119) xor ca(121) xor ca(123) xor ca(125) xor ca(127) xor dq( 43);
					ca( 44) <= ca( 12) xor ca( 97) xor ca( 98) xor ca(100) xor ca(101) xor ca(102) xor ca(103) xor ca(104) xor ca(107) xor ca(110) xor ca(112) xor ca(113) xor ca(115) xor ca(117) xor ca(119) xor ca(120) xor ca(122) xor ca(124) xor ca(126) xor dq( 44);
					ca( 45) <= ca( 13) xor ca( 96) xor ca( 98) xor ca( 99) xor ca(100) xor ca(103) xor ca(105) xor ca(106) xor ca(108) xor ca(109) xor ca(110) xor ca(111) xor ca(115) xor ca(116) xor ca(117) xor ca(119) xor ca(120) xor ca(121) xor ca(122) xor ca(123) xor ca(124) xor ca(125) xor ca(127) xor dq( 45);
					ca( 46) <= ca( 14) xor ca( 96) xor ca( 97) xor ca( 99) xor ca(102) xor ca(107) xor ca(111) xor ca(112) xor ca(113) xor ca(114) xor ca(115) xor ca(116) xor ca(119) xor ca(120) xor ca(121) xor ca(123) xor ca(125) xor ca(126) xor dq( 46);
					ca( 47) <= ca( 15) xor ca( 97) xor ca( 98) xor ca(100) xor ca(103) xor ca(108) xor ca(112) xor ca(113) xor ca(114) xor ca(115) xor ca(116) xor ca(117) xor ca(120) xor ca(121) xor ca(122) xor ca(124) xor ca(126) xor ca(127) xor dq( 47);
					ca( 48) <= ca( 16) xor ca( 98) xor ca( 99) xor ca(101) xor ca(104) xor ca(109) xor ca(113) xor ca(114) xor ca(115) xor ca(116) xor ca(117) xor ca(118) xor ca(121) xor ca(122) xor ca(123) xor ca(125) xor ca(127) xor dq( 48);
					ca( 49) <= ca( 17) xor ca( 99) xor ca(100) xor ca(102) xor ca(105) xor ca(110) xor ca(114) xor ca(115) xor ca(116) xor ca(117) xor ca(118) xor ca(119) xor ca(122) xor ca(123) xor ca(124) xor ca(126) xor dq( 49);
					ca( 50) <= ca( 18) xor ca( 96) xor ca(102) xor ca(103) xor ca(104) xor ca(109) xor ca(110) xor ca(111) xor ca(113) xor ca(114) xor ca(116) xor ca(120) xor ca(122) xor ca(123) xor ca(125) xor ca(127) xor dq( 50);
					ca( 51) <= ca( 19) xor ca( 96) xor ca( 97) xor ca(100) xor ca(101) xor ca(102) xor ca(103) xor ca(105) xor ca(106) xor ca(109) xor ca(111) xor ca(112) xor ca(113) xor ca(118) xor ca(119) xor ca(121) xor ca(122) xor ca(123) xor ca(126) xor dq( 51);
					ca( 52) <= ca( 20) xor ca( 96) xor ca( 97) xor ca( 98) xor ca(100) xor ca(103) xor ca(107) xor ca(109) xor ca(112) xor ca(115) xor ca(117) xor ca(118) xor ca(120) xor ca(123) xor ca(127) xor dq( 52);
					ca( 53) <= ca( 21) xor ca( 96) xor ca( 97) xor ca( 98) xor ca( 99) xor ca(100) xor ca(102) xor ca(106) xor ca(108) xor ca(109) xor ca(114) xor ca(115) xor ca(116) xor ca(117) xor ca(121) xor ca(122) xor dq( 53);
					ca( 54) <= ca( 22) xor ca( 96) xor ca( 97) xor ca( 98) xor ca( 99) xor ca(102) xor ca(103) xor ca(104) xor ca(106) xor ca(107) xor ca(113) xor ca(114) xor ca(116) xor ca(119) xor ca(123) xor ca(124) xor dq( 54);
					ca( 55) <= ca( 23) xor ca( 96) xor ca( 97) xor ca( 98) xor ca( 99) xor ca(101) xor ca(102) xor ca(103) xor ca(105) xor ca(106) xor ca(107) xor ca(108) xor ca(109) xor ca(110) xor ca(113) xor ca(118) xor ca(119) xor ca(120) xor ca(122) xor ca(125) xor dq( 55);
					ca( 56) <= ca( 24) xor ca( 96) xor ca( 97) xor ca( 98) xor ca( 99) xor ca(101) xor ca(103) xor ca(107) xor ca(108) xor ca(111) xor ca(113) xor ca(115) xor ca(117) xor ca(118) xor ca(120) xor ca(121) xor ca(122) xor ca(123) xor ca(124) xor ca(126) xor dq( 56);
					ca( 57) <= ca( 25) xor ca( 97) xor ca( 98) xor ca( 99) xor ca(100) xor ca(102) xor ca(104) xor ca(108) xor ca(109) xor ca(112) xor ca(114) xor ca(116) xor ca(118) xor ca(119) xor ca(121) xor ca(122) xor ca(123) xor ca(124) xor ca(125) xor ca(127) xor dq( 57);
					ca( 58) <= ca( 26) xor ca( 98) xor ca( 99) xor ca(100) xor ca(101) xor ca(103) xor ca(105) xor ca(109) xor ca(110) xor ca(113) xor ca(115) xor ca(117) xor ca(119) xor ca(120) xor ca(122) xor ca(123) xor ca(124) xor ca(125) xor ca(126) xor dq( 58);
					ca( 59) <= ca( 27) xor ca( 96) xor ca( 99) xor ca(109) xor ca(111) xor ca(113) xor ca(115) xor ca(116) xor ca(117) xor ca(119) xor ca(120) xor ca(121) xor ca(122) xor ca(123) xor ca(125) xor ca(126) xor ca(127) xor dq( 59);
					ca( 60) <= ca( 28) xor ca( 96) xor ca( 97) xor ca(101) xor ca(102) xor ca(104) xor ca(106) xor ca(109) xor ca(112) xor ca(113) xor ca(115) xor ca(116) xor ca(119) xor ca(120) xor ca(121) xor ca(123) xor ca(126) xor ca(127) xor dq( 60);
					ca( 61) <= ca( 29) xor ca( 97) xor ca( 98) xor ca(102) xor ca(103) xor ca(105) xor ca(107) xor ca(110) xor ca(113) xor ca(114) xor ca(116) xor ca(117) xor ca(120) xor ca(121) xor ca(122) xor ca(124) xor ca(127) xor dq( 61);
					ca( 62) <= ca( 30) xor ca( 98) xor ca( 99) xor ca(103) xor ca(104) xor ca(106) xor ca(108) xor ca(111) xor ca(114) xor ca(115) xor ca(117) xor ca(118) xor ca(121) xor ca(122) xor ca(123) xor ca(125) xor dq( 62);
					ca( 63) <= ca( 31) xor ca( 99) xor ca(100) xor ca(104) xor ca(105) xor ca(107) xor ca(109) xor ca(112) xor ca(115) xor ca(116) xor ca(118) xor ca(119) xor ca(122) xor ca(123) xor ca(124) xor ca(126) xor dq( 63);
					ca( 64) <= ca( 32) xor ca( 96) xor ca(102) xor ca(104) xor ca(105) xor ca(108) xor ca(109) xor ca(114) xor ca(115) xor ca(116) xor ca(118) xor ca(120) xor ca(122) xor ca(123) xor ca(125) xor ca(127) xor dq( 64);
					ca( 65) <= ca( 33) xor ca( 97) xor ca(103) xor ca(105) xor ca(106) xor ca(109) xor ca(110) xor ca(115) xor ca(116) xor ca(117) xor ca(119) xor ca(121) xor ca(123) xor ca(124) xor ca(126) xor dq( 65);
					ca( 66) <= ca( 34) xor ca( 96) xor ca( 98) xor ca(100) xor ca(101) xor ca(102) xor ca(107) xor ca(109) xor ca(111) xor ca(113) xor ca(114) xor ca(115) xor ca(116) xor ca(119) xor ca(120) xor ca(125) xor ca(127) xor dq( 66);
					ca( 67) <= ca( 35) xor ca( 96) xor ca( 97) xor ca( 99) xor ca(100) xor ca(103) xor ca(104) xor ca(106) xor ca(108) xor ca(109) xor ca(112) xor ca(113) xor ca(116) xor ca(118) xor ca(119) xor ca(120) xor ca(121) xor ca(122) xor ca(124) xor ca(126) xor dq( 67);
					ca( 68) <= ca( 36) xor ca( 96) xor ca( 97) xor ca( 98) xor ca(102) xor ca(105) xor ca(106) xor ca(107) xor ca(115) xor ca(118) xor ca(120) xor ca(121) xor ca(123) xor ca(124) xor ca(125) xor ca(127) xor dq( 68);
					ca( 69) <= ca( 37) xor ca( 96) xor ca( 97) xor ca( 98) xor ca( 99) xor ca(100) xor ca(101) xor ca(102) xor ca(103) xor ca(104) xor ca(107) xor ca(108) xor ca(109) xor ca(110) xor ca(113) xor ca(114) xor ca(115) xor ca(116) xor ca(117) xor ca(118) xor ca(121) xor ca(125) xor ca(126) xor dq( 69);
					ca( 70) <= ca( 38) xor ca( 97) xor ca( 98) xor ca( 99) xor ca(100) xor ca(101) xor ca(102) xor ca(103) xor ca(104) xor ca(105) xor ca(108) xor ca(109) xor ca(110) xor ca(111) xor ca(114) xor ca(115) xor ca(116) xor ca(117) xor ca(118) xor ca(119) xor ca(122) xor ca(126) xor ca(127) xor dq( 70);
					ca( 71) <= ca( 39) xor ca( 96) xor ca( 98) xor ca( 99) xor ca(103) xor ca(105) xor ca(111) xor ca(112) xor ca(113) xor ca(114) xor ca(116) xor ca(120) xor ca(122) xor ca(123) xor ca(124) xor ca(127) xor dq( 71);
					ca( 72) <= ca( 40) xor ca( 96) xor ca( 97) xor ca( 99) xor ca(101) xor ca(102) xor ca(109) xor ca(110) xor ca(112) xor ca(118) xor ca(119) xor ca(121) xor ca(122) xor ca(123) xor ca(125) xor dq( 72);
					ca( 73) <= ca( 41) xor ca( 96) xor ca( 97) xor ca( 98) xor ca(101) xor ca(103) xor ca(104) xor ca(106) xor ca(109) xor ca(111) xor ca(114) xor ca(115) xor ca(117) xor ca(118) xor ca(120) xor ca(123) xor ca(126) xor dq( 73);
					ca( 74) <= ca( 42) xor ca( 96) xor ca( 97) xor ca( 98) xor ca( 99) xor ca(100) xor ca(101) xor ca(105) xor ca(106) xor ca(107) xor ca(109) xor ca(112) xor ca(113) xor ca(114) xor ca(116) xor ca(117) xor ca(121) xor ca(122) xor ca(127) xor dq( 74);
					ca( 75) <= ca( 43) xor ca( 97) xor ca( 98) xor ca( 99) xor ca(100) xor ca(101) xor ca(102) xor ca(106) xor ca(107) xor ca(108) xor ca(110) xor ca(113) xor ca(114) xor ca(115) xor ca(117) xor ca(118) xor ca(122) xor ca(123) xor dq( 75);
					ca( 76) <= ca( 44) xor ca( 96) xor ca( 98) xor ca( 99) xor ca(103) xor ca(104) xor ca(106) xor ca(107) xor ca(108) xor ca(110) xor ca(111) xor ca(113) xor ca(116) xor ca(117) xor ca(122) xor ca(123) xor dq( 76);
					ca( 77) <= ca( 45) xor ca( 97) xor ca( 99) xor ca(100) xor ca(104) xor ca(105) xor ca(107) xor ca(108) xor ca(109) xor ca(111) xor ca(112) xor ca(114) xor ca(117) xor ca(118) xor ca(123) xor ca(124) xor dq( 77);
					ca( 78) <= ca( 46) xor ca( 98) xor ca(100) xor ca(101) xor ca(105) xor ca(106) xor ca(108) xor ca(109) xor ca(110) xor ca(112) xor ca(113) xor ca(115) xor ca(118) xor ca(119) xor ca(124) xor ca(125) xor dq( 78);
					ca( 79) <= ca( 47) xor ca( 96) xor ca( 99) xor ca(100) xor ca(104) xor ca(107) xor ca(111) xor ca(115) xor ca(116) xor ca(117) xor ca(118) xor ca(120) xor ca(122) xor ca(124) xor ca(125) xor ca(126) xor dq( 79);
					ca( 80) <= ca( 48) xor ca( 96) xor ca( 97) xor ca(102) xor ca(104) xor ca(105) xor ca(106) xor ca(108) xor ca(109) xor ca(110) xor ca(112) xor ca(113) xor ca(114) xor ca(115) xor ca(116) xor ca(121) xor ca(122) xor ca(123) xor ca(124) xor ca(125) xor ca(126) xor ca(127) xor dq( 80);
					ca( 81) <= ca( 49) xor ca( 96) xor ca( 97) xor ca( 98) xor ca(100) xor ca(101) xor ca(102) xor ca(103) xor ca(104) xor ca(105) xor ca(107) xor ca(111) xor ca(116) xor ca(118) xor ca(119) xor ca(123) xor ca(125) xor ca(126) xor ca(127) xor dq( 81);
					ca( 82) <= ca( 50) xor ca( 96) xor ca( 97) xor ca( 98) xor ca( 99) xor ca(100) xor ca(103) xor ca(105) xor ca(108) xor ca(109) xor ca(110) xor ca(112) xor ca(113) xor ca(114) xor ca(115) xor ca(118) xor ca(120) xor ca(122) xor ca(126) xor ca(127) xor dq( 82);
					ca( 83) <= ca( 51) xor ca( 97) xor ca( 98) xor ca( 99) xor ca(100) xor ca(101) xor ca(104) xor ca(106) xor ca(109) xor ca(110) xor ca(111) xor ca(113) xor ca(114) xor ca(115) xor ca(116) xor ca(119) xor ca(121) xor ca(123) xor ca(127) xor dq( 83);
					ca( 84) <= ca( 52) xor ca( 98) xor ca( 99) xor ca(100) xor ca(101) xor ca(102) xor ca(105) xor ca(107) xor ca(110) xor ca(111) xor ca(112) xor ca(114) xor ca(115) xor ca(116) xor ca(117) xor ca(120) xor ca(122) xor ca(124) xor dq( 84);
					ca( 85) <= ca( 53) xor ca( 96) xor ca( 99) xor ca(103) xor ca(104) xor ca(108) xor ca(109) xor ca(110) xor ca(111) xor ca(112) xor ca(114) xor ca(116) xor ca(119) xor ca(121) xor ca(122) xor ca(123) xor ca(124) xor ca(125) xor dq( 85);
					ca( 86) <= ca( 54) xor ca( 97) xor ca(100) xor ca(104) xor ca(105) xor ca(109) xor ca(110) xor ca(111) xor ca(112) xor ca(113) xor ca(115) xor ca(117) xor ca(120) xor ca(122) xor ca(123) xor ca(124) xor ca(125) xor ca(126) xor dq( 86);
					ca( 87) <= ca( 55) xor ca( 98) xor ca(101) xor ca(105) xor ca(106) xor ca(110) xor ca(111) xor ca(112) xor ca(113) xor ca(114) xor ca(116) xor ca(118) xor ca(121) xor ca(123) xor ca(124) xor ca(125) xor ca(126) xor ca(127) xor dq( 87);
					ca( 88) <= ca( 56) xor ca( 96) xor ca( 99) xor ca(100) xor ca(101) xor ca(104) xor ca(107) xor ca(109) xor ca(110) xor ca(111) xor ca(112) xor ca(118) xor ca(125) xor ca(126) xor ca(127) xor dq( 88);
					ca( 89) <= ca( 57) xor ca( 97) xor ca(100) xor ca(101) xor ca(102) xor ca(105) xor ca(108) xor ca(110) xor ca(111) xor ca(112) xor ca(113) xor ca(119) xor ca(126) xor ca(127) xor dq( 89);
					ca( 90) <= ca( 58) xor ca( 98) xor ca(101) xor ca(102) xor ca(103) xor ca(106) xor ca(109) xor ca(111) xor ca(112) xor ca(113) xor ca(114) xor ca(120) xor ca(127) xor dq( 90);
					ca( 91) <= ca( 59) xor ca( 99) xor ca(102) xor ca(103) xor ca(104) xor ca(107) xor ca(110) xor ca(112) xor ca(113) xor ca(114) xor ca(115) xor ca(121) xor dq( 91);
					ca( 92) <= ca( 60) xor ca( 96) xor ca(101) xor ca(102) xor ca(103) xor ca(105) xor ca(106) xor ca(108) xor ca(109) xor ca(110) xor ca(111) xor ca(116) xor ca(117) xor ca(118) xor ca(119) xor ca(124) xor dq( 92);
					ca( 93) <= ca( 61) xor ca( 96) xor ca( 97) xor ca(100) xor ca(101) xor ca(103) xor ca(107) xor ca(111) xor ca(112) xor ca(113) xor ca(114) xor ca(115) xor ca(120) xor ca(122) xor ca(124) xor ca(125) xor dq( 93);
					ca( 94) <= ca( 62) xor ca( 96) xor ca( 97) xor ca( 98) xor ca(100) xor ca(106) xor ca(108) xor ca(109) xor ca(110) xor ca(112) xor ca(116) xor ca(117) xor ca(118) xor ca(119) xor ca(121) xor ca(122) xor ca(123) xor ca(124) xor ca(125) xor ca(126) xor dq( 94);
					ca( 95) <= ca( 63) xor ca( 97) xor ca( 98) xor ca( 99) xor ca(101) xor ca(107) xor ca(109) xor ca(110) xor ca(111) xor ca(113) xor ca(117) xor ca(118) xor ca(119) xor ca(120) xor ca(122) xor ca(123) xor ca(124) xor ca(125) xor ca(126) xor ca(127) xor dq( 95);
					ca( 96) <= ca( 64) xor ca( 96) xor ca( 98) xor ca( 99) xor ca(101) xor ca(104) xor ca(106) xor ca(108) xor ca(109) xor ca(111) xor ca(112) xor ca(113) xor ca(115) xor ca(117) xor ca(120) xor ca(121) xor ca(122) xor ca(123) xor ca(125) xor ca(126) xor ca(127) xor dq( 96);
					ca( 97) <= ca( 65) xor ca( 96) xor ca( 97) xor ca( 99) xor ca(101) xor ca(104) xor ca(105) xor ca(106) xor ca(107) xor ca(112) xor ca(115) xor ca(116) xor ca(117) xor ca(119) xor ca(121) xor ca(123) xor ca(126) xor ca(127) xor dq( 97);
					ca( 98) <= ca( 66) xor ca( 96) xor ca( 97) xor ca( 98) xor ca(101) xor ca(104) xor ca(105) xor ca(107) xor ca(108) xor ca(109) xor ca(110) xor ca(114) xor ca(115) xor ca(116) xor ca(119) xor ca(120) xor ca(127) xor dq( 98);
					ca( 99) <= ca( 67) xor ca( 96) xor ca( 97) xor ca( 98) xor ca( 99) xor ca(100) xor ca(101) xor ca(104) xor ca(105) xor ca(108) xor ca(111) xor ca(113) xor ca(114) xor ca(116) xor ca(118) xor ca(119) xor ca(120) xor ca(121) xor ca(122) xor ca(124) xor dq( 99);
					ca(100) <= ca( 68) xor ca( 96) xor ca( 97) xor ca( 98) xor ca( 99) xor ca(104) xor ca(105) xor ca(110) xor ca(112) xor ca(113) xor ca(118) xor ca(120) xor ca(121) xor ca(123) xor ca(124) xor ca(125) xor dq(100);
					ca(101) <= ca( 69) xor ca( 97) xor ca( 98) xor ca( 99) xor ca(100) xor ca(105) xor ca(106) xor ca(111) xor ca(113) xor ca(114) xor ca(119) xor ca(121) xor ca(122) xor ca(124) xor ca(125) xor ca(126) xor dq(101);
					ca(102) <= ca( 70) xor ca( 96) xor ca( 98) xor ca( 99) xor ca(102) xor ca(104) xor ca(107) xor ca(109) xor ca(110) xor ca(112) xor ca(113) xor ca(117) xor ca(118) xor ca(119) xor ca(120) xor ca(123) xor ca(124) xor ca(125) xor ca(126) xor ca(127) xor dq(102);
					ca(103) <= ca( 71) xor ca( 97) xor ca( 99) xor ca(100) xor ca(103) xor ca(105) xor ca(108) xor ca(110) xor ca(111) xor ca(113) xor ca(114) xor ca(118) xor ca(119) xor ca(120) xor ca(121) xor ca(124) xor ca(125) xor ca(126) xor ca(127) xor dq(103);
					ca(104) <= ca( 72) xor ca( 96) xor ca( 98) xor ca(102) xor ca(110) xor ca(111) xor ca(112) xor ca(113) xor ca(117) xor ca(118) xor ca(120) xor ca(121) xor ca(124) xor ca(125) xor ca(126) xor ca(127) xor dq(104);
					ca(105) <= ca( 73) xor ca( 97) xor ca( 99) xor ca(103) xor ca(111) xor ca(112) xor ca(113) xor ca(114) xor ca(118) xor ca(119) xor ca(121) xor ca(122) xor ca(125) xor ca(126) xor ca(127) xor dq(105);
					ca(106) <= ca( 74) xor ca( 96) xor ca( 98) xor ca(101) xor ca(102) xor ca(106) xor ca(109) xor ca(110) xor ca(112) xor ca(117) xor ca(118) xor ca(120) xor ca(123) xor ca(124) xor ca(126) xor ca(127) xor dq(106);
					ca(107) <= ca( 75) xor ca( 97) xor ca( 99) xor ca(102) xor ca(103) xor ca(107) xor ca(110) xor ca(111) xor ca(113) xor ca(118) xor ca(119) xor ca(121) xor ca(124) xor ca(125) xor ca(127) xor dq(107);
					ca(108) <= ca( 76) xor ca( 98) xor ca(100) xor ca(103) xor ca(104) xor ca(108) xor ca(111) xor ca(112) xor ca(114) xor ca(119) xor ca(120) xor ca(122) xor ca(125) xor ca(126) xor dq(108);
					ca(109) <= ca( 77) xor ca( 96) xor ca( 99) xor ca(100) xor ca(102) xor ca(105) xor ca(106) xor ca(110) xor ca(112) xor ca(114) xor ca(117) xor ca(118) xor ca(119) xor ca(120) xor ca(121) xor ca(122) xor ca(123) xor ca(124) xor ca(126) xor ca(127) xor dq(109);
					ca(110) <= ca( 78) xor ca( 97) xor ca(100) xor ca(101) xor ca(103) xor ca(106) xor ca(107) xor ca(111) xor ca(113) xor ca(115) xor ca(118) xor ca(119) xor ca(120) xor ca(121) xor ca(122) xor ca(123) xor ca(124) xor ca(125) xor ca(127) xor dq(110);
					ca(111) <= ca( 79) xor ca( 98) xor ca(101) xor ca(102) xor ca(104) xor ca(107) xor ca(108) xor ca(112) xor ca(114) xor ca(116) xor ca(119) xor ca(120) xor ca(121) xor ca(122) xor ca(123) xor ca(124) xor ca(125) xor ca(126) xor dq(111);
					ca(112) <= ca( 80) xor ca( 96) xor ca( 99) xor ca(100) xor ca(101) xor ca(103) xor ca(104) xor ca(105) xor ca(106) xor ca(108) xor ca(110) xor ca(114) xor ca(118) xor ca(119) xor ca(120) xor ca(121) xor ca(123) xor ca(125) xor ca(126) xor ca(127) xor dq(112);
					ca(113) <= ca( 81) xor ca( 96) xor ca( 97) xor ca(105) xor ca(107) xor ca(110) xor ca(111) xor ca(113) xor ca(114) xor ca(117) xor ca(118) xor ca(120) xor ca(121) xor ca(126) xor ca(127) xor dq(113);
					ca(114) <= ca( 82) xor ca( 96) xor ca( 97) xor ca( 98) xor ca(100) xor ca(101) xor ca(102) xor ca(104) xor ca(108) xor ca(109) xor ca(110) xor ca(111) xor ca(112) xor ca(113) xor ca(117) xor ca(121) xor ca(124) xor ca(127) xor dq(114);
					ca(115) <= ca( 83) xor ca( 97) xor ca( 98) xor ca( 99) xor ca(101) xor ca(102) xor ca(103) xor ca(105) xor ca(109) xor ca(110) xor ca(111) xor ca(112) xor ca(113) xor ca(114) xor ca(118) xor ca(122) xor ca(125) xor dq(115);
					ca(116) <= ca( 84) xor ca( 98) xor ca( 99) xor ca(100) xor ca(102) xor ca(103) xor ca(104) xor ca(106) xor ca(110) xor ca(111) xor ca(112) xor ca(113) xor ca(114) xor ca(115) xor ca(119) xor ca(123) xor ca(126) xor dq(116);
					ca(117) <= ca( 85) xor ca( 99) xor ca(100) xor ca(101) xor ca(103) xor ca(104) xor ca(105) xor ca(107) xor ca(111) xor ca(112) xor ca(113) xor ca(114) xor ca(115) xor ca(116) xor ca(120) xor ca(124) xor ca(127) xor dq(117);
					ca(118) <= ca( 86) xor ca(100) xor ca(101) xor ca(102) xor ca(104) xor ca(105) xor ca(106) xor ca(108) xor ca(112) xor ca(113) xor ca(114) xor ca(115) xor ca(116) xor ca(117) xor ca(121) xor ca(125) xor dq(118);
					ca(119) <= ca( 87) xor ca(101) xor ca(102) xor ca(103) xor ca(105) xor ca(106) xor ca(107) xor ca(109) xor ca(113) xor ca(114) xor ca(115) xor ca(116) xor ca(117) xor ca(118) xor ca(122) xor ca(126) xor dq(119);
					ca(120) <= ca( 88) xor ca(102) xor ca(103) xor ca(104) xor ca(106) xor ca(107) xor ca(108) xor ca(110) xor ca(114) xor ca(115) xor ca(116) xor ca(117) xor ca(118) xor ca(119) xor ca(123) xor ca(127) xor dq(120);
					ca(121) <= ca( 89) xor ca(103) xor ca(104) xor ca(105) xor ca(107) xor ca(108) xor ca(109) xor ca(111) xor ca(115) xor ca(116) xor ca(117) xor ca(118) xor ca(119) xor ca(120) xor ca(124) xor dq(121);
					ca(122) <= ca( 90) xor ca( 96) xor ca(100) xor ca(101) xor ca(102) xor ca(105) xor ca(108) xor ca(112) xor ca(113) xor ca(114) xor ca(115) xor ca(116) xor ca(120) xor ca(121) xor ca(122) xor ca(124) xor ca(125) xor dq(122);
					ca(123) <= ca( 91) xor ca( 96) xor ca( 97) xor ca(100) xor ca(103) xor ca(104) xor ca(110) xor ca(116) xor ca(118) xor ca(119) xor ca(121) xor ca(123) xor ca(124) xor ca(125) xor ca(126) xor dq(123);
					ca(124) <= ca( 92) xor ca( 96) xor ca( 97) xor ca( 98) xor ca(100) xor ca(102) xor ca(105) xor ca(106) xor ca(109) xor ca(110) xor ca(111) xor ca(113) xor ca(114) xor ca(115) xor ca(118) xor ca(120) xor ca(125) xor ca(126) xor ca(127) xor dq(124);
					ca(125) <= ca( 93) xor ca( 97) xor ca( 98) xor ca( 99) xor ca(101) xor ca(103) xor ca(106) xor ca(107) xor ca(110) xor ca(111) xor ca(112) xor ca(114) xor ca(115) xor ca(116) xor ca(119) xor ca(121) xor ca(126) xor ca(127) xor dq(125);
					ca(126) <= ca( 94) xor ca( 98) xor ca( 99) xor ca(100) xor ca(102) xor ca(104) xor ca(107) xor ca(108) xor ca(111) xor ca(112) xor ca(113) xor ca(115) xor ca(116) xor ca(117) xor ca(120) xor ca(122) xor ca(127) xor dq(126);
					ca(127) <= ca( 95) xor ca( 99) xor ca(100) xor ca(101) xor ca(103) xor ca(105) xor ca(108) xor ca(109) xor ca(112) xor ca(113) xor ca(114) xor ca(116) xor ca(117) xor ca(118) xor ca(121) xor ca(123) xor dq(127);


					oa( 31) <= ca(127) xor dq(  0);
					oa( 30) <= ca(126) xor dq(  1);
					oa( 29) <= ca(125) xor dq(  2);
					oa( 28) <= ca(124) xor dq(  3);
					oa( 27) <= ca(123) xor ca(127) xor dq(  4);
					oa( 26) <= ca(122) xor ca(126) xor ca(127) xor dq(  5);
					oa( 25) <= ca(121) xor ca(125) xor ca(126) xor ca(127) xor dq(  6);
					oa( 24) <= ca(120) xor ca(124) xor ca(125) xor ca(126) xor dq(  7);
					oa( 23) <= ca(119) xor ca(123) xor ca(124) xor ca(125) xor ca(127) xor dq(  8);
					oa( 22) <= ca(118) xor ca(122) xor ca(123) xor ca(124) xor ca(126) xor dq(  9);
					oa( 21) <= ca(117) xor ca(121) xor ca(122) xor ca(123) xor ca(125) xor ca(127) xor dq( 10);
					oa( 20) <= ca(116) xor ca(120) xor ca(121) xor ca(122) xor ca(124) xor ca(126) xor dq( 11);
					oa( 19) <= ca(115) xor ca(119) xor ca(120) xor ca(121) xor ca(123) xor ca(125) xor dq( 12);
					oa( 18) <= ca(114) xor ca(118) xor ca(119) xor ca(120) xor ca(122) xor ca(124) xor ca(127) xor dq( 13);
					oa( 17) <= ca(113) xor ca(117) xor ca(118) xor ca(119) xor ca(121) xor ca(123) xor ca(126) xor ca(127) xor dq( 14);
					oa( 16) <= ca(112) xor ca(116) xor ca(117) xor ca(118) xor ca(120) xor ca(122) xor ca(125) xor ca(126) xor dq( 15);
					oa( 15) <= ca(111) xor ca(115) xor ca(116) xor ca(117) xor ca(119) xor ca(121) xor ca(124) xor ca(125) xor dq( 16);
					oa( 14) <= ca(110) xor ca(114) xor ca(115) xor ca(116) xor ca(118) xor ca(120) xor ca(123) xor ca(124) xor ca(127) xor dq( 17);
					oa( 13) <= ca(109) xor ca(113) xor ca(114) xor ca(115) xor ca(117) xor ca(119) xor ca(122) xor ca(123) xor ca(126) xor ca(127) xor dq( 18);
					oa( 12) <= ca(108) xor ca(112) xor ca(113) xor ca(114) xor ca(116) xor ca(118) xor ca(121) xor ca(122) xor ca(125) xor ca(126) xor ca(127) xor dq( 19);
					oa( 11) <= ca(107) xor ca(111) xor ca(112) xor ca(113) xor ca(115) xor ca(117) xor ca(120) xor ca(121) xor ca(124) xor ca(125) xor ca(126) xor dq( 20);
					oa( 10) <= ca(106) xor ca(110) xor ca(111) xor ca(112) xor ca(114) xor ca(116) xor ca(119) xor ca(120) xor ca(123) xor ca(124) xor ca(125) xor ca(127) xor dq( 21);
					oa(  9) <= ca(105) xor ca(109) xor ca(110) xor ca(111) xor ca(113) xor ca(115) xor ca(118) xor ca(119) xor ca(122) xor ca(123) xor ca(124) xor ca(126) xor ca(127) xor dq( 22);
					oa(  8) <= ca(104) xor ca(108) xor ca(109) xor ca(110) xor ca(112) xor ca(114) xor ca(117) xor ca(118) xor ca(121) xor ca(122) xor ca(123) xor ca(125) xor ca(126) xor ca(127) xor dq( 23);
					oa(  7) <= ca(103) xor ca(107) xor ca(108) xor ca(109) xor ca(111) xor ca(113) xor ca(116) xor ca(117) xor ca(120) xor ca(121) xor ca(122) xor ca(124) xor ca(125) xor ca(126) xor dq( 24);
					oa(  6) <= ca(102) xor ca(106) xor ca(107) xor ca(108) xor ca(110) xor ca(112) xor ca(115) xor ca(116) xor ca(119) xor ca(120) xor ca(121) xor ca(123) xor ca(124) xor ca(125) xor dq( 25);
					oa(  5) <= ca(101) xor ca(105) xor ca(106) xor ca(107) xor ca(109) xor ca(111) xor ca(114) xor ca(115) xor ca(118) xor ca(119) xor ca(120) xor ca(122) xor ca(123) xor ca(124) xor ca(127) xor dq( 26);
					oa(  4) <= ca(100) xor ca(104) xor ca(105) xor ca(106) xor ca(108) xor ca(110) xor ca(113) xor ca(114) xor ca(117) xor ca(118) xor ca(119) xor ca(121) xor ca(122) xor ca(123) xor ca(126) xor dq( 27);
					oa(  3) <= ca( 99) xor ca(103) xor ca(104) xor ca(105) xor ca(107) xor ca(109) xor ca(112) xor ca(113) xor ca(116) xor ca(117) xor ca(118) xor ca(120) xor ca(121) xor ca(122) xor ca(125) xor ca(127) xor dq( 28);
					oa(  2) <= ca( 98) xor ca(102) xor ca(103) xor ca(104) xor ca(106) xor ca(108) xor ca(111) xor ca(112) xor ca(115) xor ca(116) xor ca(117) xor ca(119) xor ca(120) xor ca(121) xor ca(124) xor ca(126) xor dq( 29);
					oa(  1) <= ca( 97) xor ca(101) xor ca(102) xor ca(103) xor ca(105) xor ca(107) xor ca(110) xor ca(111) xor ca(114) xor ca(115) xor ca(116) xor ca(118) xor ca(119) xor ca(120) xor ca(123) xor ca(125) xor dq( 30);
					oa(  0) <= ca( 96) xor ca(100) xor ca(101) xor ca(102) xor ca(104) xor ca(106) xor ca(109) xor ca(110) xor ca(113) xor ca(114) xor ca(115) xor ca(117) xor ca(118) xor ca(119) xor ca(122) xor ca(124) xor dq( 31);
				end if;
			end if;
		end if;
	end process;
	c <= ca;
	o <= oa;
end bch_128x32;
