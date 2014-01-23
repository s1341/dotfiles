GIT_DIRTY_COLOR=$FG[133]
GIT_CLEAN_COLOR=$FG[118]
GIT_PROMPT_INFO=$FG[012]
ZSH_THEME_GIT_PROMPT_PREFIX=" "
ZSH_THEME_GIT_PROMPT_SUFFIX="%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_DIRTY="[%{$GIT_DIRTY_COLOR%}✘%{$reset_color%}]"
ZSH_THEME_GIT_PROMPT_CLEAN="[%{$GIT_CLEAN_COLOR%}✔%{$reset_color%}]"

ZSH_THEME_GIT_PROMPT_ADDED="%{$FG[082]%}＋%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_MODIFIED="%{$FG[166]%}≠%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_DELETED="%{$FG[160]%}✘%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_UNMERGED="%{$FG[082]%}⋇%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_UNTRACKED="%{$FG[190]%}➘%{$reset_color%}"

prompt_git () {
    echo "$(git_prompt_info)%{$GIT_DIRTY_COLOR%}$(git_prompt_status)"
}

prompt_context () {
    local context=""
    local user=`whoami`
    if [[ "$DEFAULT_USER" != "$user" || -n "$SSH_CLIENT" ]]; then
        context="%{$fg[yellow]%}⚡ $user@%m %{$reset_color%}"
    elif [[ -n "$SUDO_USER" ]]; then
        context="%{$fg[red]%}⚙ $user@%m %{$reset_color%}"
    fi
    echo -n $context
}

prompt_path () {
    echo -n "[%{$fg[green]%}%~%{$reset_color%}]"
}

prompt_return_code () {
    local _result=""
    [[ $RETVAL -ne 0 ]] && _result="%{$fg_bold[red]%}✘%{$reset_color%}" \
                        || _result="%{$fg_bold[green]%}✔%{$reset_color%}";
    echo -n "[$_result]"
}

# If I am using vi keys, I want to know what mode I'm currently using.
# zle-keymap-select is executed every time KEYMAP changes.
# From http://zshwiki.org/home/examples/zlewidgets
VIMODE="[i]"
function zle-keymap-select {
    VIMODE="${${KEYMAP/vicmd/[n]}/(main|viins)/[i]}"
    zle reset-prompt
}
zle -N zle-keymap-select

prompt_vim_mode () {
    echo -n "%{$fg[yellow]%}$VIMODE%{$reset_color%}"
}

build_prompt () {
    RETVAL=$?
    echo -n "╭─"
    prompt_context
    prompt_vim_mode
    prompt_path
    echo
    echo -n "╰─"
    prompt_return_code
    echo "%{$FG[104]%}$%{$reset_color%}"
}

PROMPT='%{%f%b%k%}$(build_prompt) '
RPROMPT='$(prompt_git)'
