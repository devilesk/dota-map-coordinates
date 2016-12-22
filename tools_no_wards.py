import json
import subprocess
from operator import add, div
from graham_scan import convex_hull

worldMinX = -8288
worldMinY = -8288
worldMaxX = 8288
worldMaxY = 8288

def worldXY_to_XY(point):
    
def process_file(file):
    data = []
    buffer = []
    begin = False
    tools_no_wards = False
    with open(file, 'r') as f:
        for line in f.readlines():
            if line.startswith('"CMapEntity"') or line.startswith('"CMapMesh"'):
                begin = True
                buffer = []
            if begin:
                buffer.append(line)
                if '"materials/tools/tools_no_wards.vmat"' in line:
                    tools_no_wards = True
                if line.startswith('}'):
                    if tools_no_wards:
                        data += buffer
                        tools_no_wards = False
                    begin = False
    return data

data = process_file('dota_pvp_prefab.vmap.txt')
with open('tools_no_wards.txt', 'w') as f:
    for line in data:
        f.write(line)
        
with open('tools_no_wards.json', 'w') as f:
    parsed_data = {"data": json.loads(subprocess.Popen(["node", "kv2.js", "tools_no_wards.txt"], stdout=subprocess.PIPE).communicate()[0])}
    f.write(json.dumps(parsed_data, indent=1, sort_keys=True))

def process_mesh(mesh):
    origin = mesh['origin']['values']
    vertices = mesh['meshData']['values']['vertexData']['values']['streams']['values'][0]['data']['values']
    points = []
    for vertex in vertices:
        point = [int(round(x)) for x in map(add, vertex, origin)][:2]
        points.append(tuple(point))
    points = convex_hull(list(set(points)))
    return points
    
tools_no_wards_data = []
for obj in parsed_data['data']:
    if obj['key'] == 'CMapEntity':
        for mesh in obj['children']['values']:
            tools_no_wards_data.append(process_mesh(mesh))
            continue
    elif obj['key'] == 'CMapMesh':
        tools_no_wards_data.append(process_mesh(obj))
print tools_no_wards_data

import matplotlib.path as mplPath
import numpy as np

bbPath = mplPath.Path(np.array(tools_no_wards_data[0]))

print bbPath.contains_point((-7119, -6656))