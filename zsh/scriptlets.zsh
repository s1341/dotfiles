function find_large_files {
  count=${1:=10}
  find . -type f -print0 | xargs -0 du | sort -n | tail -$count | cut -f2 | xargs -I{} du -sh {}
}

function hardtouch {
  tail -n1 "$1" | grep 'TOUCHPATTERN' >/dev/null || echo //TOUCHPATTERN0 >> "$1"

  sed -i 's/TOUCHPATTERN[0-9]*/TOUCHPATTERN'$(date +%H%M%S)'/' "$1"
}

function unhardtouch {
  sed -i '/TOUCHPATTERN/d' "$1"
}
