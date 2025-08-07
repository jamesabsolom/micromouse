# Getting Started

1. Open the editor panel.  
2. Write your first script:

```micromouse
LOOP
    MOVE
```

3. Press **Run** to see the mouse wander indefinitely.  
4. Try adding `IF SENSOR FRONT PROX` to stop the mouse when it detects an obstacle:

```micromouse
LOOP
    IF SENSOR FRONT PROX
        BREAK
    MOVE
```
