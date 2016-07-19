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
### Sanity checks
It is discouraged to add sanity checks to data structures (for example to detect
impossible reactions). This makes the code more complex and less readable.
Instead the code should be more resilient towards incorrect data. 

### Types
In almost all circumstances it is preferred to use types from the `vector_math`
library to keep the code more readable. Array to vector conversion should be
minimized.

### Loops
Prefer `for-in` loops over `forEach` loops. Always use `for-in` when possible.

### Comments
Meaningless comments such as `/// Constructor` or copied comments from the
super class should be omitted.

### Error messages
Error messages should be full sentences.

Topics for further research
---------------------------
### Optimization of reaction finding
Currently a voxel based approach is used where all inter-voxel reactions are
implicitly discarded. Alternative approaches have shown significant lower
performance. More performance might be gained by caching results from previous
cycles. A very interesting question is how much the voxel approach hurts the
accuracy of the entire simulation.

### Accuracy of brownian motion
Currently a not too accurate approach is used to compute the random motion. Each
cycle the particle is displaced by a normalized vector that points in a random
direction times a random number between 0 and 1.
