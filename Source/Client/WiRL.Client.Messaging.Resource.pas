{******************************************************************************}
{                                                                              }
{       WiRL: RESTful Library for Delphi                                       }
{                                                                              }
{       Copyright (c) 2015-2019 WiRL Team                                      }
{                                                                              }
{       https://github.com/delphi-blocks/WiRL                                  }
{                                                                              }
{******************************************************************************}
unit WiRL.Client.Messaging.Resource;

{$I WiRL.inc}

interface

uses
  System.SysUtils, System.Classes,
  WiRL.Core.JSON,

{$IFDEF HAS_SYSTEM_THREADING}
  System.Threading,
{$ENDIF}

  WiRL.Client.Resource.JSON,
  WiRL.Client.SubResource.JSON;

type
  TWiRLMessageEvent = procedure (Sender: TObject; AMessage: TJSONObject) of object;

  TWiRLClientMessagingResource = class(TWiRLClientResourceJSON)
  private
{$IFDEF HAS_SYSTEM_THREADING}
    FWorkerTask: ITask;
{$ENDIF}
    FListenSubRes: TWiRLClientSubResourceJSON;
    FMyQueueSubRes: TWiRLClientSubResourceJSON;
    FPollingInterval: Integer;
    FActive: Boolean;
    FOnMessage: TWiRLMessageEvent;
    FSynchronizeEvents: Boolean;
    procedure SetPollingInterval(const Value: Integer);
    procedure SetActive(const Value: Boolean);
  protected
    procedure HandleMessage(AMessage: TJSONObject);
    procedure StartPolling;
    procedure StopPolling;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    property Active: Boolean read FActive write SetActive;
    property PollingInterval: Integer read FPollingInterval write SetPollingInterval;
    property SynchronizeEvents: Boolean read FSynchronizeEvents write FSynchronizeEvents;
    property OnMessage: TWiRLMessageEvent read FOnMessage write FOnMessage;
  end;

implementation

{ TWiRLClientMessagingResource }

constructor TWiRLClientMessagingResource.Create(AOwner: TComponent);
begin
  inherited;
  FListenSubRes := TWiRLClientSubResourceJSON.Create(nil);
  FListenSubRes.ParentResource := Self;
  FListenSubRes.Resource := 'listen';

  FMyQueueSubRes := TWiRLClientSubResourceJSON.Create(nil);
  FMyQueueSubRes.ParentResource := Self;
  FMyQueueSubRes.Resource := 'myqueue';

  FPollingInterval := 500;
  FActive := False;
end;

destructor TWiRLClientMessagingResource.Destroy;
begin
  StopPolling;
  FListenSubRes.Free;
  FMyQueueSubRes.Free;
  inherited;
end;

procedure TWiRLClientMessagingResource.HandleMessage(AMessage: TJSONObject);
begin
  if Assigned(FOnMessage) then
  begin
    if SynchronizeEvents then
      TThread.Queue(nil,
        procedure
        begin
          FOnMessage(Self, AMessage);
        end
      )
    else
      FOnMessage(Self, AMessage);
  end;
end;

procedure TWiRLClientMessagingResource.SetActive(const Value: Boolean);
begin
  if FActive <> Value then
  begin
    FActive := Value;
    if FActive then
      StartPolling
    else
      StopPolling;
  end;
end;

procedure TWiRLClientMessagingResource.SetPollingInterval(const Value: Integer);
begin
  if FPollingInterval <> Value then
  begin
    FPollingInterval := Value;
    if Active then
    begin
      StopPolling;
      StartPolling;
    end;
  end;
end;

procedure TWiRLClientMessagingResource.StartPolling;
begin
  if not ([csLoading, csReading] * ComponentState = []) then
    Exit;

{$IFDEF HAS_SYSTEM_THREADING}
  FWorkerTask := TTask.Create(
    procedure
    var
      LArray: TJSONArray;
      LElement: TJSONValue;
      LMessage: TJSONObject;
      LResponse: TJSONObject;
    begin
      FListenSubRes.GET;

      while TTask.CurrentTask.Status = TTaskStatus.Running do
      begin
        try
          FMyQueueSubRes.GET;

          LResponse := FMyQueueSubRes.Response as TJSONObject;
          LArray := LResponse.Get('Messages').JsonValue as TJSONArray;
          for LElement in LArray do
          begin
            LMessage := (LElement as TJSONObject);
            HandleMessage(LMessage);
          end;
        except on E: Exception do
          // handle errors? ignore errors?
        end;

        Sleep(FPollingInterval);
      end; // while
    end // task
  ).Start;
{$ENDIF}
end;

procedure TWiRLClientMessagingResource.StopPolling;
begin
{$IFDEF HAS_SYSTEM_THREADING}
  if Assigned(FWorkerTask) and (FWorkerTask.Status < TTaskStatus.Completed) then
    FWorkerTask.Cancel;
{$ENDIF}
end;

end.
