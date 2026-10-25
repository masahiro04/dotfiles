# dotfiles

Personal configuration for macOS: Neovim (LazyVim), zsh, git, and a few other tools.

## Layout

```
.
├── .zshrc              # zsh: PATH, aliases, prompt, language runtimes
├── .gitconfig          # git user, push defaults, git-secrets patterns
├── .gitignore          # global ignore
├── install.sh          # symlinks the dotfiles into $HOME
└── .config/
    ├── nvim/           # Neovim (LazyVim based)
    ├── git/ignore      # extra global ignore rules
    ├── herdr/          # herdr config.toml
    ├── solargraph/     # Ruby LSP (solargraph) config
    └── zed/            # Zed editor settings
```

Runtime state and credentials under `.config/` (gh, gcloud, op, iterm2, etc.)
are gitignored and never committed.

## Setup

```sh
git clone <this repo> ~/dotfiles
cd ~/dotfiles
source install.sh
```

`install.sh` symlinks every top-level dotfile (including `.config/`) into `$HOME`.
Neovim bootstraps lazy.nvim on first launch, so no extra install step is needed.

## Neovim

Built on [LazyVim](https://www.lazyvim.org/). The leader key is LazyVim's default (`<Space>`).

### Extras enabled

Linting / formatting: eslint, prettier.
Languages: TypeScript, JSON, Tailwind, Docker, Markdown, Prisma, Ruby (solargraph), Rust, SQL, Terraform, TOML, YAML.
Also: Copilot, mini-hipatterns.

### Custom plugins (`lua/plugins/`)

| File                   | What it does                                                          |
| ---------------------- | --------------------------------------------------------------------- |
| `colorschema.lua`      | tokyonight colorscheme                                                |
| `ui.lua`               | noice, nvim-notify (bottom-right), lualine (nightfly), incline        |
| `bufferline.lua`       | bufferline tweaks                                                     |
| `editor.lua`           | flash, winresizer, vim-better-whitespace, and other editing helpers   |
| `treesitter.lua`       | treesitter parsers                                                    |
| `lsp-hover.lua`        | LSP hover window tweaks                                               |
| `diffview.lua`         | diffview, plus `:G diff` / `:G diffmain` / `:G diffparent` wrappers   |
| `markdown-preview.lua` | markdown-preview.nvim                                                 |
| `render-markdown.lua`  | in-buffer Markdown rendering                                          |

### Custom modules (`lua/`)

- **`cheatsheet/`**: a searchable cheatsheet of every keymap and command in this config. Open it with `;?` (fuzzy search) or `;k` (floating list). `<C-h>` on an entry jumps to the related `:help`. The data lives in `lua/cheatsheet/data.lua`; add a line there whenever you add a keymap.
- **`review/`**: code review comments stored outside the source tree in `.review/` at the git root. Add comments with `<leader>aa`, list them with `<leader>al`, yank them as Markdown with `<leader>ay`, and publish them to the current PR as a draft review with `<leader>ap` (uses `gh`). Also fetches and replies to existing PR threads. See `:help review`.
- **`browser_preview/`**: open the current file (for example a PNG) in a browser with `<leader>ob` or `:BrowserPreview [path]`. See `:help browser-preview`.

### Frequently used keymaps

Everything below is also in the cheatsheet (`;?`).

```
jj              leave insert mode
ss / sv         horizontal / vertical split
sh sj sk sl     move between windows
<C-e> / <C-r>   winresizer mode
bp / bn / bd    previous / next / close buffer
te              new tab
nh              clear search highlight
qq              jump anywhere on screen (flash)
dr              rename symbol
<C-j>           next diagnostic
<leader>y       copy the relative path of the current file
```

Git:

```
:G                   fugitive status, full screen in a new tab (gq to close)
:G diff              2-column diff in diffview
:G diff main...HEAD  PR-style three-dot diff
:G diffmain          diff against origin/main
:G diffparent        diff against the parent branch (for stacked branches)
<leader>gg           LazyGit
]h / [h              next / previous hunk
```

### Plugin management

Use `:Lazy! install` to install new plugins. Do **not** run `:Lazy sync`: it also
updates LazyVim itself and has broken the UI before. `lazy-lock.json` is
gitignored and kept local.

## zsh

- Homebrew (arm) first in `PATH`.
- Aliases: `g` (git), `gs` (git switch), `vi` (nvim), `d` / `de` / `dew` / `dcu` (docker compose), `hw` (herdr workspace create), `a` / `aa` / `aaa` (cd up).
- `delete-merged-branches` removes local branches already merged into main.
- Loads nvm, rbenv, goenv, cargo, tfenv, pnpm, and the Google Cloud SDK.
- vcs_info shows the current git branch and dirty state in the prompt.

## git

`.gitconfig` sets `push.autoSetupRemote`, `core.autocrlf = input`, and
[git-secrets](https://github.com/awslabs/git-secrets) patterns for AWS keys.
`.config/git/ignore` holds additional global ignore rules.
