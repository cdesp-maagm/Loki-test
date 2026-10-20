
import json
import os
from eseo.loki.web import record_config

def file_entry(f):
    st = f.stat()
    return {
        "name": f.name,
        "size": st.st_size
    }

def get_file_list():
    # TODO Support filtering (name pattern, date)
    # TODO Support sorting (name, date, size)
    # TODO Support max number of entries
    try:
        file_list = [file_entry(f) for f in os.scandir(record_config["path"]) if f.is_file]
        err = False
    except:
        file_list = []
        err = True
    return json.dumps({
        "path": record_config["path"],
        "filename": record_config["filename"],
        "error": err,
        "files": file_list
    })

def run_list(args, form, start_response):
    start_response("200 Ok", [('Content-Type', 'application/json;charset=utf-8')])
    return [get_file_list().encode()]

def run_download(args, form, start_response):
    start_response("200 Ok", [('Content-Type', 'application/octet-stream')])

    with open(args["path"][-1], 'rb') as f:
        data = f.read()

    return [data]


