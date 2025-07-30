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

echo "Basic tests completed"