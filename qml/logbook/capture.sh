#!/bin/sh
# Run by `wl-paste --watch` with the copy on stdin; prints `text <hex bytes>` or `image <file>` for the shell.
kind=$1
dir=$2

[ "${CLIPBOARD_STATE:-data}" = "data" ] || exit 0
# Password managers mark what they copy; leave that out of the history.
wl-paste --list-types 2>/dev/null | grep -qx 'x-kde-passwordManagerHint' && exit 0

if [ "$kind" = image ]; then
    mkdir -p "$dir"
    tmp=$(mktemp "$dir/new.XXXXXX") || exit 0
    cat > "$tmp"
    if [ ! -s "$tmp" ]; then
        rm -f "$tmp"
        exit 0
    fi
    # Named by content, so the same image is only kept once.
    file="$dir/$(sha256sum "$tmp" | cut -d' ' -f1).png"
    mv -f "$tmp" "$file"
    printf 'image %s\n' "$file"
else
    # Anything over 100 kB is skipped rather than kept in part.
    data=$(head -c 100001 | od -An -v -tx1 | tr -d ' \n')
    [ -n "$data" ] && [ "${#data}" -le 200000 ] && printf 'text %s\n' "$data"
fi
exit 0
