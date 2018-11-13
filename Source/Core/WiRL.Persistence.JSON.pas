{******************************************************************************}
{                                                                              }
{       WiRL: RESTful Library for Delphi                                       }
{                                                                              }
{       Copyright (c) 2015-2018 WiRL Team                                      }
{                                                                              }
{       https://github.com/delphi-blocks/WiRL                                  }
{                                                                              }
{******************************************************************************}
unit WiRL.Persistence.JSON;

interface

uses
  System.SysUtils, System.Classes, System.Rtti, System.SyncObjs,
  System.TypInfo, System.Generics.Collections, System.JSON, Data.DB,

  WiRL.Core.JSON,
  WiRL.Core.Declarations,

  WiRL.Persistence.Types,
  WiRL.Persistence.Attributes,
  WiRL.Persistence.Core,
  WiRL.Persistence.DynamicTypes,
  WiRL.Persistence.Utils;

type
  TNeonSerializerJSON = class(TNeonBase)
  private
    procedure WriteMembers(AType: TRttiType; AInstance: Pointer; AResult: TJSONValue);
  private
    function WriteString(const AValue: TValue): TJSONValue;
    function WriteChar(const AValue: TValue): TJSONValue;
    function WriteEnum(const AValue: TValue): TJSONValue;
    function WriteInteger(const AValue: TValue): TJSONValue;
    function WriteFloat(const AValue: TValue): TJSONValue;
    /// <summary>
    ///   Writer for Variant types
    /// </summary>
    /// <remarks>
    ///   The variant will be written as string
    /// </remarks>
    function WriteVariant(const AValue: TValue): TJSONValue;
    /// <summary>
    ///   Writer for static and dynamic arrays
    /// </summary>
    function WriteArray(const AValue: TValue): TJSONValue;
    /// <summary>
    ///   Writer for the set type
    /// </summary>
    /// <remarks>
    ///   The output is a string with the values comma separated and enclosed by square brackets
    /// </remarks>
    /// <returns>[First,Second,Third]</returns>
    function WriteSet(const AValue: TValue): TJSONValue;
    /// <summary>
    ///   Writer for a record type
    /// </summary>
    /// <remarks>
    ///   For records the engine serialize the fields by default
    /// </remarks>
    function WriteRecord(const AValue: TValue): TJSONValue;
    /// <summary>
    ///   Writer for a standard TObject (descendants)  type (no list, stream or streamable)
    /// </summary>
    function WriteObject(const AValue: TValue): TJSONValue;
    /// <summary>
    ///   Writer for an Interface type
    /// </summary>
    /// <remarks>
    ///   The object that implements the interface is serialized
    /// </remarks>
    function WriteInterface(const AValue: TValue): TJSONValue;
    /// <summary>
    ///   Writer for TStream (descendants) objects
    /// </summary>
    function WriteStream(const AValue: TValue): TJSONValue;
    /// <summary>
    ///   Writer for TDataSet (descendants) objects
    /// </summary>
    function WriteDataSet(const AValue: TValue): TJSONValue;
    /// <summary>
    ///   Writer for "Enumerable" objects (Lists, Generic Lists, TStrings, etc...)
    /// </summary>
    /// <remarks>
    ///   Objects must have GetEnumerator, Clear, Add methods
    /// </remarks>
    function WriteEnumerable(const AValue: TValue): TJSONValue;
    /// <summary>
    ///   Writer for "Streamable" objects
    /// </summary>
    /// <remarks>
    ///   Objects must have LoadFromStream and SaveToStream methods
    /// </remarks>
    function WriteStreamable(const AValue: TValue): TJSONValue;
  private
    /// <summary>
    ///   This method chooses the right Writer based on the Kind of the AValue parameter
    /// </summary>
    function WriteDataMember(const AValue: TValue): TJSONValue;
  public
    constructor Create(const AConfig: INeonConfiguration);

    /// <summary>
    ///   Serialize any Delphi type into a JSONValue, the Delphi type must be passed as a TValue
    /// </summary>
    function ValueToJSON(const AValue: TValue): TJSONValue;
    /// <summary>
    ///   Serialize any Delphi objects into a JSONValue
    /// </summary>
    function ObjectToJSON(AObject: TObject): TJSONValue;
  end;

  TNeonDeserializerJSON = class(TNeonBase)
  private
    procedure ReadMembers(AType: TRttiType; AInstance: Pointer; AJSONObject: TJSONObject);
  private
    function ReadString(AJSONValue: TJSONValue; AType: TRttiType; AKind: TTypeKind): TValue;
    function ReadChar(AJSONValue: TJSONValue; AType: TRttiType; AKind: TTypeKind): TValue;
    function ReadEnum(AJSONValue: TJSONValue; AType: TRttiType): TValue;
    function ReadInteger(AJSONValue: TJSONValue; AType: TRttiType): TValue;
    function ReadInt64(AJSONValue: TJSONValue; AType: TRttiType): TValue;
    function ReadFloat(AJSONValue: TJSONValue; AType: TRttiType): TValue;
    function ReadSet(AJSONValue: TJSONValue; AType: TRttiType): TValue;
    function ReadVariant(AJSONValue: TJSONValue; AType: TRttiType): TValue;
  private
    function ReadArray(AJSONValue: TJSONValue; AType: TRttiType; const AData: TValue): TValue;
    function ReadDynArray(AJSONValue: TJSONValue; AType: TRttiType; const AData: TValue): TValue;
    function ReadObject(AJSONValue: TJSONValue; AType: TRttiType; const AData: TValue): TValue;
    function ReadInterface(AJSONValue: TJSONValue; AType: TRttiType; const AData: TValue): TValue;
    function ReadRecord(AJSONValue: TJSONValue; AType: TRttiType; const AData: TValue): TValue;
    function ReadDataSet(AJSONValue: TJSONValue; AType: TRttiType; const AData: TValue): TValue;
    function ReadStream(AJSONValue: TJSONValue; AType: TRttiType; const AData: TValue): TValue;

    function ReadStreamable(AJSONValue: TJSONValue; AType: TRttiType; const AData: TValue): Boolean;
    function ReadEnumerable(AJSONValue: TJSONValue; AType: TRttiType; const AData: TValue): Boolean;

    function ReadDataMember(AJSONValue: TJSONValue; AType: TRttiType; const AData: TValue): TValue;
  public
    constructor Create(const AConfig: INeonConfiguration);

    procedure JSONToObject(AObject: TObject; AJSON: TJSONValue);
    function JSONToTValue(AJSON: TJSONValue; AType: TRttiType): TValue; overload;
    function JSONToTValue(AJSON: TJSONValue; AType: TRttiType; const AData: TValue): TValue; overload;
    function JSONToArray(AJSON: TJSONValue; AType: TRttiType): TValue;
  end;

  TNeonMapperJSON = class
  public
    class function ValueToJSON(const AValue: TValue): TJSONValue; overload;
    class function ValueToJSON(const AValue: TValue; AConfig: INeonConfiguration): TJSONValue; overload;

    class function ObjectToJSON(AObject: TObject): TJSONValue; overload;
    class function ObjectToJSON(AObject: TObject; AConfig: INeonConfiguration): TJSONValue; overload;

    class function ObjectToJSONString(AObject: TObject): string; overload;
    class function ObjectToJSONString(AObject: TObject; AConfig: INeonConfiguration): string; overload;
  public
    class procedure JSONToObject(AObject: TObject; AJSON: TJSONValue; AConfig: INeonConfiguration); overload;
    class procedure JSONToObject(AObject: TObject; const AJSON: string; AConfig: INeonConfiguration); overload;

    class function JSONToObject(AType: TRttiType; AJSON: TJSONValue): TObject; overload;
    class function JSONToObject(AType: TRttiType; const AJSON: string): TObject; overload;

    class function JSONToObject<T: class, constructor>(AJSON: TJSONValue): T; overload;
    class function JSONToObject<T: class, constructor>(const AJSON: string): T; overload;
  end;

implementation

uses
  WiRL.Rtti.Utils,
  WiRL.Core.Utils;

{ TNeonSerializerJSON }

constructor TNeonSerializerJSON.Create(const AConfig: INeonConfiguration);
begin
  inherited Create(AConfig);
  FOperation := TNeonOperation.Serialize;
end;

function TNeonSerializerJSON.ObjectToJSON(AObject: TObject): TJSONValue;
begin
  FOriginalInstance := AObject;
  if not Assigned(AObject) then
    Exit(TJSONObject.Create);

  Result := WriteDataMember(AObject);
end;

function TNeonSerializerJSON.ValueToJSON(const AValue: TValue): TJSONValue;
begin
  FOriginalInstance := AValue;

  Result := WriteDataMember(AValue);
end;

function TNeonSerializerJSON.WriteArray(const AValue: TValue): TJSONValue;
var
  LIndex: Integer;
  LArray: TJSONArray;
begin
  LArray := TJSONArray.Create;
  for LIndex := 0 to AValue.GetArrayLength - 1 do
    LArray.AddElement(WriteDataMember(AValue.GetArrayElement(LIndex)));

  Result := LArray;
end;

function TNeonSerializerJSON.WriteChar(const AValue: TValue): TJSONValue;
begin
  if AValue.AsString = #0 then
    Result := TJSONString.Create('')
  else
    Result := TJSONString.Create(AValue.AsString);
end;

function TNeonSerializerJSON.WriteDataMember(const AValue: TValue): TJSONValue;
begin
  Result := nil;

  case AValue.Kind of
    tkChar,
    tkWChar:
    begin
      Result := WriteChar(AValue);
    end;

    tkString,
    tkLString,
    tkWString,
    tkUString:
    begin
      Result := WriteString(AValue);
    end;

    tkEnumeration:
    begin
      Result := WriteEnum(AValue);
    end;

    tkInteger,
    tkInt64:
    begin
      Result := WriteInteger(AValue);
    end;

    tkFloat:
    begin
      Result := WriteFloat(AValue);
    end;

    tkClass:
    begin
      if AValue.AsObject is TDataSet then
        Result := WriteDataSet(AValue)
      else if AValue.AsObject is TStream then
        Result := WriteStream(AValue)
      else
      begin
        Result := WriteEnumerable(AValue);
        if not Assigned(Result) then
          Result := WriteStreamable(AValue);
        if not Assigned(Result) then
          Result := WriteObject(AValue);
      end;
    end;

    tkArray:
    begin
      Result := WriteArray(AValue);
    end;

    tkDynArray:
    begin
      Result := WriteArray(AValue);
    end;

    tkSet:
    begin
      Result := WriteSet(AValue);
    end;

    tkRecord:
    begin
      Result := WriteRecord(AValue);
      if not Assigned(Result) then
        Result := TJSONObject.Create;
    end;

    tkInterface:
    begin
      Result := WriteInterface(AValue);
    end;

    tkVariant:
    begin
      Result := WriteVariant(AValue);
    end;
    {
    tkUnknown,
    tkMethod,
    tkPointer,
    tkProcedure,
    tkClassRef:
    }
  end;
end;

function TNeonSerializerJSON.WriteDataSet(const AValue: TValue): TJSONValue;
var
  LDataSet: TDataSet;
begin
  LDataSet := AValue.AsObject as TDataSet;

  if not Assigned(LDataSet) then
    Exit(TJSONNull.Create);

  Result := TDataSetUtils.DataSetToJSONArray(LDataSet, FConfig);
end;

function TNeonSerializerJSON.WriteEnum(const AValue: TValue): TJSONValue;
begin
  if AValue.TypeInfo = System.TypeInfo(Boolean) then
  begin
    if AValue.AsBoolean then
      Result := TJSONTrue.Create
    else
      Result := TJSONFalse.Create;
  end
  else
    Result := TJSONString.Create(GetEnumName(AValue.TypeInfo, AValue.AsOrdinal));
end;

function TNeonSerializerJSON.WriteFloat(const AValue: TValue): TJSONValue;
begin
  if (AValue.TypeInfo = System.TypeInfo(TDateTime)) or
     (AValue.TypeInfo = System.TypeInfo(TDate)) or
     (AValue.TypeInfo = System.TypeInfo(TTime)) then
    Result := TJSONString.Create(TJSONHelper.DateToJSON(AValue.AsType<TDateTime>, FConfig.UseUTCDate))
  else
    Result := TJSONNumber.Create(AValue.AsExtended);
end;

function TNeonSerializerJSON.WriteInteger(const AValue: TValue): TJSONValue;
begin
  Result := TJSONNumber.Create(AValue.AsInt64);
end;

function TNeonSerializerJSON.WriteInterface(const AValue: TValue): TJSONValue;
var
  LInterface: IInterface;
  LObject: TObject;
begin
  LInterface := AValue.AsInterface;
  LObject := LInterface as TObject;
  Result := WriteObject(LObject);
end;

procedure TNeonSerializerJSON.WriteMembers(AType: TRttiType;
  AInstance: Pointer; AResult: TJSONValue);
var
  LJSONValue: TJSONValue;
  LMembers: TNeonRttiMembers;
  LNeonMember: TNeonRttiMember;
begin
  LMembers := GetNeonMembers(AInstance, AType);
  LMembers.FilterSerialize;
  try
    for LNeonMember in LMembers do
    begin
      if LNeonMember.Serializable then
      begin
        try
          LJSONValue := WriteDataMember(LNeonMember.GetValue);
          if Assigned(LJSONValue) then
            (AResult as TJSONObject).AddPair(GetNameFromMember(LNeonMember), LJSONValue);
        except
          LogError(Format('Error converting property [%s] of object [%s]',
            [LNeonMember.Name, AType.Name]));
        end;
      end;
    end;
  finally
    LMembers.Free;
  end;
end;

function TNeonSerializerJSON.WriteObject(const AValue: TValue): TJSONValue;
var
  LObject: TObject;
  LType: TRttiType;
begin
  Result := TJSONObject.Create;
  LObject := AValue.AsObject;

  if not Assigned(LObject) then
    Exit(TJSONNull.Create);

  LType := TRttiHelper.Context.GetType(LObject.ClassType);

  WriteMembers(LType, LObject, Result);
end;

function TNeonSerializerJSON.WriteEnumerable(const AValue: TValue): TJSONValue;
var
  LObject: TObject;
  LMethodGetEnumerator, LMethodAdd: TRttiMethod;
  LMethodClear, LMethodMoveNext: TRttiMethod;
  LEnumObject: TObject;
  LListType, LEnumType: TRttiType;
  LCurrentProp: TRttiProperty;
  LValue: TValue;
  LJSONValue: TJSONValue;
begin
  Result := nil;
  LObject := AValue.AsObject;

  if not Assigned(LObject) then
    Exit(TJSONNull.Create);

  LListType := TRttiHelper.Context.GetType(LObject.ClassType);

  LMethodGetEnumerator := LListType.GetMethod('GetEnumerator');
  if not Assigned(LMethodGetEnumerator) or
     (LMethodGetEnumerator.MethodKind <> mkFunction) or
     (LMethodGetEnumerator.ReturnType.Handle.Kind <> tkClass)
  then
    Exit;

  LMethodClear := LListType.GetMethod('Clear');
  if not Assigned(LMethodClear) then
    Exit;

  LMethodAdd := LListType.GetMethod('Add');
  if not Assigned(LMethodAdd) or (Length(LMethodAdd.GetParameters) <> 1) then
    Exit;

  LEnumObject := LMethodGetEnumerator.Invoke(LObject, []).AsObject;
  if not Assigned(LEnumObject) then
    Exit;

  try
    LEnumType := TRttiHelper.Context.GetType(LEnumObject.ClassType);

    LCurrentProp := LEnumType.GetProperty('Current');
    if not Assigned(LCurrentProp) then
      Exit;

    LMethodMoveNext := LEnumType.GetMethod('MoveNext');
    if not Assigned(LMethodMoveNext) or
       (Length(LMethodMoveNext.GetParameters) <> 0) or
       (LMethodMoveNext.MethodKind <> mkFunction) or
       (LMethodMoveNext.ReturnType.Handle <> TypeInfo(Boolean))
    then
      Exit;

    Result := TJSONArray.Create;
    while LMethodMoveNext.Invoke(LEnumObject, []).AsBoolean do
    begin
      LValue := LCurrentProp.GetValue(LEnumObject);
      LJSONValue := WriteDataMember(LValue);

      (Result as TJSONArray).AddElement(LJSONValue);
    end;

  finally
    LEnumObject.Free;
  end;
end;

function TNeonSerializerJSON.WriteRecord(const AValue: TValue): TJSONValue;
var
  LType: TRttiType;
begin
  Result := TJSONObject.Create;
  LType := TRttiHelper.Context.GetType(AValue.TypeInfo);
  try
    WriteMembers(LType, AValue.GetReferenceToRawData, Result);
  except
    FreeAndNil(Result);
  end;
end;

function TNeonSerializerJSON.WriteSet(const AValue: TValue): TJSONValue;
begin
  Result := TJSONString.Create(SetToString(AValue.TypeInfo, Integer(AValue.GetReferenceToRawData^), True));
end;

function TNeonSerializerJSON.WriteStream(const AValue: TValue): TJSONValue;
var
  LStream: TStream;
  LBase64: string;
begin
  LStream := AValue.AsObject as TStream;

  if not Assigned(LStream) then
    Exit(TJSONNull.Create);

  LStream.Position := soFromBeginning;
  LBase64 := TBase64.Encode(LStream);
  Result := TJSONString.Create(LBase64);
end;

function TNeonSerializerJSON.WriteStreamable(const AValue: TValue): TJSONValue;
var
  LObject: TObject;
  LBinaryStream: TMemoryStream;
  LBase64: string;
  LStreamable: IDynamicStream;
begin
  Result := nil;
  LObject := AValue.AsObject;

  if not Assigned(LObject) then
    Exit(TJSONNull.Create);

  LStreamable := TDynamicStream.GuessType(LObject);
  if Assigned(LStreamable) then
  begin
    LBinaryStream := TMemoryStream.Create;
    try
      LStreamable.SaveToStream(LBinaryStream);
      LBinaryStream.Position := soFromBeginning;
      LBase64 := TBase64.Encode(LBinaryStream);
      if IsOriginalInstance(AValue) then
        Result := TJSONObject.Create.AddPair('$value', LBase64)
      else
        Result := TJSONString.Create(LBase64);
    finally
      LBinaryStream.Free;
    end;
  end;
end;

function TNeonSerializerJSON.WriteString(const AValue: TValue): TJSONValue;
begin
  Result := TJSONString.Create(AValue.AsString);
end;

function TNeonSerializerJSON.WriteVariant(const AValue: TValue): TJSONValue;
begin
  Result := TJSONString.Create(AValue.AsVariant);
end;

{ TNeonDeserializerJSON }

constructor TNeonDeserializerJSON.Create(const AConfig: INeonConfiguration);
begin
  inherited Create(AConfig);
  FOperation := TNeonOperation.Deserialize;
end;

{ TNeonDeserializerJSON }

function TNeonDeserializerJSON.ReadArray(AJSONValue: TJSONValue;
  AType: TRttiType; const AData: TValue): TValue;
var
  LIndex: NativeInt;
  LItemValue: TValue;
  LItemType: TRttiType;
  LJSONArray: TJSONArray;
  LJSONItem: TJSONValue;
begin
  // TValue record copy (but the TValue only copy the reference to Data)
  Result := AData;

  // Clear (and Free) previous elements?
  LJSONArray := AJSONValue as TJSONArray;
  LItemType := (AType as TRttiArrayType).ElementType;

  // Check static array bounds
  for LIndex := 0 to LJSONArray.Count - 1 do
  begin
    LJSONItem := LJSONArray.Items[LIndex];
    LItemValue := TRttiHelper.CreateNewValue(LItemType);
    LItemValue := ReadDataMember(LJSONItem, LItemType, Result);
    Result.SetArrayElement(LIndex, LItemValue);
  end;
end;

function TNeonDeserializerJSON.ReadDynArray(AJSONValue: TJSONValue; AType:
    TRttiType; const AData: TValue): TValue;
var
  LIndex: NativeInt;
  LItemValue: TValue;
  LItemType: TRttiType;
  LArrayLength: NativeInt;
  LJSONArray: TJSONArray;
  LJSONItem: TJSONValue;
begin
  Result := AData;

  // Clear (and Free) previous elements?
  LJSONArray := AJSONValue as TJSONArray;
  LItemType := (AType as TRttiDynamicArrayType).ElementType;
  LArrayLength := LJSONArray.Count;
  DynArraySetLength(PPointer(Result.GetReferenceToRawData)^, Result.TypeInfo, 1, @LArrayLength);

  for LIndex := 0 to LJSONArray.Count - 1 do
  begin
    LJSONItem := LJSONArray.Items[LIndex];

    LItemValue := TRttiHelper.CreateNewValue(LItemType);
    LItemValue := ReadDataMember(LJSONItem, LItemType, LItemValue);

    Result.SetArrayElement(LIndex, LItemValue);
  end;
end;

function TNeonDeserializerJSON.ReadChar(AJSONValue: TJSONValue; AType:
    TRttiType; AKind: TTypeKind): TValue;
begin
  if (AJSONValue is TJSONNull) or AJSONValue.Value.IsEmpty then
    Exit(#0);

  case AKind of
    // AnsiChar
    tkChar:  Result := TValue.From<UTF8Char>(UTF8Char(AJSONValue.Value.Chars[0]));

    // WideChar
    tkWChar: Result := TValue.From<Char>(AJSONValue.Value.Chars[0]);
  end;
end;

function TNeonDeserializerJSON.ReadDataMember(AJSONValue: TJSONValue; AType:
    TRttiType; const AData: TValue): TValue;
begin
  if AJSONValue is TJSONNull then
    Exit(TValue.Empty);

  case AType.TypeKind of
    // Simple types
    tkInt64:       Result := ReadInt64(AJSONValue, AType);
    tkInteger:     Result := ReadInteger(AJSONValue, AType);
    tkChar:        Result := ReadChar(AJSONValue, AType, AType.TypeKind);
    tkWChar:       Result := ReadChar(AJSONValue, AType, AType.TypeKind);
    tkEnumeration: Result := ReadEnum(AJSONValue, AType);
    tkFloat:       Result := ReadFloat(AJSONValue, AType);
    tkLString:     Result := ReadString(AJSONValue, AType, AType.TypeKind);
    tkWString:     Result := ReadString(AJSONValue, AType, AType.TypeKind);
    tkUString:     Result := ReadString(AJSONValue, AType, AType.TypeKind);
    tkString:      Result := ReadString(AJSONValue, AType, AType.TypeKind);
    tkSet:         Result := ReadSet(AJSONValue, AType);
    tkVariant:     Result := ReadVariant(AJSONValue, AType);
    tkArray:       Result := ReadArray(AJSONValue, AType, AData);
    tkDynArray:    Result := ReadDynArray(AJSONValue, AType, AData);

    // Complex types
    tkClass:
    begin
      { TODO -opaolo -c : Refactor Read*Object function (boolean result) 20/05/2017 12:25:19 }
      if AData.AsObject is TDataSet then
        Result := ReadDataSet(AJSONValue, AType, AData)
      else if AData.AsObject is TStream then
        Result := ReadStream(AJSONValue, AType, AData)
      else
      begin
        if ReadEnumerable(AJSONValue, AType, AData) then
          Result := AData
        else if ReadStreamable(AJSONValue, AType, AData) then
          Result := AData
        else
          Result := ReadObject(AJSONValue, AType, AData);
      end;
    end;
    tkInterface:   Result := ReadInterface(AJSONValue, AType, AData);
    tkRecord:      Result := ReadRecord(AJSONValue, AType, AData);

    // Not supported (yet)
    {
    tkUnknown: ;
    tkClassRef: ;
    tkPointer: ;
    tkMethod: ;
    tkProcedure: ;
    }
    else Result := TValue.Empty;
  end;
end;

function TNeonDeserializerJSON.ReadDataSet(AJSONValue: TJSONValue;
  AType: TRttiType; const AData: TValue): TValue;
var
  LJSONArray: TJSONArray;
  LJSONItem: TJSONObject;
  LJSONField: TJSONValue;
  LDataSet: TDataSet;
  LIndex: Integer;
  LItemIntex: Integer;
  LName: string;
begin
  Result := AData;
  LDataSet := AData.AsObject as TDataSet;
  LJSONArray := AJSONValue as TJSONArray;

  for LIndex := 0 to LJSONArray.Count - 1 do
  begin
    LJSONItem := LJSONArray.Items[LIndex] as TJSONObject;

    LDataSet.Append;
    for LItemIntex := 0 to LDataSet.Fields.Count - 1 do
    begin
      LName := LDataSet.Fields[LItemIntex].FieldName;

      LJSONField := LJSONItem.GetValue(LName);
      if Assigned(LJSONField) then
      begin
        { TODO -opaolo -c : Be more specific (field and json type) 27/04/2017 17:16:09 }
        LDataSet.FieldByName(LName).AsString := LJSONField.Value;
      end;
    end;
    LDataSet.Post;
  end;
end;

function TNeonDeserializerJSON.ReadEnum(AJSONValue: TJSONValue; AType: TRttiType): TValue;
begin
  if AType.Handle = System.TypeInfo(Boolean) then
  begin
    if AJSONValue is TJSONTrue then
      Result := True
    else if AJSONValue is TJSONFalse then
      Result := False
    else
      raise ENeonException.Create('Invalid JSON value. Boolean expected');
  end
  else
  begin
    TValue.Make(GetEnumValue(AType.Handle, AJSONValue.Value), AType.Handle, Result);
  end;
end;

function TNeonDeserializerJSON.ReadEnumerable(AJSONValue: TJSONValue; AType:
    TRttiType; const AData: TValue): Boolean;
var
  LItemValue: TValue;
  LList: IDynamicList;
  LJSONArray: TJSONArray;
  LJSONItem: TJSONValue;
  LIndex: Integer;
  LItemType: TRttiType;
begin
  Result := False;
  LList := TDynamicList.GuessType(AData.AsObject);
  if Assigned(LList) then
  begin
    Result := True;
    LItemType := LList.GetItemType;
    LList.Clear;

    LJSONArray := AJSONValue as TJSONArray;

    for LIndex := 0 to LJSONArray.Count - 1 do
    begin
      LJSONItem := LJSONArray.Items[LIndex];

      LItemValue := LList.NewItem;
      LItemValue := ReadDataMember(LJSONItem, LItemType, LItemValue);

      LList.Add(LItemValue);
    end;
  end;
end;

function TNeonDeserializerJSON.ReadFloat(AJSONValue: TJSONValue; AType: TRttiType): TValue;
begin
  if AJSONValue is TJSONNull then
    Exit(0);

  if AType.Handle = System.TypeInfo(TDate) then
    Result := TValue.From<TDate>(TJSONHelper.JSONToDate(AJSONValue.Value, True))
  else if AType.Handle = System.TypeInfo(TTime) then
    Result := TValue.From<TTime>(TJSONHelper.JSONToDate(AJSONValue.Value, True))
  else if AType.Handle = System.TypeInfo(TDateTime) then
    Result := TValue.From<TDateTime>(TJSONHelper.JSONToDate(AJSONValue.Value, True))
  else
  begin
    if AJSONValue is TJSONNumber then
      Result := (AJSONValue as TJSONNumber).AsDouble
    else
      raise ENeonException.Create('Invalid JSON value. Float expected');
  end;
end;

function TNeonDeserializerJSON.ReadInt64(AJSONValue: TJSONValue; AType:
    TRttiType): TValue;
var
  LNumber: TJSONNumber;
begin
  if AJSONValue is TJSONNull then
    Exit(0);

  LNumber := AJSONValue as TJSONNumber;
  Result := LNumber.AsInt64
end;

function TNeonDeserializerJSON.ReadInteger(AJSONValue: TJSONValue; AType: TRttiType): TValue;
var
  LNumber: TJSONNumber;
begin
  if AJSONValue is TJSONNull then
    Exit(0);

  LNumber := AJSONValue as TJSONNumber;
  Result := LNumber.AsInt;
end;

function TNeonDeserializerJSON.ReadInterface(AJSONValue: TJSONValue;
  AType: TRttiType; const AData: TValue): TValue;
begin
  Result := AData;
end;

procedure TNeonDeserializerJSON.ReadMembers(AType: TRttiType;
  AInstance: Pointer; AJSONObject: TJSONObject);
var
  LMembers: TNeonRttiMembers;
  LNeonMember: TNeonRttiMember;
  LJSONValue: TJSONValue;
  LMemberValue: TValue;
begin
  LMembers := GetNeonMembers(AInstance, AType);
  LMembers.FilterDeserialize;
  try
    for LNeonMember in LMembers do
    begin
      if LNeonMember.Serializable then
      begin
        //Look for a JSON with the calculated Member Name
        LJSONValue := AJSONObject.GetValue(GetNameFromMember(LNeonMember));

        // Property not found in JSON, continue to the next one
        if not Assigned(LJSONValue) then
          Continue;

        LMemberValue := ReadDataMember(LJSONValue, LNeonMember.RttiType, LNeonMember.GetValue);
        LNeonMember.SetValue(LMemberValue);
      end;
    end;
  finally
    LMembers.Free;
  end;
end;

function TNeonDeserializerJSON.ReadObject(AJSONValue: TJSONValue;
  AType: TRttiType; const AData: TValue): TValue;
var
  LJSONObject: TJSONObject;
  LPData: Pointer;
begin
  Result := AData;
  LPData := AData.AsObject;
  LJSONObject := AJSONValue as TJSONObject;

  if (AType.TypeKind = tkClass) or (AType.TypeKind = tkInterface) then
    ReadMembers(AType, LPData, LJSONObject);
end;

function TNeonDeserializerJSON.ReadRecord(AJSONValue: TJSONValue;
  AType: TRttiType; const AData: TValue): TValue;
var
  LJSONObject: TJSONObject;
  LPData: Pointer;
begin
  Result := AData;
  LPData := AData.GetReferenceToRawData;

  if not Assigned(LPData) then
    Exit;

  // Objects, Records, Interfaces are all represented by JSON objects
  LJSONObject := AJSONValue as TJSONObject;

  ReadMembers(AType, LPData, LJSONObject);
end;

function TNeonDeserializerJSON.ReadSet(AJSONValue: TJSONValue; AType: TRttiType): TValue;
var
  LSetStr: string;
begin
  LSetStr := AJSONValue.Value;
  LSetStr := LSetStr.Replace(sLineBreak, '', [rfReplaceAll]);
  LSetStr := LSetStr.Replace(' ', '', [rfReplaceAll]);
  TValue.Make(StringToSet(AType.Handle, LSetStr), aType.Handle, Result);
end;

function TNeonDeserializerJSON.ReadStream(AJSONValue: TJSONValue;
  AType: TRttiType; const AData: TValue): TValue;
var
  LStream: TStream;
begin
  Result := AData;
  LStream := AData.AsObject as TStream;
  LStream.Position := soFromBeginning;

  TBase64.Decode(AJSONValue.Value, LStream);
end;

function TNeonDeserializerJSON.ReadStreamable(AJSONValue: TJSONValue;
  AType: TRttiType; const AData: TValue): Boolean;
var
  LStream: TMemoryStream;
  LStreamable: IDynamicStream;
  LJSONValue: TJSONValue;
begin
  Result := False;
  LStreamable := TDynamicStream.GuessType(AData.AsObject);
  if Assigned(LStreamable) then
  begin
    Result := True;
    LStream := TMemoryStream.Create;
    try
      if IsOriginalInstance(AData) then
        LJSONValue := (AJSONValue as TJSONObject).GetValue('$value')
      else
        LJSONValue := AJSONValue;

      TBase64.Decode(LJSONValue.Value, LStream);
      LStream.Position := soFromBeginning;
      LStreamable.LoadFromStream(LStream);
    finally
      LStream.Free;
    end;
  end;
end;

function TNeonDeserializerJSON.ReadString(AJSONValue: TJSONValue;
  AType: TRttiType; AKind: TTypeKind): TValue;
begin
  case AKind of
    // AnsiString
    tkLString: Result := TValue.From<UTF8String>(UTF8String(AJSONValue.Value));

    //WideString
    tkWString: Result := TValue.From<string>(AJSONValue.Value);

    //UnicodeString
    tkUString: Result := TValue.From<string>(AJSONValue.Value);

    //ShortString
    tkString:  Result := TValue.From<UTF8String>(UTF8String(AJSONValue.Value));

    // Future string types treated as unicode strings
    else
      Result := AJSONValue.Value;
  end;
end;

function TNeonDeserializerJSON.ReadVariant(AJSONValue: TJSONValue; AType: TRttiType): TValue;
begin

end;

function TNeonDeserializerJSON.JSONToArray(AJSON: TJSONValue; AType: TRttiType): TValue;
begin
  Result := ReadDataMember(AJSON, AType, TValue.Empty);
end;

procedure TNeonDeserializerJSON.JSONToObject(AObject: TObject; AJSON: TJSONValue);
var
  LType: TRttiType;
  LValue: TValue;
begin
  FOriginalInstance := AObject;
  LType := TRttiHelper.Context.GetType(AObject.ClassType);
  LValue := AObject;
  ReadDataMember(AJSON, LType, AObject);
end;

function TNeonDeserializerJSON.JSONToTValue(AJSON: TJSONValue; AType: TRttiType;
  const AData: TValue): TValue;
begin
  FOriginalInstance := AData;
  Result := ReadDataMember(AJSON, AType, AData);
end;

function TNeonDeserializerJSON.JSONToTValue(AJSON: TJSONValue; AType: TRttiType): TValue;
begin
  //FOriginalInstance := AData;
  Result := ReadDataMember(AJSON, AType, TValue.Empty);
end;

{ TNeonMapperJSON }

class function TNeonMapperJSON.JSONToObject(AType: TRttiType; AJSON: TJSONValue): TObject;
begin
  Result := TRttiHelper.CreateInstance(AType);
  JSONToObject(Result, AJSON, TNeonConfiguration.Default);
end;

class function TNeonMapperJSON.JSONToObject(AType: TRttiType; const AJSON: string): TObject;
var
  LJSON: TJSONValue;
begin
  LJSON := TJSONObject.ParseJSONValue(AJSON);
  try
    Result := TRttiHelper.CreateInstance(AType);
    JSONToObject(Result, LJSON, TNeonConfiguration.Default);
  finally
    LJSON.Free;
  end;
end;

class function TNeonMapperJSON.JSONToObject<T>(AJSON: TJSONValue): T;
begin
  Result := JSONToObject(TRttiHelper.Context.GetType(TClass(T)), AJSON) as T;
end;

class procedure TNeonMapperJSON.JSONToObject(AObject: TObject; const AJSON: string; AConfig: INeonConfiguration);
var
  LJSON: TJSONValue;
begin
  LJSON := TJSONObject.ParseJSONValue(AJSON);
  try
    JSONToObject(AObject, LJSON, AConfig);
  finally
    LJSON.Free;
  end;
end;

class function TNeonMapperJSON.JSONToObject<T>(const AJSON: string): T;
begin
  Result := JSONToObject(TRttiHelper.Context.GetType(TClass(T)), AJSON) as T;
end;

class function TNeonMapperJSON.ObjectToJSON(AObject: TObject; AConfig: INeonConfiguration): TJSONValue;
var
  LWriter: TNeonSerializerJSON;
begin
  LWriter := TNeonSerializerJSON.Create(AConfig);
  try
    Result := LWriter.ObjectToJSON(AObject);
  finally
    LWriter.Free;
  end;
end;

class function TNeonMapperJSON.ObjectToJSONString(AObject: TObject): string;
begin
  Result := TNeonMapperJSON.ObjectToJSONString(AObject, TNeonConfiguration.Default);
end;

class function TNeonMapperJSON.ObjectToJSON(AObject: TObject): TJSONValue;
begin
  Result := TNeonMapperJSON.ObjectToJSON(AObject, TNeonConfiguration.Default);
end;

class function TNeonMapperJSON.ObjectToJSONString(AObject: TObject; AConfig: INeonConfiguration): string;
var
  LJSON: TJSONValue;
begin
  LJSON := ObjectToJSON(AObject, AConfig);
  try
    Result := TJSONHelper.ToJSON(LJSON);
  finally
    LJSON.Free;
  end;
end;

class function TNeonMapperJSON.ValueToJSON(const AValue: TValue): TJSONValue;
begin
  Result := TNeonMapperJSON.ValueToJSON(AValue, TNeonConfiguration.Default);
end;

class function TNeonMapperJSON.ValueToJSON(const AValue: TValue; AConfig: INeonConfiguration): TJSONValue;
var
  LWriter: TNeonSerializerJSON;
begin
  LWriter := TNeonSerializerJSON.Create(AConfig);
  try
    Result := LWriter.ValueToJSON(AValue);
  finally
    LWriter.Free;
  end;
end;

class procedure TNeonMapperJSON.JSONToObject(AObject: TObject; AJSON:
    TJSONValue; AConfig: INeonConfiguration);
var
  LReader: TNeonDeserializerJSON;
begin
  LReader := TNeonDeserializerJSON.Create(AConfig);
  try
    LReader.JSONToObject(AObject, AJSON);
  finally
    LReader.Free;
  end;
end;

end.
