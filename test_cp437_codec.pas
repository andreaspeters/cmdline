program test_cp437_codec;

{$mode objfpc}{$H+}
{$codepage utf8}

uses SysUtils, cp437_codec;

procedure Fail(const Msg: string);
begin
  WriteLn(StdErr, 'FAIL: ', Msg);
  Halt(1);
end;

procedure Check(Condition: Boolean; const Msg: string);
begin
  if not Condition then Fail(Msg);
end;

procedure CheckEq(const Expected, Actual: UTF8String; const Msg: string);
begin
  if Expected <> Actual then
    Fail(Msg + ' (expected byte length ' + IntToStr(Length(Expected)) +
      ', got ' + IntToStr(Length(Actual)) + ')');
end;

procedure TestASCIIAndDOSHouse;
var
  I: Integer;
begin
  for I := $20 to $7E do
    CheckEq(UTF8String(AnsiChar(I)), CP437DecodeByte(I),
      'ASCII byte ' + IntToStr(I));
  CheckEq(UTF8String('⌂'), CP437DecodeByte($7F), 'DOS house at 7F');
end;

procedure TestAccentsAndCurrency;
begin
  CheckEq(UTF8String('Ç'), CP437DecodeByte($80), 'C cedilla');
  CheckEq(UTF8String('é'), CP437DecodeByte($82), 'e acute');
  CheckEq(UTF8String('¢'), CP437DecodeByte($9B), 'cent sign');
  CheckEq(UTF8String('£'), CP437DecodeByte($9C), 'pound sign');
  CheckEq(UTF8String('¥'), CP437DecodeByte($9D), 'yen sign');
  CheckEq(UTF8String('₧'), CP437DecodeByte($9E), 'peseta sign');
end;

procedure TestBoxDrawingAndBlocks;
begin
  CheckEq(UTF8String('░'), CP437DecodeByte($B0), 'light shade');
  CheckEq(UTF8String('▒'), CP437DecodeByte($B1), 'medium shade');
  CheckEq(UTF8String('▓'), CP437DecodeByte($B2), 'dark shade');
  CheckEq(UTF8String('│'), CP437DecodeByte($B3), 'single vertical');
  CheckEq(UTF8String('─'), CP437DecodeByte($C4), 'single horizontal');
  CheckEq(UTF8String('┌'), CP437DecodeByte($DA), 'single top left');
  CheckEq(UTF8String('┐'), CP437DecodeByte($BF), 'single top right');
  CheckEq(UTF8String('└'), CP437DecodeByte($C0), 'single bottom left');
  CheckEq(UTF8String('┘'), CP437DecodeByte($D9), 'single bottom right');
  CheckEq(UTF8String('╔'), CP437DecodeByte($C9), 'double top left');
  CheckEq(UTF8String('╗'), CP437DecodeByte($BB), 'double top right');
  CheckEq(UTF8String('╚'), CP437DecodeByte($C8), 'double bottom left');
  CheckEq(UTF8String('╝'), CP437DecodeByte($BC), 'double bottom right');
  CheckEq(UTF8String('═'), CP437DecodeByte($CD), 'double horizontal');
  CheckEq(UTF8String('║'), CP437DecodeByte($BA), 'double vertical');
  CheckEq(UTF8String('█'), CP437DecodeByte($DB), 'full block');
end;

procedure TestGreekMathAndEndOfTable;
begin
  CheckEq(UTF8String('α'), CP437DecodeByte($E0), 'alpha');
  CheckEq(UTF8String('ß'), CP437DecodeByte($E1), 'sharp s');
  CheckEq(UTF8String('Γ'), CP437DecodeByte($E2), 'Gamma');
  CheckEq(UTF8String('π'), CP437DecodeByte($E3), 'pi');
  CheckEq(UTF8String('Ω'), CP437DecodeByte($EA), 'Omega');
  CheckEq(UTF8String('∞'), CP437DecodeByte($EC), 'infinity');
  CheckEq(UTF8String('■'), CP437DecodeByte($FE), 'black square');
  CheckEq(UTF8String(#$C2#$A0), CP437DecodeByte($FF), 'no-break space');
end;

procedure TestStringAndCoverage;
var
  I: Integer;
  Raw: RawByteString;
begin
  Raw := 'A' + AnsiChar($DA) + AnsiChar($C4) + AnsiChar($BF) +
    AnsiChar($DB);
  CheckEq(UTF8String('A┌─┐█'), CP437DecodeString(Raw),
    'raw CP437 string conversion');
  for I := $20 to $FF do
    Check(CP437DecodeByte(I) <> '',
      'printable byte has mapping: ' + IntToStr(I));
end;

begin
  TestASCIIAndDOSHouse;
  TestAccentsAndCurrency;
  TestBoxDrawingAndBlocks;
  TestGreekMathAndEndOfTable;
  TestStringAndCoverage;
  WriteLn('PASS: CP437 codec tests');
end.
