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

-- The PCM counter increments an address range in nibbles.
--
-- The address is used to load data from the PCM ROM.
entity pcm_counter is
  generic (
    ADDR_WIDTH : natural
  );
  port (
    reset : in std_logic;

    clk : in std_logic;
    vck : in std_logic;

    data     : in byte_t;
    we       : in std_logic;
    set_low  : in std_logic;
    set_high : in std_logic;

    -- output address
    addr : out unsigned(ADDR_WIDTH-1 downto 0);

    -- The nibble signal is asserted when the high nibble should be loaded from
    -- the PCM ROM. Otherwise the low nibble should be loaded from the PCM rom.
    nibble : out std_logic;

    -- The done signal is asserted when the counter has reached the end
    -- address.
    done : buffer std_logic
  );
end pcm_counter;

architecture rtl of pcm_counter is
  signal vck_falling : std_logic;

  -- registers
  signal ctr     : unsigned(ADDR_WIDTH+1 downto 0);
  signal ctr_end : unsigned(7 downto 0);
begin
  -- detect falling edges of the VCK signal
  vck_edge_detector : entity work.edge_detector
  generic map (FALLING => true)
  port map (
    clk  => clk,
    data => vck,
    q    => vck_falling
  );

  latch_comp : process (clk, reset)
  begin
    if reset = '1' then
      ctr_end <= (others => '0');
    elsif rising_edge(clk) then
      if set_high = '1' and we = '1' then
        ctr_end <= unsigned(data);
      end if;
    end if;
  end process;

  latch_counter : process (clk, reset)
  begin
    if reset = '1' then
      ctr <= (others => '0');
    elsif rising_edge(clk) then
      if set_low = '1' and we = '1' then
        ctr(ADDR_WIDTH+1 downto ADDR_WIDTH-6) <= unsigned(data);
        ctr(ADDR_WIDTH-7 downto 0) <= (others => '0');
      elsif vck_falling = '1' and done = '0' then
        ctr <= ctr + 1;
      end if;
    end if;
  end process;

  -- set the address and nibble
  addr   <= ctr(ADDR_WIDTH downto 1);
  nibble <= not ctr(0);

  -- set the done signal
  done <= '1' when ctr_end = ctr(ADDR_WIDTH+1 downto ADDR_WIDTH-6) else '0';
end rtl;
