program test_ansi_bbs_mode;

{$mode objfpc}{$H+}
{$codepage utf8}

uses
  Interfaces, Forms, SysUtils, Classes, Graphics, ucmdbox;

const
  OutputFile = '/tmp/cmdbox-cp437-test-output.txt';

procedure Fail(const Msg: string);
begin
  WriteLn(StdErr, 'FAIL: ', Msg);
  Halt(1);
end;

procedure Check(Condition: Boolean; const Msg: string);
begin
  if not Condition then Fail(Msg);
end;

function ReadRawFile(const AFileName: string): RawByteString;
var
  Stream: TFileStream;
begin
  Result := '';
  Stream := TFileStream.Create(AFileName, fmOpenRead or fmShareDenyNone);
  try
    SetLength(Result, Stream.Size);
    if Stream.Size > 0 then Stream.ReadBuffer(Result[1], Stream.Size);
  finally
    Stream.Free;
  end;
end;

procedure TestBBSDefaultsAndStreamDecode;
var
  Host: TForm;
  Box: TCmdBox;
  Input: TMemoryStream;
  Raw, Saved: RawByteString;
begin
  Host := TForm.Create(nil);
  try
    Box := TCmdBox.Create(Host);
    Box.Parent := Host;
    Host.HandleNeeded;
    Check(Box.AnsiTextEncoding = ateUTF8,
      'UTF-8 remains the backwards-compatible default');
    Box.ApplyAnsiBBSDefaults;
    Check(Box.EscapeCodeType = esctAnsi, 'BBS defaults enable ANSI parsing');
    Check(Box.AnsiTextEncoding = ateCP437, 'BBS defaults enable CP437');
    Check(Box.TerminalColumns = 80, 'BBS defaults use 80 columns');
    Check(Box.WrapMode = wwmChar, 'BBS defaults use character wrapping');
    Check(Box.BackGroundColor = clBlack, 'BBS defaults use a black background');
    Check(Box.Font.Pitch = fpFixed, 'BBS font has fixed pitch');
    Check(Box.Font.Quality = fqNonAntialiased, 'BBS font is rendered crisply');
    Check(Box.Font.Name <> '', 'BBS font selection returns a font name');

    Raw := AnsiChar($DA) + AnsiChar($C4) + AnsiChar($BF) +
      AnsiChar($DB);
    Input := TMemoryStream.Create;
    try
      Input.WriteBuffer(Raw[1], Length(Raw));
      Input.Position := 0;
      Box.WriteStream(Input);
    finally
      Input.Free;
    end;

    Box.SaveToFile(OutputFile);
    Saved := ReadRawFile(OutputFile);
    Check(Pos(UTF8String('┌─┐█'), Saved) = 1,
      'WriteStream decodes raw CP437 box drawing bytes');
  finally
    Host.Free;
    DeleteFile(OutputFile);
  end;
end;

procedure TestExplicitUTF8Mode;
var
  Host: TForm;
  Box: TCmdBox;
  Saved: RawByteString;
begin
  Host := TForm.Create(nil);
  try
    Box := TCmdBox.Create(Host);
    Box.Parent := Host;
    Host.HandleNeeded;
    Box.EscapeCodeType := esctAnsi;
    Box.AnsiTextEncoding := ateUTF8;
    Box.Write(UTF8String('┌─┐'));
    Box.SaveToFile(OutputFile);
    Saved := ReadRawFile(OutputFile);
    Check(Pos(UTF8String('┌─┐'), Saved) = 1,
      'explicit UTF-8 terminal output stays intact');
  finally
    Host.Free;
    DeleteFile(OutputFile);
  end;
end;

begin
  try
    Application.Initialize;
    TestBBSDefaultsAndStreamDecode;
    TestExplicitUTF8Mode;
    WriteLn('PASS: ANSI BBS mode integration tests');
  except
    on E: Exception do Fail(E.ClassName + ': ' + E.Message);
  end;
end.
