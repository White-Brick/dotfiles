# Command alias
alias vim='nvim'
alias py='python3'
alias jst='joshuto'
alias tl='tree -C -L 1'
alias mkcd='foo(){ mkdir -p "$1"; cd "$1" }; foo '
alias delELF='find . -maxdepth 1 -type f -perm +111 -exec file {} \; | grep "exe" | cut -d: -f1|xargs rm -f'
#alias gac="git add . && git commit -a -m "

# File path alias
alias Code='cd ~/Code'
alias Primer='cd /Users/geewinter/Code/02_C++/study/C++Primer-demo'
alias Notes='cd /Users/geewinter/Library/Mobile\ Documents/iCloud~md~obsidian/Documents/Obsidian\ Vault/Notes'
alias algorithm='cd /Users/geewinter/Code/02_c++/study/algorithm'
alias config='cd ~/.config'
alias Linux='cd ~/Code/02_C++/Linux/'
alias obsidian='cd /Users/geewinter/Library/Mobile\ Documents/iCloud~md~obsidian/Documents'
alias iCloud='cd /Users/geewinter/Library/Mobile\ Documents/com~apple~CloudDocs'

