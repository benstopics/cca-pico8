# cca-pico8

### Colossal Cave Adventure - PICO-8 Port

This is a PICO8 port of the original FORTRAN source code for (Colossal Cave) ADVENT(ure).

##### Credit goes to:
- [Neko250](https://github.com/Neko250/adventure) for sharing the original Fortran source.
- [Krystman](https://www.lexaloffle.com/bbs/?pid=80908) for creating Memsplore which allowed me to visualize and learn the memory structure.
- [dw817](https://www.lexaloffle.com/bbs/?pid=101378) for sharing his Big Integer implementation, which fixed the arithmetic in the map data decoding logic.
- [sulai](https://www.lexaloffle.com/bbs/?pid=43636) for sharing his `tostring` implementation which enhanced my debugging experience.
- [shiftalow](https://www.lexaloffle.com/bbs/?tid=41798) for sharing his `cat` implementation.
- [Rochet2](https://github.com/Rochet2/lualzw/blob/master/lualzw.lua) for sharing his Lua LZW compression implementation, which allowed the DAT file to easily fit in the cartridge RAM.
- [greatwolf](https://stackoverflow.com/a/18694774) for sharing his `utf8_from` implementation.
- [mkol103](https://www.lexaloffle.com/bbs/?tid=41855) for sharing his PICO-8 Word Processor code and providing invaluable insight into properly capturing keyboard input.
- [yi](https://gist.github.com/yi/01e3ab762838d567e65d) for sharing his Lua hex2string implementation which aided in getting the DAT file into the `.p8` file.
