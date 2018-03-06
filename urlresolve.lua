local t={}

function t.github(reponame,fileaddr)
    return "https://raw.githubusercontent.com/" .. reponame .. "/master/" .. fileaddr
end
function t.bitbucket(reponame,fileaddr)
    return "https://bitbucket.org/" .. reponame .. "/raw/master/" .. fileaddr
end
function t.gitee(reponame,fileaddr)
    return "https://gitee.com/" .. reponame .. "/raw/master/" .. fileaddr
end
function t.csdncode(reponame,fileaddr)
    return "https://code.csdn.net/" .. reponame .. "/blob/master/" .. fileaddr
end
function t.cngit(reponame,fileaddr)
    return "http://kiritow.com:3000/" .. reponame .. "/raw/master/" .. fileaddr
end
function t.codingnet(reponame,fileaddr)
    local idx=string.find(x,"/")
    if(idx~=nil) then
        local user=string.sub(x,1,idx-1)
        local repo=string.sub(x,idx+1)
        return "https://coding.net/u/" .. user .. "/p/" .. repo .. "/git/raw/master/" .. fileaddr
    else
        error("Cannot resolve coding.net repository url.")
    end
end

return t