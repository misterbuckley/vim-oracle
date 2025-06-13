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

command! -nargs=0 VimOracle call vim_oracle#invoke()
command! -nargs=1 VimOraclePrompt call vim_oracle#prompt_with_text(<q-args>)
command! -nargs=0 VimOraclePromptWindow call vim_oracle#open_prompt_window()
command! -nargs=0 VimOracleSend call vim_oracle#send_prompt_buffer()

if !exists('g:vim_oracle_no_mappings') || !g:vim_oracle_no_mappings
  nnoremap <Leader>ai :VimOracle<CR>
endif