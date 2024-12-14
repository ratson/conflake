{ lib, ... }:

{
  test-simple = [
    (lib.singleton { a = 1; })
    [
      {
        a = 1;
      }
    ]
  ];

  test-chained = [
    (lib.singleton { a = 1; })
    builtins.head
    (x: x.a)
    1
  ];
}
