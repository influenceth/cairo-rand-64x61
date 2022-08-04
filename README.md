[![PyPI version](https://badge.fury.io/py/cairo_rand_64x61.svg)](https://badge.fury.io/py/cairo_rand_64x61)

# Cairo Rand 64x61

A psuedrandom and procedural generation library using 64.61 fixed point math for Cairo

## Usage ##
Install with `pip install cairo_rand_64x61` and import and use with `from cairo_rand_64x61.simplex import Simplex`.

## Signed 64.61 Fixed Point Numbers ##
This library is heavily dependend on 64.61 bit fixed point numbers. See https://github.com/influenceth/cairo-math-64x61 for more information.

## Simplex Library ##
`Simplex` includes an implementation of a three-dimensional simplex noise based on the GLSL implementation found here: https://github.com/ashima/webgl-noise/blob/master/src/noise3D.glsl. It is tested against output of the GLSL library. Keep in mind that in many cases the GLSL implementation will be run on GPUs using medium precision which will lead to errors with large input values for `x, y, z`. This cairo library does *NOT* attempt to mimic this error (this error will also disappear if using high precision on GPU).

## Extensibility ##
This library strives to adhere to the OpenZeppelin extensibility pattern: https://docs.openzeppelin.com/contracts-cairo/0.2.1/extensibility#libraries
