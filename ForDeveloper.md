# 开发者文档

为保证库能够被cnpm识别,Github仓库或其他git或http站点提供的根目录下需要存在一个配置文件,用来说明库应该如何安装并使用.

该文件应包含一个Lua表,如下:

```Lua
{
    ["name"]="Example", -- 程序库名称
    ["info"]="An example library for cnpm", -- 程序库简介
    ["author"]="Kiritow", -- 作者
    ["version"]="1.0" or "auto", -- 版本
    ["files"]={ -- 文件拷贝列表
        ["main.lua"]="/usr/bin/cnpm-example.lua",
        ["libexample.lua"]="/usr/lib/libexample.lua",
        ["uninstaller.lua"]="/etc/cnpm/Example/uninst.lua",
        ["precheck.lua"]="",
        ["setup.lua"]=""
    },
    ["depends"]={ -- 依赖关系(可选)
        "libevent"
    },
    ["precheck"]="precheck.lua", -- 安装前检查程序(可选)
    ["setup"]="setup.lua", -- 安装后配置程序(可选)
    ["uninst"]="uninstaller.lua" -- 卸载前配置程序(可选)
}
```

如果识别到正确的文件,cnpm就会认定其为合法源.

## 认证源

为了加强包管理系统的安全性, cnpm会内置一份认证源清单. 当用户从未认证源下载内容时, 会弹出安全警告(可以关闭该提示). 开发者可以提交加入认证清单的申请.
