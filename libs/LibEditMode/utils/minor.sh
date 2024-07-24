#!/bin/bash

LAST="$(awk -F= '/^local MINOR =/{print $2}' LibEditMode.lua | xargs)"
MINOR="$(((LAST + 1)))"

echo "old minor: $LAST"
echo "new minor: $MINOR"

echo
read -r -p $'\e[33mContinue? (y/N) \e[0m' -n 1
echo

if [[ ! "$REPLY" =~ ^[Yy]$ ]]; then
  exit
fi

echo
while read -r file; do
  if grep 'local MINOR = ' "$file" >/dev/null; then
    sed -Ei "s/^local MINOR = [0-9]+\$/local MINOR = ${MINOR}/" "$file"
    echo "updated $file"
  fi
done < <(find . -name '*.lua')
echo
