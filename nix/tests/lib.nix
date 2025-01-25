{ inputs, ... }:

let
  inherit (inputs) self;
  inherit (self.lib) mkVersion;
in
{
  mkVersion = [
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
