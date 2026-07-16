module vop

pub struct Null {}

pub type Value = Method | Null | Object | bool | f64 | int | string

fn default_method_fn(_ Object, _ []Value) Value {
	return Null{}
}

fn default_handler_fn(_ Object, _ string, _ []Value) Value {
	return Null{}
}

pub struct Method {
pub:
	func fn (Object, []Value) Value = default_method_fn
}

pub struct Object {
pub:
	handler fn (Object, string, []Value) Value = default_handler_fn
}

pub fn (obj Object) call(msg string, args ...Value) Value {
	return obj.handler(obj, msg, args)
}

pub fn (obj Object) get[T](key string) !T {
	val := obj.call('get', key)
	$if T is string {
		if val is string {
			return val
		}
	} $else $if T is int {
		if val is int {
			return val
		}
	} $else $if T is f64 {
		if val is f64 {
			return val
		}
	} $else $if T is bool {
		if val is bool {
			return val
		}
	} $else $if T is Object {
		if val is Object {
			return val
		}
	} $else $if T is Value {
		return val
	} $else {
		$compile_error('vop.get[T]: unsupported type')
	}
	return error('vop.get[T]: type mismatch or null value')
}

pub fn (obj Object) set[T](key string, val T) Object {
	$if T is string {
		obj.call('set', key, Value(val))
	} $else $if T is int {
		obj.call('set', key, Value(val))
	} $else $if T is f64 {
		obj.call('set', key, Value(val))
	} $else $if T is bool {
		obj.call('set', key, Value(val))
	} $else $if T is Object {
		obj.call('set', key, Value(val))
	} $else $if T is Value {
		obj.call('set', key, val)
	} $else {
		$compile_error('vop.set[T]: unsupported type')
	}
	return obj
}

pub fn (obj Object) define(name string, method Method) Object {
	obj.call('define', name, method)
	return obj
}

pub fn (obj Object) call_as[T](msg string, args ...Value) !T {
	val := obj.call(msg, ...args)
	$if T is string {
		if val is string {
			return val
		}
	} $else $if T is int {
		if val is int {
			return val
		}
	} $else $if T is f64 {
		if val is f64 {
			return val
		}
	} $else $if T is bool {
		if val is bool {
			return val
		}
	} $else $if T is Object {
		if val is Object {
			return val
		}
	} $else $if T is Value {
		return val
	} $else {
		$compile_error('vop.call_as[T]: unsupported return type')
	}
	return error('vop.call_as[T]: type mismatch or invalid method return type')
}

pub fn from_struct[T](s T) Object {
	mut parent := new_base()
	$for field in T.fields {
		$if field.typ is string {
			parent.set(field.name, s.$(field.name))
		} $else $if field.typ is int {
			parent.set(field.name, s.$(field.name))
		} $else $if field.typ is f64 {
			parent.set(field.name, s.$(field.name))
		} $else $if field.typ is bool {
			parent.set(field.name, s.$(field.name))
		}
	}
	return parent
}

pub fn to_struct[T](obj Object) T {
	mut s := T{}
	$for field in T.fields {
		$if field.typ is string {
			s.$(field.name) = obj.get[string](field.name) or { '' }
		} $else $if field.typ is int {
			s.$(field.name) = obj.get[int](field.name) or { 0 }
		} $else $if field.typ is f64 {
			s.$(field.name) = obj.get[f64](field.name) or { 0.0 }
		} $else $if field.typ is bool {
			s.$(field.name) = obj.get[bool](field.name) or { false }
		}
	}
	return s
}

pub fn new_object(props map[string]Value) Object {
	mut parent := new_base()
	for k, v in props {
		parent.set(k, v)
	}
	return parent
}

pub fn (v Value) to_str() string {
	match v {
		string { return v }
		int { return v.str() }
		f64 { return v.str() }
		bool { return v.str() }
		else { return '' }
	}
}

pub fn (v Value) to_int() int {
	match v {
		int { return v }
		else { return 0 }
	}
}

pub fn (v Value) to_bool() bool {
	match v {
		bool { return v }
		else { return false }
	}
}

pub fn new_base() Object {
	mut properties := map[string]Value{}
	mut dynamic_methods := map[string]Method{}

	return Object{
		handler: fn [mut properties, mut dynamic_methods] (self_obj Object, msg string, args []Value) Value {
			match msg {
				'get' {
					if args.len > 0 {
						key := args[0]
						if key is string {
							return properties[key] or { Null{} }
						}
					}
					return Null{}
				}
				'set' {
					if args.len > 1 {
						key := args[0]
						val := args[1]
						if key is string {
							properties[key] = val
							return true
						}
					}
					return false
				}
				'define' {
					if args.len > 1 {
						name := args[0]
						method := args[1]
						if name is string && method is Method {
							dynamic_methods[name] = method
							return true
						}
					}
					return false
				}
				'respond_to' {
					if args.len > 0 {
						name := args[0]
						if name is string {
							if name in dynamic_methods {
								return true
							}
						}
					}
					return false
				}
				else {
					if msg in dynamic_methods {
						return dynamic_methods[msg].func(self_obj, args)
					}
					return Null{}
				}
			}
		}
	}
}