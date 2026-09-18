unit ansi_screen;

{$mode objfpc}{$H+}

interface

type
  TAnsiAttribute = (aaBold, aaDim, aaItalic, aaUnderline, aaBlink,
    aaInverse, aaConceal, aaStrike);
  TAnsiAttributes = set of TAnsiAttribute;

  TAnsiCell = record
    Glyph: UTF8String;
    Foreground: Cardinal;
    Background: Cardinal;
    Attributes: TAnsiAttributes;
  end;

  TAnsiScreenBuffer = class
  private
    FWidth: Integer;
    FHeight: Integer;
    FCells: array of TAnsiCell;
    FCursorX: Integer;
    FCursorY: Integer;
    FTopMargin, FBottomMargin: Integer;
    FLeftMargin, FRightMargin: Integer;
    FOriginMode: Boolean;
    FDefaultCell: TAnsiCell;
    function CellIndex(AX, AY: Integer): Integer;
    procedure CheckDimensions(AWidth, AHeight: Integer);
    procedure SetCursorX(AValue: Integer);
    procedure SetCursorY(AValue: Integer);
    procedure FillRow(AY: Integer);
  public
    constructor Create(AWidth, AHeight: Integer);
    procedure Resize(AWidth, AHeight: Integer);
    procedure Clear;
    procedure SetCell(AX, AY: Integer; const ACell: TAnsiCell);
    function GetCell(AX, AY: Integer): TAnsiCell;
    procedure WriteGlyph(const AGlyph: UTF8String);
    procedure WriteStyledGlyph(const AGlyph: UTF8String; AForeground,
      ABackground: Cardinal; AAttributes: TAnsiAttributes);
    procedure WriteText(const AText: UTF8String);
    procedure SetScrollRegion(ATop, ABottom: Integer);
    procedure SetOriginMode(AEnabled: Boolean);
    procedure LineFeed;
    procedure ReverseIndex;
    procedure ScrollUp(AAmount: Integer = 1);
    procedure ScrollDown(AAmount: Integer = 1);
    property Width: Integer read FWidth;
    property Height: Integer read FHeight;
    property CursorX: Integer read FCursorX write SetCursorX;
    property CursorY: Integer read FCursorY write SetCursorY;
    property TopMargin: Integer read FTopMargin;
    property BottomMargin: Integer read FBottomMargin;
    property LeftMargin: Integer read FLeftMargin;
    property RightMargin: Integer read FRightMargin;
    property OriginMode: Boolean read FOriginMode;
    property DefaultCell: TAnsiCell read FDefaultCell write FDefaultCell;
  end;

function AnsiDefaultCell: TAnsiCell;

implementation

uses SysUtils;

function NextUTF8Length(const AText: UTF8String; AIndex: Integer): Integer;
var B: Byte;
begin
  B := Byte(AText[AIndex]);
  if B < $80 then Exit(1);
  if (B and $E0) = $C0 then Exit(2);
  if (B and $F0) = $E0 then Exit(3);
  if (B and $F8) = $F0 then Exit(4);
  Result := 1;
end;

function AnsiDefaultCell: TAnsiCell;
begin
  Result.Glyph := ' ';
  Result.Foreground := $00AAAAAA;
  Result.Background := $00000000;
  Result.Attributes := [];
end;

constructor TAnsiScreenBuffer.Create(AWidth, AHeight: Integer);
begin
  inherited Create;
  FDefaultCell := AnsiDefaultCell;
  Resize(AWidth, AHeight);
end;

procedure TAnsiScreenBuffer.CheckDimensions(AWidth, AHeight: Integer);
begin
  if (AWidth < 1) or (AHeight < 1) then
    raise EArgumentOutOfRangeException.Create('ANSI screen dimensions must be positive');
end;

function TAnsiScreenBuffer.CellIndex(AX, AY: Integer): Integer;
begin
  if (AX < 0) or (AX >= FWidth) or (AY < 0) or (AY >= FHeight) then
    raise EArgumentOutOfRangeException.CreateFmt('ANSI cell out of range: %d,%d', [AX, AY]);
  Result := AY * FWidth + AX;
end;

procedure TAnsiScreenBuffer.Resize(AWidth, AHeight: Integer);
var
  OldCells: array of TAnsiCell;
  OldWidth, OldHeight: Integer;
  X, Y, CopyWidth, CopyHeight: Integer;
begin
  CheckDimensions(AWidth, AHeight);
  OldWidth := FWidth;
  OldHeight := FHeight;
  OldCells := FCells;
  FWidth := AWidth;
  FHeight := AHeight;
  FTopMargin := 0;
  FBottomMargin := FHeight - 1;
  FLeftMargin := 0;
  FRightMargin := FWidth - 1;
  FOriginMode := False;
  SetLength(FCells, FWidth * FHeight);
  Clear;
  CopyWidth := OldWidth;
  if CopyWidth > FWidth then CopyWidth := FWidth;
  CopyHeight := OldHeight;
  if CopyHeight > FHeight then CopyHeight := FHeight;
  for Y := 0 to CopyHeight - 1 do
    for X := 0 to CopyWidth - 1 do
      FCells[Y * FWidth + X] := OldCells[Y * OldWidth + X];
  if FCursorX >= FWidth then FCursorX := FWidth - 1;
  if FCursorY >= FHeight then FCursorY := FHeight - 1;
end;

procedure TAnsiScreenBuffer.Clear;
var I: Integer;
begin
  for I := 0 to Length(FCells) - 1 do
    FCells[I] := FDefaultCell;
  FCursorX := 0;
  FCursorY := 0;
end;

procedure TAnsiScreenBuffer.FillRow(AY: Integer);
var X: Integer;
begin
  for X := FLeftMargin to FRightMargin do
    FCells[AY * FWidth + X] := FDefaultCell;
end;

procedure TAnsiScreenBuffer.SetScrollRegion(ATop, ABottom: Integer);
begin
  if ATop < 0 then ATop := 0;
  if ABottom >= FHeight then ABottom := FHeight - 1;
  if ATop >= ABottom then Exit;
  FTopMargin := ATop;
  FBottomMargin := ABottom;
  FCursorX := FLeftMargin;
  FCursorY := FTopMargin;
end;

procedure TAnsiScreenBuffer.SetOriginMode(AEnabled: Boolean);
begin
  FOriginMode := AEnabled;
  FCursorX := FLeftMargin;
  if AEnabled then FCursorY := FTopMargin else FCursorY := 0;
end;

procedure TAnsiScreenBuffer.ScrollUp(AAmount: Integer);
var I, X, Y: Integer;
begin
  if AAmount < 1 then Exit;
  if AAmount > FBottomMargin - FTopMargin + 1 then
    AAmount := FBottomMargin - FTopMargin + 1;
  for I := 1 to AAmount do
  begin
    for Y := FTopMargin to FBottomMargin - 1 do
      for X := FLeftMargin to FRightMargin do
        FCells[Y * FWidth + X] := FCells[(Y + 1) * FWidth + X];
    FillRow(FBottomMargin);
  end;
end;

procedure TAnsiScreenBuffer.ScrollDown(AAmount: Integer);
var I, X, Y: Integer;
begin
  if AAmount < 1 then Exit;
  if AAmount > FBottomMargin - FTopMargin + 1 then
    AAmount := FBottomMargin - FTopMargin + 1;
  for I := 1 to AAmount do
  begin
    for Y := FBottomMargin downto FTopMargin + 1 do
      for X := FLeftMargin to FRightMargin do
        FCells[Y * FWidth + X] := FCells[(Y - 1) * FWidth + X];
    FillRow(FTopMargin);
  end;
end;

procedure TAnsiScreenBuffer.LineFeed;
begin
  if FCursorY = FBottomMargin then ScrollUp
  else if FCursorY < FHeight - 1 then Inc(FCursorY);
end;

procedure TAnsiScreenBuffer.ReverseIndex;
begin
  if FCursorY = FTopMargin then ScrollDown
  else if FCursorY > 0 then Dec(FCursorY);
end;

procedure TAnsiScreenBuffer.SetCell(AX, AY: Integer; const ACell: TAnsiCell);
begin
  FCells[CellIndex(AX, AY)] := ACell;
end;

function TAnsiScreenBuffer.GetCell(AX, AY: Integer): TAnsiCell;
begin
  Result := FCells[CellIndex(AX, AY)];
end;

procedure TAnsiScreenBuffer.SetCursorX(AValue: Integer);
begin
  if AValue < 0 then AValue := 0;
  if AValue >= FWidth then AValue := FWidth - 1;
  FCursorX := AValue;
end;

procedure TAnsiScreenBuffer.SetCursorY(AValue: Integer);
begin
  if AValue < 0 then AValue := 0;
  if AValue >= FHeight then AValue := FHeight - 1;
  FCursorY := AValue;
end;

procedure TAnsiScreenBuffer.WriteGlyph(const AGlyph: UTF8String);
begin
  if AGlyph = '' then Exit;
  FCells[CellIndex(FCursorX, FCursorY)].Glyph := AGlyph;
  Inc(FCursorX);
  if FCursorX >= FWidth then
  begin
    FCursorX := 0;
    if FCursorY < FHeight - 1 then Inc(FCursorY);
  end;
end;

procedure TAnsiScreenBuffer.WriteStyledGlyph(const AGlyph: UTF8String;
  AForeground, ABackground: Cardinal; AAttributes: TAnsiAttributes);
begin
  if AGlyph = '' then Exit;
  FCells[CellIndex(FCursorX, FCursorY)].Glyph := AGlyph;
  FCells[CellIndex(FCursorX, FCursorY)].Foreground := AForeground;
  FCells[CellIndex(FCursorX, FCursorY)].Background := ABackground;
  FCells[CellIndex(FCursorX, FCursorY)].Attributes := AAttributes;
  Inc(FCursorX);
  if FCursorX >= FWidth then
  begin
    FCursorX := 0;
    if FCursorY < FHeight - 1 then Inc(FCursorY);
  end;
end;

procedure TAnsiScreenBuffer.WriteText(const AText: UTF8String);
var I: Integer;
    Glyph: UTF8String;
begin
  I := 1;
  while I <= Length(AText) do
  begin
    case AText[I] of
      #10: begin FCursorX := 0; LineFeed; Inc(I); end;
      #13: begin FCursorX := 0; Inc(I); end;
      else
        Glyph := Copy(AText, I, NextUTF8Length(AText, I));
        if Glyph = '' then Glyph := AText[I];
        WriteGlyph(Glyph);
        Inc(I, Length(Glyph));
    end;
  end;
end;

end.
