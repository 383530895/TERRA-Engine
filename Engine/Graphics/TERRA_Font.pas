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
 * TERRA_Font
 * Implements a Font Resource with unicode text support
 ***********************************************************************************************************************
}
Unit TERRA_Font;

{$I terra.inc}
Interface
Uses {$IFDEF USEDEBUGUNIT}TERRA_Debug,{$ENDIF}
  TERRA_String, TERRA_Object, TERRA_Utils, TERRA_Resource, TERRA_Stream, TERRA_Image, TERRA_Color, TERRA_Vector2D, TERRA_Vector3D,
  TERRA_Math, TERRA_Texture, TERRA_Sprite, TERRA_Renderer, TERRA_TextureAtlas, TERRA_VertexFormat, TERRA_Viewport,
  TERRA_ResourceManager, TERRA_Matrix4x4, TERRA_Matrix3x3, TERRA_ClipRect, TERRA_Collections;


Const
  TabSize = 100;

  FontPadding = 10;
  FontSpread  = 14;

  FontRescale = 3;
  FontInvScale = 1.0 / FontRescale;

  DefaultFontSize = 30;

  DefaultFontPageWidth = 256 * FontRescale;
  DefaultFontPageHeight = 512 * FontRescale;

  fontmode_Sprite   = 0;
  fontmode_Measure  = 1;
  fontmode_Offscreen=2;

  fontControlColor = 1;
  fontControlCornerColorA = 2;
  fontControlCornerColorB = 3;
  fontControlCornerColorC = 4;
  fontControlCornerColorD = 5;
  fontControlTab = 8;
  fontControlBlink = 9;
  fontControlItalics = 11;
  fontControlWave = 12;
  fontControlNewLine = 13;
  fontControlSprite = 14;
  fontControlEnd = 31;

Type
  FontGradient = (
    gradientNone      = 0,
    gradientHorizontal= 1,
    gradientVertical  = 2
  );


  PFontKerning = ^FontKerning;
  FontKerning = Record
    Next:Cardinal;
    Ammount:SmallInt;
  End;

  TERRAFont = Class;
  FontGlyphFactory = Class;

  FontGlyph = Class(TERRAObject)
    Private
      _Temp:Image;

    Protected
      _Font:TERRAFont;
      _Factory:FontGlyphFactory;

      _Item:TextureAtlasItem;

    Public
      ID:Cardinal;

      Width:Word;
      Height:Word;

      XOfs,YOfs:SmallInt;
      XAdvance:SmallInt;

      KerningList:Array Of FontKerning;
      KerningCount:Integer;

      Procedure Release; Override;

      Function GetAdvance(Next:Cardinal):Integer;
      Procedure AddKerning(Next:Cardinal; Ammount:SmallInt);

      Function GetImage():Image;
  End;

  FontSprite = Class(TERRASprite)
    Protected
      _Scale:Single;

      Procedure AddGlyph(Const X,Y:Single; Glyph:FontGlyph; Const A, B, C, D:ColorRGBA; Skew:Single);

  End;


  FontEffect = Record
    Effect:TERRAChar;
    Arg:TERRAString;
  End;

  FontGlyphFactory = Class(TERRAObject)
    Protected
      _Next:FontGlyphFactory;
      _LocalScale:Single;

    Public
      Procedure LoadFromStream(Source:Stream); Virtual; Abstract;
      Procedure LoadFromFile(Const FileName:TERRAString);

      Function InitGlyph(Font:TERRAFont; ID:Cardinal; Size:Integer):FontGlyph; Virtual; Abstract;
      Function GetKerning(Current, Next:Cardinal):Integer; Virtual; Abstract;
  End;

  TERRAFont = Class(Resource)
    Protected
      _Glyphs:Array Of FontGlyph;
      _GlyphCount:Integer;

      _Atlas:TextureAtlas;

      _AvgHeight:Single;

      _Factory:FontGlyphFactory;
      _NeedsRebuild:Boolean;
      _AddingGlyph:Boolean;
      _Loading:Boolean;

      Procedure RebuildPages();

    Public
      Function Load(Source:Stream):Boolean; Override;
      //Function Save(FileName:TERRAString):Boolean;

      Function Unload:Boolean; Override;
      Function Update:Boolean; Override;

      Function AddGlyph(ID:Cardinal; Source:Image; XOfs,YOfs:SmallInt; XAdvance:SmallInt = -1):FontGlyph; Overload;
      Function AddGlyph(ID:Cardinal; FileName:TERRAString; XOfs,YOfs:SmallInt; XAdvance:SmallInt = -1):FontGlyph; Overload;
      Function AddEmptyGlyph():FontGlyph;
      Function GetGlyph(ID:Cardinal; CreatedIfNeeded:Boolean = True):FontGlyph;
      Procedure SortGlyphs();

      Procedure RecalculateMetrics();

      Class Function GetManager:Pointer; Override;

      Procedure AddGlyphFactory(Factory:FontGlyphFactory; Scale:Single = 1.0);

      Property Atlas:TextureAtlas Read _Atlas;

      Property NewLineOffset:Single Read _AvgHeight Write _AvgHeight;
  End;

  FontProperty = Class(TERRAObject)
    Protected
      _Value:TERRAFont;

    Public
      Constructor Create(Const Name:TERRAString; InitValue:TERRAFont);

      Function IsValueObject():Boolean; Override;

      Function GetObjectType:TERRAString; Override;

      Function GetBlob():TERRAString; Override;
      Procedure SetBlob(Const Blob:TERRAString); Override;

      Property Value:TERRAFont Read _Value Write _Value;
  End;

  FontStreamValidateFunction = Function(Source:Stream):Boolean;
  FontLoader = Function(Source:Stream; Font:TERRAFont):Boolean;

  FontClassInfo = Record
    Name:TERRAString;
    Validate:FontStreamValidateFunction;
    Loader:FontLoader;
  End;

  FontManager = Class(ResourceManager)
    Protected
      _DefaultFont:TERRAFont;

      Function GetDefaultFont:TERRAFont;

    Public
      Procedure Release; Override;

      Procedure Update; Override;

      Class Function Instance:FontManager;

      Function DrawGlyph(View:TERRAViewport; X,Y,Z:Single; Const Transform:Matrix3x3; Const Scale:Single; Glyph:FontGlyph; Const Outline, Glow, A,B,C,D:ColorRGBA; Clip:TERRAClipRect; Italics:Boolean; Var DestSprite:FontSprite):Boolean;

      Function GetFont(Name:TERRAString; ValidateError:Boolean = True):TERRAFont;

      Property DefaultFont:TERRAFont Read GetDefaultFont;
   End;

  Function GetFontLoader(Source:Stream):FontLoader;
  Procedure RegisterFontFormat(Name:TERRAString; Validate:FontStreamValidateFunction; Loader:FontLoader);

  Function ConvertFontCodes(S:TERRAString):TERRAString;
  Function UnconvertFontCodes(S:TERRAString):TERRAString;

Implementation
Uses TERRA_Error, TERRA_OS, TERRA_Application, TERRA_Sort, TERRA_TextureManager,
  TERRA_Log, TERRA_FileUtils, TERRA_MemoryStream, TERRA_ImageDrawing,
  TERRA_GraphicsManager, TERRA_FileManager, TERRA_Packer, TERRA_DistanceField;

Var
  _FontExtensions:Array Of FontClassInfo;
  _FontExtensionCount:Integer;
  _FontManager_Instance:ApplicationObject;

Type
  GlyphSort = Class(Sort)
    Public
      Class Procedure Swap(Data:Pointer; A,B:Integer); Override;
      Class Procedure SetPivot(Data:Pointer; A:Integer); Override;
      Class Function Compare(Data:Pointer; A:Integer):Integer; Override;
  End;

Var
  _GlyphPivot:Cardinal;

{ GlyphSort }
Class Procedure GlyphSort.SetPivot(Data:Pointer; A:Integer);
Var
  Fnt:TERRAFont;
Begin
  Fnt := TERRAFont(Data);
  _GlyphPivot := Fnt._Glyphs[A].ID;
End;

Class Function GlyphSort.Compare(Data:Pointer; A:Integer):Integer;
Var
  Fnt:TERRAFont;
Begin
  Fnt := TERRAFont(Data);
  If (Fnt._Glyphs[A].ID < _GlyphPivot) Then
    Result := 1
  Else
  If (Fnt._Glyphs[A].ID > _GlyphPivot) Then
    Result := -1
  Else
    Result := 0;
End;

Class Procedure GlyphSort.Swap(Data:Pointer; A,B:Integer);
Var
  Fnt:TERRAFont;
  Temp:FontGlyph;
Begin
  Fnt := TERRAFont(Data);
  Temp := Fnt._Glyphs[A];
  Fnt._Glyphs[A] := Fnt._Glyphs[B];
  Fnt._Glyphs[B] := Temp;
End;


Function GetFontLoader(Source:Stream):FontLoader;
Var
  Pos:Cardinal;
  I:Integer;
Begin
  Result := Nil;
  If Not Assigned(Source) Then
    Exit;

  Pos := Source.Position;

  For I:=0 To Pred(_FontExtensionCount) Do
  Begin
    Source.Seek(Pos);
    If _FontExtensions[I].Validate(Source) Then
    Begin
      Log(logDebug, 'Font', 'Found '+_FontExtensions[I].Name);
      Result := _FontExtensions[I].Loader;
      Break;
    End;
  End;

  Source.Seek(Pos);
End;

Procedure RegisterFontFormat(Name:TERRAString; Validate:FontStreamValidateFunction; Loader:FontLoader);
Var
  I,N:Integer;
Begin
  Name := StringLower(Name);

  For I:=0 To Pred(_FontExtensionCount) Do
  If (_FontExtensions[I].Name = Name) Then
    Exit;

  N := _FontExtensionCount;
  Inc(_FontExtensionCount);
  SetLength(_FontExtensions, _FontExtensionCount);
  _FontExtensions[N].Name := Name;
  _FontExtensions[N].Validate :=Validate;
  _FontExtensions[N].Loader := Loader;
End;

{ FontManager }
Class Function FontManager.Instance:FontManager;
Begin
  If _FontManager_Instance = Nil Then
    _FontManager_Instance := InitializeApplicationComponent(FontManager, TextureManager);

  Result := FontManager(_FontManager_Instance.Instance);
End;

Function FontManager.GetFont(Name:TERRAString; ValidateError:Boolean):TERRAFont;
Var
  FontName, FileName, S:TERRAString;
  I:Integer;
Begin
  If (Name='') Then
  Begin
    Result := Nil;
    Exit;
  End;

  FontName := Name;

  Name := GetFileName(Name, True);

  S := '';
  I := 0;
  While (S='') And (I<_FontExtensionCount) Do
  Begin
    FileName := FontName+'.'+_FontExtensions[I].Name;
    S := FileManager.Instance.SearchResourceFile(FileName);
    Inc(I);
  End;

  If S<>'' Then
  Begin
    Result := TERRAFont.Create(rtLoaded, S);
    Result.Priority := 90;
    Self.AddResource(Result);
  End Else
  If ValidateError Then
    RaiseError('Could not find font. ['+Name +']');
End;

Function FontManager.DrawGlyph(View:TERRAViewport; X,Y,Z:Single; Const Transform:Matrix3x3; Const Scale:Single; Glyph:FontGlyph; Const Outline, Glow, A,B,C,D:ColorRGBA; Clip:TERRAClipRect; Italics:Boolean; Var DestSprite:FontSprite):Boolean;
Var
  Filter:TextureFilterMode;
  Item:TextureAtlasItem;
  Target:FontSprite;
  Tex:TERRATexture;
  Skew:Single;
Begin
  Result := False;

  If DestSprite = Nil Then
    Exit;

  Filter := filterBilinear;

  Item := Glyph._Item;
  If Item = Nil Then
    Exit;

  Tex := Glyph._Font._Atlas.GetTexture(Item.PageID);
  If Tex = Nil Then
    Exit;

  If (Italics) Then
    Skew := 5.0
  Else
    Skew := 0.0;

  DestSprite.Shader := View.SpriteRenderer.FontShader;
  DestSprite.Layer := Z;
  DestSprite.Texture := Tex;
  DestSprite.SetTransform(Transform);
  DestSprite.ClipRect := Clip;
  DestSprite.Outline := Outline;
  DestSprite.Glow := Glow;
  DestSprite._Scale := Scale;

  DestSprite.AddGlyph(X, Y, Glyph, A, B, C, D, Skew);

  Result := True;
End;

{$I default_font.inc}
Function FontManager.GetDefaultFont: TERRAFont;
Var
  Glyph:FontGlyph;
  I, ID:Integer;
  Src:Stream;
  SrcImg, SubImg:Image;

  Procedure SubPic(X, Y, W, H:Integer);
  Begin
    SubImg := SrcImg.Crop(X, Y, X + W , Y + H);
  End;
Begin
  Result := _DefaultFont;
  If Assigned(Result) Then
    Exit;

  _DefaultFont := TERRAFont.Create(rtDynamic, 'default_font');
  Result := _DefaultFont;

  Src := MemoryStream.Create(bm_size, @bm_data[0]);
  SrcImg := Image.Create(Src);
  ReleaseObject(Src);

  For I:=32 To 128 Do
  Begin
    ID := I;
    Glyph := Nil;
    SubImg := Nil;

	  Case ID Of
	  32: SubPic(8*20, 12*2, 4, 12);
	  Ord('#'):	SubPic(8*10, 12*2, 8, 12);
	  Ord('!'):	SubPic(8*11, 12*2, 4, 12);
	  Ord('?'): SubPic(8*12, 12*2, 8, 12);
	  Ord(','): SubPic(8*13, 12*2, 4, 12);
    Ord('.'): SubPic(8*14, 12*2, 4, 12);
	  Ord('$'): SubPic(8*15, 12*2, 8, 12);
	  Ord(':'): SubPic(8*16, 12*2, 8, 12);
	  Ord('+'): SubPic(8*17, 12*2, 8, 12);
	  Ord('-'): SubPic(8*18, 12*2, 8, 12);
	  Ord(''''):SubPic(8*19, 12*2, 4, 12);
	  48..57: SubPic(8*(ID-48), 12*2, 8, 12);
	  65..90: SubPic(8*(ID-65), 12*0, 8, 12);
	  97..122:  SubPic(8*(ID-97), 12*1, 8, 12);
	  End;

    If Assigned(SubImg) Then
    Begin
      Glyph := Result.AddGlyph(ID, SubImg, 0, 0);
      ReleaseObject(SubImg);
    End;

	  If (Assigned(Glyph)) Then
    Begin
		  If (ID=73) Then
  			Glyph.XAdvance := 5
      Else
		  If (ID=105) Then
			  Glyph.XAdvance := 5
      Else
    		Glyph.XAdvance := Glyph.Width;
    End;
  End;

  ReleaseObject(SrcImg);

  Result.Update();

  Result._NeedsRebuild := True;
End;

Procedure FontManager.Release;
Begin
  ReleaseObject(_DefaultFont);

  Inherited;
  _FontManager_Instance := Nil;
End;


Procedure FontManager.Update();
Var
  It:Iterator;
  Fnt:TERRAFont;
Begin
  If (Assigned(Self._DefaultFont)) And (Self._DefaultFont._NeedsRebuild) Then
    Self._DefaultFont.RebuildPages();

  It := Self.Resources.GetIterator();
  While It.HasNext() Do
  Begin
    Fnt := TERRAFont(It.Value);

    If (Fnt._NeedsRebuild) Then
      Fnt.RebuildPages();
  End;
  ReleaseObject(It);
End;

{ FontGlyph }
Procedure FontGlyph.AddKerning(Next: Cardinal; Ammount: SmallInt);
Var
  N:Integer;
Begin
  N := Self.KerningCount;
  Inc(Self.KerningCount);
  SetLength(Self.KerningList, Self.KerningCount);
  Self.KerningList[N].Next := Next;
  Self.KerningList[N].Ammount := Ammount;
End;

Function FontGlyph.GetAdvance(Next:Cardinal):Integer;
Var
  I:Integer;
Begin
  Result := (XAdvance - XOfs);

  For I:=0 To Pred(KerningCount) Do
  If (KerningList[I].Next = Next) Then
  Begin
    Inc(Result, KerningList[I].Ammount);
    Exit;
  End;

  If Assigned(Self._Factory) Then
    Inc(Result, Self._Factory.GetKerning(ID, Next));
End;

Function FontGlyph.GetImage: Image;
Begin
  If Assigned(_Temp) Then
    Result := _Temp
  Else
  If Assigned(_Item) Then
    Result := _Item.Buffer
  Else
    Result := Nil;
End;

Procedure FontGlyph.Release;
Begin
  ReleaseObject(_Temp);
End;

{ Font }
Function TERRAFont.Load(Source: Stream): Boolean;
Var
  Loader:FontLoader;
  Pos:Integer;
Begin
  Result := False;
  If (Source = Nil) Then
    Exit;

  _GlyphCount := 0;

  Pos := Source.Position;
  Loader := GetFontLoader(Source);
  If (Not Assigned(Loader)) Then
    Exit;

  Source.Seek(Pos);
  _Loading := True;
  Result := Loader(Source, Self);
  _Loading := False;

  If (Not Result) Then
    Exit;


  Result := Self.Update();
End;

Procedure TERRAFont.RecalculateMetrics();
Var
  Glyph:FontGlyph;
  I, Pos:Integer;
Begin
  _AvgHeight := 0.0;
  For I:=0 To Pred(_GlyphCount) Do
  Begin
    Glyph := _Glyphs[I];
    _AvgHeight := _AvgHeight + Glyph.Height;

    //Page := Self.GetPage(Glyph.Page);
  End;

  If (_GlyphCount>0) Then
    _AvgHeight := _AvgHeight / _GlyphCount;

  _AvgHeight := _AvgHeight;
End;

Class Function TERRAFont.GetManager:Pointer;
Begin
  Result := FontManager.Instance;
End;

Function TERRAFont.GetGlyph(ID:Cardinal; CreatedIfNeeded:Boolean = True):FontGlyph;
Var
  A,B, Mid:Integer;
  I:Integer;
  F:FontGlyphFactory;
Begin
  Result := Nil;

  If (Self._NeedsRebuild) Or (_AddingGlyph) Then
  Begin // not sorted yet, so cannot do a binary search
    For I:=0 To Pred(_GlyphCount) Do
    If (_Glyphs[I].ID = ID) Then
    Begin
      Result := _Glyphs[I];
      Exit;
    End;
  End Else
  Begin
    {If (ID=49) Then
      IntToString(2);}

    A := 0;
    B := Pred(_GlyphCount);
    Mid := 0;
    While (A<B) Do
    Begin
      Mid := A + ((B-A) Shr 1);

      If (_Glyphs[Mid].ID < ID) Then
      Begin
        A := Mid + 1;
        If (_Glyphs[A].ID = ID) Then // hack
        Begin
          Inc(Mid);
          Break;
        End;
      End Else
      If (_Glyphs[Mid].ID > ID) Then
      Begin
        B := Mid;
      End Else
        Break;
    End;

    {$IFDEF DEBUG_FONTS}Log(logDebug, 'Texture', 'Testing glyph '+IntToString(Mid));{$ENDIF}
    {$IFDEF DEBUG_FONTS}Log(logDebug, 'Texture', 'Glyph count '+IntToString(_GlyphCount)+'/'+IntToString(Length(_Glyphs)));{$ENDIF}

    If (Mid<_GlyphCount) And (_GlyphCount>0) And (_Glyphs[Mid]<>Nil) And (_Glyphs[Mid].ID = ID) Then
    Begin
      Result := _Glyphs[Mid];
      If (Assigned(Result)) Then
        Exit;
    End;
  End;

  If (Not CreatedIfNeeded) Then
    Exit;

  // not found yet? well, lets try to stream it from one of the glyph factories
  F := _Factory;
  While Assigned(F) Do
  Begin
    Result := F.InitGlyph(Self, ID, Trunc(DefaultFontSize * F._LocalScale * FontRescale));
    If Assigned(Result) Then
    Begin
      Result._Factory := F;
      Exit;
    End;

    F := F._Next;
  End;

  Log(logWarning, 'Font', 'Glyph '+ IntegerProperty.Stringify(ID)+' was not found!');
End;

Function TERRAFont.Unload: Boolean;
Var
  I:Integer;
Var
  F:FontGlyphFactory;
Begin
  F := _Factory;
  While Assigned(F) Do
  Begin
    _Factory := F;
    F := F._Next;
    ReleaseObject(_Factory);
  End;
  _Factory := Nil;

  ReleaseObject(_Atlas);

  For I:=0 To Pred(_GlyphCount) Do
    ReleaseObject(_Glyphs[I]);
    
  _GlyphCount := 0;
  SetLength(_Glyphs, 0);

  Result := True;
End;

Function TERRAFont.Update:Boolean;
Begin
  Inherited Update();

  If (_Atlas = Nil) Then
    _Atlas := TextureAtlas.Create(Self.Name, DefaultFontPageWidth, DefaultFontPageHeight);


  RecalculateMetrics();

  Self.SetStatus(rsReady);

	Result := True;
End;

Procedure TERRAFont.SortGlyphs;
Var
  I,J:Integer;
  Temp:FontGlyph;
Begin
//  GlyphSort.Sort(Self, _GlyphCount);
  For I:= Pred(_GlyphCount) DownTo 0 Do
    For J:=1 To I Do
    If (_Glyphs[J-1].ID > _Glyphs[J].ID) Then
    Begin
     Temp := _Glyphs[J-1];
     _Glyphs[J-1] := _Glyphs[j];
     _Glyphs[J] := Temp;
    End;
End;

Procedure TERRAFont.AddGlyphFactory(Factory: FontGlyphFactory; Scale:Single);
Var
  F:FontGlyphFactory;
Begin
  If (Factory = Nil) Then
    Exit;
    
  Factory._LocalScale := Scale;

  If (_Factory = Nil) Then
  Begin
    _Factory := Factory;
    Exit;
  End;

  F := _Factory;
  While Assigned(F._Next) Do
  Begin
    If (F = Factory) Or (F._Next = Factory) Then
      Exit;

    F := F._Next;
  End;

  F._Next := Factory;
  Factory._Next := Nil;
End;

Function TERRAFont.AddEmptyGlyph:FontGlyph;
Begin
  Inc(_GlyphCount);
  SetLength(_Glyphs, _GlyphCount);
  Result := FontGlyph.Create();
  Result._Font := Self;
  _Glyphs[Pred(_GlyphCount)] := Result;
End;

Function TERRAFont.AddGlyph(ID:Cardinal; FileName:TERRAString; XOfs, YOfs, XAdvance: SmallInt):FontGlyph;
Var
  Source: Image;
Begin
  FileName := GetFileName(FileName, True);

  Source := Image.Create(FileName);
  If (Source.Width>0) Then
    Result := Self.AddGlyph(ID, Source, XOfs, YOfs, XAdvance)
  Else
    Result := Nil;

  ReleaseObject(Source);
End;

Function TERRAFont.AddGlyph(ID: Cardinal; Source:Image; XOfs, YOfs, XAdvance:SmallInt):FontGlyph;
Var
  It:ImageIterator;
  C:ColorRGBA;
  N:Byte;

  Temp:Image;
Begin
  //Self.Prefetch();

  Result := Nil;

  If (Source = Nil) Or (Source.Width<=0) Then
    Exit;

//  Source.Save('glyph'+CardinalTOString(ID)+'.png');

  Temp := Image.Create(Source.Width + FontPadding * 2, Source.Height + FontPadding * 2);
  Temp.Blit(FontPadding, FontPadding, 0, 0, Source.Width, Source.Height, Source);

  //Temp.Save('glyph'+CardinalTOString(ID)+'.png');

(*  It := Temp.Pixels([image_Kernel, image_Read, image_Write], maskRGBA);
  While It.HasNext() Do
  Begin
    C := It.ApplyKernel(Kernel_Dilate);

    If (C.A<128) And (C.A>0) Then
      N := 255
    Else
      N := 0;

      //N := C.A;

    It.Value := ColorCreate(N, 0, 0, It.Value.R);
  End;
  ReleaseObject(It);

  Temp.Save('glyph'+CardinalTOString(ID)+'.png');*)

  _AddingGlyph := True;
  Result := Self.GetGlyph(ID, False);
  _AddingGlyph := False;

  If (Assigned(Result)) Then
  Begin
    Result.XOfs := XOfs;
    Result.YOfs := YOfs;
    Result.XAdvance := XAdvance;
    Exit;
  End;

  Result := Self.AddEmptyGlyph();

  {If (Id=32) Then
     IntegerProperty.Stringify(2);}

  Result.ID := ID;
  Result.Width := Source.Width;
  Result.Height := Source.Height;
  Result.XOfs := XOfs;
  Result.YOfs := YOfs;

  Result._Temp := CreateDistanceField(Temp, componentAlpha, 1, FontSpread);
  //Result._Temp := Image.Create(Temp);

//  Result._Temp.Save('glyph'+CardinalTOString(ID)+'.png');

  If (XAdvance<=0) Then
    XAdvance := Source.Width;

  Result.XAdvance := XAdvance;

  ReleaseObject(Temp);

  _NeedsRebuild := True;
End;

Procedure TERRAFont.RebuildPages();
Var
  I:Integer;
Begin
  _NeedsRebuild := False;

  Log(logDebug,'Font', 'Updating font: '+ Self.Name);

  Self.SortGlyphs();

  // rebuild the whole font atlas
  For I:=0 To Pred(_GlyphCount) Do
  If (Assigned(_Glyphs[I]._Temp)) Then
  Begin
    _Glyphs[I]._Item := _Atlas.Add(_Glyphs[I]._Temp, CardinalToString(_Glyphs[I].ID), False, FontPadding);
    ReleaseObject(_Glyphs[I]._Temp);
  End;

  _Atlas.Update();

  Self.RecalculateMetrics();
End;


Function ConvertFontCodes(S:TERRAString):TERRAString;
Var
  S2:TERRAString;
  C:TERRAChar;
  It:StringIterator;
Begin
  Result := '';

  While StringCharPosIterator(Ord('\'), S, It) Do
  Begin
    It.Split(S2, S);

    Result := Result + S2;

    C := CharLower(StringFirstChar(S));
    S := StringCopy(S, 2, MaxInt);

    Case C Of
    Ord('n'):  Result := Result + StringFromChar(fontControlNewLine);
    Ord('t'):  Result := Result + StringFromChar(fontControlTab);
    Ord('b'):  Result := Result + StringFromChar(fontControlBlink);
    Ord('i'):  Result := Result + StringFromChar(fontControlItalics);
    Ord('w'):  Result := Result + StringFromChar(fontControlWave);

    Ord('p'):
      Begin
        S2 := StringGetNextSplit(S, Ord('}'));
        S2 := StringCopy(S2, 2, MaxInt);
        Result := Result + StringFromChar(fontControlSprite) + S2 + StringFromChar(fontControlEnd);
      End;

    Ord('c'):
      Begin
        S2 := StringGetNextSplit(S, Ord('}'));
        S2 := StringCopy(S2, 2, MaxInt);
        Result := Result + StringFromChar(fontControlColor) + S2 + StringFromChar(fontControlEnd);
      End;

    Else
      Result := Result + StringFromChar(C);

    End;
  End;

  Result := Result + S;
End;

Function UnconvertFontCodes(S:TERRAString):TERRAString;
Var
  S2:TERRAString;
  C:TERRAChar;
  It:StringIterator;
Begin
  Result := '';

  StringCreateIterator(S, It);
  While It.HasNext Do
  Begin
    C := It.GetNext();
    Case C Of
    fontControlNewLine: Result := Result + '\n';
    fontControlTab: Result := Result + '\t';
    fontControlBlink: Result := Result + '\b';
    fontControlItalics: Result := Result + '\i';
    fontControlWave: Result := Result + '\w';

    fontControlSprite:
      Begin
        Result := Result + '\p{';
        Repeat
          C := It.GetNext();
          If C = fontControlEnd Then
            Break;

          StringAppendChar(Result, C);
        Until False;
        Result := Result + '}';
      End;

    fontControlColor:
      Begin
        Result := Result + '\c{';
        Repeat
          C := It.GetNext();
          If C = fontControlEnd Then
            Break;

          StringAppendChar(Result, C);
        Until False;
        Result := Result + '}';
      End;

    Else
      StringAppendChar(Result, C);
    End;
  End;
End;

{ FontProperty }
Constructor FontProperty.Create(const Name: TERRAString; InitValue:TERRAFont);
Begin
  Self._ObjectName := Name;
  Self._Value := InitValue;
End;

Function FontProperty.GetBlob: TERRAString;
Begin
  If Assigned(_Value) Then
    Result := Self._Value.Name
  Else
    Result := '';

  If Result = '' Then
    Result := '#';
End;

Procedure FontProperty.SetBlob(const Blob: TERRAString);
Begin
  If Blob<>'#' Then
    _Value := FontManager.Instance.GetFont(Blob)
  Else
    _Value := FontManager.Instance.DefaultFont;
End;

Function FontProperty.GetObjectType: TERRAString;
Begin
  Result := 'font';
End;

Function FontProperty.IsValueObject: Boolean;
Begin
  Result := True;
End;

{ FontGlyphFactory }
Procedure FontGlyphFactory.LoadFromFile(const FileName: TERRAString);
Var
  Source:Stream;
Begin
  Source := FileManager.Instance.OpenStream(FileName);
  If Assigned(Source) Then
  Begin
    LoadFromStream(Source);
    ReleaseObject(Source);
  End;
End;

{ FontSprite }
Procedure FontSprite.AddGlyph(Const X,Y:Single; Glyph:FontGlyph; Const A, B, C, D:ColorRGBA; Skew:Single);
Var
  Width, Height:Integer;
  Item:TextureAtlasItem;
Begin
  Item := Glyph._Item;

  Width := Trunc((Item.Buffer.Width - FontPadding) * _Scale);
  Height := Trunc((Item.Buffer.Height - FontPadding) * _Scale);

  //0.25 / (Spread * Scale)
  Self.MakeQuad(VectorCreate2D(X + Glyph.XOfs * FontInvScale * _Scale, Y +  + Glyph.YOfs * FontInvScale * _Scale), 0.0, Item.U1, Item.V1, Item.U2, Item.V2, Width *FontInvScale, Height* FontInvScale, A, B, C, D, Skew);
End;


End.
