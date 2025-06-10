#!/usr/bin/env bash

DEFAULT_BINARY=$(which tmux-copyrat)

#
# Top-level options
#

setup_option () {
    opt_name=$1
    default_value=$2
    current_value=$(tmux show-option -gqv @copyrat-${opt_name})
    value=${current_value:-${default_value}}
    tmux set-option -g @copyrat-${opt_name} ${value}
}

# Allows manual configuration of path to tmux-copyrat binary
setup_option "binary" "$DEFAULT_BINARY"

# Sets the window name which copyrat should use when running, providing a
# default value in case @copyrat-window-name was not defined.
setup_option "window-name" "[copyrat]"

# Get that window name as a local variable for use in pattern bindings below.
window_name=$(tmux show-option -gqv @copyrat-window-name)

# Sets the keytable for all bindings, providing a default if @copyrat-keytable
# was not defined. Keytables open a new shortcut space: if 't' is the switcher
# (see below), prefix + t + <your-shortcut>
setup_option "keytable" "cpyrt"

# Sets the key to access the keytable: prefix + <key> + <your-shortcut>
# providing a default if @copyrat-keyswitch is not defined.
setup_option "keyswitch" "t"

keyswitch=$(tmux show-option -gv @copyrat-keyswitch)
keytable=$(tmux show-option -gv @copyrat-keytable)
tmux bind-key ${keyswitch} switch-client -T ${keytable}


#
# Pattern bindings
#

if [[ "$OSTYPE" == darwin* ]]; then
  setup_option "clipboard-exe" "pbcopy"
else
  if [[ "$XDG_SESSION_TYPE" == wayland ]]; then
    setup_option "clipboard-exe" "wl-copy"
  else
    setup_option "clipboard-exe" "xclip -selection clipboard"
  fi
fi
clipboard_exe=$(tmux show-option -gv @copyrat-clipboard-exe)
binary=$(tmux show-option -gv @copyrat-binary)

setup_pattern_binding () {
    key=$1
    pattern_arg="$2"
    tmux bind-key -T ${keytable} ${key} new-window -d -n "${window_name}" "${binary} run --window-name \"${window_name}\" --clipboard-exe \"${clipboard_exe}\" --reverse --unique-hint ${pattern_arg}"
}

# prefix + t + a searches for command-line arguments
setup_pattern_binding "a" "--pattern-name command-line-args"
# prefix + t + c searches for hex colors #aa00f5
setup_pattern_binding "c" "--pattern-name hexcolor"
# prefix + t + d searches for dates or datetimes
setup_pattern_binding "d" "--pattern-name datetime"
# prefix + t + D searches for docker shas
setup_pattern_binding "D" "--pattern-name docker"
# prefix + t + e searches for email addresses (see https://www.regular-expressions.info/email.html)
setup_pattern_binding "e" "--pattern-name email"
# prefix + t + G searches for any string of 4+ digits
setup_pattern_binding "G" "--pattern-name digits"
# prefix + t + h searches for SHA1/2 short or long hashes
setup_pattern_binding "h" "--pattern-name sha"
# prefix + t + m searches for Markdown URLs [...](matched.url)
setup_pattern_binding "m" "--pattern-name markdown-url"
# prefix + t + p searches for absolute & relative paths
setup_pattern_binding "p" "--pattern-name path"
# prefix + t + P searches for hex numbers: 0xbedead
setup_pattern_binding "P" "--pattern-name pointer-address"
# prefix + t + q searches for strings inside single|double|backticks
setup_pattern_binding "q" "-x quoted-single -x quoted-double -x quoted-backtick"
# prefix + t + u searches for URLs
setup_pattern_binding "u" "--pattern-name url"
# prefix + t + U searches for UUIDs
setup_pattern_binding "U" "--pattern-name uuid"
# prefix + t + v searches for version numbers
setup_pattern_binding "v" "--pattern-name version"
# prefix + t + 4 searches for IPV4
setup_pattern_binding "4" "--pattern-name ipv4"
# prefix + t + 6 searches for IPV6
setup_pattern_binding "6" "--pattern-name ipv6"
# prefix + t + Space searches for all known patterns (noisy and potentially slower)
setup_pattern_binding "space" "--all-patterns"

# prefix + t + / prompts for a pattern and search for it
tmux bind-key -T ${keytable} "/" command-prompt -p "search:" "new-window -d -n '${window_name}' \"${binary} run --window-name \\\"${window_name}\\\" --reverse --unique-hint --clipboard-exe \\\"${clipboard_exe}\\\" --custom-patterns \\\"%%\\\"\""
