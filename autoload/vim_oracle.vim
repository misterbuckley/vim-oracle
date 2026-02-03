" vim_oracle.vim - Autoload functions for vim-oracle plugin

" Global variable to track the chat buffer number
let s:chat_buffer = -1
" Global variable to track if the last chat job has finished
let s:chat_job_finished = 1
" Global variable for prompt history
let s:prompt_history = []
" Variable to track current history selection
let s:history_selection = 0

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

" History management functions
function! vim_oracle#load_history() abort
  let l:history_file = vim_oracle#get_history_file()
  if filereadable(l:history_file)
    try
      let s:prompt_history = readfile(l:history_file)
      " Remove empty lines
      let s:prompt_history = filter(s:prompt_history, 'v:val !~ "^\\s*$"')
    catch
      let s:prompt_history = []
    endtry
  else
    let s:prompt_history = []
  endif
endfunction

function! vim_oracle#save_history() abort
  let l:history_file = vim_oracle#get_history_file()
  let l:history_dir = fnamemodify(l:history_file, ':h')
  
  " Create directory if it doesn't exist
  if !isdirectory(l:history_dir)
    call mkdir(l:history_dir, 'p')
  endif
  
  try
    call writefile(s:prompt_history, l:history_file)
  catch
    " Silent fail if we can't write history
  endtry
endfunction

function! vim_oracle#get_history_file() abort
  if has('win32') || has('win64')
    let l:config_dir = expand('$APPDATA/vim-oracle')
  else
    let l:config_dir = expand('~/.config/vim-oracle')
  endif
  return l:config_dir . '/prompt_history.txt'
endfunction

function! vim_oracle#add_to_history(prompt) abort
  if empty(a:prompt) || len(a:prompt) < 3
    return
  endif
  
  " Remove the prompt if it already exists to avoid duplicates
  let s:prompt_history = filter(s:prompt_history, 'v:val !=# a:prompt')
  
  " Add to the beginning of history
  call insert(s:prompt_history, a:prompt)
  
  " Limit history size to 100 entries
  if len(s:prompt_history) > 100
    let s:prompt_history = s:prompt_history[0:99]
  endif
  
  call vim_oracle#save_history()
endfunction

function! vim_oracle#execute_command(prompt) abort
  " Load history if not already loaded
  if empty(s:prompt_history)
    call vim_oracle#load_history()
  endif
  
  " Add prompt to history
  call vim_oracle#add_to_history(a:prompt)
  
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
  
  " Check if we're in a prompt window and use its content
  if exists('b:vim_oracle_prompt_window') && empty(l:prompt)
    call vim_oracle#execute_prompt_from_window()
    return
  endif
  
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
    " Load history if not already loaded
    if empty(s:prompt_history)
      call vim_oracle#load_history()
    endif
    
    " Add prompt to history
    call vim_oracle#add_to_history(a:prompt)
    
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

" Open a small prompt window for editing the default prompt
function! vim_oracle#open_prompt_window(...) abort
  " Get the current context for the prompt BEFORE creating new window
  let l:filename = expand('%')
  let l:linenum = line('.')
  let l:filetype = &filetype

  " Check if we have a range (visual selection) and capture selected text
  let l:selected_text = ''
  if a:0 >= 2 && a:1 != a:2
    " We have a range, get the selected text from the range
    let l:start_line = a:1
    let l:end_line = a:2
    let l:selected_lines = getline(l:start_line, l:end_line)
    let l:selected_text = join(l:selected_lines, "\n")
  endif

  " Create a small window at the bottom
  botright 5new

  " Set buffer options for the prompt window
  setlocal buftype=nofile
  setlocal bufhidden=wipe
  setlocal noswapfile
  setlocal wrap
  setlocal filetype=vim_oracle_prompt

  " Mark this as a prompt window
  let b:vim_oracle_prompt_window = 1

  " Get the appropriate prompt template and format it
  let l:prompt_template = vim_oracle#get_prompt_template(l:filetype)
  let l:formatted_prompt = vim_oracle#format_prompt(l:prompt_template, l:filename, l:linenum)

  " Populate the window with the formatted prompt
  call setline(1, l:formatted_prompt)

  " If we have selected text, add it below the default prompt
  if !empty(l:selected_text)
    call append(line('$'), '')
    call append(line('$'), 'Selected text:')
    " Split the selected text by lines and append each line
    let l:selected_lines = split(l:selected_text, '\n')
    for l:line in l:selected_lines
      call append(line('$'), l:line)
    endfor
    " Add a blank line after the selected text for the cursor
    call append(line('$'), '')
  endif

  " Set up key mappings for the prompt window (removed Enter mappings to allow normal newlines)

  " Start in insert mode at the appropriate position
  if !empty(l:selected_text)
    " Position cursor after the selected text on a new line
    normal! G
    startinsert
  else
    " Start at the end of the default prompt line
    startinsert!
  endif
endfunction

" Execute the prompt from the prompt window
function! vim_oracle#execute_prompt_from_window() abort
  if !exists('b:vim_oracle_prompt_window')
    return
  endif

  " Get the content of the prompt window
  let l:prompt = join(getline(1, '$'), ' ')

  " Close the prompt window
  close

  " Open the chat with the prompt from the window
  call vim_oracle#open_chat(l:prompt)
endfunction

" Send prompt from prompt window (new function for VimOraclePromptWindowSend)
function! vim_oracle#send_prompt_from_window() abort
  if !exists('b:vim_oracle_prompt_window')
    echo "This command can only be used in a VimOracle prompt window"
    return
  endif

  " Get the content of the prompt window
  let l:prompt = join(getline(1, '$'), "\n")

  if empty(trim(l:prompt))
    echo "Prompt window is empty"
    return
  endif

  " Close the prompt window
  close

  " Open the chat with the prompt from the window
  call vim_oracle#open_chat(l:prompt)
endfunction

" Open history browser from prompt window
function! vim_oracle#open_history_browser() abort
  if !exists('b:vim_oracle_prompt_window')
    echo "This command can only be used in a VimOracle prompt window"
    return
  endif
  
  " Load history if not already loaded
  if empty(s:prompt_history)
    call vim_oracle#load_history()
  endif
  
  if empty(s:prompt_history)
    echo "No prompt history available"
    return
  endif
  
  " Store the current prompt window buffer number
  let s:prompt_window_bufnr = bufnr('%')
  
  " Create history browser window
  botright 10new
  
  " Set buffer options for history browser
  setlocal buftype=nofile
  setlocal bufhidden=wipe
  setlocal noswapfile
  setlocal nowrap
  setlocal filetype=vim_oracle_history
  setlocal nomodifiable
  
  " Mark this as a history browser window
  let b:vim_oracle_history_browser = 1
  
  " Initialize selection
  let s:history_selection = 0
  
  " Populate the browser with history items
  call vim_oracle#update_history_display()
  
  " Set up key mappings
  nnoremap <buffer> <C-j> :call vim_oracle#history_next()<CR>
  nnoremap <buffer> <C-k> :call vim_oracle#history_prev()<CR>
  nnoremap <buffer> <CR> :call vim_oracle#select_history_item()<CR>
  nnoremap <buffer> <Esc> :call vim_oracle#close_history_browser()<CR>
  nnoremap <buffer> q :call vim_oracle#close_history_browser()<CR>
  
  " Position cursor on first line
  normal! gg
endfunction

" Update the history display
function! vim_oracle#update_history_display() abort
  if !exists('b:vim_oracle_history_browser')
    return
  endif
  
  setlocal modifiable
  
  " Clear the buffer
  silent! %delete _
  
  " Add header
  call setline(1, '=== Prompt History (Ctrl-J/K to navigate, Enter to select, Esc/q to close) ===')
  call setline(2, '')
  
  " Add history items with selection indicator
  let l:line_num = 3
  for l:i in range(len(s:prompt_history))
    let l:prefix = (l:i == s:history_selection) ? '> ' : '  '
    let l:prompt_preview = substitute(s:prompt_history[l:i], '\n', ' ', 'g')
    if len(l:prompt_preview) > 70
      let l:prompt_preview = l:prompt_preview[:67] . '...'
    endif
    call setline(l:line_num, l:prefix . (l:i + 1) . '. ' . l:prompt_preview)
    let l:line_num += 1
  endfor
  
  setlocal nomodifiable
  
  " Position cursor on selected item
  call cursor(s:history_selection + 3, 1)
  
  " Update the prompt window with selected history item
  call vim_oracle#preview_history_item()
endfunction

" Navigate to next history item
function! vim_oracle#history_next() abort
  if s:history_selection < len(s:prompt_history) - 1
    let s:history_selection += 1
    call vim_oracle#update_history_display()
  endif
endfunction

" Navigate to previous history item
function! vim_oracle#history_prev() abort
  if s:history_selection > 0
    let s:history_selection -= 1
    call vim_oracle#update_history_display()
  endif
endfunction

" Preview the selected history item in the prompt window
function! vim_oracle#preview_history_item() abort
  if s:history_selection >= 0 && s:history_selection < len(s:prompt_history) && bufexists(s:prompt_window_bufnr)
    let l:current_win = winnr()
    let l:prompt_winnr = bufwinnr(s:prompt_window_bufnr)
    
    if l:prompt_winnr != -1
      execute l:prompt_winnr . 'wincmd w'
      
      " Clear and populate the prompt window with the selected history item
      silent! %delete _
      call setline(1, s:prompt_history[s:history_selection])
      
      " Return to history browser window
      execute l:current_win . 'wincmd w'
    endif
  endif
endfunction

" Select the current history item and close browser
function! vim_oracle#select_history_item() abort
  if s:history_selection >= 0 && s:history_selection < len(s:prompt_history) && bufexists(s:prompt_window_bufnr)
    let l:prompt_winnr = bufwinnr(s:prompt_window_bufnr)
    
    if l:prompt_winnr != -1
      " Close the history browser
      close
      
      " Switch to prompt window
      execute l:prompt_winnr . 'wincmd w'
      
      " Go to end of content and enter insert mode
      normal! G$
      startinsert
    endif
  endif
endfunction

" Close the history browser
function! vim_oracle#close_history_browser() abort
  if exists('b:vim_oracle_history_browser')
    let l:prompt_winnr = bufwinnr(s:prompt_window_bufnr)
    
    " Close this window
    close
    
    " Return to prompt window if it still exists
    if l:prompt_winnr != -1
      execute l:prompt_winnr . 'wincmd w'
    endif
  endif
endfunction
