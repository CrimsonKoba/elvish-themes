# DO NOT EDIT THIS FILE DIRECTLY
# This is a file generated from a literate programing source file located at
# https://github.com/zzamboni/elvish-themes/blob/master/chain.org.
# You should make any changes there and regenerate it from Emacs org-mode using C-c C-v t

use re

use github.com/muesli/elvish-libs/git

prompt-segments = [ su dir git-branch git-combined arrow ]
rprompt-segments = [ ]

glyph = [
  &git-branch=    "⎇"
  &git-dirty=     "✎ "
  &git-ahead=     "⬆"
  &git-behind=    "⬇"
  &git-staged=    "✔"
  &git-untracked= "+"
  &git-deleted=   "-"
  &su=            "⚡"
  &chain=         "─"
  &arrow=         ">"
]

segment-style = [
  &chain=         default
  &su=            yellow
  &dir=           cyan
  &git-branch=    blue
  &git-dirty=     yellow
  &git-ahead=     "38;5;52"
  &git-behind=    "38;5;52"
  &git-staged=    "38;5;22"
  &git-untracked= "38;5;52"
  &git-deleted=   "38;5;52"
  &timestamp=     gray
  &arrow=         green
]

prompt-pwd-dir-length = 1

timestamp-format = "%R"

root-id = 0

bold-prompt = $false

fn -colorized [what color]{
  if (!=s $color default) {
    if $bold-prompt {
      color = $color";bold"
    }
    edit:styled $what $color
  } else {
    put $what
  }
}

fn -colorized-glyph [segment-name]{
  -colorized $glyph[$segment-name] $segment-style[$segment-name]
}

fn prompt-segment [style @texts]{
  text = "["(joins ' ' $texts)"]"
  -colorized $text $style
}

last-status = [&]

fn -parse-git {
  last-status = (git:status)
}

fn segment-git-branch {
  branch = $last-status[branch-name]
  if (not-eq $branch "") {
    if (eq $branch '(detached)') {
      branch = $last-status[branch-oid][0:7]
    }
    prompt-segment $segment-style[git-branch] $glyph[git-branch] $branch
  }
}

fn segment-git-dirty {
  if (> $last-status[local-modified] 0) {
    prompt-segment $segment-style[git-dirty] $glyph[git-dirty]
  }
}

fn segment-git-ahead {
  if (> $last-status[rev-ahead] 0) {
    prompt-segment $segment-style[git-ahead] $glyph[git-ahead]
  }
}

fn segment-git-behind {
  if (> $last-status[rev-behind] 0) {
    prompt-segment $segment-style[git-behind] $glyph[git-behind]
  }
}

fn segment-git-staged {
  total-staged = (+ $last-status[staged-modified-count staged-deleted-count staged-added-count renamed-count copied-count])
  if (> $total-staged 0) {
    prompt-segment $segment-style[git-staged] $glyph[git-staged]
  }
}

fn segment-git-untracked {
  if (> $last-status[untracked-count] 0) {
    prompt-segment $segment-style[git-untracked] $glyph[git-untracked]
  }
}

fn segment-git-deleted {
  if (> $last-status[local-deleted-count] 0) {
    prompt-segment $segment-style[git-deleted] $glyph[git-deleted]
  }
}

fn segment-git-combined {
  indicators = []
  total-staged = (+ $last-status[staged-modified-count staged-deleted-count staged-added-count renamed-count copied-count])

  if (> $last-status[untracked-count] 0) {
    indicators = [ $@indicators (-colorized-glyph git-untracked) ]
  }
  if (> $last-status[local-deleted-count] 0) {
    indicators = [ $@indicators (-colorized-glyph git-deleted) ]
  }
  if (> $last-status[local-modified-count] 0) {
    indicators = [ $@indicators (-colorized-glyph git-dirty) ]
  }
  if (> $total-staged 0) {
    indicators = [ $@indicators (-colorized-glyph git-staged) ]
  }
  if (> $last-status[rev-ahead] 0) {
    indicators = [ $@indicators (-colorized-glyph git-ahead) ]
  }
  if (> $last-status[rev-behind] 0) {
    indicators = [ $@indicators (-colorized-glyph git-behind) ]
  }
  if (> (count $indicators) 0) {
    put '[' $@indicators ']'
  }
}

fn -prompt-pwd {
  tmp = (tilde-abbr $pwd)
  if (== $prompt-pwd-dir-length 0) {
    put $tmp
  } else {
    re:replace '(\.?[^/]{'$prompt-pwd-dir-length'})[^/]*/' '$1/' $tmp
  }
}

fn segment-dir {
  prompt-segment $segment-style[dir] (-prompt-pwd)
}

fn segment-su {
  uid = (id -u)
  if (eq $uid $root-id) {
    prompt-segment $segment-style[su] $glyph[su]
  }
}

fn segment-timestamp {
  prompt-segment $segment-style[timestamp] (date +$timestamp-format)
}

fn segment-arrow {
  -colorized $glyph[arrow]" " $segment-style[arrow]
}

# List of built-in segments
segment = [
  &su=            $segment-su~
  &dir=           $segment-dir~
  &git-branch=    $segment-git-branch~
  &git-dirty=     $segment-git-dirty~
  &git-ahead=     $segment-git-ahead~
  &git-behind=    $segment-git-behind~
  &git-staged=    $segment-git-staged~
  &git-untracked= $segment-git-untracked~
  &git-deleted=   $segment-git-deleted~
  &git-combined=  $segment-git-combined~
  &arrow=         $segment-arrow~
  &timestamp=     $segment-timestamp~
]

fn -interpret-segment [seg]{
  k = (kind-of $seg)
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
  } elif (eq $k 'styled') {
    # If it's an edit:styled, return it as-is
    put $seg
  }
}

fn -build-chain [segments]{
  first = $true
  output = ""
  -parse-git
  for seg $segments {
    time = (-time { output = [(-interpret-segment $seg)] })
    if (> (count $output) 0) {
      if (not $first) {
        -colorized $glyph[chain] $segment-style[chain]
      }
      put $@output
      first = $false
    }
  }
}

fn prompt {
  put (-build-chain $prompt-segments)
}

fn rprompt {
  put (-build-chain $rprompt-segments)
}

fn init {
  edit:prompt = $prompt~
  edit:rprompt = $rprompt~
}

init
