Unit TERRA_Localization;
{$I terra.inc}

Interface
Uses TERRA_String, TERRA_Utils, TERRA_Stream;

Const
  language_English   = 'EN';
  language_German    = 'DE';
  language_French    = 'FR';
  language_Portuguese= 'PT';
  language_Spanish   = 'ES';
  language_Italian   = 'IT';
  language_Japanese  = 'JP';
  language_Chinese   = 'ZH';
  language_Russian   = 'RU';
  language_Korean    = 'KO';

  invalidString = '???';

  MaxPinyinSuggestions = 64;

Type
  LocalizationLoader = Class
    Procedure Process(Var Key, Value:TERRAString); Virtual; Abstract;

    Function GetString(Const Key:TERRAString):TERRAString; Virtual;
  End;

  StringEntry = Record
    Key:TERRAString;
    Value:TERRAString;
    Group:Integer;
  End;

  StringManager = Class(TERRAObject)
    Protected
      _Lang:TERRAString;
      _Strings:Array Of StringEntry;
      _StringCount:Integer;

      Function GetLang:TERRAString;

      Function FormatString(Const Text:TERRAString; Loader:LocalizationLoader = Nil):TERRAString;

    Public
      Constructor Create;

      Class Function Instance:StringManager;
      Procedure SetLanguage(Lang:TERRAString);

      Function GetString(Const Key:TERRAString; Group:Integer = -1):TERRAString;
      Function HasString(Const Key:TERRAString):Boolean;
      Procedure SetString(Const Key, Value:TERRAString; Group:Integer = -1);
      Function EmptyString():TERRAString;

      Procedure Reload();

      Procedure RemoveGroup(GroupID:Integer);
      Procedure MergeGroup(Source:Stream; GroupID:Integer; Loader:LocalizationLoader = Nil);


      Property Language:TERRAString Read GetLang Write SetLanguage;
  End;

  PinyinSuggestion = Record
    ID:Word;
    Text:TERRAString;
  End;

  PinyinConverter = Class
    Protected
      _Suggestions:Array Of PinyinSuggestion;
      _SuggestionCount:Integer;

      Procedure Match(S:TERRAString);

    Public
      Constructor Create();

      Procedure GetSuggestions(Text:TERRAString);

      Function GetResult(Index:Integer):Word;

      Function Replace(Var Text:TERRAString; Index:Integer):Boolean;

      Property Results:Integer Read _SuggestionCount;
  End;

Function GetKoreanInitialJamo(N:Word):Integer;
Function GetKoreanMedialJamo(N:Word):Integer;
Function GetKoreanFinalJamo(N:Word):Integer;

Function MemoryToString(Const N:Cardinal):TERRAString;

Function IsSupportedLanguage(Const Lang:TERRAString):Boolean;

Function GetCurrencyForCountry(Const Country:TERRAString):TERRAString;

Function GetLanguageDescription(Lang:TERRAString):TERRAString;

Implementation
Uses TERRA_Application, TERRA_FileManager, TERRA_Log;

Var
  _Manager:StringManager = Nil;

Function IsSupportedLanguage(Const Lang:TERRAString):Boolean;
Begin
  Result := (Lang = language_English) Or (Lang = language_German)
             Or (Lang = language_French)  Or (Lang = language_Portuguese)
              Or (Lang = language_Spanish)  Or (Lang = language_Italian)
               Or (Lang = language_Japanese)  Or (Lang = language_Chinese)
                Or (Lang = language_Russian)  Or (Lang = language_Korean);
End;

Function GetCurrencyForCountry(Const Country:TERRAString):TERRAString;
Begin
  If (Country = 'GB') Then
  Begin
    Result := 'GBP';
  End Else
  If (Country = 'RU') Then
  Begin
    Result := 'RUB';
  End Else
  If (Country = 'BR') Then
  Begin
    Result := 'BRL';
  End Else
  If (Country = 'US') Then
  Begin
    Result := 'USD';
  End Else
  If (Country = 'JP') Then
  Begin
    Result := 'JPY';
  End Else
  If (Country = 'KR') Then
  Begin
    Result := 'KRW';
  End Else
  If (Country = 'UA') Then
  Begin
    Result := 'UAH';
  End Else
  If (Country = 'AU') Then
  Begin
    Result := 'AUD';
  End Else
  If (Country = 'CA') Then
  Begin
    Result := 'CAD';
  End Else
  If (Country = 'ID') Then
  Begin
    Result := 'IDR';
  End Else
  If (Country = 'MY') Then
  Begin
    Result := 'MYR';
  End Else
  If (Country = 'MX') Then
  Begin
    Result := 'MXN';
  End Else
  If (Country = 'NZ') Then
  Begin
    Result := 'NZD';
  End Else
  If (Country = 'NO') Then
  Begin
    Result := 'NOK';
  End Else
  If (Country = 'PH') Then
  Begin
    Result := 'PHP';
  End Else
  If (Country = 'SG') Then
  Begin
    Result := 'SGD';
  End Else
  If (Country = 'TH') Then
  Begin
    Result := 'THB';
  End Else
  If (Country = 'TR') Then
  Begin
    Result := 'TRY';
  End Else
  Begin
    Result := 'USD';
  End;
End;

Function GetKoreanInitialJamo(N:Word):Integer;
Begin
  Case N Of
	12593: Result := 0;
	12594: Result := 1;
	12596: Result := 2;
	12599: Result := 3;
	12600: Result := 4;
	12601: Result := 5;
	12609: Result := 6;
	12610: Result := 7;
	12611: Result := 8;
	12613: Result := 9;
	12614: Result := 10;
	12615: Result := 11;
	12616: Result := 12;
	12617: Result := 13;
	12618: Result := 14;
	12619: Result := 15;
	12620: Result := 16;
	12621: Result := 17;
	12622: Result := 18;
  Else
    Result := -1;
  End;
End;

Function GetKoreanMedialJamo(N:Word):Integer;
Begin
  Case N Of
	12623: Result := 0;
	12624: Result := 1;
	12625: Result := 2;
	12626: Result := 3;
	12627: Result := 4;
	12628: Result := 5;
	12629: Result := 6;
	12630: Result := 7;
	12631: Result := 8;
	12632: Result := 9;
	12633: Result := 10;
	12634: Result := 11;
	12635: Result := 12;
	12636: Result := 13;
	12637: Result := 14;
	12638: Result := 15;
	12639: Result := 16;
	12640: Result := 17;
	12641: Result := 18;
	12642: Result := 19;
	12643: Result := 20;
  Else
    Result := -1;
  End;
End;

Function GetKoreanFinalJamo(N:Word):Integer;
Begin
  Case N Of
	12593: Result := 1;
	12594: Result := 2;
	12595: Result := 3;
	12596: Result := 4;
	12597: Result := 5;
	12598: Result := 6;
	12599: Result := 7;
	12601: Result := 8;
	12602: Result := 9;
	12603: Result := 10;
	12604: Result := 11;
	12605: Result := 12;
	12606: Result := 13;
	12607: Result := 14;
	12608: Result := 15;
	12609: Result := 16;
	12610: Result := 17;
	12612: Result := 18;
	12613: Result := 19;
	12614: Result := 20;
	12615: Result := 21;
	12616: Result := 22;
	12618: Result := 23;
	12619: Result := 24;
	12620: Result := 25;
	12621: Result := 26;
	12622: Result := 27;
  Else
    Result := -1;
  End;
End;


Function MemoryToString(Const N:Cardinal):TERRAString;
Var
  Ext:Char;
  X:Single;
  Int,Rem:Integer;
Begin
  If (N>=1 Shl 30)Then
  Begin
    X:=N/(1 Shl 30);
    Int:=Trunc(X);
    Rem:=Trunc(Frac(X)*10);
    Ext := 'G';
  End Else
  If (N>=1 Shl 20)Then
  Begin
    X:=N/(1 Shl 20);
    Int:=Trunc(X);
    Rem:=Trunc(Frac(X)*10);
    Ext:='M';
  End Else
  If (N>=1 Shl 10)Then
  Begin
    X:=N/(1 Shl 10);
    Int:=Trunc(X);
    Rem:=Trunc(Frac(X)*10);
    Ext:='K';
  End Else
  Begin
    Int:=N;
    Rem:=0;
    Ext:=#0;
  End;

  Result:=IntToString(Int);
  If Rem>0 Then
  Result:=Result+'.'+IntToString(Rem);
  Result:=Result+' ';
  If Ext<>#0 Then
    Result:=Result+Ext;

  If (Application.Instance<>Nil) And (Application.Instance.Language = language_Russian) Then
    StringAppendChar(Result, 1073)
  Else
    Result := Result + 'b';
End;

{ StringManager }
Constructor StringManager.Create;
Begin
  _Lang := '';
  If Assigned(Application.Instance()) Then
    SetLanguage(Application.Instance.Language)
  Else
    SetLanguage('EN');
End;

Function StringManager.EmptyString:TERRAString;
Begin
  Result := InvalidString;
End;

Function StringManager.GetLang:TERRAString;
Begin
  If (_Lang ='') And (Assigned(Application.Instance())) Then
    SetLanguage(Application.Instance.Language);

  Result := _Lang;
End;

Procedure StringManager.SetString(Const Key, Value:TERRAString; Group:Integer = -1);
Var
  I:Integer;
Begin
  For I:=0 To Pred(_StringCount) Do
  If (StringEquals(_Strings[I].Key, Key)) Then
  Begin
    _Strings[I].Value := Value;
    _Strings[I].Group := Group;
    Exit;
  End;

  Inc(_StringCount);
  SetLength(_Strings, _StringCount);
  _Strings[Pred(_StringCount)].Key := Key;
  _Strings[Pred(_StringCount)].Value := FormatString(Value);
  _Strings[Pred(_StringCount)].Group := Group;
End;

Function StringManager.GetString(Const Key:TERRAString; Group:Integer):TERRAString;
Var
  I:Integer;
Begin
  If (_Lang ='') And (Assigned(Application.Instance())) Then
    SetLanguage(Application.Instance.Language);

  For I:=0 To Pred(_StringCount) Do
  If (StringEquals(_Strings[I].Key, Key)) And ((Group<0) Or (_Strings[I].Group = Group)) Then
  Begin
    Result := _Strings[I].Value;
    Exit;
  End;

  Log(logWarning, 'Strings', 'String value for ['+Key+'] not found!');
  Result := Self.EmptyString;
End;

Class Function StringManager.Instance:StringManager;
Begin
  If Not Assigned(_Manager) Then
    _Manager := StringManager.Create;

  Result := _Manager;
End;

Procedure StringManager.MergeGroup(Source: Stream; GroupID:Integer; Loader:LocalizationLoader = Nil);
Var
  Ofs, I:Integer;
  S, S2:TERRAString;
Begin
  If (Source = Nil ) Then
    Exit;

  Log(logDebug, 'Strings', 'Merging strings from '+Source.Name);
  Ofs := _StringCount;

  S := '';
  While Not Source.EOF Do
  Begin
    Source.ReadLine(S);
    If S='' Then
      Continue;

    S := StringTrimLeft(S);
    If S='' Then
      Continue;
      
    I := Pos(',', S);
    S2 := Copy(S, 1, Pred(I));
    S2 := StringTrimRight(S2);

    S := Copy(S, Succ(I), MaxInt);
    S := StringTrimLeft(S);

    Inc(_StringCount);
    SetLength(_Strings, _StringCount);

    If Assigned(Loader) Then
      Loader.Process(S2, S);

    _Strings[Pred(_StringCount)].Key := S2;
    _Strings[Pred(_StringCount)].Value := S;
    _Strings[Pred(_StringCount)].Group := GroupID;

    //Log(logDebug, 'Strings', 'Found '+S2 +' = '+S);
  End;

  For I:=Ofs To Pred(_StringCount) Do
  Begin
    _Strings[I].Value := FormatString(_Strings[I].Value, Loader);
    //Log(logDebug, 'Localization', _Strings[I].Key + ' -> ' + _Strings[I].Value); 
  End;
End;

Procedure StringManager.SetLanguage(Lang:TERRAString);
Var
  S, S2:TERRAString;
  Source:Stream;
  I:Integer;
Begin
  Lang := StringUpper(Lang);
  If (Lang = 'CH') Or (Lang='CN') Then
    Lang := 'ZH';
  If (Lang = 'JA') Then
    Lang := 'JP';

  If (_Lang = Lang) Then
    Exit;

  S := 'translation_'+ StringLower(Lang)+'.txt';
  S := FileManager.Instance.SearchResourceFile(S);
  If S='' Then
  Begin
    Log(logWarning, 'Strings', 'Could not find translation file for lang='+Lang);

    If (Lang<>language_English) Then
      SetLanguage(language_English);

    Exit;
  End;

  _StringCount := 0;
  Source := FileManager.Instance.OpenStream(S);
  _Lang := Lang;
  Self.MergeGroup(Source, -1);
  Source.Destroy;

  If Application.Instance<>Nil Then
    Application.Instance.Language := Lang;
End;

Procedure StringManager.Reload();
Var
  S:TERRAString;
Begin
  S := _Lang;
  _Lang := '';

  SetLanguage(S);
End;

Procedure StringManager.RemoveGroup(GroupID: Integer);
Var
  I:Integer;
Begin
  I := 0;
  While (I<_StringCount) Do
  If (_Strings[I].Group = GroupID) Then
  Begin
    _Strings[I] := _Strings[Pred(_StringCount)];
    Dec(_StringCount);
  End Else
    Inc(I);
End;

Function StringManager.HasString(Const Key:TERRAString): Boolean;
Begin
  Result := GetString(Key)<>Self.EmptyString;
End;

Function StringManager.FormatString(Const Text:TERRAString; Loader:LocalizationLoader = Nil):TERRAString;
Var
  S1, S2, S3, S4, Replacement:TERRAString;
  C:TERRAChar;
  It:StringIterator;
  IsValidChar:Boolean;
Begin
  If Not StringSplitByChar(Text, S1, S2, Ord('@')) Then
  Begin
    Result := Text;
    Exit;
  End;

  Replacement := '';
  S4 := '';

  StringCreateIterator(S2, It);
  While It.HasNext Do
  Begin
    C := It.GetNext();
    IsValidChar := ((C>=Ord('a')) And (C<=Ord('z'))) Or ((C>=Ord('A')) And (C<=Ord('Z'))) Or ((C>=Ord('0')) And (C<=Ord('9'))) Or (C=Ord('_'));

    If Not IsValidChar Then
    Begin
      It.Split(S3, S4);
      StringPrependChar(S4, C);

      If Assigned(Loader) Then
        Replacement := Loader.GetString(S3)
      Else
        Replacement := Self.GetString(S3);

      If (Replacement = Self.EmptyString) Then
      Begin
        Log(logWarning, 'Localization', 'Could not find replacement string for "'+S3+'" in '+Text);
      End;

      Break;
    End;
  End;

  Result := S1 + Replacement + FormatString(S4, Loader);
End;

Type
  PinyinEntry = Record
    ID:Word;
    Text:TERRAString;
  End;

Var
  _PinyinCount:Integer;
  _PinyinData:Array Of PinyinEntry;

{ PinyinConverter }
Constructor PinyinConverter.Create;
Var
  Src:Stream;
  I:Integer;
Begin
  If (_PinyinCount>0) Then
    Exit;

  Src := FileManager.Instance.OpenStream('pinyin.dat');
  If Src = Nil Then
    Exit;

  Src.Read(@_PinyinCount, 4);
  SetLength(_PinyinData ,_PinyinCount);

  I := 0;
  While (Not Src.EOF) And (I<_PinyinCount) Do
  Begin
    Src.Read(@_PinyinData[I].ID, 2);
    Src.ReadString(_PinyinData[I].Text);
    Inc(I);
  End;
End;

Procedure PinyinConverter.GetSuggestions(Text:TERRAString);
Const
  MaxLength = 7;
Var
  It:StringIterator;
  N:Integer;
  Temp:TERRAString;
  C:TERRAChar;
Begin
  _SuggestionCount :=0 ;

  N := -1;
  StringCreateIterator(Text, It);
  While It.HasNext() Do
  Begin
    C := It.GetNext();
    If (C>255) Then
    Begin
      N := It.Position + 1;
      Break;
    End;
  End;

  If (N>0) Then
    Text := StringCopy(Text, N, MaxInt);

  If (Text='') Then
    Exit;

  If StringLength(Text)>MaxLength Then
    Text := StringCopy(Text, StringLength(Text )- MaxLength, MaxInt);

  Text := StringLower(Text);

  Temp := Text;
  While Text<>'' Do
  Begin
    Match(Text);
    Text := StringCopy(Text, 2, MaxInt);
  End;

  Text := Temp;
  While Text<>'' Do
  Begin
    Match(Text);
    Text := StringCopy(Text, 1, Pred(Length(Text)));
  End;

End;

Function PinyinConverter.GetResult(Index: Integer): Word;
Begin
  If (Index>=0) And (Index<Self.Results) Then
    Result := _Suggestions[Index].ID
  Else
    Result := 0;
End;

Procedure PinyinConverter.Match(S:TERRAString);
Var
  I:Integer;
Begin
  If (_SuggestionCount>=MaxPinyinSuggestions) Then
    Exit;

  For I:=0 To Pred(_PinyinCount) Do
  If (_PinyinData[I].Text = S) Then
  Begin
    Inc(_SuggestionCount);
    SetLength(_Suggestions, _SuggestionCount);
    _Suggestions[Pred(_SuggestionCount)].ID := _PinyinData[I].ID;
    _Suggestions[Pred(_SuggestionCount)].Text := S;
  End;
End;

Function PinyinConverter.Replace(var Text:TERRAString; Index: Integer):Boolean;
Var
  I:Integer;
  S,S2:TERRAString;
Begin
  Result := False;
  I := StringPosReverse(_Suggestions[Index].Text, Text);
  If (I<=0) Then
    Exit;

  S := Copy(Text, 1, Pred(I));
  S2 := Copy(Text, I+Length(_Suggestions[Index].Text), MaxInt);

  Text := S;
  StringAppendChar(Text, _Suggestions[Index].ID);
  Text := Text + S2;

  Result := True;
End;

Function GetLanguageDescription(Lang:TERRAString):TERRAString;
Begin
  Lang := StringUpper(Lang);

  If Lang = language_English Then
    Result := 'English'
  Else
  If Lang = language_German Then
    Result := 'Deutsch'
  Else
  If Lang = language_Spanish Then
    Result := 'Espa�ol'
  Else
  If Lang = language_Portuguese Then
    Result := 'Portugu�s'
  Else
  If Lang = language_French Then
    Result := 'Fran�ais'
  Else
  If Lang = language_Italian Then
    Result := 'Italiano'
  Else
  If Lang = language_Russian Then
    Result := StringFromChar(1056)+ StringFromChar(1091) + StringFromChar(1089) + StringFromChar(1089) + StringFromChar(1082) + StringFromChar(1080) + StringFromChar(1081)
  Else
  If Lang = language_Korean Then
    Result := StringFromChar(54620) + StringFromChar(44544)
  Else
  If Lang = language_Japanese Then
    Result := StringFromChar(26085) + StringFromChar(26412) + StringFromChar(35486)
  Else
  If Lang = language_Chinese Then
    Result := StringFromChar(20013) + StringFromChar(22269)
  Else
    Result := invalidString;
End;

{ LocalizationLoader }
Function LocalizationLoader.GetString(Const Key: TERRAString): TERRAString;
Begin
  Result := StringManager.Instance.GetString(Key);
End;

Initialization
Finalization
  If Assigned(_Manager) Then
    _Manager.Destroy;
End.