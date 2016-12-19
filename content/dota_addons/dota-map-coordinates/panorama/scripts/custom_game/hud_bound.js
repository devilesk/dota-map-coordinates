GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_TOP_TIMEOFDAY, false );
GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_TOP_HEROES, false );
GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_FLYOUT_SCOREBOARD, false );

function SetCamera() {
  GameUI.SetCameraPitchMin(90);
  GameUI.SetCameraPitchMax(90);
  GameUI.SetCameraDistance(25);
  GameUI.SetCameraLookAtPositionHeightOffset(1500);
  $.Schedule(1, SetCamera);
}
$.Msg("test");
$.Schedule(1, SetCamera);