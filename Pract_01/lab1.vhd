---------------------------------------------------------------------
--
--  Fichero:
--    lab1.vhd  14/7/2015
--
--    (c) J.M. Mendias
--    Dise�o Autom�tico de Sistemas
--    Facultad de Inform�tica. Universidad Complutense de Madrid
--
--  Prop�sito:
--    Laboratorio 1
--
--  Notas de dise�o:
--
---------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity lab1 is
  port (
    switches_n : in  std_logic_vector(7 downto 0);
    pbs_n      : in  std_logic_vector(1 downto 0);
    leds       : out std_logic_vector(7 downto 0);
    upSegs     : out std_logic_vector(7 downto 0);
    leftSegs   : out std_logic_vector(7 downto 0);
    rightSegs  : out std_logic_vector(7 downto 0)
  );
end lab1;

---------------------------------------------------------------------

library ieee;
use ieee.numeric_std.all;
use work.common.all;

architecture syn of lab1 is

  signal opCode  : std_logic_vector(1 downto 0); 
  signal opCode4 : std_logic_vector (3 downto 0);
  signal leftOp  : signed(7 downto 0);
  signal rightOp : signed(7 downto 0);
  signal result  : signed(7 downto 0);
  
begin
  
  opCode  <= NOT(pbs_n);
  opCode4 <= "00" & NOT(pbs_n);
  leftOp  <= signed("0000" & NOT(switches_n (7 downto 4)));
  rightOp <= signed("0000" & NOT(switches_n (3 downto 0)));

  ALU:
  with opCode select
   result <= 
     rightOp + leftOp when "00",
	  rightOp - leftOp when "01",
	  -(rightOp) when "10",
	  rightOp(3 downto 0) * leftOp(3 downto 0) when "11",
	  "00000000" when others;
    
  leftConverter : bin2segs 
  port map ( bin => std_logic_vector(result(7 downto 4)), dp => '0', segs => leftSegs);
  
  rigthConverter : bin2segs
  port map ( bin => std_logic_vector(result(3 downto 0)), dp => '0', segs => rightSegs);

  upConverter : bin2segs
  port map ( bin => opCode4, dp => '0', segs => upSegs);

  leds <= NOT(switches_n);
  
end syn;
