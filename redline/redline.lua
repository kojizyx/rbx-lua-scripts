-- redline.lua | koji_xyz | v21
-- UI: UI Library - Script utility | shystemmm

if _G.rl_cleanup then pcall(_G.rl_cleanup); task.wait(0.1) end

local rn = notify
rn("loading...","Redline",3)

local plrs = game:GetService("Players")
local run  = game:GetService("RunService")
local lp   = plrs.LocalPlayer

local fl=math.floor; local sq=math.sqrt; local ac=math.acos
local dg=math.deg; local cl=math.clamp; local mx=math.max; local oc=os.clock
local abs=math.abs

local function try(f) local ok,r=pcall(f); return ok and r or nil end
local function ms() return oc()*1000 end
local function log(...) pcall(print,...) end

-- fps
getfenv().FPS = 120 --[[ This is how many times the script will run every second everything over 120 is some ass ]]
local function get_fps()
    local f = tonumber(_G.FPS) or 120
    if f < 15 then f = 15 end
    if f > 360 then f = 360 end
    return f
end

local w2f = {monarch=1906, phoenix=833, siege=1162, castigate=800}

local cfg_defaults = {
    ents="Entities", ping=47, auto_ping=true,
    gp=true, gp_aim=true, gp_dist=1000,
    face_chk=false, face_ang=100,
    pg_cast=450, pg_mon=1500, pg_phx=500, pg_siege=900,
    glare_d=30, debug=false,
    warn=true, warn_ang=60,
    warn_r=255, warn_g=60, warn_b=60,
    warn_a=0.5, warn_corner=false, warn_blink=false, warn_fade=false,
    warn_style='solid',
    mg={monarch=200, castigate=200, phoenix=200, siege=300},
    s2=true, s2_w2f=1000,
    phx_spd=80, phx_pct=0,
    mp=true, mp_cd=500, mp_ang=90, mp_maxd=20, mp_detect=32, mp_window=220, mp_scan=false, mp_anim=false, mp_anim_dbg=false,
    sl=false, sl_key='q', sl_str=15, sl_spd=18, sl_dur=14,
    sl_dist=500, sl_fov=130, sl_fovs=true, sl_fovf=true,
    sl_pred=8, sl_part='head',
    aura=false, aura_rng=23, aura_cd=15,
    aura_cancel=true,
    aura_hb=false,
    esp=true, esp_name=true, esp_hp=true, esp_pos=true, esp_out=true,
    esp_sz=14, esp_rng=500, esp_dist=true,
    esp_r=220, esp_g=170, esp_b=255,
    hb=false, hb_size=8,
    hud=true, hud_sz=24, hud_x=960, hud_y=975,
    team=false, training=true,
    theme='purple',
    auto_save=true,
}

local function deep_copy(src, dst)
    for k,v in pairs(src) do
        if type(v)=="table" then dst[k]={}; deep_copy(v,dst[k])
        else dst[k]=v end
    end
end

local cfg = {}
deep_copy(cfg_defaults, cfg)

local function dlog(...) if cfg.debug then pcall(print,...) end end

local key_hex = {
    q=0x51,w=0x57,e=0x45,r=0x52,t=0x54,y=0x59,u=0x55,i=0x49,o=0x4F,p=0x50,
    a=0x41,s=0x53,d=0x44,f=0x46,g=0x47,h=0x48,j=0x4A,k=0x4B,l=0x4C,
    z=0x5A,x=0x58,c=0x43,v=0x56,b=0x42,n=0x4E,m=0x4D,
    f1=0x70,f2=0x71,f3=0x72,f4=0x73,f5=0x74,f6=0x75,f7=0x76,f8=0x77,
    lshift=0xA0,rshift=0xA1,lctrl=0xA2,rctrl=0xA3,lalt=0xA4,ralt=0xA5,
    capslock=0x14,tab=0x09,space=0x20,
    ['1']=0x31,['2']=0x32,['3']=0x33,['4']=0x34,['5']=0x35,
    numpad0=0x60,numpad1=0x61,numpad2=0x62,
}
local function khex(name) return key_hex[name] or 0x51 end

local loops_active = true

local st = {
    last_gun="castigate", gun_t=0, parry_t=0,
    mp_busy=false, mp_t=0, sl_on=false, sl_tgt=nil, sl_til=0,
    aura_t=0, att=nil, hb_on=true,
}

local themes = {
    purple   = {esp={220,170,255}, fov={150,60,255}},
    dark     = {esp={200,200,210}, fov={120,120,140}},
    blue     = {esp={180,210,255}, fov={40,110,230}},
    red      = {esp={255,185,185}, fov={210,40,60}},
    green    = {esp={175,255,195}, fov={50,190,80}},
    white    = {esp={240,240,245}, fov={220,220,225}},
    cyan     = {esp={160,240,255}, fov={0,200,240}},
    orange   = {esp={255,210,160}, fov={255,130,30}},
    pink     = {esp={255,180,220}, fov={220,60,160}},
    yellow   = {esp={255,245,160}, fov={230,200,0}},
    teal     = {esp={160,240,220}, fov={0,180,160}},
    crimson  = {esp={255,150,160}, fov={180,20,40}},
    gold     = {esp={255,230,130}, fov={200,160,0}},
    midnight = {esp={160,170,220}, fov={60,70,160}},
    rose     = {esp={255,190,200}, fov={200,80,120}},
    lime     = {esp={200,255,160}, fov={120,220,0}},
}

local theme_list = {
    'purple','dark','blue','red','green','white',
    'cyan','orange','pink','yellow','teal','crimson',
    'gold','midnight','rose','lime',
}

local zone_w=25; local zone_cd=0.4; local flash_cd=0.1
local SELF_R=9  -- gun effects within this many studs of you are YOUR own shots, never parry off them
local zone_win={}; local active_z={}
local seen_win=setmetatable({},{__mode="k"})

local function zk(p)
    if not p then return "?" end
    return fl(p.X/zone_w)..","..fl(p.Z/zone_w)
end

local phx_flight=false; local miss_n=0; local miss_max=3
local phx_log={t0=0,dist=0,sched=0,press_t=0,active=false}  -- projectile tuning data
local mp_unk={}  -- per-name throttle for the melee swing-name scanner
local att_gun={}; local att_gun_t={}; local att_gun_ttl=8000
local win_last={}  -- last scheduled shot time per attacker/zone, kills 1-shot-many-parries
local shot=nil
local function new_shot() shot={t=nil, t0=nil, claimed=false, certain=false, gun=nil, entry=nil} end
new_shot()
local seen_eff={}; local seen_vfx={}; local seen_part={}; local seen_pt={}
local t_win=nil; local warn_til=0; local warn_blink_t=0
local pg_seen={}; local pg_parried={}; local pg_last_press=0
local on_cassette, on_window, on_flash, on_parry, on_melee, try_melee, is_own

local flash_map = {MonarchFlash="monarch",PhoenixFlash="phoenix",SiegeFlashOutsider="siege",CastigateFlash="castigate"}
local glare_map = {MonarchGlare="monarch",SiegeGlare="siege",PhoenixGlare="phoenix",Cross="castigate"}
local win_map   = {ParryIndicator=true,SuspendedIndicator=true}

local c_char, c_root  -- cached. rebuilt only when the character changes, not every call
local function get_char()
    local ch=lp and try(function() return lp.Character end)
    if ch~=c_char then c_char=ch; c_root=nil end  -- new character -> drop the stale root
    return c_char
end
local function get_root()
    local ch=get_char(); if not ch then c_root=nil; return nil end
    if c_root and try(function() return c_root.Parent end)~=nil then return c_root end  -- still good, skip the lookup
    c_root=try(function() return ch:FindFirstChild("HumanoidRootPart") end)
    return c_root
end
local function get_pos() local r=get_root(); return r and try(function() return r.Position end) end

-- memory reads (theo offsets, roblox version-8884371d30284041). matcha emulated api cant read
-- animations, but memory_read can. every read is pcall-wrapped + sanity-bounded so a wrong
-- offset just yields nothing instead of crashing on a bad pointer.
local OFF={
    anim_active=0x888,   -- Animator.ActiveAnimations
    track_anim=0xd0,     -- AnimationTrack.Animation
    anim_id=0xd8,        -- Animation instance -> AnimationId string
    str_len=0x10,        -- roblox string length field
    attr_cont=0x48,      -- Instance.AttributeContainer
    attr_list=0x18,      -- AttributeContainer -> first attribute
    attr_next=0x58,      -- attribute -> next attribute
    attr_val=0x18,       -- attribute -> value struct
    val=0xd0,            -- Misc.Value
}
local mem_on=type(memory_read)=="function"
local function r_ptr(a) if not mem_on or not a or a==0 then return 0 end local ok,v=pcall(memory_read,"uintptr_t",a); return (ok and tonumber(v)) or 0 end
local function r_int(a) if not mem_on or not a or a==0 then return 0 end local ok,v=pcall(memory_read,"int",a); return (ok and tonumber(v)) or 0 end
local function r_rbxstr(a)  -- roblox SSO string: <16 chars inline, else pointer at offset
    if not mem_on or not a or a==0 then return "" end
    local len=r_int(a+OFF.str_len)
    if len<=0 or len>256 then return "" end
    local sp=(len>=16) and r_ptr(a) or a
    if sp==0 then return "" end
    local ok,s=pcall(memory_read,"string",sp); return (ok and s) or ""
end
local function inst_addr(obj)
    if not obj then return nil end
    local ok,a=pcall(function() return obj.Address end)
    return (ok and tonumber(a)) or nil
end

-- pull the live offsets from theo's service so they auto-update when roblox patches. built-in
-- values above are the fallback if the fetch fails. one HttpGet at startup, then cached.
local function load_offsets()
    local ok,txt=pcall(function() return game:HttpGet("https://offsets.imtheo.lol/offsets.hpp") end)
    if not ok or type(txt)~="string" or #txt<200 then log("[off] live fetch failed, using built-in offsets"); return end
    local function grab(key,scope)
        local hay=txt
        if scope then local i=txt:find("namespace "..scope, 1, true); if i then hay=txt:sub(i,i+1500) end end
        local h=hay:match(key.."%s*=%s*(0x%x+)")
        return h and tonumber(h) or nil
    end
    OFF.anim_active = grab("ActiveAnimations") or OFF.anim_active
    OFF.track_anim  = grab("Animation","AnimationTrack") or OFF.track_anim
    OFF.anim_id     = grab("AnimationId") or OFF.anim_id
    OFF.str_len     = grab("StringLength") or OFF.str_len
    OFF.attr_cont   = grab("AttributeContainer") or OFF.attr_cont
    OFF.attr_list   = grab("AttributeList") or OFF.attr_list
    OFF.attr_next   = grab("AttributeToNext") or OFF.attr_next
    OFF.attr_val    = grab("AttributeToValue") or OFF.attr_val
    OFF.val         = grab("Value","Misc") or OFF.val
    log("[off] live offsets loaded (anim_active="..string.format("0x%x",OFF.anim_active)..")")
end
pcall(load_offsets)

local function dsq(a,b)
    if not a or not b then return math.huge end
    local x=b.X-a.X; local y=b.Y-a.Y; local z=b.Z-a.Z; return x*x+y*y+z*z
end
local function hdsq(a,b)
    if not a or not b then return math.huge end
    local x=b.X-a.X; local z=b.Z-a.Z; return x*x+z*z
end
local function vang(a,b)
    local d=a.X*b.X+a.Y*b.Y+a.Z*b.Z
    local m1=sq(a.X^2+a.Y^2+a.Z^2); local m2=sq(b.X^2+b.Y^2+b.Z^2)
    if m1==0 or m2==0 then return 180 end
    return dg(ac(cl(d/(m1*m2),-1,1)))
end

local function is_self(p)
    if not lp then return false end; if p==lp then return true end
    local ok,n=pcall(function() return p.Name end); return ok and n==lp.Name
end
local function is_enemy(p)
    if not cfg.team then return true end; if not lp then return true end
    local ok1,t1=pcall(function() return lp.Team end)
    local ok2,t2=pcall(function() return p.Team end)
    if not(ok1 and ok2) then return true end
    if t1==nil or t2==nil then return true end
    return t1~=t2
end

-- wall check: removed. matcha external has no Ray.new / workspace:Raycast / RaycastParams.
-- all line-of-sight checks are no-ops here (they always passed before anyway).

local function head_pos(e)
    if not e then return nil end
    local src=e
    local ok,ch=pcall(function() return e.Character end); if ok and ch then src=ch end
    local h=try(function() return src:FindFirstChild("Head") end)
    if h then return try(function() return h.Position end) end
    local r=try(function() return src:FindFirstChild("HumanoidRootPart") end)
    if r then return try(function() return r.Position end) end
    return nil
end

local function near_ent(pos)
    local ch=get_char(); local best,bd=nil,math.huge
    local function chk(r,ref)
        if not r then return end
        local p=try(function() return r.Position end); if not p then return end
        local d=dsq(pos,p); if d<bd then bd=d; best=ref end
    end
    local ef=try(function() return workspace:FindFirstChild(cfg.ents) end)
    if ef then
        for _,e in ipairs(try(function() return ef:GetChildren() end) or {}) do
            if ch and e==ch then continue end
            if try(function() return e.Name end)==lp.Name then continue end
            chk(try(function() return e:FindFirstChild("HumanoidRootPart") end) or try(function() return e:FindFirstChild("Head") end),e)
        end
    end
    for _,p in ipairs(try(function() return plrs:GetPlayers() end) or {}) do
        if is_self(p) then continue end
        local char=try(function() return p.Character end); if not char then continue end
        chk(try(function() return char:FindFirstChild("HumanoidRootPart") end),p)
    end
    for _,obj in ipairs(try(function() return workspace:GetChildren() end) or {}) do
        if ch and obj==ch then continue end
        if not obj:IsA("Model") then continue end
        if try(function() return obj.Name end)==lp.Name then continue end
        local hum=try(function() return obj:FindFirstChildOfClass("Humanoid") end); if not hum then continue end
        chk(try(function() return obj:FindFirstChild("HumanoidRootPart") end) or try(function() return obj:FindFirstChild("Head") end),obj)
    end
    return best
end

local function get_tgts(bots)
    local out={}; if not lp then return out end
    local inc=(bots==nil) and cfg.training or bots
    for _,p in ipairs(try(function() return plrs:GetPlayers() end) or {}) do
        if is_self(p) or not is_enemy(p) then continue end
        local char=try(function() return p.Character end); if not char then continue end
        local root=try(function() return char:FindFirstChild("HumanoidRootPart") end); if not root then continue end
        local rpos=try(function() return root.Position end); if not rpos then continue end
        local ro=try(function() return p:FindFirstChild("ReadOnly") end)
        local hv=ro and try(function() return ro:FindFirstChild("health") end)
        local hp=hv and try(function() return hv.Value end)
        if hp and hp<=0 then continue end
        local hd=try(function() return char:FindFirstChild("Head") end)
        local hpos=(hd and try(function() return hd.Position end)) or rpos
        table.insert(out,{char=char,root=root,pos=rpos,hpos=hpos,name=p.Name,player=true,ent=p})
    end
    if inc then
        local ef=try(function() return workspace:FindFirstChild(cfg.ents) end)
        local ch=get_char()
        if ef then
            for _,e in ipairs(try(function() return ef:GetChildren() end) or {}) do
                if ch and e==ch then continue end
                local en=try(function() return e.Name end) or ""
                if en==lp.Name then continue end
                local hd=try(function() return e:FindFirstChild("Head") end)
                -- drones/npcs may not have a humanoid rig, so fall back through any main part
                local root=try(function() return e:FindFirstChild("HumanoidRootPart") end)
                    or try(function() return e:FindFirstChild("Torso") end)
                    or try(function() return e.PrimaryPart end)
                    or hd
                    or try(function() return e:FindFirstChildWhichIsA("BasePart") end)
                local anch=root; if not anch then continue end
                local rpos=try(function() return anch.Position end); if not rpos then continue end
                local hpos=(hd and try(function() return hd.Position end)) or rpos
                table.insert(out,{char=e,root=anch,pos=rpos,hpos=hpos,name=en,player=false,ent=e})
            end
        end
        for _,obj in ipairs(try(function() return workspace:GetChildren() end) or {}) do
            if not obj:IsA("Model") then continue end
            if try(function() return obj.Name end)==lp.Name then continue end
            local hum=try(function() return obj:FindFirstChildOfClass("Humanoid") end); if not hum then continue end
            local r=try(function() return obj:FindFirstChild("HumanoidRootPart") end); if not r then continue end
            local hp=try(function() return r.Position end); if not hp then continue end
            local hd=try(function() return obj:FindFirstChild("Head") end)
            table.insert(out,{pos=hp,hpos=hd and try(function() return hd.Position end) or hp,
                char=obj,name=try(function() return obj.Name end) or "?",ref=obj})
        end
    end
    return out
end

-- cache the target list. get_tgts walks every player + the entity folder + all of
-- workspace, so calling it at 120hz from two loops was scanning the whole game ~240x/sec
-- and dumping hundreds of ms of ping. refresh it ~16x/sec and share it instead.
local tgt_cache, tgt_cache_t = {}, 0
local function tgts_cached()
    local now=ms()
    if now-tgt_cache_t>60 then tgt_cache=get_tgts(true); tgt_cache_t=now end
    return tgt_cache
end

-- press parry key (F)
local function press_f()
    pcall(keypress,0x46); task.wait(0.05); pcall(keyrelease,0x46)
end

-- single chokepoint for gun parry presses. one shot can be seen by the glare path, the
-- window indicator path AND the pgui path within a few hundred ms, so this hard-locks one
-- gun parry press per 250ms unless force=true (the deliberate siege 2nd parry, ~1s later).
-- kept short so two different shooters firing close together can both still be parried.
local gp_lock=0
local function gun_press(force)
    local now=ms()
    if not force and now<gp_lock then dlog("[gp] press blocked (locked)"); return false end
    gp_lock=now+250
    press_f()
    return true
end

local cfg_file="redline_config.txt"
local cfg_changed=false
local chg_t=0

local function mark_chg()
    cfg_changed=true; chg_t=oc()
end

local function cfg_ser()
    local out={}
    local function flat(t,pre)
        for k,v in pairs(t) do
            local full=pre and (pre.."."..tostring(k)) or tostring(k)
            local vt=type(v)
            if vt=="number" then out[#out+1]=full.."="..tostring(v)
            elseif vt=="boolean" then out[#out+1]=full.."="..(v and "true" or "false")
            elseif vt=="string" then out[#out+1]=full.."="..v
            elseif vt=="table" then flat(v,full) end
        end
    end
    flat(cfg,nil); return table.concat(out,"\n")
end

local function cfg_apply(str)
    if not str or str=="" then return false end
    for line in (str.."\n"):gmatch("([^\n]*)\n") do
        local key,val=line:match("^([^=]+)=(.*)$")
        if key and val then
            local parts={}; for p in key:gmatch("[^%.]+") do parts[#parts+1]=p end
            local tbl=cfg
            for i=1,#parts-1 do
                if type(tbl)~="table" then tbl=nil; break end
                tbl=tbl[parts[i]]
            end
            if type(tbl)=="table" and #parts>=1 then
                local last=parts[#parts]; local cur=tbl[last]
                if type(cur)=="number" then tbl[last]=tonumber(val) or cur
                elseif type(cur)=="boolean" then tbl[last]=(val=="true")
                elseif type(cur)=="string" then tbl[last]=val end
            end
        end
    end
    return true
end

local function cfg_save()
    if type(writefile)~="function" then
        pcall(setclipboard,cfg_ser()); rn("config copied (no writefile)","Redline",3); return
    end
    local ok=pcall(writefile,cfg_file,cfg_ser())
    if ok then rn("config saved","Redline",2)
    else pcall(setclipboard,cfg_ser()); rn("save failed, copied","Redline",3) end
    cfg_changed=false
end

local function cfg_load()
    if type(readfile)~="function" then return false end
    if type(isfile)=="function" then
        local ok,ex=pcall(isfile,cfg_file)
        if not ok or not ex then pcall(writefile,cfg_file,""); return false end
    end
    local ok,data=pcall(readfile,cfg_file)
    if ok and data and data~="" then
        cfg_apply(data); log("[cfg] loaded")
        if tonumber(cfg.gp_dist) and cfg.gp_dist<=250 then cfg.gp_dist=1000; log("[cfg] bumped old detect range -> 1000") end
        return true
    end
    return false
end

task.spawn(function() task.wait(0.2); cfg_load() end)

local function set_warn_style(s)
    s=s or 'fade'
    cfg.warn_corner = s:find('corner')~=nil
    cfg.warn_blink  = s:find('blink')~=nil
    cfg.warn_fade   = not s:find('solid') and not s:find('blink')
end

local parry_queue={}
local pq_last_press=0
local PQ_MIN_GAP=80
local last_gp_press=0  -- shared between the effects queue and the pgui scan, stops 2 parries per shot
local last_parry_conf=0  -- dedup the PARRY confirmed log when one parry spawns several vfx parts

local function enqueue_parry(sched_ms, att_ref, gun, snap_pos)
    if not cfg.gp then return nil end
    local fire_at=ms()+math.max(0,sched_ms)
    local entry={
        fire_at=fire_at, created=ms(),
        gun=gun, att=att_ref, snap=snap_pos, done=false,
    }
    table.insert(parry_queue,entry)
    table.sort(parry_queue,function(a,b) return a.fire_at<b.fire_at end)
    dlog("[pq] queued "..tostring(gun).." +"..fl(sched_ms).."ms")
    return entry
end

task.spawn(function()
    while loops_active do
        local now=ms()
        for _,entry in ipairs(parry_queue) do
            if entry.done then continue end
            if now<entry.fire_at then break end
            if not cfg.gp then
                entry.done=true
            elseif now-last_gp_press<300 then
                -- the pgui scan already parried this shot, dont double tap
                entry.done=true
                dlog("[pq] dup skip (already parried)")
            elseif now-pq_last_press>=PQ_MIN_GAP then
                entry.done=true
                pq_last_press=now
                last_gp_press=now
                local _gun=entry.gun; local _att=entry.att; local _snap=entry.snap
                task.spawn(function()
                    if cfg.gp_aim then
                        local sp=nil
                        if _att then
                            local hp=head_pos(_att)
                            if hp and _snap and dsq(hp,_snap)>2500 then sp=_snap
                            elseif hp then sp=hp else sp=_snap end
                        else sp=_snap end
                        if sp and type(mousemoverel)=="function" then
                            local cam=workspace.CurrentCamera
                            local vp=cam and try(function() return cam.ViewportSize end)
                            if vp then
                                local ok_sp,scr=pcall(WorldToScreen,sp)
                                if ok_sp and scr and type(scr)~="boolean" then
                                    local sx=scr.X; local sy=scr.Y
                                    if sx and sy then
                                        local dx=(sx-vp.X/2)*0.7; local dy=(sy-vp.Y/2)*0.7
                                        local spd=sq(dx*dx+dy*dy)
                                        if spd>30 then local s=30/spd; dx=dx*s; dy=dy*s end
                                        if abs(dx)>0.5 or abs(dy)>0.5 then
                                            pcall(mousemoverel,0,fl(dx),fl(dy))
                                        end
                                    end
                                end
                            end
                        end
                    end
                    dlog("[pq] F -> "..tostring(_gun))
                    if _gun=="phoenix" then phx_log.press_t=ms() end
                    gun_press()
                end)
                break
            else
                break
            end
        end
        local now2=ms()
        local clean={}
        for _,e in ipairs(parry_queue) do
            if not e.done and (now2-e.created)<8000 then table.insert(clean,e) end
        end
        parry_queue=clean
        task.wait(0.01)
    end
end)

local aura_pending=false

local function calc_sched(gun, dist)
    local ping=cfg.ping or 47
    local mg_tbl=(type(cfg.mg)=="table") and cfg.mg or {}
    local mg=(mg_tbl[gun]) or 200
    local sched=mx(0,(w2f[gun] or 800)-mg-ping)
    if gun=="phoenix" then
        local travel=0
        if dist then
            local spd=cfg.phx_spd or 80
            if (cfg.phx_pct or 0)>0 then spd=spd*(1+(dist/100)*((cfg.phx_pct or 0)/100)) end
            travel=(dist/spd)*1000
        end
        sched=mx(0,(w2f.phoenix or 686)+travel-mg-ping)
        phx_flight=true
        if not phx_log.active then phx_log.t0=ms(); phx_log.active=true; phx_log.press_t=0 end  -- start the flight clock once per shot
        if dist then phx_log.dist=dist end
        phx_log.sched=sched
    end
    return sched
end

-- the claim only resets on cassette/flash. if you move away or dodge, the shot whiffs and the
-- flash never comes, so the claim would stay stuck and block every later shot. expire it once
-- enough time passed for that gun's whole window->flash to be over.
local function maybe_reset_shot()
    if shot and shot.claimed and shot.t and (ms()-shot.t) > ((w2f[shot.gun] or 800)+600) then
        dlog("[gp] shot cycle timed out, reset")
        new_shot()
    end
end

on_window=function(gun_guess,epos,src,certain)
    if not cfg.gp then return end
    local me0=get_pos()
    if me0 and epos and sq(dsq(me0,epos))<SELF_R then dlog("[gp] self effect, skip"); return end
    if ms()-last_parry_conf<300 then dlog("[gp] just parried, skip lingering"); return end
    local my=get_pos()
    local att=nil
    if epos then
        local cand=near_ent(epos)
        if cand then
            local cand_hp=head_pos(cand)
            if cand_hp and dsq(epos,cand_hp)>900 then
                dlog("[gp] stale SI"); zone_win[zk(epos)]=oc()+flash_cd; active_z[zk(epos)]=nil; return
            end
            att=cand; st.att=att
        end
    end
    local gun=gun_guess
    if certain then st.last_gun=gun; st.gun_t=ms() end  -- glare named the gun, track it so the next window times right
    if att then
        if certain then
            -- a glare names the gun for sure, so trust it and refresh the cache.
            -- this kills the "fired siege, swapped to monarch, still says siege" miss.
            att_gun[att]=gun; att_gun_t[att]=ms()
        else
            local stored=att_gun[att]; local stored_t=att_gun_t[att] or 0
            if stored and (ms()-stored_t)<att_gun_ttl then
                gun=stored
                if stored~=gun_guess then dlog("[gp] gun override "..tostring(gun_guess).." -> "..stored) end
            end
        end
    end
    -- distance first so a reaim can recompute timing
    local dist=nil
    if my and att then local hp=head_pos(att); if hp then dist=sq(dsq(my,hp)) end end

    -- a shot is ONE gun. claim the whole cassette->flash cycle once, not per gun. on a swap the
    -- first SuspendedIndicator can guess the stale gun (castigate) and a later one the real gun
    -- (monarch) a few ms apart. instead of firing twice, REAIM the single pending press to the
    -- better gun. a certain glare locks it so a later uncertain window cant downgrade it.
    if not shot then new_shot() end
    maybe_reset_shot()
    if certain then shot.certain=true end
    if shot.claimed then
        if gun~=shot.gun and (certain or not shot.certain) then
            local nsched=calc_sched(gun,dist)
            local fire_at=(shot.t0 or ms())+nsched  -- anchor to the shots FIRST window, not now
            if shot.entry and not shot.entry.done then
                shot.entry.gun=gun; shot.entry.fire_at=fire_at
                dlog("[gp] reaim shot -> "..tostring(gun).." | sched "..fl(nsched).."ms")
                shot.gun=gun
                if certain then shot.certain=true end
            elseif certain and fire_at>ms()+20 then
                shot.entry=enqueue_parry(fire_at-ms(),att,gun,epos)  -- press already fired, only a glare may queue the right one
                dlog("[gp] requeue shot -> "..tostring(gun).." | sched "..fl(nsched).."ms")
                shot.gun=gun; shot.certain=true
            else
                dlog("[gp] reaim too late / uncertain -> keep "..tostring(shot.gun))
            end
        else
            dlog("[gp] already claimed this shot -> "..tostring(gun))
        end
        return
    end
    -- one shooter's shot can spawn a glare AND a window indicator. dedup PER SHOOTER so a
    -- different attacker is handled on its own with the correct timing.
    local who=att or (epos and zk(epos)) or "g"
    if win_last[who] and ms()<win_last[who] then dlog("[gp] same shooter busy, skip"); return end
    if cfg.face_chk and att and my then
        local ok_s,ch=pcall(function() return att.Character end)
        local src_e=(ok_s and ch) or att
        local hd=try(function() return src_e:FindFirstChild("Head") end) or try(function() return src_e:FindFirstChild("HumanoidRootPart") end)
        local look=hd and try(function() return hd.CFrame.LookVector end)
        if look then
            local ap=head_pos(att)
            if ap and vang(look,Vector3.new(my.X-ap.X,my.Y-ap.Y,my.Z-ap.Z))>cfg.face_ang then
                dlog("[gp] facing away"); return
            end
        end
    end
    local sched=calc_sched(gun,dist)
    if gun=="phoenix" then
        dlog("[gp] phoenix | sched "..fl(sched).."ms")
    else
        dlog("[gp] "..tostring(gun).." | sched "..fl(sched).."ms | "..(dist and fl(dist) or "?").."st")
    end
    if cfg.warn then
        -- only warn when the attacker is actually pointed at me (a gun about to go off at me),
        -- and keep it solid for the whole incoming window instead of a quick blink
        local aim_at_me=true
        if att and my then
            local ok_s,ch=pcall(function() return att.Character end)
            local src_e=(ok_s and ch) or att
            local hd=try(function() return src_e:FindFirstChild("Head") end) or try(function() return src_e:FindFirstChild("HumanoidRootPart") end)
            local look=hd and try(function() return hd.CFrame.LookVector end)
            local ap=head_pos(att)
            if look and ap then
                aim_at_me=vang(look,Vector3.new(my.X-ap.X,my.Y-ap.Y,my.Z-ap.Z))<=(cfg.warn_ang or 60)
            end
        end
        if aim_at_me then
            warn_til=tick()+mx(0.45,(sched/1000)+0.2); warn_blink_t=tick()
            rn("incoming "..tostring(gun),"Redline",1)
        end
    end
    t_win=ms()
    win_last[who]=ms()+math.max(300,sched)+350  -- this shooter owned until just after the parry
    shot.claimed=true; shot.gun=gun; shot.t=ms(); shot.t0=ms()
    shot.entry=enqueue_parry(sched,att,gun,epos)
end

local siege_s2_t=0

on_flash=function(gun,fpos)
    st.last_gun=gun; st.gun_t=ms()
    for k in next,active_z do zone_win[k]=oc()+flash_cd end; active_z={}
    if fpos then
        local firer=near_ent(fpos)
        if firer then att_gun[firer]=gun; att_gun_t[firer]=ms() end
    end
    dlog("[detect] flash "..tostring(gun))
    t_win=nil
    if gun=="phoenix" and phx_log.active and phx_log.t0>0 then
        local flight=ms()-phx_log.t0
        local dist=phx_log.dist or 0
        local spd=(flight>0 and dist>0) and (dist/(flight/1000)) or 0  -- studs per second the projectile actually flew
        local lead=(phx_log.press_t>0) and (ms()-phx_log.press_t) or -1  -- how long before impact we pressed
        log(string.format("[phx] IMPACT | dist %dst | flight %dms | real_spd %.1f st/s | pressed %dms early | cfg_spd %d",
            fl(dist),fl(flight),spd,fl(lead),cfg.phx_spd or 80))
        phx_log.active=false
        local t_impact=ms()
        task.spawn(function()
            task.wait(0.5)
            if st.parry_t>=t_impact-200 then log("[phx] -> PARRIED")
            else log("[phx] -> MISSED (raise phx speed if pressed too early, lower if too late)") end
        end)
    end
    if gun=="phoenix" and phx_flight then dlog("[gp] skip: phoenix in flight"); return end
    local t_flash=ms()
    task.spawn(function()
        task.wait(2.5)
        if st.parry_t<t_flash then
            miss_n=miss_n+1; dlog("[gp] miss #"..miss_n)
            if miss_n>=miss_max then
                miss_n=0; log("[gp] miss reset"); rn("AP reset","Redline",1)
            end
        else miss_n=0 end
    end)
    if gun=="siege" and cfg.s2 and cfg.gp then
        local now_s2=ms()
        if now_s2-siege_s2_t>((cfg.s2_w2f or 1000)+300) then  -- one 2nd-parry per whole siege cycle, not per flash
            siege_s2_t=now_s2
            local ping=cfg.ping or 47
            local mg_tbl=(type(cfg.mg)=="table") and cfg.mg or {}
            local sched2=math.max(50,(cfg.s2_w2f or 1000)-(mg_tbl.siege or 200)-ping)
            task.spawn(function()
                task.wait(sched2/1000)  -- siege always has 2 hits, parry the 2nd no matter what
                if cfg.gp and cfg.s2 then gun_press(true); dlog("[gp] F -> siege (2nd)") end
            end)
        end
    end
    new_shot(); dlog("[gp] flash -> "..tostring(gun))
end

on_parry=function(ev)
    local my=get_pos(); local ours=false
    if my then
        local ok,desc=pcall(function() return ev:GetDescendants() end)
        if ok and desc then
            for _,v in ipairs(desc) do
                local ok_n,vn=pcall(function() return v.Name end)
                if ok_n and vn=="SparkDots" then
                    local vp2=v.Parent; local vpos=vp2 and try(function() return vp2.Position end)
                    if vpos and sq(dsq(my,vpos))<15 then ours=true; break end
                end
            end
        end
        if not ours then
            local ok_p,ep=pcall(function() return ev.Position end)
            if ok_p and ep and (ep.X~=0 or ep.Y~=0 or ep.Z~=0) then
                if sq(dsq(my,ep))<20 then ours=true end
            else ours=true end
        end
    else ours=true end
    if ours then
        if ms()-last_parry_conf<350 then return end  -- same parry, just extra vfx parts
        last_parry_conf=ms()
        st.parry_t=ms(); miss_n=0; pq_last_press=ms()
        gp_lock=ms()+250  -- you just parried, hold off any straggler press from another path
        for _,e in ipairs(parry_queue) do
            if not e.done and e.fire_at<=ms()+260 then e.done=true end  -- cancel only this shot's pending press, keep other attackers'
        end
        if phx_flight then phx_flight=false end
        if cfg.aura_cancel then aura_pending=false end
        log("[gp] PARRY confirmed")
    else
        -- enemy/ally parried near us -> kill our queued aura m1 (rival's aura cancel)
        if cfg.aura and cfg.aura_cancel then aura_pending=false; dlog("[aura] cancel: opp parry") end
        dlog("[gp] parry (enemy?)")
    end
end

-- melee ap
-- rival idea: read early from extra studs, only parry when theyre close enough and the
-- swing is still valid (not almost dead). matcha external CANT read animation tracks
-- (GetPlayingAnimationTracks fails, animators dont replicate), so we use the slash effect
-- + attacker distance + attacker velocity to do the same thing.
try_melee=function()
    if not cfg.mp or st.mp_busy then return end
    local now=ms(); if now-st.mp_t<cfg.mp_cd then return end
    st.mp_busy=true; st.mp_t=now; dlog("[mp] F")
    task.spawn(function() press_f(); task.wait(0.6); st.mp_busy=false end)
end

local function mp_face_ok(att,kpos,my)
    if not att then return true end
    local src=att
    local ok,ch=pcall(function() return att.Character end); if ok and ch then src=ch end
    local hd=try(function() return src:FindFirstChild("Head") end) or try(function() return src:FindFirstChild("HumanoidRootPart") end)
    local cf=hd and try(function() return hd.CFrame end)
    local look=cf and try(function() return cf.LookVector end)
    if not look then return true end
    return vang(look,Vector3.new(my.X-kpos.X,my.Y-kpos.Y,my.Z-kpos.Z))<=(cfg.mp_ang or 90)
end

local function att_root(att)
    if not att then return nil end
    local ok,ch=pcall(function() return att.Character end)
    return ((ok and ch) or att):FindFirstChild("HumanoidRootPart")
end

-- your friends melee animation ids. matcha cant read these from the lua api, so we read the
-- Animator struct from memory with theo's offsets and compare the playing ids to these.
local melee_anims={
    ["rbxassetid://71188211641772"]=true,
    ["rbxassetid://87457990259233"]=true,
    ["rbxassetid://105441036119013"]=true,
}
local function animator_of(char)
    if not char then return nil end
    local hum=try(function() return char:FindFirstChildOfClass("Humanoid") end)
    local anr=hum and try(function() return hum:FindFirstChildOfClass("Animator") end)
    if not anr then anr=try(function() return char:FindFirstChildOfClass("AnimationController") end) end
    return anr
end
-- read the asset ids of every animation track currently playing on this animator.
-- ASSUMPTION (flagged): ActiveAnimations is a vector of {AnimationTrack*, ...} pairs, 0x10 stride.
-- if the debug shows no ids, this stride/layout is the knob to change.
local function active_anim_ids(animator)
    local out={}
    local base=inst_addr(animator); if not base then return out end
    local s=r_ptr(base+OFF.anim_active)
    local e=r_ptr(base+OFF.anim_active+0x8)
    if s==0 or e==0 or e<s or (e-s)>0x8000 then return out end  -- junk guard
    local n=0
    for a=s, e-0x8, 0x10 do
        local track=r_ptr(a)
        if track~=0 then
            local anim=r_ptr(track+OFF.track_anim)
            if anim~=0 then
                local id=r_rbxstr(anim+OFF.anim_id)
                if id~="" then out[#out+1]=id end
            end
        end
        n=n+1; if n>=24 then break end
    end
    return out
end

-- attribute reader/dumper. the offset dump gives the chain (container -> list -> next -> value)
-- but NOT the attribute name offset or the value variant layout, so this dumps the raw memory
-- around each node. run it on your gun/character, paste the output, and i can decode the layout.
local function dump_attrs(obj,label)
    local base=inst_addr(obj); if not base then log("[attr] "..(label or "?").." no address"); return end
    local cont=r_ptr(base+OFF.attr_cont)
    log("[attr] ==== "..(label or "?").." ==== inst="..string.format("0x%x",base).." cont="..string.format("0x%x",cont))
    if cont==0 then log("[attr] no attribute container (no attributes set)"); return end
    local node=r_ptr(cont+OFF.attr_list)
    local guard=0
    while node~=0 and guard<24 do
        guard=guard+1
        local row={}
        for o=0,0x78,0x8 do row[#row+1]=string.format("+%02x=0x%x",o,r_ptr(node+o)) end  -- raw words to read the layout
        log("[attr] node"..guard.." @0x"..string.format("%x",node))
        log("[attr]   "..table.concat(row," "))
        local nm=r_rbxstr(node)            -- best-guess: name at node+0
        local val=r_ptr(node+OFF.attr_val) -- value struct
        log("[attr]   name?='"..tostring(nm).."' valPtr=0x"..string.format("%x",val).." valAt+0xd0="..r_int((val~=0 and val or node)+OFF.val))
        node=r_ptr(node+OFF.attr_next)
    end
    log("[attr] ==== done, paste this back ====")
end

on_melee=function(ev,src)
    if not cfg.mp then return end
    local my=get_pos(); if not my then return end
    local ok,kpos=pcall(function() return ev.Position end)
    local att
    if not(ok and kpos and (kpos.X~=0 or kpos.Y~=0 or kpos.Z~=0)) then
        -- matcha gives SlashAcross a zero position, so the effect cant range-check itself.
        -- find the nearest real enemy and use THEIR position instead of blindly parrying.
        local best,bd
        for _,t in ipairs(tgts_cached()) do
            local d=sq(dsq(my,t.pos))
            if d<=(cfg.mp_detect or 32) and (not bd or d<bd) then bd=d; best=t end
        end
        if not best then dlog("[mp] "..tostring(src).." swing (zero-pos), no enemy in range"); return end
        kpos=best.pos; att=best.ent or best.char
        dlog("[mp] "..tostring(src).." swing (zero-pos) -> nearest enemy "..fl(bd).."st")
    end
    local dist=sq(dsq(my,kpos))
    if dist>(cfg.mp_detect or 32) then dlog("[mp] "..tostring(src).." too far "..fl(dist).."st (detect "..(cfg.mp_detect or 32)..")"); return end
    if not att then att=near_ent(kpos) end
    dlog("[mp] "..tostring(src).." swing @ "..fl(dist).."st | att "..(att and (try(function() return att.Name end) or "?") or "none"))
    if not mp_face_ok(att,kpos,my) then dlog("[mp] facing away"); return end
    if dist<=(cfg.mp_maxd or 20) then dlog("[mp] in range -> parry"); try_melee(); return end
    local root=att_root(att)
    local vel=root and (try(function() return root.Velocity end) or try(function() return root.AssemblyLinearVelocity end))
    local apos=root and try(function() return root.Position end)
    if not(vel and apos) then dlog("[mp] no vel/pos, cant predict close"); return end
    local dx=my.X-apos.X; local dy=my.Y-apos.Y; local dz=my.Z-apos.Z
    local m=sq(dx*dx+dy*dy+dz*dz); if m<=0 then return end
    local closing=vel.X*(dx/m)+vel.Y*(dy/m)+vel.Z*(dz/m) -- studs/s toward me
    if closing<=2 then dlog("[mp] not closing in ("..fl(closing).." st/s)"); return end
    local gap=sq(dsq(my,apos))-(cfg.mp_maxd or 20)
    local t_in=gap/closing
    local win=(cfg.mp_window or 220)/1000
    if t_in<=0 or t_in>=win then dlog("[mp] timing off, t_in "..fl(t_in*1000).."ms (win "..(cfg.mp_window or 220)..")"); return end
    dlog("[mp] closing, parry in "..fl(t_in*1000).."ms")
    local fire=ms()
    task.spawn(function()
        task.wait(cl(t_in,0,win))
        if ms()-fire>(cfg.mp_window or 220) then dlog("[mp] swing went stale"); return end
        local mp2=get_pos(); local ap2=att_root(att) and try(function() return att_root(att).Position end)
        if mp2 and ap2 and sq(dsq(mp2,ap2))<=(cfg.mp_maxd or 20)+3 then try_melee()
        else dlog("[mp] didnt close enough by fire time") end
    end)
end

is_own=function(ev)
    local my=get_pos(); if not my then return false end
    local ok,ep=pcall(function() return ev.Position end)
    if not ok or not ep then return false end
    return dsq(my,ep)<9
end

on_cassette=function() new_shot(); dlog("[gp] cassette -> new shot") end

local function scan_folder(folder,seen,vfx)
    local ok,kids=pcall(function() return folder:GetChildren() end)
    if not ok or not kids then return end
    for _,e in ipairs(kids) do
        local ok_n,nm=pcall(function() return e.Name end); if not ok_n or not nm then continue end
        local addr=try(function() return e.Address end) or tostring(e)
        if seen[addr] then continue end
        local ok_p,epos=pcall(function() return e.Position end)
        local pos=ok_p and epos or nil
        local my=get_pos()
        if vfx then
            local gun=glare_map[nm]; if not gun then continue end
            seen[addr]=oc()
            local dist=pos and my and sq(dsq(my,pos)) or math.huge
            if dist<SELF_R then continue end  -- your own shot vfx, not incoming
            if dist<=(cfg.glare_d or 30) then dlog("[gp] glare "..nm); on_window(gun,pos,nm,true)
            elseif dist<=(cfg.gp_dist or 1000) then
                -- too far to trigger off the glare alone, but it NAMES the gun for sure. fix the
                -- current shots timing if its claimed with the wrong gun (catches the swap miss).
                st.last_gun=gun; st.gun_t=ms()
                if shot and shot.claimed and shot.gun~=gun then
                    local ns=calc_sched(gun,nil); local fire_at=(shot.t0 or ms())+ns
                    if shot.entry and not shot.entry.done then
                        shot.entry.gun=gun; shot.entry.fire_at=fire_at; shot.gun=gun; shot.certain=true
                        dlog("[gp] glare id reaim -> "..gun)
                    elseif fire_at>ms()+40 then
                        shot.entry=enqueue_parry(fire_at-ms(),nil,gun,nil); shot.gun=gun; shot.certain=true
                        dlog("[gp] glare id requeue -> "..gun)
                    end
                end
            end
        else
            if win_map[nm] then
                if not pos then continue end
                if seen_win[e] then continue end
                local dist=pos and my and sq(dsq(my,pos)) or math.huge
                if dist<SELF_R then continue end
                if dist>(cfg.gp_dist or 250) then continue end
                local key=zk(pos); local exp=zone_win[key]
                if exp and oc()<exp then continue end
                seen_win[e]=true; zone_win[key]=oc()+zone_cd; active_z[key]=true
                if ms()-pg_last_press<700 then dlog("[gp] skip "..nm.." (pgui)"); continue end
                dlog("[gp] WINDOW "..nm.." | "..fl(dist).."st")
                on_window(st.last_gun,pos,nm,false)
            elseif flash_map[nm] then
                local dist=pos and my and sq(dsq(my,pos)) or math.huge
                if dist<SELF_R then seen[addr]=oc(); continue end
                seen[addr]=oc(); on_flash(flash_map[nm],pos)
            elseif nm=="defaultParry" or nm=="defaultParryOutsider" then
                seen[addr]=oc(); on_parry(e)
            elseif nm=="SlashAcross" or nm=="GlitchAura" then
                local dist=pos and my and sq(dsq(my,pos)) or math.huge
                if dist<3 and dist~=math.huge then seen[addr]=oc(); continue end  -- your own swing
                seen[addr]=oc(); on_melee(e,nm)
            elseif nm=="BulletTracer" then
                if not pos then seen[addr]=oc(); continue end
                local dist=sq(dsq(my,pos)); if dist<5 then seen[addr]=oc(); continue end
                seen[addr]=oc(); on_cassette()
            elseif nm=="Part" then
                if seen_part[addr] then continue end
                seen_part[addr]=true; seen_pt[addr]=oc()
                local ok2,ck=pcall(function() return e:GetChildren() end)
                if ok2 and ck then
                    for _,k in ipairs(ck) do
                        local ok_k,kn=pcall(function() return k.Name end)
                        if ok_k and kn=="CASETTE_PLAY" then
                            if not is_own(e) then on_cassette() end; break
                        end
                    end
                end
            elseif cfg.mp_scan and nm~="Part" then
                -- swing-name finder: dump any unknown effect that pops near you so you can
                -- read off what the melee swing is actually called, then wire it like SlashAcross
                local dist=pos and my and sq(dsq(my,pos)) or math.huge
                if dist<=(cfg.mp_detect or 32) and dist>=2 then
                    local last=mp_unk[nm] or 0
                    if oc()-last>2 then mp_unk[nm]=oc(); dlog("[mp scan] '"..nm.."' @ "..fl(dist).."st") end
                end
            end
        end
    end
end

local pgui_map={Cross="castigate",MonarchGlare="monarch",SiegeGlare="siege",PhoenixGlare="phoenix"}
local pg_delay={castigate="pg_cast",monarch="pg_mon",phoenix="pg_phx",siege="pg_siege"}

local function scan_pgui()
    if not cfg.gp then return end
    local pgui=lp and lp:FindFirstChild("PlayerGui"); if not pgui then return end
    local ve=pgui:FindFirstChild("VisualEffects") or try(function() return pgui:FindFirstChild("VisualEffects",true) end)
    if not ve then return end
    local now=oc()
    for eff_nm,gun in pairs(pgui_map) do
        local eff=ve:FindFirstChild(eff_nm); if not eff then continue end
        local ok_a,addr=pcall(function() return tostring(eff.Address) end); if not ok_a then continue end
        if pg_parried[addr] then continue end
        if not pg_seen[addr] then
            pg_seen[addr]=now; st.last_gun=gun; st.gun_t=ms()  -- glare seen, lock the gun early
            if shot and shot.claimed then
                if shot.gun~=gun then
                    local ns=calc_sched(gun,nil); local fire_at=(shot.t0 or ms())+ns
                    if shot.entry and not shot.entry.done then
                        shot.entry.gun=gun; shot.entry.fire_at=fire_at; shot.gun=gun
                        dlog("[gp] pgui glare reaim -> "..gun)
                    elseif fire_at>ms()+40 then  -- wrong press already fired, but real gun fires later -> queue it
                        shot.entry=enqueue_parry(fire_at-ms(),nil,gun,nil); shot.gun=gun
                        dlog("[gp] pgui glare requeue -> "..gun)
                    end
                end
                shot.certain=true  -- a real glare named it, dont let stale windows downgrade
            end
        end
        local elapsed=now-pg_seen[addr]
        local delay=(cfg[pg_delay[gun] or "pg_cast"] or 450)/1000
        if elapsed>=delay then
            pg_parried[addr]=true
            if not shot then new_shot() end
            maybe_reset_shot()
            if shot.claimed then dlog("[gp] pgui skip, claimed -> "..gun); continue end
            shot.claimed=true; shot.gun=gun; shot.certain=true; shot.t=ms(); shot.t0=ms()
            local _gun=gun
            task.spawn(function()
                dlog("[gp] F -> ".._gun.." (pgui)")
                if not gun_press() then return end  -- another path already parried this shot
                pg_last_press=ms()
            end)
        end
    end
    for addr,t in pairs(pg_seen) do
        if now-t>5 then pg_seen[addr]=nil; pg_parried[addr]=nil end
    end
end

local function scan_effects()
    local eff=try(function() return workspace:FindFirstChild("Effects") end)
    if eff then scan_folder(eff,seen_eff,false) end
    for _,fn in ipairs({"VisualEffects","LocalEffects","VFX","ClientEffects"}) do
        local f=try(function() return workspace:FindFirstChild(fn) end)
        if f then scan_folder(f,seen_vfx,true) end
    end
end

-- periodic cleanup
task.spawn(function()
    while loops_active do
        task.wait(5); local t=oc()
        for addr,at in next,seen_pt do if t-at>7 then seen_part[addr]=nil; seen_pt[addr]=nil end end
        -- note: seen_eff / seen_vfx are NOT aged out. a glare/effect can linger in the world for
        -- seconds, and ageing the dedup made it re-detect and spam parries. one effect = one detect.
        for k,exp in next,zone_win do if type(exp)=="number" and t-exp>5 then zone_win[k]=nil end end
        local now_ms=ms()
        for k,_ in next,att_gun do
            if now_ms-(att_gun_t[k] or 0)>att_gun_ttl then att_gun[k]=nil; att_gun_t[k]=nil end
        end
    end
end)

-- auto team detect
task.spawn(function()
    while loops_active do
        if not cfg.team and lp then
            local ok,t=pcall(function() return lp.Team end)
            if ok and t then cfg.team=true end
        end
        task.wait(3)
    end
end)

local draw_font=Drawing.Fonts.UI
local esp_obj={}; local esp_sp={}

local function rm_esp(p)
    local d=esp_obj[p]; if not d then return end
    for _,k in ipairs({"nm","hp","ps"}) do pcall(function() d[k]:Remove() end) end
    esp_obj[p]=nil; esp_sp[p]=nil
end
local function mk_esp(p)
    if esp_obj[p] then return end
    local function mk(col)
        local t=Drawing.new("Text"); t.Visible=false; t.Center=true
        t.Outline=true; t.Font=draw_font; t.Size=14; t.ZIndex=3; t.Color=col; return t
    end
    esp_obj[p]={
        nm=mk(Color3.fromRGB(cfg.esp_r,cfg.esp_g,cfg.esp_b)),
        hp=mk(Color3.fromRGB(80,255,120)),
        ps=mk(Color3.fromRGB(160,130,255)),
        root_char=nil, mhp=nil,
    }
end

task.spawn(function()
    while loops_active do
        if lp then
            local all=try(function() return plrs:GetPlayers() end) or {}; local set={}
            for _,p in ipairs(all) do set[p]=true; if not is_self(p) then mk_esp(p) end end
            for p in next,esp_obj do if not set[p] or is_self(p) then rm_esp(p) end end
        end
        task.wait(0.5)
    end
end)

local hud_obj=nil
local function mk_hud()
    if hud_obj then return end
    local function mk(col)
        local t=Drawing.new("Text"); t.Visible=false; t.Center=true
        t.Font=draw_font; t.Size=14; t.ZIndex=3; t.Color=col; return t
    end
    hud_obj={name=mk(Color3.fromRGB(100,200,255)),hp=mk(Color3.fromRGB(80,255,120)),ps=mk(Color3.fromRGB(255,210,60)),mhp=nil}
end
local function rm_hud()
    if not hud_obj then return end
    for _,k in ipairs({"name","hp","ps"}) do pcall(function() hud_obj[k]:Remove() end) end; hud_obj=nil
end

local fov_obj=nil
local function mk_fov()
    if fov_obj then return end
    fov_obj=Drawing.new("Circle"); fov_obj.Visible=false; fov_obj.Filled=false
    pcall(function() fov_obj.NumSides=96 end)  -- high side count so its actually round, no flat edges
    fov_obj.Color=Color3.fromRGB(255,255,255); fov_obj.Thickness=1.5; fov_obj.ZIndex=10
end
local function rm_fov()
    if fov_obj then pcall(function() fov_obj:Remove() end); fov_obj=nil end
end

local warn_obj=nil; local warn_corners={}
local function mk_warn()
    if warn_obj then return end
    warn_obj=Drawing.new("Square"); warn_obj.Visible=false; warn_obj.Filled=true
    warn_obj.Position=Vector2.new(0,0); warn_obj.Size=Vector2.new(20000,20000); warn_obj.ZIndex=20
end
local function mk_corners()
    if #warn_corners>0 then return end
    for _=1,4 do
        local s=Drawing.new("Square"); s.Visible=false; s.Filled=true; s.ZIndex=20
        warn_corners[#warn_corners+1]=s
    end
end

task.spawn(function()
    while loops_active do
        if cfg.hud then mk_hud() else rm_hud() end
        if cfg.sl and cfg.sl_fovs then mk_fov() end
        mk_warn(); mk_corners()
        task.wait(0.5)
    end
end)

local function hcol(pct)
    if pct>0.6 then return Color3.fromRGB(80,255,120)
    elseif pct>0.3 then return Color3.fromRGB(255,210,60)
    else return Color3.fromRGB(255,75,75) end
end

local esp_t=0; local tgt_vel={}

local function pred_pos(t)
    local ap=t.hpos or t.pos; if not ap then return nil end
    local cache=tgt_vel[t]; local now=tick()
    if cache and (now-cache.t)<0.5 then
        local dt=now-cache.t
        if dt>0 then
            local pred=(cfg.sl_pred or 8)/100
            local vx=(ap.X-cache.pos.X)/dt; local vy=(ap.Y-cache.pos.Y)/dt; local vz=(ap.Z-cache.pos.Z)/dt
            tgt_vel[t]={pos=ap,t=now}
            return Vector3.new(ap.X+vx*pred,ap.Y+vy*pred,ap.Z+vz*pred)
        end
    end
    tgt_vel[t]={pos=ap,t=now}; return ap
end

local function in_fov(sp)
    if not cfg.sl_fovf then return true end
    local cam=workspace.CurrentCamera; if not cam then return true end
    local vp=try(function() return cam.ViewportSize end); if not vp then return true end
    local dx=sp.X-vp.X/2; local dy=sp.Y-vp.Y/2
    local fov=cfg.sl_fov or 130
    return (dx*dx+dy*dy)<=(fov*fov)
end

local function update_esp()
    if not lp then return end
    local now=tick(); if now-esp_t<0.016 then return end; esp_t=now

    -- warn
    if tick()<warn_til then
        local frac=cl((warn_til-tick())/0.5,0,1)
        local base_a=cfg.warn_a or 0.3
        local alpha=base_a
        if cfg.warn_fade then alpha=base_a*frac end  -- start at the set value, fade down to 0
        if cfg.warn_blink then
            local bt=tick()-warn_blink_t; alpha=base_a*(0.5+0.5*abs(math.sin(bt*10)))
        end
        alpha=cl(alpha,0,base_a)
        local col=Color3.fromRGB(cfg.warn_r or 255,cfg.warn_g or 60,cfg.warn_b or 60)
        if cfg.warn_corner then
            if warn_obj then warn_obj.Visible=false end
            local cam=workspace.CurrentCamera
            local vp=cam and try(function() return cam.ViewportSize end) or Vector2.new(1920,1080)
            local csz=vp.X*0.22
            local cpos={{0,0},{vp.X-csz,0},{0,vp.Y-csz},{vp.X-csz,vp.Y-csz}}
            for i,s in ipairs(warn_corners) do
                s.Color=col; s.Transparency=alpha
                s.Position=Vector2.new(cpos[i][1],cpos[i][2])
                s.Size=Vector2.new(csz,csz); s.Visible=true
            end
        else
            for _,s in ipairs(warn_corners) do if s then s.Visible=false end end
            if warn_obj then warn_obj.Color=col; warn_obj.Transparency=alpha; warn_obj.Visible=true end
        end
    else
        if warn_obj then warn_obj.Visible=false end
        for _,s in ipairs(warn_corners) do if s then s.Visible=false end end
    end

    -- hud
    if hud_obj and cfg.hud then
        local ro=try(function() return lp:FindFirstChild("ReadOnly") end)
        local hv=ro and try(function() return ro:FindFirstChild("health") end)
        local hp=hv and try(function() return hv.Value end)
        if hud_obj.mhp==nil then
            local mhv=ro and (try(function() return ro:FindFirstChild("maxhealth") end) or try(function() return ro:FindFirstChild("MaxHealth") end))
            local v=mhv and try(function() return mhv.Value end)
            hud_obj.mhp=(v and v>0 and v) or 100
        end
        local iv=ro and try(function() return ro:FindFirstChild("impact") end)
        local imp=iv and try(function() return iv.Value end)
        local sz=cfg.hud_sz or 14; local x,y=cfg.hud_x or 960,cfg.hud_y or 975
        hud_obj.name.Size=sz; hud_obj.hp.Size=sz-1; hud_obj.ps.Size=sz-1
        hud_obj.name.Text=tostring(lp.Name); hud_obj.name.Position=Vector2.new(x,y); hud_obj.name.Visible=true
        if hp and hp>0 then
            local mhp=hud_obj.mhp or 100; local pct=cl(hp/mhp,0,1)
            hud_obj.hp.Text=fl(hp).." / "..fl(mhp).."  "..fl(pct*100).."%"
            hud_obj.hp.Color=hcol(pct); hud_obj.hp.Position=Vector2.new(x,y+sz+2); hud_obj.hp.Visible=true
        else hud_obj.hp.Visible=false end
        if imp~=nil then
            hud_obj.ps.Text="posture "..string.format("%.1f",imp)
            hud_obj.ps.Position=Vector2.new(x,y+(sz+2)*2); hud_obj.ps.Visible=true
        else hud_obj.ps.Visible=false end
    elseif hud_obj then
        hud_obj.name.Visible=false; hud_obj.hp.Visible=false; hud_obj.ps.Visible=false
    end

    -- fov
    if fov_obj then
        if cfg.sl and cfg.sl_fovs and cfg.sl_fovf then
            local cam=workspace.CurrentCamera; local vp=cam and try(function() return cam.ViewportSize end)
            if vp and (cfg.sl_fov or 0)>0 then
                fov_obj.Position=Vector2.new(vp.X/2,vp.Y/2); fov_obj.Radius=cfg.sl_fov; fov_obj.Visible=true
            else fov_obj.Visible=false end
        else fov_obj.Visible=false end
    end

    -- esp
    if not cfg.esp then
        for _,d in next,esp_obj do d.nm.Visible=false; d.hp.Visible=false; d.ps.Visible=false end
        return
    end
    local my_pos=get_pos()
    for p,d in next,esp_obj do
        local char=try(function() return p.Character end)
        if char~=d.root_char then
            d.root_char=char
            d.root=char and try(function() return char:FindFirstChild("HumanoidRootPart") end)
            d.mhp=nil
        end
        local root=d.root
        if not root then d.nm.Visible=false; d.hp.Visible=false; d.ps.Visible=false; continue end
        local rpos=try(function() return root.Position end)
        if not rpos then d.nm.Visible=false; d.hp.Visible=false; d.ps.Visible=false; continue end
        local rng=cfg.esp_rng or 500
        if rng>0 and my_pos and dsq(my_pos,rpos)>rng*rng then
            d.nm.Visible=false; d.hp.Visible=false; d.ps.Visible=false; continue
        end
        local ws_sp; local ws_ok=pcall(function() ws_sp,_=WorldToScreen(rpos+Vector3.new(0,2.5,0)) end)
        if not ws_ok or not ws_sp then d.nm.Visible=false; d.hp.Visible=false; d.ps.Visible=false; continue end
        local raw=Vector2.new(ws_sp.X,ws_sp.Y)
        local prev=esp_sp[p]
        if prev then
            local ddx=raw.X-prev.X; local ddy=raw.Y-prev.Y
            if ddx*ddx+ddy*ddy>1600 then esp_sp[p]=raw
            else raw=Vector2.new(prev.X+ddx*0.5,prev.Y+ddy*0.5); esp_sp[p]=raw end
        else esp_sp[p]=raw end
        local sx=raw.X; local sy=raw.Y-30; local sz=cfg.esp_sz or 14
        d.nm.Size=sz; d.hp.Size=sz-1; d.ps.Size=sz-1
        local ecol=Color3.fromRGB(cfg.esp_r,cfg.esp_g,cfg.esp_b)
        d.nm.Color=ecol; d.nm.Outline=true; d.hp.Outline=true; d.ps.Outline=true
        local ro=try(function() return p:FindFirstChild("ReadOnly") end)
        local hv=ro and try(function() return ro:FindFirstChild("health") end)
        local hp=hv and try(function() return hv.Value end)
        if d.mhp==nil then
            local mhv=ro and (try(function() return ro:FindFirstChild("maxhealth") end) or try(function() return ro:FindFirstChild("MaxHealth") end))
            local v=mhv and try(function() return mhv.Value end); d.mhp=(v and v>0 and v) or 100
        end
        local iv=ro and try(function() return ro:FindFirstChild("impact") end)
        local imp=iv and try(function() return iv.Value end)
        if cfg.esp_name then d.nm.Text=tostring(p.Name); d.nm.Position=Vector2.new(sx,sy); d.nm.Visible=true else d.nm.Visible=false end
        if cfg.esp_hp and hp and hp>0 then
            local mhp=d.mhp or 100
            d.hp.Text=fl(hp).." / "..fl(mhp)
            if cfg.esp_dist and my_pos then d.hp.Text=d.hp.Text.."  "..fl(sq(dsq(my_pos,rpos))).."st" end
            d.hp.Color=hcol(cl(hp/mhp,0,1)); d.hp.Position=Vector2.new(sx,sy+sz+2); d.hp.Visible=true
        else d.hp.Visible=false end
        if cfg.esp_pos and imp~=nil then
            d.ps.Text="p "..string.format("%.1f",imp); d.ps.Position=Vector2.new(sx,sy+(sz+2)*2); d.ps.Visible=true
        else d.ps.Visible=false end
    end
end

local hb_seen={}; local hb_last_scan=0
local hb_orig=setmetatable({},{__mode="k"})  -- original sizes so toggling off restores them
local function restore_hurtboxes()
    for obj,sz in pairs(hb_orig) do pcall(function() obj.Size=sz end) end
    hb_seen={}
end

local function scan_hurtboxes(force, aura_sz)
    if (not cfg.hb or not st.hb_on) and not force then return end
    local now=tick()
    if not force and now-hb_last_scan<5 then return end
    hb_last_scan=now
    local sz=(aura_sz and aura_sz>0 and aura_sz) or cfg.hb_size or 8; local n=0
    local me=get_char()
    for _,p in ipairs(try(function() return plrs:GetPlayers() end) or {}) do
        if is_self(p) or not is_enemy(p) then continue end
        local char=try(function() return p.Character end); if not char then continue end
        if char==me then continue end
        local ok,desc=pcall(function() return char:GetDescendants() end); if not ok then continue end
        for _,obj in ipairs(desc) do
            if not obj:IsA("BasePart") then continue end
            if obj.Name~="Torso_Hurtbox" then continue end
            if hb_seen[obj] and not force then continue end
            hb_seen[obj]=true
            if not hb_orig[obj] then hb_orig[obj]=try(function() return obj.Size end) end
            pcall(function() obj.Size=Vector3.new(sz,sz,sz) end)
            n=n+1
        end
    end
    if n>0 and not aura_sz then dlog("[hb] "..n.." player hurtboxes sz="..sz) end
end

local function try_aura()
    if not cfg.aura then aura_pending=false; return end
    local now=tick(); if now-st.aura_t<(cfg.aura_cd or 15)/100 then return end
    local my=get_pos(); if not my then return end
    local rsq=(cfg.aura_rng or 23)^2
    local best,bd=nil,math.huge
    for _,t in ipairs(tgts_cached()) do
        if hdsq(my,t.pos)>rsq then continue end
        local d=dsq(my,t.pos); if d<bd then bd=d; best=t end
    end
    if not best then
        if cfg.aura_hb and not cfg.hb then restore_hurtboxes() end
        return
    end
    st.aura_t=now; aura_pending=true
    local _name=best.name or "?"
    task.spawn(function()
        if cfg.aura_hb then scan_hurtboxes(true, cfg.aura_rng) end
        if not aura_pending then return end
        pcall(mouse1click)
        aura_pending=false
        dlog("[aura] -> ".._name)
        if cfg.aura_hb and not cfg.hb then task.wait(0.15); restore_hurtboxes() end
    end)
end

-- pick the live part to aim at (head or body) straight off the character each frame
local function aim_part(char)
    if not char then return nil end
    if cfg.sl_part=="body" then
        return try(function() return char:FindFirstChild("UpperTorso") end)
            or try(function() return char:FindFirstChild("Torso") end)
            or try(function() return char:FindFirstChild("LowerTorso") end)
            or try(function() return char:FindFirstChild("HumanoidRootPart") end)
            or try(function() return char.PrimaryPart end)
            or try(function() return char:FindFirstChild("Head") end)
    end
    return try(function() return char:FindFirstChild("Head") end)
        or try(function() return char:FindFirstChild("HumanoidRootPart") end)
        or try(function() return char.PrimaryPart end)
        or try(function() return char:FindFirstChildWhichIsA("BasePart") end)
end

local function live_aim_pos(t)
    if not t then return nil end
    local char=t.char
    if char and not try(function() return char.Parent end) then return nil end
    local part=aim_part(char) or t.root
    if not part then return t.hpos or t.pos end
    local p=try(function() return part.Position end)
    if not p then return t.hpos or t.pos end
    -- if we only got the root/anchor (not the actual head/torso part), the root often sits
    -- low or at the feet, so nudge up to head/torso height. stops it aiming at the ground.
    local nm=try(function() return part.Name end) or ""
    if nm~="Head" and nm~="UpperTorso" and nm~="Torso" and nm~="LowerTorso" then
        local up=(cfg.sl_part=="body") and 1.5 or 2.6
        p=p+Vector3.new(0,up,0)
    end
    return p
end

local function sl_pick()
    local tgts=tgts_cached(); if #tgts==0 then return nil end  -- shared cache, no per-frame workspace walk
    local my=get_pos(); local best,bd=nil,math.huge
    for _,t in ipairs(tgts) do
        local dv=cfg.sl_dist or 500
        if dv>0 and my and sq(dsq(my,t.pos))>dv then continue end
        local ap=pred_pos(t) or t.hpos
        if cfg.sl_fovf then
            local ok_sp,scr=pcall(WorldToScreen,ap)
            if ok_sp and scr and type(scr)~="boolean" then if not in_fov(scr) then continue end end
        end
        local d=my and dsq(my,t.pos) or math.huge; if d<bd then bd=d; best=t end
    end
    return best
end

local function do_sl()
    if not cfg.sl then st.sl_on=false; st.sl_tgt=nil; return end
    if not st.sl_on then return end
    if tick()>st.sl_til then st.sl_on=false; st.sl_tgt=nil; return end
    if not st.sl_tgt then
        local t=sl_pick(); if not t then return end
        st.sl_tgt=t
    end
    local t=st.sl_tgt; if not t then return end
    local ap=live_aim_pos(t); if not ap then st.sl_tgt=nil; return end  -- read fresh pos, drop dead target
    local cam=workspace.CurrentCamera; if not cam then return end
    local vp=try(function() return cam.ViewportSize end); if not vp then return end
    local ok_sp,sp,on=pcall(WorldToScreen,ap)
    if not ok_sp or not sp or type(sp)=="boolean" then return end
    if on==false then return end  -- target behind camera, dont fling the mouse
    local str=cl((cfg.sl_str or 15)/100,0.01,1)
    local dx=(sp.X-vp.X/2)*str; local dy=(sp.Y-vp.Y/2)*str
    local spd=sq(dx*dx+dy*dy); local sv=cfg.sl_spd or 18
    if sv>0 and spd>sv then local s=sv/spd; dx=dx*s; dy=dy*s end
    if type(mousemoverel)=="function" and (abs(dx)>0.3 or abs(dy)>0.3) then pcall(mousemoverel,0,fl(dx),fl(dy)) end
end

local esp_acc=0

-- soft reload: clear all stuck per-shot state + effect dedup. matcha has no console clear,
-- so this also prints a divider so the old areas spam is visually cut off.
local function soft_reset(tag)
    shot=nil; parry_queue={}; miss_n=0; gp_lock=0; siege_s2_t=0
    phx_log.active=false; st.last_gun="castigate"; aura_pending=false
    seen_eff={}; seen_vfx={}; seen_part={}; seen_pt={}
    zone_win={}; active_z={}; win_last={}; pg_seen={}; pg_parried={}
    att_gun={}; att_gun_t={}
    log("[rl] ======== "..(tag or "reload").." ======== state cleared")
end

-- teleport watch: a big position jump in one tick = you got teleported (new round/area).
-- wipe stale state so old effects dont fire phantom parries in the new spot.
task.spawn(function()
    local last_p
    while loops_active do
        local p=get_pos()
        if p and last_p and sq(dsq(p,last_p))>250 then soft_reset("teleport") end
        last_p=p
        task.wait(0.2)
    end
end)

run.RenderStepped:Connect(function(dt)
    if not loops_active then return end
    esp_acc=esp_acc+(dt or 0)
    if esp_acc<0.016 then return end  -- cap esp redraw ~60hz, saves work on high refresh screens
    esp_acc=0
    update_esp()
end)

-- main detect loop (runs at _G.FPS hz)
-- parry detection needs to be fast (glares are brief), so this stays at full rate
task.spawn(function()
    while loops_active do
        scan_effects()
        scan_pgui()
        task.wait(1/get_fps())
    end
end)

-- aura + hitbox dont need 120hz. running them ~30hz cuts a ton of load
task.spawn(function()
    while loops_active do
        scan_hurtboxes()
        try_aura()
        task.wait(0.033)
    end
end)

-- memory melee: read each nearby enemys playing animation ids and parry if a melee id is up.
-- ~20hz, nearest enemies only, so the memory walk stays cheap. debug logs every id it reads.
task.spawn(function()
    while loops_active do
        if cfg.mp and (cfg.mp_anim or cfg.mp_anim_dbg) and mem_on then
            local my=get_pos()
            if my then
                for _,t in ipairs(tgts_cached()) do
                    local d=sq(dsq(my,t.pos))
                    if d<=(cfg.mp_detect or 32) then
                        local anr=animator_of(t.char)
                        if anr then
                            for _,id in ipairs(active_anim_ids(anr)) do
                                if cfg.mp_anim_dbg then dlog("[mp anim] "..(t.name or "?").." "..fl(d).."st | "..id) end
                                if cfg.mp_anim and melee_anims[id] then
                                    dlog("[mp anim] MELEE id matched -> parry")
                                    try_melee(); break
                                end
                            end
                        end
                    end
                end
            end
        end
        task.wait(0.05)
    end
end)

-- auto ping (GetPingValue is the only ping that works on matcha; Stats returns 0)
task.spawn(function()
    while loops_active do
        if cfg.auto_ping and type(GetPingValue)=="function" then
            local ok,p=pcall(GetPingValue)
            if ok and tonumber(p) and p>0 then cfg.ping=cl(fl(p),0,2000) end  -- real ping, not capped at old 400
        end
        task.wait(2)
    end
end)

-- silent aim hold loop
task.spawn(function()
    while loops_active do
        if cfg.sl then
            local held=try(function() return iskeypressed(khex(cfg.sl_key)) end) or false
            if held then
                if not st.sl_tgt then
                    local tgt=sl_pick()
                    if tgt then st.sl_on=true; st.sl_tgt=tgt end
                end
                if st.sl_on then st.sl_til=tick()+(cfg.sl_dur or 14)/10 end
            end
        end
        do_sl(); task.wait(1/get_fps())
    end
end)

_G.rl_cleanup=function()
    loops_active=false
    rm_hud(); rm_fov()
    if warn_obj then pcall(function() warn_obj:Remove() end); warn_obj=nil end
    for _,s in ipairs(warn_corners) do pcall(function() s:Remove() end) end; warn_corners={}
    for _,d in next,esp_obj do
        for _,k in ipairs({"nm","hp","ps"}) do pcall(function() d[k]:Remove() end) end
    end
    esp_obj={}; esp_sp={}; tgt_vel={}; att_gun={}; att_gun_t={}
    seen_eff={}; seen_vfx={}; seen_part={}; seen_pt={}; zone_win={}
    parry_queue={}; hb_seen={}
end

-- ui (MatchaUI lib via ForMatcha-Testing loader)
-- no scroll frames. every tab is short enough to fit the window, so we use real
-- section headers + direct widgets. cleaner and no scroll bugs.
task.spawn(function()
    -- wait until the game + our character are fully in before building the menu (less load lag)
    repeat task.wait(0.1) until lp
    pcall(function() if not game:IsLoaded() then game.Loaded:Wait() end end)
    repeat task.wait(0.1) until get_char() and get_root()
    task.wait(0.5)

    local cam=workspace.CurrentCamera
    local vp=cam and try(function() return cam.ViewportSize end)
    if vp then cfg.hud_x=fl(vp.X/2); cfg.hud_y=fl(vp.Y*0.90) end

    cfg_load()
    set_warn_style(cfg.warn_style)

    local src=try(function() return game:HttpGet("https://raw.githubusercontent.com/shystemcito/ForMatcha-Testing/refs/heads/main/Libs/Loader.luau") end)
    if type(src)~="string" or #src<50 then rn("UI loader fetch failed","Redline",8); return end
    local fn=loadstring("MatchaLib = (function()\n"..src.."\nend)()")
    if not fn then rn("UI loader compile failed","Redline",8); return end
    pcall(fn)
    local UiLib=MatchaLib and try(function() return MatchaLib.load("MatchaUI") end)
    if type(UiLib)~="table" then rn("MatchaUI load failed","Redline",8); return end

    local Window=UiLib.CreateWindow({
        Title  = "Redline  v21   |   koji_xyz",
        X      = 70,
        Y      = 50,
        Width  = 640,
        Height = 640,
        ZIndex = 100,
    })
    pcall(function() Window.SetVisible(false) end)  -- build hidden, show once everything is in

    -- full theme engine: each theme repaints the whole ui, not just the accent
    local function mix(r1,g1,b1,r2,g2,b2,t)
        return Color3.fromRGB(fl(r1+(r2-r1)*t), fl(g1+(g2-g1)*t), fl(b1+(b2-b1)*t))
    end
    local function stk(k,col) pcall(function() UiLib.SetThemeColor(k,col) end) end
    local function apply_theme(name)
        local td=themes[name] or themes.purple
        cfg.esp_r=td.esp[1]; cfg.esp_g=td.esp[2]; cfg.esp_b=td.esp[3]
        if fov_obj then pcall(function() fov_obj.Color=Color3.fromRGB(td.fov[1],td.fov[2],td.fov[3]) end) end
        local ar,ag,ab=td.fov[1],td.fov[2],td.fov[3]
        local function tint(t) return mix(12,12,16, ar,ag,ab, t) end
        pcall(function() UiLib.SetAccentColor(Color3.fromRGB(ar,ag,ab)) end)
        stk("Background", tint(0.04));     stk("ContentBg", tint(0.05))
        stk("TopBar", tint(0.11));         stk("LeftBar", tint(0.08))
        stk("ElementBg", tint(0.16));      stk("ElementBorder", tint(0.30))
        stk("CategoryHover", tint(0.22));  stk("CategoryText", Color3.fromRGB(232,232,240))
        stk("AccentOff", tint(0.32));      stk("TextPrimary", Color3.fromRGB(242,242,248))
        stk("TextSecondary", Color3.fromRGB(182,182,196)); stk("TextDisabled", Color3.fromRGB(112,112,126))
        stk("SliderTrack", tint(0.24));    stk("SliderKnob", Color3.fromRGB(240,240,246))
        stk("DropdownBg", tint(0.11));     stk("DropdownItem", tint(0.07))
        stk("DropdownHover", tint(0.26));  stk("InputBg", tint(0.07))
        stk("TooltipBg", tint(0.02));      stk("NotifBg", tint(0.13))
        stk("ScrollBar", tint(0.20));      stk("ScrollThumb", Color3.fromRGB(ar,ag,ab))
        stk("TitleText", Color3.fromRGB(246,246,251)); stk("SectionHeader", tint(0.34))
    end

    local sl_keys={"q","e","r","t","g","h","z","x","c","v","f1","f2","f3","lshift","capslock"}
    local warn_opts={"fade","solid","blink","corner_fade","corner_solid","corner_blink"}
    local kbMenu, kbHb

    local function reset_cfg()
        deep_copy(cfg_defaults, cfg)
        apply_theme(cfg.theme)
        cfg_save()
        pcall(function() UiLib.Notify("Redline","config reset to default  (reinject to refresh menu)",4) end)
    end

    -- attach a hover tooltip to a widget handle
    local function tip(h, txt) if h then pcall(function() Window.AddTooltip(h, txt) end) end return h end

    -- gun parry
    pcall(function()
        local c=Window.AddCategory("Gun Parry")
        Window.AddSection(c,"Gun Parry")
        Window.AddToggle(c,"Enable",cfg.gp,function(s) cfg.gp=s; mark_chg() end)
        tip(Window.AddToggle(c,"Training mode",cfg.training,function(s) cfg.training=s; mark_chg() end),"also target training dummies and bots, not just real players")
        tip(Window.AddToggle(c,"Glint aim",cfg.gp_aim,function(s) cfg.gp_aim=s; mark_chg() end),"snap your crosshair toward the shooter when it parries a gun")
        Window.AddToggle(c,"Incoming warn",cfg.warn,function(s) cfg.warn=s; mark_chg() end)
        tip(Window.AddToggle(c,"Debug logs",cfg.debug,function(s) cfg.debug=s; mark_chg() end),"log detects and internals in the console. still parries normally")
        tip(Window.AddSlider(c,"Castigate delay",50,1500,cfg.pg_cast,function(v) cfg.pg_cast=fl(v); mark_chg() end),"ms to wait after a castigate shot is seen before parrying")
        Window.AddSlider(c,"Monarch delay",200,3000,cfg.pg_mon,function(v) cfg.pg_mon=fl(v); mark_chg() end)
        Window.AddSlider(c,"Siege delay",50,2500,cfg.pg_siege,function(v) cfg.pg_siege=fl(v); mark_chg() end)
        Window.AddSlider(c,"Phoenix delay",50,2000,cfg.pg_phx,function(v) cfg.pg_phx=fl(v); mark_chg() end)
        tip(Window.AddToggle(c,"Siege 2nd parry",cfg.s2,function(s) cfg.s2=s; mark_chg() end),"siege fires twice. this handles the follow-up parry")
        tip(Window.AddSlider(c,"Siege gap",200,2500,cfg.s2_w2f,function(v) cfg.s2_w2f=fl(v); mark_chg() end),"time between siege's first and second shot")
    end)

    -- melee parry
    pcall(function()
        local c=Window.AddCategory("Melee Parry")
        Window.AddSection(c,"Melee Parry")
        Window.AddToggle(c,"Enable",cfg.mp,function(s) cfg.mp=s; mark_chg() end)
        Window.AddSlider(c,"Cooldown ms",50,1000,cfg.mp_cd,function(v) cfg.mp_cd=fl(v); mark_chg() end)
        tip(Window.AddSlider(c,"Facing angle",5,180,cfg.mp_ang,function(v) cfg.mp_ang=fl(v); mark_chg() end),"only parry swings from attackers facing you within this angle")
        Window.AddSlider(c,"Parry range",1,60,cfg.mp_maxd,function(v) cfg.mp_maxd=fl(v); mark_chg() end)
        tip(Window.AddSlider(c,"Early detect",5,80,cfg.mp_detect,function(v) cfg.mp_detect=fl(v); mark_chg() end),"start watching for a melee swing from this far away")
        tip(Window.AddSlider(c,"Valid window ms",80,600,cfg.mp_window,function(v) cfg.mp_window=fl(v); mark_chg() end),"how long a detected swing stays parryable")
        tip(Window.AddToggle(c,"Swing name scan",cfg.mp_scan,function(s) cfg.mp_scan=s; mark_chg() end),"debug: logs any unknown effect near you. swing a melee at the bot and read the name to wire it up")
        Window.AddSection(c,"Memory Animation Melee")
        tip(Window.AddToggle(c,"Anim melee (memory)",cfg.mp_anim,function(s) cfg.mp_anim=s; mark_chg() end),"reads enemy animation ids from memory (theo offsets) and parries known melee swings. needs unsafe execution enabled")
        tip(Window.AddToggle(c,"Anim debug (log ids)",cfg.mp_anim_dbg,function(s) cfg.mp_anim_dbg=s; mark_chg() end),"logs every animation id read off nearby enemies. swing at the bot to capture the real melee ids, then add them")
        tip(Window.AddToggle(c,"Dump attributes (debug)",false,function(s)
            if not s then return end
            local ch=get_char()
            local tool=ch and try(function() return ch:FindFirstChildOfClass("Tool") end)
            if tool then dump_attrs(tool,"tool:"..(try(function() return tool.Name end) or "?")) end
            if ch then dump_attrs(ch,"character") end
            if lp then dump_attrs(lp,"player") end
        end),"equip your gun, flip this on, then paste the [attr] output so the value layout can be decoded")
    end)

    -- parry tuning
    pcall(function()
        local c=Window.AddCategory("Tuning")
        Window.AddSection(c,"Parry Tuning")
        tip(Window.AddSlider(c,"Max detect",10,2500,cfg.gp_dist,function(v) cfg.gp_dist=fl(v); mark_chg() end),"max distance a gun shot is detected from. raise this for far shots")
        tip(Window.AddSlider(c,"Glare range",1,150,cfg.glare_d,function(v) cfg.glare_d=fl(v); mark_chg() end),"max distance a gun's glare wind-up effect counts")
        tip(Window.AddSlider(c,"Castigate margin",0,600,cfg.mg.castigate,function(v) cfg.mg.castigate=fl(v); mark_chg() end),"press F this many ms earlier than calculated (lag comp)")
        Window.AddSlider(c,"Monarch margin",0,600,cfg.mg.monarch,function(v) cfg.mg.monarch=fl(v); mark_chg() end)
        Window.AddSlider(c,"Siege margin",0,600,cfg.mg.siege,function(v) cfg.mg.siege=fl(v); mark_chg() end)
        Window.AddSlider(c,"Phoenix margin",0,600,cfg.mg.phoenix,function(v) cfg.mg.phoenix=fl(v); mark_chg() end)
    end)

    -- soft aim
    pcall(function()
        local c=Window.AddCategory("Aim")
        Window.AddSection(c,"Soft Aim")
        Window.AddToggle(c,"Enable",cfg.sl,function(s) cfg.sl=s; if not s then rm_fov(); st.sl_on=false end; mark_chg() end)
        tip(Window.AddDropdown(c,"Aim part",{"head","body"},cfg.sl_part,function(sel) cfg.sl_part=sel; mark_chg() end),"aim at the head or the torso")
        tip(Window.AddToggle(c,"FOV filter",cfg.sl_fovf,function(s) cfg.sl_fovf=s; if not s then rm_fov() end; mark_chg() end),"only target enemies inside the FOV circle")
        Window.AddToggle(c,"Show FOV circle",cfg.sl_fovs,function(s) cfg.sl_fovs=s; if not s then rm_fov() end; mark_chg() end)
        tip(Window.AddSlider(c,"Strength",1,100,cfg.sl_str,function(v) cfg.sl_str=fl(v); mark_chg() end),"how hard it pulls your aim each tick. higher = snappier")
        tip(Window.AddSlider(c,"Max speed",0,100,cfg.sl_spd,function(v) cfg.sl_spd=fl(v); mark_chg() end),"caps how fast the aim moves. lower = smoother, 0 = uncapped")
        tip(Window.AddSlider(c,"Hold time",1,50,cfg.sl_dur,function(v) cfg.sl_dur=fl(v); mark_chg() end),"how long aim stays locked after you release the key (x100ms)")
        Window.AddSlider(c,"FOV radius",10,600,cfg.sl_fov,function(v) cfg.sl_fov=fl(v); mark_chg() end)
        Window.AddSlider(c,"Max dist",10,1000,cfg.sl_dist,function(v) cfg.sl_dist=fl(v); mark_chg() end)
        Window.AddDropdown(c,"SA hold key",sl_keys,cfg.sl_key,function(sel) cfg.sl_key=sel; mark_chg() end)
    end)

    -- aura + hitbox
    pcall(function()
        local c=Window.AddCategory("Combat")
        Window.AddSection(c,"Aura")
        Window.AddToggle(c,"Enable",cfg.aura,function(s) cfg.aura=s; mark_chg() end)
        tip(Window.AddToggle(c,"Cancel on opp parry",cfg.aura_cancel,function(s) cfg.aura_cancel=s; mark_chg() end),"stop your aura swing if the enemy parries first")
        tip(Window.AddToggle(c,"Hitbox mode",cfg.aura_hb,function(s) cfg.aura_hb=s; if not s then restore_hurtboxes() end; mark_chg() end),"expand enemy hitboxes right as aura swings so it lands easier. size matches aura range. auto-clears when off or no target")
        Window.AddSlider(c,"Range",1,100,cfg.aura_rng,function(v) cfg.aura_rng=fl(v); mark_chg() end)
        Window.AddSlider(c,"Cooldown x10ms",1,200,cfg.aura_cd,function(v) cfg.aura_cd=fl(v); mark_chg() end)
        Window.AddSection(c,"Hitbox Expander")
        tip(Window.AddToggle(c,"Enable hitbox",cfg.hb,function(s) cfg.hb=s; if s then st.hb_on=true; hb_last_scan=0 else restore_hurtboxes() end; mark_chg() end),"master switch. when on, hitbox stays active until you tap the toggle key")
        kbHb=Window.AddKeybind(c,"Hitbox toggle key",0x48,function(k,n) rn("hitbox key set","Redline",2) end)
        tip(kbHb,"only works while Enable hitbox is on. taps hitbox off and back on")
        Window.AddSlider(c,"Hitbox size",1,50,cfg.hb_size,function(v) cfg.hb_size=fl(v); hb_last_scan=0; hb_seen={}; mark_chg() end)
    end)

    -- esp + hud
    pcall(function()
        local c=Window.AddCategory("ESP")
        Window.AddSection(c,"Enemy ESP")
        Window.AddToggle(c,"Enable",cfg.esp,function(s) cfg.esp=s; mark_chg() end)
        Window.AddToggle(c,"Name",cfg.esp_name,function(s) cfg.esp_name=s; mark_chg() end)
        Window.AddToggle(c,"Health",cfg.esp_hp,function(s) cfg.esp_hp=s; mark_chg() end)
        Window.AddToggle(c,"Posture",cfg.esp_pos,function(s) cfg.esp_pos=s; mark_chg() end)
        Window.AddToggle(c,"Distance",cfg.esp_dist,function(s) cfg.esp_dist=s; mark_chg() end)
        Window.AddSlider(c,"Range",10,1500,cfg.esp_rng,function(v) cfg.esp_rng=fl(v); mark_chg() end)
        Window.AddSlider(c,"Font size",8,30,cfg.esp_sz,function(v) cfg.esp_sz=fl(v); mark_chg() end)
        Window.AddColorPicker(c,"ESP color",Color3.fromRGB(cfg.esp_r,cfg.esp_g,cfg.esp_b),function(co)
            cfg.esp_r=fl(co.R*255); cfg.esp_g=fl(co.G*255); cfg.esp_b=fl(co.B*255); mark_chg()
        end)
        Window.AddSection(c,"Self HUD")
        Window.AddToggle(c,"Enable",cfg.hud,function(s) cfg.hud=s; if not s then rm_hud() end; mark_chg() end)
        Window.AddSlider(c,"Font size",8,32,cfg.hud_sz,function(v) cfg.hud_sz=fl(v); mark_chg() end)
        Window.AddSlider(c,"X center",0,3840,cfg.hud_x,function(v) cfg.hud_x=fl(v); mark_chg() end)
        Window.AddSlider(c,"Y pos",0,2160,cfg.hud_y,function(v) cfg.hud_y=fl(v); mark_chg() end)
    end)

    -- warn
    pcall(function()
        local c=Window.AddCategory("Warn")
        Window.AddSection(c,"Incoming Flash")
        Window.AddToggle(c,"Enable",cfg.warn,function(s) cfg.warn=s; mark_chg() end)
        Window.AddDropdown(c,"Style",warn_opts,cfg.warn_style,function(sel) cfg.warn_style=sel; set_warn_style(sel); mark_chg() end)
        Window.AddSlider(c,"Transparency %",0,95,fl((cfg.warn_a or 0.3)*100),function(v) cfg.warn_a=fl(v)/100; mark_chg() end)
        tip(Window.AddSlider(c,"Aim cone angle",20,180,cfg.warn_ang,function(v) cfg.warn_ang=fl(v); mark_chg() end),"only warn when the shooter is pointed at you within this angle")
        Window.AddColorPicker(c,"Flash color",Color3.fromRGB(cfg.warn_r,cfg.warn_g,cfg.warn_b),function(co)
            cfg.warn_r=fl(co.R*255); cfg.warn_g=fl(co.G*255); cfg.warn_b=fl(co.B*255); mark_chg()
        end)
    end)

    -- config
    pcall(function()
        local c=Window.AddCategory("Config")
        Window.AddSection(c,"Theme")
        Window.AddDropdown(c,"Color theme",theme_list,cfg.theme,function(sel) cfg.theme=sel; apply_theme(sel); mark_chg() end)
        kbMenu=Window.AddKeybind(c,"Menu toggle key",0x11,function(k,n) rn("menu key set","Redline",2) end)
        Window.AddSection(c,"Config")
        tip(Window.AddToggle(c,"Auto save (2s)",cfg.auto_save,function(s) cfg.auto_save=s end),"saves your settings 2s after any change")
        Window.AddButton(c,"Save config",function() cfg_save() end)
        tip(Window.AddButton(c,"Reset to defaults",function() reset_cfg() end),"reset every setting. reinject to refresh the menu sliders")
        Window.AddSection(c,"Network")
        Window.AddToggle(c,"Auto ping",cfg.auto_ping,function(s) cfg.auto_ping=s; mark_chg() end)
        local ping_now=0; pcall(function() if type(GetPingValue)=="function" then local okp,pv=pcall(GetPingValue); if okp and tonumber(pv) then ping_now=fl(pv) end end end)
        local ping_max=mx(400,ping_now+150)  -- high-ping players can slide past 400
        Window.AddSlider(c,"Ping ms",0,ping_max,cl(cfg.ping,0,ping_max),function(v) cfg.ping=fl(v); mark_chg() end)
        Window.AddSection(c,"Credits")
        Window.AddValueLabel(c,"Main dev","koji")
        Window.AddValueLabel(c,"Testers","Leo / zq")
    end)

    apply_theme(cfg.theme)
    pcall(function() Window.SetVisible(true) end)  -- everything built, now show it

    -- menu toggle key (Ctrl default, rebind in Config)
    task.spawn(function()
        local last=false
        while loops_active do
            local active=false; pcall(function() active=isrbxactive() end)
            if active then
                local vk=(kbMenu and kbMenu.Key) or 0x11
                local dn=false; pcall(function() dn=iskeypressed(vk) end)
                if dn and not last then pcall(function() Window.SetVisible(not Window.Visible) end) end
                last=dn
            end
            task.wait(0.05)
        end
    end)

    -- hitbox toggle key (H default, rebind in Combat)
    task.spawn(function()
        local last=false
        while loops_active do
            local active=false; pcall(function() active=isrbxactive() end)
            if active then
                local vk=(kbHb and kbHb.Key) or 0x48
                local dn=false; pcall(function() dn=iskeypressed(vk) end)
                if dn and not last then
                    if cfg.hb then
                        st.hb_on=not st.hb_on
                        if st.hb_on then hb_last_scan=0 else restore_hurtboxes() end
                        pcall(function() UiLib.Notify("Redline","hitbox "..(st.hb_on and "ON" or "OFF"),1) end)
                    end
                end
                last=dn
            end
            task.wait(0.05)
        end
    end)

    -- autosave
    task.spawn(function()
        while loops_active do
            if cfg.auto_save and cfg_changed and (oc()-chg_t)>2 then cfg_save() end
            task.wait(1)
        end
    end)

    pcall(function() UiLib.Notify("Redline","loaded  |  koji_xyz  (Ctrl = menu)",5) end)
    log("[rl] v21 | MatchaUI | fps "..get_fps())

    UiLib.Run()
end)