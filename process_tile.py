from operator import add, sub
import json
import subprocess
import math
from graham_scan import convex_hull
from process_data import load_world_data, grid_to_world, any_intersects_point, grid_to_image
from PIL import Image

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
                print layer_name, 'found'
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
##        print 'get_cells_for_node_id', len(self.cell_configuration), self.nodeID
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
##                print count, x, y, self.cell_orientation[count]
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
            dst = "tmp.txt"
            with open(dst, 'w') as f:
                for line in buf:
                    f.write(line)
            data = json.loads(subprocess.Popen(["node", parser_src, dst], stdout=subprocess.PIPE).communicate()[0])
            self.parent_map_tile = CMapTile()
            self.parent_map_tile.load_json(data[0])
            
def parse_tools_no_wards_prefab(src, dst):

    def process_file(src):
        data = []
        buffer = []
        begin = False
        tools_no_wards = False
        with open(src, 'r') as f:
            for line in f.readlines():
                if line.startswith('"CMapTile"') or line.startswith('"CMapMesh"'):
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
        print mesh_obj.parent_map_tile.nodeID
        cells = mesh_obj.parent_map_tile.get_cells_for_node_id()
        for cell in cells:
            print 'cell', cell
            #cell[1] = 6784
            #cell[2] = 5760
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
                print 'vertex', vertex[:2], v, point
                points.append(tuple(point))
            points = convex_hull(list(set(points)))
            data.append(points)

    image = Image.new('RGB', (gridWidth, gridHeight), (255, 255, 255))
    pixels = image.load()
    for gX in range(0, gridWidth):
        for gY in range(0, gridHeight):
            wX, wY = grid_to_world(gX, gY)
            if any_intersects_point(data, [wX, wY]):
                x, y = grid_to_image(gX, gY)
                pixels[x, y] = (0, 0, 0)
    image.save(dst)

worldMinX, worldMinY, \
worldMaxX, worldMaxY, \
worldWidth, worldHeight, \
gridWidth, gridHeight = load_world_data("data/worlddata.json")

generate_tools_no_wards_data("keyvalues2.js", "data/dire_basic_tools_no_wards.txt", "dire_basic_tools_no_wards.png")


