program KuglerLog;

uses
  FastMM4,
  Forms,
  fMain in 'fMain.pas' {MainForm},
  uDebugCom in 'uDebugCom.pas',
  VTreeHelper in 'VTreeHelper.pas',
  uUSBDetection in 'uUSBDetection.pas',
  fDataParserEditor in 'fDataParserEditor.pas' {DataParserEditor},
  fDataDisplay in 'fDataDisplay.pas' {Form1},
  uImportExport in 'uImportExport.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.Title := 'Kugler Log';
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
