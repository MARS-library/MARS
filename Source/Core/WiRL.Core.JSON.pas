{******************************************************************************}
{                                                                              }
{       WiRL: RESTful Library for Delphi                                       }
{                                                                              }
{       Copyright (c) 2015-2019 WiRL Team                                      }
{                                                                              }
{       https://github.com/delphi-blocks/WiRL                                  }
{                                                                              }
{******************************************************************************}
unit WiRL.Core.JSON;

interface

uses
  System.JSON, System.SysUtils, System.Generics.Collections;

type
  TJSONAncestor = System.JSON.TJSONAncestor;
  TJSONPair     = System.JSON.TJSONPair;
  TJSONValue    = System.JSON.TJSONValue;
  TJSONTrue     = System.JSON.TJSONTrue;
  TJSONFalse    = System.JSON.TJSONFalse;
  TJSONString   = System.JSON.TJSONString;
  TJSONNumber   = System.JSON.TJSONNumber;
  TJSONObject   = System.JSON.TJSONObject;
  TJSONNull     = System.JSON.TJSONNull;
  TJSONArray    = System.JSON.TJSONArray;

  TJSONHelper = class
  public
    class function PrettyPrint(AJSONValue: TJSONValue): string; static;

    class function ToJSON(AJSONValue: TJSONValue): string; static;
    class function StringArrayToJsonArray(const values: TArray<string>): string; static;
    class procedure JSONCopyFrom(ASource, ADestination: TJSONObject); static;

    class function BooleanToTJSON(AValue: Boolean): TJSONValue;
    class function DateToJSON(ADate: TDateTime; AInputIsUTC: Boolean = True): string; static;
    class function JSONToDate(const ADate: string; AReturnUTC: Boolean = True): TDateTime; static;
  end;

implementation

uses
  System.DateUtils,
  System.Variants,
  WiRL.Core.Utils;

{ TJSONHelper }

class function TJSONHelper.BooleanToTJSON(AValue: Boolean): TJSONValue;
begin
  if AValue then
    Result := TJSONTrue.Create
  else
    Result := TJSONFalse.Create;
end;

class function TJSONHelper.DateToJSON(ADate: TDateTime; AInputIsUTC: Boolean = True): string;
begin
  Result := '';
  if ADate <> 0 then
    Result := DateToISO8601(ADate, AInputIsUTC);
end;

class function TJSONHelper.JSONToDate(const ADate: string; AReturnUTC: Boolean = True): TDateTime;
begin
  Result := 0.0;
  if ADate<>'' then
    Result := ISO8601ToDate(ADate, AReturnUTC);
end;

class function TJSONHelper.ToJSON(AJSONValue: TJSONValue): string;
var
  LBytes: TBytes;
begin
  SetLength(LBytes, AJSONValue.ToString.Length * 6);
  SetLength(LBytes, AJSONValue.ToBytes(LBytes, 0));
  Result := TEncoding.Default.GetString(LBytes);
end;

class function TJSONHelper.StringArrayToJsonArray(const values: TArray<string>): string;
var
  LArray: TJSONArray;
  LIndex: Integer;
begin
  LArray := TJSONArray.Create;
  try
    for LIndex := 0 to High(values) do
      LArray.Add(values[LIndex]);
    Result := ToJSON(LArray);
  finally
    LArray.Free;
  end;
end;

class procedure TJSONHelper.JSONCopyFrom(ASource, ADestination: TJSONObject);
var
  LPair: TJSONPair;
begin
  for LPair in ASource do
    ADestination.AddPair(TJSONPair(LPair.Clone));
end;

class function TJSONHelper.PrettyPrint(AJSONValue: TJSONValue): string;
var
  LJSONString: string;
  LChar: Char;
  LOffset: Integer;

  function Spaces(AOffset: Integer): string;
  begin
    Result := StringOfChar(#32, AOffset * 2);
  end;

begin
  Result := '';
  LOffset := 0;
  LJSONString := AJSONValue.ToString;
  for LChar in LJSONString do
  begin
    if LChar = '{' then
    begin
      Inc(LOffset);
      Result := Result + LChar;
      Result := Result + sLineBreak;
      Result := Result + Spaces(LOffset);
    end
    else if LChar = '}' then
    begin
      Dec(LOffset);
      Result := Result + sLineBreak;
      Result := Result + Spaces(LOffset);
      Result := Result + LChar;
    end
    else if LChar = ',' then
    begin
      Result := Result + LChar;
      Result := Result + sLineBreak;
      Result := Result + Spaces(LOffset);
    end
    else if LChar = '[' then
    begin
      Inc(LOffset);
      Result := Result + LChar;
      Result := Result + sLineBreak;
      Result := Result + Spaces(LOffset);
    end
    else if LChar = ']' then
    begin
      Dec(LOffset);
      Result := Result + sLineBreak;
      Result := Result + Spaces(LOffset);
      Result := Result + LChar;
    end
    else
      Result := Result + LChar;
  end;
end;

end.
