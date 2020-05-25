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

-- Pulse-code modulation (PCM) sounds are handled by the MSM5205 chip.
--
-- We are using an implelmentation of the MSM5205 by Jose Tejada:
-- https://github.com/jotego/jt5205
entity pcm is
  port (
    reset  : in std_logic;
    clk    : in std_logic;
    cen    : in std_logic;
    din    : in std_logic_vector(3 downto 0);
    sample : out signed(15 downto 0);
    irq    : out std_logic
  );
end entity pcm;

architecture arch of pcm is
  signal sound : signed(11 downto 0);

  component jt5205 is
    port (
      rst   : in std_logic;
      clk   : in std_logic;
      cen   : in std_logic;
      sel   : in std_logic_vector(1 downto 0);
      din   : in std_logic_vector(3 downto 0);
      sound : out signed(11 downto 0);
      irq   : out std_logic
    );
  end component jt5205;
begin
  jt5205_inst : component jt5205
  port map (
    rst   => reset,
    clk   => clk,
    cen   => cen,
    sel   => "10",
    din   => din,
    sound => sound,
    irq   => irq
  );

  sample <= sound(11) & sound & "000";
end architecture arch;
