# DO NOT EDIT THIS FILE DIRECTLY
# This is a file generated from a literate programing source file located at
# https://github.com/zzamboni/elvish-themes/blob/master/chain.org.
# You should make any changes there and regenerate it from Emacs org-mode using C-c C-v t

var prompt-segments-defaults = [ su dir git-branch git-combined arrow ]
var rprompt-segments-defaults = [ ]

  use re
  use str
  use path

  use github.com/CrimsonKoba/elvish-gitstatus/gitstatus
  use github.com/CrimsonKoba/elvish-modules/spinners

  var prompt-segments = $prompt-segments-defaults
  var rprompt-segments = $rprompt-segments-defaults

  var default-glyph = [
    &git-branch=    "⎇"
    &git-dirty=     "●"
    &git-ahead=     "⬆"
    &git-behind=    "⬇"
    &git-staged=    "✔"
    &git-untracked= "+"
    &git-deleted=   "-"
    &su=            "⚡"
    &chain=         "─"
    &session=       "▪"
    &arrow=         ">"
  ]

  var default-segment-style = [
    &git-branch=    [ blue         ]
    &git-dirty=     [ yellow       ]
    &git-ahead=     [ red          ]
    &git-behind=    [ red          ]
    &git-staged=    [ green        ]
    &git-untracked= [ red          ]
    &git-deleted=   [ red          ]
    &git-combined=  [ default      ]
    &git-timestamp= [ cyan         ]
    &git-repo=      [ blue         ]
    &su=            [ yellow       ]
    &chain=         [ default      ]
    &arrow=         [ green        ]
    &dir=           [ cyan         ]
    &session=       [ session      ]
    &timestamp=     [ bright-black ]
  ]

  var glyph = [&]
  var segment-style = [&]

  var prompt-pwd-dir-length = 1

  var timestamp-format = "%R"

  var root-id = 0

  var bold-prompt = $false

  var show-last-chain = $true

  var space-after-arrow = $true

  var git-get-timestamp = { git log -1 --date=short --pretty=format:%cd }

  var prompt-segment-delimiters = "[]"
  # prompt-segment-delimiters = [ "<<" ">>" ]

  fn -session-color {
    var valid-colors = [ red green yellow blue magenta cyan white bright-black bright-red bright-green bright-yellow bright-blue bright-magenta bright-cyan bright-white ]
    put $valid-colors[(% $pid (count $valid-colors))]
  }

  fn -colorized {|what @color|
    if (and (not-eq $color []) (eq (kind-of $color[0]) list)) {
      set color = [(all $color[0])]
    }
    if (and (not-eq $color [default]) (not-eq $color [])) {
      if (eq $color [session]) {
        set color = [(-session-color)]
      }
      if $bold-prompt {
        set color = [ $@color bold ]
      }
      styled $what $@color
    } else {
      put $what
    }
  }

  fn -glyph {|segment-name|
    if (has-key $glyph $segment-name) {
      put $glyph[$segment-name]
    } else {
      put $default-glyph[$segment-name]
    }
  }

  fn -segment-style {|segment-name|
    if (has-key $segment-style $segment-name) {
      put $segment-style[$segment-name]
    } else {
      put $default-segment-style[$segment-name]
    }
  }

  fn -colorized-glyph {|segment-name @extra-text|
    -colorized (-glyph $segment-name)(str:join "" $extra-text) (-segment-style $segment-name)
  }

  fn prompt-segment {|segment-or-style @texts|
    var style = $segment-or-style
    if (or (has-key $default-segment-style $segment-or-style) (has-key $segment-style $segment-or-style)) {
      set style = (-segment-style $segment-or-style)
    }
    if (or (has-key $default-glyph $segment-or-style) (has-key $glyph $segment-or-style)) {
      set texts = [ (-glyph $segment-or-style) $@texts ]
    }
    var text = $prompt-segment-delimiters[0](str:join ' ' $texts)$prompt-segment-delimiters[1]
    -colorized $text $style
  }

  var segment = [&]

  var last-status = [&]

  fn -parse-git {|&with-timestamp=$false|
    set last-status = (gitstatus:query $pwd)
    if $with-timestamp {
      set last-status[timestamp] = ($git-get-timestamp)
    }
  }

  set segment[git-branch] = {
    var branch = $last-status[local-branch]
    if (not-eq $branch $nil) {
      if (eq $branch '') {
        set branch = $last-status[commit][0..7]
      }
      prompt-segment git-branch $branch
    }
  }

  set segment[git-timestamp] = {
    var ts = $nil
    if (has-key $last-status timestamp) {
      set ts = $last-status[timestamp]
    } else {
      set ts = ($git-get-timestamp)
    }
    prompt-segment git-timestamp $ts
  }

  fn -show-git-indicator {|segment|
    var status-name = [
      &git-dirty=  unstaged        &git-staged=    staged
      &git-ahead=  commits-ahead   &git-untracked= untracked
      &git-behind= commits-behind  &git-deleted=   unstaged
    ]
    var value = $last-status[$status-name[$segment]]
    # The indicator must show if the element is >0 or a non-empty list
    if (eq (kind-of $value) list) {
      not-eq $value []
    } else {
      and (not-eq $value $nil) (> $value 0)
    }
  }

  fn -git-prompt-segment {|segment|
    if (-show-git-indicator $segment) {
      prompt-segment $segment
    }
  }

  #-git-indicator-segments = [untracked deleted dirty staged ahead behind]
  var -git-indicator-segments = [untracked dirty staged ahead behind]

  each {|ind|
    set segment[git-$ind] = { -git-prompt-segment git-$ind }
  } $-git-indicator-segments

  set segment[git-combined] = {
    var indicators = [(each {|ind|
          if (-show-git-indicator git-$ind) { -colorized-glyph git-$ind }
    } $-git-indicator-segments)]
    if (> (count $indicators) 0) {
      var color = (-segment-style git-combined)
      put (-colorized $prompt-segment-delimiters[0] $color) $@indicators (-colorized $prompt-segment-delimiters[1] $color)
    }
  }

  fn -prompt-pwd {
    var tmp = (tilde-abbr $pwd)
    if (== $prompt-pwd-dir-length 0) {
      put $tmp
    } else {
      re:replace '(\.?[^/]{'$prompt-pwd-dir-length'})[^/]*/' '$1/' $tmp
    }
  }

  set segment[dir] = {
    prompt-segment dir (-prompt-pwd)
  }

  var uid = (id -u)
  set segment[su] = {
    if (eq $uid $root-id) {
      prompt-segment su
    }
  }

  set segment[timestamp] = {
    prompt-segment timestamp (date +$timestamp-format)
  }

  set segment[session] = {
    prompt-segment session
  }

  set segment[arrow] = {
    var end-text = ''
    if $space-after-arrow { set end-text = ' ' }
    -colorized-glyph arrow $end-text
  }

  fn -interpret-segment {|seg|
    var k = (kind-of $seg)
    if (eq $k 'fn') {
      # If it's a lambda, run it
      $seg
    } elif (eq $k 'string') {
      if (has-key $segment $seg) {
        # If it's the name of a built-in segment, run its function
        $segment[$seg]
      } else {
        # If it's any other string, return it as-is
        put $seg
      }
    } elif (or (eq $k 'styled') (eq $k 'styled-text')) {
      # If it's a styled object, return it as-is
      put $seg
    } else {
      fail "Invalid segment of type "(kind-of $seg)": "(to-string $seg)". Must be fn, string or styled."
    }
  }

  fn -build-chain {|segments|
    if (eq $segments []) {
      return
    }
    for seg $segments {
      if (str:has-prefix (to-string $seg) "git-") {
        -parse-git
        break
      }
    }
    var first = $true
    var output = ""
    for seg $segments {
      set output = [(-interpret-segment $seg)]
      if (> (count $output) 0) {
        if (not $first) {
          if (or $show-last-chain (not-eq $seg $segments[-1])) {
            -colorized-glyph chain
          }
        }
        put $@output
        set first = $false
      }
    }
  }

  fn prompt {
    if (not-eq $prompt-segments []) {
      -build-chain $prompt-segments
    }
  }

  fn rprompt {
    if (not-eq $rprompt-segments []) {
      -build-chain $rprompt-segments
    }
  }

  fn init {
    set edit:prompt = $prompt~
    set edit:rprompt = $rprompt~
  }

    var find-all-user-repos = {
      fd -H -I -t d '^.git$' ~ | each $path:dir~
    }

var summary-repos-file = $E:HOME/.local/share/elvish/package-data/elvish-themes/chain-summary-repos.json

  var summary-repos = []

  fn -write-summary-repos {
    mkdir -p (path:dir $summary-repos-file)
    to-json [$summary-repos] > $summary-repos-file
  }

  fn -read-summary-repos {
    try {
      set summary-repos = (from-json < $summary-repos-file)
    } catch {
      set summary-repos = []
    }
  }

  fn summary-data {|repos|
    each {|r|
      try {
        cd $r
        -parse-git &with-timestame
        var status = [($segment[git-combined])]
        put [
          &repo= (tilde-abbr $r)
          &status= $status
          &ts= $last-status[timestamp]
          &timestamp= ($segment[git-timestamp])
          &branch= ($segment[git-branch])
        ]
      } catch e {
        put [
          &repo= (tilde-abbr $r)
          &status= [(styled '['(to-string $e)']' red)]
          &ts= ""
          &timestamp= ""
          &branch= ""
        ]
      }
    } $repos
  }

  fn summary-status {|@repos &all=$false &only-dirty=$false|
    var prev = $pwd

    # Determine how to sort the output. This only happens in newer
    # versions of Elvish (where the order function exists)
    use builtin
    var order-cmd~ = $all~
    if (has-key $builtin: order~) {
      set order-cmd~ = { order &less-than={|a b| <s $a[ts] $b[ts] } &reverse }
    }

    # Read repo list from disk, cache in $chain:summary-repos
    -read-summary-repos

    # Determine the list of repos to display:
    # 1) If the &all option is given, find them
    if $all {
      spinners:run &title="Finding all git repos" &style=blue {
        set repos = [($find-all-user-repos)]
      }
    }
    # 2) If repos is not given nor defined through &all, use $chain:summary-repos
    if (eq $repos []) {
      set repos = $summary-repos
    }
    # 3) If repos is specified, just use it

    # Produce the output
    spinners:run &title="Gathering repo data" &style=blue { summary-data $repos } | order-cmd | each {|r|
      var status-display = $r[status]
      if (or (not $only-dirty) (not-eq $status-display [])) {
        if (eq $status-display []) {
          set status-display = [(-colorized "[" session) (styled OK green) (-colorized "]" session)]
        }
        var @status = $r[timestamp] ' ' (all $status-display) ' ' $r[branch]
        echo &sep="" $@status ' ' (-colorized $r[repo] (-segment-style git-repo))
      }
    }
    cd $prev
  }

  fn add-summary-repo {|@dirs|
    if (eq $dirs []) {
      set dirs = [ $pwd ]
    }
    -read-summary-repos
    each {|d|
      if (has-value $summary-repos $d) {
        echo (styled "Repo "$d" is already in the list" yellow)
      } else {
        set summary-repos = [ $@summary-repos $d ]
        echo (styled "Repo "$d" added to the list" green)
      }
    } $dirs
    -write-summary-repos
  }

  fn remove-summary-repo {|@dirs|
    if (eq $dirs []) {
      set dirs = [ $pwd ]
    }
    -read-summary-repos
    var @new-repos = (each {|d|
        if (not (has-value $dirs $d)) { put $d }
    } $summary-repos)
    each {|d|
      if (has-value $summary-repos $d) {
        echo (styled "Repo "$d" removed from the list." green)
      } else {
        echo (styled "Repo "$d" was not on the list" yellow)
      }
    } $dirs

    set summary-repos = $new-repos
    -write-summary-repos
  }
