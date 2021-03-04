# ArchLinux mono 编译 openRA
https://github.com/OpenRA/OpenRA/blob/bleed/INSTALL.md


## 安装mono以及msbuild toolchain
```
sudo pacman -S mono mono-msbuild
```

## 下载并编译 openRA

```
git clone git@github.com:OpenRA/OpenRA.git

cd OpenRA

make RUNTIME=mono

./launch-game.sh Game.Mod=ra
```

界面顺利启动，点击安装，开始下载资源