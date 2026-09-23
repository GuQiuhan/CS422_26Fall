module LESSON-04-B-ALT

  syntax Boolean ::= "true" | "false"
                   | "(" Boolean ")" [bracket]
                   > "!" Boolean [function]
                   > right: Boolean "&&" Boolean [function]
                   > left: Boolean "^" Boolean [function]
                   > left: Boolean "||" Boolean [function]

endmodule
