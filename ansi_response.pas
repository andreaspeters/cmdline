unit ansi_response;

{$mode objfpc}{$H+}

interface

type
  TAnsiResponseEvent = procedure(const AResponse: RawByteString) of object;

  TAnsiResponseEncoder = class
  private
    FOnResponse: TAnsiResponseEvent;
    procedure Emit(const AResponse: RawByteString);
  public
    constructor Create(AOnResponse: TAnsiResponseEvent);
    procedure DeviceStatus;
    procedure CursorPosition(ARow, AColumn: Integer);
    procedure DeviceAttributes;
    property OnResponse: TAnsiResponseEvent read FOnResponse write FOnResponse;
  end;

implementation

uses SysUtils;

constructor TAnsiResponseEncoder.Create(AOnResponse: TAnsiResponseEvent);
begin
  inherited Create;
  FOnResponse := AOnResponse;
end;

procedure TAnsiResponseEncoder.Emit(const AResponse: RawByteString);
begin
  if Assigned(FOnResponse) then FOnResponse(AResponse);
end;

procedure TAnsiResponseEncoder.DeviceStatus;
begin
  Emit(#27 + '[0n');
end;

procedure TAnsiResponseEncoder.CursorPosition(ARow, AColumn: Integer);
begin
  if ARow < 1 then ARow := 1;
  if AColumn < 1 then AColumn := 1;
  Emit(#27 + '[' + IntToStr(ARow) + ';' + IntToStr(AColumn) + 'R');
end;

procedure TAnsiResponseEncoder.DeviceAttributes;
begin
  Emit(#27 + '[?62;1;2;6;9c');
end;

end.
