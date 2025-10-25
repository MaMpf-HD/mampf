FROM ubuntu:24.04

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    git python3 python3-pip python3-dbus dbus-x11 x11-xserver-utils \
    libxcursor-dev libxrandr-dev libgtk-3-dev python3-cairo-dev \
    python-gi-dev liblz4-dev python3-xdg libpam-dev quilt xserver-xorg-dev \
    xutils-dev xserver-xorg-video-dummy xvfb keyboard-configuration \
    && pip install cython --upgrade --break-system-packages

# xpra
# https://pypi.org/project/xpra
# https://github.com/Xpra-org/xpra/blob/master/docs/Build/Debian.md#build-requirements
RUN git clone --depth=1 https://github.com/Xpra-org/xpra /tmp/xpra/ \
    && cd /tmp/xpra/ \
    && DEBIAN_FRONTEND=noninteractive yes | ./setup.py dev-env --minimal --x11 --with-openh264 \
    && DEBIAN_FRONTEND=noninteractive ./setup.py install --prefix=/usr --install-layout=deb \
    && cp fs/bin/* /bin/ \
    && rm -rf /tmp/xpra/

# xpra-html5
# https://github.com/Xpra-org/xpra-html5
RUN git clone --depth=1 https://github.com/Xpra-org/xpra-html5.git /tmp/xpra-html5/ \
    && cd /tmp/xpra-html5/ \
    && ./setup.py install \
    && rm -rf /tmp/xpra-html5/

ENTRYPOINT ["xpra", "start", ":79", \
    "--bind-tcp=0.0.0.0:8060", \
    "--auth=none", "--html=on", "--opengl=on", \
    "--pulseaudio=no", "--audio=no", \
    "--mdns=no", "--webcam=no", \
    "--daemon=no", "--exit-with-windows=no", \
    "--start=xhost +"]

# Cypress
# ignore garbage error: https://github.com/cypress-io/cypress/issues/30895
# https://github.com/cypress-io/cypress/issues/27217
# https://docs.github.com/en/codespaces/developing-in-a-codespace/forwarding-ports-in-your-codespace?tool=vscode
# https://spin.atomicobject.com/cypress-running-docker-container/
