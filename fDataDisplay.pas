unit fDataDisplay;

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
  StdCtrls;

type
  TDataDisplay = class(TForm)
    mData : TMemo;
  private
    { Private-Deklarationen }
  public
    procedure SetText(sText : String);
  end;

var
  DataDisplay : TDataDisplay;

implementation

{$R *.dfm}
{ TDataDisplay }

procedure TDataDisplay.SetText(sText : String);
begin
  mData.Clear;
  mData.Lines.Add(sText);
end;

end.
