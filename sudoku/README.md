# Sudoku for TIC-80

Here's the development plan:
- [x] *REV1*: Print the 9x9 grid, make it real nice looking.
- [x] *REV2*: Focus on the user interface: how the user interacts with the biz.
- [x] *REV3*: Work on the sudoku puzzle generation algorithm.
- [x] *REV4*: Create title, options (including difficulty), stats, and puzzle screens. Add "Undo"/"New Game"/"Exit" buttons to game screen.
    - [x] Add a new STATE.REFRESH_PUZZLE state that only flips straight back to STATE.PUZZLE.
    - [x] "Exit" button transitions to STATE.TITLE.
    - [x] Add a new STATE.SUCCESS state that activates when the "Check" button is clicked and everything is correct.
- [x] *REV5*: Implement extra features:
    - [x] Add a timing clock that starts with the first click and stops the moment the puzzle is solved.
    - [x] Under timing clock, display number of times auto-note button has been clicked.
    - [x] Allow the user to undo the last move.
    - [ ] Implement game play history using date, difficulty, num autoclicks, and time.
- [ ] *FINAL*: Pull it all together.
    - [ ] Add instructions screen/state from main screen.
    - [ ] Make src.states.title.drawTitle() draw a big-ass graphic.
    - [ ] Make all screens accept mouse input.


Links:
- [Solving Any Sudoku Puzzle](https://github.com/norvig/pytudes/blob/main/ipynb/Sudoku.ipynb?short_path=42d38da)
- [Sudoku Creation and Grading](https://www.sudokuwiki.org/Sudoku_Creation_and_Grading.pdf)