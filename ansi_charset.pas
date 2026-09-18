unit ansi_charset;

{$mode objfpc}{$H+}

interface

type
  TAnsiIntegerArray = array of Integer;

function DecodeDECSpecialGraphics(AChar: Char): UTF8String;
function DecodeG0OrASCII(AChar: Char; ASpecialGraphics: Boolean): UTF8String;
function ParseColonParameters(const AText: string): TAnsiIntegerArray;

implementation

uses SysUtils;
function DecodeDECSpecialGraphics(AChar: Char): UTF8String;
begin
  case AChar of
    '`': Result := '◆'; 'a': Result := '▒'; 'f': Result := '°';
    'g': Result := '±'; 'j': Result := '┘'; 'k': Result := '┐';
    'l': Result := '┌'; 'm': Result := '└'; 'n': Result := '┼';
    'q': Result := '─'; 't': Result := '├'; 'u': Result := '┤';
    'v': Result := '┴'; 'w': Result := '┬'; 'x': Result := '│';
    'y': Result := '≤'; 'z': Result := '≥'; '{': Result := 'π';
    '|': Result := '≠'; '}': Result := '£'; '~': Result := '·';
    else Result := AChar;
  end;
end;

function DecodeG0OrASCII(AChar: Char; ASpecialGraphics: Boolean): UTF8String;
begin
  if ASpecialGraphics then Result := DecodeDECSpecialGraphics(AChar)
  else Result := AChar;
end;

function ParseColonParameters(const AText: string): TAnsiIntegerArray;
var I, Start, Count: Integer;
begin
  Result := nil;
  Count := 1;
  for I := 1 to Length(AText) do if AText[I] = ':' then Inc(Count);
  SetLength(Result, Count);
  Start := 1; Count := 0;
  for I := 1 to Length(AText) + 1 do
    if (I > Length(AText)) or (AText[I] = ':') then
    begin
      Result[Count] := StrToIntDef(Copy(AText, Start, I - Start), -1);
      Inc(Count); Start := I + 1;
    end;
end;

end.
