
import asyncio
from eseo.loki.web import record_config, modem

async def send_cmd():
    try:
        reader, writer = await asyncio.open_unix_connection("/tmp/loki-record.sock")
        writer.write(b"disp-reset")
        await writer.drain()
        writer.close()
    except:
        pass

def run(args, form, start_response):
    loop = asyncio.new_event_loop()
    loop.run_until_complete(send_cmd())
    start_response("200 Ok", [('Content-Type', 'text/html;charset=utf-8')])
    return [b"OK"]
