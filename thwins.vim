"=============================================================================
"    Copyright: Copyright (C) 2013-2016 mitnk
"               Permission is hereby granted to use and distribute this code,
"               with or without modifications, provided that this copyright
"               notice is copied with it. Like anything else that's free,
"               thwins.vim is provided *as is* and comes with no warranty of
"               any kind, either expressed or implied. In no event will the
"               copyright holder be liable for any damages resulting from
"               the use of this software.
" Name Of File: thwins.vim
"  Description: Three Windows for Vim
"   Maintainer: mitnk (w AT mitnk DOT com)
"=============================================================================

" Exit quickly if already running
if exists("g:thwins_version") || &cp
    finish
endif

let g:thwins_version = "0.2.1"

" Check for Vim version 700 or greater
if v:version < 700
    echo "Sorry, thwins.vim " . g:thwins_version .
        "\nONLY runs with Vim 7.0 and greater."
    finish
endif

if !exists('g:thwins_max_window_number')
    let g:thwins_max_window_number = 3
endif


" Array for storing Buffer order
let s:thwins_bufs = []


function! THWINS_GetMaxWindowNumber()
    let max_window_number = g:thwins_max_window_number
    if max_window_number > 3
        let max_window_number = 3
    endif
    if max_window_number < 2
        let max_window_number = 2
    endif
    return max_window_number
endfunction


" Change Main Window
" Make sure the position of the third window Unchange.
function! THWINS_ChangeMainWindow(old_bufs)
    if len(a:old_bufs) <= 2
        return
    endif
    let cnr = s:thwins_bufs[0]
    if cnr != a:old_bufs[0]
        let s:thwins_bufs = [cnr]
        let tmp = a:old_bufs[0]
        for idx in range(1, 2)
            if a:old_bufs[idx] == cnr
                let s:thwins_bufs += [tmp]
            else
                let s:thwins_bufs += [a:old_bufs[idx]]
            endif
        endfor
    endif
endfunction


function! THWINS_GetDisplayedBuffers()
    let cnr = bufnr('%')

    " Make sure there are at least two windows
    let window_counter = 0
    windo let window_counter = window_counter + 1
    if window_counter < 2
        return [cnr]
    endif

    let buffers = [cnr]
    while window_counter > 0
        exec 'wincmd w'
        let nr = bufnr('%')
        if index(buffers, nr) == -1
            let buffers += [nr]
        endif
        let window_counter -= 1
    endwhile
    return reverse(sort(buffers))
endfunction


"" Collect three highest buffers to display
"" Priorities are: Current > Main > Displayed > New opened > Others
function! THWINS_SyncBufs()
    let max_window_number = THWINS_GetMaxWindowNumber()
    let old_bufs = s:thwins_bufs

    " Add current buffer
    let cnr = bufnr('%')
    if len(s:thwins_bufs) > 0
        let last_main_nr = s:thwins_bufs[0]
    else
        let last_main_nr = cnr
    endif
    let s:thwins_bufs = [cnr]
    let bufs_displayed = THWINS_GetDisplayedBuffers()

    " Add last main buffer if it exists
    if index(bufs_displayed, last_main_nr) != -1 && index(s:thwins_bufs, last_main_nr) == -1
        let s:thwins_bufs += [last_main_nr]
    endif

    " Add other displayed buffers
    let idx = 0
    while len(s:thwins_bufs) < max_window_number && len(bufs_displayed) > idx
        let inr = bufs_displayed[idx]
        if index(s:thwins_bufs, inr) == -1
            let s:thwins_bufs += [inr]
        endif
        let idx += 1
    endwhile

    let bufs_listed = THWINS_GetListedBufs()
    let idx = 0
    while len(s:thwins_bufs) < max_window_number && len(bufs_listed) > idx
        let inr = bufs_listed[idx]
        if index(s:thwins_bufs, inr) == -1
            let s:thwins_bufs += [inr]
        endif
        let idx += 1
    endwhile

    if sort(copy(old_bufs)) == sort(copy(s:thwins_bufs))
        call THWINS_ChangeMainWindow(old_bufs)
    endif
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
    let max_window_number = THWINS_GetMaxWindowNumber()
    if max_window_number > 2 && len(s:thwins_bufs) > 2
        for idx in range(len(s:thwins_bufs) - 2, 1, -1)
            exec 'belowright sb ' . s:thwins_bufs[idx]
        endfor
    endif
    exec 'wincmd h'
    call THWINS_ResizeMasterPaneWidth()
endfunction


function! THWINS_ResizeMasterPaneWidth()
    if (&columns < 120)
        let thwins_master_pane_width=&columns * 3 / 5
    elseif (&columns < 170)
        let thwins_master_pane_width=85
    else
        let thwins_master_pane_width=0
    endif
    if thwins_master_pane_width
        exec 'vertical resize ' . thwins_master_pane_width
    endif
endfunction


function! THWINS_Full ()
    on!
endfunction


function! THWINS_CloseCurrent()
    if len(s:thwins_bufs) == 0
        let is_main = 0
    else
        let is_main = (bufnr('%') == s:thwins_bufs[0])
    endif

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


" Walk through all the three windows (after a rearrangement),
" in order to make sure the main window got a BufEnter event and
" the other two window got BufLeave events
function! THWINS_WalkThrough()
    " from main window to the right-bottom one
    exec 'wincmd l'
    " from right-bottom one to right-up one
    exec 'wincmd k'
    " back to the main window
    exec 'wincmd h'
endfunction


function! THWINS_ChangeMaxWindowNumber()
    if g:thwins_max_window_number >= 3
        let g:thwins_max_window_number = 2
        echo "Changed max windows to 2"
        return
    endif
    if g:thwins_max_window_number <= 2
        let g:thwins_max_window_number = 3
        echo "Changed max windows to 3"
        return
    endif
endfunction


function! THWINS_Focus()
    call THWINS_SyncBufs()
    call THWINS_Layout()
    call THWINS_WalkThrough()
endfunction


nmap <C-H> :call THWINS_Focus()<CR>
nmap <C-C> :call THWINS_CloseCurrent()<CR>
nmap <C-D> :call THWINS_CloseOthers()<CR>
nmap <C-J> <C-W>w
nmap <C-K> <C-W>W
nmap <C-L> :call THWINS_Full()<CR>
nmap <C-M> :call THWINS_ChangeMaxWindowNumber()<CR>
