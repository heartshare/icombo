-------------------------------
-- iCombo version 0.2.4 beta
-------------------------------
-------- explode string -------
function explode(s, delimiter)
    result = {}
    for match in (s..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match)
    end
    return result
end
-------- get client ip --------
function getClientIp()
        IP = ngx.req.get_headers()["X-Real-IP"]
        if IP == nil then
            IP  = ngx.var.remote_addr 
        end
        if IP == nil then
            IP  = "unknown"
        end
        return IP
end
-------- table find --------
function tableFind(t, e)
    for _, v in ipairs(t) do
        if v == e then
          return true
        end
    end
    return nil
end
-------- read file --------
function fileRead(filename)
    local f = io.open(filename, "r")
    if f == nil then
       return
    end
    local t = f:read("*all")
    f:close()
    return t
end
-------- write file --------
function fileWrite(filename, content)
    local f = io.open(filename, "w")
    if f == nil then
       return nil
    end
    local t = f:write(content)
    f:close()
    return true
end
-------- get file extension --------
function getFileExt(filename)
    return filename:match(".+%.(%w+)$")
end
-------- check value empty --------
function empty(val)
    if val == nil or val == '' then
        return true
    end
    return 
end
-------- remove css comments ---------
function removeCssComents(out)
        out = out:gsub("/%*.-%*/", "")
                 :gsub('\n%s', "")
                 :gsub('^%s*', "")
                 :gsub('\n$', "")
                 :gsub('%s*{', "{")
                 :gsub(';%s*', ";")
                 :gsub(';\n', ";")
                 :gsub('{%s*', "{")
                 :gsub(';}', "}")
                 :gsub('}%s*', "}")
                 :gsub('}\r\n', "}")
                 :gsub('}\n', "}")
                 :gsub('\r\n}', "}")
                 :gsub(',%s*', ",")
                 :gsub(':%s', ":")
                 :gsub('%s>%s', ">")
                 :gsub('#([0-f])%1([0-f])%2([0-f])%3([\\s;\\}])', "#%1%2%3%4")
        return out
    
end
-------- delete cache file -----------
function delFile(posix, path)
    for name in posix.files(path) do
        if name ~= "." and name ~= ".." then
            posix.unlink(path..name)
        end
    end
end
-------- log execute_time ---------
function logTime()
    local exec_time = string .format("%.3f", ngx.now() - ngx.req.start_time())
    ngx.log(ngx.CRIT, exec_time);
end
-------- log -----------
function log(data, status)
    status = status or 400
    ngx.log(ngx.CRIT, data)
    if status ~= 0 then
        ngx.exit(status)
    end
end

-------- main --------
local file_lists  = ngx.var.arg_f
if file_lists == nil then
    log("param f is empty")
end

local types            = {["js"]="application/x-javascript", ["css"]="text/css"}
local posix            = require 'posix'
local root             = ngx.var.document_root..'/'
local file_dir         = root
local req_url          = ngx.var.host..ngx.var.uri..file_lists
local uris             = explode(file_lists, ",")
local size             = table.getn(uris)
local cache_dir        = ""
local out              = ""
local ext              = ""
local file_out         = ""
local file_info        = 0
local last_modify      = 0
local http_last_modify = 0
local count            = 0

-- only allow js css
ext = getFileExt(uris[1])
if types[ext] == nil then
    log("extension is error")
end

-- max files
local max_files = ngx.var.max_files
if not empty(max_files) and size > tonumber(max_files) then
    log("exceed max files")
end

-- set file directory
if ext == "css" then
    if ngx.var.css_dir ~= nil then
        file_dir = root..ngx.var.css_dir
    end
elseif ngx.var.js_dir ~= nil then
    file_dir = root..ngx.var.js_dir
end

if ngx.var.cache_dir ~= nil then
    cache_dir = ngx.var.cache_dir.."/"
else
    log("cache_dir is empty")
end

-- delete cache file
if ngx.var.arg_c ~= nil and ngx.var.admin_ip ~= nil then
    local admin_ip = explode(ngx.var.admin_ip, ",");
    local ip       = getClientIp()
    if (tableFind(admin_ip, ip)) ~= nil then
        delFile(posix, cache_dir)
        ngx.header.content_type  = "text/html"
        ngx.say('success')
        ngx.exit(200)
    end
end

-- get files last modify time
for i = 1, size, 1 do 
    file_info = posix.stat(file_dir..uris[i])
    if file_info == nil then
        log(uris[i].." file not found")
    end
    if file_info["type"] ~= "regular" or getFileExt(uris[i]) ~= ext then
        log(uris[i].." extension is error")
    end
    if file_info["mtime"] > last_modify then
        last_modify = file_info["mtime"]
    end
end

ngx.header.content_type  = types[ext]
http_last_modify         = ngx.http_time(last_modify)

local md5_req_url  = ngx.md5(req_url)
local combo_file   = cache_dir..md5_req_url..".combo"
local icombo_sub   = '/icombo_sub/'..md5_req_url..".combo"
local combo_modify = posix.stat(combo_file, "mtime") 
-- cache nil
if nil == combo_modify then
    combo_modify = 0
end

local up_cache = last_modify > combo_modify
-- cache valid
if not up_cache then
    return ngx.exec(icombo_sub)
end

-- cache expire or nil
local bom           = string.char(0xEF, 0xBB, 0xBF)
local dir_name      = ""
local css_path_auto = ngx.var.css_path_auto
local t_out    = {}
for i = 1, size, 1 do 
    file_out = fileRead(file_dir..uris[i])
    if file_out == nil then
        log(uris[i].." read fail")
    elseif file_out == "" then
        -- no cache file
        if 0 == combo_modify then
           log(uris[i].." content is empty")
        else
            log(uris[i].." read old cache file", 0)
            return ngx.exec(icombo_sub)
        end        
    end
    if file_out:sub(1,3) == bom then
        file_out = file_out:sub(4)
    end
    -- css_path_auto
    dir_name = posix.dirname(uris[i])
    if not empty(css_path_auto) and dir_name ~= nil then
        -- handle ../
        file_out, count = ngx.re.gsub(file_out, '../'..css_path_auto, './'..css_path_auto, 'i');
        -- handle ./
        file_out, count = ngx.re.gsub(file_out, '(?<!/)'..css_path_auto, dir_name..'/'..css_path_auto, 'i');
    end
    t_out[i] = file_out
end

-- large string use table is fast
out   = table.concat(t_out, "\r\n")
t_out = nil

if ext == "css" then
    -- remove css comment
    local css_trim = ngx.var.css_trim
    if css_trim ~= nil and css_trim:lower() == "on" then
        out = removeCssComents(out)
    end
    -- replace images path
    local css_replace = ngx.var.css_replace
    if not empty(css_replace) then
        local replaces  = explode(css_replace, "|")
        size            = table.getn(replaces)
        for i = 1, size, 1 do
            local single = explode(replaces[i], ",")
            out, count   = ngx.re.gsub(out, single[1], single[2], 'i')
        end
    end
end

local res = fileWrite(combo_file, out)
if res == nil then
    log('cache write fail, please check cache_dir permitted access')
end
posix.utime(combo_file, last_modify)
return ngx.exec(icombo_sub)