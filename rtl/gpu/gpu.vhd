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

-- The graphical processing unit (GPU) implements the graphical layers of the
-- original arcade hardware.
--
-- The VRAM has been implemented using a dual-port RAM, because both the CPU
-- and the GPU need to access the VRAM concurrently. Port A is connected to the
-- CPU data bus, port B is connected to the GPU.
--
-- This differs from the original arcade hardware, which only contains
-- single-port RAM. Using a dual-port RAM instead simplifies things, because we
-- don't need all the additional logic required to coordinate RAM access.
entity gpu is
  generic (
    CHAR_LAYER_ENABLE   : boolean := true;
    FG_LAYER_ENABLE     : boolean := true;
    BG_LAYER_ENABLE     : boolean := true;
    SPRITE_LAYER_ENABLE : boolean := true
  );
  port (
    -- reset
    reset : in std_logic;

    -- clock signals
    clk : in std_logic;
    cen : in std_logic;

    -- configuration
    config : in gpu_config_t;

    -- control signals
    busy : out std_logic;
    flip : in std_logic;

    -- RAM interface
    ram_we   : in std_logic;
    ram_addr : in unsigned(CPU_ADDR_WIDTH-1 downto 0);
    ram_din  : in byte_t;
    ram_dout : out byte_t;

    -- tile ROM interface
    char_rom_addr   : out unsigned(CHAR_ROM_ADDR_WIDTH-1 downto 0) := (others => '0');
    char_rom_data   : in std_logic_vector(CHAR_ROM_DATA_WIDTH-1 downto 0);
    fg_rom_addr     : out unsigned(FG_ROM_ADDR_WIDTH-1 downto 0) := (others => '0');
    fg_rom_data     : in std_logic_vector(FG_ROM_DATA_WIDTH-1 downto 0);
    bg_rom_addr     : out unsigned(BG_ROM_ADDR_WIDTH-1 downto 0) := (others => '0');
    bg_rom_data     : in std_logic_vector(BG_ROM_DATA_WIDTH-1 downto 0);
    sprite_rom_addr : out unsigned(SPRITE_ROM_ADDR_WIDTH-1 downto 0) := (others => '0');
    sprite_rom_data : in std_logic_vector(SPRITE_ROM_DATA_WIDTH-1 downto 0);

    -- chip select signals
    char_ram_cs    : in std_logic;
    fg_ram_cs      : in std_logic;
    bg_ram_cs      : in std_logic;
    sprite_ram_cs  : in std_logic;
    palette_ram_cs : in std_logic;

    -- scroll layer positions
    fg_scroll_pos : in pos_t;
    bg_scroll_pos : in pos_t;

    -- video signals
    video : buffer video_t;
    rgb   : out rgb_t
  );
end gpu;

architecture arch of gpu is
  -- character RAM
  signal char_ram_addr : unsigned(CHAR_RAM_CPU_ADDR_WIDTH-1 downto 0);
  signal char_ram_dout : byte_t;

  -- foreground RAM
  signal fg_ram_addr : unsigned(SCROLL_RAM_CPU_ADDR_WIDTH-1 downto 0);
  signal fg_ram_dout : byte_t;

  -- background RAM
  signal bg_ram_addr : unsigned(SCROLL_RAM_CPU_ADDR_WIDTH-1 downto 0);
  signal bg_ram_dout : byte_t;

  -- sprite RAM
  signal sprite_ram_dout : byte_t;

  -- palette RAM
  signal palette_ram_dout : byte_t;

  -- layer output signals
  signal char_data   : byte_t := (others => '0');
  signal fg_data     : byte_t := (others => '0');
  signal bg_data     : byte_t := (others => '0');
  signal sprite_data : byte_t := (others => '0');

  -- busy signals
  signal char_busy    : std_logic;
  signal fg_busy      : std_logic;
  signal bg_busy      : std_logic;
  signal sprite_busy  : std_logic;
  signal palette_busy : std_logic;

  -- sprite priority data
  signal sprite_priority : priority_t;
begin
  -- video timing generator
  video_gen : entity work.video_gen
  port map (
    clk   => clk,
    cen   => cen,
    video => video
  );

  char_layer_gen : if CHAR_LAYER_ENABLE generate
    -- character layer
    char_layer : entity work.char_layer
    generic map (
      ROM_ADDR_WIDTH => CHAR_ROM_ADDR_WIDTH,
      ROM_DATA_WIDTH => CHAR_ROM_DATA_WIDTH
    )
    port map (
      -- clock signals
      clk => clk,
      cen => cen,

      -- configuration
      config => config.char_config,

      -- control signals
      busy => char_busy,
      flip => flip,

      -- RAM interface
      ram_cs   => char_ram_cs,
      ram_we   => ram_we,
      ram_addr => char_ram_addr,
      ram_din  => ram_din,
      ram_dout => char_ram_dout,

      -- ROM interface
      rom_addr => char_rom_addr,
      rom_data => char_rom_data,

      -- video signals
      video => video,
      data  => char_data
    );
  end generate;

  fg_layer_gen : if FG_LAYER_ENABLE generate
    -- foreground layer
    fg_layer : entity work.scroll_layer
    generic map (
      ROM_ADDR_WIDTH => FG_ROM_ADDR_WIDTH,
      ROM_DATA_WIDTH => FG_ROM_DATA_WIDTH
    )
    port map (
      -- clock signals
      clk => clk,
      cen => cen,

      -- configuration
      config => config.fg_config,

      -- control signals
      busy => fg_busy,
      flip => flip,

      -- RAM interface
      ram_cs   => fg_ram_cs,
      ram_we   => ram_we,
      ram_addr => fg_ram_addr,
      ram_din  => ram_din,
      ram_dout => fg_ram_dout,

      -- ROM interface
      rom_addr => fg_rom_addr,
      rom_data => fg_rom_data,

      -- video signals
      video      => video,
      scroll_pos => fg_scroll_pos,
      data       => fg_data
    );
  end generate;

  bg_layer_gen : if BG_LAYER_ENABLE generate
    -- background layer
    bg_layer : entity work.scroll_layer
    generic map (
      ROM_ADDR_WIDTH => BG_ROM_ADDR_WIDTH,
      ROM_DATA_WIDTH => BG_ROM_DATA_WIDTH
    )
    port map (
      -- clock signals
      clk => clk,
      cen => cen,

      -- configuration
      config => config.bg_config,

      -- control signals
      busy => bg_busy,
      flip => flip,

      -- RAM interface
      ram_cs   => bg_ram_cs,
      ram_we   => ram_we,
      ram_addr => bg_ram_addr,
      ram_din  => ram_din,
      ram_dout => bg_ram_dout,

      -- ROM interface
      rom_addr => bg_rom_addr,
      rom_data => bg_rom_data,

      -- video signals
      video      => video,
      scroll_pos => bg_scroll_pos,
      data       => bg_data
    );
  end generate;

  sprite_layer_gen : if SPRITE_LAYER_ENABLE generate
    -- sprite layer
    sprite_layer : entity work.sprite_layer
    generic map (
      ROM_ADDR_WIDTH => SPRITE_ROM_ADDR_WIDTH,
      ROM_DATA_WIDTH => SPRITE_ROM_DATA_WIDTH
    )
    port map (
      -- clock signals
      clk => clk,
      cen => cen,

      -- configuration
      config => config.sprite_config,

      -- control signals
      busy => sprite_busy,
      flip => flip,

      -- RAM interface
      ram_cs   => sprite_ram_cs,
      ram_we   => ram_we,
      ram_addr => ram_addr(SPRITE_RAM_CPU_ADDR_WIDTH-1 downto 0),
      ram_din  => ram_din,
      ram_dout => sprite_ram_dout,

      -- ROM interface
      rom_addr => sprite_rom_addr,
      rom_data => sprite_rom_data,

      -- video signals
      video    => video,
      priority => sprite_priority,
      data     => sprite_data
    );
  end generate;

  -- colour palette
  palette : entity work.palette
  port map (
    -- reset
    reset => reset,

    -- clock signals
    clk => clk,
    cen => cen,

    -- control signals
    busy => palette_busy,

    -- RAM interface
    ram_cs   => palette_ram_cs,
    ram_we   => ram_we,
    ram_addr => ram_addr(PALETTE_RAM_CPU_ADDR_WIDTH-1 downto 0),
    ram_din  => ram_din,
    ram_dout => palette_ram_dout,

    -- layer data
    char_data   => char_data,
    fg_data     => fg_data,
    bg_data     => bg_data,
    sprite_data => sprite_data,

    -- sprite priority
    sprite_priority => sprite_priority,

    -- video signals
    video => video,
    rgb   => rgb
  );

  -- Rotate tile RAM addresses
  --
  -- This allows tiles to be stored as 16-bit words (i.e. two contiguous bytes)
  -- in memory, rather than spliting them into high and low bytes stored in the
  -- upper and lower-half of the RAM.
  char_ram_addr <= rotate_left(ram_addr(CHAR_RAM_CPU_ADDR_WIDTH-1 downto 0), 1);
  fg_ram_addr   <= rotate_left(ram_addr(SCROLL_RAM_CPU_ADDR_WIDTH-1 downto 0), 1);
  bg_ram_addr   <= rotate_left(ram_addr(SCROLL_RAM_CPU_ADDR_WIDTH-1 downto 0), 1);

  -- mux GPU data output
  ram_dout <= sprite_ram_dout or
              char_ram_dout or
              fg_ram_dout or
              bg_ram_dout or
              palette_ram_dout;

  -- Set busy signal
  --
  -- The busy signal is asserted when the GPU needs to prevent the CPU from
  -- writing to shared memory.
  busy <= (char_ram_cs and char_busy) or
          (fg_ram_cs and fg_busy) or
          (bg_ram_cs and bg_busy) or
          (sprite_ram_cs and sprite_busy) or
          (palette_ram_cs and palette_busy);
end architecture arch;
