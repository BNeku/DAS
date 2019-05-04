---------------------------------------------------------------------
--
--  Fichero:
--    lab6.vhd  15/7/2015
--
--    (c) J.M. Mendias
--    Diseño Automático de Sistemas
--    Facultad de Informática. Universidad Complutense de Madrid
--
--  Propósito:
--    Laboratorio 6
--
--  Notas de diseño:
--
---------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity lab6 is
  port ( 
    rstPb_n : in  std_logic;
    osc     : in  std_logic;
    ps2Clk  : in  std_logic;
    ps2Data : in  std_logic;
    hSync   : out std_logic;
    vSync   : out std_logic;
    RGB     : out std_logic_vector(8 downto 0)
  );
end lab6;

---------------------------------------------------------------------

library ieee;
use ieee.numeric_std.all;
use work.common.all;

architecture syn of lab6 is

  constant CLKFREQ : natural := 50_000_000;  -- frecuencia del reloj en MHz

  signal clk, rst_n : std_logic;

  signal data: std_logic_vector(7 downto 0);
  signal dataRdy: std_logic;
  signal qP, aP, pP, lP, spcP: boolean;
  
  signal color : std_logic_vector(2 downto 0);
  
  signal campoJuego, raquetaDer, raquetaIzq, pelota: std_logic;
  
  signal mover, finPartida, reiniciar: boolean;

  signal lineAux, pixelAux : std_logic_vector(9 downto 0);
  
  signal line, yRight, yLeft, yBall: unsigned(7 downto 0);
  signal pixel, xBall: unsigned(7 downto 0);
  
begin

  clk <= osc;
  resetSyncronizer : synchronizer
    generic map ( STAGES => 2, INIT => '0' )
    port map ( rst_n => rstPb_n, clk => clk, x => '1', xSync => rst_n );

  ------------------  

  ps2KeyboardInterface : ps2Receiver
    generic map ( REGOUTPUTS => false )
    port map ( rst_n => rst_n, clk => clk, dataRdy => dataRdy, data => data, ps2Clk => ps2Clk, ps2Data => ps2Data);
   
  keyScanner:
  process( rst_n, clk )
    type states is (keyON, keyOFF);
    variable state : states;
	 begin
    if rst_n='0' then
      state := keyON;
      qP <= false;
      aP <= false;
		lP <= false;
		pP <= false;
		spcP <= false;
    elsif rising_edge(clk) then
      if dataRdy='1' then
        case state is
          when keyON =>
            case data is
              when X"F0" => state := keyOFF;
              when X"15" => qP <= true;
              when X"1C" => aP <= true;
				  when X"4D" => lP <= true;
				  when X"4B" => pP <= true;
				  when X"29" => spcP <= true;
				  when others => state:= keyON;
            end case;
          when keyOFF =>
            state := keyON;
            case data is
              when X"15" => qP <= false; 
              when X"1C" => aP <= false;
				  when X"4D" => lP <= false;
				  when X"4B" => pP <= false;
				  when others => spcP <= false;             
          end case;
        end case;
      end if;
    end if;
  end process;        

------------------  

  screenInteface: vgaInterface
    generic map ( FREQ => 50_000, SYNCDELAY => 0 )
    port map ( rst_n => rst_n, clk => clk, line => lineAux, pixel => pixelAux, R => color, G => color, B => color, hSync => hSync, vSync => vSync, RGB => RGB );

  pixel <= unsigned(pixelAux(9 downto 2));
  line <= unsigned(lineAux(9 downto 2));
  
  color <= "000" when campoJuego='1' or raquetaIzq='1' or raquetaDer='1' or pelota='1' else "111" ;

------------------
  
  campoJuego <= '1' when line = 8 or line= 111 or ( pixel=79 and line(3)='1' ) else '0';
  raquetaDer <= '1' when pixel = 8 and(line > yRight and line < yRight+16)else'0' ;
  raquetaIzq<= '1' when pixel = 152 and(line > yLeft and line < yLeft+16)else'0' ;
  pelota  <= '1' when pixel=xBall and line = yBall else'0';

------------------

  finPartida <= true when xball >153 or xball <8 else false;
  reiniciar <= true when finPartida else false;   
--  
--------------------
  
  pulseGen:
  process (rst_n, clk)
    constant maxValue : natural := CLKFREQ/50-1;
    variable count: natural range 0 to maxValue;
  begin
    if rst_n='0' then
      mover<=false;
      count:=0;
    elsif rising_edge(clk) then
		if count = maxValue then
			count := 0;
			mover <= true;
		else
			count := count + 1;
			mover<= false;
		end if;
	 end if;
  end process;    
--        
--------------------
--
  yRightRegister:
  process (rst_n, clk)
  begin
    if rst_n='0' then
      yRight<="00001100";
    elsif rising_edge(clk) then
		if mover = true then 
			if  yRight < 95  and aP = true then
				yRight <= yRight + 1;
			elsif yRight > 8 and qP = true then
				yRight <= yRight - 1;
			end if;
		end if;
	 end if;
  end process;
  
  yLeftRegister:
  process (rst_n, clk)
  begin
    if rst_n='0' then
      yLeft<="00001100";
    elsif rising_edge(clk) then
		if mover = true then 
			if  yLeft < 95  and pP = true then
				yLeft <= yLeft + 1;
			elsif yLeft > 8 and  lP = true then
				yLeft <= yLeft - 1;
			end if;
		end if;
	 end if;
  end process;
--  
--------------------
--  
  xBallRegister:
  process (rst_n, clk)
    type sense is (left, right);
    variable dir: sense;
  begin
    if rst_n='0' then
      xBall<="00001111";
		dir:=right;
    elsif rising_edge(clk) then
	 if finPartida=false  then
		if mover=true then
			if dir = right then
			if  xBall > 149 and (yBall > yLeft and yBall < yLeft+16) then
				dir:=left;
			end if;
				xBall <= xBall + 1;
		else		
			if xBall < 10 and (yBall > yRight and yBall < yRight+16) then
				dir:=right;
			end if;
				xBall <= xBall - 1;
			end if;
		end if;
		elsif spcP=true then
			xBall<="00001111";
			dir:=right;
	   end if;
	 
	 end if;
  end process;
--
  yBallRegister:
  process (rst_n, clk)
    type sense is (up, down);
    variable dir: sense;
  begin
    if rst_n='0' then
      yBall<="00001111";
		dir:=up;
    elsif rising_edge(clk) then
		if finPartida=false then
		if mover = true then 
		if dir = down then
			if  yBall > 109  then
				dir:=up;
			end if;
				yBall <= yBall + 1;
		else		
			if yBall < 10 then
				dir:=down;
			end if;
				yBall <= yBall - 1;
		end if;
		end if;
		elsif spcP=true then
			yBall<="00001111";
			dir:=up;
	 end if;
	 end if;
  end process;

end syn;

