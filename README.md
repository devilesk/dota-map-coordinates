# dota-map-coordinates

Custom game for dumping map entity coordinate data to JSON used in the dota interactive map app.

Usage:

Run copymap.bat to get the latest dota map files. Also creates an empty mapdata.txt output file.

Launch the custom game in Workshop Tools

Output path:

`C:\Program Files (x86)\Steam\steamapps\common\dota 2 beta\game\dota\mapdata.txt`

Note: The empty mapdata.txt file needs to exist or else a folder called mapdata.txt will be created and there will be no output text file.
mapdata.txt also needs to be cleared before each run because the custom game can only append the data to the file.