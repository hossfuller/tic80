# Space Explorer

Travel the universe, doing space things at various space destinations.

## Features/Ideas

Space exploration ship that travels to different space destinations like planets, moons, asteroids, and space stations. The ship also has to dodge comets, other ships, and other smaller space junk.

The ship will have energy, health, and shield bars. Shields take the damage and regenerate. If there are no shields, then the health takes the hit -- until the shields regenerate. Energy allows for firing the thrusters and regenerates at a speed dictated by the user's distance from the main star.


## Development Plan

#### Needed skills to develop

- [ ] Vector spaceships with energy, health, and shields.
- [ ] Camera that follows the spaceship across entire game map.
- [ ] A main star, planets, and other space stuff with gravity that affects the spaceship.
- [ ] Randomized map upon game start that stays the same throughout the game.

#### Development Plan

The different revisions implement separate features. This list is ever changing.

- [ ] **REV0.1**: Movement around the entire TIC-80 map.
    - [ ] Camera stays centered on object.
    - [ ] Debug screen that displays user's map location.
    - [ ] Backdrop of stationary random stars, black holes, and distant galaxies.
- [ ] **REV0.2**: Add foreground heavenly bodies.
    - [ ] Parent class for all heavenly bodies with mass, radius, color.
    - [ ] Implement keplarian orbital mechanics which is really
    - [ ] Add mouse controls that allow us to zoom in and out of map.
- [ ] **REV0.3**: Refined heavenly bodies.
    - [ ] Randomly generated names, colors, atmospherics for planets and moons.
    - [ ] AAU-style names for anything smaller than a moon.
- [ ] **REV0.4**: Spaceships, modeled on the Asteroids work.
    - [ ] Different space ship designs for different purposes.
    - [ ] Spaceships have attributes like mass, engine power, etc that affect things like movement and shield regeneration.
    - [ ] Ships have maximum values for things like mass, etc.
    - [ ] Collision detection.
    - [ ] Energy for movement, health and shields for life.
    - [ ] Bring over Asteroids particle effects like explosions, thrust, sparks, and smoke.
    - [ ] Can feel gravitational effects from heavenly bodies.
- [ ] **REV0.5**: Space docking, cargo, and passengers
    - [ ] Space stations and ships should have a way to connect to each other to exchange passengers, cargo, or energy/health.
    - [ ] Colors, effects, and sounds indicate successful docking.
    - [ ] Implement cargo holds and passenger seating in spaceships.
- [ ] **REV0.6**: Spaceship upgrades
    - [ ] Certain places will provide ways to auto-refill energy, health, and shields.
    - [ ] Energy, health, and shields can also be upgraded to higher max values.
    - [ ] Cargo space and passenger seating can also be increased.
- [ ] **REV0.7**: Game objectives
- [ ] **REV0.8**: tbd
- [ ] **REV0.9**: tbd
- [ ] **REV1.0**: tbd
- [ ] **REV1.1**: tbd


## Links

- [KOMET](https://tic80.com/play?cart=610)
- [PSLIB](https://tic80.com/play?cart=85)
- [Orbit Simulator 0.1](https://tic80.com/play?cart=1025)
- [Super Space Smugglers](https://dzejkop.itch.io/super-space-smugglers)
- [Nerd Talk - Orbital Mechanics (part 1)](https://dzejkop.itch.io/super-space-smugglers/devlog/649707/nerd-talk-orbital-mechanics-part-1)
- [TIC-80 Visual Tutorial - 1](https://tic80.com/play?cart=2245)
- [TIC-80 Visual Tutorial - 2](https://tic80.com/play?cart=2246)
- [TIC-80 Visual Tutorial - 3](https://tic80.com/play?cart=2311)
- [Heliocentrism vs Geocentrism](https://tic80.com/play?cart=4527)
