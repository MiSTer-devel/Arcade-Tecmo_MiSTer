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

package types is
  -- data types
  subtype nibble_t is std_logic_vector(3 downto 0);
  subtype byte_t is std_logic_vector(7 downto 0);

  -- colour value
  subtype color_t is std_logic_vector(3 downto 0);

  -- pixel value
  subtype pixel_t is std_logic_vector(3 downto 0);

  -- row of pixels in a 8x8 tile
  subtype row_t is std_logic_vector(31 downto 0);

  -- layer priority value
  subtype priority_t is std_logic_vector(1 downto 0);

  -- 16-bit audio sample
  subtype audio_t is signed(15 downto 0);

  -- graphics layer enum
  type layer_t is (SPRITE_LAYER, CHAR_LAYER, FG_LAYER, BG_LAYER, FILL_LAYER);

  -- address range
  type addr_range_t is record
    min : unsigned(15 downto 0);
    max : unsigned(15 downto 0);
  end record addr_range_t;

  -- 2D position
  type pos_t is record
    x : unsigned(8 downto 0);
    y : unsigned(8 downto 0);
  end record pos_t;

  -- 4BPP colour value
  type rgb_t is record
    r : std_logic_vector(3 downto 0);
    g : std_logic_vector(3 downto 0);
    b : std_logic_vector(3 downto 0);
  end record rgb_t;

  -- video signals
  type video_t is record
    -- position
    pos : pos_t;

    -- sync signals
    hsync : std_logic;
    vsync : std_logic;

    -- blank signals
    hblank : std_logic;
    vblank : std_logic;

    -- enable video output
    enable : std_logic;
  end record video_t;

  -- tile descriptor
  type tile_t is record
    code  : unsigned(10 downto 0);
    color : color_t;
  end record tile_t;

  -- sprite descriptor
  type sprite_t is record
    code     : unsigned(12 downto 0);
    color    : color_t;
    enable   : std_logic;
    flip_x   : std_logic;
    flip_y   : std_logic;
    pos      : pos_t;
    priority : priority_t;
    size     : unsigned(6 downto 0);
  end record sprite_t;

  -- memory map
  type mem_map_t is record
    prog_rom_1  : addr_range_t; -- program ROM #1
    work_ram    : addr_range_t; -- work RAM
    char_ram    : addr_range_t; -- character RAM
    fg_ram      : addr_range_t; -- foreground RAM
    bg_ram      : addr_range_t; -- background RAM
    sprite_ram  : addr_range_t; -- sprite RAM
    palette_ram : addr_range_t; -- palette RAM
    prog_rom_2  : addr_range_t; -- program ROM #2 (bank switched)
    fg_scroll   : addr_range_t; -- foreground scroll register
    bg_scroll   : addr_range_t; -- background scroll register
    sound       : addr_range_t; -- sound
    flip        : addr_range_t; -- flip screen
    bank        : addr_range_t; -- bank register
    joy_1       : addr_range_t; -- joystick 1
    buttons_1   : addr_range_t; -- buttons 1
    joy_2       : addr_range_t; -- joystick 2
    buttons_2   : addr_range_t; -- buttons 2
    coin        : addr_range_t; -- coin
    dip_sw_1    : addr_range_t; -- DIP switch #1
    dip_sw_2    : addr_range_t; -- DIP switch #2
  end record mem_map_t;

  type snd_map_t is record
    prog_rom : addr_range_t; -- program ROM
    work_ram : addr_range_t; -- work RAM
    fm       : addr_range_t; -- FM sound
    pcm_lo   : addr_range_t; -- PCM low
    pcm_hi   : addr_range_t; -- PCM high
    pcm_vol  : addr_range_t; -- PCM volume
    req_off  : addr_range_t; -- request off
    req      : addr_range_t; -- request
  end record snd_map_t;

  -- sprite configuration
  type sprite_config_t is record
    hi_code_msb  : natural;
    hi_code_lsb  : natural;
    enable_bit   : natural;
    flip_y_bit   : natural;
    flip_x_bit   : natural;
    lo_code_msb  : natural;
    lo_code_lsb  : natural;
    size_msb     : natural;
    size_lsb     : natural;
    priority_msb : natural;
    priority_lsb : natural;
    hi_pos_y_bit : natural;
    hi_pos_x_bit : natural;
    color_msb    : natural;
    color_lsb    : natural;
    lo_pos_y_msb : natural;
    lo_pos_y_lsb : natural;
    lo_pos_x_msb : natural;
    lo_pos_x_lsb : natural;
  end record sprite_config_t;

  -- tile configuration
  type tile_config_t is record
    hi_code_msb : natural;
    hi_code_lsb : natural;
    lo_code_msb : natural;
    lo_code_lsb : natural;
    color_msb   : natural;
    color_lsb   : natural;
  end record tile_config_t;

  -- GPU configuration
  type gpu_config_t is record
    char_config   : tile_config_t;
    fg_config     : tile_config_t;
    bg_config     : tile_config_t;
    sprite_config : sprite_config_t;
  end record gpu_config_t;

  -- game configuration
  type game_config_t is record
    mem_map    : mem_map_t;
    snd_map    : snd_map_t;
    gpu_config : gpu_config_t;
  end record game_config_t;
end package types;
