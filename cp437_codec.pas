unit cp437_codec;

{$mode objfpc}{$H+}

interface

function CP437DecodeByte(AByte: Byte): UTF8String;
function CP437DecodeString(const AString: RawByteString): UTF8String;

implementation

const
  CP437High: array[$80..$FF] of Word = (
    $00C7, $00FC, $00E9, $00E2, $00E4, $00E0, $00E5, $00E7,
    $00EA, $00EB, $00E8, $00EF, $00EE, $00EC, $00C4, $00C5,
    $00C9, $00E6, $00C6, $00F4, $00F6, $00F2, $00FB, $00F9,
    $00FF, $00D6, $00DC, $00A2, $00A3, $00A5, $20A7, $0192,
    $00E1, $00ED, $00F3, $00FA, $00F1, $00D1, $00AA, $00BA,
    $00BF, $2310, $00AC, $00BD, $00BC, $00A1, $00AB, $00BB,
    $2591, $2592, $2593, $2502, $2524, $2561, $2562, $2556,
    $2555, $2563, $2551, $2557, $255D, $255C, $255B, $2510,
    $2514, $2534, $252C, $251C, $2500, $253C, $255E, $255F,
    $255A, $2554, $2569, $2566, $2560, $2550, $256C, $2567,
    $2568, $2564, $2565, $2559, $2558, $2552, $2553, $256B,
    $256A, $2518, $250C, $2588, $2584, $258C, $2590, $2580,
    $03B1, $00DF, $0393, $03C0, $03A3, $03C3, $00B5, $03C4,
    $03A6, $0398, $03A9, $03B4, $221E, $03C6, $03B5, $2229,
    $2261, $00B1, $2265, $2264, $2320, $2321, $00F7, $2248,
    $00B0, $2219, $00B7, $221A, $207F, $00B2, $25A0, $00A0
  );

function CodePointToUTF8(ACodePoint: Cardinal): UTF8String;
begin
  Result := '';
  if ACodePoint <= $7F then
  begin
    SetLength(Result, 1);
    Result[1] := AnsiChar(ACodePoint);
  end
  else if ACodePoint <= $7FF then
  begin
    SetLength(Result, 2);
    Result[1] := AnsiChar($C0 or (ACodePoint shr 6));
    Result[2] := AnsiChar($80 or (ACodePoint and $3F));
  end
  else
  begin
    SetLength(Result, 3);
    Result[1] := AnsiChar($E0 or (ACodePoint shr 12));
    Result[2] := AnsiChar($80 or ((ACodePoint shr 6) and $3F));
    Result[3] := AnsiChar($80 or (ACodePoint and $3F));
  end;
end;

function CP437DecodeByte(AByte: Byte): UTF8String;
begin
  if AByte < $7F then
    Result := CodePointToUTF8(AByte)
  else if AByte = $7F then
    Result := CodePointToUTF8($2302)
  else
    Result := CodePointToUTF8(CP437High[AByte]);
end;

function CP437DecodeString(const AString: RawByteString): UTF8String;
var
  I: Integer;
begin
  Result := '';
  for I := 1 to Length(AString) do
    Result := Result + CP437DecodeByte(Byte(AString[I]));
end;

end.
