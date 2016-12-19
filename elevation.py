import json
from PIL import Image

file_path = 'C:\Program Files (x86)\Steam\steamapps\common\dota 2 beta\game\dota\elevationdata.json'

with open(file_path, 'r') as f:
    data = json.loads(f.read())
    print data.keys()
    image = Image.new('RGB', (data['width'], data['height']))
    pixels = image.load()
    zValues = []
    for pt in data['points']:
        zValues.append(pt['worldZ'])
    zValues = sorted(list(set(zValues)))
    zMin = zValues[0]
    zMax = zValues[-1]
    #print zValues

    elevations = []
    for pt in data['points']:
        z = pt['worldZ']
        v = int((z + abs(zMin)) / 128)
        elevations.append(v)
        if v == (z + abs(zMin)) / 128:
            pixels[int(pt['x']), data['height'] - int(pt['y']) - 1] = (v % 3 * 50, v, v % 3 * 50)
        elif z > 500:
            pixels[int(pt['x']), data['height'] - int(pt['y']) - 1] = (255, 0, 0)
    image.save('elevation.png')

    elevations = sorted(list(set(elevations)))
    print elevations
