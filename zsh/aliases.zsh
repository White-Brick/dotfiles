# Command alias
alias vim='nvim'
alias py='python3'
alias jst='joshuto'
alias mkcd='foo(){ mkdir -p "$1"; cd "$1" }; foo '
alias delELF='find . -maxdepth 1 -type f -perm +111 -exec file {} \; | grep "exe" | cut -d: -f1|xargs rm -f'
#alias gac="git add . && git commit -a -m "

# File path alias
alias Code='cd ~/Code'
alias Notes='cd /Users/geewinter/Library/Mobile\ Documents/com\~apple\~CloudDocs/Coding/Notes/'
alias algorithm='cd /Users/geewinter/Code/02_c++/study/algorithm'
alias config='cd ~/.config'
alias Linux='cd ~/Code/02_C++/Linux/'

