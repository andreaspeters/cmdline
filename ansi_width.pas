unit ansi_width;

{$mode objfpc}{$H+}

interface

function AnsiCodePointWidth(ACodePoint: Cardinal): Integer;
function AnsiUTF8Width(const AGlyph: UTF8String): Integer;

implementation

function AnsiCodePointWidth(ACodePoint: Cardinal): Integer;
begin
  if (ACodePoint = 0) or ((ACodePoint >= $0300) and (ACodePoint <= $036F)) or
     ((ACodePoint >= $200B) and (ACodePoint <= $200F)) or
     ((ACodePoint >= $FE00) and (ACodePoint <= $FE0F)) then Exit(0);
  if ((ACodePoint >= $1100) and (ACodePoint <= $115F)) or
     ((ACodePoint >= $2329) and (ACodePoint <= $232A)) or
     ((ACodePoint >= $2E80) and (ACodePoint <= $A4CF)) or
     ((ACodePoint >= $AC00) and (ACodePoint <= $D7A3)) or
     ((ACodePoint >= $F900) and (ACodePoint <= $FAFF)) or
     ((ACodePoint >= $FE10) and (ACodePoint <= $FE19)) or
     ((ACodePoint >= $FF01) and (ACodePoint <= $FF60)) or
     ((ACodePoint >= $1F300) and (ACodePoint <= $1FAFF)) then Exit(2);
  Result := 1;
end;

function AnsiUTF8Width(const AGlyph: UTF8String): Integer;
var I, L: Integer; B: Byte; CP: Cardinal;
begin
  Result := 0; I := 1;
  while I <= Length(AGlyph) do
  begin
    B := Byte(AGlyph[I]);
    if B < $80 then begin CP := B; L := 1 end
    else if (B and $E0) = $C0 then begin CP := B and $1F; L := 2 end
    else if (B and $F0) = $E0 then begin CP := B and $0F; L := 3 end
    else begin CP := B and $07; L := 4 end;
    while (L > 1) and (I + L - 1 <= Length(AGlyph)) do begin CP := (CP shl 6) or (Byte(AGlyph[I + L - 1]) and $3F); Dec(L) end;
    Result := Result + AnsiCodePointWidth(CP);
    I := I + Length(AGlyph);
  end;
end;

end.
