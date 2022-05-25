# MineSweeper
This is a MineSweeper clone made in the LÖVE2D game engine, which uses the Lua programming language.

No built version is included, but you can launch the game if you have LÖVE2D installed.
Alternatively, you can fuse the game yourself (see [here](https://love2d.org/wiki/Game_Distribution) for details).

To launch the game, just drag the game directory onto the love executable or launch it from a command line.
Launching it from a command line allows you to specify startup options. The syntax is:
```
loveExecutable gameDir width height mines
```
`width` and `height` are the width and height of the game given in number of cells.
`mines` can either be the absolute number of mines or a mine density given as a percentage of the total number of cells.
For example, giving `20`, `10`, and `15` as the last three options will produce a 20×10 game with a total of 15 mines.
Giving `15%` instead of `15` as the `mines` option will instead produce a 20×10 game with 30 mines (20&nbsp;×&nbsp;10&nbsp;×&nbsp;0.15&nbsp;=&nbsp;30).

The controls are quite simple:
- Left click to reveal an empty cell
- Right click to place/remove a flag
- Left click on a number to reveal the surrounding cells

After either winning or losing a game, clicking anywhere will start a new game with the same width, height, and number of mines.
