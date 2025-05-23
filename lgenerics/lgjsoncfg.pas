{****************************************************************************
*                                                                           *
*   This file is part of the LGenerics package.                             *
*   Storing configuration data in JSON files, replicates                    *
*   the TJSONConfig interface.                                              *
*                                                                           *
*   Copyright(c) 2023-2025 A.Koverdyaev(avk)                                *
*                                                                           *
*   This code is free software; you can redistribute it and/or modify it    *
*   under the terms of the Apache License, Version 2.0;                     *
*   You may obtain a copy of the License at                                 *
*     http://www.apache.org/licenses/LICENSE-2.0.                           *
*                                                                           *
*  Unless required by applicable law or agreed to in writing, software      *
*  distributed under the License is distributed on an "AS IS" BASIS,        *
*  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. *
*  See the License for the specific language governing permissions and      *
*  limitations under the License.                                           *
*                                                                           *
*****************************************************************************}
unit lgJsonCfg;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, lgUtils, lgHelpers, lgJson;

const
  DEF_FORMAT = [jfoSingleLineArray, jfoSingleLineObject, jfoEgyptBrace];

type
  EJsonConfError   = class(Exception);
  TConfigOption    = (coOverriteDuplicates);
  TConfigOptions   = set of TConfigOption;
  TJsonFormatStyle = lgJson.TJsonFormatStyle;
  TJsLineBreak     = lgJson.TJsLineBreak;

  { TJsonConf }

  TJsonConf = class(TComponent)
  private
    FFileName: string;
    FFormatStyle: TJsonFormatStyle;
    FOptions: TConfigOptions;
    FFormatted: Boolean;
    FCurrNode: TJsonNode;
    procedure DoSetFileName(const aFileName: string; aForceReload: Boolean);
    function  GetFormatIndentSize: Integer;
    function  GetFormatOptions: TJsFormatOptions;
    function  GetLineBreak: TJsLineBreak;
    procedure SetFileName(const aFileName: string);
    procedure SetFormatIndentSize(AValue: Integer);
    procedure SetFormatOptions(const AValue: TJsFormatOptions);
    procedure SetLineBreak(AValue: TJsLineBreak);
    function  StripSlash(const P: string) : string;
  protected
  const
    VALUE_KINDS = [jvkFalse, jvkTrue, jvkNumber, jvkString];
  var
    FRoot: TJsonNode;
    FModified: Boolean;
    procedure LoadFromFile(const aFileName: string);
    procedure Loaded; override;
    function  FindValue(const aPath: string; out aParent: TJsonNode; out aName: string): TJsonNode;
    function  FindPath(const aPath: string; aForceKey: Boolean): TJsonNode;
    function  FindObj(const aPath: string; aForceKey: Boolean): TJsonNode;
    function  FindObj(const aPath: string; aForceKey: Boolean; out aName: string): TJsonNode;
    function  FindElem(const aPath: string; aForceParent: Boolean; AllowObject: Boolean = False): TJsonNode;
    function  FindElem(const aPath: string; aForceParent: Boolean; out aParent: TJsonNode; out aName: string; AllowObject: Boolean = False): TJsonNode;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Reload;
    procedure Clear;
    procedure Flush;
    procedure Changed;
    procedure OpenKey(const aPath: string; aForceKey: Boolean);
    function  TryOpenKey(const aPath: string; aForceKey: Boolean): Boolean;
    procedure CloseKey;
    procedure ResetKey;
    procedure EnumSubKeys(const aPath: string; aList: TStrings);
    function  EnumSubKeys(const aPath: string): TStringArray;
    procedure EnumValues(const aPath: string; aList: TStrings);
    function  EnumValues(const aPath: string): TStringArray;

    function  GetValue(const aPath: string; const aDefault: string): string;
    function  GetValue(const aPath: string; aDefault: Integer): Integer;
    function  GetValue(const aPath: string; aDefault: Int64): Int64; //if in range[-(2^53 - 1),(2^53 - 1)]
    function  GetValue(const aPath: string; aDefault: Boolean): Boolean;
    function  GetValue(const aPath: string; aDefault: Double): Double;
    function  GetValue(const aPath: string; aValue: TStrings; const aDefault: string): Boolean;
    function  GetValue(const aPath: string; aValue: TStrings; const aDefault: TStrings): Boolean;
    function  GetValue(const aPath: string; const aDefault: TJVarArray): TJVarArray;

    procedure SetValue(const aPath: string; const aValue: string);
    procedure SetValue(const aPath: string; aValue: Integer);
    procedure SetValue(const aPath: string; aValue: Int64);//may be rounded if not in range[-(2^53 - 1),(2^53 - 1)]
    procedure SetValue(const aPath: string; aValue: Boolean);
    procedure SetValue(const aPath: string; aValue: Double);
    procedure SetValue(const aPath: string; aValue: TStrings; AsObject: Boolean = False);
    procedure SetValue(const aPath: string; const aValue: TJVarArray);
    procedure SetValue(const aPath: string; const aValue: TJPairArray);

    procedure SetDeleteValue(const aPath: string; const aValue, aDefValue: string);
    procedure SetDeleteValue(const aPath: string; aValue, aDefValue: Integer);
    procedure SetDeleteValue(const aPath: string; aValue, aDefValue: Int64);
    procedure SetDeleteValue(const aPath: string; aValue, aDefValue: Boolean);

    procedure DeletePath(const aPath: string);
    procedure DeleteValue(const aPath: string);
  { returns False if instance does not contain the key specified in aOldPath or already
    contains the key specified in aNewPath, otherwise renames the key and returns True }
    function  RenameKey(const aOldPath, aNewPath: string): Boolean;
  { closes the current key if it was opened before and recursively removes
    all keys containing empty objects }
    procedure Cleanup;
    property  Modified: Boolean read FModified;
    property  FormatStyle: TJsonFormatStyle read FFormatStyle write FFormatStyle;
  published
    property  FileName: string read FFileName write SetFileName;
    property  Formatted: Boolean read FFormatted write FFormatted;
    property  FormatOptions: TJsFormatOptions read GetFormatOptions write SetFormatOptions default DEF_FORMAT;
    property  FormatIndentSize: Integer read GetFormatIndentSize write SetFormatIndentSize default DEF_INDENT;
    property  LineBreak: TJsLineBreak read GetLineBreak write SetLineBreak default {$IFDEF WINDOWS}jlbCRLF{$ELSE}jlbLF{$ENDIF};
    property  Options: TConfigOptions read FOptions write FOptions;
  end;

implementation
{$B-}{$COPERATORS ON}{$POINTERMATH ON}

resourcestring
  SlgEInvalidJsonFileFmt = '"%s" is not a valid JSON configuration file';
  SlgECouldNotOpenKeyFmt = 'Could not open key "%s"';
  SlgDuplicateNameFmt    = 'Duplicate object member: "%s"';

{ TJsonConf }

procedure TJsonConf.DoSetFileName(const aFileName: string; aForceReload: Boolean);
begin
  if (not aForceReload) and (FFileName = aFileName) then exit;
  FFileName := aFileName;
  if csLoading in ComponentState then exit;
  Flush;
  if not FileExists(aFileName) then
    Clear
  else
    LoadFromFile(aFileName);
end;

function TJsonConf.GetFormatIndentSize: Integer;
begin
  Result := FFormatStyle.IndentSize;
end;

function TJsonConf.GetFormatOptions: TJsFormatOptions;
begin
  Result := FFormatStyle.Options;
end;

function TJsonConf.GetLineBreak: TJsLineBreak;
begin
  Result := FFormatStyle.LineBreak;
end;

procedure TJsonConf.SetFileName(const aFileName: string);
begin
  DoSetFileName(aFileName, False);
end;

procedure TJsonConf.SetFormatIndentSize(AValue: Integer);
begin
  FFormatStyle.IndentSize := AValue;
end;

procedure TJsonConf.SetFormatOptions(const AValue: TJsFormatOptions);
begin
  FFormatStyle.Options := AValue;
end;

procedure TJsonConf.SetLineBreak(AValue: TJsLineBreak);
begin
  FFormatStyle.LineBreak := AValue;
end;

function TJsonConf.StripSlash(const P: string): string;
begin
  if (P <> '') and (P[System.Length(P)] = '/') then
    Result := System.Copy(P, 1, Pred(System.Length(P)))
  else
    Result := P;
end;

procedure TJsonConf.LoadFromFile(const aFileName: string);
var
  Node: TJsonNode = nil;
begin
  if TJsonNode.TryParseFile(aFileName, Node) and (Node.IsObject) then
    begin
      FRoot.Free;
      FRoot := Node;
      FCurrNode := Node;
      exit;
    end
  else
    Node.Free;
  raise EJsonConfError.CreateFmt(SlgEInvalidJsonFileFmt,[aFileName]);
end;

procedure TJsonConf.Loaded;
begin
  inherited;
  Reload;
end;

function TJsonConf.FindValue(const aPath: string; out aParent: TJsonNode; out aName: string): TJsonNode;
begin
  Result := FindElem(StripSlash(APath), True, aParent, aName, True);
end;

function TJsonConf.FindPath(const aPath: string; aForceKey: Boolean): TJsonNode;
begin
  if (aPath = '') or (aPath[System.Length(aPath)] <> '/') then
    Result := FindObj(aPath + '/', aForceKey)
  else
    Result := FindObj(aPath, aForceKey);
end;

function TJsonConf.FindObj(const aPath: string; aForceKey: Boolean): TJsonNode;
var
  Dummy: string;
begin
  Result := FindObj(aPath, aForceKey, Dummy);
end;

function TJsonConf.FindObj(const aPath: string; aForceKey: Boolean; out aName: string): TJsonNode;
var
  Node, Next: TJsonNode;
  I, StartPos: SizeInt;
  Key: string;
begin
  if aPath = '' then
    begin
      aName := '';
      exit(FCurrNode);
    end;
  aName := '';
  StartPos := 1;
  if aPath[1] = '/' then
    begin
      Node := FRoot;
      Inc(StartPos);
    end
  else
    Node := FCurrNode;
  for I := StartPos to System.Length(aPath) do
    if aPath[I] = '/' then
      begin
        Key := System.Copy(aPath, StartPos, I - StartPos);
        StartPos := Succ(I);
        if Node.Find(Key, Next) then
          Node := Next
        else
          if aForceKey then
            Node := Node.AddNode(Key, jvkObject)
          else
            exit(nil);
      end;
  if StartPos <= System.Length(aPath) then
    aName := System.Copy(aPath, StartPos, System.Length(aPath));
  Result := Node;
end;

function TJsonConf.FindElem(const aPath: string; aForceParent: Boolean; AllowObject: Boolean): TJsonNode;
var
  o: TJsonNode;
  Dummy: string;
begin
  Result := FindElem(APath, aForceParent, o, Dummy, AllowObject);
end;

function TJsonConf.FindElem(const aPath: string; aForceParent: Boolean; out aParent: TJsonNode;
  out aName: string; AllowObject: Boolean): TJsonNode;
var
  Node: TJsonNode;
begin
  aParent := FindObj(aPath, aForceParent, aName);
  if (aParent <> nil) and aParent.Find(aName, Node) and ((Node.Kind <> jvkObject) or AllowObject) then
    exit(Node);
  Result := nil;
end;

constructor TJsonConf.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FRoot := TJsonNode.Create;
  FCurrNode := FRoot;
  FFormatStyle := lgJson.DefaultJsonFmtStyle;
end;

destructor TJsonConf.Destroy;
begin
  if FRoot <> nil then
    begin
      Flush;
      FRoot.Free;
    end;
  inherited;
end;

procedure TJsonConf.Reload;
begin
  if Filename <> '' then
    DoSetFileName(Filename, True);
end;

procedure TJsonConf.Clear;
begin
  FRoot.Clear;
  FCurrNode := FRoot;
  FModified := False;
end;

procedure TJsonConf.Flush;
begin
  if Modified then
    begin
      if Formatted then
        FRoot.SaveToFile(FileName, FormatStyle)
      else
        FRoot.SaveToFile(FileName);
      FModified := False;
    end;
end;

procedure TJsonConf.Changed;
begin
  FModified := True;
end;

procedure TJsonConf.OpenKey(const aPath: string; aForceKey: Boolean);
begin
  if aPath = '' then
    FCurrNode := FRoot
  else
    if aPath[System.Length(aPath)] <> '/' then
      FCurrNode := FindObj(aPath + '/', aForceKey)
    else
      FCurrNode := FindObj(aPath, aForceKey);
  if FCurrNode = nil then
    raise EJsonConfError.CreateFmt(SlgECouldNotOpenKeyFmt, [aPath]);
end;

function TJsonConf.TryOpenKey(const aPath: string; aForceKey: Boolean): Boolean;
var
  Node: TJsonNode;
begin
  if aPath = '' then
    Node := FRoot
  else
    if aPath[System.Length(aPath)] <> '/' then
      Node := FindObj(aPath + '/', aForceKey)
    else
      Node := FindObj(aPath, aForceKey);
  if Node = nil then exit(False);
  FCurrNode := Node;
  Result := True;
end;

procedure TJsonConf.CloseKey;
begin
  ResetKey;
end;

procedure TJsonConf.ResetKey;
begin
  FCurrNode := FRoot;
end;

procedure TJsonConf.EnumSubKeys(const aPath: string; aList: TStrings);
var
  Node: TJsonNode;
  I: Integer;
begin
  Node := FindPath(aPath, False);
  if Node <> nil then
    for I := 0 to Pred(Node.Count) do
      if Node.Items[I].IsObject then
        aList.Add(Node.Pairs[I].Key);
end;

function TJsonConf.EnumSubKeys(const aPath: string): TStringArray;
var
  r: TStringArray;
  Node: TJsonNode;
  I, Len: Integer;
begin
  Node := FindPath(aPath, False);
  if Node = nil then exit(nil);
  System.SetLength(r, Node.Count);
  Len := 0;
  for I := 0 to Pred(Node.Count) do
    if Node.Items[I].IsObject then
      begin
        r[Len] := Node.Pairs[I].Key;
        Inc(Len);
      end;
  System.SetLength(r, Len);
  Result := r;
end;

procedure TJsonConf.EnumValues(const aPath: string; aList: TStrings);
var
  Node: TJsonNode;
  I: Integer;
begin
  Node := FindPath(aPath, False);
  if Node <> nil then
    for I := 0 to Pred(Node.Count) do
      if not Node.Items[I].IsObject then
        aList.Add(Node.Pairs[I].Key);
end;

function TJsonConf.EnumValues(const aPath: string): TStringArray;
var
  r: TStringArray;
  Node: TJsonNode;
  I, Len: Integer;
begin
  Node := FindPath(aPath, False);
  System.SetLength(r, ARRAY_INITIAL_SIZE);
  Len := 0;
  if Node <> nil then
    for I := 0 to Pred(Node.Count) do
      if not Node.Items[I].IsObject then
        begin
          if System.Length(r) = Len then
            System.SetLength(r, Len * 2);
          r[Len] := Node.Pairs[I].Key;
          Inc(Len);
        end;
  System.SetLength(r, Len);
  Result := r;
end;

function TJsonConf.GetValue(const aPath: string; const aDefault: string): string;
var
  n: TJsonNode;
begin
  n := FindElem(StripSlash(aPath), False);
  if (n <> nil) and (n.Kind in VALUE_KINDS) then exit(n.ToString);
  Result := aDefault;
end;

function TJsonConf.GetValue(const aPath: string; aDefault: Integer): Integer;
var
  n: TJsonNode;
  I: Int64 = 0;
begin
  n := FindElem(StripSlash(aPath), False);
  if (n <> nil) and n.IsNumber and Double.IsExactInt(n.AsNumber, I) and
     (I <= High(Integer)) and (I >= Low(Integer)) then exit(Integer(I));
  Result := aDefault;
end;

function TJsonConf.GetValue(const aPath: string; aDefault: Int64): Int64;
var
  n: TJsonNode;
  I: Int64 = 0;
begin
  n := FindElem(StripSlash(aPath), False);
  if (n <> nil) and n.IsNumber and Double.IsExactInt(n.AsNumber, I) then exit(I);
  Result := aDefault;
end;

function TJsonConf.GetValue(const aPath: string; aDefault: Boolean): Boolean;
var
  n: TJsonNode;
begin
  n := FindElem(StripSlash(aPath), False);
  if (n <> nil) and n.IsBoolean then exit(n.AsBoolean);
  Result := aDefault;
end;

function TJsonConf.GetValue(const aPath: string; aDefault: Double): Double;
var
  n: TJsonNode;
begin
  n := FindElem(StripSlash(aPath), False);
  if (n <> nil) and n.IsNumber then exit(n.AsNumber);
  Result := aDefault;
end;

function TJsonConf.GetValue(const aPath: string; aValue: TStrings; const aDefault: string): Boolean;
var
  n, v: TJsonNode;
  p: TJsonNode.TPair;
begin
  aValue.Clear;
  n := FindElem(StripSlash(APath), False, True);
  if n <> nil then
    begin
      case n.Kind of
        jvkArray:
          for v in n do
            if v.Kind in VALUE_KINDS then
              aValue.Add(v.ToString);
        jvkObject:
          for p in n.Entries do
            if p.Value.Kind in VALUE_KINDS then
              aValue.Add(p.Key + '=' + p.Value.ToString);
      else
        aValue.Text := n.ToString;
      end;
      exit(True);
    end;
  aValue.Text := aDefault;
  Result := False;
end;

function TJsonConf.GetValue(const aPath: string; aValue: TStrings; const aDefault: TStrings): Boolean;
begin
  Result := GetValue(aPath, aValue, '');
  if not Result then
    aValue.Assign(aDefault);
end;

function TJsonConf.GetValue(const aPath: string; const aDefault: TJVarArray): TJVarArray;
var
  n, v: TJsonNode;
  I: SizeInt;
begin
  Result := nil;
  n := FindElem(StripSlash(APath), False, True);
  if (n <> nil) and n.IsArray then
    begin
      System.SetLength(Result, n.Count);
      I := 0;
      for v in n do
        if v.Kind in VALUE_KINDS then
          begin
            Result[I] := v.Value;
            Inc(I);
          end;
      System.SetLength(Result, I);
      exit;
    end;
  Result := aDefault;
end;

procedure TJsonConf.SetValue(const aPath: string; const aValue: string);
var
  n, p: TJsonNode;
  Key: string;
begin
  n := FindValue(aPath, p, Key);
  if n = nil then
    p.Add(Key, aValue)
  else
    n.AsString := aValue;
  FModified := True;
end;

procedure TJsonConf.SetValue(const aPath: string; aValue: Integer);
var
  n, p: TJsonNode;
  Key: string;
  d: Double;
begin
  n := FindValue(aPath, p, Key);
  d := aValue;
  if n = nil then
    p.Add(Key, d)
  else
    n.AsNumber := d;
  FModified := True;
end;

procedure TJsonConf.SetValue(const aPath: string; aValue: Int64);
var
  n, p: TJsonNode;
  Key: string;
  d: Double;
begin
  n := FindValue(aPath, p, Key);
  d := aValue;
  if n = nil then
    p.Add(Key, d)
  else
    n.AsNumber := d;
  FModified := True;
end;

procedure TJsonConf.SetValue(const aPath: string; aValue: Boolean);
var
  n, p: TJsonNode;
  Key: string;
begin
  n := FindValue(aPath, p, Key);
  if n = nil then
    p.Add(Key, aValue)
  else
    n.AsBoolean := aValue;
  FModified := True;
end;

procedure TJsonConf.SetValue(const aPath: string; aValue: Double);
var
  n, p: TJsonNode;
  Key: string;
begin
  n := FindValue(aPath, p, Key);
  if n = nil then
    p.Add(Key, aValue)
  else
    n.AsNumber := aValue;
  FModified := True;
end;

procedure TJsonConf.SetValue(const aPath: string; aValue: TStrings; AsObject: Boolean);
var
  n, p: TJsonNode;
  I: SizeInt;
  Key, Value: string;
begin
  n := FindValue(aPath, p, Key);
  if n = nil then
    if AsObject then
      n := p.AddNode(Key, jvkObject)
    else
      n := p.AddNode(Key, jvkArray)
  else
    if not AsObject then
      begin
        n.Clear;
        n.AsArray;
      end
    else
      n.AsObject;
  if AsObject then
    if coOverriteDuplicates in Options then
      for I := 0 to Pred(aValue.Count) do
        begin
          aValue.GetNameValue(I, Key, Value);
          n[Key].AsString := Value;
        end
    else
      for I := 0 to Pred(aValue.Count) do
        begin
          aValue.GetNameValue(I, Key, Value);
          if not n.TryAdd(Key, Value) then
            raise EJsonConfError.CreateFmt(SlgDuplicateNameFmt, [Key]);
        end
  else
    for Value in aValue do
      n.Add(Value);
  FModified := True;
end;

procedure TJsonConf.SetValue(const aPath: string; const aValue: TJVarArray);
var
  n, p: TJsonNode;
  I: SizeInt;
  k: string;
begin
  n := FindValue(aPath, p, k);
  if n = nil then
    p.Add(k, aValue)
  else
    begin
      n.Clear;
      n.AsArray;
      for I := 0 to System.High(aValue) do
        case aValue[I].Kind of
          vkNull:   ;
          vkBool:   n.Add(Boolean(aValue[I]));
          vkNumber: n.Add(Double(aValue[I]));
          vkString: n.Add(string(aValue[I]));
        end;
    end;
  FModified := True;
end;

procedure TJsonConf.SetValue(const aPath: string; const aValue: TJPairArray);
var
  n, p: TJsonNode;
  I: SizeInt;
  k: string;
  Ok: Boolean;
begin
  n := FindValue(aPath, p, k);
  if n = nil then
    n := p.AddNode(k, jvkObject)
  else
    n.AsObject;
  if coOverriteDuplicates in Options then
    for I := 0 to System.High(aValue) do
      with aValue[I] do
        n[Key].Value := Value
  else
    for I := 0 to System.High(aValue) do
      with aValue[I] do
        begin
          case Value.Kind of
            vkNull:   Ok := n.TryAddNull(Key);
            vkBool:   Ok := n.TryAdd(Key, Boolean(Value));
            vkNumber: Ok := n.TryAdd(Key, Double(Value));
          else // vkString
            Ok := n.TryAdd(Key, string(Value));
          end;
          if not Ok then
            raise EJsonConfError.CreateFmt(SlgDuplicateNameFmt, [Key]);
        end;
  FModified := True;
end;

procedure TJsonConf.SetDeleteValue(const aPath: string; const aValue, aDefValue: string);
begin
  if aValue = aDefValue then
    DeleteValue(aPath)
  else
    SetValue(aPath, aValue);
end;

procedure TJsonConf.SetDeleteValue(const aPath: string; aValue, aDefValue: Integer);
begin
  if aValue = aDefValue then
    DeleteValue(aPath)
  else
    SetValue(aPath, aValue);
end;

procedure TJsonConf.SetDeleteValue(const aPath: string; aValue, aDefValue: Int64);
begin
  if aValue = aDefValue then
    DeleteValue(aPath)
  else
    SetValue(aPath, aValue);
end;

procedure TJsonConf.SetDeleteValue(const aPath: string; aValue, aDefValue: Boolean);
begin
  if aValue = aDefValue then
    DeleteValue(aPath)
  else
    SetValue(aPath, aValue);
end;

procedure TJsonConf.DeletePath(const aPath: string);
var
  Node: TJsonNode;
  Key: string;
begin
  if (aPath = '') or (aPath = '/') then exit;
  Node := FindObj(StripSlash(aPath), False, Key);
  if (Node <> nil) and Node.Remove(Key) then
    FModified := True;
end;

procedure TJsonConf.DeleteValue(const aPath: string);
begin
  DeletePath(aPath);
end;

function TJsonConf.RenameKey(const aOldPath, aNewPath: string): Boolean;
var
  OldNode, NewNode, OldValue: TJsonNode;
  OldKey, NewKey: string;
  Path: TStringArray;
  I: SizeInt;
begin
  if (aOldPath = '') or (aOldPath = '/') or (aNewPath = '') or (aNewPath = '/') then
    exit(False);
  OldNode := FindObj(StripSlash(aOldPath), False, OldKey);
  if (OldNode = nil) or not OldNode.Find(OldKey, OldValue) then exit(False);
  if FindElem(StripSlash(aNewPath), False, True) <> nil then exit(False);
  NewNode := FindObj(StripSlash(aNewPath), True, NewKey);
  NewNode.AddNode(NewKey).CopyFrom(OldValue);
  if OldValue.IsObject and (FCurrNode <> FRoot) then // check that OldValue does not belong
    begin                                            // to the path of the current key
      Path := nil;
      if FRoot.TryGetPath(FCurrNode, Path) then
        for I := System.High(Path) downto 0 do
          if FRoot.FindPath(Path[0..I]) = OldValue then
            begin
              FCurrNode := FRoot;
              break;
            end;
    end;
  OldNode.Remove(OldKey);
  FModified := True;
  Result := True;
end;

procedure TJsonConf.Cleanup;
  procedure DoClean(aNode: TJsonNode);
  var
    I: SizeInt;
    Value: TJsonNode;
  begin
    if aNode.IsObject then
      for I := Pred(aNode.Count) downto 0 do
        begin
          Value := aNode.Items[I];
          if Value.IsObject then
            begin
              DoClean(Value);
              if Value.Count = 0 then
                begin
                  aNode.Delete(I);
                  FModified := True;
                end;
            end;
        end;
  end;
begin
  FCurrNode := FRoot;
  DoClean(FRoot);
end;

end.

