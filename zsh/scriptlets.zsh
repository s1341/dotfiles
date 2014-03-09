function find_large_files {
  count=${1:=10}
  find . -type f -print0 | xargs -0 du | sort -n | tail -$count | cut -f2 | xargs -I{} du -sh {}
}
