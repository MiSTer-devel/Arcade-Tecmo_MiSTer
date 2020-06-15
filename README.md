# Tecmo

Tecmo was a Japanese video game company founded in 1967, who like many other game companies of the era, had their roots outside the amusement business. In Tecmo's case, they were originally a supplier of cleaning equipment.

Nevertheless, they went on to create some classic arcade games during the 80s and 90s. Many of which saw later releases on consoles like Nintendo Entertainment System, Sega Master System, Commodore 64, Atari Lynx, etc.

This core currently supports three games: Rygar (1986), Gemini Wing (1987), and Silkworm (1988).

## Getting Started

Place the MRA, RBF, and the MAME ROM files in the following locations:

```
_Arcade/Rygar.mra
_Arcade/Gemini Wing.mra
_Arcade/Silkworm.mra
_Arcade/cores/tecmo.rbf
_Arcade/mame/rygar.zip
_Arcade/mame/gemini.zip
_Arcade/mame/silkworm.zip
```

For more information on using MRA files with MiSTer, please refer to the [wiki](https://github.com/MiSTer-devel/Main_MiSTer/wiki/Arcade-Roms).

## Controls

Keyboard inputs:

| name     | key                   |
| ---      | ---                   |
| Coin 1   | 5                     |
| Coin 2   | 6                     |
| Start 1  | 1                     |
| Start 2  | 1                     |
| Button 1 | CTRL                  |
| Button 2 | ALT                   |
| Button 3 | SPACE                 |
| Movement | UP, DOWN, LEFT, RIGHT |

Joystick inputs:

| name     | button                |
| ---      | ---                   |
| Coin     | L                     |
| Start    | R                     |
| Pause    | START                 |
| Button 1 | A                     |
| Button 2 | B                     |
| Button 3 | X                     |
| Movement | UP, DOWN, LEFT, RIGHT |

## Credits

Made with :heart: by [Josh Bassett](https://twitter.com/nullobject), 2020.

I would also like to give a massive shout out to all my [Patreon](https://www.patreon.com/nullobject) supporters. Your support keeps me working on these games, and helps bring them to everybody.

Special thanks to:

<table>
  <tr>
    <td><img src="https://github.com/MiSTer-devel/Arcade-Tecmo_MiSTer/raw/master/doc/avatar.png" width="100px;" /></td>
    <td>Alex Painemilla Carreño</td>
  </tr>
  <tr>
    <td><img src="https://github.com/MiSTer-devel/Arcade-Tecmo_MiSTer/raw/master/doc/amineko-stone.jpeg" width="100px;" /></td>
    <td>Amineko Stone</td>
  </tr>
  <tr>
    <td><img src="https://github.com/MiSTer-devel/Arcade-Tecmo_MiSTer/raw/master/doc/andrew-boudreau.jpg" width="100px;" /></td>
    <td>Andrew Boudreau</td>
  </tr>
  <tr>
    <td><img src="https://github.com/MiSTer-devel/Arcade-Tecmo_MiSTer/raw/master/doc/avatar.png" width="100px;" /></td>
    <td>Arjan de Lang</td>
  </tr>
  <tr>
    <td><img src="https://github.com/MiSTer-devel/Arcade-Tecmo_MiSTer/raw/master/doc/avatar.png" width="100px;" /></td>
    <td>Benjamin Walker</td>
  </tr>
  <tr>
    <td><img src="https://github.com/MiSTer-devel/Arcade-Tecmo_MiSTer/raw/master/doc/christopher-gelatt.png" width="100px;" /></td>
    <td>Christopher Gelatt</td>
  </tr>
  <tr>
    <td><img src="https://github.com/MiSTer-devel/Arcade-Tecmo_MiSTer/raw/master/doc/christopher-tuckwell.jpeg" width="100px;" /></td>
    <td>Christopher Tuckwell</td>
  </tr>
  <tr>
    <td><img src="https://github.com/MiSTer-devel/Arcade-Tecmo_MiSTer/raw/master/doc/hard-rich.jpeg" width="100px;" /></td>
    <td>Hard Rich</td>
  </tr>
  <tr>
    <td><img src="https://github.com/MiSTer-devel/Arcade-Tecmo_MiSTer/raw/master/doc/avatar.png" width="100px;" /></td>
    <td>iker</td>
  </tr>
  <tr>
    <td><img src="https://github.com/MiSTer-devel/Arcade-Tecmo_MiSTer/raw/master/doc/lakeside.jpeg" width="100px;" /></td>
    <td>Lakeside</td>
  </tr>
  <tr>
    <td><img src="https://github.com/MiSTer-devel/Arcade-Tecmo_MiSTer/raw/master/doc/avatar.png" width="100px;" /></td>
    <td>Matt Postema</td>
  </tr>
  <tr>
    <td><img src="https://github.com/MiSTer-devel/Arcade-Tecmo_MiSTer/raw/master/doc/ordigdug.png" width="100px;" /></td>
    <td>ordigdug</td>
  </tr>
  <tr>
    <td><img src="https://github.com/MiSTer-devel/Arcade-Tecmo_MiSTer/raw/master/doc/scralings.png" width="100px;" /></td>
    <td>Scralings</td>
  </tr>
</table>

Thanks to:

Adrian Longland, Akai Futari, Allen Tipper, Amosfear, Andrew Francomb, Antonio Bellotta, Benjamin Leggett, Charles Sagett, Chris B, Darren Newman, David Filskov, David Jones, Devon Nelson, Filip Kindt, Funkycochise, George Stravopodis, Herbert Krammer, Humanoide70, Jim Wehrfritz, John Perry, John Stringer, Jordan Retterer, JPS (RetroFPGA), Juan Jose Velez Ramirez, Keith Kelly, Leslie Welch, Ludovic Germaneau, Mahendra, Manuel Antoni, Mark Fulton, Mark Paterson, Mat Azel, Matthew, Matthias Penkert-Hennig, Max L Schultz, Max Schütz, Michael Fuerst, Michael Yount, Miguel Candelario, Mike Parks, Monokrom, MrX-8B, Naku aka Ben, Octavio Bernacer Sempere, olivier bernhard, Oscar Laguna Garcia, Per Sweden, Phillip McMahon, Porkchop Express, RetroDriven, Ross Jolet, Shane Lynch, Shaneus, SpearZ, Tony Peters, toolb0x, Victor Bly, Víctor Gomariz Ladrón de Guevara, Xzarian, Zichio

...and the rest of my supporters :sparkling_heart:

## Development

Compile the core:

    $ make build

Program the DE10-Nano:

    $ make program

## Licence

This project is licensed under the MIT licence. See the LICENCE file for more details.
