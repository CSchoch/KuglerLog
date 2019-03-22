unit fDataParserEditor;
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
  SynEditHighlighter,
  SynHighlighterPas,
  SynEditOptionsDialog,
  SynCompletionProposal,
  SynEdit,
  uPSComponent,
  uPSCompiler,
  uPSUtils,
  StdCtrls,
  IdGlobal,
  uPSComponent_Default,
  uPSRuntime,
  DateUtils,
  JvDialogs, SynEditCodeFolding;

type
  TDataParserEditor = class(TForm)
    eCode : TSynEdit;
    SynCompletionProposal1 : TSynCompletionProposal;
    SynPasSyn1 : TSynPasSyn;
    PSScript1 : TPSScript;
    btCompile : TButton;
    PSImport_DateUtils1 : TPSImport_DateUtils;
    mCompilerOutput : TMemo;
    btSave : TButton;
    sdCode : TSaveDialog;
    btOpen : TButton;
    odCode : TOpenDialog;
    PSImport_Classes1 : TPSImport_Classes;
    procedure btCompileClick(Sender : TObject);
    procedure PSScript1Compile(Sender : TPSScript);
    procedure btSaveClick(Sender : TObject);
    procedure btOpenClick(Sender : TObject);
    procedure bt1Click(Sender : TObject);
  private
    { Private-Deklarationen }
    FCompiled : Boolean;
  public
    { Public-Deklarationen }
    function DataToString(i_Datatyp : Integer; Data : TIdBytes) : string;
    procedure LoadFromFile(const FileName : string);
  end;

var
  DataParserEditor : TDataParserEditor;

implementation

{$R *.dfm}

procedure TDataParserEditor.btCompileClick(Sender : TObject);
var
  i : Integer;
  s_Messages : string;
  b_Compiled : Boolean;
begin
  mCompilerOutput.Lines.Clear;
  PSScript1.Script := eCode.Lines;
  b_Compiled := PSScript1.Compile;
  for i := 0 to PSScript1.CompilerMessageCount - 1 do
  begin
    s_Messages := s_Messages + PSScript1.CompilerMessages[i].MessageToString + #13#10;
  end;
  if b_Compiled then
  begin
    s_Messages := s_Messages + 'Succesfully compiled'#13#10;
  end;
  mCompilerOutput.Lines.Add('Compiled Script: '#13#10 + s_Messages);
end;

procedure TDataParserEditor.btOpenClick(Sender : TObject);
begin
  if odCode.Execute() and (odCode.FileName <> '') then
  begin
    eCode.Lines.LoadFromFile(odCode.FileName);
  end;
end;

procedure TDataParserEditor.btSaveClick(Sender : TObject);
begin
  if sdCode.Execute() and (sdCode.FileName <> '') then
  begin
    eCode.Lines.SaveToFile(sdCode.FileName);
  end;
end;

function TDataParserEditor.DataToString(i_Datatyp : Integer; Data : TIdBytes) : string;
var
  i : Integer;
  Messages : string;
begin
  if not FCompiled then
  begin
    PSScript1.Script := eCode.Lines;
    FCompiled := PSScript1.Compile;
  end;
  if FCompiled then
  begin
    if (Data <> nil) and ( High(Data) > 0) then
    begin
      Result := PSScript1.ExecuteFunction([i_Datatyp, Data], 'DataToString');
    end;
  end
  else
  begin
    Messages := 'Compiler Error: ';
    for i := 0 to PSScript1.CompilerMessageCount - 1 do
    begin
      Messages := Messages + PSScript1.CompilerMessages[i].MessageToString + #13#10;
      Result := Messages;
    end;
  end;
end;

procedure TDataParserEditor.LoadFromFile(const FileName : string);
begin
  eCode.Lines.LoadFromFile(FileName);
end;

function GetBool(const AValue : TIdBytes; const AIndex : Integer) : Boolean;
begin
  Result := AValue[AIndex] = 1;
end;

function GetWord(const AValue : TIdBytes; const AIndex : Integer) : Word;
begin
  Result := PWord(@AValue[AIndex])^;
end;

function GetDWord(const AValue : TIdBytes; const AIndex : Integer) : LongWord;
begin
  Result := PLongWord(@AValue[AIndex])^;
end;

function GetSint(const AValue : TIdBytes; const AIndex : Integer) : ShortInt;
begin
  Result := PShortInt(@AValue[AIndex])^;
end;

function GetUSint(const AValue : TIdBytes; const AIndex : Integer) : Byte;
begin
  Result := AValue[AIndex];
end;

function GetInt(const AValue : TIdBytes; const AIndex : Integer) : SmallInt;
begin
  Result := PSmallInt(@AValue[AIndex])^;
end;

function GetUInt(const AValue : TIdBytes; const AIndex : Integer) : Word;
begin
  Result := PWord(@AValue[AIndex])^;
end;

function GetDInt(const AValue : TIdBytes; const AIndex : Integer) : LongInt;
begin
  Result := PLongInt(@AValue[AIndex])^;
end;

function GetUDInt(const AValue : TIdBytes; const AIndex : Integer) : Cardinal;
begin
  Result := PCardinal(@AValue[AIndex])^;
end;

function GetReal(const AValue : TIdBytes; const AIndex : Integer) : Single;
begin
  Result := PSingle(@AValue[AIndex])^;
end;

function GetLReal(const AValue : TIdBytes; const AIndex : Integer) : Double;
begin
  Result := PDouble(@AValue[AIndex])^;
end;

function GetDateTime(const AValue : TIdBytes; const AIndex : Integer) : TDateTime;
var
  i_Date : Integer;
  i_Time : Integer;
begin
  i_Date := BytesToLongInt(AValue, AIndex + 4);
  i_Time := BytesToLongInt(AValue, AIndex);
  Result := 0;
  if (i_Time <> 0) or (i_Date <> 0) then
  begin
    Result := EncodeDateTime(1991, 12, 31, 0, 0, 0, 0);
    if i_Time <> 0 then
    begin
      Result := IncMilliSecond(Result, i_Time);
    end;
    if i_Date <> 0 then
    begin
      Result := IncDay(Result, i_Date);
    end;
  end;
end;

function GetDate(const AValue : TIdBytes; const AIndex : Integer) : TDate;
var
  i_Date : Integer;
begin
  i_Date := BytesToLongInt(AValue, AIndex);
  Result := 0;
  if i_Date <> 0 then
  begin
    Result := EncodeDateTime(1991, 12, 31, 0, 0, 0, 0);
    Result := IncDay(Result, i_Date);
  end;
end;

function GetTimeOfDay(const AValue : TIdBytes; const AIndex : Integer) : TTime;
var
  i_Time : Integer;
begin
  i_Time := BytesToLongInt(AValue, AIndex);
  Result := 0;
  if i_Time <> 0 then
  begin
    Result := EncodeDateTime(1991, 12, 31, 0, 0, 0, 0);
    Result := IncMilliSecond(Result, i_Time);
  end;
end;

function GetTime(const AValue : TIdBytes; const AIndex : Integer) : Cardinal;
begin
  Result := PCardinal(@AValue[AIndex])^;
end;

function SimotionTimeToString(ATime : Cardinal) : String;
var
  TempTime : Cardinal;
  Days : Cardinal;
  Hours : Cardinal;
  Minutes : Cardinal;
  Seconds : Cardinal;
  MilliSeconds : Cardinal;
  s : string;
begin
  s := 'T#';
  TempTime := ATime;
  Days := TempTime div MSecsPerDay;
  TempTime := TempTime - (Days * MSecsPerDay);
  if Days <> 0 then
  begin
    s := s + UIntToStr(Days) + 'd';
  end;
  Hours := TempTime div (SecsPerHour * MSecsPerSec);
  TempTime := TempTime - (Hours * SecsPerHour * MSecsPerSec);
  if Hours <> 0 then
  begin
    if Length(s) > 2 then
    begin
      s := s + '_';
    end;
    s := s + UIntToStr(Hours) + 'h';
  end;
  Minutes := TempTime div (SecsPerMin * MSecsPerSec);
  TempTime := TempTime - (Minutes * SecsPerMin * MSecsPerSec);
  if Minutes <> 0 then
  begin
    if Length(s) > 2 then
    begin
      s := s + '_';
    end;
    s := s + UIntToStr(Minutes) + 'm';
  end;
  Seconds := TempTime div MSecsPerSec;
  TempTime := TempTime - (Seconds * MSecsPerSec);
  if Seconds <> 0 then
  begin
    if Length(s) > 2 then
    begin
      s := s + '_';
    end;
    s := s + UIntToStr(Seconds) + 's';
  end;
  MilliSeconds := TempTime;
  if Length(s) > 2 then
  begin
    if MilliSeconds <> 0 then
    begin
      s := s + '_' + UIntToStr(MilliSeconds) + 'ms';
    end;
  end
  else
  begin
    s := s + UIntToStr(MilliSeconds) + 'ms';
  end;

  Result := s;
end;

procedure TDataParserEditor.bt1Click(Sender : TObject);
begin
  SimotionTimeToString(1001);
end;

function GetString(const AValue : TIdBytes; const AIndex : Integer; const ALength : Integer) : String;
begin
  // Index + 2 because simotion adds 2 bytes in front of string
  Result := Trim(BytesToString(AValue, AIndex + 2, ALength, TEncoding.UTF7));
end;

procedure TDataParserEditor.PSScript1Compile(Sender : TPSScript);
begin
  with Sender do
  begin
    with Comp do
    begin
      AddTypeS('TIdBytes', 'array of byte');
      AddTypeS('TDate', 'TDateTime');
      AddTypeS('TTime', 'TDateTime');
    end;
    AddFunction(@BytesToLongInt, 'function BytesToLongInt(const AValue: TIdBytes; const AIndex: Integer): LongInt;');
    AddFunction(@BytesToShort, 'function BytesToShort(const AValue: TIdBytes; const AIndex: Integer): Smallint;');
    AddFunction(@BytesToInt64, 'function BytesToInt64(const AValue: TIdBytes; const AIndex: Integer): Int64;');
    AddFunction(@BytesToWord, 'function BytesToWord(const AValue: TIdBytes; const AIndex: Integer): Word;');
    AddFunction(@BytesToLongWord, 'function BytesToLongWord(const AValue: TIdBytes; const AIndex: Integer): LongWord;');
    AddFunction(@GetBool, 'function GetBool(const AValue : TIdBytes; const AIndex : Integer) : Boolean;');
    AddFunction(@GetWord, 'function GetWord(const AValue : TIdBytes; const AIndex : Integer) : Word;');
    AddFunction(@GetDWord, 'function GetDWord(const AValue : TIdBytes; const AIndex : Integer) : LongWord;');
    AddFunction(@GetSint, 'function GetSint(const AValue : TIdBytes; const AIndex : Integer) : ShortInt;');
    AddFunction(@GetUSint, 'function GetUSint(const AValue : TIdBytes; const AIndex : Integer) : Byte;');
    AddFunction(@GetInt, 'function GetInt(const AValue : TIdBytes; const AIndex : Integer) : SmallInt;');
    AddFunction(@GetUInt, 'function GetUInt(const AValue : TIdBytes; const AIndex : Integer) : Word;');
    AddFunction(@GetDInt, 'function GetDInt(const AValue : TIdBytes; const AIndex : Integer) : LongInt;');
    AddFunction(@GetUDInt, 'function GetUDInt(const AValue : TIdBytes; const AIndex : Integer) : Cardinal;');
    AddFunction(@GetReal, 'function GetReal(const AValue : TIdBytes; const AIndex : Integer) : Single;');
    AddFunction(@GetLReal, 'function GetLReal(const AValue : TIdBytes; const AIndex : Integer) : Double;');
    AddFunction(@GetDateTime, 'function GetDateTime(const AValue : TIdBytes; const AIndex : Integer) : TDateTime;');
    AddFunction(@GetDate, 'function GetDate(const AValue : TIdBytes; const AIndex : Integer) : TDate;');
    AddFunction(@GetString,
      'function GetString(const AValue : TIdBytes; const AIndex : Integer; const ALength : Integer) : String;');
    AddFunction(@GetTime, 'function GetTime(const AValue : TIdBytes; const AIndex : Integer) : Cardinal;');
    AddFunction(@GetTimeOfDay, 'function GetTimeOfDay(const AValue : TIdBytes; const AIndex : Integer) : TTime;');
    AddFunction(@DateTimeToStr, 'function DateTimeToStr(const DateTime: TDateTime) : String;');
    AddFunction(@TimeToStr, 'function TimeToStr(const DateTime: TDateTime) : String;');
    AddFunction(@SimotionTimeToString, 'function SimotionTimeToString(const ATime : Cardinal) : String;');
  end;

end;

// function DataToString(i_Datatyp : Integer; Data : TIdBytes) : String;
// var
// i : integer;
// e : Extended;
// dt : TDateTime;
// BoolStrings : array[0..1] of String;
// s : String;
// begin
// BoolStrings[0] := 'FALSE';
// BoolStrings[1] := 'TRUE';
//
// Result := '';
// Result := Result + 'b_Test: ' + BoolStrings[Data[0]] + #13#10;
//
// i := GetInt(Data, 1);
// Result := Result + 'i_Test: ' + IntToStr(i) + #13#10;
//
// i := GetDInt(Data, 3);
// Result := Result + 'di_Test: ' + IntToStr(i) + #13#10;
//
// s := GetString(Data, 9, 10);
// Result := Result + 'str_Test: ' + s + #13#10;
//
// e := GetReal(Data, 19);
// Result := Result + 'r_Test: ' + FloatToStr(e) + #13#10;
//
// e := GetLReal(Data, 23);
// Result := Result + 'lr_Test: ' + FloatToStr(e) + #13#10;
//
// dt := GetDateTime(Data, 31);
// Result := Result + 'dt_Test: ' + DateTimeToStr(dt) + #13#10;
// end;



end.
