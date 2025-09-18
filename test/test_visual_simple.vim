" Simple test for visual mode functionality

" Load the plugin
source plugin/vim-oracle.vim
source autoload/vim_oracle.vim

echo "Testing VimOracle visual mode capture..."

" Test function existence
if exists('*vim_oracle#open_prompt_window')
  echo "✓ vim_oracle#open_prompt_window function exists"
else
  echo "✗ vim_oracle#open_prompt_window function not found"
endif

echo "Visual mode test completed."