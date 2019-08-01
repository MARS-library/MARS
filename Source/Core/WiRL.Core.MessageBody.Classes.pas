{******************************************************************************}
{                                                                              }
{       WiRL: RESTful Library for Delphi                                       }
{                                                                              }
{       Copyright (c) 2015-2019 WiRL Team                                      }
{                                                                              }
{       https://github.com/delphi-blocks/WiRL                                  }
{                                                                              }
{******************************************************************************}
unit WiRL.Core.MessageBody.Classes;

interface

uses
  System.Classes, System.SysUtils, System.Rtti,

  WiRL.Core.Declarations,
  WiRL.Core.Classes,
  WiRL.http.Request,
  WiRL.http.Response,
  WiRL.Core.Attributes,
  WiRL.Core.Application,
  WiRL.http.Accept.MediaType,
  WiRL.Core.MessageBodyWriter,
  WiRL.Core.MessageBodyReader;

type
  TMessageBodyWriter = class(TInterfacedObject, IMessageBodyWriter)
  protected
    [Context] WiRLApplication: TWiRLApplication;
  public
    procedure WriteTo(const AValue: TValue; const AAttributes: TAttributeArray;
      AMediaType: TMediaType; AResponse: TWiRLResponse); virtual; abstract;
  end;

  TMessageBodyReader = class(TInterfacedObject, IMessageBodyReader)
  protected
    [Context] WiRLApplication: TWiRLApplication;
  public
    function ReadFrom(AParam: TRttiParameter; AMediaType: TMediaType;
      ARequest: TWiRLRequest): TValue; virtual; abstract;
  end;

  TMessageBodyProvider = class(TInterfacedObject, IMessageBodyReader, IMessageBodyWriter)
  protected
    [Context] WiRLApplication: TWiRLApplication;
  public
    function ReadFrom(AParam: TRttiParameter; AMediaType: TMediaType;
      ARequest: TWiRLRequest): TValue; virtual; abstract;

    procedure WriteTo(const AValue: TValue; const AAttributes: TAttributeArray;
      AMediaType: TMediaType; AResponse: TWiRLResponse); virtual; abstract;
  end;

implementation

end.
