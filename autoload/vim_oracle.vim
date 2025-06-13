" vim_oracle.vim - Autoload functions for vim-oracle plugin

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

function! vim_oracle#prompt_with_text(text) abort
  let filename = expand('%')
  let linenum = line('.')
  let filetype = &filetype
  
  let prompt_template = vim_oracle#get_prompt_template(filetype)
  let default_prompt = vim_oracle#format_prompt(prompt_template, filename, linenum)
  
  let full_prompt = default_prompt . a:text
  call vim_oracle#execute_command(full_prompt)
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

" Wrapper for <Leader>ai mapping. If called from a prompt window, send the
" buffer contents instead of opening a new command-line prompt.
function! vim_oracle#invoke() abort
  if exists('b:vim_oracle_prompt_window')
    call vim_oracle#send_prompt_buffer()
  else
    call vim_oracle#prompt()
  endif
endfunction

" Open a small scratch buffer pre-populated with the default prompt
function! vim_oracle#open_prompt_window() abort
  let l:prompt = ''
  " If the user had text selected in visual mode, yank it and use it as the prompt.
  if line("'<") > 0 && line("'>") > 0
    silent! normal! `<v`>y
    let l:prompt = getreg("\"")
  endif

  if empty(l:prompt)
    let l:filename = expand('%')
    let l:linenum = line('.')
    let l:filetype = &filetype
    let l:template = vim_oracle#get_prompt_template(l:filetype)
    let l:prompt = vim_oracle#format_prompt(l:template, l:filename, l:linenum)
  endif

  botright new
  resize 5
  setlocal buftype=nofile bufhidden=wipe noswapfile nobuflisted
  setlocal filetype=vimoracleprompt
  let b:vim_oracle_prompt_window = 1
  call setline(1, split(l:prompt, "\n"))
  normal! G$
  startinsert!
endfunction

" Send the contents of the current prompt buffer to the AI tool and close it
function! vim_oracle#send_prompt_buffer() abort
  if !exists('b:vim_oracle_prompt_window')
    call vim_oracle#prompt()
    return
  endif

  let l:prompt = join(getline(1, '$'), "\n")
  bwipeout!
  call vim_oracle#execute_command(l:prompt)
endfunction
