{
  lib,
  emacs,
  emacsPackagesFor,
  extraPackages ? epkgs: [ epkgs.make-emacs-awesome ],
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
