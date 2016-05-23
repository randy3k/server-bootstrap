# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# remove mac directory title
if [[ $- == *i* ]] ; then
    printf '\e]7;%s\a'
fi

# ignore ctrl-d
IGNOREEOF=1

# PS1
PS1="\[\033[33m\](\h)\[\033[00m\]-\W\\$ "
PS1='\[\e]0;\u@\h\a\]'"$PS1"

# color
LS_COLORS='di=34:fi=0:ln=35:pi=36;1:so=33;1:bd=0:cd=0:or=35;4:mi=0:ex=31:su=0;7;31:*.rpm=90'

# aliases
NPS='ps ax -o user,pid,pcpu,pmem,nice,stat,cputime,etime,command | grep -v "^USER" | awk '"'"'$3 > 1'"'"''
CUT='if [[ -t 1 ]]; then (cat | cut -c 1-$COLUMNS); else cat; fi'
alias nps="$NPS | $CUT"
alias rmtex='rm -f *.aux *.dvi *.lis *.log *.blg *.bbl *.toc *.idx *.ind *.ilg *.thm *.out
*.fdb_latexmk *.fls *.synctex.gz *.nav *.snm'
# alias sudo='sudo '
# alias rsync="rsync -av --exclude \".*\""
alias ls='ls --color=auto'
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias h=history
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
alias R='R --no-save'
alias r='R --no-save'
alias p='ipython'
alias j='julia'

# bash completion
if [[ $- == *i* ]] ; then
    bind "set completion-ignore-case on"
    bind "set show-all-if-ambiguous on"
    bind "set colored-stats on"
    bind "set colored-completion-prefix on"
    bind TAB:menu-complete
fi

# alt arrow keys
if [[ $- == *i* ]] ; then
    bind '"\e[1;3C": forward-word'
    bind '"\e[1;3D": backward-word'
fi

function bootstrap {
    case "$1" in
        subl)
            curl -s https://raw.githubusercontent.com/randy3k/server-bootstrap/master/subl.sh | bash
        ;;
        ruby)
            curl -s https://raw.githubusercontent.com/randy3k/server-bootstrap/master/ruby_local_install.sh | bash
        ;;
        brew)
            curl -s https://raw.githubusercontent.com/randy3k/server-bootstrap/master/linuxbrew.sh | bash
        ;;
        conda)
            curl -s https://raw.githubusercontent.com/randy3k/server-bootstrap/master/conda.sh | bash
        ;;
        julia)
            curl -s https://raw.githubusercontent.com/randy3k/server-bootstrap/master/julia_local_install.sh | bash
        ;;
        *)
            curl -s https://raw.githubusercontent.com/randy3k/server-bootstrap/master/bootstrap.sh | bash
        ;;
    esac
    source ~/.bash_profile
}

# for gauss
if [ "$(hostname)" == "gauss" ]; then

    function slurm {
        if [[ -n "$SLURM_NTASKS" ]]
        then
            echo -e "[-N${SLURM_NNODES} -n${SLURM_NTASKS}]"
        fi
    }
    PS1="\[\033[33m\](\h)\[\033[00m\]\[\033[32m\]$(slurm)\[\033[00m\]-\W\\\$ "
    PS1='\[\e]0;\u@\h\a\]'"$PS1"

    function sapply {
        if [ -z "$@" ]; then
            cmd="export COLUMNS=$COLUMNS; $NPS | $CUT"
        else
            cmd="$@"
        fi
        # echo $cmd
        hosts=`sinfo|grep -v ^PARTITION|grep c0|grep -v down|awk {'print $6'}|sed -r 's/(\[|,)([0-9]+)-([0-9]+)/\1$(echo {\2..\3})/g;s/^/echo /'|bash|sed -r 's/ /,/g;s/\[/{/;s/\]/}/;s/^/echo /'|bash|sed 's/\s/\n/g'|sort|uniq`
        for j in $hosts; do echo $j; ssh $j "$cmd"; done;
    }

    alias killr="killall -9 -u rcslai R; sapply 'killall -9 -u rcslai R'"

    function sjobs {
        if [ -z $1 ]; then
            NAME=$LOGNAME
        else
            NAME=$1
        fi
        sapply "export COLUMNS=$COLUMNS; $NPS | grep $NAME | grep -v 'grep'" | eval "$CUT"
    }

else
    function git-branch-name {
        echo `git symbolic-ref HEAD --short 2> /dev/null || (git branch | sed -n 's/\* (*\([^)]*\))*/\1/p')`
    }

    function git-dirty {
        st=$(git status 2>/dev/null | tail -n 1)
        if [[ ! $st =~ "working directory clean" ]]
        then
            echo "*"
        fi
    }

    function git-unpushed {
        brinfo=`git branch -v | grep "$(git-branch-name)"`
        if [[ $brinfo =~ ("behind "([[:digit:]]*)) ]]
        then
            echo -n "-${BASH_REMATCH[2]}"
        fi
        if [[ $brinfo =~ ("ahead "([[:digit:]]*)) ]]
        then
            echo -n "+${BASH_REMATCH[2]}"
        fi
    }
    function gitcolor {
        st=$(git status 2>/dev/null | head -n 1)
        if [[ ! $st == "" ]]
        then
            if [[ $(git-dirty) == "*" ]];
            then
                echo -e "\033[31m"
            elif [[ $(git-unpushed) != "" ]];
            then
                echo -e "\033[33m"
            else
                echo -e "\033[32m"
            fi
        fi
    }
    function gitify {
        st=$(git status 2>/dev/null | head -n 1)
        if [[ ! $st == "" ]]
        then
            echo -e " ($(git-branch-name)$(git-dirty)$(git-unpushed))"
        fi
    }
    PS1="\[\033[33m\](\h)\[\033[00m\]-\W\[\$(gitcolor)\]\$(gitify)\[\033[00m\]\$ "
    PS1='\[\e]0;\a\]'"$PS1"

fi
