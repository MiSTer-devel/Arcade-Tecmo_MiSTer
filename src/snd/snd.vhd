--   __   __     __  __     __         __
--  /\ "-.\ \   /\ \/\ \   /\ \       /\ \
--  \ \ \-.  \  \ \ \_\ \  \ \ \____  \ \ \____
--   \ \_\\"\_\  \ \_____\  \ \_____\  \ \_____\
--    \/_/ \/_/   \/_____/   \/_____/   \/_____/
--   ______     ______       __     ______     ______     ______
--  /\  __ \   /\  == \     /\ \   /\  ___\   /\  ___\   /\__  _\
--  \ \ \/\ \  \ \  __<    _\_\ \  \ \  __\   \ \ \____  \/_/\ \/
--   \ \_____\  \ \_____\ /\_____\  \ \_____\  \ \_____\    \ \_\
--    \/_____/   \/_____/ \/_____/   \/_____/   \/_____/     \/_/
--
-- https://joshbassett.info
-- https://twitter.com/nullobject
-- https://github.com/nullobject
--
-- Copyright (c) 2020 Josh Bassett
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.common.all;

-- The sound subsystem plays both FM and PCM sounds.
--
-- It has its own Z80 CPU that is responsible for starting and stopping sounds
-- in response to requests from the main CPU.
entity snd is
  port (
    -- reset
    reset : in std_logic;

    -- clock signals
    clk     : in std_logic;
    cen_4   : in std_logic;
    cen_384 : in std_logic;

    -- CPU interface
    req  : in std_logic;
    data : in byte_t;

    -- audio data
    audio : out audio_t
  );
end entity snd;

architecture arch of snd is
  -- CPU signals
  signal cpu_addr   : unsigned(CPU_ADDR_WIDTH-1 downto 0);
  signal cpu_din    : byte_t;
  signal cpu_dout   : byte_t;
  signal cpu_mreq_n : std_logic;
  signal cpu_rd_n   : std_logic;
  signal cpu_wr_n   : std_logic;
  signal cpu_rfsh_n : std_logic;
  signal cpu_nmi_n  : std_logic := '1';
  signal cpu_int_n  : std_logic := '1';

  -- chip select signals
  signal sound_rom_1_cs : std_logic;
  signal sound_ram_cs   : std_logic;
  signal req_cs         : std_logic;
  signal req_off_cs     : std_logic;

  -- data signals
  signal sound_rom_1_data : byte_t;
  signal sound_rom_2_data : byte_t;
  signal sound_ram_data   : byte_t;
  signal req_data         : byte_t;

  -- registers
  signal data_reg : byte_t;

  -- FM signals
  signal fm_cs     : std_logic;
  signal fm_data   : byte_t;
  signal fm_sample : audio_t;

  -- PCM signals
  signal pcm_low_cs  : std_logic;
  signal pcm_high_cs : std_logic;
  signal pcm_vol_cs  : std_logic;
  signal pcm_addr    : unsigned(SOUND_ROM_2_ADDR_WIDTH-1 downto 0);
  signal pcm_nibble  : std_logic;
  signal pcm_done    : std_logic;
  signal pcm_vck     : std_logic;
  signal pcm_data    : nibble_t;
  signal pcm_sample  : audio_t;
begin
  cpu : entity work.T80s
  port map (
    RESET_n     => not reset,
    CLK         => clk,
    CEN         => cen_4,
    INT_n       => cpu_int_n,
    NMI_n       => cpu_nmi_n,
    MREQ_n      => cpu_mreq_n,
    IORQ_n      => open,
    RD_n        => cpu_rd_n,
    WR_n        => cpu_wr_n,
    RFSH_n      => cpu_rfsh_n,
    HALT_n      => open,
    BUSAK_n     => open,
    unsigned(A) => cpu_addr,
    DI          => cpu_din,
    DO          => cpu_dout
  );

  -- sound program ROM
  sound_rom_1 : entity work.single_port_rom
  generic map (
    ADDR_WIDTH => SOUND_ROM_1_ADDR_WIDTH,
    INIT_FILE  => "rom/cpu_4h.mif"
  )
  port map (
    clk  => clk,
    cs   => sound_rom_1_cs,
    addr => cpu_addr(SOUND_ROM_1_ADDR_WIDTH-1 downto 0),
    dout => sound_rom_1_data
  );

  -- PCM ROM
  sound_rom_2 : entity work.single_port_rom
  generic map (
    ADDR_WIDTH => SOUND_ROM_2_ADDR_WIDTH,
    INIT_FILE  => "rom/cpu_1f.mif"
  )
  port map (
    clk  => clk,
    addr => pcm_addr,
    dout => sound_rom_2_data
  );

  -- sound work RAM
  sound_ram : entity work.single_port_ram
  generic map (ADDR_WIDTH => SOUND_RAM_ADDR_WIDTH)
  port map (
    clk  => clk,
    cs   => sound_ram_cs,
    addr => cpu_addr(SOUND_RAM_ADDR_WIDTH-1 downto 0),
    din  => cpu_dout,
    dout => sound_ram_data,
    we   => not cpu_wr_n
  );

  -- FM player
  fm : entity work.fm
  port map (
    reset  => reset,
    clk    => clk,
    irq_n  => cpu_int_n,
    cs     => fm_cs,
    addr   => ('0' & cpu_addr(0)),
    din    => cpu_dout,
    dout   => fm_data,
    we     => not cpu_wr_n,
    sample => fm_sample
  );

  -- PCM address counter
  pcm_counter : entity work.pcm_counter
  generic map (ADDR_WIDTH => SOUND_ROM_2_ADDR_WIDTH)
  port map (
    reset    => reset,
    clk      => clk,
    vck      => pcm_vck,
    data     => cpu_dout,
    we       => not cpu_wr_n,
    set_low  => pcm_low_cs,
    set_high => pcm_high_cs,
    addr     => pcm_addr,
    nibble   => pcm_nibble,
    done     => pcm_done
  );

  -- PCM player
  pcm : entity work.pcm
  port map (
    reset  => pcm_done,
    clk    => clk,
    cen    => cen_384,
    din    => pcm_data,
    sample => pcm_sample,
    irq    => pcm_vck
  );

  -- audio mixer
  mixer : entity work.mixer
  generic map (GAIN_0 => 1.0, GAIN_1 => 0.8)
  port map (
    ch0 => fm_sample,
    ch1 => pcm_sample,
    mix => audio
  );

  nmi : process (clk, reset)
  begin
    if reset = '1' then
      cpu_nmi_n <= '1';
    elsif rising_edge(clk) then
      if req_off_cs = '1' and cpu_wr_n = '0' then
        -- clear NMI
        cpu_nmi_n <= '1';
      elsif req = '1' then
        -- set NMI
        cpu_nmi_n <= '0';

        -- latch input data
        data_reg <= data;
      end if;
    end if;
  end process;

  --  address    description
  -- ----------+-----------------
  -- 0000-3fff | sound ROM #1
  -- 4000-7fff | sound RAM
  -- 8000-bfff | FM
  -- c000-ffff | request
  -- c000-cfff | PCM low
  -- d000-dfff | PCM high
  -- e000-efff | PCM volume
  -- f000-ffff | request off
  sound_rom_1_cs <= '1' when cpu_addr >= x"0000" and cpu_addr <= x"3fff" and cpu_mreq_n = '0' and cpu_rfsh_n = '1' else '0';
  sound_ram_cs   <= '1' when cpu_addr >= x"4000" and cpu_addr <= x"7fff" and cpu_mreq_n = '0' and cpu_rfsh_n = '1' else '0';
  fm_cs          <= '1' when cpu_addr >= x"8000" and cpu_addr <= x"bfff" and cpu_mreq_n = '0' and cpu_rfsh_n = '1' else '0';
  req_cs         <= '1' when cpu_addr >= x"c000" and cpu_addr <= x"ffff" and cpu_mreq_n = '0' and cpu_rfsh_n = '1' else '0';
  pcm_low_cs     <= '1' when cpu_addr >= x"c000" and cpu_addr <= x"cfff" and cpu_mreq_n = '0' and cpu_rfsh_n = '1' else '0';
  pcm_high_cs    <= '1' when cpu_addr >= x"d000" and cpu_addr <= x"dfff" and cpu_mreq_n = '0' and cpu_rfsh_n = '1' else '0';
  pcm_vol_cs     <= '1' when cpu_addr >= x"e000" and cpu_addr <= x"efff" and cpu_mreq_n = '0' and cpu_rfsh_n = '1' else '0';
  req_off_cs     <= '1' when cpu_addr >= x"f000" and cpu_addr <= x"ffff" and cpu_mreq_n = '0' and cpu_rfsh_n = '1' else '0';

  -- set request data
  req_data <= data_reg when req_cs = '1' and cpu_rd_n = '0' else (others => '0');

  -- mux CPU data input
  cpu_din <= sound_rom_1_data or
             sound_ram_data or
             fm_data or
             req_data;

  -- set the PCM data
  pcm_data <= sound_rom_2_data(7 downto 4) when pcm_nibble = '1' else
              sound_rom_2_data(3 downto 0);
end architecture arch;
