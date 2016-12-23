import json
import math

with open('data/cellOrientation.txt', 'r') as f:
    cellOrientation = json.loads(f.read())
    
tile_node_ids = ["19244", "19222"]
with open('data/cellConfiguration.txt', 'r') as f:
    cellConfiguration = json.loads(f.read())
    print len(cellConfiguration)
    i = 0
    count = 0
    while i < len(cellConfiguration):
        #print x, int(data[x])
        b = cellConfiguration[i+1:i+int(cellConfiguration[i])+1]
        assert len(b) == int(cellConfiguration[i])
        count = count + 1
        r, c = math.floor(count / 64), count % 64
        y, x = r * 257 - 8288, c * 257 - 8288
        for tile in tile_node_ids:
            if tile in b:
        #if "19338" in b:
                print x, y, tile, count, b.index(tile)
        i = i + int(cellConfiguration[i]) + 1
    print count

print cellOrientation[3515]
print cellOrientation[3641]
