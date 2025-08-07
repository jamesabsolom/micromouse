# Micromouse Maze Solver Simulator

## Overview
Micromouse is a maze solver simulator that allows users to create and solve mazes using a set of commands. The project is designed to be extensible, allowing for the addition of new commands and features over time.

It follows the Micromouse competition rules, where a robot must navigate through a maze to find a point as quickly as possible.

## Existing Commands
**PLEASE NOTE:**
*- This is a work in progress and commands may change or be added over time.*
*- This horrible readme is a temporary placeholder until a proper documentation system is in place.*

### Movement Commands
- MOVE: Moves the robot forwards by a number of steps. (defined in the globals script)
- LEFT: Turns the robot left by 1 degree.
- RIGHT: Turns the robot right by 1 degree.

### Variable Commands
- VAR *var_type* *var_name* = *value*: Defines a variable of a specified type with an initial value.
    - Variable types include:
        - INT: Integer variable.
        - FLOAT: Floating-point variable.
        - STRING: String variable.
        - Vector: A vector variable, which can hold multiple values. Defined as {VAL1, VAL2}
- SET *var_name* = *value*: Sets the value of an existing variable.
- LIST *var_type* *var_name* = [*item1*,*item2*, ...]: Defines a list variable with specified items.
- APPEND *var_name* *value*: Appends an item to an existing list variable.
- POSITION: Returns the current position of the robot as a vector. Can be used anywhere a vector is expected.
    - *Example:* WHILE NOT CENTERED POSITION: Checks if the robot is not centered on its current position.

### Loop,Repeat and For Commands
- LOOP: Starts a loop which will just repeat until broken.
- REPEAT *num*: Repeats the last command a specified number of times.
- FOR *var* IN *list_var*: Iterates over a list, setting the variable to each item in the list.

### While Commands
- WHILE *condition*: Starts a while loop that continues as long as the condition is true.
- WHILE NOT *condition*: Starts a while loop that continues as long as the condition is false.
    - Conditions can include:
        - SENSOR: Checks the value of a sensor.
        - FACING *Vector_Value*: Checks whether the robot is facing a cell
        - ON *Vector_Value*: Checks whether the robot is on a cell
        - CENTERED *Vector_Value*: Checks whether the robot is centered on a cell

### If Commands
- IF *condition*: Executes the next command if the condition is true.
- IF NOT *condition*: Executes the next command if the condition is false.
    - Conditions can include:
        - SENSOR: Checks the value of a sensor.
        - FACING *Vector_Value*: Checks whether the robot is facing a cell
        - ON *Vector_Value*: Checks whether the robot is on a cell
-ELSE: Executes the next command if the previous IF condition was false/true depending on the IF command used.

## MICROMOUSE TODO

- [ ] Re-add only highlighting no structural text
- [x] Hook up generate new maze button
- [ ] Write documentation on available commands
- [x] Hook up documentation button

- [ ] Basic commands which should definitely exist
    - [ ] Basic maths commands
        - [ ] ADD VAR1 VAR2
        - [ ] SUBTRACT VAR1 VAR2
        - [ ] MULTIPLY VAR1 VAR2
        - [ ] DIVIDE VAR1 VAR2
    - [ ] Basic comparison commands
        - [ ] IF VAR1 EQUALS VAR2 with not variant
        - [ ] IF VAR1 GREATER VAR2 with not variant
        - [ ] IF VAR1 LESS VAR2 with not variant
    - [ ] Add boolean variables
        - [ ] VAR BOOLEAN VARNAME TRUE/FALSE
        - [ ] SET VARNAME TRUE/FALSE
        - [ ] IF VARNAME TRUE/FALSE with not variant
    - [ ] Add a way to create a vector variable from two existing integer variables
        - [ ] VAR VECTOR VARNAME = {VAR1, VAR2}
        - [ ] SET VARNAME = {VAR1, VAR2}

- [ ] Progress to optimistic movement
    - [x] POSITION keyword which just returns your current position (SET VARNAME = POSITION)
    - [ ] IF VALUE IN LIST support with not variant
    - [ ] CLEAR LIST support to allow clearing of visited lists
    - [ ] Add a way to refer to a value in a list by index
        - [ ] VAR TYPE VARNAME = LIST_VAR[INDEX]
        - [ ] SET VARNAME = LIST_VAR[INDEX]
        - [ ] IF VARNAME EQUALS LIST_VAR[INDEX] with not variant

- [ ] Add function system
    - [ ] DEFINE FUNCTION keyword
    - [ ] CALL FUNCTION keyword

- [ ] Add a way to edit settings
    - [ ] Add a settings file (ini) which can be edited
    - [x] Add a settings button to the UI
    - [x] Hook up the settings button to open a menu
    
