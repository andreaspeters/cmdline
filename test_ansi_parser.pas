program test_ansi_parser;

{$mode objfpc}{$H+}

uses SysUtils, ansi_parser;

procedure Fail(const Msg: string);
begin
  WriteLn(StdErr, 'FAIL: ', Msg);
  Halt(1);
end;

procedure Check(Condition: Boolean; const Msg: string);
begin
  if not Condition then Fail(Msg);
end;

procedure CheckEq(Expected, Actual: Integer; const Msg: string);
begin
  if Expected <> Actual then
    Fail(Format('%s (expected %d, got %d)', [Msg, Expected, Actual]));
end;

procedure TestStreamingAndParams;
var P: TAnsiParser; S: TAnsiSequence; Ready: Boolean;
begin
  P := TAnsiParser.Create;
  try
    Ready := P.Feed(#27, S); Check(not Ready, 'ESC must be incomplete');
    Ready := P.Feed('[', S); Check(not Ready, 'CSI introducer must be incomplete');
    P.Feed('3', S); P.Feed('1', S); P.Feed(';', S); P.Feed('4', S);
    Ready := P.Feed('m', S);
    Check(Ready, 'split SGR must complete');
    Check(S.Kind = askCSI, 'event kind must be CSI');
    Check(S.FinalChar = 'm', 'SGR final');
    CheckEq(2, Length(S.Params), 'SGR param count');
    CheckEq(31, S.Params[0], 'first SGR param');
    CheckEq(4, S.Params[1], 'second SGR param');
  finally P.Free end;
end;

procedure TestEmptyAndPrivateParams;
var P: TAnsiParser; S: TAnsiSequence;
begin
  P := TAnsiParser.Create;
  try
    P.Feed(#27,S); P.Feed('[',S); Check(P.Feed('m',S), 'empty SGR completes');
    CheckEq(0, Length(S.Params), 'ESC[m has implicit params');
    P.Feed(#27,S); P.Feed('[',S); P.Feed('?',S); P.Feed('2',S); P.Feed('5',S);
    Check(P.Feed('l',S), 'private mode completes');
    Check(S.PrivateMarker = '?', 'private marker retained');
    CheckEq(25, S.Params[0], 'private mode param');
    P.Feed(#27,S); P.Feed('[',S); P.Feed(';',S); Check(P.Feed('H',S), 'empty CUP completes');
    CheckEq(2, Length(S.Params), 'two empty CUP params');
    CheckEq(-1, S.Params[0], 'empty first param');
    CheckEq(-1, S.Params[1], 'empty second param');
  finally P.Free end;
end;

procedure TestFinalRangeAndRecovery;
var P: TAnsiParser; S: TAnsiSequence;
begin
  P := TAnsiParser.Create;
  try
    P.Feed(#27,S); P.Feed('[',S); P.Feed('3',S);
    Check(P.Feed('@',S), '@ is a valid CSI final');
    Check(S.FinalChar='@', 'ICH final retained');
    P.Feed(#27,S); P.Feed('[',S); P.Feed(#24,S);
    Check(P.State=apsGround, 'CAN cancels CSI');
    P.Feed(#27,S); P.Feed('[',S); P.Feed('9',S); P.Feed(#27,S);
    P.Feed('[',S); P.Feed('2',S);
    Check(P.Feed('J',S), 'new ESC recovers from partial CSI');
    CheckEq(2, S.Params[0], 'recovered sequence params');
  finally P.Free end;
end;

procedure TestUtf8BytesRemainGround;
var P: TAnsiParser; S: TAnsiSequence; U: UTF8String; I: Integer;
begin
  P := TAnsiParser.Create;
  try
    U := UTF8String('ä');
    for I := 1 to Length(U) do
    begin
      Check(not P.Feed(U[I],S), 'ordinary UTF-8 byte is not ANSI');
      Check(P.State=apsGround, 'UTF-8 byte leaves parser grounded');
    end;
  finally P.Free end;
end;

begin
  TestStreamingAndParams;
  TestEmptyAndPrivateParams;
  TestFinalRangeAndRecovery;
  TestUtf8BytesRemainGround;
  WriteLn('PASS: ANSI parser tests');
end.
