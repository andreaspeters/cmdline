unit ansi_mouse;

{$mode objfpc}{$H+}

interface

type
  TAnsiMouseTrackingMode = (amtNone, amtX10, amtNormal,
    amtButtonEvent, amtAnyEvent);
  TAnsiMouseEventKind = (amePress, ameRelease, ameMotion,
    ameWheelUp, ameWheelDown, ameFocusIn, ameFocusOut);

  { Pure xterm mouse protocol state and encoder. Coordinates and button numbers
    are terminal coordinates/codes: X/Y are 1-based; buttons are 0..2, or 3
    for motion without a pressed button. }
  TAnsiMouseEncoder = class
  private
    FTrackingMode: TAnsiMouseTrackingMode;
    FSGREncoding: Boolean;
    FUTF8Encoding: Boolean;
    FURXVTEEncoding: Boolean;
    FFocusEvents: Boolean;
    FAlternateScroll: Boolean;
  public
    constructor Create;
    procedure Reset;
    procedure SetPrivateMode(AMode: Integer; AEnabled: Boolean);
    function Encode(AKind: TAnsiMouseEventKind; AButton, AX, AY,
      AModifiers: Integer): string;
    property TrackingMode: TAnsiMouseTrackingMode read FTrackingMode;
    property SGREncoding: Boolean read FSGREncoding;
    property UTF8Encoding: Boolean read FUTF8Encoding;
    property URXVTEncoding: Boolean read FURXVTEEncoding;
    property FocusEvents: Boolean read FFocusEvents;
    property AlternateScroll: Boolean read FAlternateScroll;
  end;

implementation

uses SysUtils;

function UTF8MouseValue(AValue: Integer): string;
begin
  if AValue < 128 then Exit(Chr(AValue));
  if AValue < 2048 then
    Exit(Chr($C0 or (AValue shr 6)) + Chr($80 or (AValue and $3F)));
  Result := Chr($E0 or (AValue shr 12)) + Chr($80 or ((AValue shr 6) and $3F)) +
    Chr($80 or (AValue and $3F));
end;

constructor TAnsiMouseEncoder.Create;
begin
  inherited Create;
  Reset;
end;

procedure TAnsiMouseEncoder.Reset;
begin
  FTrackingMode := amtNone;
  FSGREncoding := False;
  FUTF8Encoding := False;
  FURXVTEEncoding := False;
  FFocusEvents := False;
  FAlternateScroll := False;
end;

procedure TAnsiMouseEncoder.SetPrivateMode(AMode: Integer; AEnabled: Boolean);
var
  NewMode: TAnsiMouseTrackingMode;
begin
  if AMode = 1006 then
  begin
    FSGREncoding := AEnabled;
    Exit;
  end;
  if AMode = 1005 then begin FUTF8Encoding := AEnabled; Exit end;
  if AMode = 1015 then begin FURXVTEEncoding := AEnabled; Exit end;
  if AMode = 1004 then begin FFocusEvents := AEnabled; Exit end;
  if AMode = 1007 then begin FAlternateScroll := AEnabled; Exit end;

  case AMode of
    9: NewMode := amtX10;
    1000: NewMode := amtNormal;
    1002: NewMode := amtButtonEvent;
    1003: NewMode := amtAnyEvent;
    else Exit;
  end;

  if AEnabled then
    FTrackingMode := NewMode
  else if FTrackingMode = NewMode then
    FTrackingMode := amtNone;
end;

function TAnsiMouseEncoder.Encode(AKind: TAnsiMouseEventKind;
  AButton, AX, AY, AModifiers: Integer): string;
var
  Code: Integer;
  FinalChar: Char;
begin
  Result := '';

  if AKind in [ameFocusIn, ameFocusOut] then
  begin
    if not FFocusEvents then Exit;
    if AKind = ameFocusIn then Result := #27 + '[I' else Result := #27 + '[O';
    Exit;
  end;

  case FTrackingMode of
    amtNone: Exit;
    amtX10:
      if AKind <> amePress then Exit;
    amtNormal:
      if not (AKind in [amePress, ameRelease, ameWheelUp, ameWheelDown]) then
        Exit;
    amtButtonEvent:
      begin
        if AKind = ameMotion then
        begin
          if not (AButton in [0..2]) then Exit;
        end
        else if not (AKind in [amePress, ameRelease, ameWheelUp,
          ameWheelDown]) then
          Exit;
      end;
    amtAnyEvent: ;
  end;

  if AX < 1 then AX := 1;
  if AY < 1 then AY := 1;
  AModifiers := AModifiers and (4 or 8 or 16);
  FinalChar := 'M';

  case AKind of
    amePress:
      begin
        if not (AButton in [0..2]) then Exit;
        Code := AButton;
      end;
    ameRelease:
      begin
        if not (AButton in [0..2]) then Exit;
        if FSGREncoding then
        begin
          Code := AButton;
          FinalChar := 'm';
        end
        else
          Code := 3;
      end;
    ameMotion:
      begin
        if not (AButton in [0..3]) then Exit;
        Code := AButton + 32;
      end;
    ameWheelUp: Code := 64;
    ameWheelDown: Code := 65;
  end;
  Inc(Code, AModifiers);

  if FSGREncoding then
    Result := #27 + '[<' + IntToStr(Code) + ';' + IntToStr(AX) + ';' +
      IntToStr(AY) + FinalChar
  else if FURXVTEEncoding then
    Result := #27 + '[M' + IntToStr(Code) + ';' + IntToStr(AX) + ';' +
      IntToStr(AY) + 'M'
  else
  begin
    if FUTF8Encoding then
      Result := #27 + '[M' + UTF8MouseValue(Code + 32) + UTF8MouseValue(AX + 32) +
        UTF8MouseValue(AY + 32)
    else
    begin
      { The original X10 encoding has one byte per coordinate. }
      if (AX > 223) or (AY > 223) then Exit;
      Result := #27 + '[M' + Chr(Code + 32) + Chr(AX + 32) + Chr(AY + 32);
    end;
  end;
end;

end.
