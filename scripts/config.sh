#!/bin/bash
echo "# --------------------------------------------"
echo "# Configure some terminal settings.           "
echo "#                                             "
echo "# Author : Keegan Mullaney                    "
echo "# Website: http://keegoid.com                 "
echo "# Email  : keeganmullaney@gmail.com           "
echo "#                                             "
echo "# http://keegoid.mit-license.org              "
echo "# --------------------------------------------"

# --------------------------  SETUP PARAMETERS

[ -z "$CONFIG" ] && CONFIG="$HOME/.quick-config"
[ -z "$BACKUP" ] && BACKUP="$CONFIG/backup"
[ -z "$SYNCED" ] && SYNCED="$HOME/Dropbox/Config"

# config files
CONF1="$HOME/.bashrc"
CONF2="$HOME/.inputrc"
CONF3="$HOME/.config/sublime-text-3/Packages/User/Preferences.sublime-settings"
CONF4="$HOME/.config/sublime-text-3/Packages/User/Monokai - Spacegray.tmTheme"
CONF5="$HOME/.config/sublime-text-3/Packages/User/Monokai-Spacegray.sublime-theme"
CONF6="$HOME/.muttrc"
CONF7="$HOME/.tmux.conf"
CONF8="$HOME/.vimrc"
CONF9="$HOME/.gitignore_global"

# --------------------------  BACKUPS

# backup config files
do_backup() {
    local name
    local today

    confirm "Backup config files before making changes?" true
    [ "$?" -gt 0 ] && return 1

    today=`date +%Y%m%d_%s`
    mkdir -pv "$BACKUP-$today"

    for i in $1; do
        echo "$i"
        if [ -e "$i" ] && [ ! -L "$i" ]; then
            name=$(trim_longest_left_pattern "$i" "/")
            cp "$i" "$BACKUP-$today/$name" && success "made backup: $BACKUP-$today/$name"
        fi
    done

    RET="$?"
    debug

    return 0
}

# --------------------------  GIT CONFIG

set_git_config() {
    # check if already configured
    if ! git config --list | grep -q "user.name"; then
        read -ep "your name for git commit logs: " -i 'Keegan Mullaney' real_name
        read -ep "your email for git commit logs: " -i 'keeganmullaney@gmail.com' email_address
        read -ep "your preferred text editor for git commits: " -i 'vi' git_editor
        configure_git "$real_name" "$email_address" "$git_editor" && success "configured: $1"
    fi

    RET="$?"
    debug
}

# --------------------------  TERMINAL HISTORY LOOKUP (also awesome)

set_terminal_history() {
    local conf_file="$1"

    [ -f $conf_file ] || touch $conf_file
    if grep -q "backward-char" $conf_file >/dev/null 2>&1; then
        notify "already added terminal history lookup"
    else
        pause "Press [Enter] to configure .inputrc" true
cat << 'EOF' >> $conf_file 
# terminal history lookup
'\e[A': history-search-backward
'\e[B': history-search-forward
'\e[C': forward-char
'\e[D': backward-char
EOF
        success "configured: $conf_file"
    fi

    RET="$?"
    debug
}

# --------------------------  TERMINAL COLOR PROMPTS

set_terminal_color() {
    local conf_file="$1"

    if grep -q "#force_color_prompt=yes" $conf_file >/dev/null 2>&1; then
        pause "Press [Enter] to activate color terminal prompts" true
        sed -i.bak -e "/force_color_prompt=yes/ s/^# //" $conf_file && source $conf_file && success "configured: $conf_file with color terminal prompts"
    else
        notify "already set color prompts"
    fi

    RET="$?"
    debug
}

# --------------------------  AUTOJUMP (so awesome)

set_autojump() {
    local conf_file="$1"
    local src_cmd="$2"

    if grep -q "autojump/autojump.sh" $conf_file >/dev/null 2>&1; then
        notify "already added autojump (usage: j directory)"
    else
        pause "Press [Enter] to configure autojump for gnome-terminal" true
        echo -e "$src_cmd" >> $conf_file && source $conf_file && success "configured: $conf_file with autojump"
    fi

    RET="$?"
    debug
}

# --------------------------  MAIN

pause "" true

do_backup               "$CONF1 $CONF2 $CONF3 $CONF4 $CONF5 $CONF6 $CONF7 $CONF8 $CONF9"

# aliases (to practice terminal commands for Linux certification exams, I'm not using aliases at the moment)
#set_sourced_config      "$HOME/.bashrc" \
#                        "https://gist.github.com/9d74e08779c1db6cb7b7" \
#                        "$CONFIG/bash/aliases/bash_aliases" \
#                        "\n# source alias file\nif [ -f $CONFIG/bash/aliases/bash_aliases ]; then\n   . $CONFIG/bash/aliases/bash_aliases\nfi"

# mutt color scheme
set_sourced_config      "$HOME/.muttrc" \
                        "https://github.com/altercation/mutt-colors-solarized.git" \
                        "$CONFIG/mutt/colors/mutt-colors-solarized-dark-16.muttrc" \
                        "# source colorscheme file\nsource $CONFIG/mutt/colors/mutt-colors-solarized-dark-16.muttrc"

# tmux config
set_sourced_config      "$HOME/.tmux.conf" \
                        "https://gist.github.com/3247d5a1c172167e593c.git" \
                        "$CONFIG/tmux/tmux.conf" \
                        "source-file $CONFIG/tmux/tmux.conf"

# vim config
set_sourced_config      "$HOME/.vimrc" \
                        "https://gist.github.com/00a60c7355c27c692262.git" \
                        "$CONFIG/vim/vim.conf" \
                        "\" source config file\n:so $CONFIG/vim/vim.conf"

[ -d "$SYNCED/vim" ] || { mkdir -pv "$SYNCED/vim"; notify3 "note: vim spellfile will be located in $SYNCED/vim, you can change this in $CONFIG/vim/vim.conf"; }

# terminal profile (can't find profile file in new Ubuntu 16.04)
#set_copied_config       "$HOME/.gconf/apps/gnome-terminal/profiles/Default/%gconf.xml" \
#                        "https://gist.github.com/dad1663d2463db32c6e8.git" \
#                        "$CONFIG/terminal/profile/gconf.xml"

# sublime text
mkdir -p "$HOME/.config/sublime-text-3/Packages/User"
set_copied_config       "$HOME/.config/sublime-text-3/Packages/User/Preferences.sublime-settings" \
                        "https://gist.github.com/2ff3aa9ce91ff6e0e706.git" \
                        "$CONFIG/subl/config/subl.conf"

set_copied_config       "$HOME/.config/sublime-text-3/Packages/User/Monokai - Spacegray.tmTheme" \
                        "https://github.com/keegoid/monokai-spacegray.git" \
                        "$CONFIG/subl/color_schemes/monokai-spacegray/Monokai - Spacegray.tmTheme"

set_copied_config       "$HOME/.config/sublime-text-3/Packages/User/Monokai-Spacegray.sublime-theme" \
                        "https://gist.github.com/1c5164d1f9e71d570eda.git" \
                        "$CONFIG/subl/themes/1c5164d1f9e71d570eda/Monokai-Spacegray.sublime-theme"

set_copied_config       "$HOME/.gitignore_global" \
                        "https://gist.github.com/efa547b362910ac7077c.git" \
                        "$CONFIG/git/gitignore_global"

set_git_config          "$HOME/.gitconfig"

set_terminal_history    "$HOME/.inputrc"

# already done in Ubuntu 16.04
#set_terminal_color      "$HOME/.bashrc"

set_autojump            "$HOME/.bashrc" \
                        "\n# source autojump file\nif [ -f /usr/share/autojump/autojump.sh ]; then\n   . /usr/share/autojump/autojump.sh\nfi"

[ "$?" -eq 0 ] && source "$HOME/.bashrc"
