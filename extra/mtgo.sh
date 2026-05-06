#!/bin/bash
do_winecfg=false
do_sound=false
while [ -n "${1:-}" ]; do
  case "${1:-}" in
  --winecfg) do_winecfg=true ;;
  --sound) do_sound=true ;;
  esac
  shift
done

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

commontricks="gdiplus=builtin"

if $do_sound; then
  gst-inspect-1.0 # seems to help avoiding wine crash when loading gstreamer
  run winetricks ${commontricks} sound=pulse winegstreamer=builtin wmp=builtin
else
  run winetricks ${commontricks} sound=alsa winegstreamer=disabled wmp=disabled
fi
$do_winecfg && (
  run winecfg
  run wineserver -kw
  sleep 1
)

run wineboot

#cd ~/.wine/drive_c/
#
#workaround_dotnet() {
#  D="/home/wine/.wine/drive_c/windows/Microsoft.NET/Framework/v4.0.30319"
#  F="mscoreei.dll"
#  if [ ! -f "${D}/${F}" ]; then
#    echo "THERE IS AN ISSUE WITH DOTNET!"
#    echo "Trying to fix it..., wait a moment"
#    run wineserver -k
#    cd ${D}
#    run curl -fOL https://github.com/pauleve/docker-mtgo/raw/master/extra/mscoreei.dll
#    return 1
#  fi
#}
#workaround_dotnet

setup="/opt/mtgo/mtgo.exe"

export WINEDLLOVERRIDES="d3d11,dxgi=n"
export WINEDEBUG=-all
run wine ${setup}
started=0
s=6
while :; do
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
