function OnSubmit() {
    GameEvents.SendCustomGameEventToServer("submit", {
        "playerID": Players.GetLocalPlayer(),
        "x": $('#x-input').text,
        "y": $('#y-input').text,
        "delay": $('#delay-input').text
    });
}
function OnClear() {
    GameEvents.SendCustomGameEventToServer("clear", {
        "playerID": Players.GetLocalPlayer(),
        "x": $('#x-input').text,
        "y": $('#y-input').text
    });
}

(function() {
    
});