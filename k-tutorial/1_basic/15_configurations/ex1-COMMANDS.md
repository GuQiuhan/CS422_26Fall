# Exercise 1: testing the divInt flag

```
kompile lesson-15-ex1-divflag.k
krun ex1-div.exp -cDIVINT="false"   # /Int (truncating): -7 / 3 => -2
krun ex1-div.exp -cDIVINT="true"    # divInt (Euclidean): -7 / 3 => -3
```
