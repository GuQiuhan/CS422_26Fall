// Exercise (Associativity): change `&&` to right-associative so that
// `true && false && false` parses as `true && (false && false)`
// (Fig. 4-B), i.e. the leftmost `&&` ends up at the top of the AST.
module LESSON-04-B-ALT

  syntax Boolean ::= "true" | "false"
                   | "(" Boolean ")" [bracket]
                   > "!" Boolean [function]
                   > right: Boolean "&&" Boolean [function]
                   > left: Boolean "^" Boolean [function]
                   > left: Boolean "||" Boolean [function]

endmodule
