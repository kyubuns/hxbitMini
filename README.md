# HxBitMini

HxBitMini is a binary serialization library for Haxe.  
Forked from [HxBit](https://github.com/HeapsIO/hxbit).

## Installation

TBD

## Serialization

You can serialize objects by implementing the `hxbit.Serializable` interface. You need to specify which fields you want to serialize by using the `@:s` metadata:

```haxe
class User implements hxbit.Serializable {
    @:s public var name : String;
    @:s public var age : Int;
    @:s public var friends : Array<User>;
    ...
}
```

This will automatically add a few methods and variables to your `User` class:

```haxe
/**
  These fields are automatically generated when implementing the interface.
**/
interface Serializable {
	/** Returns the unique class id for this object **/
	public function getCLID() : Int;
	/** Serialize the object id and fields using this Serializer **/
	public function serialize( ctx : hxbit.Serializer ) : Void;
	/** Unserialize object fields using this Serializer **/  
	public function unserialize( ctx : hxbit.Serializer ) : Void;
	/** Returns the object data schema **/  
	public function getSerializeSchema() : hxbit.Schema;
}
```

This allows you to serialize/unserialize using this code:

```haxe
var s = new hxbit.Serializer();
var bytes = s.serialize(user);
....
var u = new hxbit.Serializer();
var user = u.unserialize(bytes, User);
....
```

### Comparison with haxe.Serializer/Unserializer

Haxe standard library serialization works by doing runtime type checking, which is slower. However it can serialize any value even if it's not been marked as Serializable.

HxBit serialization uses macro to generate strictly typed serialization code that allows very fast I/O. OTOH this increase code size and is using a less readable binary format instead of Haxe standard serialization which uses a text representation.

### Supported types

The following types are supported:

  - Int / haxe.UInt : stored as either 1 byte (0-254) or 5 bytes (0xFF + 32 bits)
  - Float : stored as single precision 32 bits IEEE float
  - Bool : stored as single by (0 or 1)
  - String : stored as size+1 prefix, then utf8 bytes (0 prefix = null)
  - any Enum value : stored as index byte + args values
  - haxe.io.Bytes : stored as size+1 prefix + raw bytes (0 prefix = null)
  - Array&lt;T&gt; and haxe.ds.Vector&lt;T&gt; : stored as size+1 prefix, then T list (0 prefix = null)
  - Map&lt;K,V&gt; : stored as size+1 prefix, then (K,V) pairs (0 prefix = null)
  - Null&lt;T&gt; : stored as a byte 0 for null, 1 followed by T either
  - Serializable (any other serializable instance) : stored with __uid, then class id and data if if was not already serialized
  - Strutures { field : T... } : optimized to store a bit field of not null values, then only defined fields values 

### Default values

When unserializing, the class constructor is not called. If you want to have some non-serialized field already initialized before starting unserialization, you can set the default value using Haxe initializers:

```haxe
class User implements hxbit.Serializable {
    ...
    // when unserializing, someOtherField will be set to [] instead of null
    var someOtherField : Array<Int> = []; 
}
```

### Unsupported types

If you want to serialize unsupported types, you could implement your own serialization through the optional methods `customSerialize` and `customUnserialize`.

```haxe
class Float32ArrayContainer implements hxbit.Serializable {

    public var value:Float32Array;

    ...

    @:keep
    public function customSerialize(ctx : hxbit.Serializer) {
        ctx.addInt(value.length);
        for(i in 0...value.length)
            ctx.addFloat(value[i]);
    }

    @:keep
    public function customUnserialize(ctx : hxbit.Serializer) {
        var length = ctx.getInt();
        var tempArray = new Array<Float>();
        for(i in 0...length)
            tempArray.push(ctx.getFloat());

        value = new Float32Array(tempArray);
    }
}
```

## Versioning

HxBit serialization is capable of performing versioning, by storing in serialized data the schema of each serialized class, then comparing it to the current schema when unserializing, making sure that data is not corrupted.

In order to save some data with versioning, use the following:

```haxe
var s = new hxbit.Serializer();
s.beginSave();
// ... serialize your data...
var bytes = s.endSave();
```

And in order to load versionned data, use:

```haxe
var s = new hxbit.Serializer();
s.beginLoad(bytes);
// .. unserializer your data
```
Versioned data is slightly larger than unversioned one since it contains the Schema data of each serialized class.

Currently versioning handles:
 - removing fields (previous data is ignored)
 - adding fields (they are set to default value: 0 for Int/Float, false for Bool, empty Array/Map/etc.)

More convertions can be easily added in `Serializer.convertValue`, including custom ones if you extends Serializer. 

