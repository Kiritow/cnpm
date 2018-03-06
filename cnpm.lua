print("CN Package Manager")
print("Author: Github/Kiritow")

local component=require("component")

local function cmd(cmdstr,infostr)
    local old=component.gpu.setForeground(0xFFFF00)
    io.write(cmdstr)
    component.gpu.setForeground(0xFFFFFF)
    print("  " .. infostr)
    component.gpu.setForeground(old)
end
local function err(info)
    local old=component.gpu.setForeground(0xFF0000)
    print(infostr)
    component.gpu.setForeground(old)
end

local shell=require("shell")
local args,ops=shell.parse(...)
local argc=#args
if(argc<1) then
    print("Usage:")
    cmd("cnpm install <package>","Install package")
    cmd("cnpm add <repo>","Add an external repository to cnpm")
    cmd("cnpm del <repo>","Delete an external repository")
    cmd("cnpm update","Update software info")
    cmd("cnpm upgrade [<package>]","Upgrade packages")
    cmd("cnpm remove <package>","Remove package")
    return
end
