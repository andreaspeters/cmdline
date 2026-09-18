unit ansi_telnet;

{$mode objfpc}{$H+}

interface

uses Classes, SysUtils, Sockets, BaseUnix;

type
  TTelnetDataEvent = procedure(const AData: RawByteString) of object;

  TAnsiTelnetClient = class
  private
    FSocket: LongInt;
    FOnData: TTelnetDataEvent;
    function Negotiate(const AData: RawByteString): RawByteString;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Connect(const AHost: string; APort: Word);
    procedure Disconnect;
    function Connected: Boolean;
    procedure Send(const AData: RawByteString);
    function ReceiveOnce: RawByteString;
    property OnData: TTelnetDataEvent read FOnData write FOnData;
  end;

implementation

const
  IAC: Char = #255; WILL: Byte = 251; WONT: Byte = 252;
  DO_: Byte = 253; DONT: Byte = 254;

constructor TAnsiTelnetClient.Create;
begin
  inherited Create;
  FSocket := -1;
end;

destructor TAnsiTelnetClient.Destroy;
begin
  Disconnect;
  inherited Destroy;
end;

function TAnsiTelnetClient.Connected: Boolean;
begin
  Result := FSocket >= 0;
end;

procedure TAnsiTelnetClient.Connect(const AHost: string; APort: Word);
var Addr: TInetSockAddr;
    HostAddr: TInAddr;
begin
  Disconnect;
  HostAddr := StrToHostAddr(AHost);
  if HostAddr.s_addr = 0 then
    raise Exception.CreateFmt('Cannot resolve telnet host: %s', [AHost]);
  FSocket := fpSocket(AF_INET, SOCK_STREAM, 0);
  if FSocket < 0 then raise Exception.Create('Cannot create telnet socket');
  FillChar(Addr, SizeOf(Addr), 0);
  Addr.sin_family := AF_INET;
  Addr.sin_port := htons(APort);
  Addr.sin_addr := HostAddr;
  if fpConnect(FSocket, @Addr, SizeOf(Addr)) <> 0 then
  begin
    Disconnect;
    raise Exception.CreateFmt('Cannot connect telnet host: %s:%d', [AHost, APort]);
  end;
end;

procedure TAnsiTelnetClient.Disconnect;
begin
  if FSocket >= 0 then begin fpShutdown(FSocket, 2); fpClose(FSocket); FSocket := -1 end;
end;

function TAnsiTelnetClient.Negotiate(const AData: RawByteString): RawByteString;
var I: Integer; Cmd, Opt: Byte;
begin
  Result := ''; I := 1;
  while I <= Length(AData) do
  begin
    if Byte(AData[I]) <> 255 then begin Result := Result + AData[I]; Inc(I); Continue end;
    if I + 1 > Length(AData) then Break;
    Cmd := Byte(AData[I + 1]);
    if Cmd = 255 then begin Result := Result + IAC; Inc(I, 2); Continue end;
    if I + 2 > Length(AData) then Break;
    Opt := Byte(AData[I + 2]);
    if Cmd = WILL then Send(IAC + Char(DONT) + Char(Opt))
    else if Cmd = DO_ then Send(IAC + Char(WONT) + Char(Opt));
    Inc(I, 3);
  end;
end;

procedure TAnsiTelnetClient.Send(const AData: RawByteString);
begin
  if not Connected then raise Exception.Create('Telnet client is not connected');
  if Length(AData) > 0 then fpSend(FSocket, @AData[1], Length(AData), 0);
end;

function TAnsiTelnetClient.ReceiveOnce: RawByteString;
var Buffer: array[0..8191] of Byte; N: LongInt;
begin
  Result := '';
  if not Connected then Exit;
  N := fpRecv(FSocket, @Buffer[0], SizeOf(Buffer), 0);
  if N <= 0 then begin if N = 0 then Disconnect; Exit end;
  SetLength(Result, N);
  Move(Buffer[0], Result[1], N);
  Result := Negotiate(Result);
  if (Result <> '') and Assigned(FOnData) then FOnData(Result);
end;

end.
