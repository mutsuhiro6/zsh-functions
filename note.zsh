export NOTE_DIR="$HOME/Documents/note"

__note_fzf() {
  fd --follow --base-directory "$NOTE_DIR" --exclude ".git" . |
    fzf --reverse \
      --border top \
      --height 100% \
      --preview="bat --terminal-width $(($(tput cols) * 35 / 50 - 10)) --wrap=character -fp -l markdown $NOTE_DIR/{1}" \
      --preview-window=right:70% \
      "$@"
}

note() {
  if [[ $# -lt 1 ]]; then
    print -u "Usage: note subcommands"
    return 1
  fi
  subcommand="$1"
  case "$1" in
    list | ls)
      __note_fzf -m
      ;;
    new | n)
      local title
      while [[ -z $title ]]; do
        print -n "Title: "
        read -r title
      done
      local suffix=$(LC_ALL=C tr -dc a-f0-9 </dev/urandom | head -c 7).md
      local filename=$(tr '[:upper:]' '[:lower:]' <<<$(tr ' ' '_' <<<$title))
      local abs_filepath=$NOTE_DIR/${filename}_$suffix
      while [ -e "$abs_filepath" ]; do
        suffix=$(LC_ALL=C tr -dc a-f0-9 </dev/urandom | head -c 7).md
        abs_filepath=$NOTE_DIR/${filename}_$suffix
      done
      print "# $title" >$abs_filepath
      ${EDITOR:-vim} $abs_filepath
      ;;
    edit | e)
      __note_fzf --bind "enter:become(${EDITOR:-vim} $NOTE_DIR/{1})"
      ;;
    remove | rm)
      __note_fzf --print0 -m | xargs -I filename -0 -o rm -i $NOTE_DIR/filename
      ;;
    view | v)
      __note_fzf --bind "enter:become(bat --plain --language=markdown $NOTE_DIR/{1})"
      ;;
    grep | rg)
      rg -inH "$@" $NOTE_DIR/
      ;;
    browse)
      # TODO: Use local web server
      local DEFAULT_BROWSER="Google Chrome"
      local index=$(mktemp).md
      printf "# Note\n\n" >$index
      fd --absolute-path --follow --base-directory "$NOTE_DIR" --exclude ".git" . |
        while read -r abs_filepath; do
          title=$(rg -N -m 1 '^# ' $abs_filepath | sed 's/^# //')
          printf "- [%s](file:%s)\n" $title $abs_filepath >>$index
        done
      open -a "$DEFAULT_BROWSER" $index
      ;;
    zsh-completions)
      print "#compdef note"
      print '__note_zsh_completions "$@"'
      ;;
    *)
      print -u 2 "No such command: $1"
      return 1
      ;;
  esac
}

__note_zsh_completions() {
  local line state
  local ret=1
  _arguments \
    '1: :__note_zsh_completions_subcommands' && ret=0
  return ret
}

__note_zsh_completions_subcommands() {
  local -a sub_commands=(
    {list,ls,l}':List notes'
    {new,n}':New note'
    {edit,e}':Edit note'
    {remove,rm}':Remove note(s)'
    {view,v}':View file'
    {grep,rg}':Grep notes'
    browse':(Beta) Browse notes with browser'
    zsh-completions':Print completion file for ZSH'
  )
  _describe -t subcommands 'subcommand' sub_commands
}
