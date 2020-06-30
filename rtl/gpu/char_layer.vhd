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
    ROM_ADDR_WIDTH : natural;
    ROM_DATA_WIDTH : natural
  );
  port (
    -- reset
    reset : in std_logic;

    -- clock signals
    clk : in std_logic;
    cen : in std_logic;

    -- configuration
    config : in tile_config_t;

    -- control signals
    busy : buffer std_logic;
    flip : in std_logic;

    -- char RAM
    ram_cs   : in std_logic;
    ram_we   : in std_logic;
    ram_addr : in unsigned(CHAR_RAM_CPU_ADDR_WIDTH-1 downto 0);
    ram_din  : in byte_t;
    ram_dout : out byte_t;

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
  signal ram_addr_b : unsigned(CHAR_RAM_GPU_ADDR_WIDTH-1 downto 0) := (others => '0');
  signal ram_dout_b : std_logic_vector(CHAR_RAM_GPU_DATA_WIDTH-1 downto 0);

  signal ram_cs_rising : std_logic;

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
  -- The character RAM (2kB) contains the code and colour of each tile in the
  -- tilemap.
  char_ram : entity work.true_dual_port_ram
  generic map (
    ADDR_WIDTH_A => CHAR_RAM_CPU_ADDR_WIDTH,
    ADDR_WIDTH_B => CHAR_RAM_GPU_ADDR_WIDTH,
    DATA_WIDTH_B => CHAR_RAM_GPU_DATA_WIDTH
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
    clk => clk,

    swap => line_buffer_swap,

    -- port A (write)
    addr_a => line_buffer_addr_a,
    din_a  => line_buffer_din_a,
    we_a   => line_buffer_we_a,

    -- port B (read)
    addr_b => line_buffer_addr_b,
    dout_b => line_buffer_dout_b
  );

  -- detect rising edges of the RAM_CS signal
  ram_cs_edge_detector : entity work.edge_detector
  generic map (RISING => true)
  port map (
    clk  => clk,
    data => ram_cs,
    q    => ram_cs_rising
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
            ram_addr_b <= row & (col+1);

          when 1 =>
            -- latch tile
            tile <= decode_tile(config, ram_dout_b);

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

  -- The busy signal is asserted when the CPU requests VRAM access. It is
  -- deasserted after the tile data has been latched.
  latch_busy : process (clk, reset)
  begin
    if reset = '1' then
      busy <= '0';
    elsif rising_edge(clk) then
      if cen = '1' then
        if to_integer(offset_x) = 5 then
          busy <= '0';
        elsif ram_cs_rising = '1' then
          busy <= '1';
        end if;
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
end architecture arch;
