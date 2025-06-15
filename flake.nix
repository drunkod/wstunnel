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
          # A wrapper script to run the server with a default configuration.
          wstunnel-server = pkgs.writeShellScriptBin "run-wstunnel-server" ''
            #!${pkgs.stdenv.shell}
            echo "Starting wstunnel server on wss://0.0.0.0:8080..."
            echo "This uses a self-signed certificate by default."
            echo "Clients should connect to this machine's public IP on port 8080."
            ${wstunnelPackage}/bin/wstunnel server wss://0.0.0.0:8080
          '';

          # A wrapper script to run the client in SOCKS5 mode.
          # It requires the server URL as a command-line argument.
          wstunnel-client = pkgs.writeShellScriptBin "run-wstunnel-client" ''
            #!${pkgs.stdenv.shell}
            if [ -z "$1" ]; then
              echo "Error: Server URL is required." >&2
              echo "Usage: $0 wss://<server_ip_or_domain>:8080" >&2
              exit 1
            fi
            
            SERVER_URL="$1"
            SOCKS_ADDR="127.0.0.1:10808"

            echo "Starting wstunnel client..."
            echo "Connecting to server at: $SERVER_URL"
            echo "SOCKS5 proxy will be available on $SOCKS_ADDR"
            # Note: By default, this does not verify the server's TLS certificate,
            # which is necessary to connect to the default server's self-signed cert.
            ${wstunnelPackage}/bin/wstunnel client -L "socks5://$SOCKS_ADDR" "$SERVER_URL"
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
            echo "  nix run .#server"
            echo "  nix run .#client -- wss://<server_ip>:8080"
            echo "------------------------------------"
          '';
        };

        formatter = pkgs.nixpkgs-fmt;
      }
    );
}