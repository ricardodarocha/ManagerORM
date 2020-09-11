# ManagerORM
ORM Object Relational Mapping Manager. This is an unit that map FDQuery to object&lt;T>

**Requirements**
Recently Delphi version 
Support for Generics
Support for rtti
Suport for Firedac

**Usage**

1. Declare a class that represents your database entities (Model)
```Pascal
TCar = class
      Brand: String;
      Year: Tdatetime;
      Power: Integer;
    end;
```

2. Use TManager to bring data from database to object
```Pascal
  var
      Car: TCar;
      Manager: TManager<TCar>;
      -- FdQuery1: TFdQuery; Put a FdQuery into Datamodule and configure a FdConnection
    begin
      Car := TCar.Create;
      Manager := TManager<TCar>.Create(Car, FdQuery1);
      Manager.Open(); //it performs 'select brand, year, power from car' automatically
      while Manager.Iterate do
        ListBox1.add(format('%s - %d hp', [Car.Brand, Car.Power]), Car);
    end; 

```
```Shell
$? #output
> Maserati Levante - 350 hp
> Alfa Romeo Giulia 952 - 200 hp
```
  
3.Create a new car and save to database
```Pascal
var
  Car: TCar;
  Manager: TManager<TCar>;
begin
  Car := TCar.Create;
  Car.Brand := 'Dodge Viper II';
  Car.Year := 2007;
  Car.Power := 608;
  Manager := TManager<TCar>.Create(Car, FdQuery1);
  Manager.Post(Car);
  Car.Free;
  Manager.Free;
end;
```

4. Normally you need to configure FdQuery with fielddefs to allow Firedac to generate autoinc, and to fill required field with defaults.
  To automatize this task use custom sql to save data
 ```Pascal
    with Car do
      Manager.Post(Car, 'insert into car (Brand, Year, Power) values(:b, :y, :p)', [Brand, Year, Power]);

``` 

**Dependencies**
This unit uses Grijjy.Bson.Serialization lib to generate JSON
```Pascal
uses ... 
  Grijjy.Bson.Serialization, // ToJson
  Grijjy.Bson;               // Json Annotation
```
```Shell
git clone https://github.com/grijjy/GrijjyFoundation.git
```

Read documentation
https://grijjy.github.io/GrijjyFoundation/

To remove that dependency just delete uses and implement the method `ToJson()` with your way 
