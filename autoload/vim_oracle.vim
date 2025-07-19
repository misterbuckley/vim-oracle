" vim_oracle.vim - Autoload functions for vim-oracle plugin

" Global variable to track the chat buffer number
let s:chat_buffer = -1
" Global variable to track if the last chat job has finished
let s:chat_job_finished = 1

function! vim_oracle#prompt() abort
  let filename = expand('%')
  let linenum = line('.')
  let filetype = &filetype
  
  let prompt_template = vim_oracle#get_prompt_template(filetype)
  let default_prompt = vim_oracle#format_prompt(prompt_template, filename, linenum)
  
  let user_input = input('AI prompt: ', default_prompt)
  if user_input !=# ''
    call vim_oracle#execute_command(user_input)
  endif
endfunction

function! vim_oracle#get_prompt_template(filetype) abort
  if has_key(g:vim_oracle_filetype_prompts, a:filetype)
    return g:vim_oracle_filetype_prompts[a:filetype]
  else
    return g:vim_oracle_default_prompt
  endif
endfunction

function! vim_oracle#format_prompt(template, filename, linenum) abort
  let formatted = substitute(a:template, '{filename}', a:filename, 'g')
  let formatted = substitute(formatted, '{line}', a:linenum, 'g')
  let formatted = substitute(formatted, '{filetype}', &filetype, 'g')
  return formatted
endfunction

function! vim_oracle#execute_command(prompt) abort
  let escaped_prompt = shellescape(a:prompt)
  let command = g:vim_oracle_command . ' ' . escaped_prompt
  
  if g:vim_oracle_window_position ==# 'floating' && has('nvim')
    call vim_oracle#open_floating_terminal(command)
  else
    call vim_oracle#open_positioned_terminal(command)
  endif
endfunction

function! vim_oracle#open_positioned_terminal(command) abort
  " Map the configured window position to commands that open a new window
  " before running the terminal command.  This avoids quoting problems when
  " {command} contains single quotes.
  let position_map = {
        \ 'below': 'botright new',
        \ 'above': 'topleft new',
        \ 'right': 'botright vertical new',
        \ 'left': 'topleft vertical new',
        \ 'tab': 'tabnew'
        \ }

  let open_cmd = get(position_map, g:vim_oracle_window_position, 'botright new')
  execute open_cmd

  if has('nvim')
    " Use the configured shell to run {command} so that quoting with spaces or
    " single quotes works consistently.
    call termopen([&shell, &shellcmdflag, a:command])
  else
    call term_start([&shell, &shellcmdflag, a:command], {'curwin': 1})
  endif
  startinsert
endfunction

function! vim_oracle#open_floating_terminal(command) abort
  if !has('nvim')
    call vim_oracle#open_positioned_terminal(a:command)
    return
  endif
  
  let width = float2nr(&columns * 0.8)
  let height = float2nr(&lines * 0.6)
  let col = float2nr((&columns - width) / 2)
  let row = float2nr((&lines - height) / 2)
  
  let opts = {
    \ 'relative': 'editor',
    \ 'width': width,
    \ 'height': height,
    \ 'col': col,
    \ 'row': row,
    \ 'style': 'minimal',
    \ 'border': 'rounded'
    \ }
  
  let buf = nvim_create_buf(v:false, v:true)
  let win = nvim_open_win(buf, v:true, opts)
  " Run the command through the user's shell so that prompts containing quotes
  " or spaces are handled correctly.
  call termopen([&shell, &shellcmdflag, a:command])
  startinsert
endfunction




" Open or switch to a chat window with AI
function! vim_oracle#open_chat(...) abort
  let l:prompt = a:0 > 0 ? a:1 : ''
  
  " If a prompt is provided, always create a new chat session
  if !empty(l:prompt)
    call vim_oracle#create_new_chat(l:prompt)
    return
  endif
  
  " If the last chat job finished, start a new conversation
  if s:chat_job_finished
    call vim_oracle#create_new_chat(l:prompt)
    return
  endif
  
  " Check if we have a valid chat buffer
  if s:chat_buffer != -1 && bufexists(s:chat_buffer)
    " Check if the buffer is already visible in any window
    let l:chat_winnr = bufwinnr(s:chat_buffer)
    if l:chat_winnr != -1
      " Buffer is visible, switch to that window
      execute l:chat_winnr . 'wincmd w'
      return
    else
      " Buffer exists but is hidden, open it in a new window
      call vim_oracle#open_chat_window(s:chat_buffer)
      return
    endif
  endif
  
  " No existing chat buffer, create a new one
  call vim_oracle#create_new_chat(l:prompt)
endfunction

" Create a new chat session
function! vim_oracle#create_new_chat(...) abort
  let l:initial_prompt = a:0 > 0 ? a:1 : ''
  
  " Mark that a new chat job is starting
  let s:chat_job_finished = 0
  
  " Start an interactive chat session
  let chat_prompt = empty(l:initial_prompt) ? '' : l:initial_prompt
  
  if g:vim_oracle_window_position ==# 'floating' && has('nvim')
    call vim_oracle#open_floating_chat(chat_prompt)
  else
    call vim_oracle#open_positioned_chat(chat_prompt)
  endif
endfunction

" Open chat in a positioned window
function! vim_oracle#open_positioned_chat(prompt) abort
  let position_map = {
        \ 'below': 'botright new',
        \ 'above': 'topleft new',
        \ 'right': 'botright vertical new',
        \ 'left': 'topleft vertical new',
        \ 'tab': 'tabnew'
        \ }

  let open_cmd = get(position_map, g:vim_oracle_window_position, 'botright new')
  execute open_cmd
  
  let s:chat_buffer = bufnr('%')
  call vim_oracle#setup_chat_buffer(a:prompt)
endfunction

" Open chat in a floating window (Neovim only)
function! vim_oracle#open_floating_chat(prompt) abort
  if !has('nvim')
    call vim_oracle#open_positioned_chat(a:prompt)
    return
  endif
  
  let width = float2nr(&columns * 0.8)
  let height = float2nr(&lines * 0.6)
  let col = float2nr((&columns - width) / 2)
  let row = float2nr((&lines - height) / 2)
  
  let opts = {
    \ 'relative': 'editor',
    \ 'width': width,
    \ 'height': height,
    \ 'col': col,
    \ 'row': row,
    \ 'style': 'minimal',
    \ 'border': 'rounded'
    \ }
  
  let buf = nvim_create_buf(v:false, v:true)
  let s:chat_buffer = buf
  let win = nvim_open_win(buf, v:true, opts)
  call vim_oracle#setup_chat_buffer(a:prompt)
endfunction

" Setup the chat buffer with appropriate settings
function! vim_oracle#setup_chat_buffer(prompt) abort
  " Mark this as a chat buffer
  let b:vim_oracle_chat_buffer = 1
  
  if !empty(a:prompt)
    " If we have a prompt, execute it directly using the existing method
    let escaped_prompt = shellescape(a:prompt)
    let command = g:vim_oracle_command . ' ' . escaped_prompt
    
    if has('nvim')
      call termopen([&shell, &shellcmdflag, command], {'on_exit': function('vim_oracle#on_chat_exit')})
    else
      call term_start([&shell, &shellcmdflag, command], {'curwin': 1, 'exit_cb': function('vim_oracle#on_chat_exit')})
    endif
  else
    " No prompt, start interactive session
    if has('nvim')
      call termopen([&shell, &shellcmdflag, g:vim_oracle_command], {'on_exit': function('vim_oracle#on_chat_exit')})
    else
      call term_start([&shell, &shellcmdflag, g:vim_oracle_command], {'curwin': 1, 'exit_cb': function('vim_oracle#on_chat_exit')})
    endif
  endif
  
  startinsert
endfunction

" Callback function when chat terminal exits
function! vim_oracle#on_chat_exit(...) abort
  " Mark that the chat job has finished
  let s:chat_job_finished = 1
endfunction

" Send a prompt to an existing chat session
function! vim_oracle#send_prompt_to_chat(prompt) abort
  " Send the prompt to the existing terminal session
  if has('nvim')
    " For Neovim, send to the terminal job
    if exists('b:terminal_job_id')
      " Try different line ending combinations
      call chansend(b:terminal_job_id, a:prompt . "\r\n")
    endif
  else
    " For Vim, use term_sendkeys
    call term_sendkeys(bufnr('%'), a:prompt . "\<CR>")
  endif
endfunction


" Open an existing chat buffer in a new window
function! vim_oracle#open_chat_window(bufnr) abort
  let position_map = {
        \ 'below': 'botright split',
        \ 'above': 'topleft split',
        \ 'right': 'botright vertical split',
        \ 'left': 'topleft vertical split',
        \ 'tab': 'tabnew'
        \ }

  let open_cmd = get(position_map, g:vim_oracle_window_position, 'botright split')
  execute open_cmd
  execute 'buffer ' . a:bufnr
endfunction

" Handle tab switching to keep chat state synchronized
function! vim_oracle#refresh_chat_on_tab_enter() abort
  " Check if the current tab has a chat buffer visible
  if s:chat_buffer != -1 && bufexists(s:chat_buffer)
    let l:chat_winnr = bufwinnr(s:chat_buffer)
    if l:chat_winnr != -1
      " Chat buffer is visible in current tab, ensure it's up to date
      " Terminal buffers automatically maintain their state, so no action needed
      " This function can be extended for future synchronization needs
    endif
  endif
endfunction
