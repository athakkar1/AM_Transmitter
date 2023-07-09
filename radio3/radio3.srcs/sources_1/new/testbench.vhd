library IEEE;
use IEEE.STD_LOGIC_1164.ALL, STD.textio.all;
USE ieee.numeric_std.all;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;
-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;
entity testbench is
end entity testbench;

architecture io of testbench is
file vectors : text;
file results : text;
    COMPONENT i2s_playback IS
        GENERIC(
        d_width     :  INTEGER := 16;
        points      :  INTEGER := 190;
        modpoints    :  INTEGER := 999;
        amp         :  INTEGER := 256);
        PORT(
        clock       :  IN  STD_LOGIC;                     --system clock (100 MHz on Basys board)
        reset_n     :  IN  STD_LOGIC;                     --active low asynchronous reset
        adder       : IN STD_LOGIC;
        mclk        :  OUT STD_LOGIC;  --master clock
        sclk        :  OUT STD_LOGIC;  --serial clock (or bit clock)
        ws          :  OUT STD_LOGIC;  --word select (or left-right clock)
        sd_rx       :  IN  STD_LOGIC;                     --serial data in
        sclk_dac    :  out STD_LOGIC;
        ldac        :  OUT std_logic := '0';
        cs          :  out STD_LOGIC;
        sd_tx       :  OUT STD_LOGIC); --right channel data received
    END COMPONENT;
SIGNAL clock        :  STD_LOGIC := '0';
SIGNAL master_clk   :  STD_LOGIC := '0';
SIGNAL adc_sclk     :  STD_LOGIC := '0';
SIGNAL adc_ws       :  STD_LOGIC := '0';
SIGNAL sd_rx        :  std_logic := '0';
SIGNAL sclk_dac     :  STD_LOGIC := '0';
SIGNAL ldac         :  STD_LOGIC := '0';
SIGNAL dac_cs       :  STD_LOGIC := '0';
SIGNAL sd_tx        :  STD_LOGIC := '0';
begin
    top_0: i2s_playback
    GENERIC MAP(d_width => 16, points => 190, modpoints => 999, amp => 256)
    PORT MAP(adder => '1', reset_n => '1', clock => clock, mclk => master_clk, sclk => adc_sclk, 
    sclk_dac => sclk_dac, ws => adc_ws, sd_rx => sd_rx, ldac => ldac, cs => dac_cs, sd_tx => sd_tx);
process
  begin
    while now < 1 sec  loop -- set the simulation time as desired
      clock <= not clock;
      wait for 5 ns; -- set the clock period as desired
    end loop;
    wait;
  end process;
  
  process(adc_sclk)
  variable ILine : Line;
  variable ch_in : bit;
  variable ch : character;
  variable wscnt : integer := 0;
  variable feed : integer := 0;
  begin
  file_open(vectors, "C:/Users/thakk/radio3/input.txt", READ_MODE);
  readline(vectors, ILine);
  if(adc_sclk'event) then
    wscnt := wscnt + 1;
    if(wscnt = 50) then
    readline(vectors, ILine);
    wscnt := 0;
    end if;
    if(wscnt > 2 AND adc_sclk = '0') then
        if(feed < 2) then
            feed := feed + 1;
            sd_rx <= to_stdulogic(ch_in);
        else
            feed := 0;
            read(ILine, ch_in);
            sd_rx <= to_stdulogic(ch_in);
        end if;
    end if;
  end if;
  end process;
  
process(sclk_dac)
  variable ILine : Line;
  variable ch_out : bit;
  variable ch : character;
  variable sclk : integer := 0;
  begin
  file_open(results, "C:/Users/thakk/radio3/output.txt", WRITE_MODE);
  if(sclk_dac = '1' AND dac_cs = '0') then
    if(sclk < 16) then
    sclk := sclk + 1;
    ch_out := to_bit(sd_tx);
    write(ILine, ch_out, right);
    else
    sclk := 0;
    writeline(results, ILine);
    file_close(results);
    end if;
  end if;
  end process;
end architecture io;