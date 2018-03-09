print("CN Package Manager")
print("Author: Github/Kiritow")

local component=require("component")
local shell=require("shell")
local serialization=require("serialization")
local uuid=require("uuid")

local function showcmd(cmdstr,infostr)
    local old=component.gpu.setForeground(0xFFFF00)
    io.write(cmdstr)
    component.gpu.setForeground(0xFFFFFF)
    print("  " .. infostr)
    component.gpu.setForeground(old)
end
local function showerr(infostr)
    local old=component.gpu.setForeground(0xFF0000)
    print(infostr)
    component.gpu.setForeground(old)
end
local function cwrite(color,infostr)
    local old=component.gpu.setForeground(color)
    io.write(infostr)
    component.gpu.setForeground(old)
end

local args,ops=shell.parse(...)
local argc=#args
if(argc<1) then
    print("Usage:")
    showcmd("cnpm install <package>","Install package")
    showcmd("cnpm list [-in] [<package>]",
        "Search package" ..
        "\tList all package if no package name given.\n" ..
        "\t-i Only search in installed package\n" ..
        "\t-n Only search in not installed package"
    ) 
    showcmd("cnpm add [-gbmkno,--url=<url>] <repo>",
        "Add an external repository to cnpm\n" ..
        "\t-g Github repository (default)\n" ..
        "\t-b Bitnami repository\n" ..
        "\t-m Gitee repository\n" ..
        "\t-k CNPM official repository\n" ..
        "\t-n CodingNet repository\n" ..
        "\t-o Register as oppm repository\n" ..
        "\t--url=<url> Direct repository link"
    )
    showcmd("cnpm del <repo>","Delete an external repository")
    showcmd("cnpm update","Update software info")
    showcmd("cnpm upgrade [<package>]","Upgrade packages")
    showcmd("cnpm remove <package>","Remove package")
    return 0
end

-- Hardware check
local network=component.internet
if(network==nil) then 
    showerr("No network device found.") 
end

local function getdb()
    local f=io.open("/etc/cnpm/packages.cache","r")
    if(f==nil) then
        -- Try create on first time failure
        local ff,err=io.open("/etc/cnpm/packages.cache","w")
        if(ff==nil) then
            error("Failed to read packages cache file: " .. err)
        else
            ff:close()
            return {}
        end
    end
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
    
    print("Initializing...")
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
        showerr("Cannot resolve repository url.")
        return 1
    end
    
    if(oppm) then 
        -- TODO: Fill the gap between oppm and cnpm
        print("Warning: Oppm repository may not be completely supported.")
    end
    
    local realcfgurl=""
    
    print("Resolving url...")
    if(git) then
        realcfgurl=resolver(args[2],"mainfest.txt")
    else
        if(string.sub(url,-1)~="/") then 
            url=url .. "/" 
        end
        realcfgurl=url .. "mainfest.txt"   
    end
    
    print("Downloading mainfest...")
    local hand=network.request(realcfgurl)
    local res=""
    while true do
        local tmp=hand.read()
        if(tmp~=nil) then
            res=res .. tmp
        else break end
    end
    hand.close()
    
    print("Reading mainfest...")
    local fn=load("return " .. res,"Mainfest","t",{})
    local isok,err=pcall(fn)
    if(not isok) then
        showerr("Failed to load mainfest: " .. err)
        return 2
    end

    local mft=err -- If nothing wrong happend, then the second value should be mft(Mainfest Table)
    
    local function checkval(param,tp)
        if(tp==nil) then tp="string" end
        if(type(tp)~="table") then
            tp={tp}
        end
        for k,v in pairs(tp) do
            if(type(param)==v) then return param end
        end
        error("Invalid param type")
    end
    
    print("Checking mainfest...")
    local pkg={}
    local ret,err=pcall(
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
        showerr("Invalid package mainfest: " .. err)
        return 3
    end

    print("Adding package info...")
    local db=getdb()

    local spkg={}
    spkg.pkg=pkg
    spkg.site=string.gsub(realcfgurl,"/mainfest.txt","/")
    spkg.cert=false -- Repo add through "cnpm add" are not certified.
    spkg.guid=uuid.next()

    -- Checking package repeat before adding it
    for k,t in pairs(db) do
        if(t.site==spkg.site) then
            showerr("Package already exist.")
            return 1
        end
    end

    print("Updating package info...")
    -- Notice that database is stored by <guid,spkg>
    while(db[spkg.guid]~=nil) do
        spkg.guid=uuid.next()
    end
    db[spkg.guid]=spkg
    
    savedb(db)

    print("Repository Added.")
    return 0
end

local function format_table(t)
    local maxlen={}
    for k,v in ipairs(t.head) do 
        table.insert(maxlen,string.len(v))
    end
    for i,line in ipairs(t.data) do
        for k,v in ipairs(line) do 
            if(maxlen[k]<string.len(v)) then
                maxlen[k]=string.len(v)
            end
        end
    end

    io.write("|")
    for k,v in ipairs(t.head) do
        for i=1,maxlen[k]+2,1 do
            io.write("=")
        end
        io.write("|")
    end
    io.write("\n")

    io.write("| ")
    for k,v in ipairs(t.head) do
        io.write(v)
        for i=1,maxlen[k]-string.len(v),1 do
            io.write(" ")
        end
        io.write(" | ")
    end
    io.write("\n")

    io.write("|")
    for k,v in ipairs(t.head) do
        for i=1,maxlen[k]+2,1 do
            io.write("-")
        end
        io.write("|")
    end
    io.write("\n")

    for i,line in ipairs(t.data) do
        io.write("| ")
        for k,v in ipairs(line) do
            io.write(v)
            for i=1,maxlen[k]-string.len(v),1 do
                io.write(" ")
            end
            io.write(" | ")
        end

        io.write("\n")
    end

    io.write("|")
    for k,v in ipairs(t.head) do
        for i=1,maxlen[k]+2,1 do
            io.write("=")
        end
        io.write("|")
    end
    io.write("\n")
end

if(args[1]=="list") then
    local db=getdb()
    local lst={}
    lst.head={"Package Name","Author","Certified","Installed"}
    lst.data={}

    for k,t in pairs(db) do
        local xt={t.pkg.name,t.pkg.author or "(public)"}
        if(t.pkg.cert) then
            table.insert(xt,"Yes")
        else
            table.insert(xt,"No")
        end
        table.insert(xt,"Unknown")
        
        table.insert(lst.data,xt)
    end

    format_table(lst)
end