unit ansi_parser;

{$mode objfpc}{$H+}

interface

type
  TAnsiParserState = (apsGround, apsEscape, apsCSI, apsString, apsStringEscape);
  TAnsiSequenceKind = (askNone, askEscape, askCSI, askString);
  TAnsiParams = array of Integer;

  TAnsiSequence = record
    Kind: TAnsiSequenceKind;
    FinalChar: Char;
    PrivateMarker: Char;
    Intermediates: string;
    Params: TAnsiParams;
    StringCommand: Char;
    StringData: UTF8String;
  end;

  TAnsiParser = class
  private
    FState: TAnsiParserState;
    FParamText: string;
    FPrivateMarker: Char;
    FIntermediates: string;
    FStringCommand: Char;
    FStringData: UTF8String;
    procedure ParseParams(out AParams: TAnsiParams);
    function FinishString(out ASequence: TAnsiSequence): Boolean;
    procedure AppendStringByte(AChar: Char);
    procedure ResetSequenceState;
  public
    constructor Create;
    procedure Reset;
    function Feed(AChar: Char; out ASequence: TAnsiSequence): Boolean;
    property State: TAnsiParserState read FState;
  end;

implementation

uses SysUtils;

const
  MaxAnsiStringLength = 65536;

constructor TAnsiParser.Create;
begin
  inherited Create;
  Reset;
end;

procedure TAnsiParser.ResetSequenceState;
begin
  FParamText := '';
  FPrivateMarker := #0;
  FIntermediates := '';
  FStringCommand := #0;
  FStringData := '';
end;

procedure TAnsiParser.Reset;
begin
  FState := apsGround;
  ResetSequenceState;
end;

procedure TAnsiParser.ParseParams(out AParams: TAnsiParams);
var I, StartPos, Count: Integer; Part: string;
begin
  SetLength(AParams, 0);
  if FParamText = '' then Exit;
  Count := 1;
  for I := 1 to Length(FParamText) do
    if FParamText[I] = ';' then Inc(Count);
  SetLength(AParams, Count);
  StartPos := 1;
  Count := 0;
  for I := 1 to Length(FParamText) + 1 do
    if (I > Length(FParamText)) or (FParamText[I] = ';') then
    begin
      Part := Copy(FParamText, StartPos, I - StartPos);
      if Part = '' then AParams[Count] := -1
      else AParams[Count] := StrToIntDef(Part, -1);
      Inc(Count);
      StartPos := I + 1;
    end;
end;

procedure TAnsiParser.AppendStringByte(AChar: Char);
begin
  if Length(FStringData) < MaxAnsiStringLength then
    FStringData := FStringData + AChar;
end;

function TAnsiParser.FinishString(out ASequence: TAnsiSequence): Boolean;
begin
  ASequence.Kind := askString;
  ASequence.FinalChar := #0;
  ASequence.PrivateMarker := #0;
  ASequence.Intermediates := '';
  SetLength(ASequence.Params, 0);
  ASequence.StringCommand := FStringCommand;
  ASequence.StringData := FStringData;
  Result := True;
  Reset;
end;

function TAnsiParser.Feed(AChar: Char; out ASequence: TAnsiSequence): Boolean;
begin
  Result := False;
  ASequence.Kind := askNone;
  ASequence.FinalChar := #0;
  ASequence.PrivateMarker := #0;
  ASequence.Intermediates := '';
  SetLength(ASequence.Params, 0);
  ASequence.StringCommand := #0;
  ASequence.StringData := '';

  if AChar in [#24, #26] then begin Reset; Exit end;
  if (AChar = #27) and not (FState in [apsGround, apsString, apsStringEscape]) then
  begin
    FState := apsEscape;
    ResetSequenceState;
    Exit;
  end;

  case FState of
    apsGround:
      if AChar = #27 then FState := apsEscape;
    apsEscape:
      if AChar = '[' then
      begin
        FState := apsCSI;
        FParamText := '';
        FPrivateMarker := #0;
        FIntermediates := '';
      end
      else if AChar in [']', 'P', '_', '^', 'X'] then
      begin
        FStringCommand := AChar;
        FStringData := '';
        FState := apsString;
      end
      else if (Ord(AChar) >= $30) and (Ord(AChar) <= $7E) then
      begin
        ASequence.Kind := askEscape;
        ASequence.FinalChar := AChar;
        ASequence.Intermediates := FIntermediates;
        Result := True;
        Reset;
      end
      else if Ord(AChar) in [$20..$2F] then
        FIntermediates := FIntermediates + AChar
      else if not (Ord(AChar) in [$00..$1F]) then
        Reset;
    apsCSI:
      begin
        if (FParamText = '') and (FPrivateMarker = #0) and
           (AChar in ['<', '=', '>', '?']) then FPrivateMarker := AChar
        else if AChar in ['0'..'9', ';', ':'] then FParamText := FParamText + AChar
        else if Ord(AChar) in [$20..$2F] then FIntermediates := FIntermediates + AChar
        else if Ord(AChar) in [$40..$7E] then
        begin
          ASequence.Kind := askCSI;
          ASequence.FinalChar := AChar;
          ASequence.PrivateMarker := FPrivateMarker;
          ASequence.Intermediates := FIntermediates;
          ParseParams(ASequence.Params);
          Result := True;
          Reset;
        end
        else if not (Ord(AChar) in [$00..$1F]) then Reset;
      end;
    apsString:
      begin
        if (FStringCommand = ']') and (AChar = #7) then
          Result := FinishString(ASequence)
        else if AChar = #27 then
          FState := apsStringEscape
        else
          AppendStringByte(AChar);
      end;
    apsStringEscape:
      begin
        if AChar = '\' then
          Result := FinishString(ASequence)
        else
        begin
          AppendStringByte(#27);
          if AChar = #27 then FState := apsStringEscape
          else begin AppendStringByte(AChar); FState := apsString end;
        end;
      end;
  end;
end;

end.
