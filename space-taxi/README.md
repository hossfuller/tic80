# Space Taxi

Travel the universe, delivering space passengers to their space destinations.

## Features/Ideas

Space taxi ship that travels to different planets to pick up passengers and cargo.

- Arrow keys point the ship in any direction.
- Buttons control thrust, one for forward and one for backward.

User will get sound and graphic notifications whenever there's a new task. An arrow on the screen will direct the user to proper location. If they have multiple objectives at once, everything will be color coded. The user then has to travel across the map to the destination and dock the ship to unload passenger or cargo. Docks change color and lock the user in when they've properly docked.

As the user travels around space, they have to dodge stars, planets, moons, smaller space junk, and other ships. Should they have extra lives or an energy bar in case of collision?

Completion of the objective results in the score increasing.


## Development Plan

#### Needed skills to develop

- [ ] Vector spaceships.
- [ ] Camera that follows the spaceship.
- [ ] Planets and other space stuff with gravity that affects the spaceship.
- [ ] Randomized map upon game start that stays the same throughout the game.

#### Development Plan

- [ ] **0.1**: Create vector spaceship objects.
    - [ ] Add a ship designer interface.
        - [ ] Save first 10 slots/chunks for high scores.
        - [ ] After that, chunk mapping is first slot stores num of total slots for ship, and remaining slots contain x/y coords.
        - [ ] Add menu option for ship designer
        - [ ] Need interface to select color, add/remove line endpoints.
        - [ ] Note that default ship requires 10 coord slots, so 11 slots total.
        - [ ] Need to put a limit on number of slots per spaceship.
- [ ] **0.2**: Space travel
    - [ ] Some sort of background so we can verify we're moving.
    - [ ] Camera follows spaceship across space.
    - [ ] Initial objects and collision detection.
- [ ] **0.3**: Solar Systems
    - [ ] Objects for space stuff: stars, planets, and other objects.
    - [ ] Everything has gravity.
    - [ ] Randomized placement that persists for the duration of the game.
- [ ] **0.4**: Space docks
    - [ ] Create space docks that know when a user is docked.
- [ ] **0.5**: Passenger seating and cargo.
- [ ] **0.6**: Game objectives.


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
