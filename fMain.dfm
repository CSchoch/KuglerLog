object MainForm: TMainForm
  Left = 0
  Top = 0
  Caption = 'Kugler Log '#169' by C.Schoch'
  ClientHeight = 299
  ClientWidth = 525
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnClose = FormClose
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  DesignSize = (
    525
    299)
  PixelsPerInch = 96
  TextHeight = 13
  object vstMain: TVirtualStringTree
    Left = 8
    Top = 89
    Width = 509
    Height = 202
    Anchors = [akLeft, akTop, akRight, akBottom]
    Header.AutoSizeIndex = 2
    Header.Font.Charset = DEFAULT_CHARSET
    Header.Font.Color = clWindowText
    Header.Font.Height = -11
    Header.Font.Name = 'Tahoma'
    Header.Font.Style = []
    Header.Options = [hoAutoResize, hoColumnResize, hoDrag, hoShowSortGlyphs, hoVisible]
    Header.PopupMenu = pmVSTHeader
    IncrementalSearch = isVisibleOnly
    IncrementalSearchTimeout = 2000
    PopupMenu = pmVST
    SelectionCurveRadius = 2
    TabOrder = 8
    TreeOptions.AutoOptions = [toAutoDropExpand, toAutoExpand, toAutoScroll, toAutoScrollOnExpand, toAutoTristateTracking, toAutoDeleteMovedNodes, toDisableAutoscrollOnFocus]
    TreeOptions.MiscOptions = [toAcceptOLEDrop, toFullRepaintOnResize, toInitOnSave, toToggleOnDblClick, toWheelPanning, toVariableNodeHeight, toEditOnClick]
    TreeOptions.PaintOptions = [toShowDropmark, toThemeAware, toUseBlendedImages]
    TreeOptions.SelectionOptions = [toFullRowSelect]
    OnBeforePaint = vstMainBeforePaint
    OnFocusChanged = vstMainFocusChanged
    OnFreeNode = vstMainFreeNode
    OnGetText = vstMainGetText
    OnIncrementalSearch = vstMainIncrementalSearch
    OnInitNode = vstMainInitNode
    OnNodeDblClick = vstMainNodeDblClick
    Columns = <
      item
        Position = 0
        Width = 140
        WideText = 'Hinzugef'#252'gt'
      end
      item
        Position = 1
        Width = 110
        WideText = 'Zeit'
      end
      item
        Position = 2
        Width = 205
        WideText = 'Text'
      end
      item
        Position = 3
        WideText = 'Typ'
      end>
  end
  object sePort: TJvSpinEdit
    Left = 164
    Top = 8
    Width = 53
    Height = 21
    ShowButton = False
    Value = 5000.000000000000000000
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
    TabOrder = 1
  end
  object cbConnect: TCheckBox
    Left = 223
    Top = 8
    Width = 74
    Height = 21
    Caption = 'Verbinden'
    TabOrder = 2
    OnClick = cbConnectClick
  end
  object cbShowDate: TCheckBox
    Left = 303
    Top = 8
    Width = 97
    Height = 21
    Caption = 'Datum anzeigen'
    Checked = True
    State = cbChecked
    TabOrder = 3
    OnClick = cbShowDateClick
  end
  object eSearch: TEdit
    Left = 8
    Top = 35
    Width = 388
    Height = 21
    Anchors = [akLeft, akTop, akRight]
    TabOrder = 5
    Text = 'Suchen...'
    OnChange = eSearchChange
    OnExit = eSearchExit
  end
  object cSearch: TComboBox
    Left = 402
    Top = 35
    Width = 115
    Height = 21
    Anchors = [akTop, akRight]
    TabOrder = 6
    Text = 'Alle'
    OnChange = eSearchChange
    Items.Strings = (
      'Alle'
      'Hinzugef'#252'gt'
      'Zeit'
      'Text'
      'Typ')
  end
  object btClear: TButton
    Left = 402
    Top = 8
    Width = 115
    Height = 21
    Caption = 'Leeren'
    TabOrder = 4
    OnClick = btClearClick
  end
  object eIP: TJvIPAddress
    Left = 8
    Top = 8
    Width = 150
    Height = 21
    Address = -1062731766
    ParentColor = False
    TabOrder = 0
  end
  object eLogFile: TJvFilenameEdit
    Left = 8
    Top = 62
    Width = 509
    Height = 21
    DefaultExt = 'txt'
    Filter = 'Log Dateien (*.txt)|*.txt'
    DialogOptions = [ofOverwritePrompt, ofHideReadOnly, ofEnableSizing]
    DialogTitle = 'Logdatei ausw'#228'hlen'
    Anchors = [akLeft, akTop, akRight]
    TabOrder = 7
    Text = 'C:\Log.txt'
  end
  object Panel1: TPanel
    Left = 8
    Top = 264
    Width = 509
    Height = 27
    Alignment = taLeftJustify
    Anchors = [akLeft, akRight, akBottom]
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
    TabOrder = 9
    Visible = False
    OnClick = Panel1Click
  end
  object XPManifest1: TXPManifest
    Left = 480
    Top = 80
  end
  object pmVSTHeader: TVTHeaderPopupMenu
    Left = 480
    Top = 112
  end
  object ApplicationEvents1: TApplicationEvents
    OnException = ApplicationEvents1Exception
    OnMessage = ApplicationEvents1Message
    Left = 480
    Top = 144
  end
  object pmVST: TPopupMenu
    Left = 480
    Top = 176
    object meController: TMenuItem
      Caption = 'Steuerung'
      Checked = True
      OnClick = meVSTClick
    end
    object meApp: TMenuItem
      Caption = 'Programm'
      Checked = True
      OnClick = meVSTClick
    end
    object meBinary: TMenuItem
      Caption = 'Bin'#228'r'
      OnClick = meVSTClick
    end
    object meError: TMenuItem
      Caption = 'Fehler'
      Checked = True
      OnClick = meVSTClick
    end
    object meDecoder: TMenuItem
      Caption = 'Decoder'
      OnClick = meDecoderClick
    end
    object meImport: TMenuItem
      Caption = 'Import'
      OnClick = meImportClick
    end
  end
  object JvEvents: TJvScheduledEvents
    AutoSave = False
    Events = <
      item
        Name = 'AutoSave'
        OnExecute = jvEventsEvents0Execute
        StartDate = '2010/09/25 00:00:00.000'
        RecurringType = srkDaily
        EndType = sekNone
        Freq_StartTime = 7200000
        Freq_EndTime = 7200000
        Freq_Interval = 1
        Daily_EveryWeekDay = False
        Daily_Interval = 1
      end
      item
        Name = 'CheckMemory'
        OnExecute = JvEventsEvents1Execute
        StartDate = '2017/05/03 21:32:52.000'
        RecurringType = srkDaily
        EndType = sekNone
        Freq_StartTime = 0
        Freq_EndTime = 86399000
        Freq_Interval = 300000
        Daily_EveryWeekDay = False
        Daily_Interval = 1
      end>
    Left = 480
    Top = 208
  end
  object tSearchDelay: TTimer
    Interval = 500
    OnTimer = tSearchDelayTimer
    Left = 480
    Top = 248
  end
  object tConnect: TTimer
    Enabled = False
    OnTimer = tConnectTimer
    Left = 448
    Top = 80
  end
  object odImport: TJvOpenDialog
    Filter = 'Simotion Export|*.xml'
    Options = [ofHideReadOnly, ofAllowMultiSelect, ofPathMustExist, ofFileMustExist, ofEnableSizing]
    Height = 0
    Width = 0
    Left = 448
    Top = 112
  end
end
