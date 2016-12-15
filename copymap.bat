echo. 2>"C:\Program Files (x86)\Steam\steamapps\common\dota 2 beta\game\dota\mapdata.txt"

del /s /q "content\dota_addons\dota-map-coordinates\maps"
xcopy /s /y "C:\Program Files (x86)\Steam\steamapps\common\dota 2 beta\content\dota\maps" "content\dota_addons\dota-map-coordinates\maps\"

del /s /q "game\dota_addons\dota-map-coordinates\maps"
xcopy /s /y "C:\Program Files (x86)\Steam\steamapps\common\dota 2 beta\game\dota\maps\dota.vpk" "game\dota_addons\dota-map-coordinates\maps\"