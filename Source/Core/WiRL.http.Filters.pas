{******************************************************************************}
{                                                                              }
{       WiRL: RESTful Library for Delphi                                       }
{                                                                              }
{       Copyright (c) 2015-2019 WiRL Team                                      }
{                                                                              }
{       https://github.com/delphi-blocks/WiRL                                  }
{                                                                              }
{******************************************************************************}
unit WiRL.http.Filters;

interface

uses
  System.SysUtils, System.Generics.Collections, System.Generics.Defaults,
  System.Classes, System.Rtti,

  WiRL.Core.Singleton,
  WiRL.Core.Exceptions,
  WiRL.Core.Attributes,
  WiRL.Core.Context,
  WiRL.http.Request,
  WiRL.http.Response,
  WiRL.Core.Resource,
  WiRL.Rtti.Utils;

type
  TWiRLContainerRequestContext = class(TObject)
  private
    FRequest: TWiRLRequest;
    FResponse: TWiRLResponse;
    FAborted: Boolean;
    FContext: TWiRLContext;
    FResource: TWiRLResource;
    function GetResource: TWiRLResource;
  public
    property Context: TWiRLContext read FContext;
    property Request: TWiRLRequest read FRequest;
    property Response: TWiRLResponse read FResponse;
    property Resource: TWiRLResource read GetResource;
    property Aborted: Boolean read FAborted;
    procedure Abort;
    constructor Create(AContext: TWiRLContext; AResource: TWiRLResource = nil);
  end;

  TWiRLContainerResponseContext = class(TObject)
  private
    FRequest: TWiRLRequest;
    FResponse: TWiRLResponse;
    FContext: TWiRLContext;
    FResource: TWiRLResource;
    function GetResource: TWiRLResource;
  public
    property Context: TWiRLContext read FContext;
    property Request: TWiRLRequest read FRequest;
    property Response: TWiRLResponse read FResponse;
    property Resource: TWiRLResource read GetResource;
    constructor Create(AContext: TWiRLContext; AResource: TWiRLResource = nil);
  end;

  IWiRLContainerRequestFilter = interface
  ['{58406938-14A1-438F-946A-F0723920B511}']
    procedure Filter(ARequestContext: TWiRLContainerRequestContext);
  end;

  IWiRLContainerResponseFilter = interface
  ['{F952495E-00DB-44C6-ACED-33F1F2F25527}']
    procedure Filter(AResponseContext: TWiRLContainerResponseContext);
  end;

  // the lower the number the higher the priority
  // By default, when the @Priority annotation is absent
  // on a component the USER priority value is used
  TWiRLPriorities = class(TObject)
  public
    const AUTHENTICATION = 1000;
    const AUTHORIZATION = 2000;
    const HEADER_DECORATOR = 3000;
    const ENTITY_CODER = 4000;
    const USER = 5000;
  end;

  TWiRLFilterConstructorInfo = class
  private
    FConstructorFunc: TFunc<TObject>;
    FFilterQualifiedClassName: string;
    FTypeTClass: TClass;
    FPriority: Integer;
    FAttribute: TCustomAttribute;
  public
    constructor Create(AClass: TClass; const AConstructorFunc: TFunc<TObject>; APriority: Integer); overload;
    constructor Create(const AFilterQualifiedClassName: string); overload;

    function GetRequestFilter: IWiRLContainerRequestFilter;
    function GetResponseFilter: IWiRLContainerResponseFilter;
    property Attribute: TCustomAttribute read FAttribute;
    property TypeTClass: TClass read FTypeTClass;
    property Priority: Integer read FPriority;
    property ConstructorFunc: TFunc<TObject> read FConstructorFunc write FConstructorFunc;
    property FilterQualifiedClassName: string read FFilterQualifiedClassName;
    function Clone: TWiRLFilterConstructorInfo;
  end;

  TWiRLFilterRegistry = class(TObjectList<TWiRLFilterConstructorInfo>)
  private
    type
      TWiRLFilterRegistrySingleton = TWiRLSingleton<TWiRLFilterRegistry>;
    var
      FRttiContext: TRttiContext;
      // True if the list has been sorted since the first item was added
      FSorted: Boolean;
    function GetPriority(FilterClass: TClass) :Integer;
  protected
    class function GetInstance: TWiRLFilterRegistry; static; inline;
  public
    constructor Create; virtual;

    procedure Sort;
    function AddFilterName(const AFilterName: string): TWiRLFilterConstructorInfo;

    function FilterByClassName(const AClassName: string; out AConstructorInfo: TWiRLFilterConstructorInfo) :Boolean;
    function RegisterFilter<T: class>: TWiRLFilterConstructorInfo; overload;
    function RegisterFilter<T: class>(const AConstructorFunc: TFunc<TObject>): TWiRLFilterConstructorInfo; overload;

    function ApplyPreMatchingRequestFilters(AContext: TWiRLContext): Boolean;
    procedure ApplyPreMatchingResponseFilters(AContext: TWiRLContext);

    procedure FetchRequestFilter(const PreMatching: Boolean; ARequestProc: TProc<TWiRLFilterConstructorInfo>);
    procedure FetchResponseFilter(const PreMatching: Boolean; AResponseProc: TProc<TWiRLFilterConstructorInfo>);

    class property Instance: TWiRLFilterRegistry read GetInstance;
  end;


implementation

{ TWiRLConstructorInfo }

function TWiRLFilterConstructorInfo.Clone: TWiRLFilterConstructorInfo;
begin
  Result := TWiRLFilterConstructorInfo.Create(FTypeTClass, FConstructorFunc, FPriority);
end;

constructor TWiRLFilterConstructorInfo.Create(AClass: TClass;
  const AConstructorFunc: TFunc<TObject>; APriority: Integer);
var
  LFilterType: TRttiType;
begin
  inherited Create;

  FConstructorFunc := AConstructorFunc;
  FTypeTClass := AClass;
  FFilterQualifiedClassName := AClass.QualifiedClassName;
  FPriority := APriority;

  LFilterType := TRttiHelper.Context.GetType(FTypeTClass);

  TRttiHelper.ForEachAttribute<NameBindingAttribute>(LFilterType,
    procedure (AFilterAttrib: NameBindingAttribute)
    begin
      FAttribute := AFilterAttrib;
    end
  );

  if not Assigned(FAttribute) then
    TRttiHelper.ForEachAttribute<TCustomAttribute>(LFilterType,
      procedure (AFilterAttrib: TCustomAttribute)
      begin
        if TRttiHelper.HasAttribute<NameBindingAttribute>(
          TRttiHelper.Context.GetType(AFilterAttrib.ClassType)) then
          FAttribute := AFilterAttrib;
      end
    );

  // Default constructor function
  if not Assigned(FConstructorFunc) then
    FConstructorFunc :=
      function: TObject
      var
        LContext: TRttiContext;
        LType: TRttiType;
        LValue: TValue;
      begin
        LType := LContext.GetType(FTypeTClass);
        LValue := LType.GetMethod('Create').Invoke(LType.AsInstance.MetaclassType, []);
        Result := LValue.AsObject;
      end
    ;
end;

constructor TWiRLFilterConstructorInfo.Create(
  const AFilterQualifiedClassName: string);
begin
  inherited Create;
  FFilterQualifiedClassName := AFilterQualifiedClassName;
end;

function TWiRLFilterConstructorInfo.GetRequestFilter: IWiRLContainerRequestFilter;
var
  LTempObj: TObject;
begin
  LTempObj := Self.ConstructorFunc();

  // The check doesn't have any sense but I must use SUPPORT and I hate using it without a check
  if not Supports(LTempObj, IWiRLContainerRequestFilter, Result) then
    raise EWiRLNotImplementedException.Create(
      Format('[%s] does not implement requested interface [IWiRLContainerRequestFilter]', [TypeTClass.ClassName]),
      Self.ClassName,
      'GetRequestFilter'
    );

end;

function TWiRLFilterConstructorInfo.GetResponseFilter: IWiRLContainerResponseFilter;
var
  LTempObj: TObject;
begin
  LTempObj := Self.ConstructorFunc();
  // The check doesn't have any sense but I must use SUPPORT and I hate using it without a check
  if not Supports(LTempObj, IWiRLContainerResponseFilter, Result) then
    raise EWiRLNotImplementedException.Create(
      Format('[%s] does not implement requested interface [IWiRLContainerResponseFilter]', [TypeTClass.ClassName]),
      Self.ClassName,
      'GetResponseFilter'
    );
end;

{ TWiRLFilterRegistry }

function TWiRLFilterRegistry.AddFilterName(
  const AFilterName: string): TWiRLFilterConstructorInfo;
begin
  Result := TWiRLFilterConstructorInfo.Create(AFilterName);
  Add(Result);
  FSorted := False;
end;

constructor TWiRLFilterRegistry.Create;
var
  LComparer: IComparer<TWiRLFilterConstructorInfo>;
begin
  LComparer := TDelegatedComparer<TWiRLFilterConstructorInfo>.Create(
    function(const Left, Right: TWiRLFilterConstructorInfo): Integer
    begin
      Result := Left.Priority - Right.Priority;
    end
  );

  //TWiRLFilterRegistrySingleton.CheckInstance(Self);
  FRttiContext := TRttiContext.Create;

  inherited Create(LComparer, True);
end;

procedure TWiRLFilterRegistry.FetchRequestFilter(const PreMatching: Boolean;
  ARequestProc: TProc<TWiRLFilterConstructorInfo>);
var
  LConstructorInfo: TWiRLFilterConstructorInfo;
  LFilterType: TRttiType;
  LIsPreMatching: Boolean;
begin
  Sort;
  for LConstructorInfo in Self do
  begin
    if Supports(LConstructorInfo.TypeTClass, IWiRLContainerRequestFilter) then
    begin
      LFilterType := FRttiContext.GetType(LConstructorInfo.TypeTClass);
      LIsPreMatching := TRttiHelper.HasAttribute<PreMatchingAttribute>(LFilterType);

      if PreMatching and LIsPreMatching then
        ARequestProc(LConstructorInfo)
      else if not PreMatching and not LIsPreMatching then
        ARequestProc(LConstructorInfo);
    end;
  end;
end;

procedure TWiRLFilterRegistry.FetchResponseFilter(const PreMatching: Boolean; AResponseProc: TProc<TWiRLFilterConstructorInfo>);
var
  LConstructorInfo: TWiRLFilterConstructorInfo;
  LFilterType: TRttiType;
  LIsPreMatching: Boolean;
begin
  Sort;
  for LConstructorInfo in Self do
  begin
    if Supports(LConstructorInfo.TypeTClass, IWiRLContainerResponseFilter) then
    begin
      LFilterType := FRttiContext.GetType(LConstructorInfo.TypeTClass);
      LIsPreMatching := TRttiHelper.HasAttribute<PreMatchingAttribute>(LFilterType);

      if PreMatching and LIsPreMatching then
        AResponseProc(LConstructorInfo)
      else if not PreMatching and not LIsPreMatching then
        AResponseProc(LConstructorInfo);
    end;
  end;
end;

function TWiRLFilterRegistry.ApplyPreMatchingRequestFilters(AContext: TWiRLContext): Boolean;
var
  LRequestFilter: IWiRLContainerRequestFilter;
  LRequestContext: TWiRLContainerRequestContext;
  LAborted: Boolean;
begin
  LAborted := False;
  TWiRLFilterRegistry.Instance.FetchRequestFilter(True,
    procedure (ConstructorInfo: TWiRLFilterConstructorInfo)
    begin
      // The check doesn't have any sense but I must use SUPPORT and I hate using it without a check
      if not Supports(ConstructorInfo.ConstructorFunc(), IWiRLContainerRequestFilter, LRequestFilter) then
        raise EWiRLNotImplementedException.Create(
          Format('Request Filter [%s] does not implement requested interface [IWiRLContainerRequestFilter]', [ConstructorInfo.TypeTClass.ClassName]),
          Self.ClassName, 'ApplyPreMatchingRequestFilters'
        );
      LRequestContext := TWiRLContainerRequestContext.Create(AContext);
      try
        LRequestFilter.Filter(LRequestContext);
        LAborted := LAborted or LRequestContext.Aborted;
      finally
        LRequestContext.Free;
      end;
    end
  );
  Result := LAborted;
end;

procedure TWiRLFilterRegistry.ApplyPreMatchingResponseFilters(AContext: TWiRLContext);
var
  LResponseFilter: IWiRLContainerResponseFilter;
  LResponseContext: TWiRLContainerResponseContext;
begin
  TWiRLFilterRegistry.Instance.FetchResponseFilter(True,
    procedure (ConstructorInfo: TWiRLFilterConstructorInfo)
    begin
      // The check doesn't have any sense but I must use SUPPORT and I hate using it without a check
      if not Supports(ConstructorInfo.ConstructorFunc(), IWiRLContainerResponseFilter, LResponseFilter) then
        raise EWiRLNotImplementedException.Create(
          Format('Response Filter [%s] does not implement requested interface [IWiRLContainerResponseFilter]', [ConstructorInfo.TypeTClass.ClassName]),
          Self.ClassName, 'ApplyPreMatchingResponseFilters'
        );
      LResponseContext := TWiRLContainerResponseContext.Create(AContext);
      try
        LResponseFilter.Filter(LResponseContext);
      finally
        LResponseContext.Free;
      end;
    end
  );
end;

function TWiRLFilterRegistry.FilterByClassName(const AClassName: string;
  out AConstructorInfo: TWiRLFilterConstructorInfo): Boolean;
var
  LItem: TWiRLFilterConstructorInfo;
begin
  Result := False;
  for LItem in Self do
  begin
    if CompareText(LItem.TypeTClass.QualifiedClassName, AClassName) = 0 then
    begin
      AConstructorInfo := LItem;
      Exit(True);
    end;
  end;
end;

class function TWiRLFilterRegistry.GetInstance: TWiRLFilterRegistry;
begin
  Result := TWiRLFilterRegistrySingleton.Instance;
end;

function TWiRLFilterRegistry.GetPriority(FilterClass: TClass): Integer;
var
  LPriority: Integer;
begin
  LPriority := TWiRLPriorities.USER;
  TRttiHelper.HasAttribute<PriorityAttribute>(FRttiContext.GetType(FilterClass),
    procedure (Attrib: PriorityAttribute)
    begin
      LPriority := Attrib.Value;
    end
  );
  Result := LPriority;
end;

function TWiRLFilterRegistry.RegisterFilter<T>(
  const AConstructorFunc: TFunc<TObject>): TWiRLFilterConstructorInfo;
begin
  if not Supports(TClass(T), IWiRLContainerRequestFilter) and not Supports(TClass(T), IWiRLContainerResponseFilter) then
    raise EWiRLServerException.Create(
      Format('Filter registration error: [%s] should be a valid filter', [TClass(T).QualifiedClassName]),
      Self.ClassName,
      'RegisterFilter'
    );

  Result := TWiRLFilterConstructorInfo.Create(TClass(T), AConstructorFunc, GetPriority(TClass(T)));
  Add(Result);
  FSorted := False;
end;

procedure TWiRLFilterRegistry.Sort;
begin
  if not FSorted then
  begin
    inherited Sort;
    FSorted := True;
  end;
end;

function TWiRLFilterRegistry.RegisterFilter<T>: TWiRLFilterConstructorInfo;
begin
  Result := RegisterFilter<T>(nil);
end;

{ TWiRLContainerRequestContext }

procedure TWiRLContainerRequestContext.Abort;
begin
  FAborted := True;
end;

constructor TWiRLContainerRequestContext.Create(AContext: TWiRLContext; AResource: TWiRLResource);
begin
  inherited Create;
  FContext := AContext;
  FRequest := AContext.Request;
  FResponse := AContext.Response;
  FResource := AResource;
end;

function TWiRLContainerRequestContext.GetResource: TWiRLResource;
begin
  if not Assigned(FResource) then
    raise EWiRLException.Create('Resource info not available');
  Result := FResource;
end;

{ TWiRLContainerResponseContext }

constructor TWiRLContainerResponseContext.Create(AContext: TWiRLContext; AResource: TWiRLResource);
begin
  inherited Create;
  FContext := AContext;
  FRequest := AContext.Request;
  FResponse := AContext.Response;
  FResource := AResource;
end;

function TWiRLContainerResponseContext.GetResource: TWiRLResource;
begin
  if not Assigned(FResource) then
    raise EWiRLException.Create('Resource info not available');
  Result := FResource;
end;

end.

