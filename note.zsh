export NOTE_DIR="$HOME/Documents/note"

__note_fzf() {
  fd --follow --base-directory "$NOTE_DIR" --exclude ".git" --type f . |
    fzf --reverse \
      --border top \
      --height 100% \
      --preview="bat --terminal-width $(($(tput cols) * 35 / 50 - 10)) --wrap=character -fp -l markdown $NOTE_DIR/{1}" \
      --preview-window=right:70% \
      "$@"
}

note() {
  if [[ $# -lt 1 ]]; then
    print -u 2 "Usage: note subcommands"
    return 1
  fi
  subcommand="$1"
	shift
  case $subcommand in
    list | ls)
      fd --follow --base-directory "$NOTE_DIR" --exclude ".git" --type f . |
        tree -C --fromfile
      ;;
    new | n)
      local relpath
      while [[ -z $relpath ]]; do
        print -n "File path: "
        read -r relpath
      done
      relpath="${(L)relpath}"
      [[ ! $relpath =~ .md$ ]] && relpath+=.md
      local abs_filepath=$NOTE_DIR/$relpath
      while [[ -e $abs_filepath ]]; do
        print -u 2 "File $relpath already exists."
        print -n "File path: "
        read -r relpath
				relpath="${(L)relpath}"
      	[[ ! $relpath =~ .md$ ]] && relpath+=.md
        abs_filepath=$NOTE_DIR/$relpath
      done
      mkdir -p "$(dirname "$abs_filepath")"
      print "# $relpath" >$abs_filepath
      ${EDITOR:-vim} $abs_filepath
      ;;
    edit | e)
      __note_fzf --bind "enter:become(${EDITOR:-vim} $NOTE_DIR/{1})"
      ;;
    remove | rm)
      __note_fzf --print0 -m | xargs -I filename -0 -o rm -i $NOTE_DIR/filename
      ;;
    view | v)
      __note_fzf --bind "enter:become(bat -l --style=header-filename markdown $NOTE_DIR/{1})"
      ;;
    preview | p)
      local filename=$(__note_fzf)
      local tmp_html=$(mktemp -u).html
      qlmarkdown_cli "$NOTE_DIR/$filename" -o $tmp_html >/dev/null
      open $tmp_html
      print -u 2 "You can see latest $filename refreshing browser"
      fswatch --event=Updated $NOTE_DIR/$filename |
        while read -r md_file; do
          qlmarkdown_cli "$NOTE_DIR/$filename" -o $tmp_html >/dev/null
        done
      rm $tmp_html
      ;;
    grep | rg)
      rg -inH "$@" $NOTE_DIR/
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
    {list,ls}':List notes'
    {new,n}':New note'
    {edit,e}':Edit note'
    {remove,rm}':Remove note(s)'
    {view,v}':View file'
    {preview,p}':Preview as markdown in broweser'
    {grep,rg}':Grep notes'
    zsh-completions':Print completion file for ZSH'
  )
  _describe -t subcommands 'subcommand' sub_commands
}
