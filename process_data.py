import json
import math
import matplotlib.path as mplPath
import numpy as np
import subprocess
import tempfile
from graham_scan import convex_hull
from operator import add, div, sub
from PIL import Image
    
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
        buff = []
        begin = False
        tools_no_wards = False
        with open(src, 'r') as f:
            for line in f.readlines():
                if line.startswith('"CMapEntity"') or line.startswith('"CMapTile"') or line.startswith('"CMapMesh"'):
                    begin = True
                    buff = []
                if begin:
                    buff.append(line)
                    if '"materials/tools/tools_no_wards.vmat"' in line:
                        tools_no_wards = True
                    if line.startswith('}'):
                        if tools_no_wards:
                            data += buff
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
            point = [x for x in map(add, vertex, origin)][:2]
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

def any_contains_point(data, point):
    for points in data:
        if contains_point(points, point):
            return True
    return False

def any_intersects_point(data, point):
    for points in data:
        if intersects_point(points, point):
            return True
    return False

def intersects_point(points, point):
    bbPath = mplPath.Path(np.array(points))
    tile_points = [[point[0] - 32, point[1] - 32],
                   [point[0] - 32, point[1] + 32],
                   [point[0] + 32, point[1] + 32],
                   [point[0] + 32, point[1] - 32]]
    bbPath2 = mplPath.Path(np.array(tile_points))
    return bbPath.intersects_path(bbPath2)

def contains_point(points, point):
    bbPath = mplPath.Path(np.array(points))
    return bbPath.contains_point(point)

def generate_tools_no_wards_image(src, dst, image=None):
    if image is None:
        image = Image.new('RGB', (gridWidth, gridHeight), (255, 255, 255))

    with open(src, 'r') as f:
        data = json.loads(f.read())['data']
        pixels = image.load()
        for gX in range(0, gridWidth):
            for gY in range(0, gridHeight):
                wX, wY = grid_to_world(gX, gY)
                if any_intersects_point(data, [wX, wY]):
                    x, y = grid_to_image(gX, gY)
                    pixels[x, y] = (0, 0, 0)
        image.save(dst)
    return image

def parse_vmap_for_cell_info(src, layer_name='defaultLayer'):
    begin = False
    begin_cell_configuration = False
    begin_cell_orientation = False
    cell_configuration = []
    cell_orientation = []
    with open(src, 'r') as f:
        for line in f.readlines():
            if begin_cell_configuration:
                cell_configuration.append(line)
            if begin_cell_orientation:
                cell_orientation.append(line)
                    
            if '"name" "string" "' + layer_name + '"' in line:
                begin = True
            if begin:
                if '"cellConfiguration"' in line:
                    begin_cell_configuration = True
                if '"cellsOrientation"' in line:
                    begin_cell_orientation = True
                if line.startswith('		}'):
                    begin = False
                    break
            if ']' in line:
                if begin_cell_configuration:
                    begin_cell_configuration = False
                if begin_cell_orientation:
                    begin_cell_orientation = False
    cell_configuration = [ int(x) for x in json.loads(''.join([x.rstrip('\n') for x in cell_configuration]))]
    cell_orientation = [ int(x) for x in json.loads(''.join([x.rstrip('\n') for x in cell_orientation]))]
    return cell_configuration, cell_orientation

class CMapTile:

    cell_configuration, cell_orientation = parse_vmap_for_cell_info('data/dota.vmap.txt')
    
    def __init__(self):
        self.elementid = ""
        self.origin = []
        self.nodeID = ""

    def load_json(self, data):
        self.elementid = data['id']['values']
        self.origin = data['origin']['values']
        self.nodeID = data['nodeID']['values']

    def get_cells_for_node_id(self):
        i = 0
        count = 0
        cells = []
        while i < len(self.cell_configuration):
            b = self.cell_configuration[i+1:i+int(self.cell_configuration[i])+1]
            assert len(b) == int(self.cell_configuration[i])
            row, col = math.floor(count / 64), count % 64
            # tile grid 64x64 centered at world (0, 0)
            # each tile is 256x256
            # tile grid extends 256*32 = 8192 in each direction from (0, 0)
            # -8192 is leftmost tile, add 128 to get center of tile = 8064
            y, x = row * 256 - 8064, col * 256 - 8064
            count = count + 1
            if self.nodeID in b:
                cells.append([count, x, y, self.cell_orientation[count], row, col])
            i = i + int(self.cell_configuration[i]) + 1
        return cells

class CMapMesh:

    def __init__(self):
        self.elementid = ""
        self.origin = []
        self.vertices = []

    def load_json(self, data):
        self.elementid = data['id']['values']
        self.origin = data['origin']['values']
        self.vertices = data['meshData']['values']['vertexData']['values']['streams']['values'][0]['data']['values']

    def get_vertices(self):
        points = []
        offset = self.get_offset()
        for vertex in self.vertices:
            point = [x for x in map(add, vertex, offset)]
            points.append(tuple(point))
        return points

    def get_offset(self):
        return [x for x in map(sub, self.origin, self.parent_map_tile.origin)]

    def load_parent_map_tile(self, src, parser_src="keyvalues2.js"):
        def process_file(src):
            buf = []
            begin = False
            found = False
            with open(src, 'r') as f:
                for line in f.readlines():
                    if line.startswith('"CMapTile"'):
                        begin = True
                        buf = []
                    if begin:
                        buf.append(line)
                        if self.elementid in line:
                            found = True
                        if line.startswith('}'):
                            if found:
                                found = False
                                return buf
                            begin = False
            return None
        buf = process_file(src)
        if buf:
            with tempfile.NamedTemporaryFile() as tmp:
                for line in buf:
                    tmp.write(line)
                tmp.flush()
                data = json.loads(subprocess.Popen(["node", parser_src, tmp.name], stdout=subprocess.PIPE).communicate()[0])
                self.parent_map_tile = CMapTile()
                self.parent_map_tile.load_json(data[0])
            
def generate_tools_no_wards_image_from_tile_data(parser_src, prefab_src, dst, image=None):
    if image is None:
        image = Image.new('RGB', (gridWidth, gridHeight), (255, 255, 255))
        
    data = json.loads(subprocess.Popen(["node", parser_src, prefab_src], stdout=subprocess.PIPE).communicate()[0])
        
    mesh_objs = []
    for obj in data:
        if obj['key'] == 'CMapEntity':
            for mesh in obj['children']['values']:
                mesh_obj = CMapMesh()
                mesh_obj.load_json(mesh)
                mesh_objs.append(mesh_obj)
                continue
        elif obj['key'] == 'CMapMesh':
            mesh_obj = CMapMesh()
            mesh_obj.load_json(obj)
            mesh_objs.append(mesh_obj)

    data = []
    for mesh_obj in mesh_objs:
        mesh_obj.load_parent_map_tile('data/dire_basic.vmap.txt')
        cells = mesh_obj.parent_map_tile.get_cells_for_node_id()
        for cell in cells:
            points = []
            for vertex in mesh_obj.get_vertices():
                if cell[3] == 0:
                    v = vertex[:2]
                elif cell[3] == 3:
                    v = [vertex[1], -vertex[0]]
                else:
                    print 'unhandled orientation', cell[3]
                    raise ValueError
                point = [x for x in map(add, v, cell[1:3])]
                points.append(tuple(point))
            points = convex_hull(list(set(points)))
            data.append(points)

    pixels = image.load()
    for gX in range(0, gridWidth):
        for gY in range(0, gridHeight):
            wX, wY = grid_to_world(gX, gY)
            if any_intersects_point(data, [wX, wY]):
                x, y = grid_to_image(gX, gY)
                pixels[x, y] = (0, 0, 0)
    image.save(dst)
    return image

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

print 'loaded world data', worldMinX, worldMinY, worldMaxX, worldMaxY, worldWidth, worldHeight, gridWidth, gridHeight
print 'generating gridnav image'
generate_gridnav_image("data/gridnavdata.json", "img/gridnav.png")
print 'generating elevation image'
generate_elevation_image("data/elevationdata.json", "img/elevation.png")
print 'generating ent_fow_blocker_node image'
generate_ent_fow_blocker_node_image(["data/dota_pvp_prefab.vmap.txt", "data/dota_custom_default_000.vmap.txt"], "img/ent_fow_blocker_node.png")
print 'generating tree_elevation image'
generate_tree_elevation_image("data/mapdata.json", "img/tree_elevation.png")
print 'parsing dota_pvp_prefab'
parse_tools_no_wards_prefab("data/dota_pvp_prefab.vmap.txt", "data/tools_no_wards.txt")
print 'generating tools_no_wards data'
generate_tools_no_wards_data("keyvalues2.js", "data/tools_no_wards.txt", "data/tools_no_wards.json")
print 'generating tools_no_wards image'
im = generate_tools_no_wards_image("data/tools_no_wards.json", "img/tools_no_wards.png")
# add tools_no_wards from tiles to image
print 'parsing dire_basic prefab'
parse_tools_no_wards_prefab("data/dire_basic.vmap.txt", "data/dire_basic_tools_no_wards.txt")
print 'adding tile data to tools_no_wards image'
generate_tools_no_wards_image_from_tile_data("keyvalues2.js", "data/dire_basic_tools_no_wards.txt", "img/tools_no_wards.png", im)
print 'stitching final image'
stitch_images(["img/elevation.png", "img/tree_elevation.png", "img/gridnav.png", "img/ent_fow_blocker_node.png", "img/tools_no_wards.png"], "img/map_data.png")
print 'done'
