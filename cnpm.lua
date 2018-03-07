print("CN Package Manager")
print("Author: Github/Kiritow")

local component=require("component")
local shell=require("shell")
local serialization=require("serialization")

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

local args,ops=shell.parse(...)
local argc=#args
if(argc<1) then
    print("Usage:")
    cmd("cnpm install <package>","Install package")
    cmd("cnpm add [-gbmkno,--url=<url>] <repo>",
    "Add an external repository to cnpm\n" ..
    "-g Github repository (default)\n" ..
    "-b Bitnami repository\n" ..
    "-m Gitee repository\n" ..
    "-k CNPM official repository\n" ..
    "-n CodingNet repository\n" ..
    "-o Register as oppm repository\n" ..
    "--url=<url> Direct repository link\n"
    )
    cmd("cnpm del <repo>","Delete an external repository")
    cmd("cnpm update","Update software info")
    cmd("cnpm upgrade [<package>]","Upgrade packages")
    cmd("cnpm remove <package>","Remove package")
    return
end

-- Hardware check
local network=component.internet
if(network==nil) then 
    err("No network device found.") 
end

local function getdb()
    local f=io.open("/etc/cnpm/packages.cache","r")
    local content=f:read("*all")
    f:close()
    return serialization.unserialize(content)
end

local function savedb(db)
    local str=serialization.serialize(db)
    local f=io.open("/etc/cnpm/packages.cache","w")
    f:write(str)
    f:close()
end

if(args[1]=="add") then
    local restb=dofile("urlresolver.lua")
    
    local git=false
    local oppm=false
    local resolver
    local url=nil
    
    if(ops.github or ops.g) then
        git=true
        resolver=restb.github
    elseif(ops.bitbucket or ops.b) then
        git=true
        resolver=restb.bitbucket
    elseif(ops.gitee or ops.m) then
        git=true
        resolver=restb.gitee
    elseif(ops.cngit or ops.k) then
        git=true
        resolver=restb.cngit
    elseif(ops.codingnet or ops.n) then
        git=true
        resolver=restb.codingnet
    elseif(ops.oppm or ops.o) then -- Follow OPPM
        git=true
        oppm=true
    elseif(ops.url) then
        url=ops.url
    else
        err("Cannot resolve repository url.")
        return
    end
    
    if(oppm) then 
        -- TODO: Fill the gap between oppm and cnpm
        print("Warning: Oppm repository may not be completely supported.")
    end
    
    local realcfgurl=""
    
    if(git) then
        realcfgurl=resolver(args[2],"mainfest.txt")
    else
        if(string.sub(url,-1)~="/") then 
            url=url .. "/" 
        end
        realcfgurl=url .. "mainfest.txt"   
    end
    
    local hand=network.request(realcfgurl)
    local res=""
    while true do
        local tmp=hand.read()
        if(tmp~=nil) then
            res=res .. tmp
        else break end
    end
    hand.close()
    
    local fn=load(res,"Mainfest","t",{})
    local err,mft=pcall(fn)
    if(not err) then
        err("Failed to load mainfest.")
        return
    end
    
    local function checkval(param,tp)
        if(tp==nil) then tp="string" end
        if(type(tp)~="table") then
            tp={tp}
        end
        for k,v in pairs(tp) do
            if(type(param)==v) then return param end
        end
        error("invalid param type")
    end
    
    local pkg={}
    local ret=pcall(
        function()
            -- Copy info
            pkg.name=checkval(mft.name)
            pkg.info=checkval(mft.info,{"string","nil"})
            pkg.author=checkval(mft.author,{"string","nil"})
            pkg.version=checkval(mft.version)
            pkg.files=checkval(mft.files,"table")
            pkg.depends=checkval(mft.depends,{"table","string","nil"})
            pkg.precheck=checkval(mft.precheck,{"string","nil"})
            pkg.setup=checkval(mft.setup,{"string","nil"})
            pkg.uninst=checkval(mft.uninst,{"string","nil"})
            
            -- Package setup check
            for k,v in pairs(pkg.files) do
                if(type(k)~="string" or type(v)~="string") then
                    error("file list type exception.")
                end
            end
            
            if(
                (pkg.precheck and pkg.files[pkg.precheck]==nil) or
                (pkg.setup and pkg.files[pkg.setup]==nil) or
                (pkg.uninst and pkg.files[pkg.uninst]==nil)
            ) then
                error("special files not found in files list.")
            end
        end
    )
    
    if(ret==false) then
        err("Invalid package mainfest.")
    end
end
