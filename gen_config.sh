#!/bin/sh

set -e

# $1 = name of opam package
# $2, ... = packages

opam_package="$1"
shift 1

# bash in nix in bash
cat > default.nix <<EOFO
{ pkgs ? import <nixpkgs> {} }:

with pkgs;
let
  packages = [ $(printf "%s " "$@")];
  inputs = with buildPackages; packages ++ [ pkg-config ];
in
stdenv.mkDerivation {
  name = "opam-nix-env";
  nativeBuildInputs = inputs;

  phases = [ "buildPhase" ];

  buildPhase = ''
	cat > \$out <<EOF
opam-version: "2.0"
variables {
  NIX_CC: "\$NIX_CC"
  NIX_CC_FLAGS: "\$NIX_CC_FLAGS"
  NIX_CFLAGS_COMPILE: "\$NIX_CFLAGS_COMPILE"
  NIX_CC_WRAPPER_TARGET_HOST_x86_64_unknown_linux_gnu: "\$NIX_CC_WRAPPER_TARGET_HOST_x86_64_unknown_linux_gnu"
  NIX_LDFLAGS: "\$NIX_LDFLAGS"
  PKG_CONFIG_PATH: "\$PKG_CONFIG_PATH"
  PATH: "\$PATH"
}
EOF
  '';

  preferLocalBuild = true;
}
EOFO

nix-build default.nix -o "$opam_package.config"

