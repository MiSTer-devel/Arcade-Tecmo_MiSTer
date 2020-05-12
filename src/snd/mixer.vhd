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

library ieee_proposed;
use ieee_proposed.fixed_float_types.all;
use ieee_proposed.fixed_pkg.all;

use work.common.all;

entity mixer is
  generic (
    GAIN_0 : real := 1.0;
    GAIN_1 : real := 1.0
  );
  port (
    ch0 : in audio_t;
    ch1 : in audio_t;
    mix : out audio_t
  );
end entity mixer;

architecture arch of mixer is
  signal g0 : sfixed(4 downto -4);
  signal g1 : sfixed(4 downto -4);

  signal c0 : sfixed(20 downto -4);
  signal c1 : sfixed(20 downto -4);
begin
  -- convert the gains to fixed-point values
  g0 <= to_sfixed(GAIN_0, g0);
  g1 <= to_sfixed(GAIN_1, g1);

  -- apply the gain values to each channel
  c0 <= to_sfixed(ch0, 15, 0) * g0;
  c1 <= to_sfixed(ch1, 15, 0) * g1;

  -- sum the channels
  mix <= to_signed(
    c0 + c1,
    mix'length,
    fixed_saturate, -- saturate (clip) the summed value
    fixed_truncate  -- truncate the fractional bits
  );
end architecture arch;
