# vop

A message-passing object protocol for the V programming language. It provides dynamic property and method management, closure-based state encapsulation, and compile-time struct translation.

---

## Features

- **Closure-Based Encapsulation:** State (properties and methods) is captured inside a closure handler, preventing direct external access to the underlying storage maps.
- **Dynamic Fields and Methods:** Properties and behaviors can be added, updated, or checked at runtime.
- **Self-Reference Passing:** Dynamic methods receive the calling object as their first parameter, enabling access and modification of the object's properties.
- **Compile-Time Struct Bridge:** Utilities to translate static V structs into dynamic objects and vice versa using V's comptime reflection features.
- **Standard Error Handling:** Employs V's Result type (`!T`) for runtime type verification and retrieval.

---

## Setup and Installation

You can integrate this module into your project using one of the following methods:

### Option 1: Global Installation (Recommended)
Install the module globally using V's package manager directly from your Git repository:

```bash
v install --git https://github.com/tailsmails/vop
```

Once installed, you can import it in any V project on your system:

```v
import vop
```

### Option 2: Local Directory Setup (Manual)
If you prefer not to install it globally, clone or copy the `vop` folder directly into your project's directory structure:

```text
my_project/
├── vop/
│   └── vop.v
└── main.v
```

And import it inside your `main.v` as `import vop`.

---

## Core Architecture

At the core of the module is the `Object` struct, which contains a single function pointer called `handler`:

```v
pub struct Object {
pub:
	handler fn (Object, string, []Value) Value = default_handler_fn
}
```

The handler acts as a dispatcher. When `call` is invoked on an `Object`, the message and arguments are sent to this handler, which executes the corresponding logic (getting/setting a property or executing a registered `Method`). 

The internal state is stored in `properties` and `dynamic_methods` maps. These maps are instantiated inside `new_base()` and captured by the handler closure, making them inaccessible from outside the interface.

---

## Usage Guide

### 1. Property Management
Initialize an empty object, write values, and retrieve them:

```v
import vop

fn main() {
	mut obj := vop.new_base()
	obj.set('name', 'Alice')
	obj.set('age', 25)

	// Retrieval returns a Result Type (!T)
	name := obj.get[string]('name') or { 'Unknown' }
	age := obj.get[int]('age') or { 0 }
}
```

### 2. Defining Methods with Self-Reference
Dynamic methods have access to the object they are executed on via the first parameter (`self`). This allows them to mutate or query the object's properties:

```v
import vop

fn main() {
	mut obj := vop.new_base()
	obj.set('balance', 100)

	// Define a deposit method
	deposit_method := vop.Method{
		func: fn (self vop.Object, args []vop.Value) vop.Value {
			amount := args[0].to_int()
			current_balance := self.get[int]('balance') or { 0 }
			self.set('balance', current_balance + amount)
			return vop.Null{}
		}
	}

	obj.define('deposit', deposit_method)
	obj.call('deposit', 50)

	new_balance := obj.get[int]('balance') or { 0 } // Output: 150
}
```

### 3. Struct Translation
Convert standard V structs to dynamic `vop` objects and vice versa:

```v
import vop

struct User {
	name string
	age  int
}

fn main() {
	u := User{ name: 'Bob', age: 30 }

	// Convert Struct to Dynamic Object
	obj := vop.from_struct(u)

	// Modify a property dynamically
	obj.set('age', 31)

	// Convert back to Struct
	updated_user := vop.to_struct[User](obj)
}
```

---

## API Reference

### Types
- `Value`: A sum type representing accepted data types: `Method | Null | Object | bool | f64 | int | string`.
- `Null`: An empty struct representing a null value.
- `Method`: A struct wrapping a function pointer with the signature `fn (Object, []Value) Value`.
- `Object`: A structure that dispatches calls to its encapsulated handler.

### Module Functions
- `new_base() Object`: Instantiates a base object with an encapsulated map state.
- `new_object(props map[string]Value) Object`: Instantiates an object pre-populated with a map of properties.
- `from_struct[T](s T) Object`: Converts any compatible struct `T` into a dynamic object using comptime reflection.
- `to_struct[T](obj Object) T`: Reconstructs a static struct `T` from a dynamic object's properties.

### Object Methods
- `set[T](key string, val T) Object`: Sets a property. Returns the object for method chaining.
- `get[T](key string) !T`: Retrieves a property. Returns a Result type `!T`.
- `define(name string, method Method) Object`: Binds a dynamic method to a string identifier.
- `call(msg string, args ...Value) Value`: Sends a message to the object dispatcher.
- `call_as[T](msg string, args ...Value) !T`: Sends a message and casts the return value to a Result type `!T`.

### Value Cast Methods
- `to_str() string`: Stringifies standard `Value` types. Returns an empty string for unconvertible types.
- `to_int() int`: Safely extracts an integer, defaulting to `0` if the type mismatch occurs.
- `to_bool() bool`: Safely extracts a boolean, defaulting to `false` if the type mismatch occurs.