import json
import math
from PIL import Image
import subprocess
from operator import add, div
from graham_scan import convex_hull
import matplotlib.path as mplPath
import numpy as np
    
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

def world_to_grid(wX, wY, bRound=True):
    x = (wX - worldMinX) / float(64)
    y = (wY - worldMinY) / float(64)
    if bRound:
        rx = int(round(x))
        ry = int(round(y))
        return rx, ry
    return x, y

def grid_to_world(gX, gY):
    return gX * 64 + worldMinX, gY * 64 + worldMinY

def grid_to_image(gX, gY):
    return gX, gridHeight - gY - 1

def world_to_image(wX, wY):
    x, y = world_to_grid(wX, wY)
    return grid_to_image(x, y)

def generate_gridnav_image(src, dst):
    with open(src, 'r') as f:
        data = json.loads(f.read())['data']
        image = Image.new('RGB', (gridWidth, gridHeight), (255, 255, 255))
        pixels = image.load()
        for pt in data:
            x, y = world_to_image(pt['x'], pt['y'])
            pixels[x, y] = (0, 0, 0)
        image.save(dst)

def generate_elevation_image(src, dst):
    with open(src, 'r') as f:
        data = json.loads(f.read())['data']
        image = Image.new('RGB', (gridWidth, gridHeight))
        pixels = image.load()
        for gX in range(0, len(data)):
            row = data[gX]
            for gY in range(0, len(row)):
                x, y = grid_to_image(gX, gY)
                z = int(data[gX][gY]) + 1
                pixels[x, y] = (10 * z, 0, 0)
        image.save(dst)

def generate_ent_fow_blocker_node_image(files, dst):
    data = []
    def process_file(src):
        with open(src, 'r') as f:
            for line in f.readlines():
                # assumes origin line appears before ent_fow_blocker_node line
                if '"origin"' in line:
                    origin_line = [int(round(float(x))) for x in line.split('" "')[2].strip('\r\n').replace('"', '').split(" ")][:2]
                if "ent_fow_blocker_node" in line:
                    data.append(origin_line)

    for f in files:
        process_file(f)

    image = Image.new('RGB', (gridWidth, gridHeight), (255, 255, 255))
    pixels = image.load()
    for pt in data:
        x, y = world_to_image(pt[0], pt[1])
        pixels[x, y] = (0, 0, 0)
    image.save(dst)

def generate_tree_elevation_image(src, dst):
    with open(src, 'r') as f:
        data = json.loads(f.read())['ent_dota_tree']
        image = Image.new('RGB', (gridWidth, gridHeight), (255, 255, 255))
        pixels = image.load()
        for pt in data:
            x, y = world_to_image(pt['x'], pt['y'])
            z = int(pt['z'] / 128) + 1
            pixels[x, y] = (10 * z, 0, 0)
        image.save(dst)

def parse_tools_no_wards_prefab(src, dst):

    def process_file(src):
        data = []
        buffer = []
        begin = False
        tools_no_wards = False
        with open(src, 'r') as f:
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

    data = process_file(src)
    with open(dst, 'w') as f:
        for line in data:
            f.write(line)

def generate_tools_no_wards_data(parser_src, prefab_src, dst):
    data = json.loads(subprocess.Popen(["node", parser_src, prefab_src], stdout=subprocess.PIPE).communicate()[0])

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
    for obj in data:
        if obj['key'] == 'CMapEntity':
            for mesh in obj['children']['values']:
                tools_no_wards_data.append(process_mesh(mesh))
                continue
        elif obj['key'] == 'CMapMesh':
            tools_no_wards_data.append(process_mesh(obj))

    with open(dst, 'w') as f:
        f.write(json.dumps({"data": tools_no_wards_data}, indent=1, sort_keys=True))

def generate_tools_no_wards_image(src, dst):

    def any_contains_point(data, point):
        for points in data:
            if contains_point(points, point):
                return True
        return False
    
    def contains_point(points, point):
        bbPath = mplPath.Path(np.array(points))
        return bbPath.contains_point(point)
    
    with open(src, 'r') as f:
        data = json.loads(f.read())['data']
        image = Image.new('RGB', (gridWidth, gridHeight), (255, 255, 255))
        pixels = image.load()
        for gX in range(0, gridWidth):
            for gY in range(0, gridHeight):
                wX, wY = grid_to_world(gX, gY)
                if any_contains_point(data, [wX, wY]):
                    x, y = grid_to_image(gX, gY)
                    pixels[x, y] = (0, 0, 0)
        image.save(dst)

def stitch_images(files, dst):
    images = map(Image.open, files)
    widths, heights = zip(*(i.size for i in images))

    total_width = sum(widths)
    max_height = max(heights)

    new_im = Image.new('RGB', (total_width, max_height))

    x_offset = 0
    for im in images:
      new_im.paste(im, (x_offset,0))
      x_offset += im.size[0]

    new_im.save(dst)

worldMinX, worldMinY, \
worldMaxX, worldMaxY, \
worldWidth, worldHeight, \
gridWidth, gridHeight = load_world_data("data/worlddata.json")

generate_gridnav_image("data/gridnavdata.json", "img/gridnav.png")
generate_elevation_image("data/elevationdata.json", "img/elevation.png")
generate_ent_fow_blocker_node_image(["data/dota_pvp_prefab.vmap.txt", "data/dota_custom_default_000.vmap.txt"], "img/ent_fow_blocker_node.png")
generate_tree_elevation_image("data/mapdata.json", "img/tree_elevation.png")
parse_tools_no_wards_prefab("data/dota_pvp_prefab.vmap.txt", "data/tools_no_wards.txt")
generate_tools_no_wards_data("keyvalues2.js", "data/tools_no_wards.txt", "data/tools_no_wards.json")
generate_tools_no_wards_image("data/tools_no_wards.json", "img/tools_no_wards.png")
stitch_images(["img/elevation.png", "img/tree_elevation.png", "img/gridnav.png", "img/ent_fow_blocker_node.png", "img/tools_no_wards.png"], "img/map_data.png")
