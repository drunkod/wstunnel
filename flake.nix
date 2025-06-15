# flake.nix
{
  description = "A wstunnel server and client flake for simple testing";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        wstunnelPackage = pkgs.wstunnel;

      in
      {
        packages = {
          # CORRECTED: This script now accepts additional arguments (like --restrict-...)
          # by using "$@" to pass them to the wstunnel command.
          wstunnel-server = pkgs.writeShellScriptBin "run-wstunnel-server" ''
            #!${pkgs.stdenv.shell}
            echo "Starting wstunnel server..."
            echo "Passing arguments to wstunnel: $@"
            # The "$@" allows passing all command line arguments to the program
            ${wstunnelPackage}/bin/wstunnel server "$@"
          '';

          # CORRECTED: This script was simplified to correctly handle all arguments.
          # It no longer checks for $1, but instead passes everything through.
          wstunnel-client = pkgs.writeShellScriptBin "run-wstunnel-client" ''
            #!${pkgs.stdenv.shell}
            SOCKS_ADDR="127.0.0.1:10808"

            echo "Starting wstunnel client..."
            echo "SOCKS5 proxy will be available on $SOCKS_ADDR"
            echo "Passing arguments to wstunnel: $@"

            # This automatically adds the SOCKS5 listener and then appends
            # all your other arguments (like the server URL and path prefix).
            ${wstunnelPackage}/bin/wstunnel client -L "socks5://$SOCKS_ADDR" "$@"
          '';

          # Expose the core wstunnel package directly.
          wstunnel = wstunnelPackage;
        };

        apps = {
          server = {
            type = "app";
            program = "${self.packages.${system}.wstunnel-server}/bin/run-wstunnel-server";
          };
          client = {
            type = "app";
            program = "${self.packages.${system}.wstunnel-client}/bin/run-wstunnel-client";
          };
        };

        # The server is the default app to run.
        defaultApp = self.apps.${system}.server;

        # A development shell with wstunnel and testing tools.
        devShells.default = pkgs.mkShell {
          name = "wstunnel-dev-shell";
          buildInputs = [
            wstunnelPackage
            pkgs.curl # For testing the proxy
          ];
          shellHook = ''
            echo "--- Wstunnel Development Shell ---"
            echo "The 'wstunnel' and 'curl' commands are available."
            echo ""
            echo "To run a server (listens on port 8080):"
            echo "  wstunnel server wss://0.0.0.0:8080"
            echo ""
            echo "To run a client (creates a SOCKS5 proxy on 10808):"
            echo "  wstunnel client -L socks5://127.0.0.1:10808 wss://<server_ip>:8080"
            echo ""
            echo "To test the SOCKS5 proxy with curl:"
            echo "  curl -x socks5h://127.0.0.1:10808 https://ifconfig.me"
            echo ""
            echo "You can also use the flake's apps:"
            echo "  nix run .#server -- wss://0.0.0.0:8080"
            echo "  nix run .#client -- wss://<server_ip>:8080"
            echo "------------------------------------"
          '';
        };

        formatter = pkgs.nixpkgs-fmt;
      }
    );
}