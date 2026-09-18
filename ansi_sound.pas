unit ansi_sound;

{$mode objfpc}{$H+}

interface

type
  TAnsiSoundKind = (askBell);
  TAnsiSoundEvent = procedure(AKind: TAnsiSoundKind) of object;

  TAnsiSoundDecoder = class
  private
    FOnSound: TAnsiSoundEvent;
  public
    constructor Create(AOnSound: TAnsiSoundEvent);
    procedure ProcessByte(AByte: Byte);
    procedure Bell;
    property OnSound: TAnsiSoundEvent read FOnSound write FOnSound;
  end;

implementation

constructor TAnsiSoundDecoder.Create(AOnSound: TAnsiSoundEvent);
begin
  inherited Create;
  FOnSound := AOnSound;
end;

procedure TAnsiSoundDecoder.Bell;
begin
  if Assigned(FOnSound) then FOnSound(askBell);
end;

procedure TAnsiSoundDecoder.ProcessByte(AByte: Byte);
begin
  if AByte = 7 then Bell;
end;

end.
