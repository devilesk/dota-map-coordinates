import json
from PIL import Image

file_path = 'C:\Program Files (x86)\Steam\steamapps\common\dota 2 beta\game\dota\elevationdata.json'

with open(file_path, 'r') as f:
    data = json.loads(f.read())
    image = Image.new('RGB', (259, 259))
    pixels = image.load()
    for i in range(0, 259):
        for j in range(0, 259):
            v = int(data[i][j])
            pixels[i, 259 - j - 1] = (255, v * 50, 0)
    image.save('elevation2.png')
