# build-wsl-kernel
[WSL2-Linux-Kernel](https://github.com/microsoft/WSL2-Linux-Kernel)をDockerをつかってビルドします。

## Requirements
- Docker
- GNU Make
- Coreutils
- curl
- tar
- gunzip

## Support Compiler
- gcc-9
- gcc-10
- gcc-11
- clang-11
- clang-12

## Usage
WSL上のLinuxやmacOSなどで`make`を実行するだけでソースコードのダウンロード、ビルド用のDockerイメージのビルド、カーネルのビルドまで行います。(デフォルトはgcc-9）<br>
コンパイラを変えたいときは引数にビルドしたいコンパイラを渡します。
```
$ make clang-12
```

ビルドが終わると、コンパイラの名前でディレクトリが出来て、その中にビルドしたカーネルとオブジェクトファイルが置かれます。
```
$ tree -L 1 gcc-9
gcc-9
├── linux-msft-wsl-5.10.16.3.bzImage
├── linux-msft-wsl-5.10.16.3.vmlinux
└── obj

1 directory, 2 files
```

vmlinuxかbzImageをWindows側にコピーし、`.wslconfig`にカーネルのファイル名を指定すれば利用できます。
- [Wslconfig を使用してグローバルオプションを構成する](https://docs.microsoft.com/ja-jp/windows/wsl/wsl-config#configure-global-options-with-wslconfig)