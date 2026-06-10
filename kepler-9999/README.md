# Kepler-9999

Travel the fictional Kepler-9999 system, doing space things at various space destinations.

## Features/Ideas

Space exploration ship that travels to different space destinations like planets, moons, asteroids, and space stations. The ship also has to dodge comets, other ships, and other smaller space junk.

The ship will have energy, health, and shield bars. Shields take the damage and regenerate. If there are no shields, then the health takes the hit -- until the shields regenerate. Energy allows for firing the thrusters and regenerates at a speed dictated by the user's distance from the main star.


## Development Plan

#### Needed skills to develop

- [x] Vector spaceships with energy, health, and shields.
- [x] Camera that follows the spaceship across entire game map.
- [x] Randomized map upon game start that stays the same throughout the game.
- [ ] A main star, planets, and other space stuff with gravity that affects the spaceship.

#### Development Plan

The different revisions implement separate features. This list is ever changing.

- [x] **REV0.1**: Movement around the entire TIC-80 map.
    - [x] Camera stays centered on object.
    - [x] Debug screen that displays user's map location.
    - [x] Backdrop of stationary random stars, black holes, and distant galaxies.
- [x] **REV0.2**: Spaceships, modeled on the Asteroids work.
    - [x] Spaceships have attributes like mass, engine power, etc that affect things like movement and shield regeneration.
    - [x] Energy for movement, health and shields for life.
    - [x] Implement the player's HUD screen.
- [x] **REV0.3**: User can select the ship type they want.
    - [x] Different types of spaceships with max_speed/holds being inversely proportional: freight (solid/liquid?), passengers, smugglers
    - [x] User selects their ship type from the options screen.
    - [x] Ship selection dictates ships' maximum values for mass, speed, etc.
    - [x] Implement cargo holds and passenger seating in spaceships. Solid cargo
    - [x] Different ships have different shapes.
    - [x] Fix controls for start, options, and play screen.
- [x] **REV0.4**: Add foreground heavenly bodies.
    - [x] Parent class for all heavenly bodies with mass, radius, color.
    - [x] Particle effects for stars: stellar wind and flares.
    - [x] Add mouse controls that allow us to zoom in and out of map.
- [x] **REV0.5**: Add more heavenly bodies.
    - [x] Update HUD with dynamic Speed indicator.
    - [x] Add a planet class, and include rings and atmospheres.
    - [x] Add a moon class that is attached to a particular planet.
    - [x] Add other minor body classes.
    - [x] Randomly generated names, colors, atmospherics for planets and moons (AAU-style names for anything smaller than a moon).
    - [x] Particle effects for planets: clouds and/or bands that appear to orbit the planet.
- [x] **REV0.6**: Collision detection and particle effects!
    - [x] Collision detection.
    - [x] Figure out how heavy everything should hit the ship.
    - [x] Work out mechanics of the ships shields/energy/life when collisions happen.
    - [x] Rebalance `SpaceShip` engine levels for all the different ships.
    - [x] Particle effects from stars can damage the ship.
    - [x] Bring over Asteroids particle effects like explosions, thrust, sparks, and smoke.
- [x] **REV0.7**: Put the heavens in motion.
    - [x] Gravity!
    - [x] Implement inertia and make the energy engine feel it (more mass makes the ship expend more energy to stop).
- [x] **REV0.8**: Mining
    - [x] Add a harpoon to the spaceship that can be fired at moons and smaller objects with the `BTN_P1_A` button.
    - [x] Harpoon locks the ship in place with the harpooned object so that the ship is attached to the object.
    - [x] When attached, pressing `BTN_P1_A` disengages the harpoon.
    - [x] Colliding with the harpooned object doesn't damage the ship.
    - [x] While attached to the object, holding `BTN_P1_B` extracts mass from the object. This mass goes into any available space in the cargo hold.
    - [x] Moons need to implode if they've been mined clean. Since this is the only way to kill moons, do it in `Moon::explosionEffect()`
    - [x] Update the `STATE.READY` and `STATE.PAUSE` screens to display controls instructions.
- [x] **REV0.9**: The Space Station and various colony space docks
    - [x] There is a single space station in the game that orbits the sun like a planet.
    - [x] All other planets have space docks.
    - [x] Space docks and station have an ore hold that the spaceship can deposit into.
    - [x] Docks attached to space station automatically transfer their ore to the main station bank.
    - [x] If the dock is destroyed, that ore is lost.
    - [x] When docked, a spaceship's attributes are refilled. The current ore bank is displayed in the upper-left corner of the screen.
    - [x] Colors, effects, and sounds indicate successful docking.
    - [x] The spaceship can deposit the mined mass in the game bank.
    - [x] Harpooning the space station puts the game into the `STATE.SHOP` state.
    - [x] Mined mass can be traded for upgrades to the engines or to refill the engines.
- [x] **REV1.0**: High scores and refinements.
    - [x] Refine SpaceStation and SpaceDock look. It's currently a bit much.
    - [x] A player's score is the amount of mass they deliver (mass of ore, cargo, contraband, and passengers)
    - [x] Track date, mass delivered, and engine levels.
- [ ] **REV1.1**: Missions
    - [x] While docked at the space station or any of the planets' space docks, pick up cargo/passengers/contraband for delivery.
    - [x] Use the `pickup`/`deliver` functions to meddle with the ship's mass.
    - [x] Mission type: deliver cargo
    - [x] Mission type: carry passengers to different destinations
    - [ ] Mission type: mining contracts
- [ ] **REV1.2**: NPC Ships
    - [ ] A freighter travels from dock to dock collecting ore deposits and transferring them to the space station.
    - [ ] The freighter can be lost, and if so, that ore is gone but also a new freighter spawns somewhere else.
    - [ ] A passenger ship travels from dock to dock delivering passengers.
    - [ ] A smuggler ship that doles out smuggling contracts.
    - [ ] Mission type: deliver contraband (to/from a specific NPC smuggler ship?)
- [ ] **REV1.3**: Sound effects and music
    - [ ] Sound effects for everything.
- [ ] **REV1.4**: tbd
- [ ] **REV1.5**: tbd


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
