# zed-nix

Nix-пакет [Zed](https://zed.dev) из официального бинарного релиза
(`zed-linux-x86_64.tar.gz` с GitHub releases). nixpkgs собирает Zed из
исходников и отстаёт от апстрима — здесь версия обновляется ежедневно
GitHub Action'ом.

```nix
zedSrc = builtins.fetchTarball {
  url = "https://github.com/farwydi/zed-nix/archive/refs/heads/master.tar.gz";
};
zed = pkgs.callPackage "${zedSrc}/package.nix" { };
```

Обновление вручную: `./update.sh [версия]`.
