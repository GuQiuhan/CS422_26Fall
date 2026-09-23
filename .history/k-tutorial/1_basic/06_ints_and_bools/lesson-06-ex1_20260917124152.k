// Exercise (first, under "Booleans in K"): isBlueAndNotYellow
module LESSON-06-EX1
  imports BOOL

  syntax Fruit ::= Blueberry() | Banana() | Kiwi()
  syntax Bool ::= isBlue(Fruit) [function]
                | isYellow(Fruit) [function]
                | isBlueAndNotYellow(Fruit) [function]

  rule isBlue(Blueberry()) => true
  rule isBlue(Banana()) => false
  rule isBlue(Kiwi()) => true

  rule isYellow(Banana()) => true
  rule isYellow(Blueberry()) => false
  rule isYellow(Kiwi()) => true

  rule isBlueAndNotYellow(F) => isBlue(F) andBool notBool isYellow(F)
endmodule
