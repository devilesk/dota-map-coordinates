import json
import matplotlib.path as mplPath
import numpy as np

true_sight = {
    'npc_dota_fort': 900,
    'npc_dota_tower': 700,
    'ent_dota_fountain': 1200
}

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
                pt['triggerName'] = trigger['name']
                pt['pullType'] = neutral_data[trigger['name']]['PullType']
                pt['neutralType'] = neutral_data[trigger['name']]['NeutralType']
                break
        
    meta = {}
    coorddata = {}
    for key in data:
        print (key)
        if key == 'trigger_multiple':
            coorddata[key] = []
            for obj in data[key]:
                entity = {
                    'points': [],
                    'name': obj['name']
                }
                for i in range(1, 5):
                    entity['points'].append(obj[str(i)])
                coorddata[key].append(entity)
        else:
            coorddata[key] = []
            for obj in data[key]:
                new_obj = {}
                coords = {}
                for k in obj:
                    if k == 'team' or k == 'name' or k == 'z':
                        continue
                    elif k != 'x' and k != 'y' and k != 'pullType' and k != 'neutralType' and k != 'triggerName':
                        if obj[k] == 0:
                            continue
                        elif k == 'bat':
                            obj[k] = round(obj[k], 2)
                        new_obj[k] = obj[k]
                    else:
                        coords[k] = obj[k]

                if key == 'npc_dota_tower' or key == 'npc_dota_barracks':
                    subkey = obj['name'].split('_')[2]
                    coords['subType'] = subkey
                    meta[key + '_' + subkey] = new_obj
                    if key == 'npc_dota_tower':
                        meta[key + '_' + subkey]['trueSight'] = true_sight[key]
                else:
                    meta[key] = new_obj
                    if key == 'npc_dota_fort' or key == 'ent_dota_fountain':
                        meta[key]['trueSight'] = true_sight[key]

                coorddata[key].append(coords)
    result = {
        'data': coorddata,
        'stats': meta
    }
    with open('mapdata.json', 'w') as g:
        g.write(json.dumps(result))
