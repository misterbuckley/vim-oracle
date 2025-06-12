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
    call termopen(a:command)
  else
    call term_start(a:command, {'curwin': 1})
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
  call termopen(a:command)
  startinsert
endfunction
