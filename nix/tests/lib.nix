{ inputs, ... }:

let
  inherit (inputs) self;
in
{
  mkVersion = [
    (self.lib.mkVersion null)
    "0.0.0+date=19700101_dirty"
  ];

  mkVersion-self = [
    (self.lib.mkVersion self)
    (self.lib.mkVersion {
      inherit (self) lastModifiedDate;
      shortRev = self.shortRev or "dirty";
    })
  ];
}
