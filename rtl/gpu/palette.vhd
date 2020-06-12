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
use work.types.all;

-- The palette combines data from the different graphics layers to produce an
-- actual RGB value that can be rendered on the screen.
entity palette is
  port (
    -- reset
    reset : in std_logic;

    -- clock signals
    clk : in std_logic;
    cen : in std_logic;

    -- control signals
    busy : buffer std_logic;

    -- palette RAM
    ram_cs   : in std_logic;
    ram_we   : in std_logic;
    ram_addr : in unsigned(PALETTE_RAM_CPU_ADDR_WIDTH-1 downto 0);
    ram_din  : in byte_t;
    ram_dout : out byte_t;

    -- layer data
    char_data   : in byte_t;
    fg_data     : in byte_t;
    bg_data     : in byte_t;
    sprite_data : in byte_t;

    -- sprite priority
    sprite_priority : in priority_t;

    -- video signals
    video : in video_t;
    rgb   : out rgb_t
  );
end palette;

architecture arch of palette is
  signal ram_addr_b : unsigned(PALETTE_RAM_GPU_ADDR_WIDTH-1 downto 0);
  signal ram_dout_b : std_logic_vector(PALETTE_RAM_GPU_DATA_WIDTH-1 downto 0);

  -- current layer
  signal layer : layer_t;

  -- pixel register
  signal pixel_reg : rgb_t;
begin
  -- The palette RAM contains 1024 16-bit RGB colour values, stored in
  -- RRRRGGGGXXXXBBBB format.
  palette_ram : entity work.true_dual_port_ram
  generic map (
    ADDR_WIDTH_A => PALETTE_RAM_CPU_ADDR_WIDTH,
    ADDR_WIDTH_B => PALETTE_RAM_GPU_ADDR_WIDTH,
    DATA_WIDTH_B => PALETTE_RAM_GPU_DATA_WIDTH
  )
  port map (
    -- CPU interface
    clk_a  => clk,
    cs_a   => ram_cs,
    we_a   => ram_we and not busy,
    addr_a => ram_addr,
    din_a  => ram_din,
    dout_a => ram_dout,

    -- GPU interface
    clk_b  => clk,
    addr_b => ram_addr_b,
    dout_b => ram_dout_b
  );

  -- latch RGB data from the palette RAM
  latch_rgb_data : process (clk, reset)
  begin
    if reset = '1' then
      pixel_reg.r <= (others => '0');
      pixel_reg.g <= (others => '0');
      pixel_reg.b <= (others => '0');
    elsif rising_edge(clk) then
      if cen = '1' then
        pixel_reg.r <= ram_dout_b(15 downto 12);
        pixel_reg.g <= ram_dout_b(11 downto 8);
        pixel_reg.b <= ram_dout_b(3 downto 0);
      end if;
    end if;
  end process;

  -- set current layer
  layer <= mux_layers(sprite_priority, sprite_data, char_data, fg_data, bg_data);

  -- set palette RAM address
  with layer select
    ram_addr_b <= "00" & unsigned(sprite_data) when SPRITE_LAYER,
                  "01" & unsigned(char_data)   when CHAR_LAYER,
                  "10" & unsigned(fg_data)     when FG_LAYER,
                  "11" & unsigned(bg_data)     when BG_LAYER,
                  "0100000000"                 when FILL_LAYER;

  -- set RGB data
  rgb.r <= pixel_reg.r when video.enable = '1' else (others => '0');
  rgb.g <= pixel_reg.g when video.enable = '1' else (others => '0');
  rgb.b <= pixel_reg.b when video.enable = '1' else (others => '0');

  -- set busy signal
  busy <= ram_cs and video.enable;
end arch;
