# tunnel

tunnel 是一个采用对称加密的TCP隧道项目，采用 client/server 架构建立一条传输层加密隧道保障传输数据的安全。tunnel的灵感来自于 [qtunnel](https://github.com/getqujing/qtunnel)。

## 安装

* 注意：当前还不支持在 Windows 环境安装本程序

你需要根据你使用的 Linux 发行版先安装 crystal 和 shards，以及 openssl-devel 库才能顺利编译本项目。

安装步骤：

``` bash
git clone https://github.com/gnuos/tunnel.cr.git
cd tunnel.cr
shards update --verbose
shards build --release
ls -lh ./bin/

```

## 使用

在编译完成后，会在当年目录下产生一个 bin 目录，编译好的二进制可执行程序 `tunnel` 就在 bin 目录中。

查看使用说明：
```bash
./bin/tunnel -h
```

默认是关闭debug信息和透明传输的，如果有调试方面的需要，可以加上 -d 和 -t参数，这样可以单独调试任何一端的程序。

## Development

TODO List:
1. 要添加自定义协议防止TCP Replay的攻击
2. 要给数据包加上顺序标签防止数据包被意外drop后无法正确接收
3. 要给数据包加上散列签名，在数据被中间人修改后可以辨认出真伪
4. 要加入数据重传机制，确保数据可靠传输到对端
5. 加入适合企业级使用的更多的认证方式

## Contributing

1. Fork it (<https://github.com/gnuos/tunnel/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Kevin](https://github.com/gnuos) - creator and maintainer

