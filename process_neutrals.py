import json
import matplotlib.path as mplPath
import numpy as np

with open('data/mapdata.json', 'r') as f:
    neutrals = []
    data = json.loads(f.read())['data']
    for k in data['trigger_multiple']:
        neutrals.append(k['name'])
##        print k['name']

neutral_data = {}
with open('data/dota_pvp_prefab.vmap.txt', 'r') as f:
    dump_on_next_brace = False
    for line in f.readlines():
        if 'VolumeName' in line:
            VolumeName = line.strip('\n').split(" ")[-1].replace('"', '')
        if 'PullType' in line:
            PullType = line.strip('\n').split(" ")[-1].replace('"', '')
        if 'NeutralType' in line:
            NeutralType = line.strip('\n').split(" ")[-1].replace('"', '')
        if 'npc_dota_neutral_spawner' in line:
            dump_on_next_brace = True
        if '}' in line and dump_on_next_brace:
            dump_on_next_brace = False
##            print VolumeName, PullType, NeutralType
            neutral_data[VolumeName] = {
                'PullType': PullType,
                'NeutralType': NeutralType
            }

##print neutral_data

for pt in data['npc_dota_neutral_spawner']:
    point = [pt['x'], pt['y']]
    for trigger in data['trigger_multiple']:
        points = []
        for i in range(1, 5):
            points.append([trigger[str(i)]['x'], trigger[str(i)]['y']])
        bbPath = mplPath.Path(np.array(points))
        if bbPath.contains_point(point):
            pt['name'] = trigger['name']
            pt['PullType'] = neutral_data[trigger['name']]['PullType']
            pt['NeutralType'] = neutral_data[trigger['name']]['NeutralType']
            break
