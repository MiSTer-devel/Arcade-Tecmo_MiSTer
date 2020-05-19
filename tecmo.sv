//   __   __     __  __     __         __
//  /\ "-.\ \   /\ \/\ \   /\ \       /\ \
//  \ \ \-.  \  \ \ \_\ \  \ \ \____  \ \ \____
//   \ \_\\"\_\  \ \_____\  \ \_____\  \ \_____\
//    \/_/ \/_/   \/_____/   \/_____/   \/_____/
//   ______     ______       __     ______     ______     ______
//  /\  __ \   /\  == \     /\ \   /\  ___\   /\  ___\   /\__  _\
//  \ \ \/\ \  \ \  __<    _\_\ \  \ \  __\   \ \ \____  \/_/\ \/
//   \ \_____\  \ \_____\ /\_____\  \ \_____\  \ \_____\    \ \_\
//    \/_____/   \/_____/ \/_____/   \/_____/   \/_____/     \/_/
//
// https://joshbassett.info
// https://twitter.com/nullobject
// https://github.com/nullobject
//
// Copyright (c) 2020 Josh Bassett
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

module emu
(
  //Master input clock
  input         CLK_50M,

  //Async reset from top-level module.
  //Can be used as initial reset.
  input         RESET,

  //Must be passed to hps_io module
  inout  [45:0] HPS_BUS,

  //Base video clock. Usually equals to CLK_SYS.
  output        VGA_CLK,

  //Multiple resolutions are supported using different VGA_CE rates.
  //Must be based on CLK_VIDEO
  output        VGA_CE,

  output  [7:0] VGA_R,
  output  [7:0] VGA_G,
  output  [7:0] VGA_B,
  output        VGA_HS,
  output        VGA_VS,
  output        VGA_DE,    // = ~(VBlank | HBlank)
  output        VGA_F1,

  //Base video clock. Usually equals to CLK_SYS.
  output        HDMI_CLK,

  //Multiple resolutions are supported using different HDMI_CE rates.
  //Must be based on CLK_VIDEO
  output        HDMI_CE,

  output  [7:0] HDMI_R,
  output  [7:0] HDMI_G,
  output  [7:0] HDMI_B,
  output        HDMI_HS,
  output        HDMI_VS,
  output        HDMI_DE,   // = ~(VBlank | HBlank)
  output  [1:0] HDMI_SL,   // scanlines fx

  //Video aspect ratio for HDMI. Most retro systems have ratio 4:3.
  output  [7:0] HDMI_ARX,
  output  [7:0] HDMI_ARY,

  output        LED_USER,  // 1 - ON, 0 - OFF.

  // b[1]: 0 - LED status is system status OR'd with b[0]
  //       1 - LED status is controled solely by b[0]
  // hint: supply 2'b00 to let the system control the LED.
  output  [1:0] LED_POWER,
  output  [1:0] LED_DISK,

  output [15:0] AUDIO_L,
  output [15:0] AUDIO_R,
  output        AUDIO_S,   // 1 - signed audio samples, 0 - unsigned

  //SDRAM interface with lower latency
  output        SDRAM_CLK,
  output        SDRAM_CKE,
  output [12:0] SDRAM_A,
  output  [1:0] SDRAM_BA,
  inout  [15:0] SDRAM_DQ,
  output        SDRAM_DQML,
  output        SDRAM_DQMH,
  output        SDRAM_nCS,
  output        SDRAM_nCAS,
  output        SDRAM_nRAS,
  output        SDRAM_nWE,

  // Open-drain User port.
  // 0 - D+/RX
  // 1 - D-/TX
  // 2..6 - USR2..USR6
  // Set USER_OUT to 1 to read from USER_IN.
  input   [6:0] USER_IN,
  output  [6:0] USER_OUT
);

assign VGA_F1 = 0;

assign AUDIO_S = 1;
assign AUDIO_R = AUDIO_L;

assign LED_DISK  = 0;
assign LED_POWER = 0;

assign HDMI_ARX = status[1] ? 8'd16 : 8'd4;
assign HDMI_ARY = status[1] ? 8'd9  : 8'd3;

assign SDRAM_CLK = clk_sdram;

`include "build_id.v"
localparam CONF_STR = {
  "A.Tecmo;;",
  "H0O1,Aspect Ratio,Original,Wide;",
  "O35,Scandoubler Fx,None,HQ2x,CRT 25%,CRT 50%,CRT 75%;",
  "-;",
  "O89,Lives,3,4,5,2;",
  "OA,Cabinet,Upright,Cocktail;",
  "OBC,Bonus Life,50K 200K 500K,100K 300K 600K,200K 500K,100K;",
  "ODE,Difficulty,Easy,Normal,Hard,Hardest;",
  "OF,Allow Continue,Yes,No;",
  "-;",
  "R0,Reset;",
  "J1,Fire,Jump,Start,Coin;",
  "V,v",`BUILD_DATE
};

////////////////////////////////////////////////////////////////////////////////
// CLOCKS
////////////////////////////////////////////////////////////////////////////////

wire clk_sys, clk_sdram;
wire cen_12;
wire locked;

pll pll
(
  .refclk(CLK_50M),
  .outclk_0(clk_sys),
  .outclk_1(clk_sdram),
  .locked(locked)
);

////////////////////////////////////////////////////////////////////////////////
// HPS IO
////////////////////////////////////////////////////////////////////////////////

wire  [1:0] buttons;
wire [31:0] status;
wire        forced_scandoubler;
wire [21:0] gamma_bus;
wire        direct_video;

wire [24:0] ioctl_addr;
wire  [7:0] ioctl_data;
wire        ioctl_wr;
wire        ioctl_download;
wire  [7:0] ioctl_index;

wire [10:0] ps2_key;

wire  [8:0] joystick_0, joystick_1;
wire [15:0] joy = joystick_0 | joystick_1;

hps_io #(.STRLEN($size(CONF_STR)>>3)) hps_io
(
  .clk_sys(clk_sys),
  .HPS_BUS(HPS_BUS),

  .conf_str(CONF_STR),

  .buttons(buttons),
  .status(status),
  .status_menumask(direct_video),
  .forced_scandoubler(forced_scandoubler),
  .gamma_bus(gamma_bus),
  .direct_video(direct_video),

  .ioctl_addr(ioctl_addr),
  .ioctl_dout(ioctl_data),
  .ioctl_wr(ioctl_wr),
  .ioctl_download(ioctl_download),
  .ioctl_index(ioctl_index),

  .joystick_0(joystick_0),
  .joystick_1(joystick_1),

  .ps2_key(ps2_key)
);

////////////////////////////////////////////////////////////////////////////////
// VIDEO
////////////////////////////////////////////////////////////////////////////////

wire [3:0] r, g, b;
wire       hsync, vsync;
wire       hblank, vblank;

arcade_video #(256, 224, 12, 0) arcade_video
(
  .*,

  // clock
  .clk_video(clk_sys),
  .ce_pix(cen_12),

  // video
  .RGB_in({r, g, b}),
  .HBlank(hblank),
  .VBlank(vblank),
  .HSync(hsync),
  .VSync(vsync),

  // rotate/aspect
  .no_rotate(1),
  .rotate_ccw(0),
  .fx(status[5:3])
);

////////////////////////////////////////////////////////////////////////////////
// SDRAM
////////////////////////////////////////////////////////////////////////////////

wire [22:0] sdram_addr;
wire [31:0] sdram_data;
wire        sdram_we;
wire        sdram_req;
wire        sdram_ack;
wire        sdram_valid;
wire [31:0] sdram_q;

sdram #(.CLK_FREQ(48.0)) sdram
(
  .reset(~locked),
  .clk(clk_sys),

  // controller interface
  .addr(sdram_addr),
  .data(sdram_data),
  .we(sdram_we),
  .req(sdram_req),
  .ack(sdram_ack),
  .valid(sdram_valid),
  .q(sdram_q),

  // SDRAM interface
  .sdram_a(SDRAM_A),
  .sdram_ba(SDRAM_BA),
  .sdram_dq(SDRAM_DQ),
  .sdram_cke(SDRAM_CKE),
  .sdram_cs_n(SDRAM_nCS),
  .sdram_ras_n(SDRAM_nRAS),
  .sdram_cas_n(SDRAM_nCAS),
  .sdram_we_n(SDRAM_nWE),
  .sdram_dqml(SDRAM_DQML),
  .sdram_dqmh(SDRAM_DQMH)
);

////////////////////////////////////////////////////////////////////////////////
// CONTROLS
////////////////////////////////////////////////////////////////////////////////

wire       pressed = ps2_key[9];
wire [7:0] code    = ps2_key[7:0];

reg key_left  = 0;
reg key_right = 0;
reg key_down  = 0;
reg key_up    = 0;
reg key_jump  = 0;
reg key_fire  = 0;
reg key_start = 0;
reg key_coin  = 0;

always @(posedge clk_sys) begin
  reg old_state;
  old_state <= ps2_key[10];

  if (old_state != ps2_key[10]) begin
    case (code)
      'h75: key_up    <= pressed; // up
      'h72: key_down  <= pressed; // down
      'h6B: key_left  <= pressed; // left
      'h74: key_right <= pressed; // right
      'h16: key_start <= pressed; // 1
      'h2E: key_coin  <= pressed; // 5
      'h14: key_fire  <= pressed; // ctrl
      'h11: key_jump  <= pressed; // alt
    endcase
  end
end

wire right = key_right | joy[0];
wire left  = key_left  | joy[1];
wire down  = key_down  | joy[2];
wire up    = key_up    | joy[3];
wire fire  = key_fire  | joy[4];
wire jump  = key_jump  | joy[5];
wire start = key_start | joy[6];
wire coin  = key_coin  | joy[7];

////////////////////////////////////////////////////////////////////////////////
// GAME
////////////////////////////////////////////////////////////////////////////////

wire reset = RESET | ioctl_download | status[0] | buttons[1];
reg [3:0] game_index = 0;

// set game index
always @(posedge clk_sys) begin
  if (ioctl_wr & (ioctl_index == 1)) game_index <= ioctl_data[3:0];
end

tecmo tecmo
(
  .reset(reset),
  .clk(clk_sys),
  .cen_12(cen_12),

  .joystick_1({2'b0, jump, fire, up, down, right, left}),
  .joystick_2({2'b0, jump, fire, up, down, right, left}),
  .start_1(start),
  .start_2(1'b0),
  .coin_1(coin),
  .coin_2(1'b0),

  .dip_allow_continue(~status[15]),
  .dip_bonus_life(status[12:11]),
  .dip_cabinet(~status[10]),
  .dip_difficulty(status[14:13]),
  .dip_lives(status[9:8]),

  .sdram_addr(sdram_addr),
  .sdram_data(sdram_data),
  .sdram_we(sdram_we),
  .sdram_req(sdram_req),
  .sdram_ack(sdram_ack),
  .sdram_valid(sdram_valid),
  .sdram_q(sdram_q),

  .ioctl_addr(ioctl_addr),
  .ioctl_data(ioctl_data),
  .ioctl_wr(ioctl_wr & (ioctl_index == 0)),
  .ioctl_download(ioctl_download),

  .game_index(game_index),

  .hsync(hsync),
  .vsync(vsync),
  .hblank(hblank),
  .vblank(vblank),

  .r(r),
  .g(g),
  .b(b),

  .audio(AUDIO_L)
);

endmodule
