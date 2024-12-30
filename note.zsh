export NOTE_DIR="$HOME/Documents/note"

__note_fzf() {
  fd --follow --base-directory "$NOTE_DIR" --exclude ".git" . |
    fzf --reverse \
      --border top \
      --height 40% \
      --preview="bat --plain --language=markdown $NOTE_DIR/{1}" \
      --preview-window=right:50% \
      --inline-info \
      "$@"
}

note() {
  subcommand="$1"
  local DEFAULT_BROWSER="Google Chrome"
  case "$1" in
    list | ls | l)
      __note_fzf -m
      ;;
    new | n)
      local title
      print -n "Title: "
      read -r title
      local suffix=$(LC_ALL=C tr -dc a-f0-9 </dev/urandom | head -c 7).md
      local filename=$(tr '[:upper:]' '[:lower:]' <<<$(tr ' ' '_' <<<$title))
      local abs_filepath=$NOTE_DIR/${filename}_$suffix
      while [ -e "$abs_filepath" ]; do
        suffix=$(LC_ALL=C tr -dc a-f0-9 </dev/urandom | head -c 7).md
        abs_filepath=$NOTE_DIR/${filename}_$suffix
      done
      print "# $title" >$filename
      ${EDITOR:-vim} $filename
      ;;
    edit | e)
      __note_fzf --bind "enter:become(${EDITOR:-vim} $NOTE_DIR/{1})"
      ;;
    remove | rm)
      __note_fzf --print0 -m | xargs -I filename -0 -o rm -t -i $NOTE_DIR/filename
      ;;
    view | v)
      if (command -v bat); then
        __note_fzf --bind "enter:become(bat --plain --language=markdown $NOTE_DIR/{1})"
      else
        __note_fzf --bind "enter:become(less $NOTE_DIR/{1})"
      fi
      ;;
    open | o)
      __note_fzf --print0 -m | xargs -I filename -0 -o open -a $DEFAULT_BROWSER $NOTE_DIR/filename
      ;;
    grep | rg)
      if (command rg); then
        rg -inH "$@" $NOTE_DIR/
      else
        grep -inH "$@" $NOTE_DIR/
      fi
      ;;
    browse)
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
    {view,v}':View source'
    {open,o}':Open note with browser'
    {grep,rg}':Grep notes'
    browse':(Beta) Browse notes with browser'
    zsh-completions':Print completion file for ZSH'
  )
  _describe -t subcommands 'subcommand' sub_commands
}
