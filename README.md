# Rygar (1986)

<img alt="Rygar" src="https://github.com/nullobject/rygar-fpga/raw/master/doc/rygar-banner.jpg" />

Rygar was originally built in 1986 by Tecmo, a Japanese video game company, and saw later releases on consoles like Nintendo Entertainment System, Sega Master System, Commodore 64, Atari Lynx, etc.

I began this project by writing an [emulator](https://github.com/nullobject/rygar-emu), so I could focus on learning how the arcade game works, without having to worry about the FPGA side of things. I kept detailed project notes while working on both the emulator and FPGA core, which will be turned into a series of [blog posts](https://joshbassett.info).

## Getting Started

In order to run this arcade core, you will need to provide the correct ROMs (they are not included for legal reasons).

To simplify the process, you only need to provide the `rygar.zip` file from the MAME ROMs.

1. Download the [latest Rygar release](https://github.com/MiSTer-devel/Arcade-Rygar_MiSTer/releases/latest).
2. Extract the MRA and RBF files from the archive.
3. Place the extracted files and the ZIP file containing the MAME ROM files in the following locations:

```
_Arcade/rygar.mra
_Arcade/cores/rygar.rbf
_Arcade/mame/rygar.zip
```

For more information on using MRA files with MiSTer, please refer to the [wiki](https://github.com/MiSTer-devel/Main_MiSTer/wiki/Arcade-Roms).

## Controls

Keyboard inputs:

| name     | key                   |
| ---      | ---                   |
| Coin     | 5                     |
| Start    | 1                     |
| Attack   | CTRL                  |
| Jump     | ALT                   |
| Movement | UP, DOWN, LEFT, RIGHT |

Joystick inputs:

| name     | button                |
| ---      | ---                   |
| Coin     | L                     |
| Start    | R                     |
| Attack   | A                     |
| Jump     | B                     |
| Movement | UP, DOWN, LEFT, RIGHT |

## Development

Compile the core:

    $ make build

Program the DE10-Nano:

    $ make program

## Credits

Made with :heart: by [Josh Bassett](https://twitter.com/nullobject), 2020.

Special thanks to:

* [Jose Tejada](https://twitter.com/topapate)
* [ElectronAsh](https://twitter.com/AshEvans81)

## Licence

Rygar is licensed under the MIT licence. See the LICENCE file for more details.
