# vim-oracle Development Guide

## Testing

### Running Tests

To run the basic functionality tests:

```bash
vim -c 'source test/test_prompt_window.vim' -c 'q' 2>&1 | grep -E "[✓✗]"
```

This command will:
- Load vim in non-interactive mode
- Source the test file
- Filter output to show only test results (✓ for pass, ✗ for fail)
- Exit vim automatically

### Test Structure

Tests are located in the `test/` directory. Each test file should:
- Source the necessary plugin files
- Test for command existence using `command CommandName`
- Test for function existence using `exists('*function_name')`
- Use ✓ and ✗ symbols to indicate pass/fail status
- Include descriptive output messages

### Adding New Tests

When adding new functionality:
1. Create or update test files in the `test/` directory
2. Follow the existing test pattern for consistency
3. Test both command availability and function existence
4. Run tests to ensure they pass before committing changes

### Current Test Coverage

- `test/test_prompt_window.vim`: Tests for VimOraclePromptWindow functionality
  - Verifies `:VimOraclePromptWindow` command exists
  - Verifies `vim_oracle#open_prompt_window()` function exists

## Features

### VimOraclePromptWindow

The `:VimOraclePromptWindow` command opens a small, temporary window at the bottom of the current window where users can edit the default prompt before sending it to the AI.

**Usage:**
1. Run `:VimOraclePromptWindow` to open the prompt editing window
2. The window will be populated with the formatted default prompt (including current filename and line number)
3. Edit the prompt as needed
4. Press Enter (in normal or insert mode) or run `:VimOracle` to send the prompt and open the AI chat
5. The prompt window will close automatically and the chat window will open with your custom prompt

**Key Features:**
- Pre-populated with context-aware default prompt
- Small window (5 lines) positioned at bottom
- Temporary buffer that doesn't create files
- Enter key shortcut for quick execution
- Integrates seamlessly with existing `:VimOracle` command

**Implementation Details:**
- Command: `:VimOraclePromptWindow` → `vim_oracle#open_prompt_window()`
- Window marked with `b:vim_oracle_prompt_window = 1`
- Buffer type: `nofile`, `bufhidden=wipe`, no swapfile
- Filetype: `vim_oracle_prompt`
- Key mappings: `<CR>` in both normal and insert mode

## Development Guidelines

- Always add tests when implementing new features
- Update existing tests when modifying functionality
- Ensure all tests pass before submitting changes
- Follow existing code patterns and conventions