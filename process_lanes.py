import json
import matplotlib.path as mplPath
import numpy as np

#targetname goes to target

lane_data = {}
with open('data/dota_pvp_prefab.vmap.txt', 'r') as f:
    dump_on_next_brace = False
    for line in f.readlines():
        if '"origin"' in line:
            origin = [x.replace('"', '') for x in line.strip('\n').split(" ")[-3:]]
        if '"classname"' in line:
            classname = line.strip('\n').split(" ")[-1].replace('"', '')
        if '"targetname"' in line:
            targetname = line.strip('\n').split(" ")[-1].replace('"', '')
        if '"target"' in line:
            target = line.strip('\n').split(" ")[-1].replace('"', '')
        if '"path_corner"' in line:
            dump_on_next_brace = True
        if '}' in line and dump_on_next_brace:
            dump_on_next_brace = False
            print classname, target, origin, targetname
            lane_data[targetname] = {
                'target': target,
                'origin': origin
            }
print lane_data

