{ lib, inputs, ... }:

let
  inherit (builtins) attrNames;
  inherit (lib) functionArgs;
  inherit (inputs) self;
  inherit (self.lib) callWith mkVersion;
in
{
  callWith-fill-missing =
    let
      f =
        {
          a,
          b,
          c ? 0,
        }:
        {
          inherit a b c;
        };
    in
    [
      (callWith { b = 1; } f)
      (g: [
        (g { a = 1; })
        (functionArgs g)
      ])
      [
        {
          a = 1;
          b = 1;
          c = 0;
        }
        {
          a = false;
          b = true;
          c = true;
        }
      ]
    ];

  callWith-no-args = [
    (args: args)
    (callWith {
      a = 2;
      b = 1;
    })
    (f: [
      (f {
        a = 1;
        a1 = 1;
      })
      (functionArgs f)
    ])
    [
      {
        a = 1;
        a1 = 1;
        b = 1;
      }
      { }
    ]
  ];

  callWith-chain = [
    (
      {
        a,
        b,
        c,
        ...
      }@args:
      [
        (attrNames args)
        { inherit a b c; }
      ]
    )
    (callWith {
      a = 2;
      b = 1;
      b1 = 1;
      c = 2;
    })
    (callWith {
      a = 3;
      c = 1;
      c1 = 1;
    })
    (f: [
      (f {
        a = 1;
        a1 = 1;
      })
      (functionArgs f)
    ])
    [
      [
        [
          "a"
          "a1"
          "b"
          "c"
        ]
        {
          a = 1;
          b = 1;
          c = 1;
        }
      ]
      {
        a = true;
        b = true;
        c = true;
      }
    ]
  ];

  mkVersion-null = [
    (mkVersion null)
    "0.0.0+date=19700101_dirty"
  ];

  mkVersion-self = [
    (mkVersion self)
    (mkVersion {
      inherit (self) lastModifiedDate;
      shortRev = self.shortRev or "dirty";
    })
  ];
}
