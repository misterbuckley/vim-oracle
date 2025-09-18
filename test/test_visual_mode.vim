" Test VimOraclePromptWindow with visual mode selection

" Source the plugin files
source autoload/vim_oracle.vim
source plugin/vim-oracle.vim

" Create a test file with multiple lines
let g:test_content = [
  \ 'function test_function() {',
  \ '  console.log("Hello, world!");',
  \ '  return 42;',
  \ '}'
]

" Test: VimOraclePromptWindow command should exist
try
  command VimOraclePromptWindow
  echo "✓ VimOraclePromptWindow command exists"
catch
  echo "✗ VimOraclePromptWindow command does not exist"
endtry

" Test: Function should exist
if exists('*vim_oracle#open_prompt_window')
  echo "✓ vim_oracle#open_prompt_window() function exists"
else
  echo "✗ vim_oracle#open_prompt_window() function does not exist"
endif

" Test: Function should handle range parameters
try
  " Test with no range (should work without errors)
  call vim_oracle#open_prompt_window()
  if exists('b:vim_oracle_prompt_window')
    echo "✓ Function works with no range parameters"
    close
  else
    echo "✗ Function failed with no range parameters"
  endif
catch /E117/ " Too many arguments
  echo "✗ Function doesn't accept variable arguments"
catch
  echo "✗ Function failed with no range: " . v:exception
endtry

" Test: Function should handle range parameters
try
  " Create a temporary buffer with test content
  new
  call setline(1, g:test_content)

  " Test with range (lines 2-3)
  call vim_oracle#open_prompt_window(2, 3)

  if exists('b:vim_oracle_prompt_window')
    " Check if the prompt window contains the selected text
    let l:window_content = join(getline(1, '$'), "\n")
    if l:window_content =~# 'console\.log.*return 42'
      echo "✓ Function correctly includes visual selection in prompt window"
    else
      echo "✗ Function did not include visual selection. Content: " . l:window_content
    endif
    close
  else
    echo "✗ Function failed to create prompt window with range"
  endif

  " Clean up test buffer
  close
catch
  echo "✗ Function failed with range: " . v:exception
endtry

echo "Test completed"