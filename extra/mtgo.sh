#!/bin/bash

if [ ! -d "${HOME}/.wine/drive_c/windows/syswow64" ]; then
  echo
  echo
  echo "IMPORTANT: This image now uses Windows in 64bit mode (WoW64)"
  echo "You have to reset your settings: "
  echo "       ./run-mtgo --reset"
  echo
  exit 1
fi

trap "exit" INT

run() {
  echo "${@}"
  "${@}"
}

run wineboot

setup="/opt/mtgo/mtgo.exe"

export WINEDEBUG=-all
run wine ${setup}
started=0
s=6
while :; do #keep container running until mtgo is closed
  sleep $s
  winedbg --command "info proc" | grep MTGO.exe >/dev/null
  r=$?
  if [ $started -eq 0 ] && [ $r -eq 0 ]; then
    echo "====== MTGO.exe has started."
    started=1
  elif [ $started -eq 1 ] && [ $r -eq 1 ]; then
    echo "====== shutting down"
    run wineserver -kw
    exit
  fi
done
