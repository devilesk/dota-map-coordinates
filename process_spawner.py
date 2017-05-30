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
##            print classname, target, origin, targetname
            lane_data[targetname] = {
                'target': target,
                'origin': origin,
                'targetname': targetname
            }
##print lane_data


spawner_data = {}
with open('data/dota_pvp_prefab.vmap.txt', 'r') as f:
    dump_on_next_brace = False
    for line in f.readlines():
        if '"origin"' in line:
            origin = [x.replace('"', '') for x in line.strip('\n').split(" ")[-3:]]
        if '"classname"' in line:
            classname = line.strip('\n').split(" ")[-1].replace('"', '')
        if '"targetname"' in line:
            targetname = line.strip('\n').split(" ")[-1].replace('"', '')
        if 'NPCFirstWaypoint' in line:
            NPCFirstWaypoint = line.strip('\n').split(" ")[-1].replace('"', '')
        if 'npc_dota_spawner_' in line and '_staging' not in line:
            dump_on_next_brace = True
        if '}' in line and dump_on_next_brace:
            dump_on_next_brace = False
##            print classname, NPCFirstWaypoint, origin, targetname
            spawner_data[classname] = {
                'NPCFirstWaypoint': NPCFirstWaypoint,
                'origin': origin,
                'targetname': targetname
            }
##print spawner_data

for key in spawner_data:
    obj = spawner_data[key]
    obj['path'] = []
    waypoint = lane_data[obj['NPCFirstWaypoint']]
##    print waypoint
##    coord = {
##        'x': float(waypoint['origin'][0]),
##        'y': float(waypoint['origin'][1]),
####        'targetname': waypoint['targetname']
##    }
    coord = [float(x) for x in waypoint['origin'][:2]]
    obj['path'].append(coord)
    while waypoint['target'] != "" and waypoint['target'] != waypoint['targetname']:
        waypoint = lane_data[waypoint['target']]
##        print waypoint
##        coord = {
##            'x': float(waypoint['origin'][0]),
##            'y': float(waypoint['origin'][1]),
####            'targetname': waypoint['targetname']
##        }
        coord = [float(x) for x in waypoint['origin'][:2]]
        obj['path'].append(coord)
##    print '----'

geojsondata = {
    "type": "FeatureCollection",
    "features": []
}

spawnerdata = {
    "type": "FeatureCollection",
    "features": []
}

for key in spawner_data:
    obj = spawner_data[key]
    feature = {
        "type": "Feature",
        "id": key,
        "geometry": {
            "type": "LineString",
            "coordinates": obj['path']
        }
    }
    geojsondata['features'].append(feature)

    coord = [float(x) for x in obj['origin'][:2]]
    feature = {
        "type": "Feature",
        "id": key,
        "geometry": {
            "type": "Point",
            "coordinates": coord
        }
    }
    spawnerdata['features'].append(feature)


with open('data/path_corner.json', 'w') as f:
    f.write(json.dumps(geojsondata))
with open('data/npc_dota_spawner.json', 'w') as f:
    f.write(json.dumps(spawnerdata))
