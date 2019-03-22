unit fMain;
{$INCLUDE Compilerswitches.inc}

interface

uses
  Windows,
  Messages,
  SysUtils,
  Variants,
  Classes,
  Graphics,
  Controls,
  Forms,
  Dialogs,
  VirtualTrees,
  StdCtrls,
  Mask,
  JvExMask,
  JvSpin,
  JvExControls,
  JvComCtrls,
  uDebugCom,
  IdGlobal,
  VTreeHelper,
  IdComponent,
  XPMan,
  Menus,
  ShlObj,
  VTHeaderPopup,
  StrUtils,
  AppEvnts,
  DateUtils,
  IdException,
  csUtils,
  ExtCtrls,
  JvToolEdit,
  JvScheduledEvents,
  DBT,
  uUSBDetection,
  Math,
  fDataParserEditor,
  fDataDisplay,
  csExplode,
  RegularExpressions,
  uImportExport,
  JvDialogs;

type
  TMainForm = class(TForm)
    vstMain : TVirtualStringTree;
    sePort : TJvSpinEdit;
    cbConnect : TCheckBox;
    cbShowDate : TCheckBox;
    XPManifest1 : TXPManifest;
    pmVSTHeader : TVTHeaderPopupMenu;
    eSearch : TEdit;
    cSearch : TComboBox;
    btClear : TButton;
    ApplicationEvents1 : TApplicationEvents;
    pmVST : TPopupMenu;
    meController : TMenuItem;
    meApp : TMenuItem;
    meBinary : TMenuItem;
    meError : TMenuItem;
    eIP : TJvIPAddress;
    eLogFile : TJvFilenameEdit;
    JvEvents : TJvScheduledEvents;
    tSearchDelay : TTimer;
    tConnect : TTimer;
    Panel1 : TPanel;
    meDecoder : TMenuItem;
    odImport : TJvOpenDialog;
    meImport : TMenuItem;
    procedure cbConnectClick(Sender : TObject);
    procedure DebugComConnectionStausChange(b_Connected : Boolean);
    procedure DebugComText(dt_Time : TDateTime; s_Text : string; i_Telegrammtyp : Integer; i_Datatyp : Integer;
      by_Data : TBytes; by_Binary : TBytes; b_Error : Boolean);
    procedure DebugComStatus(const AStatus : TIdStatus; const AStatusText : string; b_Error : Boolean);
    procedure FormCreate(Sender : TObject);
    procedure vstMainGetText(Sender : TBaseVirtualTree; Node : PVirtualNode; Column : TColumnIndex;
      TextType : TVSTTextType; var CellText : String);
    procedure vstMainInitNode(Sender : TBaseVirtualTree; ParentNode, Node : PVirtualNode;
      var InitialStates : TVirtualNodeInitStates);
    procedure vstMainFreeNode(Sender : TBaseVirtualTree; Node : PVirtualNode);
    procedure cbShowDateClick(Sender : TObject);
    procedure FormDestroy(Sender : TObject);
    procedure eSearchChange(Sender : TObject);
    procedure vstMainBeforePaint(Sender : TBaseVirtualTree; TargetCanvas : TCanvas);
    procedure btClearClick(Sender : TObject);
    procedure ApplicationEvents1Exception(Sender : TObject; E : Exception);
    procedure meVSTClick(Sender : TObject);
    procedure ApplicationEvents1Message(var Msg : tagMSG; var Handled : Boolean);
    procedure FormClose(Sender : TObject; var Action : TCloseAction);
    procedure jvEventsEvents0Execute(Sender : TJvEventCollectionItem; const IsSnoozeEvent : Boolean);
    procedure OnUSBArrival(Sender : TObject; Drive : string);
    procedure OnUSBLeave(Sender : TObject; Drive : string);
    procedure eSearchExit(Sender : TObject);
    procedure tSearchDelayTimer(Sender : TObject);
    procedure tConnectTimer(Sender : TObject);
    procedure vstMainIncrementalSearch(Sender : TBaseVirtualTree; Node : PVirtualNode; const SearchText : String;
      var Result : Integer);
    procedure Panel1Click(Sender : TObject);
    procedure vstMainNodeDblClick(Sender : TBaseVirtualTree; const HitInfo : THitInfo);
    procedure vstMainFocusChanged(Sender : TBaseVirtualTree; Node : PVirtualNode; Column : TColumnIndex);
    procedure meDecoderClick(Sender : TObject);
    procedure JvEventsEvents1Execute(Sender : TJvEventCollectionItem; const IsSnoozeEvent : Boolean);
    procedure meImportClick(Sender : TObject);
  private
    DebugCom : TDebugCom;
    USBDetection : TComponentUSB;
    DriveToExport : string;
    iFileCount : Integer;
    function EntryTypesToString(AEntryType : TEntryTypeSet) : string;
    procedure SearchCallback(Sender : TBaseVirtualTree; Node : PVirtualNode; Data : Pointer; var Abort : Boolean);
    procedure CheckNodeVisibility(Node : PVirtualNode);
    procedure LoadFromExport;
  public
    { Public-Deklarationen }
  end;

var
  MainForm : TMainForm;

implementation

{$R *.dfm}

procedure TMainForm.ApplicationEvents1Exception(Sender : TObject; E : Exception);
var
  Data : TTreeData;
  Node : PVirtualNode;
  Dummy : Boolean;
  i : Integer;
begin
  Data.dt_Added := Now;
  Data.dt_Date_Time := 0;
  Data.s_Text := 'Exception: ' + ReplaceText(E.Message, #$D#$A, ' ');
  Data.s_Data := '';
  Data.i_Telegrammtyp := 0;
  Data.EntryType := [];
  Include(Data.EntryType, App);
  Include(Data.EntryType, Error);
  Node := VSTHAdd(vstMain, Data, false);
  CheckNodeVisibility(Node);
  i := cSearch.Items.IndexOf(cSearch.Text);
  SearchCallback(vstMain, Node, @i, Dummy);
  if E is EIdException then
  begin
    if DebugCom <> nil then
    begin
      DebugCom.Disconnect;
      DebugCom.Connect;
    end;
  end;
end;

procedure TMainForm.ApplicationEvents1Message(var Msg : tagMSG; var Handled : Boolean);
begin
  case Msg.Message of
    WM_QUERYENDSESSION :
      begin
        if DebugCom <> nil then
        begin
          DebugCom.Disconnect;
        end;
        Close;
        Handled := True;
      end;
  end;
end;

procedure TMainForm.btClearClick(Sender : TObject);
var
  Node : PVirtualNode;
  Data : PTreeData;
  Stream : TFileStream;
  s : string;
  sFileName : string;
  sFileSource : string;
  sFileDest : string;
  Divider : TStringDivideIterator;

  procedure RollFilename(sFileName : string; iNumberOfFiles : Integer);
  var
    i : Integer;
  begin

    sFileDest := Format('%s_%d.txt', [CutExtension(sFileName), iNumberOfFiles]);
    DeleteFile(sFileDest);
    for i := iNumberOfFiles downto 2 do
    begin
      sFileSource := Format('%s_%d.txt', [CutExtension(sFileName), i]);
      sFileDest := Format('%s_%d.txt', [CutExtension(sFileName), i + 1]);
      if FileExists(sFileSource) then
      begin
        RenameFile(sFileSource, sFileDest);
      end;
    end;
    sFileSource := sFileName;
    sFileDest := Format('%s_%d.txt', [CutExtension(sFileName), 2]);
    if FileExists(sFileSource) and (iFileCount >= 2) then
    begin
      RenameFile(sFileSource, sFileDest);
    end;
  end;

begin
  sFileName := eLogFile.FileName;
  ForceDirectories(ExtractFilePath(sFileName));
  if FileExists(sFileName) then
  begin
    Stream := TFileStream.Create(sFileName, fmOpenReadWrite, fmShareDenyWrite);
    Stream.Seek(0, soFromEnd);
  end
  else
  begin
    Stream := TFileStream.Create(sFileName, fmCreate, fmShareDenyWrite);
  end;
  Node := vstMain.GetFirst();
  Divider := TStringDivideIterator.Create;
  Divider.Pattern := #13#10;

  while Node <> nil do
  begin
    Data := vstMain.GetNodeData(Node);
    if not (Binary in Data.EntryType) then
    begin
      s := '';
      try
        s := FormatDateTime('dd.mm.yyyy hh:nn:ss:zzz;', Data.dt_Added);
      except
        s := ';';
      end;
      if Data.dt_Date_Time <> 0 then
      begin
        try
          case Data.i_Telegrammtyp of
            0 :
              s := s + ';';
            1 :
              s := s + FormatDateTime('hh:nn:ss:zzz;', Data.dt_Date_Time);
            2 :
              s := s + FormatDateTime('dd.mm.yyyy hh:nn:ss:zzz;', Data.dt_Date_Time);
            3 :
              s := s + FormatDateTime('dd.mm.yyyy hh:nn:ss:zzz;', Data.dt_Date_Time);
          end;
        except
          s := s + ';';
        end;
      end
      else
      begin
        s := s + ';';
      end;
      s := s + Data.s_Text;
      if Data.s_Data <> '' then
      begin
        Divider.Text := Data.s_Data;
        while Divider.MoveNext do
        begin
          s := s + ';' + Divider.CurrentStr;
        end;
      end;
      s := s + CR + LF;
      Stream.WriteBuffer(PChar(s)^, Length(s) * SizeOf(Char));
      if Stream.Size div 1024 div 1024 > 500 then
      begin
        FreeAndNil(Stream);
        RollFilename(sFileName, iFileCount);
        Stream := TFileStream.Create(sFileName, fmCreate, fmShareDenyWrite);
      end;
    end;
    Node := vstMain.GetNext(Node);
  end;
  if (DriveToExport <> '') and DriveExists(DriveToExport) then
  begin
    s := DriveToExport + CutStartDir(sFileName, DriveToExport);
    ForceDirectories(ExtractFilePath(s));
    CopyFile(PChar(sFileName), PChar(s), false);
  end;
   FreeAndNil(Divider);
  FreeAndNil(Stream);
  vstMain.Clear;
end;

procedure TMainForm.cbConnectClick(Sender : TObject);
begin
  if (Sender as TCheckBox).Checked then
  begin
    DebugCom := TDebugCom.Create(eIP.Text, sePort.AsInteger);
    with DebugCom do
    begin
      OnConnectionStatusChange := DebugComConnectionStausChange;
      OnText := DebugComText;
      OnStatus := DebugComStatus;
      Connect;
    end;
  end
  else
  begin
    if DebugCom <> nil then
    begin
      DebugCom.Disconnect;
    end;
    FreeAndNil(DebugCom);
  end;
end;

procedure TMainForm.cbShowDateClick(Sender : TObject);
begin
  if (Sender as TCheckBox).Checked then
  begin
    vstMain.Header.Columns[0].Width := 150;
  end
  else
  begin
    vstMain.Header.Columns[0].Width := 110;
  end;
end;

procedure TMainForm.DebugComConnectionStausChange(b_Connected : Boolean);
begin
  //
end;

procedure TMainForm.DebugComStatus(const AStatus : TIdStatus; const AStatusText : string; b_Error : Boolean);
var
  Data : TTreeData;
  Node : PVirtualNode;
  Dummy : Boolean;
  i : Integer;
begin
  Data.dt_Added := Now;
  Data.dt_Date_Time := 0;
  Data.s_Text := ReplaceText(AStatusText, #$D#$A, ' ');
  Data.s_Data := '';
  Data.i_Telegrammtyp := 0;
  Data.EntryType := [];
  Include(Data.EntryType, App);
  if b_Error then
  begin
    Include(Data.EntryType, Error);
  end;
  Node := VSTHAdd(vstMain, Data, false);
  CheckNodeVisibility(Node);
  i := cSearch.Items.IndexOf(cSearch.Text);
  SearchCallback(vstMain, Node, @i, Dummy);
end;

procedure TMainForm.DebugComText(dt_Time : TDateTime; s_Text : string; i_Telegrammtyp : Integer; i_Datatyp : Integer;
  by_Data : TBytes; by_Binary : TBytes; b_Error : Boolean);
var
  Data : TTreeData;
  Node : PVirtualNode;
  Dummy : Boolean;
  i : Integer;
begin
  Data.dt_Added := Now;
  Data.dt_Date_Time := dt_Time;
  Data.s_Text := s_Text;
  Data.s_Data := DataParserEditor.DataToString(i_Datatyp, by_Data);
  Data.i_Telegrammtyp := i_Telegrammtyp;
  Data.EntryType := [];
  Include(Data.EntryType, Controller);
  if b_Error then
  begin
    Include(Data.EntryType, Error);
  end;
  Node := VSTHAdd(vstMain, Data, false);
  CheckNodeVisibility(Node);
  i := cSearch.Items.IndexOf(cSearch.Text);
  SearchCallback(vstMain, Node, @i, Dummy);
{$IFDEF DEBUG}
  OutputDebugString(PChar(Data.s_Data));
{$ENDIF}
  Data.dt_Added := Now;
  Data.dt_Date_Time := 0;
  Data.s_Text := '';
  Data.s_Data := '';
  Data.i_Telegrammtyp := 0;
  Data.EntryType := [];
  Include(Data.EntryType, Controller);
  Include(Data.EntryType, Binary);
  for i := 0 to High(by_Binary) do
  begin
    Data.s_Text := Data.s_Text + '[' + ByteToHex(by_Binary[i]) + ']';
  end;
  Node := VSTHAdd(vstMain, Data, false);
  CheckNodeVisibility(Node);
  i := cSearch.Items.IndexOf(cSearch.Text);
  SearchCallback(vstMain, Node, @i, Dummy);
{$IFDEF DEBUG}
  OutputDebugString(PChar(Data.s_Text));
{$ENDIF}
end;

procedure TMainForm.LoadFromExport;
var
  Importer : TXmlImport;
  ImportData : TImportData;
  str_ExportFile : String;
begin
  if odImport.Execute() then
  begin
    for str_ExportFile in odImport.Files do
    begin
      Importer := TXmlImport.Create(str_ExportFile);
      for ImportData in Importer.Data do
      begin
        OutputDebugString(PChar(ImportData.str_Description));
        DebugComText(ImportData.dt_Date + ImportData.tod_Time, ImportData.str_Description, 2, ImportData.i_DataType,
          ImportData.aby_Data, nil, false);
      end;
      FreeAndNil(Importer);
    end;
  end;
end;

function TMainForm.EntryTypesToString(AEntryType : TEntryTypeSet) : string;
begin
  Result := '';
  if Controller in AEntryType then
  begin
    Result := Result + 'Steuerung, ';
  end;
  if App in AEntryType then
  begin
    Result := Result + 'Programm, ';
  end;
  if Binary in AEntryType then
  begin
    Result := Result + 'Binär, ';
  end;
  if Error in AEntryType then
  begin
    Result := Result + 'Fehler, ';
  end;
  Result := Copy(Result, 0, Length(Result) - 2);
end;

procedure TMainForm.SearchCallback(Sender : TBaseVirtualTree; Node : PVirtualNode; Data : Pointer; var Abort : Boolean);
var
  NodeData : PTreeData;
  Visible : Boolean;

  function SearchAll : Boolean;
  begin
    try
      Result := AnsiContainsText(FormatDateTime('dd.mm.yyyy hh:nn:ss:zzz', NodeData.dt_Added), eSearch.Text) or
        AnsiContainsText(NodeData.s_Text, eSearch.Text) or AnsiContainsText(EntryTypesToString(NodeData.EntryType),
        eSearch.Text);
      case NodeData.i_Telegrammtyp of
        0 :
          ;
        1 :
          Result := Result or AnsiContainsText(FormatDateTime('hh:nn:ss:zzz', NodeData.dt_Date_Time), eSearch.Text);
        2 :
          Result := Result or AnsiContainsText(FormatDateTime('dd.mm.yyyy hh:nn:ss:zzz', NodeData.dt_Date_Time),
            eSearch.Text);
        3 :
          Result := Result or AnsiContainsText(FormatDateTime('dd.mm.yyyy hh:nn:ss:zzz', NodeData.dt_Date_Time),
            eSearch.Text);
      end;
    except
      Result := false;
    end;
  end;

begin
  NodeData := Sender.GetNodeData(Node);
  Visible := false;
  if eSearch.Text <> 'Suchen...' then
  begin
    case Integer(Data^) of
      0 :
        Visible := SearchAll;
      1 :
        Visible := AnsiContainsText(FormatDateTime('dd.mm.yyyy hh:nn:ss:zzz', NodeData.dt_Added), eSearch.Text);
      2 :
        case NodeData.i_Telegrammtyp of
          0 :
            Visible := false;
          1 :
            Visible := AnsiContainsText(FormatDateTime('hh:nn:ss:zzz', NodeData.dt_Date_Time), eSearch.Text);
          2 :
            Visible := AnsiContainsText(FormatDateTime('dd.mm.yyyy hh:nn:ss:zzz', NodeData.dt_Date_Time), eSearch.Text);
          3 :
            Visible := AnsiContainsText(FormatDateTime('dd.mm.yyyy hh:nn:ss:zzz', NodeData.dt_Date_Time), eSearch.Text);
        end;
      3 :
        Visible := AnsiContainsText(NodeData.s_Text, eSearch.Text);
      4 :
        Visible := AnsiContainsText(EntryTypesToString(NodeData.EntryType), eSearch.Text);
    end;
  end;
  Sender.IsVisible[Node] := (Visible or (eSearch.Text = 'Suchen...')) and NodeData.b_Visible;
end;

procedure TMainForm.tConnectTimer(Sender : TObject);
begin
  tConnect.Enabled := false;
  cbConnect.Checked := True;
end;

procedure TMainForm.tSearchDelayTimer(Sender : TObject);
var
  i : Integer;
begin
  i := cSearch.Items.IndexOf(cSearch.Text);
  with eSearch do
  begin
    if (Text <> '') or ((Text = 'Suchen...') and (Tag <> 0)) then
    begin
      if Text = 'Suchen...' then
      begin
        Tag := 0;
      end
      else
      begin
        Tag := 1;
      end;
      vstMain.IterateSubtree(nil, SearchCallback, @i);
    end;
  end;
  tSearchDelay.Enabled := false;
end;

procedure TMainForm.CheckNodeVisibility(Node : PVirtualNode);
var
  Data : PTreeData;
begin
  Data := vstMain.GetNodeData(Node);
  Data.b_Visible := ((Controller in Data.EntryType) and meController.Checked or not (Controller in Data.EntryType)) and
    ((Binary in Data.EntryType) and meBinary.Checked or not (Binary in Data.EntryType)) and
    ((App in Data.EntryType) and meApp.Checked or not (App in Data.EntryType)) and
    ((Error in Data.EntryType) and meError.Checked or not (Error in Data.EntryType));
  vstMain.IsVisible[Node] := Data.b_Visible;
end;

procedure TMainForm.eSearchChange(Sender : TObject);
// var
// i : Integer;
begin
  // i := cSearch.Items.IndexOf(cSearch.Text);
  // with eSearch do
  // begin
  // if (Text <> '') and (Text <> 'Suchen...') then
  // begin
  // vstMain.IterateSubtree(nil, SearchCallback, @i);
  // end;
  // end;
  tSearchDelay.Enabled := false;
  tSearchDelay.Enabled := True;
end;

procedure TMainForm.eSearchExit(Sender : TObject);
begin
  if eSearch.Text = '' then
  begin
    eSearch.Text := 'Suchen...';
  end;
end;

procedure TMainForm.FormClose(Sender : TObject; var Action : TCloseAction);
begin
  btClearClick(btClear);
end;

procedure TMainForm.FormCreate(Sender : TObject);
type
  TNext = (enextIdentifier, enextIP, enextPort, enextPath, enextName, enextDecoder, enextFileCount);
var
  i : Integer;
  eNext : TNext;
  bConnect : Boolean;
  sDecoderFilename : string;
const
  sMESSAGE : PChar = 'Mögliche Parameter:' + #13#10 + '-IP gefolgt von einem Leerzeichen und der IP-Addresse' + #13#10 +
    '-Port gefolgt von einem Leerzeichen und dem Port' + #13#10 +
    '-Path gefolgt von einem Leerzeichen und dem Pfad für das Logfile' + #13#10 +
    '-AutoConnect Automatisches verbinden nach dem Programmstart' + #13#10 +
    '-Name gefolgt von einem Leerzeichen und dem zusätzlichen Programmtitel' + #13#10 +
    '-Decoder gefolgt von einem Leerzeichen und dem Pfad für das Decoderscript' + #13#10 +
    '-FileCount gefolgt von einem Leerzeichen und der Anzahl der zu haltenden Logdateien';

begin
  VSTHCreate(vstMain);
  DataParserEditor := TDataParserEditor.Create(Self);
  eNext := enextIdentifier;
  bConnect := false;
  eLogFile.FileName := GetShellFolder(CSIDL_PERSONAL) + 'KuglerLog\Log.txt';
  sDecoderFilename := ExtractFilePath(Application.ExeName) + 'Decoder.kld';
  iFileCount := 4;
  for i := 1 to ParamCount do
  begin
    case eNext of
      enextIdentifier :
        begin
          case CaseStringIOf(ParamStr(i), ['-ip', '-port', '-path', '-autoconnect', '-name', '-decoder',
            '-filecount', '?']) of
            0 :
              eNext := enextIP;
            1 :
              eNext := enextPort;
            2 :
              eNext := enextPath;
            3 :
              bConnect := True;
            4 :
              eNext := enextName;
            5 :
              eNext := enextDecoder;
            6 :
              eNext := enextFileCount;
            7 :
              MessageBox(0, sMESSAGE, PChar(Application.Title), MB_ICONINFORMATION or MB_OK or MB_SETFOREGROUND or
                MB_TOPMOST);
          end;
        end;
      enextIP :
        begin
          eIP.Text := ParamStr(i);
          eNext := enextIdentifier;
        end;
      enextPort :
        begin
          sePort.AsInteger := StrToIntDef(ParamStr(i), 5000);
          eNext := enextIdentifier;
        end;
      enextPath :
        begin
          eLogFile.FileName := ParamStr(i);
          eNext := enextIdentifier;
        end;
      enextName :
        begin
          Self.Caption := Self.Caption + ' >> ' + ParamStr(i);
          Application.Title := ParamStr(i) + ' >> ' + Application.Title;
          eNext := enextIdentifier;
        end;
      enextDecoder :
        begin
          sDecoderFilename := ParamStr(i);
          eNext := enextIdentifier;
        end;
      enextFileCount :
        begin
          iFileCount := StrToIntDef(ParamStr(i), 4);
          eNext := enextIdentifier;
        end;
    end;
  end;
  if bConnect then
  begin
    tConnect.Enabled := True;
  end;
  if FileExists(sDecoderFilename) then
  begin
    DataParserEditor.LoadFromFile(sDecoderFilename);
  end;
  USBDetection := TComponentUSB.Create(Self);
  USBDetection.OnUSBArrival := OnUSBArrival;
  USBDetection.OnUSBRemove := OnUSBLeave;
end;

procedure TMainForm.FormDestroy(Sender : TObject);
begin
  if DebugCom <> nil then
  begin
    DebugCom.Disconnect;
  end;
  FreeAndNil(DebugCom);
end;

procedure TMainForm.jvEventsEvents0Execute(Sender : TJvEventCollectionItem; const IsSnoozeEvent : Boolean);
begin
  btClearClick(btClear);
end;

procedure TMainForm.JvEventsEvents1Execute(Sender : TJvEventCollectionItem; const IsSnoozeEvent : Boolean);
Var
  M : TMemoryStatus;
begin
  GlobalMemoryStatus(M);
  if (M.dwAvailVirtual / M.dwTotalVirtual) < 0.5 then
  begin
    btClearClick(btClear);
  end;
end;

procedure TMainForm.meDecoderClick(Sender : TObject);
begin
  DataParserEditor.ShowModal();
end;

procedure TMainForm.meImportClick(Sender : TObject);
begin
  LoadFromExport();
end;

procedure TMainForm.meVSTClick(Sender : TObject);
var
  Node : PVirtualNode;
begin
  (Sender as TMenuItem).Checked := not (Sender as TMenuItem).Checked;
  Node := vstMain.GetFirst();
  while Node <> nil do
  begin
    CheckNodeVisibility(Node);
    Node := vstMain.GetNext(Node);
  end;
end;

procedure TMainForm.OnUSBArrival(Sender : TObject; Drive : string);
begin
  DriveToExport := Drive;
  btClear.Caption := Format('Leeren (%s)', [Drive]);
end;

procedure TMainForm.OnUSBLeave(Sender : TObject; Drive : string);
begin
  if DriveToExport = Drive then
  begin
    DriveToExport := '';
    btClear.Caption := 'Leeren';
  end;
end;

procedure TMainForm.Panel1Click(Sender : TObject);
begin
  Panel1.Visible := false;
  vstMain.Height := vstMain.Height + Panel1.Height;
end;

procedure TMainForm.vstMainBeforePaint(Sender : TBaseVirtualTree; TargetCanvas : TCanvas);
begin
  // eSearchChange(eSearch);
end;

procedure TMainForm.vstMainFocusChanged(Sender : TBaseVirtualTree; Node : PVirtualNode; Column : TColumnIndex);
var
  Data : PTreeData;
begin
  Sender.ScrollIntoView(Node, false, false);
  Data := Sender.GetNodeData(Node);
  if Assigned(DataDisplay) then
  begin
    if DataDisplay.Visible then
    begin
      DataDisplay.SetText(Data.s_Data);
    end;
  end;
end;

procedure TMainForm.vstMainFreeNode(Sender : TBaseVirtualTree; Node : PVirtualNode);
var
  Data : PTreeData;
begin
  Data := Sender.GetNodeData(Node);
  Data^.dt_Added := 0;
  Data^.dt_Date_Time := 0;
  Data^.s_Text := '';
  Data^.s_Data := '';
  Data^.i_Telegrammtyp := 0;
end;

procedure TMainForm.vstMainGetText(Sender : TBaseVirtualTree; Node : PVirtualNode; Column : TColumnIndex;
  TextType : TVSTTextType; var CellText : String);
var
  Data : PTreeData;
  s : string;
begin
  CellText := '';
  Data := vstMain.GetNodeData(Node);
  if cbShowDate.Checked then
  begin
    s := 'dd.mm.yyyy hh:nn:ss:zzz';
  end
  else
  begin
    s := 'hh:nn:ss:zzz';
  end;
  try
    case Column of
      0 :
        if Data.dt_Added <> 0 then
        begin
          CellText := FormatDateTime(s, Data.dt_Added);
        end;
      1 :
        if Data.dt_Date_Time <> 0 then
        begin
          case Data.i_Telegrammtyp of
            0 :
              ;
            1 :
              CellText := FormatDateTime('hh:nn:ss:zzz', Data.dt_Date_Time);
            2 :
              CellText := FormatDateTime(s, Data.dt_Date_Time);
            3 :
              CellText := FormatDateTime(s, Data.dt_Date_Time);
          end;

        end;
      2 :
        CellText := Data.s_Text;
      3 :
        CellText := EntryTypesToString(Data.EntryType);
    end;
  except
  end;
end;

procedure TMainForm.vstMainIncrementalSearch(Sender : TBaseVirtualTree; Node : PVirtualNode; const SearchText : String;
  var Result : Integer);
var
  s : string;
  PropText : string;
  NodeData : PTreeData;

  function SearchAll : Integer;
  begin
    try
      PropText := FormatDateTime('dd.mm.yyyy hh:nn:ss:zzz', NodeData.dt_Added);
      Result := StrLIComp(PChar(s), PChar(PropText), Min(Length(s), Length(PropText)));
      if Result <> 0 then
      begin
        case NodeData.i_Telegrammtyp of
          0 :
            PropText := '';
          1 :
            PropText := FormatDateTime('hh:nn:ss:zzz', NodeData.dt_Date_Time);
          2 :
            PropText := FormatDateTime('dd.mm.yyyy hh:nn:ss:zzz', NodeData.dt_Date_Time);
          3 :
            PropText := FormatDateTime('dd.mm.yyyy hh:nn:ss:zzz', NodeData.dt_Date_Time);
        end;
        Result := StrLIComp(PChar(s), PChar(PropText), Min(Length(s), Length(PropText)));
        if Result <> 0 then
        begin
          Result := StrLIComp(PChar(s), PChar(NodeData.s_Text), Min(Length(s), Length(NodeData.s_Text)));
          if Result <> 0 then
          begin
            PropText := EntryTypesToString(NodeData.EntryType);
            Result := StrLIComp(PChar(s), PChar(PropText), Min(Length(s), Length(PropText)));
          end;
        end;
      end;
    except
      Result := 0;
    end;
  end;

begin
  NodeData := Sender.GetNodeData(Node);
  s := SearchText;
  Panel1.Caption := SearchText;
  if not Panel1.Visible then
  begin
    vstMain.Height := vstMain.Height - Panel1.Height;
    Panel1.Visible := True;
  end;

  case cSearch.Items.IndexOf(cSearch.Text) of
    0 :
      Result := SearchAll;
    1 :
      begin
        PropText := FormatDateTime('dd.mm.yyyy hh:nn:ss:zzz', NodeData.dt_Added);
        Result := StrLIComp(PChar(s), PChar(PropText), Min(Length(s), Length(PropText)));
      end;
    2 :
      begin
        case NodeData.i_Telegrammtyp of
          0 :
            PropText := '';
          1 :
            PropText := FormatDateTime('hh:nn:ss:zzz', NodeData.dt_Date_Time);
          2 :
            PropText := FormatDateTime('dd.mm.yyyy hh:nn:ss:zzz', NodeData.dt_Date_Time);
          3 :
            PropText := FormatDateTime('dd.mm.yyyy hh:nn:ss:zzz', NodeData.dt_Date_Time);
        end;
        Result := StrLIComp(PChar(s), PChar(PropText), Min(Length(s), Length(PropText)));
      end;
    3 :
      Result := StrLIComp(PChar(s), PChar(NodeData.s_Text), Min(Length(s), Length(NodeData.s_Text)));
    4 :
      begin
        PropText := EntryTypesToString(NodeData.EntryType);
        Result := StrLIComp(PChar(s), PChar(PropText), Min(Length(s), Length(PropText)));
      end;
  end;
  if Result = 0 then
  begin
    vstMain.ScrollIntoView(Node, false, false);
  end;
end;

procedure TMainForm.vstMainInitNode(Sender : TBaseVirtualTree; ParentNode, Node : PVirtualNode;
  var InitialStates : TVirtualNodeInitStates);
var
  Data : PTreeData;
begin
  Data := Sender.GetNodeData(Node);
  Data.dt_Added := 0;
  Data.dt_Date_Time := 0;
  Data.i_Telegrammtyp := 0;
  Data.s_Text := '';
  Data.s_Data := '';
  Data.EntryType := [];
  if not Sender.Focused then
  begin
    Sender.ScrollIntoView(Node, True, false);
  end;
end;

procedure TMainForm.vstMainNodeDblClick(Sender : TBaseVirtualTree; const HitInfo : THitInfo);
var
  Data : PTreeData;
begin
  Data := Sender.GetNodeData(HitInfo.HitNode);
  if (Data.s_Data <> '') or (Assigned(DataDisplay) and DataDisplay.Visible) then
  begin
    if not Assigned(DataDisplay) then
    begin
      DataDisplay := TDataDisplay.Create(Self);
    end;
    if (Data.s_Data <> '') and not DataDisplay.Visible then
    begin
      DataDisplay.Show;
    end;
    DataDisplay.SetText(Data.s_Data);
  end;
end;

end.
