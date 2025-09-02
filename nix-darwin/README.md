# KPM NixOS Setup

## Install Nix OS

```
sh <(curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install)
```

## Install Nix Flakes

```
nix flake init -t nix-darwin --extra-experimental-features "nix-command flakes"
```

## Install Packages

```
sudo -H darwin-rebuild switch --flake .#kpm
```
