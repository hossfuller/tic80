# Sudoku for TIC-80

Here's the development plan:
- *REV1*: Print the 9x9 grid, make it real nice looking.
- *REV2*: Focus on the user interface: how the user interacts with the biz.
- *REV3*: Work on the sudoku puzzle generation algorithm.
- *REV4*: Create title, options (including difficulty), stats, and puzzle screens. Add "Undo"/"New Game"/"Exit" buttons to game screen.
    - Add a new STATE.REFRESH_PUZZLE state that only flips straight back to STATE.PUZZLE.
    - "Exit" button transitions to STATE.TITLE.
    - Add a new STATE.SUCCESS state that activates when the "Check" button is clicked and everything is correct.
- *REV5*: Implement extra features:
    - Add a timing clock that starts with the first click and stops the moment the puzzle is solved.
    - Add game play history (showing date, difficulty, and time).
    - Allow the user to undo the last move.
- *FINAL*: Pull it all together.
    - Add instructions screen/state from main screen.
    - Make src.states.title.drawTitle() draw a big-ass graphic.
    - Make all screens accept mouse input.


Links:
- [Solving Any Sudoku Puzzle](https://github.com/norvig/pytudes/blob/main/ipynb/Sudoku.ipynb?short_path=42d38da)
- [Sudoku Creation and Grading](https://www.sudokuwiki.org/Sudoku_Creation_and_Grading.pdf)