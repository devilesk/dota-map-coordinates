# dota-map-coordinates

Custom game for dumping map entity coordinate data to JSON and scripts for generating elevation and vision related images. See [dota interactive map](https://github.com/devilesk/dota-interactive-map) for an application of the data.

Usage:

Run `copymap.bat` to get the latest dota map files. Also creates an empty mapdata.txt output file.

Launch the custom game in Workshop Tools. Select a hero and enter the game. Once the game starts the following files will be generated:

* `mapdata.json` - Coordinates of all buildings, trees, shops, etc.

* `worlddata.json` - Map dimensions.

* `gridnavdata.json` - Coordinates of all untraversable 64x64 grid tiles. 

* `elevationdata.json` - Elevations of each 64x64 grid tile.

Output path:

`C:\Program Files (x86)\Steam\steamapps\common\dota 2 beta\game\dota\mapdata.txt`

Note: The empty text files need to exist or else folders instead of text files will be created by the custom game and no output will be saved.
The text files also needs to be cleared before each run because the custom game can only append the data to the file.

Run `copydata.bat` to copy the generated files from the dota directory to the data folder in the repository directory.

Run `textvmap.bat` to generate the vmap.txt files using dmxconvert. Text vmaps can also be created by opening the prefab files in Hammer and doing Save Copy As Text.

Run `process_data.py` to generate json and images based on the data. The following images are created:

* `gridnav.png` - Generated from gridnavdata.json.
![gridnav.png](img/gridnav.png?raw=true)

* `elevation.png` - Generated from elevationdata.json.
![elevation.png](img/elevation.png?raw=true)

* `tree_elevation.png` - Generated from mapdata.json.
![tree_elevation.png](img/tree_elevation.png?raw=true)

* `ent_fow_blocker_node.png` - Generated from text versions of map prefab files, dota_pvp_prefab.vmap and dota_custom_default_000.vmap.
![ent_fow_blocker_node.png](img/ent_fow_blocker_node.png?raw=true)