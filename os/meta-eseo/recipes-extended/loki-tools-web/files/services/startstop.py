
import os
import tempfile
import subprocess
from threading import Lock

lock = Lock()

def run_start(args, form, start_response):
    lock.acquire()
    subprocess.call(["sudo", "/etc/init.d/loki-record.sh",             "start"])
    subprocess.call(["sudo", "/etc/init.d/loki-env-sensors-record.sh", "start"])
    lock.release()

    start_response("200 Ok", [('Content-Type', 'text/html;charset=utf-8')])
    return [b"OK"]

def run_stop(args, form, start_response):
    lock.acquire()
    subprocess.call(["sudo", "/etc/init.d/loki-record.sh",             "stop"])
    subprocess.call(["sudo", "/etc/init.d/loki-env-sensors-record.sh", "stop"])
    lock.release()

    start_response("200 Ok", [('Content-Type', 'text/html;charset=utf-8')])
    return [b"OK"]
