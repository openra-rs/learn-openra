# win10 系统 编译 OpenRa 系统

参考: https://github1s.com/OpenRA/OpenRA/blob/HEAD/.github/workflows/ci.yaml >> windows

* 安装[`.NET 5`](https://dotnet.microsoft.com/download/dotnet/thank-you/sdk-5.0.200-windows-x64-installer)
* 安装[`chocolatey`](https://www.chocolatey.org/install)
* 使用`chocolatey`安装`lua`->`chocolatey install lua --version 5.1.5.52`
* 设置`lua`环境变量->`$ENV:Path = $ENV:Path + ";C:\Program Files (x86)\Lua\5.1\"`
* 依次执行下面命令
  * `dotnet nuget locals all --clear`
  * `.\make.ps1 check`
  * `dotnet build OpenRA.Test\OpenRA.Test.csproj -c Debug --nologo -p:TargetPlatform=win-x64`
  * `dotnet test bin\OpenRA.Test.dll --test-adapter-path:.`
  * `.\make.ps1 check-scripts`
  * `.\make.ps1 test`
* 运行游戏-> `.\launch-game.cmd`