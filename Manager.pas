unit Manager;

interface

uses
  Generics.Collections,
  FireDAC.Comp.Client;

type

TManager<T: class, constructor> = class
  fObject: T;
  fPrimaryKey: String;
  fTablename: String;
  fFdQuery: TFdQuery;
  fList: TObjectList<Tobject>;

  constructor Create(var aObject: T; aFdQuery: TFdQuery);
  destructor Destroy;

  function Tablename(const aTablename: String = ''): TManager<T>;
  function PrimaryKey(const aPrimaryKey: String = 'ID'): TManager<T>;

  function OpenSQL: String;

  /// <summary>
  ///   Mapeia a query sql gravando nela todos os valores do objeto
  /// </summary>
  procedure MapToQuery(var aObject: T);
  procedure MapFromQuery(var aObject: T);

  function Open(const aSQL: String = ''; const aWhere: String = ''{; aParam: Array of variant = []}): T;
  function Post(var aObject: T; vUpdateSQL: String; const aParametros: Array of Variant): Boolean;
//  procedure post(var aObject: T); overload;
  function ToJson(const aObject: T; const aPrettyPrint: Boolean = False): String;

end;

implementation

uses
  System.Rtti,
  System.Classes,
  System.SysUtils,
  FireDAC.Stan.Param,        // TfdMacro
  Grijjy.Bson.Serialization, // ToJson
  Grijjy.Bson;               // Json Annotation

{ TManager<T> }
constructor TManager<T>.create(var aObject: T; aFdQuery: TFdQuery);
begin
  fTablename := '';
  fPrimaryKey := '';

  if not assigned(aObject) then
    raise Exception.Create('aObject of <T> has not an Instance');

  fObject := aObject;
  fFdQuery := aFdQuery;

end;

function TManager<T>.Open(const aSQL: String; const aWhere: String{; aParam: Array of variant}): T;
var
  //RTTI
  ctx: TRttiContext;
  ty: TRttiType;
  prop: TRttiProperty;
  fi: TRttiField;
  val: variant;
  comp: TComponent;

  //ORM
  TablenameDefault: String;
  WhereDefault: String;

  //SQL
  SQLDefault: String;
  Macro: TFdMacro;
  I: Integer;
begin

  /// <summary>
  ///   Throught mapping the context of T, it's structures a SQL, run the Query and retrieve
  ///   the values of each property or class field which reference is found in the Query (same name)
  ///   Ignores unknown fields
  ///   Applies just first record of query
  /// </summary>

  {$REGION 'Default Values'}
  if fTablename <> emptyStr then
  begin
    TablenameDefault := fTablename
  end else
  begin
    TablenameDefault := T.ClassName;
    if ClassName[1] = 'T' then
      Delete(TablenameDefault, 1, 1);
  end;

  if aWhere <> emptyStr then
    WhereDefault := aWhere
  else
    WhereDefault := '';

  if aSQL <> emptyStr then
    SQLDefault := aSQL
  else
    SQLDefault := OpenSQL();

  fFdQuery.Close;
  fFdQuery.Sql.Clear;
  fFdQuery.SQL.Text := SqlDefault;

  for I := 0 to fFdQuery.Macros.Count-1 do
  begin
    Macro := fFdQuery.Macros.Items[I];
    if LowerCase(Macro.Name) = 'tablename' then
      Macro.AsRaw := TablenameDefault;
    if LowerCase(Macro.Name) = 'where' then
      Macro.AsRaw := WhereDefault;
  end;

  fFdQuery.Open();
  if fFdQuery.RecordCount = 0 then
      Exit(Nil);

  if not assigned(fObject) then
    fObject := T.create();

  result := fObject;

  ctx := TRttiContext.Create;
  ty := ctx.GetType(T.ClassInfo);

  try
    for prop in ty.GetProperties do
    begin
      if not Prop.IsWritable then
        continue;

      if fFdQuery.FindField(prop.Name) <> nil then
      begin
        try
          prop.SetValue(Pointer(fObject), TValue.From(fFdQuery.FieldByName(prop.Name).Value));
        finally

        end;
      end;

    end;
         
    for fi in ty.GetFields do
    begin
     if fFdQuery.FindField(fi.Name) <> nil then
      begin
        try
          fi.SetValue(Pointer(fObject), TValue.From(fFdQuery.FieldByName(fi.Name).Value));
        finally

        end;
      end;
    end;

  finally

     ctx.Free;
  end;
end;

function TManager<T>.OpenSQL: String;
begin
  result := 'select * from &tablename &where';
end;

function TManager<T>.Post(var aObject: T; vUpdateSQL: String; const aParametros: Array of Variant): Boolean;
begin
  result := fFdQuery.Connection.ExecSQL(vUpdateSQL, aParametros) > 0;
end;

function TManager<T>.PrimaryKey(const aPrimaryKey: String): TManager<T>;
begin
  fPrimaryKey := aPrimaryKey;
  result := self;
end;

function TManager<T>.Tablename(const aTablename: String): TManager<T>;
begin
  fTablename := aTablename;
  result := self;
end;

function TManager<T>.ToJson(const aObject: T; const aPrettyPrint: Boolean = False): String;
var
  vSettings:   TGoJsonWriterSettings;
begin
  vSettings := TGoJsonWriterSettings.Create(aPrettyPrint);
  Grijjy.Bson.Serialization.TgoBsonSerializer.Serialize<T>(aObject, vSettings, result);
end;

destructor TManager<T>.Destroy;
begin

end;

procedure TManager<T>.MapFromQuery(var aObject: T);
var
  //RTTI
  ctx: TRttiContext;
  ty: TRttiType;
  prop: TRttiProperty;
  fi: TRttiField;
  val: variant;
  comp: TComponent;

begin
  ctx := TRttiContext.Create;
  ty := ctx.GetType(T.ClassInfo);

  try
    for prop in ty.GetProperties do
    begin
      if not Prop.IsWritable then
        continue;

      if fFdQuery.FindField(prop.Name) <> nil then
      begin
        try
          prop.SetValue(Pointer(fObject), TValue.From(fFdQuery.FieldByName(prop.Name).Value));
        finally

        end;
      end;

    end;

    for fi in ty.GetFields do
    begin
     if fFdQuery.FindField(fi.Name) <> nil then
      begin
        try
          fi.SetValue(Pointer(fObject), TValue.From(fFdQuery.FieldByName(fi.Name).Value));
        finally

        end;
      end;
    end;

  finally

     ctx.Free;
  end;

end;

procedure TManager<T>.MapToQuery(var aObject: T);
var
  //RTTI
  ctx: TRttiContext;
  ty: TRttiType;
  prop: TRttiProperty;
  fi: TRttiField;
  val: variant;
  comp: TComponent;
begin
  ctx := TRttiContext.Create;
  ty := ctx.GetType(T.ClassInfo);

  try
    for prop in ty.GetProperties do
    begin
      if not Prop.IsReadable then
        continue;

      if prop.Name = 'ID' then
           continue;

      if fFdQuery.FindField(prop.Name) <> nil then
      begin
        try
          fFdQuery.FieldByName(fi.Name).Value := prop.GetValue(Pointer(fObject)).AsVariant;
        finally

        end;
      end;

    end;

    for fi in ty.GetFields do
    begin

      if fi.Name = 'ID' then
           continue;

     if fFdQuery.FindField(fi.Name) <> nil then
      begin
        try
          fFdQuery.FieldByName(fi.Name).Value := fi.GetValue(Pointer(fObject)).AsVariant;
        finally

        end;
      end;
    end;

  finally

     ctx.Free;
  end;

end;

end.
