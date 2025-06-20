# flake.nix (Corrected version)
{
  description = "A simple V2Ray flake providing a SOCKS5/HTTP proxy for debug testing";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        v2rayPackage = pkgs.v2ray;

        proxyConfig = pkgs.writeText "v2ray-proxy-config.json" ''
          {
            "log": { "loglevel": "debug" },
            "inbounds": [
              {
                "listen": "0.0.0.0",
                "port": 8082,
                "protocol": "socks",
                "settings": { "auth": "noauth", "udp": true }
              },
              {
                "listen": "0.0.0.0",
                "port": 8081,
                "protocol": "http"
              }
            ],
            "outbounds": [ { "protocol": "freedom" } ]
          }
        '';

      in
      {
        packages.default = pkgs.writeShellScriptBin "run-v2ray-proxy" ''
          #!${pkgs.stdenv.shell}
          echo "Starting V2Ray proxy server with config: ${proxyConfig}"
          echo "SOCKS5 proxy listening on 0.0.0.0:8082"
          echo "HTTP proxy listening on 0.0.0.0:8081"
          echo "You can test with: curl --proxy socks5h://127.0.0.1:8082 https://ifconfig.me"
          ${v2rayPackage}/bin/v2ray run -config ${proxyConfig}
        '';

        apps.default = {
          type = "app";
          program = "${self.packages.${system}.default}/bin/run-v2ray-proxy";
        };

        # A development shell with v2ray, curl, and our custom script for testing
        devShells.default = pkgs.mkShell {
          name = "v2ray-proxy-shell";
          # THE FIX IS HERE: Added self.packages.${system}.default to the list
          buildInputs = [ v2rayPackage pkgs.curl self.packages.${system}.default ];
          shellHook = ''
            echo "--- V2Ray Proxy Dev Shell ---"
            echo "The 'v2ray', 'curl', and 'run-v2ray-proxy' commands are available."
            echo ""
            echo "To run the proxy server in this shell, use the command:"
            echo "  run-v2ray-proxy"
            echo ""
            echo "To test the SOCKS5 proxy (on port 8080) in another terminal:"
            echo "  curl --proxy socks5h://localhost:8080 https://ifconfig.me"
            echo ""
            echo "To test the HTTP proxy (on port 8081) in another terminal:"
            echo "  curl --proxy http://localhost:8081 https://ifconfig.me"
          '';
        };

        formatter = pkgs.nixpkgs-fmt;
      }
    );
}