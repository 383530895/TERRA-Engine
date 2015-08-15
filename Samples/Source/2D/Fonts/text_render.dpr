{$I terra.inc}
{$IFDEF MOBILE}Library{$ELSE}Program{$ENDIF} BasicSample;

Uses
  {$IFDEF DEBUG_LEAKS}MemCheck,{$ELSE}  TERRA_MemoryManager,{$ENDIF}
  TERRA_String, TERRA_Object, TERRA_Utils, TERRA_Application, TERRA_Scene, TERRA_GraphicsManager,
  TERRA_ResourceManager, TERRA_Color, TERRA_Font, TERRA_FontRenderer, TERRA_OS, TERRA_FileManager,
  TERRA_PNG, TERRA_TTF, TERRA_Viewport, TERRA_Localization, TERRA_Sprite,
  TERRA_InputManager;

Type
  // A client is used to process application events
  Demo = Class(Application)
    Protected
      _Scene:TERRAScene;

			Procedure OnCreate; Override;
      Procedure OnDestroy; Override;
			Procedure OnIdle; Override;
  End;

  // A scene is used to render objects
  MyScene = Class(TERRAScene)
      Procedure RenderSprites(V:TERRAViewport); Override;
  End;

Var
  _FontRenderer:FontRenderer = Nil;

{ Game }
Procedure Demo.OnCreate;
Begin
  // Add asset folders
  FileManager.Instance.AddPath('assets');

  GraphicsManager.Instance.DeviceViewport.BackgroundColor := ColorRed;

  // Load a font
  _FontRenderer := FontRenderer.Create();
  _FontRenderer.SetFont(FontManager.Instance.GetFont('droid@52'));

  // Create a scene and set it as the current scene
  _Scene := MyScene.Create;
  GraphicsManager.Instance.SetScene(_Scene);
End;

// OnIdle is called once per frame, put your game logic here
Procedure Demo.OnDestroy;
Begin
  ReleaseObject(_FontRenderer);
  ReleaseObject(_Scene);
End;

Procedure Demo.OnIdle;
Begin
  If InputManager.Instance.Keys.WasReleased(keyEscape) Then
    Application.Instance.Terminate;
End;

// function to translate Unicode strings to TERRA strings
Function U2T(Const S:WideString):AnsiString;
Var
  I:Integer;
  W:WideChar;
Begin
  Result := '';
  For I:=1 To Length(S) Do
  Begin
    W := S[I];
    Result := Result + StringFromChar(TERRAChar(W));
  End;
End;

{ MyScene }
Procedure MyScene.RenderSprites(V:TERRAViewport);
Begin
  // render some text
  If Assigned(_FontRenderer.Font) Then
  Begin
    //_FontRenderer.DrawText(V, 50, 70, 10, ' X');    Exit;

    _FontRenderer.SetSize(50.0);
    _FontRenderer.DrawText(V, 50, 70, 10, ' Hello World!');

    _FontRenderer.SetSize(30.0);
    _FontRenderer.SetColor(ColorBlue);
    _FontRenderer.DrawText(V, 500, 100, 10, StringFromChar(fontControlWave)+'Wavy text!');

    _FontRenderer.SetColor(ColorYellow);
    _FontRenderer.DrawText(V, 550, 200, 10, 'This is a'+StringFromChar(fontControlNewLine)+'line break!');

    _FontRenderer.SetColor(ColorGreen);
    _FontRenderer.DrawText(V, 600, 300, 10, StringFromChar(fontControlItalics)+' Italic text!');

    // unicode rendering
    _FontRenderer.SetColor(ColorWhite);
    _FontRenderer.DrawText(V, 50, 200, 10, GetLanguageDescription(language_Russian));
    _FontRenderer.DrawText(V, 50, 250, 10, GetLanguageDescription(language_Chinese));
    _FontRenderer.DrawText(V, 50, 300, 10, GetLanguageDescription(language_Korean));
    _FontRenderer.DrawText(V, 50, 350, 10, GetLanguageDescription(language_Japanese));

    // dynamic text
    _FontRenderer.DrawText(V, V.Width - 100, 50, 10, CardinalToString(Application.GetTime() Div 1000));
  End;
End;

Begin
  // Start the application
  Demo.Create();
End.