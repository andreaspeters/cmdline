unit ansi_parser;

{$mode objfpc}{$H+}

interface

type
  TAnsiParserState = (apsGround, apsEscape, apsCSI);
  TAnsiSequenceKind = (askNone, askEscape, askCSI);
  TAnsiParams = array of Integer;

  TAnsiSequence = record
    Kind: TAnsiSequenceKind;
    FinalChar: Char;
    PrivateMarker: Char;
    Intermediates: string;
    Params: TAnsiParams;
  end;

  TAnsiParser = class
  private
    FState: TAnsiParserState;
    FParamText: string;
    FPrivateMarker: Char;
    FIntermediates: string;
    procedure ParseParams(out AParams: TAnsiParams);
  public
    constructor Create;
    procedure Reset;
    function Feed(AChar: Char; out ASequence: TAnsiSequence): Boolean;
    property State: TAnsiParserState read FState;
  end;

implementation

uses SysUtils;

constructor TAnsiParser.Create;
begin
  inherited Create;
  Reset;
end;

procedure TAnsiParser.Reset;
begin
  FState := apsGround;
  FParamText := '';
  FPrivateMarker := #0;
  FIntermediates := '';
end;

procedure TAnsiParser.ParseParams(out AParams: TAnsiParams);
var
  I, StartPos, Count: Integer;
  Part: string;
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
      if Part = '' then
        AParams[Count] := -1
      else
        AParams[Count] := StrToIntDef(Part, -1);
      Inc(Count);
      StartPos := I + 1;
    end;
end;

function TAnsiParser.Feed(AChar: Char; out ASequence: TAnsiSequence): Boolean;
begin
  Result := False;
  ASequence.Kind := askNone;
  ASequence.FinalChar := #0;
  ASequence.PrivateMarker := #0;
  ASequence.Intermediates := '';
  SetLength(ASequence.Params, 0);

  { CAN/SUB cancel an in-progress sequence. A new ESC restarts it. }
  if AChar in [#24, #26] then
  begin
    Reset;
    Exit;
  end;
  if (AChar = #27) and (FState <> apsGround) then
  begin
    FState := apsEscape;
    FParamText := '';
    FPrivateMarker := #0;
    FIntermediates := '';
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
      else if (Ord(AChar) >= $30) and (Ord(AChar) <= $7E) then
      begin
        ASequence.Kind := askEscape;
        ASequence.FinalChar := AChar;
        Result := True;
        Reset;
      end
      else if not (Ord(AChar) in [$20..$2F]) then
        Reset;
    apsCSI:
      begin
        if (FParamText = '') and (FPrivateMarker = #0) and
           (AChar in ['<', '=', '>', '?']) then
          FPrivateMarker := AChar
        else if (AChar in ['0'..'9', ';', ':']) then
          FParamText := FParamText + AChar
        else if Ord(AChar) in [$20..$2F] then
          FIntermediates := FIntermediates + AChar
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
        else if not (Ord(AChar) in [$00..$1F]) then
          Reset;
      end;
  end;
end;

end.
