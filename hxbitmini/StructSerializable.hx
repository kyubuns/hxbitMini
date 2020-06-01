package hxbitmini;

/**
	Struct serializable are more lightweight (no versioning etc.) than normal Serializable but a bit larger when serializing.
**/
interface StructSerializable {
	private function customSerialize( ctx : Serializer ) : Void;
	private function customUnserialize( ctx : Serializer ) : Void;
}
