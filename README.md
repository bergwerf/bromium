![Banner](banner.png)

Bromium
=======
Engine for simulating reactions using Brownian motion.

Sub-libraries
-------------
Bromium consists of the following set of smaller libraries:

- `bromium.math` Collection of general mathematical algorithms
- `bromium.views` Additional typed views
- `bromium.structs` Data structures for the simulation
- `bromium.kinetics` Simulation kinetics algorithms
- `bromium.nodes` Library for node based scene modeling
- `bromium.engine` Controller for an isolated simulation with nodes
- `bromium.gpgpu` Helpers for GPU computations using WebGL
- `bromium.glutils` WebGL utility library
- `bromium.renderer` Simulation 3D renderer
- `bromium.editor` Scene editor for Bromium

Conventions
-----------
### Types
In almost all circumstances it is preferred to use types from the `vector_math`
library to keep the code more readable. Array to vector conversion should be
minimized.

### Loops
Prefer `for-in` loops over `forEach` loops. Always use `for-in` when possible.

### Comments
Meaningless comments such as `/// Constructor` or copied comments from the
super class should be omitted.
