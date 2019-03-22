object DataParserEditor: TDataParserEditor
  Left = 0
  Top = 0
  Caption = 'Kugler Log - Decoder Editor'
  ClientHeight = 626
  ClientWidth = 566
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  DesignSize = (
    566
    626)
  PixelsPerInch = 96
  TextHeight = 13
  object eCode: TSynEdit
    Left = 8
    Top = 8
    Width = 550
    Height = 484
    Anchors = [akLeft, akTop, akRight, akBottom]
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Courier New'
    Font.Style = []
    TabOrder = 0
    CodeFolding.GutterShapeSize = 11
    CodeFolding.CollapsedLineColor = clGrayText
    CodeFolding.FolderBarLinesColor = clGrayText
    CodeFolding.IndentGuidesColor = clGray
    CodeFolding.IndentGuides = True
    CodeFolding.ShowCollapsedLine = False
    CodeFolding.ShowHintMark = True
    UseCodeFolding = False
    Gutter.Font.Charset = DEFAULT_CHARSET
    Gutter.Font.Color = clWindowText
    Gutter.Font.Height = -11
    Gutter.Font.Name = 'Courier New'
    Gutter.Font.Style = []
    Gutter.ShowLineNumbers = True
    Highlighter = SynPasSyn1
    Lines.Strings = (
      
        'function DataToString(i_Datatyp : Integer; Data : TIdBytes) : St' +
        'ring;'
      'var'
      '  i : integer;'
      '  e : Extended;'
      '  dt : TDateTime;'
      '  t : Cardinal;'
      '  BoolStrings : array[0..1] of String;'
      '  s : String;'
      'begin'
      '  // BoolStrings[0] := '#39'FALSE'#39';'
      ' //  BoolStrings[1] := '#39'TRUE'#39';'
      ''
      '  //   Result := '#39#39';'
      
        '  //  Result := Result + '#39'b_Test: '#39' + BoolStrings[Data[0]] + #13' +
        '#10;'
      ''
      '  //   i := GetInt(Data, 1);'
      '  //  Result := Result + '#39'i_Test: '#39' + IntToStr(i) + #13#10;'
      ''
      '  //   i := GetDInt(Data, 3);'
      '  //  Result := Result + '#39'di_Test: '#39' + IntToStr(i) + #13#10;'
      ''
      '  //  s := GetString(Data, 9, 10);'
      '  //  Result := Result + '#39'str_Test: '#39' + s + #13#10;'
      ''
      '  //  e := GetReal(Data, 19);'
      '  //  Result := Result + '#39'r_Test: '#39' + FloatToStr(e) + #13#10;'
      ''
      '  //  e := GetLReal(Data, 23);'
      '  //  Result := Result + '#39'lr_Test: '#39' + FloatToStr(e) + #13#10;'
      ''
      '  //  dt := GetDateTime(Data, 31);'
      
        '  //  Result := Result + '#39'dt_Test: '#39' + DateTimeToStr(dt) + #13#1' +
        '0;'
      ''
      '  //  dt := GetDate(Data, 39);'
      
        '  //  Result := Result + '#39'd_Test: '#39' + DateTimeToStr(dt) + #13#10' +
        ';'
      ''
      '  //  dt := GetTimeOfDay(Data, 43);'
      '  //  Result := Result + '#39'tod_Test: '#39' + TimeToStr(dt) + #13#10;'
      '  '
      '  //  t := GetTime(Data, 47);'
      
        '  //  Result := Result + '#39't_Test: '#39' + SimotionTimeToString(t) + ' +
        '#13#10;'
      'end;')
    Options = [eoAltSetsColumnMode, eoAutoIndent, eoDragDropEditing, eoEnhanceEndKey, eoGroupUndo, eoScrollPastEol, eoShowScrollHint, eoSmartTabDelete, eoTabsToSpaces]
    TabWidth = 2
    WantTabs = True
    FontSmoothing = fsmNone
  end
  object btCompile: TButton
    Left = 8
    Top = 593
    Width = 75
    Height = 25
    Anchors = [akLeft, akBottom]
    Caption = 'Erzeugen'
    TabOrder = 1
    OnClick = btCompileClick
  end
  object mCompilerOutput: TMemo
    Left = 8
    Top = 498
    Width = 550
    Height = 89
    Anchors = [akLeft, akRight, akBottom]
    ScrollBars = ssBoth
    TabOrder = 2
  end
  object btSave: TButton
    Left = 89
    Top = 593
    Width = 75
    Height = 25
    Anchors = [akLeft, akBottom]
    Caption = 'Speichern'
    TabOrder = 3
    OnClick = btSaveClick
  end
  object btOpen: TButton
    Left = 170
    Top = 593
    Width = 75
    Height = 25
    Anchors = [akLeft, akBottom]
    Caption = #214'ffnen'
    TabOrder = 4
    OnClick = btOpenClick
  end
  object SynCompletionProposal1: TSynCompletionProposal
    ItemList.Strings = (
      'IntToStr(i : Integer)'
      'FloatToStr(F : Extended)'
      'BytesToLongInt(AValue: TIdBytes; AIndex: Integer)'
      'BytesToShort(AValue: TIdBytes; AIndex: Integer)'
      'BytesToInt64(AValue: TIdBytes; AIndex: Integer)'
      'BytesToWord(AValue: TIdBytes; AIndex: Integer)'
      'BytesToLongWord(AValue: TIdBytes; AIndex: Integer)'
      'GetBool(AValue : TIdBytes; AIndex : Integer)'
      'GetWord(AValue : TIdBytes; AIndex : Integer)'
      'GetDWord(AValue : TIdBytes; AIndex : Integer'
      'GetSint(AValue : TIdBytes; AIndex : Integer)'
      'GetUSint(AValue : TIdBytes; AIndex : Integer)'
      'GetInt(AValue : TIdBytes; AIndex : Integer)'
      'GetUInt(AValue : TIdBytes; AIndex : Integer)'
      'GetDInt(AValue : TIdBytes; AIndex : Integer)'
      'GetUDInt(AValue : TIdBytes; AIndex : Integer)'
      'GetReal(AValue : TIdBytes; AIndex : Integer)'
      'GetLReal(AValue : TIdBytes; AIndex : Integer)'
      'GetDateTime(AValue : TIdBytes; AIndex : Integer)'
      'GetDate(AValue : TIdBytes; AIndex : Integer)'
      'GetTimeOfDay(AValue : TIdBytes; AIndex : Integer)'
      
        'GetString(AValue : TIdBytes; AIndex : Integer; ALength : Integer' +
        ')'
      'GetTime(const AValue : TIdBytes; const AIndex : Integer)'
      'DateTimeToStr(DateTime: TDateTime)'
      'TimeToStr(DateTime: TDateTime)'
      'SimotionTimeToString(const ATime : Cardinal)')
    EndOfTokenChr = '()[]. '
    TriggerChars = '.'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    TitleFont.Charset = DEFAULT_CHARSET
    TitleFont.Color = clBtnText
    TitleFont.Height = -11
    TitleFont.Name = 'MS Sans Serif'
    TitleFont.Style = [fsBold]
    Columns = <>
    ShortCut = 16416
    Editor = eCode
    Left = 432
    Top = 592
  end
  object SynPasSyn1: TSynPasSyn
    Options.AutoDetectEnabled = False
    Options.AutoDetectLineLimit = 0
    Options.Visible = True
    CommentAttri.Foreground = clGreen
    KeyAttri.Foreground = clBlue
    NumberAttri.Foreground = clFuchsia
    FloatAttri.Foreground = clFuchsia
    HexAttri.Foreground = clFuchsia
    StringAttri.Foreground = clBlue
    Left = 400
    Top = 592
  end
  object PSScript1: TPSScript
    CompilerOptions = [icAllowNoBegin, icAllowNoEnd, icBooleanShortCircuit]
    OnCompile = PSScript1Compile
    Plugins = <
      item
        Plugin = PSImport_DateUtils1
      end
      item
        Plugin = PSImport_Classes1
      end>
    UsePreProcessor = False
    Left = 464
    Top = 592
  end
  object PSImport_DateUtils1: TPSImport_DateUtils
    Left = 496
    Top = 592
  end
  object sdCode: TSaveDialog
    DefaultExt = '.kld'
    Filter = 'Decoder (*.kld)|*.kld'
    Options = [ofHideReadOnly, ofPathMustExist, ofEnableSizing]
    Left = 368
    Top = 592
  end
  object odCode: TOpenDialog
    DefaultExt = '.kld'
    Filter = 'Decoder (*.kld)|*.kld'
    Options = [ofHideReadOnly, ofPathMustExist, ofFileMustExist, ofEnableSizing]
    Left = 336
    Top = 592
  end
  object PSImport_Classes1: TPSImport_Classes
    EnableStreams = True
    EnableClasses = True
    Left = 528
    Top = 592
  end
end
