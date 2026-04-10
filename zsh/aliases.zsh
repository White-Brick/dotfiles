# Command alias
alias vim='nvim'
alias py='python3'
alias tl='tree -C -L 1'
alias mkcd='foo(){ mkdir -p "$1"; cd "$1" }; foo '
alias delELF='find . -maxdepth 1 -type f -perm +111 -exec file {} \; | grep "exe" | cut -d: -f1|xargs rm -f'
#alias gac="git add . && git commit -a -m "

# File path alias
alias Code='cd ~/Code'
alias config='cd ~/.config'

# Cloud storage paths
alias iCloud="$HOME/Library/Mobile Documents/com~apple~CloudDocs"
alias obsidian="$HOME/Library/Mobile Documents/iCloud~md~obsidian/Documents"
alias Notes="$HOME/Library/Mobile Documents/iCloud~md~obsidian/Documents/Obsidian Vault/Notes"

# C++ project shortcuts
alias Tcp='cd ~/Code/02_c++/basic/tcp'
alias Primer='cd ~/Code/02_C++/study/C++Primer-demo'
alias algorithm='cd ~/Code/02_c++/study/algorithm'
alias Linux='cd ~/Code/02_C++/Linux/'
