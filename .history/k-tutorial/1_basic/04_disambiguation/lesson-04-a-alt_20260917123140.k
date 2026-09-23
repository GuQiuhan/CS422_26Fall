// Exercise (Priority blocks): swap the priority of `&&` and `||` so that
// `true && false || false` now parses with `&&` as the top-level symbol,
// i.e. `true && (false || false)`.
module LESSON-04-A-ALT

  syntax Boolean ::= "true" | "false"
                   | "(" Boolean ")" [bracket]
                   > "!" Boolean [function]
                   > Boolean "||" Boolean [function]
                   > Boolean "^" Boolean [function]
                   > Boolean "&&" Boolean [function]

endmodule
