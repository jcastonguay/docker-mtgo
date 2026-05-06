FROM panard/wine:11.2-wow64
CMD mtgo

RUN dpkg --add-architecture i386 && apt update && apt install -y \
  mesa-vulkan-drivers mesa-vulkan-drivers:i386 \
  libgl1-mesa-dri libgl1-mesa-dri:i386 \
  libvulkan1 libvulkan1:i386 \
  libgl1 libgl1:i386 libegl1 libegl1:i386 \
  libwayland-bin 
#libwayland-dev \
#libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev \
#gstreamer1.0-plugins-good gstreamer1.0-tools gstreamer1.0-pulseaudio pulseaudio-utils 

ENV WINE_USER wine
ENV WINE_UID 1000
ENV WINEPREFIX /home/wine/.wine
RUN useradd -u $WINE_UID -d /home/wine -m -s /bin/bash $WINE_USER
WORKDIR /home/wine

COPY extra/host-webbrowser /usr/local/bin/xdg-open

USER wine

RUN wineboot -i \
  && winetricks -q dotnet48 corefonts calibri tahoma consolas lucida win7 gdiplus renderer=gdi sound=pulse dxvk\
  && wineboot -s \
  && rm -rf /home/wine/.cache

ENV WINEDEBUG -all,err+all,warn+chain,warn+cryptnet

COPY extra/mtgo.sh /usr/local/bin/mtgo

ADD --chown=wine:wine https://mtgo.patch.daybreakgames.com/patch/mtg/live/client/setup.exe?v=8 /opt/mtgo/mtgo.exe

USER wine

# hack to allow mounting of user.reg and system.reg from host
# see https://github.com/pauleve/docker-mtgo/issues/6
RUN cd .wine && mkdir host \
  && mv user.reg system.reg host/ \
  && ln -s host/*.reg .
RUN mkdir -p \
  /home/wine/.wine/drive_c/users/wine/Documents\
  /home/wine/.wine/host/wine/Documents
