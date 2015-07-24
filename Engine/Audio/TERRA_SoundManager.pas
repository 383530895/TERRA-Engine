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
 * TERRA_SoundManager
 * Implements the global sound manager
 ***********************************************************************************************************************
}
Unit TERRA_SoundManager;
{$I terra.inc}
Interface
Uses {$IFDEF USEDEBUGUNIT}TERRA_Debug,{$ENDIF}
  TERRA_String, TERRA_Utils, TERRA_Sound, TERRA_Application, TERRA_Collections, TERRA_Vector3D,
  TERRA_Log, TERRA_AudioMixer, TERRA_SoundSource, TERRA_SoundAmbience, TERRA_Resource, TERRA_ResourceManager;

Type
  SoundManager = Class(ResourceManager)
    Protected
      _Mixer:TERRAAudioMixer;

      _Ambience:SoundAmbience;

      _Enabled:Boolean;

      Procedure Init; Override;
      Procedure Update; Override;

      Procedure UpdatePosition(Position, Direction, Up:Vector3D);

      Procedure SetEnabled(Const Value: Boolean);

    Public
      Procedure Release; Override;

      Function Play(MySound:Sound):SoundSource; Overload;
      Function Play(Const Name:TERRAString):SoundSource; Overload;

      Function Spawn(MySound:Sound; Position:Vector3D; Volume:Single=1.0):SoundSource;
      Procedure Delete(Source:SoundSource);

      Function GetSound(Name:TERRAString; ValidateError:Boolean = True):Sound;

      Class Function Instance:SoundManager;

      Property Ambience:SoundAmbience Read _Ambience;
      Property Mixer:TERRAAudioMixer Read _Mixer;

      Property Enabled:Boolean Read _Enabled Write SetEnabled;
  End;

Implementation
Uses TERRA_Error, TERRA_CollectionObjects, TERRA_FileManager;

Var
  _SoundManager_Instance:ApplicationObject = Nil;

{ SoundSystem }
Procedure SoundManager.Init;
Var
  Attribs:Array[0..1] Of Integer;
Begin
  Inherited;

  Self.AutoUnload := True;

	Log(logDebug, 'Audio','Initializing audio mixer');
  _Mixer := TERRAAudioMixer.Create(DefaultSampleFrequency, DefaultAudioSampleCount);

  _Ambience := SoundAmbience.Create();

  _Enabled := True;

  AutoUnload := False;
End;

Procedure SoundManager.Release;
Var
  I:Integer;
Begin
  Inherited;

  ReleaseObject(_Ambience);

  _SoundManager_Instance := Nil;
End;

Function SoundManager.GetSound(Name:TERRAString; ValidateError:Boolean):Sound;
Var
  S:TERRAString;
Begin
  Result := Nil;
  Name := StringTrim(Name);
  If (Name='') Then
    Exit;

  Result := Sound(GetResource(Name));
  If (Not Assigned(Result)) Then
  Begin
    S := FileManager.Instance().SearchResourceFile(Name+'.wav');
    If (S='') Then
      S := FileManager.Instance().SearchResourceFile(Name+'.ogg');

    If S<>'' Then
    Begin
      Result := Sound.Create(rtLoaded, S);
      Self.AddResource(Result);
    End Else
    If ValidateError Then
      RaiseError('Could not find sound resource. ['+Name +']');
  End;
End;


Class function SoundManager.Instance: SoundManager;
Begin
  If Not Assigned(_SoundManager_Instance) Then
    _SoundManager_Instance := InitializeApplicationComponent(SoundManager, Nil);

  Result := SoundManager(_SoundManager_Instance.Instance);
End;

Procedure SoundManager.Update;
Var
  I:Integer;
Begin
  Inherited;
End;

Procedure SoundManager.Delete(Source:SoundSource);
Begin
  If Source = Nil Then
    Exit;
    
  _Mixer.RemoveSource(Source);
  ReleaseObject(Source);
End;

Function SoundManager.Play(MySound: Sound): SoundSource;
Begin
  {$IFDEF DISABLESOUND}
  Result := Nil;
  Exit;
  {$ENDIF}

  If (Not Assigned(MySound)) Then
  Begin
    Result := Nil;
    Exit;
  End;

  If (Not _Enabled) Then
  Begin
    Result := Nil;
    Exit;
  End;

  Log(logDebug, 'Sound', 'Playing '+MySound.Name);

  MySound.Prefetch();

  Result := ResourceSoundSource.Create(soundSource_Static, MySound);

  Log(logDebug, 'Sound', 'Setting '+MySound.Name+' position');

  Result.Position := VectorZero;

  Log(logDebug, 'Sound', 'Registering sound in mixer');
  _Mixer.AddSource(Result);
End;

Procedure SoundManager.UpdatePosition(Position, Direction, Up:Vector3D);
Begin
  //TODO
End;

Function SoundManager.Spawn(MySound:Sound; Position:Vector3D; Volume:Single): SoundSource;
Begin
  Result := Self.Play(MySound);
  If Assigned(Result) Then
  Begin
    Result.Position := Position;
    Result.Volume := Volume;
  End;
End;

Function SoundManager.Play(Const Name:TERRAString): SoundSource;
Var
  Snd:Sound;
Begin
  Snd := Self.GetSound(Name, False);
  If Snd = Nil Then
  Begin
    Result := Nil;
    Exit;
  End;

  Result := Self.Play(Snd);
End;

Procedure SoundManager.SetEnabled(const Value: Boolean);
Var
  S:TERRAString;
Begin
  If (Self._Enabled = Value) Then
    Exit;

  _Enabled := Value;
  
  If (Value) Then
    S := 'Enabling audio...'
  Else
    S := 'Disabling audio...';

  Log(logDebug, 'Audio', S);
End;

End.
