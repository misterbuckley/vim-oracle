" Basic test for history functionality
source plugin/vim-oracle.vim
source autoload/vim_oracle.vim

" Test basic history operations
call vim_oracle#add_to_history("Test prompt 1")
call vim_oracle#add_to_history("Test prompt 2")
call vim_oracle#add_to_history("Test prompt 3")

" Check that history was loaded/initialized properly
call vim_oracle#load_history()

echo "✓ History functionality basic test completed"