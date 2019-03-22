unit VTreeHelper;

interface
{$INCLUDE Compilerswitches.inc}

uses
  VirtualTrees,
  Classes;

type
  TEntryType = (Controller, Binary, App, Error);
  TEntryTypeSet = set of TEntryType;
  PTreeData = ^TTreeData;
  TTreeData = record
    dt_Added : TDateTime;
    dt_Date_Time : TDateTime;
    s_Text : string;
    s_Data : string;
    i_Telegrammtyp : integer;
    b_Visible : Boolean;
    EntryType : TEntryTypeSet;
  end;

function VSTHAdd(AVST : TCustomVirtualStringTree; ARecord : TTreeData; Checked : boolean; ANode :
  PVirtualNode = nil) : PVirtualNode;
//function VSTHChange(AVST : TVirtualStringTree; ARecord : TTreeData; Checked : boolean; ANode :
//  PVirtualNode) : PVirtualNode;
function VSTHChecked(AVST : TCustomVirtualStringTree; ANode : PVirtualNode) : boolean;
procedure VSTHCreate(AVST : TVirtualStringTree);
procedure VSTHDel(AVST : TVirtualStringTree; ANode : PVirtualNode);

implementation

function VSTHAdd(AVST : TCustomVirtualStringTree; ARecord : TTreeData; Checked : boolean; ANode :
  PVirtualNode = nil) : PVirtualNode;
type
  TStringArray = array[0..1] of string;

  function Seperate(s : string) : TStringArray;
  var
    i : integer;
  begin
    result[0] := s;
    result[1] := '';
    for i := 0 to length(s) do
    begin
      if s[i] = ' ' then
      begin
        result[0] := copy(s, 0, i - 1);
        result[1] := copy(s, i + 1, length(s));
        break;
      end;
    end;
  end;
var
  SubData : PTreeData;
begin
  if ANode <> nil then
  begin
    AVST.HasChildren[ANode] := True;
  end;
  result := AVST.AddChild(ANode); // Name nicht vorhanden -> füge neuen Node hinzu
  SubData := AVST.GetNodeData(result); // Daten holen
  AVST.ValidateNode(result, false);
  SubData^ := ARecord; // Daten setzen
  if result <> nil then
  begin
    AVST.CheckState[result] := csCheckedNormal;
    if not Checked then
    begin
      AVST.CheckState[result] := csUncheckedNormal;
    end;
  end;
end;

//function VSTHChange(AVST : TVirtualStringTree; ARecord : TTreeData; Checked : boolean; ANode :
//  PVirtualNode) : PVirtualNode;
////var
////  NodeData : PTreeData;
////  sName : string;
////  slSkipFolders, slSkipFiles : TStringList;
//begin
//  //  sName := '';
//  //  if AVST.GetNodeLevel(ANode) = 1 then
//  //  begin
//  //    NodeData := AVST.GetNodeData(ANode.Parent);
//  //    sName := NodeData^.sName + ' ';
//  //  end;
//  //  NodeData := AVST.GetNodeData(ANode);
//  //  if ARecord.sName = sName + NodeData^.sName then
//  //  begin
//  //    result := ANode;
//  //    ARecord.sName := NodeData^.sName;
//  //    NodeData^ := ARecord;
//  //    AVST.CheckState[result] := csCheckedNormal;
//  //    if not Checked then
//  //    begin
//  //      AVST.CheckState[result] := csUncheckedNormal;
//  //    end;
//  //  end
//  //  else
//  //  begin
//  //    slSkipFolders := TStringList.Create;
//  //    slSkipFolders.Sorted := true;
//  //    slSkipFolders.Duplicates := dupIgnore;
//  //    slSkipFolders.Assign(ARecord.SkipFolders);
//  //    ARecord.SkipFolders := slSkipFolders;
//  //    slSkipFiles := TStringList.Create;
//  //    slSkipFiles.Sorted := true;
//  //    slSkipFiles.Duplicates := dupIgnore;
//  //    slSkipFiles.Assign(ARecord.SkipFiles);
//  //    ARecord.SkipFiles := slSkipFiles;
//  //    result := VSTHAdd(AVST, ARecord, Checked);
//  //    if result.Parent = ANode then
//  //    begin
//  //      ANode := AVST.GetFirstChild(ANode);
//  //    end;
//  //    VSTHDEL(AVST, ANode);
//  //  end;
//end;

function VSTHChecked(AVST : TCustomVirtualStringTree; ANode : PVirtualNode) : boolean;
var
  CheckState : TCheckState;
begin
  result := false;
  if ANode <> nil then
  begin
    CheckState := AVST.CheckState[ANode];
    result := CheckState = csCheckedNormal;
  end;
end;

procedure VSTHCreate(AVST : TVirtualStringTree);
begin
  AVST.NodeDataSize := SizeOf(TTreeData);
end;

procedure VSTHDel(AVST : TVirtualStringTree; ANode : PVirtualNode);
//var
//  RootNode, SubNode : PVirtualNode;
//  RootData, SubData : PTreeData;
//  s : string;
begin
  //  if Assigned(ANode) then
  //  begin
  //    if AVST.GetNodeLevel(ANode) = 1 then
  //    begin
  //      RootNode := ANode.Parent;
  //      AVST.DeleteNode(ANode);
  //      if AVST.ChildCount[RootNode] = 1 then
  //      begin
  //        SubNode := AVST.GetFirstChild(RootNode);
  //        RootData := AVST.GetNodeData(RootNode);
  //        SubData := AVST.GetNodeData(SubNode);
  //        s := RootData^.sName + ' ' + SubData^.sName;
  //        RootData^ := SubData^;
  //        RootData^.SkipFolders := TStringlist.Create;
  //        RootData^.SkipFolders.Sorted := true;
  //        RootData^.SkipFolders.Duplicates := dupIgnore;
  //        RootData^.SkipFolders.Assign(SubData^.SkipFolders);
  //        RootData^.SkipFiles := TStringlist.Create;
  //        RootData^.SkipFiles.Sorted := true;
  //        RootData^.SkipFiles.Duplicates := dupIgnore;
  //        RootData^.SkipFiles.Assign(SubData^.SkipFiles);
  //        RootData^.sName := s;
  //        AVST.CheckState[RootNode] := AVST.CheckState[SubNode];
  //        AVST.DeleteNode(SubNode);
  //      end;
  //    end
  //    else
  //    begin
  //      AVST.DeleteNode(ANode);
  //    end;
  //  end;
end;
end.

