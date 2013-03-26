Thwins - Keep Vim Displaying Three Windows
=======================================

Windows are always organised as follows:

    ===================================
    |              |        S1        |
    |     Main     |===================
    |              |        S2        |
    ===================================

Priority Rules for Buffers
--------------------------

`Current` > `Main` > `Displayed` > `New opened` > `Others`

Install
-------

    mkdir -p ~/.vim/plugin/ && \
    curl -o ~/.vim/plugin/thwins.vim \
    https://raw.github.com/mitnk/thwins/master/thwins.vim

Key Mapping
-----------

- `<C-H>` Make the current buffer as the main window
- `<C-L>` Make current buffer displayed as full screen
- `<C-C>` Delete current buffer
- `<C-D>` Close all buffers except the current one
- `<C-J>` Move cursor to next buffer
- `<C-K>` Move cursor to previous buffer

Inspired By
-------------

[dwm.vim](https://github.com/spolu/dwm.vim) by Stanislas Polu
