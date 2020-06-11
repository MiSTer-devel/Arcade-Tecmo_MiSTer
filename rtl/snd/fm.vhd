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

-- Frequency-modulation (FM) sounds are handled by the YM3526 (OPL2) chip.
--
-- We are using an implementation of the YM3526 by Aleksander Osman.
entity fm is
  generic (
    -- clock frequency (in MHz)
    CLK_FREQ : real
  );
  port (
    reset : in std_logic;
    clk   : in std_logic;

    irq_n : out std_logic;

    cs   : in std_logic;
    a0   : in std_logic;
    dout : out std_logic_vector(7 downto 0);
    din  : in std_logic_vector(7 downto 0);
    we   : in std_logic;

    sample : out signed(15 downto 0)
  );
end entity fm;

architecture arch of fm is
  signal opl_dout : std_logic_vector(7 downto 0);
  signal opl_kon : std_logic_vector(8 downto 0);

  component opl2 is
    generic (
      CLK_FREQ : real
    );
    port (
      rst   : in std_logic;
      clk   : in std_logic;
      irq_n : out std_logic;

      a0   : in std_logic;
      dout : out std_logic_vector(7 downto 0);
      din  : in std_logic_vector(7 downto 0);
      we   : in std_logic;

      sample : out signed(15 downto 0)
    );
  end component opl2;
begin
  opl2_inst : component opl2
  generic map (
    CLK_FREQ => CLK_FREQ
  )
  port map (
    rst   => reset,
    clk   => clk,
    irq_n => irq_n,

    a0   => a0,
    din  => din,
    dout => opl_dout,
    we   => cs and we,

    sample => sample
  );

  dout <= opl_dout when cs = '1' else (others => '0');
end architecture arch;
