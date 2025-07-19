" vim-oracle.vim - AI-powered code assistance plugin
" Maintainer: vim-oracle
" Version: 1.0.0

if exists('g:loaded_vim_oracle')
  finish
endif
let g:loaded_vim_oracle = 1

if !exists('g:vim_oracle_command')
  let g:vim_oracle_command = 'codex'
endif

if !exists('g:vim_oracle_default_prompt')
  let g:vim_oracle_default_prompt = 'I am working in the file {filename} at line {line}. '
endif

if !exists('g:vim_oracle_filetype_prompts')
  let g:vim_oracle_filetype_prompts = {}
endif

if !exists('g:vim_oracle_window_position')
  let g:vim_oracle_window_position = 'below'
endif

command! -nargs=? VimOracleOpenChat call vim_oracle#open_chat(<q-args>)

" Auto-refresh chat buffers when switching tabs to ensure latest messages are visible
augroup VimOracleChat
  autocmd!
  autocmd TabEnter * call vim_oracle#refresh_chat_on_tab_enter()
augroup END
