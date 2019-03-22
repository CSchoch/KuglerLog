unit uUSBDetection;

interface

uses
  Windows,
  Messages,
  SysUtils,
  Classes,
  Forms,
  DBT;

const
  GUID_DEVINTERFACE_USB_DEVICE : TGUID = '{A5DCBF10-6530-11D2-901F-00C04FB951ED}';

type
  TDriveLetters = array[0..25] of Char;
  TDriveNotifyEvent = procedure(Sender : TObject; Drive : string) of object;

  TComponentUSB = class(TComponent)
  private
    FWindowHandle : HWND;
    FOnUSBArrival : TDriveNotifyEvent;
    FOnUSBRemove : TDriveNotifyEvent;
    procedure WndProc(var Msg : TMessage);
    function USBRegister : Boolean;
    function BitMaskToChar(BitMask : DWORD) : TDriveLetters;
  protected
    procedure WMDeviceChange(var Msg : TMessage); dynamic;
  public
    constructor Create(AOwner : TComponent); override;
    destructor Destroy; override;
  published
    property OnUSBArrival : TDriveNotifyEvent read FOnUSBArrival write FOnUSBArrival;
    property OnUSBRemove : TDriveNotifyEvent read FOnUSBRemove write FOnUSBRemove;
  end;

{$INCLUDE Compilerswitches.inc}

implementation

constructor TComponentUSB.Create(AOwner : TComponent);
begin
  inherited Create(AOwner);
  FWindowHandle := Classes.AllocateHWnd(WndProc);
  USBRegister;
end;

destructor TComponentUSB.Destroy;
begin
  Classes.DeallocateHWnd(FWindowHandle);
  inherited Destroy;
end;

procedure TComponentUSB.WndProc(var Msg : TMessage);
begin
  if (Msg.Msg = WM_DEVICECHANGE) then
  begin
    try
      WMDeviceChange(Msg);
    except
      Application.HandleException(Self);
    end;
  end
  else
    Msg.Result := DefWindowProc(FWindowHandle, Msg.Msg, Msg.wParam, Msg.lParam);
end;

function TComponentUSB.BitMaskToChar(BitMask : DWORD) : TDriveLetters;
var
  i : integer;
begin
  for i := 0 to 25 do
  begin
    Result[i] := ' ';
    if (BitMask and 1) = 1 then
    begin
      Result[i] := Char(i + Ord('A'));
    end;
    BitMask := BitMask shr 1;
  end;
end;

procedure TComponentUSB.WMDeviceChange(var Msg : TMessage);
var
  devType : PDevBroadcastHdr;
  devTypeEx : PDevBroadcastVolume;
  Drives : TDriveLetters;
  i : Integer;
begin
  if (msg.WParam = DBT_DEVICEARRIVAL) or (msg.WParam = DBT_DEVICEREMOVECOMPLETE) then
  begin
    devType := PDevBroadcastHdr(Msg.LParam);
    if devType.dbch_devicetype = DBT_DEVTYP_VOLUME then
    begin
      devTypeEx := PDevBroadcastVolume(Msg.LParam);
      Drives := BitMaskToChar(devTypeEx.dbcv_unitmask);
      if Msg.wParam = DBT_DEVICEARRIVAL then
      begin
        if Assigned(FOnUSBArrival) then
        begin
          for i := 0 to 25 do
          begin
            if Drives[i] <> ' ' then
            begin
              FOnUSBArrival(Self, Drives[i] + ':\');
            end;
          end;
        end;
      end;
      if Msg.wParam = DBT_DEVICEREMOVECOMPLETE then
      begin
        if Assigned(FOnUSBRemove) then
        begin
          for i := 0 to 25 do
          begin
            if Drives[i] <> ' ' then
            begin
              FOnUSBRemove(Self, Drives[i] + ':\');
            end;
          end;
        end;
      end;
    end;
  end;
end;

function TComponentUSB.USBRegister : Boolean;
var
  dbi : DEV_BROADCAST_DEVICEINTERFACE_A;
  size : Integer;
  r : Pointer;
begin
  Result := False;
  size := SizeOf(DEV_BROADCAST_DEVICEINTERFACE_A);
  ZeroMemory(@dbi, size);
  dbi.dbcc_size := size;
  dbi.dbcc_devicetype := DBT_DEVTYP_DEVICEINTERFACE;
  dbi.dbcc_reserved := 0;
  dbi.dbcc_classguid := GUID_DEVINTERFACE_USB_DEVICE;
  dbi.dbcc_name := '';

  r := RegisterDeviceNotification(FWindowHandle,
    @dbi,
    DEVICE_NOTIFY_WINDOW_HANDLE
    );
  if Assigned(r) then
    Result := True;

end;

end.

