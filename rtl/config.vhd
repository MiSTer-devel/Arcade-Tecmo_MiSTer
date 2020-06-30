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

use work.types.all;

-- This package contains the configuration values for Rygar, Gemini Wing, and
-- Silkworm.
--
-- These games all very similar, but there are some notable differences to
-- their memory maps and graphics data encodings.
package config is
  constant RYGAR_MEM_MAP : mem_map_t := (
    prog_rom_1  => (x"0000", x"bfff"),
    work_ram    => (x"c000", x"cfff"),
    char_ram    => (x"d000", x"d7ff"),
    fg_ram      => (x"d800", x"dbff"),
    bg_ram      => (x"dc00", x"dfff"),
    sprite_ram  => (x"e000", x"e7ff"),
    palette_ram => (x"e800", x"efff"),
    prog_rom_2  => (x"f000", x"f7ff"),
    fg_scroll   => (x"f800", x"f802"),
    bg_scroll   => (x"f803", x"f805"),
    sound       => (x"f806", x"f806"),
    flip        => (x"f807", x"f807"),
    bank        => (x"f808", x"f808"),
    joy_1       => (x"f800", x"f800"),
    buttons_1   => (x"f801", x"f801"),
    joy_2       => (x"f802", x"f802"),
    buttons_2   => (x"f803", x"f803"),
    coin        => (x"f804", x"f804"),
    dip_sw_1    => (x"f806", x"f807"),
    dip_sw_2    => (x"f808", x"f809")
  );

  constant GEMINI_MEM_MAP : mem_map_t := (
    prog_rom_1  => (x"0000", x"bfff"),
    work_ram    => (x"c000", x"cfff"),
    char_ram    => (x"d000", x"d7ff"),
    fg_ram      => (x"d800", x"dbff"),
    bg_ram      => (x"dc00", x"dfff"),
    palette_ram => (x"e000", x"e7ff"),
    sprite_ram  => (x"e800", x"efff"),
    prog_rom_2  => (x"f000", x"f7ff"),
    fg_scroll   => (x"f800", x"f802"),
    bg_scroll   => (x"f803", x"f805"),
    sound       => (x"f806", x"f806"),
    flip        => (x"f807", x"f807"),
    bank        => (x"f808", x"f808"),
    joy_1       => (x"f800", x"f800"),
    buttons_1   => (x"f801", x"f801"),
    joy_2       => (x"f802", x"f802"),
    buttons_2   => (x"f803", x"f803"),
    coin        => (x"f805", x"f805"),
    dip_sw_1    => (x"f806", x"f807"),
    dip_sw_2    => (x"f808", x"f809")
  );

  constant SILKWORM_MEM_MAP : mem_map_t := (
    prog_rom_1  => (x"0000", x"bfff"),
    bg_ram      => (x"c000", x"c3ff"),
    fg_ram      => (x"c400", x"c7ff"),
    char_ram    => (x"c800", x"cfff"),
    work_ram    => (x"d000", x"dfff"),
    sprite_ram  => (x"e000", x"e7ff"),
    palette_ram => (x"e800", x"efff"),
    prog_rom_2  => (x"f000", x"f7ff"),
    fg_scroll   => (x"f800", x"f802"),
    bg_scroll   => (x"f803", x"f805"),
    sound       => (x"f806", x"f806"),
    flip        => (x"f807", x"f807"),
    bank        => (x"f808", x"f808"),
    joy_1       => (x"f800", x"f800"),
    buttons_1   => (x"f801", x"f801"),
    joy_2       => (x"f802", x"f802"),
    buttons_2   => (x"f803", x"f803"),
    dip_sw_1    => (x"f806", x"f807"),
    dip_sw_2    => (x"f808", x"f809"),
    coin        => (x"f80f", x"f80f")
  );

  constant RYGAR_SND_MAP : snd_map_t := (
    prog_rom => (x"0000", x"3fff"),
    work_ram => (x"4000", x"47ff"),
    fm       => (x"8000", x"8001"),
    req      => (x"c000", x"c000"),
    pcm_lo   => (x"c000", x"c000"),
    pcm_hi   => (x"d000", x"d000"),
    pcm_vol  => (x"e000", x"e000"),
    req_off  => (x"f000", x"f000")
  );

  constant GEMINI_SND_MAP : snd_map_t := (
    prog_rom => (x"0000", x"7fff"),
    work_ram => (x"8000", x"87ff"),
    fm       => (x"a000", x"a001"),
    req      => (x"c000", x"c000"),
    pcm_lo   => (x"c000", x"c000"),
    pcm_hi   => (x"c400", x"c400"),
    pcm_vol  => (x"c800", x"c800"),
    req_off  => (x"cc00", x"cc00")
  );

  --  byte   bit        description
  -- ------+-76543210-+-------------
  --     0 | xxxx---- | hi code
  --       | -----x-- | enable
  --       | ------x- | flip y
  --       | -------x | flip x
  --     1 | xxxxxxxx | lo code
  --     2 | ------xx | size
  --     3 | xx-------| priority
  --       | --x----- | hi pos y
  --       | ---x---- | hi pos x
  --       | ----xxxx | colour
  --     4 | xxxxxxxx | lo pos y
  --     5 | xxxxxxxx | lo pos x
  --     6 | -------- |
  --     7 | -------- |
  constant DEFAULT_SPRITE_CONFIG : sprite_config_t := (
    flip_x_bit   => 0,
    flip_y_bit   => 1,
    enable_bit   => 2,
    hi_code_lsb  => 4,
    hi_code_msb  => 7,
    lo_code_lsb  => 8,
    lo_code_msb  => 15,
    size_lsb     => 16,
    size_msb     => 17,
    color_lsb    => 24,
    color_msb    => 27,
    hi_pos_x_bit => 28,
    hi_pos_y_bit => 29,
    priority_lsb => 30,
    priority_msb => 31,
    lo_pos_y_lsb => 32,
    lo_pos_y_msb => 39,
    lo_pos_x_lsb => 40,
    lo_pos_x_msb => 47
  );

  -- The only difference with Gemini/Silkworm is that the upper portion of the
  -- tile code is 5 bit wide.
  --
  --  byte   bit        description
  -- ------+-76543210-+-------------
  --     0 | xxxxx--- | hi code
  --       | -----x-- | enable
  --       | ------x- | flip y
  --       | -------x | flip x
  --     1 | xxxxxxxx | lo code
  --     2 | ------xx | size
  --     3 | xx-------| priority
  --       | --x----- | hi pos y
  --       | ---x---- | hi pos x
  --       | ----xxxx | colour
  --     4 | xxxxxxxx | lo pos y
  --     5 | xxxxxxxx | lo pos x
  --     6 | -------- |
  --     7 | -------- |
  constant GEMINI_SPRITE_CONFIG : sprite_config_t := (
    flip_x_bit   => 0,
    flip_y_bit   => 1,
    enable_bit   => 2,
    hi_code_lsb  => 3,
    hi_code_msb  => 7,
    lo_code_lsb  => 8,
    lo_code_msb  => 15,
    size_lsb     => 16,
    size_msb     => 17,
    color_lsb    => 24,
    color_msb    => 27,
    hi_pos_x_bit => 28,
    hi_pos_y_bit => 29,
    priority_lsb => 30,
    priority_msb => 31,
    lo_pos_y_lsb => 32,
    lo_pos_y_msb => 39,
    lo_pos_x_lsb => 40,
    lo_pos_x_msb => 47
  );

  constant DEFAULT_TILE_CONFIG : tile_config_t := (
    lo_code_lsb => 0,
    lo_code_msb => 7,
    hi_code_lsb => 8,
    hi_code_msb => 10,
    color_lsb   => 12,
    color_msb   => 15
  );

  constant GEMINI_TILE_CONFIG : tile_config_t := (
    lo_code_lsb => 0,
    lo_code_msb => 7,
    hi_code_lsb => 12,
    hi_code_msb => 14,
    color_lsb   => 8,
    color_msb   => 11
  );

  constant RYGAR_GAME_CONFIG : game_config_t := (
    mem_map    => RYGAR_MEM_MAP,
    snd_map    => RYGAR_SND_MAP,
    gpu_config => (DEFAULT_TILE_CONFIG, DEFAULT_TILE_CONFIG, DEFAULT_TILE_CONFIG, DEFAULT_SPRITE_CONFIG)
  );

  constant GEMINI_GAME_CONFIG : game_config_t := (
    mem_map    => GEMINI_MEM_MAP,
    snd_map    => GEMINI_SND_MAP,
    gpu_config => (DEFAULT_TILE_CONFIG, GEMINI_TILE_CONFIG, GEMINI_TILE_CONFIG, GEMINI_SPRITE_CONFIG)
  );

  constant SILKWORM_GAME_CONFIG : game_config_t := (
    mem_map    => SILKWORM_MEM_MAP,
    snd_map    => GEMINI_SND_MAP,
    gpu_config => (DEFAULT_TILE_CONFIG, DEFAULT_TILE_CONFIG, DEFAULT_TILE_CONFIG, GEMINI_SPRITE_CONFIG)
  );
end package config;
