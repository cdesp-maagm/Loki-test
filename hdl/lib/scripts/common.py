
import json
from sys import stderr
from math import floor

def cfg_set_value(cfg, name, value):
    cfg["declarations"][name]["value"] = value

def cfg_get_value(cfg, name):
    if name in cfg["declarations"]:
        return cfg["declarations"][name]["value"]
    else:
        print("ERROR: No declaration found for name {}".format(name), file=stderr)
        return 0
        
def read_config(filename):
    with open(filename) as f:
        data = json.load(f)
        for k,v in data["declarations"].items():
            if "ref" in v:
                cfg_set_value(data, k, cfg_get_value(data, v["ref"]))
        return data

def dict_to_package(data):
    constant_tpl = "    constant {cste_name} : {cste_type} := {cste_value};"
    package_tpl = """
library ieee;
{use_clauses}
package {package_name} is
{declarations}
end package {package_name};
"""

    def format_value(decl):
        if decl["type"] == "string":
            return '"{}"'.format(decl["value"])
        else:
            return decl["value"]

    def format_use_clause(name):
        return "use {};".format(name)

    if "use" not in data:
        use_clauses = ""
    elif isinstance(data["use"], list):
        use_clauses = map(format_use_clause, data["use"])
    else:
        use_clauses = [format_use_clause(data["use"])]

    decls = [constant_tpl.format(cste_name=k, cste_type=v["type"], cste_value=format_value(v))
             for k,v in data["declarations"].items()]

    print(package_tpl.format(
        package_name=data["package_name"],
        use_clauses="\n".join(use_clauses),
        declarations="\n".join(decls)
    ))

def fixed(x, ilen, flen=0):
    rlen = ilen + flen
    # Round x to flen fractional bits.
    xr = int(round(x * (1 << flen))) & ((1 << rlen) - 1)
    # Identify the sign bit.
    if x < 0:
        s = '1'
    else:
        s = '0'
    # Convert it to binary and sign-extend it to the desired length.
    b = bin(xr)[2:]
    b = b.rjust(rlen, s)

    if len(b) > rlen:
        print("WARNING: Truncating the integer part of {} to {} bits".format(x, ilen), file=stderr)

    return b[-rlen:]

def slv(x, ilen, flen=0):
    return '"{}"'.format(fixed(x, ilen, flen))

def binround(x, n):
    s = 1 << n
    return round(x * s) / s

def binfloor(x, n):
    s = 1 << n
    return floor(x * s) / s

def sign(x):
    if x < 0:
        return -1
    if x > 0:
        return 1
    return 0
