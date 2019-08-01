{******************************************************************************}
{                                                                              }
{       WiRL: RESTful Library for Delphi                                       }
{                                                                              }
{       Copyright (c) 2015-2019 WiRL Team                                      }
{                                                                              }
{       https://github.com/delphi-blocks/WiRL                                  }
{                                                                              }
{******************************************************************************}
unit WiRL.Client.SubResource.JSON;

{$I ..\Core\WiRL.inc}

interface

uses
  System.SysUtils, System.Classes, 
  WiRL.Core.JSON, 
  WiRL.Client.SubResource, 
  WiRL.http.Client;

type
  {$IFDEF HAS_NEW_PIDS}
  [ComponentPlatformsAttribute(pidWin32 or pidWin64 or pidOSX32 or pidiOSSimulator32 or pidiOSDevice32 or pidAndroid32Arm)]
  {$ELSE}
  [ComponentPlatformsAttribute(pidWin32 or pidWin64 or pidOSX32 or pidiOSSimulator or pidiOSDevice or pidAndroid)]
  {$ENDIF}
  TWiRLClientSubResourceJSON = class(TWiRLClientSubResource)
  private
    FResponse: TJSONValue;
  protected
    procedure AfterGET(); override;
    procedure AfterPOST(); override;
    function GetResponseAsString: string; virtual;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

  published
    property Response: TJSONValue read FResponse write FResponse;
    property ResponseAsString: string read GetResponseAsString;
  end;

implementation

uses
  WiRL.Core.Utils;

{ TWiRLClientResourceJSON }

procedure TWiRLClientSubResourceJSON.AfterGET();
begin
  inherited;
  if Assigned(FResponse) then
    FResponse.Free;
  FResponse := StreamToJSONValue(Client.Response.ContentStream);
end;

procedure TWiRLClientSubResourceJSON.AfterPOST;
begin
  inherited;
  if Assigned(FResponse) then
    FResponse.Free;
  FResponse := StreamToJSONValue(Client.Response.ContentStream);
end;

constructor TWiRLClientSubResourceJSON.Create(AOwner: TComponent);
begin
  inherited;
  FResponse := TJSONObject.Create;
end;

destructor TWiRLClientSubResourceJSON.Destroy;
begin
  FResponse.Free;
  inherited;
end;

function TWiRLClientSubResourceJSON.GetResponseAsString: string;
begin
  Result := '';
  if Assigned(FResponse) then
    Result := TJSONHelper.ToJSON(FResponse);
end;

end.
