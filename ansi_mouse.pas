unit ansi_mouse;

{$mode objfpc}{$H+}

interface

type
  TAnsiMouseTrackingMode = (amtNone, amtX10, amtNormal,
    amtButtonEvent, amtAnyEvent);
  TAnsiMouseEventKind = (amePress, ameRelease, ameMotion,
    ameWheelUp, ameWheelDown);

  { Pure xterm mouse protocol state and encoder. Coordinates and button numbers
    are terminal coordinates/codes: X/Y are 1-based; buttons are 0..2, or 3
    for motion without a pressed button. }
  TAnsiMouseEncoder = class
  private
    FTrackingMode: TAnsiMouseTrackingMode;
    FSGREncoding: Boolean;
  public
    constructor Create;
    procedure Reset;
    procedure SetPrivateMode(AMode: Integer; AEnabled: Boolean);
    function Encode(AKind: TAnsiMouseEventKind; AButton, AX, AY,
      AModifiers: Integer): string;
    property TrackingMode: TAnsiMouseTrackingMode read FTrackingMode;
    property SGREncoding: Boolean read FSGREncoding;
  end;

implementation

uses SysUtils;

constructor TAnsiMouseEncoder.Create;
begin
  inherited Create;
  Reset;
end;

procedure TAnsiMouseEncoder.Reset;
begin
  FTrackingMode := amtNone;
  FSGREncoding := False;
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
  else
  begin
    { The original X10 encoding has one byte per coordinate. }
    if (AX > 223) or (AY > 223) then Exit;
    Result := #27 + '[M' + Chr(Code + 32) + Chr(AX + 32) + Chr(AY + 32);
  end;
end;

end.
