# vim-oracle

A Vim plugin that provides AI-powered code assistance by integrating with external AI tools. Send prompts to your favorite AI tool directly from Vim with automatic context about your current file and line number.

## Features

- 🤖 Integrate with any command-line AI tool
- 📁 Per-filetype prompt templates
- 🎯 Automatic context injection (filename, line number, filetype)
- ⚙️ Highly configurable
- 🔗 Simple terminal integration
- 📝 Comprehensive help documentation

## Installation

### Using vim-plug

```vim
Plug 'your-username/vim-oracle'
```

### Using Vundle

```vim
Plugin 'your-username/vim-oracle'
```

### Using Pathogen

```bash
git clone https://github.com/your-username/vim-oracle ~/.vim/bundle/vim-oracle
```

### Manual Installation

1. Download the plugin files
2. Copy the contents to your Vim configuration directory:
   - `plugin/vim-oracle.vim` → `~/.vim/plugin/`
   - `autoload/vim_oracle.vim` → `~/.vim/autoload/`
   - `doc/vim-oracle.txt` → `~/.vim/doc/`

3. Generate help tags:
   ```vim
   :helptags ~/.vim/doc
   ```

## Quick Start

1. Install the plugin using your preferred method
2. Make sure you have an AI command-line tool installed (e.g., `codex`, `chatgpt`, etc.)
3. Run `:VimOracle` (or your custom mapping) to open the AI prompt

## Configuration

Add these settings to your `.vimrc` to customize the plugin:

### Basic Configuration

```vim
" Set the AI command (default: 'codex')
let g:vim_oracle_command = 'codex --model gpt-4.1'

" Set the default prompt template (supports {filename}, {line}, {filetype} placeholders)
let g:vim_oracle_default_prompt = 'I am working in file {filename} at line {line}. '
```

### Advanced Configuration

```vim
" Configure different prompts for different file types
let g:vim_oracle_filetype_prompts = {
\ 'python': 'I am working on Python code in {filename} at line {line}. Please help with: ',
\ 'javascript': 'I am working on JavaScript in {filename} at line {line}. I need help with: ',
\ 'go': 'I am working on Go code in {filename} at line {line}. Question: ',
\ 'rust': 'I am working on Rust code in {filename} at line {line}. Please assist with: ',
\ 'vim': 'I need help with this Vim script in {filename} at line {line}. '
\ }

```

### Custom Key Mappings

Define your own mappings to trigger the plugin:

```vim
nnoremap <Leader>ask :VimOracle<CR>
nnoremap <Leader>explain :VimOraclePrompt Explain this code<CR>
nnoremap <Leader>fix :VimOraclePrompt How can I fix this?<CR>
nnoremap <Leader>optimize :VimOraclePrompt How can I optimize this code?<CR>
```

### Window Positioning

Control where the AI terminal appears:

```vim
" Open AI terminal below current window (default)
let g:vim_oracle_window_position = 'below'

" Open AI terminal on the right side
let g:vim_oracle_window_position = 'right'

" Open AI terminal in a floating window (Neovim only)
let g:vim_oracle_window_position = 'floating'

" Other options: 'above', 'left', 'tab'
```

## Usage

### Interactive Mode

Run `:VimOracle` (or your mapping) to open an interactive prompt. The prompt will be pre-filled with context about your current file and line number.
You can also open a dedicated prompt window with `:VimOraclePromptWindow`. If
you run this command from Visual mode, the selected text will be
inserted into the prompt window. Otherwise, the window is populated with the
default prompt for the current filetype. Edit the text and use
`:VimOracleSend` (or your mapping) to send it to the AI tool. The prompt window
uses the `vimoracleprompt` filetype so you can define autocmds or mappings
specific to it.

### Direct Commands

Use `:VimOraclePrompt {text}` to send a prompt directly:

```vim
:VimOraclePrompt Explain this function
:VimOraclePrompt How can I improve this code?
:VimOraclePrompt What does this regex do?
```

## Configuration Examples

### For OpenAI CLI

```vim
let g:vim_oracle_command = 'codex --model gpt-4.1'
let g:vim_oracle_default_prompt = 'I am coding in {filename} at line {line}. '
```

### For Anthropic Claude CLI

```vim
let g:vim_oracle_command = 'claude --model us.anthropic.claude-sonnet-4-20250514-v1:0'
let g:vim_oracle_default_prompt = 'File: {filename}, Line: {line}, Type: {filetype}. '
```

### For Custom AI Tool

```vim
let g:vim_oracle_command = 'my-ai-tool --verbose --output-format plain'
let g:vim_oracle_default_prompt = 'Context: {filename}:{line}. Query: '
```

### Complete Configuration Example

```vim
" Set AI command
let g:vim_oracle_command = 'codex --model gpt-4.1'

" Configure window position
let g:vim_oracle_window_position = 'floating'

" Set up filetype-specific prompts
let g:vim_oracle_filetype_prompts = {
\ 'python': 'I am working on Python code in {filename} at line {line}. ',
\ 'javascript': 'I am working on JavaScript in {filename} at line {line}. ',
\ 'go': 'I am working on Go code in {filename} at line {line}. '
\ }

" Custom key mappings
nnoremap <Leader>ai :VimOracle<CR>
nnoremap <Leader>explain :VimOraclePrompt Explain this code<CR>
```

## Available Placeholders

You can use these placeholders in your prompt templates:

- `{filename}` - Current file name
- `{line}` - Current line number  
- `{filetype}` - Current file type (as detected by Vim)

## Commands

- `:VimOracle` - Open interactive AI prompt or send current prompt window
- `:VimOraclePrompt {text}` - Send direct prompt to AI tool
- `:VimOraclePromptWindow` - Open a scratch buffer for editing a prompt. If text
  is visually selected when the command is run, that text pre-fills the window
  instead of the default prompt
- `:VimOracleSend` - Send the contents of the current prompt window

## Help

Access the built-in help documentation:

```vim
:help vim-oracle
```

## Requirements

- Vim 7.0 or later
- An external AI command-line tool (e.g., OpenAI CLI, Claude CLI, etc.)

## Contributing

Contributions are welcome! Please feel free to submit issues and pull requests.

## License

This plugin is released under the MIT License.
