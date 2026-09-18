unit ansi_input;

{$mode objfpc}{$H+}

interface

type
  TAnsiKey = (akUp, akDown, akLeft, akRight, akHome, akEnd,
    akInsert, akDelete, akPageUp, akPageDown, akF1, akF2, akF3, akF4,
    akF5, akF6, akF7, akF8, akF9, akF10, akF11, akF12, akEnter,
    akBackspace, akTab, akEscape);
  TAnsiKeyModifier = (akmShift, akmAlt, akmCtrl);
  TAnsiKeyModifiers = set of TAnsiKeyModifier;

  TAnsiInputEncoder = class
  private
    FApplicationCursorKeys: Boolean;
    FApplicationKeypad: Boolean;
    FBackspaceSendsDEL: Boolean;
    function ModifiedCSI(const ABase: string; AModifiers: TAnsiKeyModifiers): RawByteString;
  public
    function EncodeKey(AKey: TAnsiKey; AModifiers: TAnsiKeyModifiers = []): RawByteString;
    property ApplicationCursorKeys: Boolean read FApplicationCursorKeys write FApplicationCursorKeys;
    property ApplicationKeypad: Boolean read FApplicationKeypad write FApplicationKeypad;
    property BackspaceSendsDEL: Boolean read FBackspaceSendsDEL write FBackspaceSendsDEL;
  end;

implementation

uses SysUtils;

function ModifierValue(AModifiers: TAnsiKeyModifiers): Integer;
begin
  Result := 1;
  if akmShift in AModifiers then Inc(Result, 1);
  if akmAlt in AModifiers then Inc(Result, 2);
  if akmCtrl in AModifiers then Inc(Result, 4);
end;

function TAnsiInputEncoder.ModifiedCSI(const ABase: string;
  AModifiers: TAnsiKeyModifiers): RawByteString;
var M: Integer;
begin
  M := ModifierValue(AModifiers);
  if M = 1 then Exit(#27 + '[' + ABase);
  Result := #27 + '[' + Copy(ABase, 1, Length(ABase) - 1) + ';' +
    IntToStr(M) + ABase[Length(ABase)];
end;

function TAnsiInputEncoder.EncodeKey(AKey: TAnsiKey;
  AModifiers: TAnsiKeyModifiers): RawByteString;
const FKeys: array[akF1..akF12] of Integer = (11, 12, 13, 14, 15, 17, 18, 19, 20, 21, 23, 24);
var N: Integer; Prefix: Char;
begin
  case AKey of
    akUp, akDown, akLeft, akRight:
      begin
        if FApplicationCursorKeys and (AModifiers = []) then Prefix := 'O' else Prefix := '[';
        case AKey of
          akUp: Result := #27 + Prefix + 'A'; akDown: Result := #27 + Prefix + 'B';
          akRight: Result := #27 + Prefix + 'C'; else Result := #27 + Prefix + 'D';
        end;
      end;
    akHome: Result := ModifiedCSI('H', AModifiers);
    akEnd: Result := ModifiedCSI('F', AModifiers);
    akInsert: Result := ModifiedCSI('2~', AModifiers);
    akDelete: Result := ModifiedCSI('3~', AModifiers);
    akPageUp: Result := ModifiedCSI('5~', AModifiers);
    akPageDown: Result := ModifiedCSI('6~', AModifiers);
    akF1..akF12:
      begin N := FKeys[AKey]; Result := ModifiedCSI(IntToStr(N) + '~', AModifiers) end;
    akEnter: Result := #13;
    akBackspace: if FBackspaceSendsDEL then Result := #127 else Result := #8;
    akTab: Result := #9;
    akEscape: Result := #27;
  end;
  if (akmAlt in AModifiers) and not (AKey in [akUp, akDown, akLeft, akRight,
    akHome, akEnd, akInsert, akDelete, akPageUp, akPageDown, akF1..akF12]) then
    Result := #27 + Result;
end;

end.
