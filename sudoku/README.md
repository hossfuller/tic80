# Sudoku for TIC-80

Here's the development plan:
- *REV1*: Print the 9x9 grid, make it real nice looking.
- *REV2*: Focus on the user interface: how the user interacts with the biz.
- *REV3*: Work on the sudoku puzzle generation algorithm.
- *REV4*: Create title, options (including difficulty), stats, and puzzle screens. Add "Undo"/"New Game"/"Exit" buttons to game screen.
- *REV5*: Implement an Undo feature. Allow user to specify difficulty (determines how many cells are revealed and grades the puzzle). Add stat tracking. Add timing.
- *FINAL*: Pull it all together.
    - Make src.states.title.drawTitle() draw a big-ass graphic.
    - Make all screens accept mouse input.


Links:
- [Solving Any Sudoku Puzzle](https://github.com/norvig/pytudes/blob/main/ipynb/Sudoku.ipynb?short_path=42d38da)
- [Sudoku Creation and Grading](https://www.sudokuwiki.org/Sudoku_Creation_and_Grading.pdf)