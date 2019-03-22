unit uImportExport;
{$INCLUDE Compilerswitches.inc}

interface

uses himXml,
  SysUtils,
  himXML_XPath,
  Windows,
  StrUtils,
  Generics.Collections,
  DateUtils,
  uDebugCom;

type
  TDataType = (dtString, dtData);
  TParseItem = (ptOthers, ptData, ptByteBuffer);

  TImportData = class(TObject)
    e_DataType : TDataType;
    ui_DataSize : Cardinal;
    tod_Time : TTime;
    dt_Date : TDate;
    str_Description : string;
    i_DataType : Integer;
    aby_Data : TBytes;
  end;

  TXmlImport = class(TObject)
  private
    FData : TList<TImportData>;
    procedure GetNodes(Nodes : TXMLNodeList; ParseItem : TParseItem = ptOthers);
    procedure ParseNodeItem(Node : TXMLNode; ParseItem : TParseItem);
  protected

  public
    constructor Create(FileName : String);
    destructor Destroy(); override;
    property Data : TList<TImportData>read FData;
  end;

implementation

constructor TXmlImport.Create(FileName : String);
var
  Xml : TXMLFile;
begin
  Xml := TXMLFile.Create();
  FData := TList<TImportData>.Create();
  Xml.LoadFromFile(FileName);
  GetNodes(Xml.Nodes);
  FreeAndNil(Xml);
  FData.Reverse;
end;

procedure TXmlImport.ParseNodeItem(Node : TXMLNode; ParseItem : TParseItem);
var
  i_temp : Integer;
  ImportData : TImportData;
  FormatSettings : TFormatSettings;
  sTemp : string;
begin
  if Node.Attributes.Exists('Name') then
  begin
    if Node.Attributes['Name'] = 'e_DataType' then
    begin
      ImportData := FData.Last;
      ImportData.e_DataType := Node.Attributes['value'];
    end
    else if Node.Attributes['Name'] = 'ui_DataSize' then
    begin
      ImportData := FData.Last;
      ImportData.ui_DataSize := Node.Attributes['value'];
    end
    else if Node.Attributes['Name'] = 'tod_Time' then
    begin
      ImportData := FData.Last;
      FormatSettings := TFormatSettings.Create();
      FormatSettings.ShortTimeFormat := 'h:nn:ss.zzz';
      FormatSettings.TimeSeparator := ':';
      sTemp := Node.Attributes['value'];
      sTemp := copy(sTemp, 1, Length(sTemp) - 4);
      ImportData.tod_Time := StrToTime(ReplaceStr(sTemp, 'TOD#', ''), FormatSettings);
      sTemp := Node.Attributes['value'];
      sTemp := copy(sTemp, Length(sTemp) - 2, 3);
      ImportData.tod_Time := IncMilliSecond(ImportData.tod_Time, StrToInt(sTemp));
    end
    else if Node.Attributes['Name'] = 'dt_Date' then
    begin
      ImportData := FData.Last;
      FormatSettings := TFormatSettings.Create();
      FormatSettings.ShortDateFormat := 'yyyy-mm-dd';
      FormatSettings.DateSeparator := '-';
      ImportData.dt_Date := StrToDate(ReplaceStr(Node.Attributes['value'], 'D#', ''), FormatSettings);
    end
    else if Node.Attributes['Name'] = 'str_Description' then
    begin
      ImportData := FData.Last;
      ImportData.str_Description := Node.Attributes['value'];
    end
    else if Node.Attributes['Name'] = 'i_DataType' then
    begin
      ImportData := FData.Last;
      ImportData.i_DataType := Node.Attributes['value'];
    end;
  end
  else if Node.Attributes.Exists('idx') then
  begin
    ImportData := FData.Last;
    ImportData.aby_Data[Integer(Node.Attributes['idx'])] := Node.Attributes['value'];
  end;
end;

destructor TXmlImport.Destroy;
var
  ImportData : TImportData;
begin
  for ImportData in FData do
  begin
    ImportData.Free;
  end;
  FreeAndNil(FData);
  inherited;
end;

procedure TXmlImport.GetNodes(Nodes : TXMLNodeList; ParseItem : TParseItem = ptOthers);
var
  i : Integer;
  Node : TXMLNode;
  Att : TXMLAttributeField;
  ImportData : TImportData;
begin
  // <Unit name="debuggingcom" >
  // <Format coding="XML" zip="YES" />
  // <Data >
  // <Segment name="IMPLEMENTATION_NORETAIN" number="5" />
  // <Item name="b_Connected" value="0" />
  // <Item name="b_Error" value="1" />
  // <Item name="b_Enable_Com" value="1" />
  // <Item name="b_StoreData" value="0" />
  // <Struct name="udt_Debug" >
  // <Array name="Data" startidx="0" >
  // <Struct idx="0" >
  // <Item name="e_DataType" value="0" />
  // <Item name="ui_DataSize" value="0" />
  // <Item name="tod_Time" value="TOD#5:57:34.088" />
  // <Item name="dt_Date" value="D#2018-06-02" />
  // <Item name="str_Description" value="MES Anforderung MHD Wechsel empfangen" />
  // <Item name="i_DataType" value="-1" />
  // <Array name="aby_Data" startidx="0" >
  // <Item idx="0" value="0" />
  // <Item idx="1" value="0" />
  // <Item idx="2" value="51" />
  // <Item idx="3" value="163" />
  // <Item idx="4" value="15" />

  for i := 0 to Nodes.Count - 1 do
  begin
    if ParseItem = ptData then
    begin
      ImportData := TImportData.Create();
      SetLength(ImportData.aby_Data, DATA_SIZE_PURE_DATA);
      FData.Add(ImportData);
    end;
    Node := Nodes[i];
    if Node.Name = 'Unit' then
    begin
      GetNodes(Node.Nodes);
    end
    else if Node.Name = 'Data' then
    begin
      GetNodes(Node.Nodes);
    end
    else if Node.Name = 'Struct' then
    begin
      if Node.Attributes.Exists('Name') then
      begin
        if Node.Attributes['Name'] = 'udt_Debug' then
        begin
          GetNodes(Node.Nodes);
        end;
      end
      else if Node.Attributes.Exists('idx') then
      begin
        GetNodes(Node.Nodes);
      end;
    end
    else if Node.Name = 'Array' then
    begin
      if Node.Attributes['Name'] = 'Data' then
      begin
        GetNodes(Node.Nodes, ptData);
      end
      else if Node.Attributes['Name'] = 'aby_Data' then
      begin
        GetNodes(Node.Nodes, ptByteBuffer);
      end;
    end
    else if Node.Name = 'Item' then
    begin
      ParseNodeItem(Node, ParseItem);
      GetNodes(Node.Nodes);
    end
  end;
end;

end.
