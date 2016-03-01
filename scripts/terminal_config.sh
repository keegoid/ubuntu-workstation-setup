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

read -ep "Directory to use for config files: ~/" -i "Dropbox/Config" CONFIG

# --------------------------------------------
# .bashrc
# --------------------------------------------

# aliases
if [ -f "$HOME/$CONFIG/.bash_aliases" ]; then
   echo "already added aliases"
else
   pause "Press [Enter] to add useful aliases" true
   cp "$PROJECT/includes/.bash_aliases" "$HOME/$CONFIG"
cat << EOF >> "$HOME/.bashrc"
# source .bash_aliases
if [ -f ~/$CONFIG/.bash_aliases ]; then
    . ~/$CONFIG/.bash_aliases
fi
EOF
   [ -f "$HOME/$CONFIG/.bash_aliases" ] && source "$HOME/.bashrc" && echo ".bash_aliases was copied to ~/$CONFIG and sourced"
fi

# autojump
if [ -f "$HOME/$CONFIG/.bash_config" ]; then
   echo "already added autojump (usage: j directory)"
else
   pause "Press [Enter] to add autojump to bash" true
   cp "$PROJECT/includes/.bash_config" "$HOME/$CONFIG"
cat << EOF >> "$HOME/.bashrc"
# source .bash_config
if [ -f ~/$CONFIG/.bash_config ]; then
   . ~/$CONFIG/.bash_config
fi
EOF
   [ -f "$HOME/$CONFIG/.bash_config" ] && source "$HOME/.bashrc" && echo ".bash_config was copied to ~/$CONFIG and sourced"
fi

# color terminal prompts
if grep -q "#force_color_prompt=yes" $HOME/.bashrc; then
   pause "Press [Enter] to activate color terminal prompts" true
   sed -i.bak -e "s|#force_color_prompt=yes|force_color_prompt=yes|" $HOME/.bashrc
else
   echo "already set color prompts"
fi

# --------------------------------------------
# .inputrc
# --------------------------------------------

# terminal history lookup
if [ -f "$HOME/$CONFIG/.input_config" ]; then
   echo "already added terminal history lookup"
else
   pause "Press [Enter] to configure .inputrc" true
   cp "$PROJECT/includes/.input_config" "$HOME/$CONFIG"
cat << EOF >> "$HOME/.inputrc"
\$include ~/$CONFIG/.input_config
EOF
   [ -f "$HOME/$CONFIG/.input_config" ] && echo ".input_config was copied to ~/$CONFIG"
fi

# --------------------------------------------
# .vimrc
# --------------------------------------------

# install vim plugins and colorthemes
[ -d "$HOME/.vim/autoload/pathogen" ] || git clone https://github.com/tpope/vim-pathogen.git $HOME/.vim/autoload/pathogen && cp $HOME/.vim/autoload/pathogen/autoload/pathogen.vim $HOME/.vim/autoload && echo "vim plugin pathogen was installed"
[ -d "$HOME/.vim/colors/badwolf" ] || git clone https://github.com/sjl/badwolf.git $HOME/.vim/colors/badwolf && cp $HOME/.vim/colors/badwolf/colors/badwolf.vim $HOME/.vim/colors && echo "vim colortheme badwolf was installed"
[ -d "$HOME/.vim/bundle/gundo" ] || git clone https://github.com/sjl/gundo.vim.git $HOME/.vim/bundle/gundo && echo "vim plugin gundo was installed"
[ -d "$HOME/.vim/bundle/ag" ] || git clone https://github.com/rking/ag.vim.git $HOME/.vim/bundle/ag && echo "vim plugin ag was installed"
[ -d "$HOME/.vim/bundle/ctrlp" ] || git clone https://github.com/ctrlpvim/ctrlp.vim.git $HOME/.vim/bundle/ctrlp && echo "vim plugin ctrlp was installed"

# configure vim (from http://dougblack.io/words/a-good-vimrc.html)
if [ -f "$HOME/$CONFIG/.vim_config" ]; then
   echo "already configured .vimrc"
else
   pause "Press [Enter] to configure .vimrc" true
   cp "$PROJECT/includes/.vim_config" "$HOME/$CONFIG"
cat << EOF >> "$HOME/.vimrc"
" source config file
:so ~/$CONFIG/.vim_config
EOF
   [ -f "$HOME/$CONFIG/.vim_config" ] && echo ".vim_config was copied to ~/$CONFIG"
fi

