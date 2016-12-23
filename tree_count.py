import json

with open('data/mapdata.json', 'r') as f:
    print len(json.loads(f.read())['ent_dota_tree'])
