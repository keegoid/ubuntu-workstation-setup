#!/bin/bash
echo "# --------------------------------------------"
echo "# Install and update programs.                "
echo "#                                             "
echo "# Author : Keegan Mullaney                    "
echo "# Website: http://keegoid.com                 "
echo "# Email  : keeganmullaney@gmail.com           "
echo "#                                             "
echo "# http://keegoid.mit-license.org              "
echo "# --------------------------------------------"

# --------------------------  SETUP PARAMETERS

[ -z "$RUBY_V" ] && RUBY_V='2.2.3'

# --------------------------  MISSING PROGRAM CHECKS

# install lists (perform install)
apt_install_list=()
gem_install_list=()
npm_install_list=()
pip_install_list=()

# check lists (check if installed)
apt_check_list=()
gem_check_list=()
npm_check_list=()
pip_check_list=()

# loop through check list and add missing packages to install list
apt_check() {
    local pkg
    local pkg_version

    for pkg in "${apt_check_list[@]}"; do
        if not_installed $pkg; then
            echo -e " ${YELLOW_BLACK} * $pkg [not installed] ${NONE_WHITE}"
            apt_install_list+=($pkg)
        else
            pkg_version=$(dpkg -s "${pkg}" 2>&1 | grep 'Version:' | cut -d " " -f 2)
            space_count="$(expr 20 - "${#pkg}")"
            pack_space_count="$(expr 20 - "${#pkg_version}")"
            real_space="$(expr ${space_count} + ${pack_space_count} + ${#pkg_version})"
            echo -en " ${GREEN_CHK}"
            printf " $pkg %${real_space}.${#pkg_version}s ${pkg_version}\n"
        fi
    done

    RET="$?"
    debug
}

# loop through check list and add missing gems to install list
gem_check() {
    local pkg
    local pkg_version

    for pkg in "${gem_check_list[@]}"; do
        if gem list $pkg -i >/dev/null; then
            pkg_version=$(gem list "${pkg}" | grep "${pkg}" | cut -d " " -f 2 | cut -d "(" -f 2 | cut -d ")" -f 1)
            space_count="$(expr 20 - "${#pkg}")"
            pack_space_count="$(expr 20 - "${#pkg_version}")"
            real_space="$(expr ${space_count} + ${pack_space_count} + ${#pkg_version})"
            echo -en " ${GREEN_CHK}"
            printf " $pkg %${real_space}.${#pkg_version}s ${pkg_version}\n"
        else
            echo -e " ${YELLOW_BLACK} * $pkg [not installed] ${NONE_WHITE}"
            gem_install_list+=($pkg)
        fi
    done

    RET="$?"
    debug
}

# loop through check list and add missing npms to install list
npm_check() {
    local pkg
    local pkg_version

    for pkg in "${npm_check_list[@]}"; do
        if npm ls -gs | grep -q "$pkg"; then
            pkg_version=$(npm ls -gs | grep "${pkg}" | cut -d "@" -f 2)
            space_count="$(expr 20 - "${#pkg}")"
            pack_space_count="$(expr 20 - "${#pkg_version}")"
            real_space="$(expr ${space_count} + ${pack_space_count} + ${#pkg_version})"
            echo -en " ${GREEN_CHK}"
            printf " $pkg %${real_space}.${#pkg_version}s ${pkg_version}\n"
        else
            echo -e " ${YELLOW_BLACK} * $pkg [not installed] ${NONE_WHITE}"
            npm_install_list+=($pkg)
        fi
    done

    RET="$?"
    debug
}

# loop through check list and add missing pips to install list
pip_check() {
    local pkg
    local pkg_trim
    local pkg_version

    for pkg in "${pip_check_list[@]}"; do
        pkg_trim=$(trim_longest_right_pattern "$pkg" "[")
        if pip list | grep "$pkg_trim" >/dev/null 2>&1; then
            pkg_version=$(pip list | grep "${pkg_trim}" | cut -d " " -f 2 | tr -d "(" | tr -d ")")
            space_count="$(expr 20 - "${#pkg}")"
            pack_space_count="$(expr 20 - "${#pkg_version}")"
            real_space="$(expr ${space_count} + ${pack_space_count} + ${#pkg_version})"
            echo -en " ${GREEN_CHK}"
            printf " $pkg %${real_space}.${#pkg_version}s ${pkg_version}\n"
        else
            echo -e " ${YELLOW_BLACK} * $pkg_trim [not installed] ${NONE_WHITE}"
            pip_install_list+=($pkg)
        fi
    done

    RET="$?"
    debug
}

# --------------------------  INSTALL FROM PACKAGE MANAGERS

# loop through install list and install any packages that are in the list
# $1 -> to update sources or not
apt_install() {
    apt_check

    if [[ "${#apt_install_list[@]}" -eq 0 ]]; then
        notify "No packages to install"
    else
        # update all of the package references before installing anything
        if [ "${1}" -eq 0 ]; then
            pause "Press [Enter] to update Ubuntu sources" true
            sudo apt-get -y update
        fi

        # install packages in the list
        read -p "Press [Enter] to install apt packages..."
        sudo apt-get -y install ${apt_install_list[@]}

        # clean up apt caches
        sudo apt-get clean
    fi

    RET="$?"
    debug
}

# loop through install list and install any gems that are in the list
gem_install() {
    gem_check

    # make sure ruby is installed
    program_must_exist "ruby"
    program_must_exist "rubygems-integration"

    if [[ "${#gem_install_list[@]}" -eq 0 ]]; then
        notify "No gems to install"
    else
        # install required gems
        pause "Press [Enter] to install gems" true
        gem install ${gem_install_list[@]}
    fi

    RET="$?"
    debug
}

# loop through install list and install any npms that are in the list
npm_install() {
    npm_check

    # make sure npm is installed
    program_must_exist "npm"
    # symlink nodejs to path
    if [ ! -L /usr/bin/node ]; then
        sudo ln -s "$(which nodejs)" /usr/bin/node
    fi

    if [[ "${#npm_install_list[@]}" -eq 0 ]]; then
        notify "No npms to install"
    else
        # install required npms
        pause "Press [Enter] to install npms" true
        sudo npm install -g ${npm_install_list[@]}
    fi

    RET="$?"
    debug
}

# loop through install list and install any pips that are in the list
pip_install() {
    pip_check

    # make sure dependencies are installed
    program_must_exist "python-pip"
    program_must_exist "python-keyring"

    if [[ "${#pip_install_list[@]}" -eq 0 ]]; then
        notify "No pips to install"
    else
        # install required pips
        pause "Press [Enter] to install pips" true
        sudo -H pip install ${pip_install_list[@]}
    fi

    RET="$?"
    debug
}

# --------------------------  RBENV FOR LATEST RUBY

install_rbenv_ruby() {
    # rbenv
    set_sourced_config  "$HOME/.profile" \
                        "https://github.com/rbenv/rbenv.git" \
                        "$HOME/.rbenv/" \
                        '[[ ":$PATH:" =~ ":$HOME/.rbenv/bin:" ]] || PATH="$HOME/.rbenv/bin:$PATH"'

    # optional, to speed up rbenv
    [ -d "$HOME/.rbenv" ] && cd "$HOME/.rbenv" && src/configure && make -C src && cd - >/dev/null

    # add rbenv init - command to .profile
    set_source_cmd      "$HOME/.profile" \
                        '"eval "$(rbenv init -)"' \
                        '[[ ":$PATH:" =~ ":$HOME/.rbenv/shims:" ]] || eval "$(rbenv init -)"'

    # ruby-build
    set_sourced_config  "$HOME/.profile" \
                        "https://github.com/rbenv/ruby-build.git" \
                        "$HOME/.rbenv/plugins/ruby-build/" \
                        '[[ ":$PATH:" =~ ":$HOME/.rbenv/plugins/ruby-build/bin:" ]] || PATH="$HOME/.rbenv/plugins/ruby-build/bin:$PATH"'

    # tell rubygems not to install docs for each package locally
    set_source_cmd      "$HOME/.gemrc" \
                        'gem: --no-ri --no-rdoc' \
                        'gem: --no-ri --no-rdoc'

    source "$HOME/.profile"

    # check that rbenv is working
    type rbenv
    rbenv version

    # install ruby
    [ "$?" -eq 0 ] && rbenv install "$RUBY_V"
    [ "$?" -eq 0 ] && rbenv global "$RUBY_V"

    # check ruby and rubygem versions
    ruby -v
    gem env home

    RET="$?"
    debug
}

# --------------------------  64-BIT ARCHITECTURE

UPDATE=0
if [ "$(dpkg --print-foreign-architectures)" = "i386" ]; then
    pause "Press [Enter] to purge all i386 packages and remove the i386 architecture" true
    sudo apt-get purge ".*:i386" && sudo dpkg --remove-architecture i386 && sudo apt-get update && success "Success, goodbye i386!" && UPDATE=1
fi

# --------------------------  DEFAULT APT PACKAGES

DEFAULT_SERVER_LIST='ca-certificates gettext-base less man-db openssh-server python-software-properties software-properites-common vim-gtk wget'
DEFAULT_WORKSTATION_LIST='autojump deluge gnupg2 gufw lynx nautilus-open-terminal silversearcher-ag tmux x11vnc xclip vim-gtk vlc'
DEFAULT_DEV_LIST='build-essential cmake checkinstall cvs dconf-cli git-core lxc mercurial subversion'
RUBY_DEPENDENCIES_LIST='libffi-dev libreadline-dev libsqlite3-dev libssl-dev libxml2-dev libxslt1-dev libyaml-dev python-software-properties zlib1g-dev'

# --------------------------  PROMPT FOR PROGRAMS

if [ "$IS_SERVER" -eq 0 ]; then
    notify "Server packages to install (none to skip)"
    read -ep "   : " -i "$SERVER_APTS_LIST"         APTS1
else
    notify3 "The following default packages can be modified prior to installation."
    echo
    echo "WORKSTATION"
    echo "DEVELOPER"
    echo "RUBY DEPENDENCIES"
    echo "GEMs, NPMs, PIPs"
    echo
    notify "Workstation packages to install (delete all to skip)"
    read -ep "   : " -i "$DEFAULT_WORKSTATION_LIST" APTS1
    notify "Developer packages to install"
    read -ep "   : " -i "$DEFAULT_DEV_LIST"         APTS2
    notify "Ruby dependencies to install"
    read -ep "   : " -i "$RUBY_DEPENDENCIES_LIST"   APTS3
    notify "Packages to install with gem"
    read -ep "   : " -i 'bundler gist'              GEMS
    notify "Packages to install with npm"
    read -ep "   : " -i 'doctoc'                    NPMS
    notify "Packages to install with pip"
    read -ep "   : " -i 'jrnl[encrypted]'           PIPS
fi

# --------------------------  ARRAY ASSIGNMENTS

# add packages, gems, npms and pips to check list arrays
apt_check_list+=($APTS1)
apt_check_list+=($APTS2)
apt_check_list+=($APTS3)
gem_check_list+=($GEMS)
npm_check_list+=($NPMS)
pip_check_list+=($PIPS)

# --------------------------  INSTALL PROGRAMS

apt_install "$UPDATE"
confirm "Install ruby with rbenv and ruby-build?" true
[ "$?" -eq 0 ] && install_rbenv_ruby
gem_install
npm_install
pip_install
