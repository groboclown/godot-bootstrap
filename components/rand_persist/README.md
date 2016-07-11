# Project Component: `rand_persist`

A reimplementation of the standard `@GDScript` random functions that also
use and persist the random seed.  This allows a per-object or per-save random
seed (to reduce an incentive for save scumming from the user).

It also allows for better implementations of "same seed == same game" persisted
across saves.

**Category**: lib

## Usage

There are two flavors of usage: as straight up functions, or as a class.

### Procedural

```
var rand_persist = load("bootstrap/lib/rand_persist.gd");
```

All of the functions take a `storage, key` pair.  The "storage" value is a
dictionary, and "key" is the key in the dictionary that stores the seed value.
If the seed value is not set in the dictionary, a new one will be created.

#### func `rand_int(storage, key)`

Returns a pseudo-random 32-bit integer value.

#### func `rand_int_range(from, to, storage, key)`

Returns a pseudo-random integer value with a value in the range `[ from, to )`.

#### func `rand_float(storage, key)`

Returns a pseudo-random float in the range `[ 0, 1 ]`.

#### func `rand_float_range(from, to, storage, key)`

Returns a pseudo-random floag in the range `[ from, to )`.


### Class

Persists the random seed in the class.

```
var rand_persist = load("bootstrap/lib/rand_persist_class.gd");
var obj = rand_persist.new();
```

#### constructor `(seed = null)`

Can optionally pass in the seed value to use for the object.

#### var `seed`

Allows for setting or retrieving the random seed of the object.

#### func `rand_int()`

Returns a pseudo-random 32-bit integer value.

#### func `rand_int_range(from, to)`

Returns a pseudo-random integer value with a value in the range `[ from, to )`.

#### func `rand_float()`

Returns a pseudo-random float in the range `[ 0, 1 ]`.

#### func `rand_float_range(from, to)`

Returns a pseudo-random floag in the range `[ from, to )`.
