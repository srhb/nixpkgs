import ./make-test.nix ({ pkgs, ...} : {
  name = "cfssl";

  machine = { config, lib, pkgs, ... }:
    {
      services.cfssl.enable = true;
      services.certmgr.enable = true;
    };

  testScript =
    ''
      $machine->waitForUnit('cfssl');
    '';
})
