unit ansi_tabs;

{$mode objfpc}{$H+}

interface

type
  TAnsiTabStops = class
  private
    FColumns: Integer;
    FStops: array of Boolean;
    function Clamp(AColumn: Integer): Integer;
  public
    constructor Create(AColumns: Integer);
    procedure Reset;
    procedure SetStop(AColumn: Integer);
    procedure ClearStop(AColumn: Integer);
    procedure ClearAll;
    function NextStop(AColumn: Integer): Integer;
    function PreviousStop(AColumn: Integer): Integer;
  end;

implementation

constructor TAnsiTabStops.Create(AColumns: Integer);
begin
  inherited Create;
  FColumns := AColumns;
  if FColumns < 1 then FColumns := 1;
  SetLength(FStops, FColumns);
  Reset;
end;

function TAnsiTabStops.Clamp(AColumn: Integer): Integer;
begin
  Result := AColumn;
  if Result < 0 then Result := 0;
  if Result >= FColumns then Result := FColumns - 1;
end;

procedure TAnsiTabStops.Reset;
var I: Integer;
begin
  for I := 0 to FColumns - 1 do FStops[I] := (I mod 8) = 0;
end;

procedure TAnsiTabStops.SetStop(AColumn: Integer);
begin FStops[Clamp(AColumn)] := True end;

procedure TAnsiTabStops.ClearStop(AColumn: Integer);
begin FStops[Clamp(AColumn)] := False end;

procedure TAnsiTabStops.ClearAll;
var I: Integer;
begin for I := 0 to FColumns - 1 do FStops[I] := False end;

function TAnsiTabStops.NextStop(AColumn: Integer): Integer;
var I: Integer;
begin
  Result := FColumns - 1;
  for I := Clamp(AColumn) + 1 to FColumns - 1 do
    if FStops[I] then Exit(I);
end;

function TAnsiTabStops.PreviousStop(AColumn: Integer): Integer;
var I: Integer;
begin
  Result := 0;
  for I := Clamp(AColumn) - 1 downto 0 do
    if FStops[I] then Exit(I);
end;

end.
