program test_ansi_mouse;

{$mode objfpc}{$H+}

uses SysUtils, ansi_mouse;

procedure Fail(const Msg: string);
begin
  WriteLn(StdErr, 'FAIL: ', Msg);
  Halt(1);
end;

procedure Check(Condition: Boolean; const Msg: string);
begin
  if not Condition then Fail(Msg);
end;

procedure CheckEq(const Expected, Actual, Msg: string);
begin
  if Expected <> Actual then
    Fail(Msg + ' (expected ' + QuotedStr(Expected) + ', got ' +
      QuotedStr(Actual) + ')');
end;

function Legacy(Code, X, Y: Integer): string;
begin
  Result := #27 + '[M' + Chr(Code + 32) + Chr(X + 32) + Chr(Y + 32);
end;

procedure TestModesAndReset;
var E: TAnsiMouseEncoder;
begin
  E := TAnsiMouseEncoder.Create;
  try
    Check(E.TrackingMode = amtNone, 'tracking starts disabled');
    Check(not E.SGREncoding, 'SGR starts disabled');
    E.SetPrivateMode(1000, True);
    Check(E.TrackingMode = amtNormal, '?1000h enables normal mode');
    E.SetPrivateMode(1002, True);
    Check(E.TrackingMode = amtButtonEvent, 'new tracking mode replaces old');
    E.SetPrivateMode(1000, False);
    Check(E.TrackingMode = amtButtonEvent,
      'resetting inactive mode leaves active mode intact');
    E.SetPrivateMode(1006, True);
    Check(E.SGREncoding, '?1006h enables SGR independently');
    E.Reset;
    Check(E.TrackingMode = amtNone, 'reset disables tracking');
    Check(not E.SGREncoding, 'reset disables SGR');
  finally
    E.Free;
  end;
end;

procedure TestX10AndNormal;
var E: TAnsiMouseEncoder;
begin
  E := TAnsiMouseEncoder.Create;
  try
    CheckEq('', E.Encode(amePress, 0, 10, 5, 0),
      'disabled encoder emits nothing');
    E.SetPrivateMode(9, True);
    CheckEq(Legacy(0, 10, 5), E.Encode(amePress, 0, 10, 5, 0),
      'X10 encodes button press');
    CheckEq('', E.Encode(ameRelease, 0, 10, 5, 0),
      'X10 suppresses release');
    CheckEq('', E.Encode(ameMotion, 0, 10, 5, 0),
      'X10 suppresses motion');

    E.SetPrivateMode(1000, True);
    CheckEq(Legacy(2 + 4 + 8 + 16, 2, 3),
      E.Encode(amePress, 2, 2, 3, 4 or 8 or 16),
      'normal mode includes modifiers');
    CheckEq(Legacy(3 + 4, 2, 3), E.Encode(ameRelease, 2, 2, 3, 4),
      'legacy release uses button code 3');
    CheckEq(Legacy(64, 2, 3), E.Encode(ameWheelUp, 0, 2, 3, 0),
      'normal mode reports wheel up');
    CheckEq(Legacy(65, 2, 3), E.Encode(ameWheelDown, 0, 2, 3, 0),
      'normal mode reports wheel down');
    CheckEq('', E.Encode(ameMotion, 0, 2, 3, 0),
      'normal mode suppresses motion');
  finally
    E.Free;
  end;
end;

procedure TestMotionModes;
var E: TAnsiMouseEncoder;
begin
  E := TAnsiMouseEncoder.Create;
  try
    E.SetPrivateMode(1002, True);
    CheckEq(Legacy(32 + 1, 7, 8), E.Encode(ameMotion, 1, 7, 8, 0),
      'button-event mode reports drag');
    CheckEq('', E.Encode(ameMotion, 3, 7, 8, 0),
      'button-event mode suppresses hover');
    CheckEq(Legacy(3, 7, 8), E.Encode(ameRelease, 1, 7, 8, 0),
      'button-event mode reports release');

    E.SetPrivateMode(1003, True);
    CheckEq(Legacy(32 + 3 + 16, 7, 8),
      E.Encode(ameMotion, 3, 7, 8, 16),
      'any-event mode reports modified hover');
  finally
    E.Free;
  end;
end;

procedure TestSGRAndCoordinateBounds;
var E: TAnsiMouseEncoder;
begin
  E := TAnsiMouseEncoder.Create;
  try
    E.SetPrivateMode(1000, True);
    CheckEq(Legacy(0, 1, 1), E.Encode(amePress, 0, -5, 0, 0),
      'coordinates clamp to one');
    CheckEq('', E.Encode(amePress, 0, 224, 1, 0),
      'legacy X coordinate beyond byte range is suppressed');
    CheckEq('', E.Encode(amePress, 0, 1, 224, 0),
      'legacy Y coordinate beyond byte range is suppressed');

    E.SetPrivateMode(1006, True);
    CheckEq(#27 + '[<10;300;400M', E.Encode(amePress, 2, 300, 400, 8),
      'SGR supports large coordinates and modifiers');
    CheckEq(#27 + '[<18;300;400m', E.Encode(ameRelease, 2, 300, 400, 16),
      'SGR release keeps button code and uses lowercase m');
    CheckEq(#27 + '[<68;4;5M', E.Encode(ameWheelUp, 0, 4, 5, 4),
      'SGR wheel includes modifiers');
  finally
    E.Free;
  end;
end;

begin
  TestModesAndReset;
  TestX10AndNormal;
  TestMotionModes;
  TestSGRAndCoordinateBounds;
  WriteLn('PASS: ANSI mouse tests');
end.
