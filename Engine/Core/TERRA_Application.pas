{***********************************************************************************************************************
 *
 * TERRA Game Engine
 * ==========================================
 *
 * Copyright (C) 2003, 2014 by S�rgio Flores (relfos@gmail.com)
 *
 ***********************************************************************************************************************
 *
 * Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with
 * the License. You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on
 * an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the
 * specific language governing permissions and limitations under the License.
 *
 **********************************************************************************************************************
 * TERRA_Application
 * Implements the engine Application class, which provides cross platform support
 ***********************************************************************************************************************
}

(*
      Procedure OnAppResize; Virtual;
      Procedure Suspend; Virtual;
      Procedure Resume; Virtual;
      Procedure OnLanguageChange; Virtual;
      Procedure OnOrientationChange; Virtual;
      Procedure OnContextLost; Virtual;
      Procedure OnViewportChange(X1, Y1, X2, Y2:Integer); Virtual;
*)
{$IFDEF OXYGENE}
namespace TERRA;

{$ELSE}
Unit TERRA_Application;
{$I terra.inc}
{$ENDIF}

{$IFDEF WINDOWS}
{$UNDEF MOBILE}
{-$DEFINE DEBUG_TAPJOY}
{$ENDIF}

{$IFDEF CRASH_REPORT}
{$IFNDEF WINDOWS}
{$DEFINE INSTALL_SIGNAL}
{$ENDIF}
{$ENDIF}


Interface
Uses TERRA_String, TERRA_Object, TERRA_Utils, TERRA_Vector2D, TERRA_Vector3D, TERRA_Matrix4x4, TERRA_Mutex;

Const
	// Operating System Class
	osUnknown = 0;
	osWindows = 1;
	osLinux   = 2;
	osOSX     = 4;
  osiOS     = 8;
  osAndroid = 16;
  osOuya    = 32;
  osWindowsPhone     = 64;
  osWii         = 128;
  osNintendoDS  = 256;
  osPSVita      = 512;
  osHTML5       = 1024;
  osFlash       = 2048;

  cpuUnknown = 0;
  cpuX86_32   = 1;
  cpuX86_64   = 2;
  cpuArm_32   = 4;
  cpuArm_64   = 8;

  osDesktop = osWindows Or osLinux or osOSX;
  osMobile = osAndroid Or osiOS Or osWindowsPhone;
  osConsole = osOUYA Or osWii Or osPSVita Or osNintendoDS;
  osWeb = osHTML5 Or osFlash;
  osEverything = $FFFFFFFF;

	MaxTimers = 16;

  TimerMultiplier = 4;

  OrientationAnimationDuration = 1000;

	// Window state
	wsNormal    = 0;
	wsMinimized = 1;
	wsMaximized = 2;

  orientationPortrait =  0;
  orientationLandscapeLeft =  1;
  orientationLandscapeRight =  2;
  orientationPortraitInverted =  3;

  eventMouseUp   = 0;
  eventMouseDown = 1;
  eventMouseMove = 2;
  eventMouseWheel = 3;
  eventKeyPress   = 4;
  eventKeyDown    = 5;
  eventKeyUp      = 6;
  eventWindowResize   = 7;
  eventAccelerometer  = 8;
  eventGyroscope      = 9;
  eventCompass        = 10;
  eventContextLost    = 11;
  eventOrientation    = 12;
  //eventViewport       = 13;
  eventIAPPurchase    = 14;
  eventIAPCredits     = 15;
  eventIAPError       = 16;

  EventBufferSize = 512;
  CallbackBufferSize = 64;

  settingsHintLow   = 0;
  settingsHintMedium = 1;
  settingsHintHigh   = 2;
  settingsHintVeryHigh   = 3;

Const
  apiFacebook = 1;
  apiTapjoy   = 2;

  facebookPostSucess        = 1;
  facebookConnectionError   = 2;
  facebookLikeSucess        = 3;
  facebookLikeError         = 4;
  facebookAuthError         = 5;

  tapjoyUpdateError        = 30;
  tapjoyConnectionError    = 31;
  tapjoySpendError         = 32;
  tapjoySpendSuccess       = 33;
  tapjoyOffersError        = 34;
  tapjoyVideoUnvailable    = 35;
  tapjoyVideoSuccess       = 36;
  tapjoyOfferSuccess       = 37;
  
Type
  ApplicationEvent = Record
    X,Y,Z,W:Single;
    S:TERRAString;
    Value:Integer;
    Action:Integer;
    HasCoords:Boolean;
  End;

  ApplicationScreenDimensions = Record
    Width:Integer;
    Height:Integer;
  End;

  ApplicationCallback = Function (Arg:TERRAObject):Boolean Of Object;

  ApplicationCallbackEntry = Record
    Run:ApplicationCallback;
    Time:Cardinal;
    Delay:Cardinal;
    Canceled:Boolean;
    Arg:TERRAObject;
  End;

  AssetWatchNotifier = Procedure(Const FileName:TERRAString); Cdecl;

(*  FolderManager = Class(ApplicationComponent)
    Protected
      _Notifiers:Array Of AssetWatchNotifier;
      _NotifierCount:Integer;

    Public
      Class Function Instance:FolderManager;

      Function WatchFolder(Const Path:TERRAString):Boolean; Virtual;

      Procedure NotifyFileChange(Const FileName:TERRAString);

      Procedure AddWatcher(Notifier:AssetWatchNotifier);
  End;*)

 BaseApplication = Class(TERRAObject)
		Protected
			_Running:Boolean;
      _Ready:Boolean;
      _Hidden:Boolean;
			_CanReceiveEvents:Boolean;
      _Suspended:Boolean;
			_Startup:Boolean;
      _StartTime:Cardinal;
			_Title:TERRAString;
			_State:Cardinal;
			_Path:TERRAString;
      _Managed:Boolean;

      _Screen:ApplicationScreenDimensions;

      _Language:TERRAString;
      _Country:TERRAString;

      _Events:Array[0..Pred(EventBufferSize)] Of ApplicationEvent;
      _EventCount:Integer;

      {$IFNDEF DISABLEINPUTMUTEX}
      _InputMutex:CriticalSection;
      {$ENDIF}

      _Callbacks:Array[0..Pred(CallbackBufferSize)] Of ApplicationCallbackEntry;
      _CallbackCount:Integer;
      _CallbackMutex:CriticalSection;

      _InitApp:Boolean;

      _Width:Integer;
      _Height:Integer;

      _AspectRatio:Single;
      _AntialiasSamples:Integer;
			_FullScreen:Boolean;
      _IgnoreCursor:Boolean;

      _PauseStart:Cardinal;
      _PauseCounter:Cardinal;
      _Paused:Boolean;

      _ContextWasLost:Boolean;

      _BundleVersion:TERRAString;

      _CurrentUser:TERRAString;

      _ChangeToFullScreen:Boolean;

      _Terminated:Boolean;

      _Orientation:Integer;
      _PreviousOrientation:Integer;
      _OrientationTime:Integer;

      _CPUCores:Integer;

      _TapjoyCredits:Integer;

      _DocumentPath:TERRAString;
      _StoragePath:TERRAString;
      _TempPath:TERRAString;
      _FontPath:TERRAString;

      _FrameStart:Cardinal;

//      _FolderManager:FolderManager;

  		_DebuggerPresent:Boolean;

      Function IsDebuggerPresent:Boolean; Virtual;

			{$IFDEF HASTHREADS}
      //_InputThread:Thread;
      {$ENDIF}

			Function InitWindow:Boolean; Virtual; Abstract;
			Procedure CloseWindow; Virtual; Abstract;

      Procedure OnShutdown; Virtual;

			Procedure InitSystem;
			Procedure ShutdownSystem;

      Procedure ProcessMessages; Virtual;
      Procedure ProcessCallbacks;

      Procedure OnFrameBegin(); Virtual;
      Procedure OnFrameEnd(); Virtual;

      Function InitSettings:Boolean; Virtual;

      Procedure Finish;

      Procedure SetPause(Value:Boolean);

      Procedure ConvertCoords(Var X,Y:Single);

      Function GetAspectRatio: Single;

      //Procedure UpdateCallbacks;
      //Procedure SetProcessorAffinity;

      Function GetTempPath():TERRAString; Virtual;
      Function GetDocumentPath():TERRAString; Virtual;
      Function GetStoragePath():TERRAString; Virtual;

      Procedure AddEventToQueue(Action:Integer; X,Y,Z,W:Single; Value:Integer; S:TERRAString; HasCoords:Boolean);

    Public
			Constructor Create();

			Function Run:Boolean; Virtual;

			Procedure Terminate(ForceClose:Boolean = False);Virtual;

      Procedure AddRectEvent(Action:Integer; X1,Y1,X2,Y2:Single); Overload;
      Procedure AddVectorEvent(Action:Integer; X,Y,Z:Single); Overload;
      Procedure AddCoordEvent(Action:Integer; X,Y, Value:Integer); Overload;
      Procedure AddValueEvent(Action:Integer; Value:Integer); Overload;
      Procedure AddStringEvent(Action:Integer; S:TERRAString); Overload;

      Function SetOrientation(Value:Integer):Boolean; Virtual;

			Procedure SetState(State:Cardinal); Virtual;
      Procedure Yeld; Virtual;

      Class Procedure Sleep(Time:Cardinal);

      Function SetFullscreenMode(UseFullScreen:Boolean):Boolean; Virtual;
      Procedure ToggleFullscreen;

      // ads
      Procedure EnableAds; Virtual;
      Procedure DisableAds; Virtual;
      Procedure ShowFullscreenAd; Virtual;

      Procedure OpenAppStore(AppID:TERRAString); Virtual;
      Procedure SendEmail(DestEmail, Subject, Body:TERRAString); Virtual;

      Function SaveToCloud():Boolean; Virtual;

      Function InputForceFeedback(ControllerID, PadID:Integer; Duration:Integer):Boolean; Virtual;

      Function HasInternet:Boolean; Virtual;

      Function HasFatalError:Boolean;
      Function GetCrashLog():TERRAString; Virtual;

      Function PostCallback(Callback:ApplicationCallback; Arg:TERRAObject = Nil; Const Delay:Cardinal = 0):Boolean;
      Procedure CancelCallback(Arg:Pointer);

      Class Function GetOption(Const OptName:TERRAString):TERRAString;
      Class Function HasOption(Const OptName:TERRAString):Boolean;

      //analytics
      Procedure SendAnalytics(EventName:TERRAString); {$IFNDEF OXYGENE}Overload; {$ENDIF} Virtual;
      Procedure SendAnalytics(EventName:TERRAString; Parameters:TERRAString); {$IFNDEF OXYGENE}Overload;{$ENDIF} Virtual;

      // achievements
      Procedure UnlockAchievement(AchievementID:TERRAString); Virtual;

      // facebook
      Procedure PostToFacebook(msg, link, desc, imageURL:TERRAString); Virtual;
      Procedure LikeFacebookPage(page, url:TERRAString); Virtual;

      //tapjoy
      Procedure Tapjoy_ShowOfferWall(); Virtual;
      Procedure Tapjoy_ShowVideo(); Virtual;
      Procedure Tapjoy_SpendCredits(Ammount:Integer); Virtual;
      Procedure Tapjoy_Update(Credits: Integer);

      Procedure LogToConsole(Const Text:TERRAString); Virtual;

      Procedure Resize(Width, Height:Integer);

      Procedure SetSuspend(Value:Boolean);

      Procedure SetTitle(Const Name:TERRAString); Virtual;

      Procedure SetLanguage(Language:TERRAString);

      Procedure ProcessEvents;

      Function GetDeviceID():TERRAString; Virtual;

      Function GetElapsedTime:Cardinal;

      Function GetPlatform:Cardinal;

      Function CanHandleEvents:Boolean;

      Function FrameTime:Cardinal;

      Function GetRecommendedSettings():Integer; Virtual;

      Function InitAccelerometer():Boolean; Virtual;
      Function InitGyroscope():Boolean; Virtual;
      Function InitCompass():Boolean; Virtual;

      Procedure StopAccelerometer(); Virtual;
      Procedure StopGyroscope(); Virtual;
      Procedure StopCompass(); Virtual;

      Function IsAppRunning(Name:TERRAString):Boolean; Virtual;
      Function IsAppInstalled(Name:TERRAString):Boolean; Virtual;
      Function IsDeviceRooted:Boolean; Virtual;

      Function GetOrientationDelta:Single;

      Function SelectRenderer():Integer; Virtual;

			Procedure OnKeyDown(Key:Word); Virtual;
			Procedure OnKeyUp(Key:Word); Virtual;
			Procedure OnKeyPress(Key:TERRAChar); Virtual;

			Procedure OnMouseDown(Const X,Y:Single; Const Button:Word); Virtual;
			Procedure OnMouseUp(Const X,Y:Single; Const Button:Word); Virtual;
			Procedure OnMouseMove(Const X,Y:Single); Virtual;
			Procedure OnMouseWheel(Const X,Y:Single; Const Delta:Integer); Virtual;

			Procedure OnAccelerometer(X,Y,Z:Single); Virtual;
			Procedure OnGyroscope(X,Y,Z:Single); Virtual;
			Procedure OnCompass(Heading, Pitch, Roll:Single); Virtual;

      Procedure OnOrientation(Orientation:Integer); Virtual;

      Procedure OnIAP_Error(ErrorCode:Integer); Virtual;
      Procedure OnIAP_Purchase(Const ID:TERRAString); Overload; Virtual;
      Procedure OnIAP_Purchase(Credits:Integer); Overload; Virtual;
      Procedure OnIAP_External(Const PurchaseID:TERRAString; UserData:Pointer); Virtual;

      Procedure OnGamepadConnect(Index:Integer); Virtual;
      Procedure OnGamepadDisconnect(Index:Integer); Virtual;

      Procedure OnAPIResult(API, Code:Integer); Virtual;

      Procedure OnFatalError(Const ErrorMsg, CrashLog, Callstack:TERRAString); Virtual;

      Procedure OnContextLost(); Virtual;

			Procedure OnCreate; Virtual;
			Procedure OnDestroy; Virtual;
			Procedure OnIdle; Virtual;
			Procedure OnStateChange(State:Integer); Virtual;

      Procedure OnGesture(StartX, StartY, EndX, EndY, GestureType:Integer; Delta:Single); Virtual;

      {$IFNDEF DISABLEVR}
        Function GetVRProjectionMatrix(Eye:Integer; FOV, Ratio, zNear, zFar:Single):Matrix4x4; Virtual;
      {$ENDIF}

      Function GetTitle:TERRAString; Virtual;
      Function GetWidth:Word; Virtual;
      Function GetHeight:Word; Virtual;
      Function GetFullScreen:Boolean; Virtual;
      Function GetIgnoreCursor:Boolean; Virtual;
      Function GetHidden:Boolean; Virtual;
      Function GetAntialiasSamples:Integer; Virtual;
      Function GetLogging:Boolean; Virtual;

      Function GetAppID:TERRAString; Virtual;

      Function GetAdMobBannerID:TERRAString; Virtual;
      Function GetAdMobInterstitialID:TERRAString; Virtual;

      Function GetAdBuddizID:TERRAString; Virtual;

      Function GetFlurryID:TERRAString; Virtual;
      Function GetTestFlightID:TERRAString; Virtual;
      Function GetFacebookID:TERRAString; Virtual;
      Function GetBillingID:TERRAString; Virtual;

      Function GetFortumoID:TERRAString; Virtual;
      Function GetFortumoSecret:TERRAString; Virtual;

      Function GetChartboostID:TERRAString; Virtual;
      Function GetChartboostSecret:TERRAString; Virtual;

      Function GetTapjoyID:TERRAString; Virtual;
      Function GetTapjoySecret:TERRAString; Virtual;

      Function GetVungleID:TERRAString; Virtual;

      Property CPUCores:Integer Read _CPUCores;

      Property OS:Cardinal Read GetPlatform;
      Property CurrentPath:TERRAString Read _Path;
      Property TempPath:TERRAString Read GetTempPath;
      Property StoragePath:TERRAString Read GetStoragePath;
      Property DocumentPath:TERRAString Read GetDocumentPath;
      Property FontPath:TERRAString Read _FontPath;

			Property Title:TERRAString Read _Title;
			Property Width:Integer Read _Width;
			Property Height:Integer Read _Height;
			Property FullScreen:Boolean Read _Fullscreen;
      Property Language:TERRAString Read _Language Write SetLanguage;
      Property Country:TERRAString Read _Country;
      Property BundleVersion:TERRAString Read _BundleVersion;
      Property CurrentUser:TERRAString Read _CurrentUser;

      Property IsRunning:Boolean Read _Running;

      Property Paused:Boolean Read _Paused Write SetPause;
      Property CanReceiveEvents:Boolean Read _CanReceiveEvents;

      Property TapjoyCredits:Integer Read _TapjoyCredits;

      Property Orientation:Integer Read _Orientation;
      Property PreviousOrientation:Integer Read _PreviousOrientation;

      Property AspectRatio:Single Read GetAspectRatio;

      Property Screen:ApplicationScreenDimensions Read _Screen;

      Property DebuggerPresent:Boolean Read _DebuggerPresent;
	End;


Function Blink(Period:Cardinal):Boolean;

Function GetOSName(OS:Integer=0):TERRAString;
Function GetCPUName(CPUType:Integer=0):TERRAString;
Function GetProgramName():TERRAString;

Function IsLandscapeOrientation(Orientation:Integer):Boolean;
Function IsPortraitOrientation(Orientation:Integer):Boolean;
Function IsInvalidOrientation(Orientation:Integer):Boolean;

Implementation

Uses SysUtils, TERRA_Error, {$IFDEF USEDEBUGUNIT}TERRA_Debug,{$ENDIF}
  {$IFNDEF WINDOWS}BaseUnix, {$ENDIF}
  TERRA_GraphicsManager, TERRA_EngineManager, TERRA_Callstack, TERRA_Collections, TERRA_List,
  TERRA_Log, TERRA_OS, TERRA_IAP, TERRA_Localization, TERRA_FileUtils, TERRA_FileManager, TERRA_InputManager
  {$IFDEF PC}, TERRA_Steam{$ENDIF};

Var
  _Application_Ready:Boolean;

Function IsInvalidOrientation(Orientation:Integer):Boolean;
Begin
    Result := (Orientation<0) Or (Orientation>=4);
End;

Function IsLandscapeOrientation(Orientation:Integer): Boolean;
Begin
  Result := (Orientation = orientationLandscapeLeft) Or (Orientation = orientationLandscapeRight);
End;

Function IsPortraitOrientation(Orientation:Integer): Boolean;
Begin
  Result := (Orientation = orientationPortrait) Or (Orientation = orientationPortraitInverted);
End;

{ BaseApplication }
Procedure BaseApplication.ShutdownSystem;
Begin
  Engine.Release();

  _Ready := False;
  _CanReceiveEvents := False;

  {$IFNDEF DISABLEINPUTMUTEX}
  ReleaseObject(_InputMutex);
  {$ENDIF}

  ReleaseObject(_CallbackMutex);


  If (Not _Managed) Then
  Begin
    CloseWindow;
  End;

  Self.OnShutdown;
End;


procedure BaseApplication.InitSystem;
Var
  I:Integer;
  S:TERRAString;
Begin
  Log(logDebug, 'App', 'Initializing randomizer');

  {$IFNDEF OXYGENE}
  System.Randomize;
  {$ENDIF}

  {$IFDEF DEBUG_TAPJOY}
  _TapjoyCredits := 250;
  {$ELSE}
  _TapjoyCredits := 0;
  {$ENDIF}

  Log(logDebug, 'App', 'Creating critical section for input');

  {$IFNDEF DISABLEINPUTMUTEX}
  _InputMutex := CriticalSection.Create({'app_input'});
  {$ENDIF}

  _CallbackMutex := CriticalSection.Create();

  Log(logDebug, 'App', 'Initializing window');

  _Orientation := orientationPortrait;
  _OrientationTime := 0;
  _PreviousOrientation := _Orientation;

  _Ready := False;

  _BundleVersion := '0.0';

  Log(logDebug, 'App', 'Initializing settings');
  If (Not InitSettings()) Then
    Halt(0);

  _Title := Self.GetTitle();
  _Width := Self.GetWidth();
  _Height := Self.GetHeight();
  _Fullscreen := Self.GetFullscreen();
  _AntialiasSamples := Self.GetAntialiasSamples();

  {$IFDEF PC}
  If (Engine.Steam.Enabled) And (IsSupportedLanguage(Engine.Steam.Language)) Then
    _Language := Engine.Steam.Language;
  {$ENDIF}

  {$IFNDEF MOBILE}
  If (Not _Managed) Then
  {$ENDIF}
    InitWindow;

  Engine.Files.AddFolder(Application.Instance.DocumentPath);
End;

Constructor BaseApplication.Create();
Begin
  _Startup := True;
  _CanReceiveEvents := False;
  _Hidden := Self.GetHidden();
  _State := wsNormal;

  _IgnoreCursor := Self.GetIgnoreCursor();

{  _UsesAccelerometer := ApplicationSettings.UsesAccelerometer;
  _UsesGyroscope := ApplicationSettings.UsesGyroscope;
  _UsesCompass := ApplicationSettings.UsesCompass;
  _UsesGameCenter := ApplicationSettings.UsesGameCenter;}

  {$IFDEF MOBILE}
  _Managed := True;
  {$ENDIF}

  _PauseCounter := 0;

  _FatalError := '';
  _Application_Ready := True;
  Self.Run();
End;

procedure BaseApplication.Finish;
Begin
  _Running := False;

  Self.OnDestroy();

  Log(logWarning, 'App', 'Shutting down all subsystems.');
  ShutdownSystem;
  Log(logWarning, 'App', 'All subsystems destroyed.');

  {$IFNDEF OXYGENE}
  If (Not _Managed) Then
  Begin
    Self.Release();
  End;
  {$ENDIF}

  Log(logWarning, 'App', 'Application has shutdown.');
End;

procedure BaseApplication.Terminate(ForceClose: Boolean);
Begin
  If (Self = Nil) Then
    Halt;

  _Terminated := True;
  _CanReceiveEvents := False;

  {$IFNDEF MOBILE}
  If ForceClose Then
  Begin
    Self.Finish();
    Halt;
  End;
  {$ENDIF}
End;

procedure BaseApplication.Resize(Width, Height: Integer);
Var
  I:Integer;
Begin
  If (Width=0) Or (Height=0) Then
    Exit;

  _Width := Width;
  _Height := Height;

  Engine.Graphics.ResizeDevice(Width, Height);
End;

Function BaseApplication.Run: Boolean;
Begin
  If (_Terminated) Then
  Begin
    Self.Finish();
    Result := False;
    Exit;
  End;

  If (Not _Managed) And (_Running) Then
  Begin
    RaiseError('Application is already running.');
    Result := False;
    Exit;
  End;

  Result := True;
  If _Startup Then
  Begin
    Log(logDebug, 'App', 'Initializing system');

    // Create window
    InitSystem();

    _InitApp := True;
    _StartTime := GetElapsedTime();

    Engine.Init();

    _Startup := False;
    If (_Managed) Or (_Hidden) Then
      Exit;
  End;

  _Running := True;
  _FrameStart := Application.GetTime();
  Self.OnFrameBegin();
  While (_Running) And (Not _Terminated) Do
  Begin
  {$IFDEF CRASH_REPORT}
  Try
  {$ENDIF}

    {$IFDEF DEBUG_CORE}{$IFDEF EXTENDED_DEBUG}Log(logDebug, 'App', 'Processing messages');{$ENDIF}{$ENDIF}
    Self.ProcessMessages();
    {$IFDEF DEBUG_CORE}{$IFDEF EXTENDED_DEBUG}Log(logDebug, 'App', 'All messages processed');{$ENDIF}{$ENDIF}

    {$IFDEF DEBUG_CORE}{$IFDEF EXTENDED_DEBUG}Log(logDebug, 'App', 'Processing callbacks');{$ENDIF}{$ENDIF}
    Self.ProcessCallbacks();
    {$IFDEF DEBUG_CORE}{$IFDEF EXTENDED_DEBUG}Log(logDebug, 'App', 'All callbacks processed');{$ENDIF}{$ENDIF}

      If (_InitApp) Then
      Begin
        Self.OnCreate();
        _InitApp := False;
        _CanReceiveEvents := True;
      End Else
      Begin
        Self.ProcessEvents();

        If _FatalError<>'' Then
        Begin
          {$IFDEF DEBUG_CORE}{$IFDEF EXTENDED_DEBUG}Log(logWarning, 'App', 'Fatal error!!!!');{$ENDIF}{$ENDIF}
          If (Engine.Input.Keys.IsDown(keyEscape)) Then
            Self.Terminate(False);
        End Else
        Begin
          {$IFDEF DEBUG_CORE}{$IFDEF EXTENDED_DEBUG}Log(logDebug, 'App', 'Callind client.OnIdle()');{$ENDIF}{$ENDIF}
          Self.OnIdle();
        End;

        {$IFDEF DEBUG_CORE}{$IFDEF EXTENDED_DEBUG}Log(logDebug, 'App', 'client.OnIdle() finished');{$ENDIF}{$ENDIF}
      End;

    If (_ContextWasLost) Then
    Begin
      _ContextWasLost := False;
      Engine.OnContextLost();
      Self.OnContextLost();
    End;

      _FrameStart := Application.GetTime();

    {$IFDEF DEBUG_CORE}{$IFDEF EXTENDED_DEBUG}Log(logDebug, 'App', 'Refreshing Components');{$ENDIF}{$ENDIF}
    If Not _Suspended Then
      Engine.Update();


    {$IFDEF DEBUG_CORE}{$IFDEF EXTENDED_DEBUG}Log(logDebug, 'App', 'Swapping buffers');{$ENDIF}{$ENDIF}
    If (_ChangeToFullScreen) Then
    Begin
	    _ChangeToFullScreen := False;
	    ToggleFullScreen();
    End;

    Self.OnFrameEnd();

    If (_Managed) Then
      Exit;

  {$IFDEF CRASH_REPORT}
  Except
    On E : Exception do
    Begin
      //FillCallStack(St, 0);
      Log(logError, 'Application', 'Exception: '+E.ClassName +' '+E.Message);
      Self.OnFatalError(CrLf+E.Message, Self.GetCrashLog(), DumpExceptionCallStack(E));
      Exit;
    End;
  End;
  {$ENDIF}
End;

  Log(logDebug, 'App', 'Application is finishing...');

  Self.Finish();
  Result := False;
End;

Function GetCPUName(CPUType:Integer=0):TERRAString;
Begin
  If (CPUType = 0) Then
  Begin
    {$IFDEF PC}
    CPUType := cpuX86_32;
    {$ENDIF}

    {$IFDEF MOBILE}
    CPUType := cpuArm_32;
    {$ENDIF}
  End;

  Case CPUType Of
  cpuX86_32: Result := 'x86_32';
  cpuX86_64: Result := 'x86_64';

  cpuArm_32: Result := 'ARM_32';
  cpuArm_64: Result := 'ARM_64';

  Else
    Result := 'Unknown';
  End;
End;

Function GetOSName(OS:Integer=0):TERRAString;
Begin
  If (OS = 0) Then
    OS := Application.Instance.GetPlatform();

  Case OS Of
  osWindows:Result := 'Windows';
  osLinux:  Result := 'Linux';
  osOSX:  Result := 'OSX';
  osWindowsPhone:    Result := 'WP8';
  osiOS:    Result := 'iOS';
  osAndroid:Result := 'Android';
  osOuya:   Result := 'Ouya';
  Else
    Result := 'Unknown';
  End;
End;

function BaseApplication.SetFullscreenMode(UseFullScreen: Boolean): Boolean;
Begin
  Log(logError, 'App','ToggleFullscreen not implemented!');
  Result := False;
End;

procedure BaseApplication.ToggleFullscreen;
Var
   NewMode:Boolean;
Begin
  NewMode := Not Self._Fullscreen;
  If SetFullscreenMode(NewMode) Then
    Self._Fullscreen := NewMode;
End;

procedure BaseApplication.SetState(State: Cardinal);
Begin
 Log(logError, 'App','SetState not implemented!');
End;

procedure BaseApplication.Yeld;
Begin
 Log(logError, 'App','Yeld not implemented!');
End;

procedure BaseApplication.SetPause(Value: Boolean);
Var
  N:Cardinal;
Begin
  If (Value = _Paused) Then
    Exit;

  If Value Then
  Begin
    _PauseStart := Self.GetElapsedTime();
    _Paused := True;
  End Else
  Begin
    _Paused := False;
    N := Self.GetElapsedTime();
    Dec(N, _PauseStart);
    Inc(_PauseCounter, N);
  End;
End;

function BaseApplication.GetElapsedTime: Cardinal;
Begin
  If (Application.Instance.Paused) Then
    Result := _PauseStart
  Else
    Result := Application.GetTime() - _PauseCounter;
End;

// do nothing
procedure BaseApplication.EnableAds; Begin End;
procedure BaseApplication.DisableAds; Begin End;

procedure BaseApplication.OpenAppStore(AppID: TERRAString); Begin End;

Procedure BaseApplication.LogToConsole(const Text: TERRAString);
Begin
  // do nothing
End;

Function BaseApplication.GetCrashLog: TERRAString;
Begin
  Result :=
    'OS: '+GetOSName() + CrLf +
    'CPU: '+GetCPUName() + CrLf +
    'Cores: '+ IntegerProperty.Stringify(Self.CPUCores) + CrLf +
    'Width: '+ IntegerProperty.Stringify(Self.Width) + CrLf +
    'Height: '+ IntegerProperty.Stringify(Self.Height) + CrLf +
    'Lang: '+ Self.Language + CrLf +
    'Country: '+ Self.Country + CrLf +
    'Bundle: '+ Self.BundleVersion + CrLf;
End;

Procedure BaseApplication.OnFrameBegin;
Begin
  // do nothing
End;

Procedure BaseApplication.OnFrameEnd;
Begin
  // do nothing
End;


procedure BaseApplication.SendAnalytics(EventName: TERRAString; Parameters: TERRAString); Begin End;
procedure BaseApplication.UnlockAchievement(AchievementID: TERRAString); Begin End;
function BaseApplication.IsDebuggerPresent: Boolean; Begin Result := False; End;


Function Blink(Period:Cardinal):Boolean;
Begin
  Result := ((Application.GetTime() Shr 4) Mod Period<(Period Shr 1));
End;

Function GetProgramName:TERRAString;
Begin
    {$IFDEF OXYGENE}
    Result := 'TERRA';
    {$ELSE}
  Result := GetFileName(ParamStr(0), True);
  //Result := CapStr(Result);
    {$ENDIF}
End;

procedure BaseApplication.OnShutdown;
Begin

End;

procedure BaseApplication.PostToFacebook(msg, link, desc, imageURL: TERRAString);
Begin
  Self.OnAPIResult(apiFacebook, facebookConnectionError);
End;

procedure BaseApplication.LikeFacebookPage(page, url: TERRAString);
Begin
  Self.OnAPIResult(apiFacebook, facebookLikeError);
End;

procedure BaseApplication.SetTitle(const Name: TERRAString);
Begin
	If (Name = _Title) Or (Name='') Then
		Exit;
		
	_Title := Name;
End;

procedure BaseApplication.SetSuspend(Value: Boolean);
Var
  I:Integer;
Begin
  If (Value = _Suspended) Then
    Exit;

  _Suspended := Value;
  Log(logDebug, 'App', 'Suspend state = '+BoolToString(Value));

(*  If (_Suspended) Then
    _ApplicationComponents[I].Instance.Suspend()
  Else
    _ApplicationComponents[I].Instance.Resume();*)
End;

function BaseApplication.CanHandleEvents: Boolean;
Begin
  Result := _CanReceiveEvents;
End;

Class Procedure BaseApplication.Sleep(Time:Cardinal);
Var
  T, Delta:Cardinal;
Begin
  T := Application.GetTime();
  Repeat
    Delta := Application.GetTime() - T;
  Until (Delta >= Time);
End;

procedure BaseApplication.ShowFullscreenAd;
Begin
  // do nothing
End;

function BaseApplication.IsAppRunning(Name: TERRAString): Boolean;
Begin
  Result := False;
End;

function BaseApplication.IsAppInstalled(Name: TERRAString): Boolean;
Begin
  Result := False;
End;

function BaseApplication.GetPlatform: Cardinal;
Begin
	Result := osUnknown;
  
	{$IFDEF WINDOWS}
  Result := osWindows;
  {$ENDIF}

	{$IFDEF LINUX}
  Result := osLinux;
  {$ENDIF}

	{$IFDEF OSX}
  Result := osOSX;
  {$ENDIF}

	{$IFDEF ANDROID}
  Result := osAndroid;
  {$ENDIF}

	{$IFDEF OUYA}
  Result := osOuya;
  {$ENDIF}

	{$IFDEF IPHONE}
  Result := osIOS;
  {$ENDIF}

	{$IFDEF WINDOWS_PHONE}
  Result := osWindowsPhone;
  {$ENDIF}
End;

function BaseApplication.GetDeviceID: TERRAString;
Begin
  Result := '';
End;

procedure BaseApplication.SendEmail(DestEmail, Subject, Body: TERRAString);
Begin
End;

function BaseApplication.IsDeviceRooted: Boolean;
Begin
  Result := False;
End;

function BaseApplication.HasInternet: Boolean;
Begin
  Result := True;
End;


procedure BaseApplication.SendAnalytics(EventName: TERRAString);
Begin
  Self.SendAnalytics(EventName, '');
End;

function BaseApplication.InitAccelerometer: Boolean;
Begin
  Result := False;
End;

function BaseApplication.InitCompass: Boolean;
Begin
  Result := False;
End;

function BaseApplication.InitGyroscope: Boolean;
Begin
  Result := False;
End;

procedure BaseApplication.StopAccelerometer;
Begin
  // do nothing
End;

procedure BaseApplication.StopCompass;
Begin
  // do nothing
End;

procedure BaseApplication.StopGyroscope;
Begin
  // do nothing
End;

procedure BaseApplication.SetLanguage(Language: TERRAString);
Begin
  If (Language = Self._Language) Then
    Exit;

  Self._Language := Language;
End;

{$IFDEF FPC}
Procedure CatchUnhandledException(Obj: TObject; Addr: Pointer; FrameCount: Longint; Frames: PPointer);
Var
  Result:TERRAString;
  I:Integer;
Begin
  Result := 'An unhandled exception occurred at 0x'+ HexStr(PtrUInt(Addr))+ CrLf;
  If Obj is Exception then
  Begin
     Result := Result + Exception(Obj).ClassName + ' : ' + Exception(Obj).Message;
  End;
  Result := Result + BackTraceStrFunc(Addr) + CrLf;
  For I:=0 To Pred(FrameCount) Do
    Result := Result + BackTraceStrFunc(Frames[i]) + CrLf;

  Log(logError, 'App', Result);
  Halt();
End;
{$ENDIF}

Function BaseApplication.HasFatalError: Boolean;
Begin
  Result := _FatalError<>'';
End;

function BaseApplication.SetOrientation(Value: Integer): Boolean;
Var
  Delta:Single;
  I:Integer;
Begin
  Result := False;

  If (IsInvalidOrientation(Value)) Then
    Begin
        Log(logDebug, 'App', 'Invalid orientation change: '+ IntegerProperty.Stringify(Value));
        Exit;
    End;

  Delta := GetOrientationDelta();
If (_Orientation = Value) {Or (Delta<1)} Then
  Begin
    Log(logDebug, 'App', 'Failed orientation change (delta='+FloatProperty.Stringify(Delta)+')');
    Exit;
  End;

  Log(logDebug, 'App', 'Changing orientation to '+  IntegerProperty.Stringify(Value));
  _PreviousOrientation := _Orientation;
  _OrientationTime := Application.GetTime();
  _Orientation := Value;

    Case _Orientation Of
    orientationLandscapeLeft:
    Begin
        Log(logDebug, 'App', 'Changing orientation to landscape-left');
    End;

    orientationLandscapeRight:
    Begin
        Log(logDebug, 'App', 'Changing orientation to landscape-right');
    End;

    orientationPortrait:
    Begin
        Log(logDebug, 'App', 'Changing orientation to portrait');
    End;

    orientationPortraitInverted:
    Begin
        Log(logDebug, 'App', 'Changing orientation to portrait-inverted');
    End;
End;


(*      _ApplicationComponents[I].Instance.OnOrientationChange();
*)

  Result := True;
End;

function BaseApplication.GetOrientationDelta: Single;
Begin
  Result := Application.GetTime() - _OrientationTime;
  Result := Result / OrientationAnimationDuration;
  If (Result>1) Then
    Result := 1
  Else
  If (Result<0) Then
    Result := 0;
End;

procedure BaseApplication.ConvertCoords(var X, Y:Single);
Var
  PX, PY:Single;
  SX, SY:Single;
  Temp:Single;
Begin
  Case _Orientation Of
  orientationLandscapeLeft:
    Begin
      Temp := X;
      X := Y;
      Y := Self.Height - Temp;
    End;

  orientationLandscapeRight:
    Begin
      Temp := X;
      X := Self.Height - Y;
      Y := Temp;
    End;

  orientationPortrait:
    Begin
    End;

  orientationPortraitInverted:
    Begin
      X := Self.Width - X;
      Y := Self.Height - Y;
    End;
  End;

  X := X / Self.Width;
  Y := Y / Self.Height;
End;

procedure BaseApplication.AddEventToQueue(Action: Integer; X, Y, Z, W: Single;
  Value: Integer; S: TERRAString; HasCoords: Boolean);
Var
  N:Integer;
Begin
  If Not _CanReceiveEvents Then
    Exit;

  {$IFDEF DEBUG_CORE}{$IFDEF EXTENDED_DEBUG}Log(logDebug, 'App', 'Locking event mutex');{$ENDIF}{$ENDIF}

  {$IFNDEF DISABLEINPUTMUTEX}
  _InputMutex.Lock();
  {$ENDIF}


  N := _EventCount;
  If N<Pred(EventBufferSize) Then
  Begin
       {$IFDEF DEBUG_CORE}{$IFDEF EXTENDED_DEBUG}Log(logDebug, 'App', 'Adding event with index '+ IntegerProperty.Stringify(N));{$ENDIF}{$ENDIF}
       Inc(_EventCount);
      _Events[N].X := X;
      _Events[N].Y := Y;
      _Events[N].Z := Z;
      _Events[N].W := W;
      _Events[N].S := S;
      _Events[N].HasCoords := HasCoords;
      _Events[N].Value := Value;
      _Events[N].Action := Action;
  End;
  {$IFDEF DEBUG_CORE}{$IFDEF EXTENDED_DEBUG}Log(logDebug, 'App', 'Unlocking event mutex');{$ENDIF}{$ENDIF}

  {$IFNDEF DISABLEINPUTMUTEX}
  _InputMutex.Unlock();
  {$ENDIF}
End;


procedure BaseApplication.AddRectEvent(Action: Integer; X1, Y1, X2, Y2: Single);
Begin
  Self.AddEventToQueue(Action, X1, Y1, X2, Y2, 0, '', True);
End;

procedure BaseApplication.AddVectorEvent(Action: Integer; X, Y, Z: Single);
Begin
  Self.AddEventToQueue(Action, X, Y, Z, 0, 0,  '', True);
End;

procedure BaseApplication.AddCoordEvent(Action: Integer; X, Y, Value: Integer);
Begin
  Self.AddEventToQueue(Action, X, Y, 0, 0, Value, '', True);
End;

procedure BaseApplication.AddValueEvent(Action: Integer; Value: Integer);
Begin
  Self.AddEventToQueue(Action, 0, 0, 0, 0, Value, '', False);
End;

procedure BaseApplication.AddStringEvent(Action: Integer; S: TERRAString);
Begin
  Self.AddEventToQueue(Action, 0, 0, 0, 0, 0, S, False);
End;

{$IFDEF DEBUG_CORE}
Function GetEventTypeName(N:Integer):TERRAString;
Begin
  Case N Of
  eventMouseUp   : Result := 'eventMouseUp';
  eventMouseDown : Result := 'eventMouseDown';
  eventMouseMove : Result := 'eventMouseMove';
  eventMouseWheel : Result := 'eventMouseWheel';
  eventKeyPress   : Result := 'eventKeyPress';
  eventKeyDown    : Result := 'eventKeyDown';
  eventKeyUp      : Result := 'eventKeyUp';
  eventWindowResize   : Result := 'eventWindowResize';
  eventAccelerometer  : Result := 'eventAccelerometer';
  eventGyroscope      : Result := 'eventGyroscope';
  eventCompass        : Result := 'eventCompass';
  eventContextLost    : Result := 'eventContextLost';
  eventOrientation    : Result := 'eventOrientation';
  eventViewport       : Result := 'eventViewport';
  eventIAPPurchase    : Result := 'eventIAPPurchase';
  eventIAPCredits     : Result := 'eventIAPCredits';
  eventIAPError       : Result := 'eventIAPError';
  Else
    Result := '#'+ IntegerProperty.Stringify(N);
  End;
End;
{$ENDIF}

procedure BaseApplication.ProcessEvents;
Var
  I:Integer;
  PX,PY:Single;
  NewW, NewH:Integer;
  Input:InputManager;
Begin
  {$IFNDEF DISABLEINPUTMUTEX}
  _InputMutex.Lock();
  {$ENDIF}

  Input := Engine.Input;

  {$IFDEF DEBUG_CORE}{$IFDEF EXTENDED_DEBUG}Log(logDebug, 'App', 'Processing '+ IntegerProperty.Stringify(_EventCount)+ ' events.');{$ENDIF}{$ENDIF}
  For I:=0 To Pred(_EventCount) Do
  Begin
    If (_Events[I].HasCoords) Then
    Begin
      PX := _Events[I].X;
      PY := _Events[I].Y;

      Self.ConvertCoords(PX, PY);

      Input.Mouse.X := PX;
      Input.Mouse.Y := PY;
    End;

    {$IFDEF DEBUG_CORE}Log(logDebug, 'App', 'Events type: '+GetEventTypeName(_Events[I].Action));{$ENDIF}

    Case _Events[I].Action Of
    eventMouseDown:
      Begin
        {$IFDEF DEBUG_CORE}Log(logDebug, 'App', 'Mouse down, X:'+ IntegerProperty.Stringify(Input.Mouse.X)+ ' Y:'+ IntegerProperty.Stringify(Input.Mouse.Y));{$ENDIF}
        Input.Keys.SetState(_Events[I].Value, True);

        {Log(logDebug, 'App', 'Mouse down, X:'+ IntegerProperty.Stringify(Input.Mouse.X)+ ' Y:'+ IntegerProperty.Stringify(Input.Mouse.Y));
        Log(logDebug, 'App', 'DeviceX1:'+ IntegerProperty.Stringify(_DeviceX1)+ ' DeviceY1:'+ IntegerProperty.Stringify(_DeviceY1));
        Log(logDebug, 'App', 'DeviceX2:'+ IntegerProperty.Stringify(_DeviceX2)+ ' DeviceY2:'+ IntegerProperty.Stringify(_DeviceY2));
        Log(logDebug, 'App', 'DeviceWidth:'+ IntegerProperty.Stringify(_DeviceWidth)+ ' DeviceHeight:'+ IntegerProperty.Stringify(_DeviceHeight));
        }

        {If (_MouseOnAdArea) Then
          Self.OnAdClick(Input.Mouse.X, Input.Mouse.Y)
        Else}
          Self.OnMouseDown(Input.Mouse.X, Input.Mouse.Y, _Events[I].Value);
      End;

    eventMouseUp:
      Begin
        {$IFDEF DEBUG_CORE}Log(logDebug, 'App', 'Mouse up, X:'+ IntegerProperty.Stringify(Input.Mouse.X)+ ' Y:'+ IntegerProperty.Stringify(Input.Mouse.Y));{$ENDIF}

        Input.Keys.SetState(_Events[I].Value, False);
        Self.OnMouseUp(Input.Mouse.X, Input.Mouse.Y, _Events[I].Value);
      End;

    eventMouseMove:
      Begin
        Self.OnMouseMove(Input.Mouse.X, Input.Mouse.Y);
      End;

    eventMouseWheel:
      Begin
        Self.OnMouseWheel(Input.Mouse.X, Input.Mouse.Y, _Events[I].Value);
      End;

    eventKeyPress:
      Begin
        Self.OnKeyPress(TERRAChar(_Events[I].Value));
      End;

    eventKeyDown:
      Begin
        Input.Keys.SetState(_Events[I].Value, True);
      End;

    eventKeyUp:
      Begin
        Input.Keys.SetState(_Events[I].Value, False);
      End;

    eventWindowResize:
      Begin
        Self.Resize(Trunc(_Events[I].X), Trunc(_Events[I].Y));
      End;

    eventAccelerometer:
      Begin
        Input.Accelerometer.X := _Events[I].X;
        Input.Accelerometer.Y := _Events[I].Y;
        Input.Accelerometer.Z := _Events[I].Z;

        Self.OnAccelerometer(Input.Accelerometer.X, Input.Accelerometer.Y, Input.Accelerometer.Z);
      End;

    eventGyroscope:
      Begin
        Input.Gyroscope.X := _Events[I].X;
        Input.Gyroscope.Y := _Events[I].Y;
        Input.Gyroscope.Z := _Events[I].Z;

        Self.OnGyroscope(Input.Gyroscope.X, Input.Gyroscope.Y, Input.Gyroscope.Z);
      End;

    eventCompass:
      Begin
        Input.Compass.X := _Events[I].X;
        Input.Compass.Y := _Events[I].Y;
        Input.Compass.Z := _Events[I].Z;

        Self.OnCompass(Input.Compass.X, Input.Compass.Y, Input.Compass.Z);
      End;

    eventContextLost:
      Begin
        Log(logDebug, 'App', 'App context was lost...');
        _ContextWasLost := True;
      End;

    eventOrientation:
      Begin
        Log(logDebug, 'App', 'Orientation request: ' +  IntegerProperty.Stringify(_Events[I].Value));
        Self.OnOrientation(_Events[I].Value);
      End;

    eventIAPPurchase:
      If _Events[I].S<>'' Then
      Begin
        Log(logDebug, 'App', 'In-app-purchase: ' + _Events[I].S);
        Self.OnIAP_Purchase(_Events[I].S);
      End Else
      Begin
        _Events[I].Value := IAP_PurchaseCanceled;
        Log(logDebug, 'App', 'In-app-purchase error: ' +  IntegerProperty.Stringify(_Events[I].Value));
        Self.OnIAP_Error(_Events[I].Value);
      End;

    eventIAPCredits:
      If (_Events[I].Value>0) Then
      Begin
        Log(logDebug, 'App', 'In-app-purchase: ' +  IntegerProperty.Stringify(_Events[I].Value) + ' credits');
        Self.OnIAP_Purchase(_Events[I].Value);
      End;

    eventIAPError:
      Begin
        Log(logDebug, 'App', 'In-app-purchase error: ' +  IntegerProperty.Stringify(_Events[I].Value));
        Self.OnIAP_Error(_Events[I].Value);
      End;

    End;
  End;

  {$IFDEF DEBUG_CORE}{$IFDEF EXTENDED_DEBUG}Log(logDebug, 'App', 'Events processed!');{$ENDIF}{$ENDIF}
  _EventCount := 0;

  {$IFNDEF DISABLEINPUTMUTEX}
  _InputMutex.Unlock();
  {$ENDIF}
End;

procedure BaseApplication.ProcessMessages;
Begin
  // do nothing
End;

function BaseApplication.SaveToCloud: Boolean;
Begin
  Result := False;
End;

Function BaseApplication.InputForceFeedback(ControllerID, PadID: Integer; Duration: Integer):Boolean;
Begin
     Result := False;
End;

function BaseApplication.GetRecommendedSettings: Integer;
Begin
  If (Self.Width<480) Or (Self.Height<480) Then
    Result := settingsHintLow
  Else
    Result := settingsHintMedium;
End;

procedure BaseApplication.Tapjoy_ShowOfferWall;
Begin
  Self.OnAPIResult(apiTapJoy, tapjoyConnectionError);
End;

procedure BaseApplication.Tapjoy_ShowVideo;
Begin
  Self.OnAPIResult(apiTapJoy, tapjoyConnectionError);
End;

procedure BaseApplication.Tapjoy_SpendCredits(Ammount: Integer);
Begin
  {$IFDEF DEBUG_TAPJOY}
  Self.OnAPIResult(apiTapJoy, tapjoySpendSuccess);
  {$ELSE}
  Self.OnAPIResult(apiTapJoy, tapjoyConnectionError);
  {$ENDIF}
End;

procedure BaseApplication.Tapjoy_Update(Credits: Integer);
Begin
  _TapjoyCredits := IntMax(0, Credits);
End;

function BaseApplication.GetDocumentPath: TERRAString;
Begin
  Result := _DocumentPath;
End;

function BaseApplication.GetStoragePath: TERRAString;
Begin
  Result := _StoragePath;
End;

function BaseApplication.GetTempPath: TERRAString;
Begin
  Result := _TempPath;
End;

function BaseApplication.FrameTime: Cardinal;
Begin
  Result := Application.GetTime() - _FrameStart;
End;

Function BaseApplication.GetAspectRatio: Single;
Begin
  Result := SafeDiv(_Height, _Width, 1.0);
End;

Function BaseApplication.PostCallback(Callback:ApplicationCallback; Arg:TERRAObject; Const Delay:Cardinal):Boolean;
Begin 
  If (_CallbackCount>=CallbackBufferSize) Then
  Begin
    Result := False;
    Exit;
  End;

  _CallbackMutex.Lock();
  _Callbacks[_CallbackCount].Run := Callback;
  _Callbacks[_CallbackCount].Time := Application.GetTime() + Delay;
  _Callbacks[_CallbackCount].Delay := Delay;
  _Callbacks[_CallbackCount].Arg := Arg;
  _Callbacks[_CallbackCount].Canceled := False;
  Inc(_CallbackCount);
  _CallbackMutex.Unlock();

  Result := True;
End;

Procedure BaseApplication.ProcessCallbacks();
Var
  I:Integer;
Begin
  _CallbackMutex.Lock();
  For I:=0 To Pred(_CallbackCount) Do
  Begin
    If (_Callbacks[I].Canceled) Then
      Continue;

    If (_Callbacks[I].Time <= Application.GetTime()) Then
    Begin
      Log(logDebug, 'Game','Executing callback...');

      If _Callbacks[I].Run(_Callbacks[I].Arg) Then
      Begin
        _Callbacks[I].Time := Application.GetTime() + _Callbacks[I].Delay;
      End Else
        _Callbacks[I].Canceled := True;
    End;
  End;

  While (I<_CallbackCount) Do
  If (_Callbacks[I].Canceled) Then
  Begin
    _Callbacks[Pred(_CallbackCount)] := _Callbacks[I];
    Dec(_CallbackCount);
  End Else
    Inc(I);

  _CallbackMutex.Unlock();
End;

Procedure BaseApplication.CancelCallback(Arg:Pointer);
Var
  I:Integer;
Begin
  _CallbackMutex.Lock();
  For I:=0 To Pred(_CallbackCount) Do
  If (_Callbacks[I].Arg = Arg) Then
  Begin
    _Callbacks[I].Canceled := True;
  End;
  _CallbackMutex.Unlock();
End;

{$IFNDEF WINDOWS}
Procedure DoSig(sig:Integer); cdecl;
Begin
   RaiseError('Segmentation fault');
End;
{$ENDIF}

Function BaseApplication.InitSettings: Boolean;
{$IFNDEF WINDOWS}
Var
  oa,na : PSigActionRec;
{$ENDIF}
Begin
  Log(logDebug, 'App', 'Initializing app path');
  {$IFDEF OXYGENE}
  _Path := System.IO.Directory.GetCurrentDirectory();
  {$ELSE}
  GetDir(0, _Path);
  {$ENDIF}
  _Language := 'EN';


  _DebuggerPresent := Self.IsDebuggerPresent();

{$IFDEF INSTALL_SIGNAL}
  Log(logDebug, 'App', 'Installing signals');
  new(na);
  new(oa);
  FillChar(Na^, SizeOf(Na), 0);
  na^.sa_Handler := SigActionHandler(@DoSig);
  FillChar(na^.Sa_Mask, SizeOf(na^.sa_mask), #0);
  na^.Sa_Flags:=0;
  fpSigAction(SIGSEGV, na, oa);
{$ENDIF}

  _CPUCores := 1;

  Result := True;
End;

Class Function BaseApplication.HasOption(Const OptName:TERRAString):Boolean;
Var
  I:Integer;
  S, S2:TERRAString;
Begin
  {$IFDEF PC}
  For I:=1 To ParamCount Do
  Begin
    S := ParamStr(I);
    If (StringFirstChar(S) <> '-') Then
      Continue;

    S2 := StringGetNextSplit(S, '=');
    If StringEquals(S2, '-'+OptName) Then
    Begin
      Result := True;
      Exit;
    End;
  End;
  {$ENDIF}
  Result := False;
End;

Class Function BaseApplication.GetOption(const OptName: TERRAString): TERRAString;
Var
  I:Integer;
  S, S2:TERRAString;
Begin
  Result := '';
  {$IFDEF PC}
  For I:=1 To ParamCount Do
  Begin
    S := ParamStr(I);
    If (StringFirstChar(S) <> '-') Then
      Continue;

    S2 := StringGetNextSplit(S, '=');
    If StringEquals(S2, '-'+OptName) Then
    Begin
      Result := S;
      Exit;
    End;
  End;
  {$ENDIF}
End;

Procedure BaseApplication.OnAccelerometer(X, Y, Z: Single);
Begin

End;

Procedure BaseApplication.OnCreate;
Begin

End;

Procedure BaseApplication.OnDestroy;
Begin

End;

Procedure BaseApplication.OnAPIResult(API, Code:Integer);
Begin

End;

Procedure BaseApplication.OnGesture(StartX, StartY, EndX, EndY, GestureType: Integer; Delta:Single);
Begin

End;

Procedure BaseApplication.OnIAP_Error(ErrorCode:Integer);
Begin
  Log(logWarning, 'Client', 'Please implement Self.OnIAP_Cancel, error code = '+ IntegerProperty.Stringify(ErrorCode));
End;

Procedure BaseApplication.OnIAP_Purchase(Const ID:TERRAString);
Begin
  Log(logWarning, 'Client', 'Please implement Self.OnIAP_Purchase, product ID = '+ID);
End;

Procedure BaseApplication.OnIAP_Purchase(Credits: Integer);
Begin
  Log(logWarning, 'Client', 'Please implement Self.OnIAP_Purchase, credits  = '+ IntegerProperty.Stringify(Credits));
End;

Procedure BaseApplication.OnIdle;
Begin

End;

Procedure BaseApplication.OnKeyDown(Key: Word);
Begin
  If Key = keyEscape  Then
    Application.Instance.Terminate;
End;

Procedure BaseApplication.OnKeyPress(Key:TERRAChar);
Begin

End;

Procedure BaseApplication.OnKeyUp(Key: Word);
Begin

End;

Procedure BaseApplication.OnContextLost;
Begin
  // Do nothing
End;

Procedure BaseApplication.OnMouseDown(Const X,Y:Single; Const Button:Word);
Begin
//  UI.Instance.OnMouseDown(X, Y, Button);
End;

Procedure BaseApplication.OnMouseMove(Const X,Y:Single);
Begin
//  UI.Instance.OnMouseMove(X, Y);
End;

Procedure BaseApplication.OnMouseUp(Const X,Y:Single; Const Button: Word);
Begin
//  UI.Instance.OnMouseUp(X, Y, Button);
End;

Procedure BaseApplication.OnMouseWheel(Const X,Y:Single; Const Delta: Integer);
Begin
//  UI.Instance.OnMouseWheel(Delta);
End;

Procedure BaseApplication.OnStateChange(State: Integer);
Begin

End;

Procedure BaseApplication.OnCompass(Heading, Pitch, Roll: Single);
Begin
End;

Procedure BaseApplication.OnGyroscope(X, Y, Z: Single);
Begin
End;


Procedure BaseApplication.OnOrientation(Orientation: Integer);
Begin
  Application.Instance.SetOrientation(Orientation);
End;

Function BaseApplication.GetAntialiasSamples: Integer;
Begin
  Result := 0;
End;

Function BaseApplication.GetAppID:TERRAString;
Begin
  Result := '0001';
End;

Function BaseApplication.GetBillingID:TERRAString;
Begin
  Result := '';
End;

Function BaseApplication.GetFacebookID:TERRAString;
Begin
  Result := '';
End;

function BaseApplication.GetFlurryID:TERRAString;
Begin
  Result := '';
End;

Function BaseApplication.GetFullScreen: Boolean;
Begin
  Result := False;
End;

Function BaseApplication.GetWidth: Word;
Begin
  Result := 960;
End;

Function BaseApplication.GetHeight: Word;
Begin
  Result := 640;
End;

Function BaseApplication.GetHidden: Boolean;
Begin
  Result := False;
End;

Function BaseApplication.GetIgnoreCursor: Boolean;
Begin
  Result := True;
End;


Procedure BaseApplication.OnFatalError(Const ErrorMsg, CrashLog, Callstack:TERRAString); 
Begin
  _Running := False;
End;

Procedure BaseApplication.OnIAP_External(Const PurchaseID:TERRAString; UserData:Pointer);
Begin
  Self.OnIAP_Error(-1);
End;

Function BaseApplication.GetAdMobBannerID:TERRAString;
Begin
  Result := '';
End;

Function BaseApplication.GetAdMobInterstitialID:TERRAString;
Begin
  Result := '';
End;

Function BaseApplication.GetLogging: Boolean;
Begin
  Result := True;
End;

Function BaseApplication.GetFortumoID:TERRAString;
Begin
  Result := '';
End;

Function BaseApplication.GetFortumoSecret:TERRAString;
Begin
  Result := '';
End;

Function BaseApplication.GetTestFlightID:TERRAString;
Begin
  Result := '';
End;

Function BaseApplication.GetTitle:TERRAString;
Begin
  Result := GetProgramName();
End;

Function BaseApplication.GetTapjoyID: TERRAString;
Begin
  Result := '';
End;

Function BaseApplication.GetTapjoySecret: TERRAString;
Begin
  Result := '';
End;

Function BaseApplication.GetChartboostID: TERRAString;
Begin
  Result := '';
End;

Function BaseApplication.GetChartboostSecret: TERRAString;
Begin
  Result := '';
End;

Function BaseApplication.GetAdBuddizID: TERRAString;
Begin
  Result := '';
End;

Function BaseApplication.GetVungleID: TERRAString;
Begin
  Result := '';
End;

Procedure BaseApplication.OnGamepadConnect(Index: Integer);
Begin
  Log(logDebug, 'Client', 'Gamepad '+ IntegerProperty.Stringify(Index)+' was connected!');
End;

Procedure BaseApplication.OnGamepadDisconnect(Index: Integer);
Begin
  Log(logDebug, 'Client', 'Gamepad '+ IntegerProperty.Stringify(Index)+' was disconnected!');
End;

{$IFNDEF DISABLEVR}
Function BaseApplication.GetVRProjectionMatrix(Eye: Integer; FOV, Ratio, zNear, zFar: Single): Matrix4x4;
Begin
  Result := Matrix4x4Perspective(FOV, Ratio, zNear, zFar);
End;
{$ENDIF}

Function BaseApplication.SelectRenderer: Integer;
Begin
  Result := 1; // select default renderer for this platform
End;


(*{ FolderManager }
Procedure FolderManager.AddWatcher(Notifier: AssetWatchNotifier);
Begin
  Inc(_NotifierCount);
  SetLength(_Notifiers, _NotifierCount);
  _Notifiers[Pred(_NotifierCount)] := Notifier;
End;

Class Function FolderManager.Instance: FolderManager;
Begin
  If Assigned(_Application_Instance) Then
    Result := _Application_Instance._FolderManager
  Else
    Result := Nil;
End;

Procedure FolderManager.NotifyFileChange(const FileName: TERRAString);
Var
  I:Integer;
Begin
  For I:=0 To Pred(_NotifierCount) Do
    _Notifiers[I](FileName);
End;

Function FolderManager.WatchFolder(const Path: TERRAString):Boolean;
Begin
  // do nothing
  Result := False;
End;*)


Initialization
  {$IFDEF FPC}
  ExceptProc := CatchUnhandledException;
  {$ENDIF}

Finalization
  //ShutdownComponents;
End.
