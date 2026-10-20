
%module(package="eseo.loki", threads="1") native

%typemap(in) ssize_t {
    %#if PY_VERSION_HEX >= 0x03000000
        $1 = PyLong_AsSsize_t($input);
    %#else
        $1 = PyInt_AsSsize_t($input);
    %#endif
}

%{
#include "libloki.h"
%}

%include <stdint.i>
%include "libloki-ellipse.h"
%include "libloki-modem.i"
%include "libloki-env-sensors.i"
%include "libloki-system.i"
%include "libloki-fifo.i"
%include "libloki-packet.i"
%include "libloki-recorder.i"
%include "libloki-socket-server.i"
%include "libloki-consumer.i"
