#!/bin/bash
revParse=$(git rev-parse --abbrev-ref HEAD)

git show-branch -a \
| grep '\(\*\|^-.*\[\)' \
| grep -v "\['$revParse'\([\^]\|~\d\+\)\?\]" \
| head -n1 \
| sed 's/.*\[\([^\^~]*\).*\].*/\1/;'