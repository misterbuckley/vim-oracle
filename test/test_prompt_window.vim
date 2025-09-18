" Simple test script for VimOraclePromptWindow functionality
" Source the plugin files
source plugin/vim-oracle.vim
source autoload/vim_oracle.vim

" Test that the command exists
try
  command VimOraclePromptWindow
  echo "✓ VimOraclePromptWindow command exists"
catch
  echo "✗ VimOraclePromptWindow command not found"
endtry

" Test that the function exists
if exists('*vim_oracle#open_prompt_window')
  echo "✓ vim_oracle#open_prompt_window function exists"
else
  echo "✗ vim_oracle#open_prompt_window function not found"
endif

" Test that the new send command exists
try
  command VimOraclePromptWindowSend
  echo "✓ VimOraclePromptWindowSend command exists"
catch
  echo "✗ VimOraclePromptWindowSend command not found"
endtry

" Test that the new send function exists
if exists('*vim_oracle#send_prompt_from_window')
  echo "✓ vim_oracle#send_prompt_from_window function exists"
else
  echo "✗ vim_oracle#send_prompt_from_window function not found"
endif

" Test that the history command exists
try
  command VimOracleHistory
  echo "✓ VimOracleHistory command exists"
catch
  echo "✗ VimOracleHistory command not found"
endtry

" Test that history functions exist
if exists('*vim_oracle#open_history_browser')
  echo "✓ vim_oracle#open_history_browser function exists"
else
  echo "✗ vim_oracle#open_history_browser function not found"
endif

if exists('*vim_oracle#add_to_history')
  echo "✓ vim_oracle#add_to_history function exists"
else
  echo "✗ vim_oracle#add_to_history function not found"
endif

if exists('*vim_oracle#load_history')
  echo "✓ vim_oracle#load_history function exists"
else
  echo "✗ vim_oracle#load_history function not found"
endif

echo "History functionality tests completed"