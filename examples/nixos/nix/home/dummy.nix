{
  system = "x86_64-linux";

  modules = [
    {
      home.homeDirectory = "/tmp";

      home.stateVersion = "24.11";
    }
  ];
}
