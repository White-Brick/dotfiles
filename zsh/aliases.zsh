# Command alias
alias vim='nvim'
alias py='python3'
alias tl='tree -C -L 1'
alias mkcd='foo(){ mkdir -p "$1"; cd "$1" }; foo '
alias delELF='find . -maxdepth 1 -type f -perm +111 -exec file {} \; | grep "exe" | cut -d: -f1|xargs rm -f'
#alias gac="git add . && git commit -a -m "
