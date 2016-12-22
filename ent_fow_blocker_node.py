import json

def process_file(file):
    data = []
    with open(file, 'r') as f:
        for line in f.readlines():
            if '"origin"' in line:
                origin_line = [int(round(float(x))) for x in line.split('" "')[2].strip('\r\n').replace('"', '').split(" ")][:2]
            if "ent_fow_blocker_node" in line:
                print origin_line, line
                data.append(origin_line)
                next = True
    return data
data = process_file('dota_pvp_prefab.vmap.txt')
data = data + process_file('dota_custom_default_000.vmap.txt')
print len(data)
with open('ent_fow_blocker_node.json', 'w') as f:
    f.write(json.dumps({"data": data}, indent=1, sort_keys=True))