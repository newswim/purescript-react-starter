let
  pkgs = import (builtins.fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/20.09.tar.gz";
  }) {};

  # To update to a newer version of easy-purescript-nix, run:
  # nix-prefetch-git https://github.com/ptrfrncsmrph/easy-purescript-nix
  #
  # Then, copy the resulting rev and sha256 here.
  # Last update: 2020-12-27
  pursPkgs = import (pkgs.fetchFromGitHub {
    owner = "ptrfrncsmrph";
    repo = "easy-purescript-nix";
    rev = "d53b10391c3ec289f8afdc664f743824115bbe70";
    sha256 = "0rmm141dhy8aivs066dq998g69h4y5amxsixbzd3nc5ngfzk3y26";
  }) { inherit pkgs; };

in pkgs.stdenv.mkDerivation {
  name = "sandbox";
  buildInputs = with pursPkgs; [
    # pursPkgs.purs-0_14_0-rc5
    pursPkgs.purs
    pursPkgs.purty
    pursPkgs.spago
    # pursPkgs.zephyr
    pkgs.nodejs-14_x
  ];
}
