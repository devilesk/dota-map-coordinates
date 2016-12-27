import json
from operator import add, div

def load_world_data(src):
    with open(src, 'r') as f:
        data = json.loads(f.read())
        worldMinX = data['worldMinX']
        worldMinY = data['worldMinY']
        worldMaxX = data['worldMaxX']
        worldMaxY = data['worldMaxY']
        worldWidth = worldMaxX - worldMinX
        worldHeight = worldMaxY - worldMinY
        gridWidth = worldWidth / 64 + 1
        gridHeight = worldHeight / 64 + 1
        return worldMinX, worldMinY, \
               worldMaxX, worldMaxY, \
               worldWidth, worldHeight, \
               gridWidth, gridHeight
    
worldMinX, worldMinY, \
worldMaxX, worldMaxY, \
worldWidth, worldHeight, \
gridWidth, gridHeight = load_world_data("data/worlddata.json")

def world_to_grid(wX, wY, bRound=True):
    x = (wX - worldMinX) / float(64)
    y = (wY - worldMinY) / float(64)
    if bRound:
        rx = int(round(x))
        ry = int(round(y))
        return rx, ry
    return x, y



generate_toolswardsonly_from_data("data/toolswardsonly.json", "img/gridnav.png", gridnav, (255, 255, 255))
