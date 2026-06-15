{
  description = "Digilent m-air-edit";

  outputs =
    { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" ];
      names = [
        "m-air-edit"
      ];

      toFlakePackage = system: name: {
        inherit name;
        value =
          (import nixpkgs {
            inherit system;
            config.allowUnfree = true;
            overlays = [ self.overlay ];
          })."${name}";
      };

      inherit (builtins) map listToAttrs;

      eachSystem =
        f:
        listToAttrs (
          map (system: {
            name = system;
            value = f system;
          }) systems
        );

      packages = eachSystem (
        system:
        let
          all = listToAttrs (map (toFlakePackage system) names);
        in
        all // { default = all.m-air-edit; }
      );

      overlay =
        final: prev:
        listToAttrs (
          map (name: {
            inherit name;
            value = final.callPackage (./pkgs + "/${name}") { };
          }) names
        );

      apps = eachSystem (system: rec {
        m-air-edit = {
          type = "app";
          program = "${packages.${system}.m-air-edit}/bin/m-air-edit";
        };
        default = m-air-edit;
      });

      defaultPackage = eachSystem (system: packages.${system}.default);

      defaultApp = eachSystem (system: apps.${system}.default);

      nixosModule = { pkgs, ... }: {
        nixpkgs.overlays = [ self.overlay ];
        environment.systemPackages = [ pkgs.m-air-edit ];
        users.groups.plugdev = { };
      };

      devShells = eachSystem (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
        in
        {
          default = pkgs.mkShell {
            packages = [
              (pkgs.python3.withPackages (py: [
                py.python-lsp-server
                py.requests
                py.beautifulsoup4
                py.black
              ]))
            ];
          };
        }
      );

    in
    {
      inherit
        packages
        overlay
        defaultPackage
        apps
        defaultApp
        nixosModule
        ;

      overlays.default = overlay;

      nixosModules.default = nixosModule;

      devShells = devShells;
    };
}
