echo. 2>"C:\Program Files (x86)\Steam\steamapps\common\dota 2 beta\game\dota\mapdata.json"
echo. 2>"C:\Program Files (x86)\Steam\steamapps\common\dota 2 beta\game\dota\worlddata.json"
echo. 2>"C:\Program Files (x86)\Steam\steamapps\common\dota 2 beta\game\dota\elevationdata.json"
echo. 2>"C:\Program Files (x86)\Steam\steamapps\common\dota 2 beta\game\dota\gridnavdata.json"

del /s /q "content\dota_addons\dota-map-coordinates\maps"
xcopy /s /y "C:\Program Files (x86)\Steam\steamapps\common\dota 2 beta\content\dota\maps" "content\dota_addons\dota-map-coordinates\maps\"

del /s /q "game\dota_addons\dota-map-coordinates\maps"
xcopy /s /y "C:\Program Files (x86)\Steam\steamapps\common\dota 2 beta\game\dota\maps\dota.vpk" "game\dota_addons\dota-map-coordinates\maps\"