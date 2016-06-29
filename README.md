Bromium
=======
Engine for simulating reactions using Brownian motion.

Sub-libraries
-------------
Bromium consists of the following set of smaller libraries:

- `bromium.math` Collection of general mathematical algorithms.
- `bromium.core.types` Data structures for simulation objects.
- `bromium.core.buffer` ByteBuffer backed storage for raw simulation data.
- `bromium.core.kinetics` Simulation kinetics algorithms.
- `bromium.nodes` Library for node based scene modeling.
- `bromium.engine` Controller for an isolated simulation with nodes.

Conventions
-----------
### Variable names
There are a number of variable naming conventions to keep the code more
consistent.

Name   | Meaning
-------|---------
`dims` | domain dimensions
`p`    | particle index
`p*`   | array with particle information
`m`    | membrane index
`m*`   | array with membrane information
`r`    | reaction index
`r*`   | array with reaction information
`n`    | node index
`n*`   | array with node information
`i`    | ALL other index values

### Types
In almost all circumstances it is preferred to use types from the `vector_math`
library to keep the code more readable. Array to vector conversion should be
minimized.

### Loops
Prefer `for-in` loops over `forEach` loops. Always use `for-in` when possible.

### Comments
Meaningless comments such as `/// Constructor` or copied comments from the
super class should be omitted.
