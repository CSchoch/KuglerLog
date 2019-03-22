unit uDebugCom;
{$INCLUDE Compilerswitches.inc}

interface

uses
  IdTCPClient,
  IdComponent,
  IdGlobal,
  SysUtils,
  ExtCtrls,
  DateUtils;

const
  HEADER_SIZE : Integer = 6; // STX(1) + Laufnummer(1) + Trennbyte(1) + Telegrammtyp(2) + Trennbyte(1)
  DATA_SIZE_TEXT_01 : Integer = 85; // Zeit(4) + Trennbyte(1) + Text(80)
  DATA_SIZE_TEXT_02 : Integer = 90; // Zeit(4) + Trennbyte(1) + Datum(4) + Trennbyte(1) + Text(80)
  DATA_SIZE_TEXT_03 : Integer = 1449;
  DATA_SIZE_TEXT_04 : Integer = 85; // Zeit(4) + Trennbyte(1) + Text(80) -> Adept spezial, da noch CRLF mit kommt
  // Zeit(4) + Trennbyte(1) + Datum(4) + Trennbyte(1) + Text(80) + Trennbyte(1) + Datentyp(2) + Trennbyte(1) + Daten(1355)
  DATA_SIZE_PURE_DATA : Integer = 1355;
  FOOTER_SIZE : Integer = 1; // ETX(1)
  DATA_SIZE_SPARE : Integer = 2; // CRLF(2)  -> Adept spezial, da noch CRLF mit kommt
type

  TOnConnectionStatusChange = procedure(b_Connected : Boolean) of object;
  TOnText = procedure(dt_Time : TDateTime; s_Text : string; i_Telegrammtyp : Integer; i_Datatyp : Integer;
    by_Data : TBytes; by_Binary : TBytes; b_Error : Boolean) of object;
  TOnStaus = procedure(const AStatus : TIdStatus; const AStatusText : string; b_Error : Boolean) of object;

  THeader = record
    by_Laufnummer : Byte;
    s_Telegrammtyp : string[2];
    b_IsDouble : Boolean;
    i_TotalSize : Integer;
  end;

  TDebugCom = class(TObject)
  private
    FClient : TIdTCPClient;
    FReciveTimer : TTimer;
    FBuffer : TBytes;
    FBufferSize : Integer;
    FRecLaufnummer : Byte;
    FConnect : Boolean;
    FOldConnected : Boolean;
    FOnConnectionStatusChange : TOnConnectionStatusChange;
    FOnText : TOnText;
    FOnStatus : TOnStaus;
    procedure ClientStatus(ASender : TObject; const AStatus : TIdStatus; const AStatusText : string);
    procedure OnReciveTimer(Sender : TObject);
    function GetHeaderData(Buffer : TBytes; by_RecLaufnummer : Byte) : THeader;
    function MakeSendData(by_Laufnummer : Byte; s_Telegram : string; Data : TBytes) : TBytes;
    function GetDateTime(i_Date, i_Time : Integer) : TDateTime;
    procedure ConvertTelegram01;
    procedure ConvertTelegram02;
    procedure ConvertTelegram03;
    procedure ConvertTelegram04;
  public
    constructor Create(s_IP : string; i_Port : Integer);
    destructor Destroy(); override;
    procedure Connect();
    procedure Disconnect();
    property OnConnectionStatusChange : TOnConnectionStatusChange read FOnConnectionStatusChange
      write FOnConnectionStatusChange;
    property OnText : TOnText read FOnText write FOnText;
    property OnStatus : TOnStaus read FOnStatus write FOnStatus;
  end;
{$INCLUDE Compilerswitches.inc}
  // Date and Time 0 = 1.1.1992 0:0:0:0 => TDateTime 0 = 30.12.1899 12:00:00

implementation

procedure TDebugCom.Connect;
begin
  FConnect := True;
  try
    FReciveTimer.Enabled := True;
    FClient.Connect;
  except
    on E : Exception do
    begin
      if Assigned(FOnStatus) then
      begin
        FOnStatus(TIdStatus(0), 'Exception: ' + E.Message, True);
      end;
    end;
  end;
end;

constructor TDebugCom.Create(s_IP : string; i_Port : Integer);
begin
  FClient := TIdTCPClient.Create(nil);
  with FClient do
  begin
    Name := 'Client';
    OnStatus := ClientStatus;
    ConnectTimeout := 2000;
    IPVersion := Id_IPv4;
    Port := i_Port;
    Host := s_IP;
    ReadTimeout := 500;
  end;
  FReciveTimer := TTimer.Create(nil);
  with FReciveTimer do
  begin
    Interval := 25;
    OnTimer := OnReciveTimer;
    Enabled := False;
  end;
end;

destructor TDebugCom.Destroy();
begin
  Self.Disconnect;
  FreeAndNil(FClient);
  FreeAndNil(FReciveTimer);
end;

procedure TDebugCom.Disconnect;
begin
  FConnect := False;
  try
    FClient.Disconnect;
  except
    on E : Exception do
    begin
      if Assigned(FOnStatus) then
      begin
        FOnStatus(TIdStatus(0), 'Exception: ' + E.Message, True);
      end;
    end;
  end;
end;

procedure TDebugCom.ConvertTelegram01;
var
  Temp_Time : TDateTime;
  s : string;
  i_Millisecond : Integer;
  i : Integer;
  buf : TArray<System.Byte>;
begin
  SetLength(buf, 4);
  for i := 0 to 3 do
  begin
    buf[3 - i] := FBuffer[i + HEADER_SIZE];
  end;
  i_Millisecond := BytesToLongInt(buf, 0);
  Temp_Time := GetDateTime(0, i_Millisecond);
  s := Trim(BytesToString(FBuffer, 11, 80, TEncoding.UTF7));
  if Assigned(FOnText) then
  begin
    FOnText(Temp_Time, s, 1, 0, nil, FBuffer, False);
  end;
end;

procedure TDebugCom.ConvertTelegram02;
var
  Temp_Time : TDateTime;
  s : string;
  i_Time : Integer;
  i_Date : Integer;
begin
  // Zeit
  i_Time := BytesToLongInt(FBuffer, HEADER_SIZE);
  // Datum
  i_Date := BytesToLongInt(FBuffer, HEADER_SIZE + 5); // 5 = Zeit(4) + Trennbyte (1)
  Temp_Time := GetDateTime(i_Date, i_Time);
  s := Trim(BytesToString(FBuffer, HEADER_SIZE + 10, 80, TEncoding.UTF7));
  // 10 = Zeit(4) + Trennbyte (1) + Datum(4) + Trennbyte (1)
  if Assigned(FOnText) then
  begin
    FOnText(Temp_Time, s, 2, 0, nil, FBuffer, False);
  end;
end;

procedure TDebugCom.ConvertTelegram03;
var
  Temp_Time : TDateTime;
  s : string;
  i_Time : Integer;
  i_Date : Integer;
  i_DataType : Integer;
  by_Data : TBytes;
begin
  // Zeit
  i_Time := BytesToLongInt(FBuffer, HEADER_SIZE);
  // Datum
  i_Date := BytesToLongInt(FBuffer, HEADER_SIZE + 5); // 5 = Zeit(4) + Trennbyte (1)
  Temp_Time := GetDateTime(i_Date, i_Time);
  s := Trim(BytesToString(FBuffer, HEADER_SIZE + 10, 80, TEncoding.UTF7));
  // 10 = Zeit(4) + Trennbyte (1) + Datum(4) + Trennbyte (1)
  i_DataType := BytesToShort(FBuffer, HEADER_SIZE + 91);
  // 91 = Zeit(4) + Trennbyte(1) + Datum(4) + Trennbyte(1) + Text(80) + Trennbyte(1)
  SetLength(by_Data, DATA_SIZE_PURE_DATA);
  Move(FBuffer[HEADER_SIZE + 94], by_Data[0], DATA_SIZE_PURE_DATA);
  // 94 = Zeit(4) + Trennbyte(1) + Datum(4) + Trennbyte(1) + Text(80) + Trennbyte(1) + Datentyp(2) + Trennbyte(1)
  if Assigned(FOnText) then
  begin
    FOnText(Temp_Time, s, 3, i_DataType, by_Data, FBuffer, False);
  end;
end;

procedure TDebugCom.ConvertTelegram04;
var
  Temp_Time : TDateTime;
  s : string;
  i_Millisecond : Integer;
  i : Integer;
  buf : TArray<System.Byte>;
begin
  SetLength(buf, 4);
  for i := 0 to 3 do
  begin
    buf[3 - i] := FBuffer[i + HEADER_SIZE];
  end;
  i_Millisecond := BytesToLongInt(buf, 0);
  Temp_Time := GetDateTime(0, i_Millisecond);
  s := Trim(BytesToString(FBuffer, 11, 80, TEncoding.UTF7));
  if Assigned(FOnText) then
  begin
    FOnText(Temp_Time, s, 1, 0, nil, FBuffer, False);
  end;
end;

procedure TDebugCom.ClientStatus(ASender : TObject; const AStatus : TIdStatus; const AStatusText : string);
begin
  if Assigned(FOnStatus) then
  begin
    FOnStatus(AStatus, AStatusText, False);
  end;
end;

procedure TDebugCom.OnReciveTimer(Sender : TObject);
var
  TempHeader : THeader;
  SendBuffer : TArray<System.Byte>;
  buf : TArray<System.Byte>;
begin
  FReciveTimer.Enabled := False;
  try
    if FClient.IOHandler <> nil then
    begin
      while not FClient.IOHandler.InputBufferIsEmpty do
      begin
        if (FClient.IOHandler.InputBuffer.Size >= HEADER_SIZE) and (FBufferSize < HEADER_SIZE) then
        begin
          FClient.IOHandler.ReadBytes(FBuffer, HEADER_SIZE, False);
          FBufferSize := FBufferSize + HEADER_SIZE;
        end;
        if FBufferSize >= HEADER_SIZE then
        begin
          TempHeader := GetHeaderData(FBuffer, FRecLaufnummer);
        end
        else
        begin
          Break;
        end;
        if TempHeader.i_TotalSize = 0 then
        begin
          Break;
        end;
        if ((FClient.IOHandler.InputBuffer.Size + FBufferSize) >= TempHeader.i_TotalSize) and
          (FBufferSize >= HEADER_SIZE) then
        begin
          FClient.IOHandler.ReadBytes(FBuffer, TempHeader.i_TotalSize - FBufferSize, True);
          if TempHeader.s_Telegrammtyp = '01' then
          begin
            if not TempHeader.b_IsDouble then
            begin
              ConvertTelegram01;
            end;
            FRecLaufnummer := TempHeader.by_Laufnummer;
            buf := MakeSendData(FRecLaufnummer, '11', nil);
            SetLength(SendBuffer, Length(SendBuffer) + Length(buf));
            Move(buf[0], SendBuffer[Length(SendBuffer) - Length(buf)], Length(buf));
          end
          else if TempHeader.s_Telegrammtyp = '02' then
          begin
            if not TempHeader.b_IsDouble then
            begin
              ConvertTelegram02;
            end;
            FRecLaufnummer := TempHeader.by_Laufnummer;
            buf := MakeSendData(FRecLaufnummer, '12', nil);
            SetLength(SendBuffer, Length(SendBuffer) + Length(buf));
            Move(buf[0], SendBuffer[Length(SendBuffer) - Length(buf)], Length(buf));
          end
          else if TempHeader.s_Telegrammtyp = '03' then
          begin
            if not TempHeader.b_IsDouble then
            begin
              ConvertTelegram03;
            end;
            FRecLaufnummer := TempHeader.by_Laufnummer;
            buf := MakeSendData(FRecLaufnummer, '13', nil);
            SetLength(SendBuffer, Length(SendBuffer) + Length(buf));
            Move(buf[0], SendBuffer[Length(SendBuffer) - Length(buf)], Length(buf));
          end
          else if TempHeader.s_Telegrammtyp = '04' then
          begin
            if not TempHeader.b_IsDouble then
            begin
              ConvertTelegram04;
            end;
            FRecLaufnummer := TempHeader.by_Laufnummer;
            buf := MakeSendData(FRecLaufnummer, '11', nil);
            SetLength(SendBuffer, Length(SendBuffer) + Length(buf));
            Move(buf[0], SendBuffer[Length(SendBuffer) - Length(buf)], Length(buf));
          end;
          FBufferSize := 0;
          SetLength(FBuffer, 0);
        end
        else
        begin
          Break;
        end;
      end;
    end;
    if Length(SendBuffer) <> 0 then
    begin
      FClient.IOHandler.Write(SendBuffer);
    end;
    FClient.CheckForGracefulDisconnect(False);
  except
    on E : Exception do
    begin
      if Assigned(FOnStatus) then
      begin
        FOnStatus(TIdStatus(0), 'Exception: ' + E.Message, True);
      end;
      FBufferSize := 0;
      SetLength(FBuffer, 0);
      Self.Disconnect;
      Self.Connect;
    end;
  end;
  if Assigned(FOnConnectionStatusChange) and FOldConnected <> FClient.Connected then
  begin
    FOnConnectionStatusChange(FClient.Connected);
  end;
  FOldConnected := FClient.Connected;
  if not FClient.Connected and FConnect then
  begin
    Self.Connect;
  end;
  if not FClient.Connected then
  begin
    FBufferSize := 0;
    SetLength(FBuffer, 0);
    if FClient.IOHandler <> nil then
    begin
      FClient.IOHandler.InputBuffer.Clear;
    end;
  end;
  FReciveTimer.Enabled := True;
end;

function TDebugCom.GetDateTime(i_Date, i_Time : Integer) : TDateTime;
begin
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

function TDebugCom.GetHeaderData(Buffer : TBytes; by_RecLaufnummer : Byte) : THeader;
begin
  Result.by_Laufnummer := Buffer[1];
  Result.s_Telegrammtyp := BytesToString(Buffer, 3, 5);
  Result.b_IsDouble := (Result.by_Laufnummer = by_RecLaufnummer) and (Result.by_Laufnummer <> 0);
  if Result.s_Telegrammtyp = '01' then
  begin
    Result.i_TotalSize := HEADER_SIZE + DATA_SIZE_TEXT_01 + FOOTER_SIZE;
  end
  else if Result.s_Telegrammtyp = '02' then
  begin
    Result.i_TotalSize := HEADER_SIZE + DATA_SIZE_TEXT_02 + FOOTER_SIZE;
  end
  else if Result.s_Telegrammtyp = '03' then
  begin
    Result.i_TotalSize := HEADER_SIZE + DATA_SIZE_TEXT_03 + FOOTER_SIZE;
  end
    else if Result.s_Telegrammtyp = '04' then
  begin
    Result.i_TotalSize := HEADER_SIZE + DATA_SIZE_TEXT_04 + FOOTER_SIZE + DATA_SIZE_SPARE;
  end;
end;

function TDebugCom.MakeSendData(by_Laufnummer : Byte; s_Telegram : string; Data : TBytes) : TBytes;
var
  i : Integer;
begin
  SetLength(Result, HEADER_SIZE + Length(Data) + FOOTER_SIZE);
  Result[0] := 2;
  Result[1] := by_Laufnummer;
  Result[2] := Byte('.');
  CopyTIdString(s_Telegram, Result, 3, 2, TEncoding.UTF7);
  Result[5] := Byte('.');
  if Data <> nil then
  begin
    for i := 0 to Length(Data) do
    begin
      Result[i + 6] := Data[i];
    end;
  end;
  Result[Length(Data) + 6] := 3;
end;

end.
