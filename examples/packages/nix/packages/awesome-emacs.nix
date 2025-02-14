{
  lib,
  emacs,
  emacsPackagesFor,
  extraPackages ?
    epkgs: with epkgs; [
      greet
      hei
      hi
    ],
  ...
}:

lib.pipe emacs [
  (
    x:
    x.overrideAttrs (_: {
      pname = "awesome-emacs";
    })
  )
  emacsPackagesFor
  (x: x.withPackages extraPackages)
]
