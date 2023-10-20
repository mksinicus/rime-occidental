const ROOT_PATH = ('.' | path expand)
const SOURCE_PATH   = ('./src/' | path expand)
const SCHEMA_NAME = 'occidental'
const DICT_FILE = 'dict.tsv'
const LEADING_KEY   = '\'

alias open = open -r
alias save = save -f

export def main [] {
  build-dict
  build-readme
}

export def move-to-rimecfg [] {
  let rimedir = open "rimedir" | str trim
  cp -fv *.yaml $rimedir
}
export alias m = move-to-rimecfg

export def build-and-move [] {
  build-dict
  move-to-rimecfg
}
export alias bm = build-and-move

export def build-dict [] {
  cd $SOURCE_PATH
  let dest_file = [$SCHEMA_NAME dict yaml] | str join '.'
  let header_file = [$SCHEMA_NAME dict header] | str join '.'
  let header = open $header_file
               | lines | each {|l| ["#" $l] | str join " "}
               | str join "\n"
  let meta_file = [$SCHEMA_NAME dict meta yaml] | str join '.'
  let meta = open $meta_file
             | from yaml | to yaml | str trim # validates yaml by the way
             | ['---' $in '...'] | str join "\n"
  let dict = open $DICT_FILE
             | read-tsv
             | add-leading-key $LEADING_KEY
             | to-tsv
  cd $ROOT_PATH
  [$header $meta $dict] | str join "\n\n"
  | save $dest_file
}

export def build-readme [] {
  cd $SOURCE_PATH
  [
    (open README.main.md)
    (open $DICT_FILE | read-tsv | add-leading-key $LEADING_KEY
    | update value {|col| ['``` ' $col.value ' ```'] | str join}
    | to md -p)
  ] | str join "\n"
  | save ([$ROOT_PATH README.md] | path join)
}

export def read-tsv [] {
  $in | (from tsv
         --comment "#"
         --trim all
         --quote (char us)) # make `"` no more special
}

# wheeled because normal `to tsv` have no option for quotes and escapes
export def to-tsv []: table -> string {
  $in | reduce -f "" {
    |it acc|
    [$it.key $it.value] | str join "\t"
    | [$acc $in] | str join "\n"
  } | [$in "\n"] | str join # UNIX EOF
}

def add-leading-key [lkey: string] {
  $in | update value {|col| [$lkey $col.value] | str join}
}

