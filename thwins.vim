"=============================================================================
"    Copyright: Copyright (C) 2013 mitnk
"               Permission is hereby granted to use and distribute this code,
"               with or without modifications, provided that this copyright
"               notice is copied with it. Like anything else that's free,
"               thwins.vim is provided *as is* and comes with no warranty of
"               any kind, either expressed or implied. In no event will the
"               copyright holder be liable for any damages resulting from
"               the use of this software.
" Name Of File: thwins.vim
"  Description: Three Windows for Vim
"   Maintainer: mitnk (whgking @ gmail)
"      Base On: dwm.vim by Stanislas Polu
"=============================================================================

" Exit quickly if already running
if exists("g:thwins_version") || &cp
    finish
endif

let g:thwins_version = "0.1.0"

" Check for Vim version 700 or greater
if v:version < 700
    echo "Sorry, thwins.vim " . g:thwins_version .
        "\nONLY runs with Vim 7.0 and greater."
    finish
endif

if !exists('g:thwins_max_buf_size')
    let g:thwins_max_buf_size = 3
endif


" Array for storing Buffer order
let s:thwins_bufs = []


" Change Main Window
" Make sure the position of the third window Unchange.
function! THWINS_ChangeMainWindow()
    let cnr = bufnr('%')
    if cnr != s:thwins_bufs[0]
        let old_bufs = s:thwins_bufs
        let s:thwins_bufs = [cnr]
        let tmp = old_bufs[0]
        for idx in range(1, 2)
            if old_bufs[idx] == cnr
                let s:thwins_bufs += [tmp]
            else
                let s:thwins_bufs += [old_bufs[idx]]
            endif
        endfor
    endif
endfunction


function! THWINS_GetDisplayedBuffers()
    let cnr = bufnr('%')
    let buffers = [cnr]
    while 1
        exec 'wincmd w'
        let nr = bufnr('%')
        if nr == cnr
            break
        endif
        if index(buffers, nr) == -1
            let buffers += [nr]
        endif
    endwhile
    return reverse(sort(buffers))
endfunction


"" Collect three highest buffers to display
"" Priorities are: Current > Main > Displayed > New opened > Others
function! THWINS_SyncBufs()
    let old_bufs = s:thwins_bufs
    echo ''
    echo 'old_bufs:'
    echo old_bufs
    echo ''

    " Add current buffer
    let cnr = bufnr('%')
    if len(s:thwins_bufs) > 0
        let last_main_nr = s:thwins_bufs[0]
    else
        let last_main_nr = cnr
    endif
    let s:thwins_bufs = [cnr]
    let bufs_displayed = THWINS_GetDisplayedBuffers()
    echo 'after adding current buffer'
    echo s:thwins_bufs

    " Add last main buffer if it exists
    if index(bufs_displayed, last_main_nr) != -1 && index(s:thwins_bufs, last_main_nr) == -1
        let s:thwins_bufs += [last_main_nr]
    endif
    echo 'dis:'
    echo bufs_displayed
    echo 'after adding main buffer'
    echo s:thwins_bufs
    echo ''

    " Add other displayed buffers
    let idx = 0
    while len(s:thwins_bufs) < 3 && len(bufs_displayed) > idx
        let inr = bufs_displayed[idx]
        if index(s:thwins_bufs, inr) == -1
            let s:thwins_bufs += [inr]
        endif
        let idx += 1
    endwhile
    echo 'after adding displayed buffers'
    echo s:thwins_bufs
    echo ''

    let bufs_listed = THWINS_GetListedBufs()
    echo ''
    echo 'listed:'
    echo bufs_listed
    echo ''
    let idx = 0
    while len(s:thwins_bufs) < 3 && len(bufs_listed) > idx
        let inr = bufs_listed[idx]
        if index(s:thwins_bufs, inr) == -1
            let s:thwins_bufs += [inr]
        endif
        let idx += 1
    endwhile
    echo 'after adding listed buffers'
    echo s:thwins_bufs

    if sort(copy(old_bufs)) == sort(copy(s:thwins_bufs))
        echo 'changing main win()'
        call THWINS_ChangeMainWindow()
    endif

    echo 'final bufs:'
    echo s:thwins_bufs
    echo ''
endfunction


function! THWINS_GetListedBufs()
    let buffers = []
    for nr in range(bufnr('$'), 1, -1)
        if buflisted(nr)
            let buffers += [nr]
        endif
    endfor
    return buffers
endfunction


function! THWINS_Layout()
    exec 'sb ' . s:thwins_bufs[0]
    on!
    if len(s:thwins_bufs) > 1
        let last_nr = s:thwins_bufs[len(s:thwins_bufs) - 1]
        exec 'belowright vs #' . last_nr
    endif
    if len(s:thwins_bufs) > 2
        for idx in range(len(s:thwins_bufs) - 2, 1, -1)
            exec 'belowright sb ' . s:thwins_bufs[idx]
        endfor
    endif
    exec 'wincmd h'
    call THWINS_ResizeMasterPaneWidth()
endfunction


function THWINS_ResizeMasterPaneWidth()
    " resize the master pane if user defined it
    if exists('g:thwins_master_pane_width')
        exec 'vertical resize ' . g:thwins_master_pane_width
    endif
endfunction


function! THWINS_Full ()
    exec 'sb ' .    bufnr('%')
    on!
endfunction


function! THWINS_Delete()
    let is_main = (bufnr('%') == s:thwins_bufs[0])
    exec 'bd'
    if is_main
        exec 'wincmd k'
    else
        exec 'wincmd h'
    endif
    call THWINS_Focus()
endfunction


function! THWINS_CloseOthers()
    for nr in range(1,bufnr("$"))
        if nr != bufnr('%') && buflisted(nr)
            exec 'bd ' . nr
        endif
    endfor
endfunction


function! THWINS_Focus()
    call THWINS_SyncBufs()
    call THWINS_Layout()
endfunction


if !exists('g:thwins_map_keys')
    let g:thwins_map_keys = 1
endif

if g:thwins_map_keys
    map <C-C> :call THWINS_CloseOthers()<CR>
    map <C-D> :call THWINS_Delete()<CR>
    map <C-H> :call THWINS_Focus()<CR>
    map <C-J> <C-W>w
    map <C-K> <C-W>W
    map <C-L> :call THWINS_Full()<CR>
endif