# CN Package Manager

An OpenComputers Package Manager. (Different from OPPM)

一个开放式电脑(OpenComputers)的包管理器

## 起因

oppm实在是太慢了, 本来访问github速度就不快, 再加上每个仓库里都有一大堆文件需要读取. 另外oppm在搜索程序的时候是在线搜索的, 也就是说发起了一大堆网络请求, 对于延迟高的地区不是十分友好.

因此,决定设计一个CNPM缓解一下问题.

CNPM计划加入如下特性:

> 程序列表本地缓存, 搜索在本地完成.
> 
> 允许从任何站点加载程序包,只要程序包符合一定要求.
>
> 兼容oppm

