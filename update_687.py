import json

with open('687/mapdata.json', 'r') as f:
    data = json.loads(f.read())['data']

    new_triggers = []
    for trigger in data['trigger_multiple']:
        new_triggers.append({
            'points': trigger
        })
    data['trigger_multiple'] = new_triggers
    for k in data:
        print k

    with open('mapdata2.json', 'w') as g:
        g.write(json.dumps({"data":data}))
