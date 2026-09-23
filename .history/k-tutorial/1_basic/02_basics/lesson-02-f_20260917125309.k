module LESSON-02-F


  syntax Color ::= Black() | White()
  syntax Hat ::= hat(Color)
  syntax Shirt ::= shirt(Color)
  syntax Pants ::= pants(Color)
  syntax Shoes ::= shoes(Color)
  syntax Outfit ::= outfit(Hat, Shirt, Pants, Shoes)
  syntax Boolean ::= true() | false()

  syntax Boolean ::= outfitMatching(Outfit) [function]

  rule outfitMatching(outfit(hat(C), shirt(C), pants(C), shoes(C))) => true()

endmodule
