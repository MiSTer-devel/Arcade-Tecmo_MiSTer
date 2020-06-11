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

-- The character layer is the part of the graphics pipeline that handles things
-- like the logo, score, playfield, and other static graphics.
--
-- It consists of a 32x32 grid of 8x8 tiles.
entity char_layer is
  generic (
    RAM_ADDR_WIDTH : natural;
    RAM_DATA_WIDTH : natural;
    ROM_ADDR_WIDTH : natural;
    ROM_DATA_WIDTH : natural
  );
  port (
    -- clock signals
    clk : in std_logic;
    cen : in std_logic;

    -- configuration
    config : in tile_config_t;

    -- control signals
    busy : out std_logic;
    flip : in std_logic;

    -- char RAM
    ram_addr : out unsigned(RAM_ADDR_WIDTH-1 downto 0);
    ram_data : in std_logic_vector(RAM_DATA_WIDTH-1 downto 0);

    -- tile ROM
    rom_addr : out unsigned(ROM_ADDR_WIDTH-1 downto 0);
    rom_data : in std_logic_vector(ROM_DATA_WIDTH-1 downto 0);

    -- video signals
    video : in video_t;

    -- graphics data
    data : out byte_t
  );
end char_layer;

architecture arch of char_layer is
  -- tile signals
  signal tile     : tile_t;
  signal color    : color_t;
  signal pixel    : pixel_t;
  signal tile_row : row_t;

  -- line buffer signals
  signal line_buffer_swap   : std_logic;
  signal line_buffer_addr_a : unsigned(LINE_BUFFER_ADDR_WIDTH-1 downto 0);
  signal line_buffer_din_a  : std_logic_vector(LINE_BUFFER_DATA_WIDTH-1 downto 0);
  signal line_buffer_we_a   : std_logic;
  signal line_buffer_addr_b : unsigned(LINE_BUFFER_ADDR_WIDTH-1 downto 0);
  signal line_buffer_dout_b : std_logic_vector(LINE_BUFFER_DATA_WIDTH-1 downto 0);

  -- flipped vertical position
  signal flip_y : unsigned(7 downto 0);

  -- destination position
  signal dest_pos : pos_t;

  -- aliases to extract the components of the horizontal and vertical position
  alias col      : unsigned(4 downto 0) is dest_pos.x(7 downto 3);
  alias row      : unsigned(4 downto 0) is dest_pos.y(7 downto 3);
  alias offset_x : unsigned(2 downto 0) is dest_pos.x(2 downto 0);
  alias offset_y : unsigned(2 downto 0) is dest_pos.y(2 downto 0);
begin
  -- A line buffer is used to cache pixel data for the next scanline.
  --
  -- It is not present in the original arcade hardware, but it hugely
  -- simplifies screen flipping because you only have to reverse the line
  -- buffer, instead of having to decode tiles in reverse.
  line_buffer : entity work.line_buffer
  generic map (
    ADDR_WIDTH => LINE_BUFFER_ADDR_WIDTH,
    DATA_WIDTH => LINE_BUFFER_DATA_WIDTH
  )
  port map (
    clk   => clk,

    swap => line_buffer_swap,

    -- port A (write)
    addr_a => line_buffer_addr_a,
    din_a  => line_buffer_din_a,
    we_a   => line_buffer_we_a,

    -- port B (read)
    addr_b => line_buffer_addr_b,
    dout_b => line_buffer_dout_b
  );

  -- Load tile data from the character RAM.
  --
  -- While the current tile is being rendered, we need to fetch data for the
  -- next tile ahead, so that it is loaded in time to render it on the screen.
  --
  -- The 16-bit tile data words aren't stored contiguously in RAM, instead they
  -- are split into high and low bytes. The high bytes are stored in the
  -- upper-half of the RAM, while the low bytes are stored in the lower-half.
  --
  -- We latch the tile code well before the end of the row, to allow the GPU
  -- enough time to fetch pixel data from the tile ROM.
  tile_data_pipeline : process (clk)
  begin
    if rising_edge(clk) then
      if cen = '1' then
        case to_integer(offset_x) is
          when 0 =>
            -- load next tile
            ram_addr <= row & (col+1);

          when 1 =>
            -- latch tile
            tile <= decode_tile(config, ram_data);

          when 7 =>
            -- latch row data
            tile_row <= rom_data;

            -- latch tile color
            color <= tile.color;

          when others => null;
        end case;
      end if;
    end if;
  end process;

  -- latch graphics data from the line buffer
  latch_gfx_data : process (clk)
  begin
    if rising_edge(clk) then
      if cen = '1' then
        data <= line_buffer_dout_b;
      end if;
    end if;
  end process;

  -- set flipped vertical position to be one scanline ahead/behind
  flip_y <= (not video.pos.y(7 downto 0))-1 when flip = '1' else
            video.pos.y(7 downto 0)+1;

  -- set destination position
  dest_pos.x <= resize(video.pos.x, dest_pos.x'length);
  dest_pos.y <= resize(flip_y, dest_pos.y'length);

  -- set tile ROM address
  rom_addr <= tile.code(9 downto 0) & offset_y(2 downto 0);

  -- select pixel from the tile row data
  pixel <= select_pixel(tile_row, offset_x);

  -- swap line buffer on alternating rows
  line_buffer_swap <= video.pos.y(0);

  -- write line buffer
  line_buffer_addr_a <= not video.pos.x(7 downto 0) when flip = '1' else video.pos.x(7 downto 0);
  line_buffer_din_a  <= color & pixel;
  line_buffer_we_a   <= not video.hblank;

  -- read line buffer two pixels ahead
  line_buffer_addr_b <= video.pos.x(7 downto 0)+2;

  -- set busy signal
  busy <= '0';
end architecture arch;
