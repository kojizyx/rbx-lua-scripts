-- redline.lua | koji_xyz | v34
-- UI: INS-ui | inspecter or some fag nigger shit

if _G.rl_cleanup then pcall(_G.rl_cleanup); task.wait(0.1) end

local _notify = notify
local function rn(t, m, d)
    if cfg and (cfg.notify==false or cfg.streamer~=false) then return end
    pcall(_notify, t, m, d)
end
rn("loading...","Redline",3)

local plrs = game:GetService("Players")
local run  = game:GetService("RunService")
local lp   = plrs.LocalPlayer

local fl=math.floor; local sq=math.sqrt; local ac=math.acos; local sin=math.sin
local dg=math.deg; local cl=math.clamp; local mx=math.max; local oc=os.clock
local abs=math.abs

local function try(f) local ok,r=pcall(f); return ok and r or nil end
local function ms() return oc()*1000 end
local function log(...) pcall(print,...) end

local function read_ping()
    local fn=rawget(_G,"GetPingValue")
    if type(fn)~="function" then fn=try(function() return GetPingValue end) end
    if type(fn)=="function" then
        local ok,p=pcall(fn)
        p=ok and tonumber(p) or nil
        if p and p>0 then
            if p<3 then p=p*1000 end
            return cl(fl(p),1,2000)
        end
    end
    local v=try(function()
        local stats=game:GetService("Stats")
        local item=stats.Network.ServerStatsItem["Data Ping"]
        if not item then return nil end
        if item.GetValue then return item:GetValue() end
        return item.Value
    end)
    v=tonumber(v)
    if v and v>0 then
        if v<3 then v=v*1000 end
        return cl(fl(v),1,2000)
    end
    return nil
end

-- fps
getfenv().FPS = 120
local function get_fps()
    local f = tonumber(_G.FPS) or 120
    if f < 15 then f = 15 end
    if f > 360 then f = 360 end
    return f
end

local w2f = {monarch=1906, phoenix=833, siege=1162, castigate=800}

local CFG_VER = 29

local cfg_defaults = {
    cfg_ver=CFG_VER,
    ents="Entities", ping=47, auto_ping=true,
    gp=true, gp_aim=true, gp_los=true, parry_los=true, gp_dist=610, gp_lead=10,
    face_chk=false, face_ang=100,
    pg_cast=170, pg_mon=1700, pg_phx=500, pg_siege=380,
    glare_d=150, debug=false,
    warn=true, warn_ang=60,
    warn_r=255, warn_g=60, warn_b=60,
    warn_a=0.42, warn_corner=false, warn_blink=false, warn_fade=false,
    warn_style='solid',
    mg={monarch=200, castigate=200, phoenix=200, siege=300},
    s2=true, s2_w2f=1000,
    phx_spd=80, phx_pct=0, phx_lead=60, phx_radius=30, phx_rocket=true,
    cas_spd=360,
    mp=true, mp_cd=500, mp_ang=90, mp_maxd=20, mp_detect=32, mp_window=220, mp_scan=false, mp_anim=false, mp_anim_dbg=false,
    sl=false, sl_key='q', sl_str=42, sl_spd=72, sl_dur=14, sl_mem=true,
    sl_dist=500, sl_fov=130, sl_fovs=true, sl_fovf=true,
    sl_pred=8, sl_part='head',
    aura=false, aura_rng=23, aura_cd=15, aura_key="none",
    aura_cancel=true,
    aura_hb=false,
    esp=true, esp_name=true, esp_hp=true, esp_pos=true, esp_out=true,
    esp_box=true, esp_chams=false,
    esp_sz=14, esp_rng=500, esp_dist=true,
    esp_draw_iv=0, esp_sync_iv=0.15,
    esp_r=220, esp_g=170, esp_b=255,
    lobby_places={94987506187454},
    twov2_places={126691165749976},
    fov_r=220, fov_g=170, fov_b=255,
    hb=false, hb_size=8, hb_rng=0, hb_key="h",
    hud=true, hud_sz=24, hud_x=960, hud_y=975,
    team=false, training=false,
    theme='Grape',
    ui_font='Minecraft',
    ui_w=840, ui_h=720,
    auto_save=true, notify=true,
    menu_key='rctrl', show_keybinds=false, streamer=true,
    spd=false, spd_top=140, spd_rmp=50, spd_hold=false, spd_key="tab",
    game={
        melee="lmb", parry="f", gun="q", augment="rmb",
        interact="r", dash="lshift", slide="c", jump="space",
        forward="w", back="s", left="a", right="d",
    },
    bdg=false, bdg_key="r",
    bdg_t={
        s_hold_min=5, s_hold_max=9,
        dash_grapple_min=3, dash_grapple_max=7,
        w_slide_min=0, w_slide_max=2,
        slide_hold_min=650, slide_hold_max=950,
    },
    hum=true, hum_min=15, hum_max=35,
    hum_hold_min=30, hum_hold_max=85,
    hum_jit_min=15, hum_jit_max=35, hum_jit_s2=10,
}

local function deep_copy(src, dst)
    for k,v in pairs(src) do
        if type(v)=="table" then dst[k]={}; deep_copy(v,dst[k])
        else dst[k]=v end
    end
end

local function cfg_wipe(t)
    for k in pairs(t) do t[k]=nil end
end

local function cfg_replace(dst)
    cfg_wipe(dst)
    deep_copy(cfg_defaults, dst)
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
    pgup=0x21,pgdn=0x22,pageup=0x21,pagedown=0x22,
    ['1']=0x31,['2']=0x32,['3']=0x33,['4']=0x34,['5']=0x35,
    numpad0=0x60,numpad1=0x61,numpad2=0x62,
}
local function khex(name) return key_hex[name] or 0x51 end

local bind_list={
    "lmb","rmb","q","w","e","r","a","s","d","t","f","g","h","c","v","b","n",
    "space","lshift","lctrl","lalt","tab","capslock",
}
local HOTKEY_NONE="none"
local function hotkey_on(key)
    if not key then return false end
    key=ui_scalar(key)
    if key==nil then return false end
    local k=tostring(key):lower()
    return k~="" and k~=HOTKEY_NONE
end
local function hotkey_vk(key)
    if not hotkey_on(key) then return nil end
    return key_to_vk(tostring(key):lower())
end
local function hotkeys_with(list)
    local out={HOTKEY_NONE}
    for _,k in ipairs(list) do out[#out+1]=k end
    return out
end
local hotkey_bind=hotkeys_with(bind_list)
local hotkey_mac=hotkeys_with({"q","e","r","t","g","h","z","x","c","v","b","n"})
local hotkey_sl=hotkeys_with({"q","e","r","t","g","h","z","x","c","v","f1","f2","f3","lshift","capslock"})
local hotkey_menu=hotkeys_with({"rctrl","lctrl","insert","delete","home","end","pageup","pagedown","f1","f2","f3","f4","backquote","tab","capslock"})
local function ui_scalar(v)
    while type(v)=="table" do v=v[1] end
    return v
end
local function norm_menu_key(key)
    key=ui_scalar(key)
    if key==nil then return HOTKEY_NONE end
    if type(key)~="string" and type(key)~="number" then return HOTKEY_NONE end
    local k=tostring(key):lower():gsub("%s+","")
    if k=="" or k==HOTKEY_NONE then return HOTKEY_NONE end
    local alias={
        rightctrl="rctrl",leftctrl="lctrl",rightcontrol="rctrl",leftcontrol="lctrl",
        rightshift="rshift",leftshift="lshift",rightalt="ralt",leftalt="lalt",
        ctrl="lctrl",control="lctrl",shift="lshift",alt="lalt",
    }
    return alias[k] or k
end
local function menu_key_pick(key)
    key=norm_menu_key(key)
    return (key~=HOTKEY_NONE and key) or HOTKEY_NONE
end
local function hum_on() return cfg.hum~=false end

function human_hold_ms()
    if not hum_on() then return 50 end
    local lo=cfg.hum_hold_min or 30
    local hi=cfg.hum_hold_max or 85
    if lo>hi then lo,hi=hi,lo end
    return math.random(lo, hi)
end

function human_jitter_ms(gun, s2)
    if not hum_on() then return 0 end
    if s2 then
        local m=cfg.hum_jit_s2 or 10
        if m<=0 then return 0 end
        local j=math.random(0, m)
        return math.random()<0.5 and -j or j
    end
    local lo=cfg.hum_jit_min or 15
    local hi=cfg.hum_jit_max or 35
    if lo>hi then lo,hi=hi,lo end
    local j=math.random(lo, hi)
    return math.random()<0.5 and -j or j
end

function parry_jitter(sched, gun, s2)
    local j=human_jitter_ms(gun, s2)
    if j==0 then return sched end
    return mx(0, sched+j)
end

local function apply_gp_lead(sched_ms, s2)
    local lead=cfg.gp_lead
    if lead==nil then lead=10 end
    if s2 then lead=math.floor(lead*0.5) end
    if lead<=0 then return sched_ms end
    return mx(0, sched_ms-lead)
end

local function kpress(name)
    if not name then return end
    name=tostring(name):lower()
    if name=="lmb" or name=="mouse1" then pcall(mouse1press); return end
    if name=="rmb" or name=="mouse2" then pcall(mouse2press); return end
    pcall(keypress, khex(name))
end
local function krel(name)
    if not name then return end
    name=tostring(name):lower()
    if name=="lmb" or name=="mouse1" then pcall(mouse1release); return end
    if name=="rmb" or name=="mouse2" then pcall(mouse2release); return end
    pcall(keyrelease, khex(name))
end
local function ktap(name, ms)
    local h=(ms and ms>0) and ms or human_hold_ms()
    kpress(name)
    task.spawn(function()
        task.wait(h/1000)
        krel(name)
    end)
end
local function kpress_hold(name)
    if hum_on() then task.wait(math.random(3, 12)/1000) end
    kpress(name)
end
local function gb(k)
    local g=cfg.game or cfg_defaults.game
    return (g and g[k]) or cfg_defaults.game[k]
end
local function mm_rel(dx, dy)
    if type(mousemoverel)~="function" then return end
    pcall(mousemoverel, fl(dx), fl(dy))
end

local bind_st={}
local vk_extra={
    lctrl=0xA2,rctrl=0xA3,control=0x11,ctrl=0x11,lshift=0xA0,rshift=0xA1,lalt=0xA4,ralt=0xA5,
    mouse1=0x01,mouse2=0x02,mouse4=0x05,mouse5=0x06,xbutton1=0x05,xbutton2=0x06,
}

local function vk_dn(vk)
    if not vk then return false end
    local dn=false
    pcall(function() dn=iskeypressed(vk) end)
    return dn
end

local function key_name_dn(name)
    if not name then return false end
    name=tostring(name):lower()
    if name=="lmb" or name=="mouse1" then return vk_dn(0x01) end
    if name=="rmb" or name=="mouse2" then return vk_dn(0x02) end
    if name=="mouse4" or name=="xbutton1" then return vk_dn(0x05) end
    if name=="mouse5" or name=="xbutton2" then return vk_dn(0x06) end
    if name=="pgup" or name=="pageup" then return vk_dn(0x21) end
    if name=="pgdn" or name=="pagedown" then return vk_dn(0x22) end
    return vk_dn(key_hex[name] or vk_extra[name])
end

local function key_to_vk(name)
    if not name then return 0x48 end
    name=tostring(name):lower()
    if name=="lmb" or name=="mouse1" then return 0x01 end
    if name=="rmb" or name=="mouse2" then return 0x02 end
    return key_hex[name] or vk_extra[name] or 0x48
end

local function bind_edge(id, vk_fn, fn, cooldown)
    bind_st[id]=bind_st[id] or {last=false,deb=0}
    local s=bind_st[id]
    local vk=type(vk_fn)=="function" and vk_fn() or vk_fn
    if not vk then s.last=false; return end
    local dn=vk_dn(vk)
    if dn and not s.last and (oc()-s.deb)>(cooldown or 0.22) then
        s.deb=oc()
        fn()
    end
    s.last=dn
end

local loops_active = true

local st = {
    last_gun="castigate", gun_t=0, parry_t=0,
    mp_busy=false, mp_t=0,
    sl_tgt=nil, sl_til=0, gp_aim=nil, aim_lk=nil, aim_mx=0, aim_my=0,
    aim_sx=nil, aim_sy=nil,
    aura_t=0, att=nil, hb_on=true, hb_n=0,
    phx_flight=false, miss_n=0, miss_max=3,
    phx_log={t0=0,dist=0,sched=0,press_t=0,active=false},
    gp_lock=0, aura_pending=false, siege_s2_t=0, s2_arm=0,
    ov_t=0, esp_sync_t=0, esp_draw_t=0,
    bdg_busy=false, bdg_gen=0,
    spd_vacc=nil,
    pq_last=0, last_gp=0, last_parry=0,
    linger_until=0, flash_t=0, flash_gun=nil,
    await_cassette=false, post_parry_until=0,
}

local UI_FONT_DEFAULT = "Minecraft"
local UI_W_DEFAULT, UI_H_DEFAULT = 840, 720

local function resolve_draw_font()
    local F = Drawing and Drawing.Fonts
    if not F then return nil end
    return F.Minecraft or F.Monospace or F.Plex or F.System or F.UI
end

function refresh_draw_font()
    local f = resolve_draw_font()
    if f then draw_font = f; draw_font_cute = f end
end

local theme_legacy={
    purple="Grape", dark="Slate", blue="Sky", red="Crimson", green="Forest",
    white="Mono", cyan="Aqua", orange="Ember", pink="Rose", yellow="Gold",
    teal="Mint", crimson="Cherry", gold="Gold", midnight="Indigo",
    rose="Bubblegum", lime="Toxic",
}

local theme_esp={
    Grape={220,170,255}, Slate={200,200,210}, Sky={180,210,255}, Crimson={255,185,185},
    Forest={175,255,195}, Mono={240,240,245}, Aqua={160,240,255}, Ember={255,210,160},
    Rose={255,180,220}, Gold={255,230,130}, Mint={160,240,220}, Cherry={255,150,160},
    Indigo={160,170,220}, Bubblegum={255,190,200}, Toxic={200,255,160}, Lemon={255,245,160},
}

local function theme_preset(name)
    if not name or name=="" then return "Grape" end
    return theme_legacy[name] or name
end

local theme_accent={
    Grape={fov={220,170,255}, warn_primary={210,110,255}, warn_glow={170,90,230}, warn_text={248,242,255}},
    Slate={fov={200,200,210}, warn_primary={180,180,195}, warn_glow={140,140,160}, warn_text={248,248,252}},
    Sky={fov={180,210,255}, warn_primary={120,170,255}, warn_glow={90,140,230}, warn_text={240,248,255}},
    Crimson={fov={255,185,185}, warn_primary={255,90,110}, warn_glow={220,60,80}, warn_text={255,240,240}},
    Forest={fov={175,255,195}, warn_primary={80,220,140}, warn_glow={50,180,110}, warn_text={240,255,248}},
    Mono={fov={240,240,245}, warn_primary={220,220,230}, warn_glow={160,160,175}, warn_text={255,255,255}},
    Aqua={fov={160,240,255}, warn_primary={60,200,240}, warn_glow={40,160,210}, warn_text={240,252,255}},
    Ember={fov={255,210,160}, warn_primary={255,140,60}, warn_glow={220,100,40}, warn_text={255,248,240}},
    Rose={fov={255,180,220}, warn_primary={255,100,160}, warn_glow={220,70,130}, warn_text={255,240,248}},
    Gold={fov={255,230,130}, warn_primary={255,190,50}, warn_glow={220,150,30}, warn_text={255,252,240}},
    Mint={fov={160,240,220}, warn_primary={70,210,180}, warn_glow={50,170,140}, warn_text={240,255,250}},
    Cherry={fov={255,150,160}, warn_primary={255,70,90}, warn_glow={220,40,60}, warn_text={255,240,242}},
    Indigo={fov={160,170,220}, warn_primary={110,120,210}, warn_glow={80,90,180}, warn_text={240,242,255}},
    Bubblegum={fov={255,190,200}, warn_primary={255,120,160}, warn_glow={220,80,130}, warn_text={255,245,248}},
    Toxic={fov={200,255,160}, warn_primary={140,230,60}, warn_glow={100,200,40}, warn_text={248,255,240}},
    Lemon={fov={255,245,160}, warn_primary={255,220,50}, warn_glow={220,180,30}, warn_text={255,252,240}},
}

function apply_theme_colors(name)
    local preset=theme_preset(name)
    local acc=theme_accent[preset] or theme_accent.Grape
    local esp=theme_esp[preset] or theme_esp.Grape
    cfg.esp_r,cfg.esp_g,cfg.esp_b=esp[1],esp[2],esp[3]
    cfg.fov_r,cfg.fov_g,cfg.fov_b=acc.fov[1],acc.fov[2],acc.fov[3]
    cfg.warn_r,cfg.warn_g,cfg.warn_b=acc.warn_primary[1],acc.warn_primary[2],acc.warn_primary[3]
    if fov_obj then pcall(function() fov_obj.Color=Color3.fromRGB(acc.fov[1],acc.fov[2],acc.fov[3]) end) end
end

local cfg_ui_sync
local ui_ping_sync

local function apply_auto_ping()
    if not cfg.auto_ping then return end
    local p=read_ping()
    if not p then return end
    if p~=cfg.ping then
        cfg.ping=p
        if ui_ping_sync then pcall(ui_ping_sync,p) end
    end
end

do

local zone_w=25; local zone_cd=0.4; local flash_cd=0.1
local SELF_R=9
local zone_win={}; local active_z={}
local seen_win=setmetatable({},{__mode="k"})

function zk(p)
    if not p then return "?" end
    return fl(p.X/zone_w)..","..fl(p.Z/zone_w)
end

local mp_unk={}
local mp_skip={}
for _,v in ipairs({"GunImpact","BulletHole","BulletSmoke","BulletSpark","MuzzleFlash","GunHit","CastigateImpact","BulletDecal","ImpactParticle","HeadOnly","GroundSlamEffect"}) do mp_skip[v]=true end
local maps={
    flash={MonarchFlash="monarch",PhoenixFlash="phoenix",SiegeFlashOutsider="siege",CastigateFlash="castigate"},
    glare={MonarchGlare="monarch",SiegeGlare="siege",PhoenixGlare="phoenix",Cross="castigate"},
    win={ParryIndicator=true,SuspendedIndicator=true},
    pgui={Cross="castigate",MonarchGlare="monarch",SiegeGlare="siege",PhoenixGlare="phoenix"},
    pg_delay={castigate="pg_cast",monarch="pg_mon",phoenix="pg_phx",siege="pg_siege"},
}
local att_gun={}; local att_gun_t={}; local att_gun_ttl=8000
local win_last={}
local shot=nil
local cycle_fired=false
local cycle_fired_t=0
function new_shot()
    shot={t=nil, t0=nil, claimed=false, certain=false, gun=nil, gun_src=nil, entry=nil, si_key=nil, flashed=false, pq_fired=false, siege_s2_queued=false}
    cycle_fired=false; cycle_fired_t=0
    st.att=nil
end
new_shot()
local SI_STALE_DSQ=8100
local LINGER_PAD=420
local stale_log={}
local cam_snap_dbg=0
local scan_vfx_n=0
local scan_pg_n=0
local si_done={}
local tool_guns={Castigate="castigate",Monarch="monarch",Siege="siege",Phoenix="phoenix"}
local id_guns={
    Castigate="castigate",castigate="castigate",
    Monarch="monarch",monarch="monarch",
    Siege="siege",siege="siege",
    Phoenix="phoenix",phoenix="phoenix",
}

local OFF={
    anim_active=0x888,
    track_anim=0xd0,
    anim_id=0xd8,
    str_len=0x10,
    attr_cont=0x48,
    attr_list=0x18,
    attr_next=0x58,
    attr_val=0x18,
    val=0xd0,
}
local mem={on=type(memory_read)=="function", w=type(memory_write)=="function"}
function mem.r_ptr(a) if not mem.on or not a or a==0 then return 0 end local ok,v=pcall(memory_read,"uintptr_t",a); return (ok and tonumber(v)) or 0 end
function mem.r_int(a) if not mem.on or not a or a==0 then return 0 end local ok,v=pcall(memory_read,"int",a); return (ok and tonumber(v)) or 0 end
function mem.r_float(a) if not mem.on or not a or a==0 then return 0 end local ok,v=pcall(memory_read,"float",a); return (ok and tonumber(v)) or 0 end
function mem.w_float(a,v) if not mem.w or not a or a==0 then return false end local ok=pcall(memory_write,"float",a,v); return ok end
function mem.r_rbxstr(a)
    if not mem.on or not a or a==0 then return "" end
    local len=mem.r_int(a+OFF.str_len)
    if len<=0 or len>256 then return "" end
    local sp=(len>=16) and mem.r_ptr(a) or a
    if sp==0 then return "" end
    local ok,s=pcall(memory_read,"string",sp); return (ok and s) or ""
end
function inst_addr(obj)
    if not obj then return nil end
    local ok,a=pcall(function() return obj.Address end)
    return (ok and tonumber(a)) or nil
end

function load_offsets()
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
    log("[off] live offsets loaded")
end
pcall(load_offsets)

function read_item_id(obj)
    if not obj then return nil end
    local id=try(function() return obj:GetAttribute("item_id") end)
    if id~=nil and id~="" then return tostring(id) end
    local sv=try(function() return obj:FindFirstChild("item_id") end)
    if sv then
        local v=try(function() return sv.Value end)
        if v~=nil and v~="" then return tostring(v) end
    end
    if mem.on then
        local base=inst_addr(obj)
        if base and base~=0 then
            local cont=mem.r_ptr(base+OFF.attr_cont)
            if cont~=0 then
                local node=mem.r_ptr(cont+OFF.attr_list)
                local guard=0
                while node~=0 and guard<24 do
                    guard=guard+1
                    if mem.r_rbxstr(node)=="item_id" then
                        local vp=mem.r_ptr(node+OFF.attr_val)
                        local n=mem.r_int((vp~=0 and vp or node)+OFF.val)
                        if n~=0 then return tostring(n) end
                    end
                    node=mem.r_ptr(node+OFF.attr_next)
                end
            end
        end
    end
    return nil
end

local pgui_order={"MonarchGlare","SiegeGlare","PhoenixGlare","Cross"}
local pg_seen={}; local pg_parried={}

function gun_from_id(att)
    if not att then return nil end
    local src=att
    local ok,ch=pcall(function() return att.Character end)
    if ok and ch then src=ch end
    local function scan(obj, depth)
        if not obj or depth>5 then return nil end
        local id=read_item_id(obj)
        if id and id_guns[id] then return id_guns[id] end
        local n=try(function() return obj.Name end)
        if n and tool_guns[n] then return tool_guns[n] end
        for _,child in ipairs(try(function() return obj:GetChildren() end) or {}) do
            local g=scan(child, depth+1)
            if g then return g end
        end
        return nil
    end
    local tool=try(function() return src:FindFirstChildOfClass("Tool") end)
    if tool then
        local g=scan(tool, 0)
        if g then return g end
    end
    return scan(src, 0)
end

function gun_from_att(att, fallback)
    if not att then return fallback end
    local g=att_gun[att]; local gt=att_gun_t[att] or 0
    if g and (ms()-gt)<att_gun_ttl then return g end
    return fallback
end

function gun_from_char(att)
    return gun_from_id(att)
end

function pgui_gun_now()
    local pgui=lp and try(function() return lp:FindFirstChild("PlayerGui") end)
    if not pgui then return nil end
    local ve=try(function() return pgui:FindFirstChild("VisualEffects") end)
        or try(function() return pgui:FindFirstChild("VisualEffects", true) end)
    if not ve then return nil end
    for _,eff_nm in ipairs(pgui_order) do
        local g=maps.pgui[eff_nm]
        if g and try(function() return ve:FindFirstChild(eff_nm) end) then return g end
    end
    return nil
end

function resolve_gun(att, gun_guess, certain)
    local from_id=att and gun_from_id(att)
    if from_id then
        if gun_guess and gun_guess~=from_id then dlog("[gp] gun id -> "..from_id) end
        return from_id, "id"
    end
    if certain and gun_guess then return gun_guess, "certain" end
    if att then
        local stored=att_gun[att]; local gt=att_gun_t[att] or 0
        if stored and (ms()-gt)<att_gun_ttl then
            if gun_guess and gun_guess~=stored then dlog("[gp] gun cache -> "..stored) end
            return stored, "cache"
        end
    end
    if gun_guess and gun_guess~="castigate" then return gun_guess, "guess" end
    local pg=pgui_gun_now()
    if pg then return pg, "pgui" end
    if gun_guess=="castigate" and certain then return gun_guess, "certain" end
    if st.last_gun and st.gun_t and (ms()-st.gun_t)<1500 and st.last_gun~="castigate" then
        return st.last_gun, "recent"
    end
    return nil, nil
end

function guess_gun(att)
    local gun=resolve_gun(att, nil, false)
    return gun, (not gun)
end

function gun_w2f(gun)
    return w2f[gun] or 800
end

function parry_base_ms(gun)
    local dk=maps.pg_delay[gun]
    if dk then
        local v=cfg[dk]
        if v==nil then v=cfg_defaults[dk] end
        if v~=nil then return v end
    end
    return gun_w2f(gun)
end

function mark_linger(gun)
    local dur=mx(LINGER_PAD, fl(gun_w2f(gun)*0.12))
    st.linger_until=mx(st.linger_until or 0, ms()+dur)
end

function shot_block_ms(gun)
    gun=gun or st.last_gun or "castigate"
    return mx(LINGER_PAD, fl(gun_w2f(gun)*0.12))
end

function extend_shot_block(gun, si_key, att)
    mark_linger(gun)
    local block=mx(gun_w2f(gun or st.last_gun or "castigate")+400, 1200)
    if si_key then win_last[si_key]=ms()+block end
    if att then win_last[att]=ms()+block end
end

function parry_cooldown_active()
    if st.s2_arm and ms()<st.s2_arm then return false end
    return ms()-st.last_parry<380 or (st.parry_t>0 and ms()-st.parry_t<380)
end

function parry_block_active(gun, allow_detect)
    if st.s2_arm and ms()<st.s2_arm then return false end
    if allow_detect then
        if ms()<st.post_parry_until then return false end
        return parry_cooldown_active()
    end
    local gap=shot_block_ms(gun)
    if ms()<st.linger_until then return true end
    if st.last_gp>0 and ms()-st.last_gp<gap then return true end
    if st.parry_t>0 and ms()-st.parry_t<gap then return true end
    if ms()-st.last_parry<gap then return true end
    return false
end

function mark_pgui_parried()
    local pgui=lp and try(function() return lp:FindFirstChild("PlayerGui") end)
    if not pgui then return end
    local ve=pgui:FindFirstChild("VisualEffects") or try(function() return pgui:FindFirstChild("VisualEffects", true) end)
    if not ve then return end
    local now=oc()
    for _,eff_nm in ipairs(pgui_order) do
        local eff=ve:FindFirstChild(eff_nm)
        if eff then
            local ok_a,addr=pcall(function() return tostring(eff.Address) end)
            if ok_a then pg_parried[addr]=true; pg_seen[addr]=now end
        end
    end
end

function flash_fallback_ok(gun, firer)
    if not gun then return false end
    if not firer or not att_in_detect_range(firer, nil) then return false end
    if ms()<st.post_parry_until then return false end
    if parry_cooldown_active() then return false end
    if shot and shot.claimed then return false end
    if pq_pending_non_s2() then return false end
    if pq_has(gun, firer, true) then return false end
    if st.last_gp>0 and ms()-st.last_gp<450 then return false end
    if st.parry_t>0 and ms()-st.parry_t<mx(600, gun_w2f(gun)*0.35) then return false end
    if st.flash_t>0 and st.flash_gun==gun and ms()-st.flash_t<mx(500, gun_w2f(gun)*0.12) then return false end
    return true
end

function shot_pq_fired()
    if not shot then return false end
    if shot.pq_fired then return true end
    if shot.entry and shot.entry.fired then return true end
    return false
end

function parry_confirmed_since(t0)
    t0=t0 or 0
    local gap=shot_block_ms(shot and shot.gun or st.last_gun)
    return st.parry_t>=t0 and ms()-st.parry_t<gap
end

function parry_this_cycle(gun)
    gun=gun or (shot and shot.gun) or st.last_gun or "castigate"
    local gap=shot_block_ms(gun)
    if not shot or not shot.claimed then
        if st.parry_t>0 and ms()-st.parry_t<gap then return true end
        return false
    end
    local t0=shot.t0 or shot.t or 0
    if parry_confirmed_since(t0) then return true end
    if (shot.pq_fired or shot_pq_fired()) and cycle_fired and ms()-cycle_fired_t<gap then return true end
    return false
end

function parry_blocks_enqueue(gun)
    gun=gun or (shot and shot.gun) or st.last_gun or "castigate"
    if shot and shot.claimed then
        if parry_confirmed_since(shot.t0 or shot.t or 0) then return true end
        if shot.pq_fired or (shot.entry and shot.entry.fired) then
            if ms()-st.last_gp<600 then return true end
            return false
        end
        if shot.entry and not shot.entry.fired then return pq_has(gun, shot.entry.att, true) end
        return false
    end
    return parry_block_active(gun)
end

function shot_gun_locked()
    if not shot or not shot.claimed or not shot.certain then return false end
    return shot.gun_src=="certain" or shot.gun_src=="pgui"
end

function pgui_only_claim()
    return shot and shot.claimed and not shot.entry and not shot.pq_fired
end

function stale_log_once(key, msg)
    local now=oc()
    if stale_log[key] and now-stale_log[key]<1.5 then return end
    stale_log[key]=now
    dlog(msg)
end
local seen_eff={}; local seen_vfx={}; local seen_part={}; local seen_pt={}
local t_win=nil; warn_til=0; warn_blink_t=0; warn_gun=nil
local pg_last_press=0
local on_cassette, on_window, on_flash, on_parry, on_melee, try_melee, is_own

local c_char, c_root
function get_char()
    local ch=lp and try(function() return lp.Character end)
    if ch~=c_char then c_char=ch; c_root=nil end
    return c_char
end
function get_root()
    local ch=get_char(); if not ch then c_root=nil; return nil end
    if c_root and try(function() return c_root.Parent end)~=nil then return c_root end
    c_root=try(function() return ch:FindFirstChild("HumanoidRootPart") end)
    return c_root
end
function get_pos() local r=get_root(); return r and try(function() return r.Position end) end

local cam={od={}, ok=false, cPtr=0, w_fail=false, BASE=type(getbase)=="function" and getbase() or 0}

function load_cam_od()
    if not mem.on then return end
    local ok,ver=pcall(function() return game:HttpGet("https://offsets.imtheo.lol/roblox/version") end)
    if not ok or not ver or ver=="" then return end
    local ok2,raw=pcall(function() return game:HttpGet(string.format("https://offsets.imtheo.lol/%s/offsets.json",ver)) end)
    if not ok2 or not raw or raw=="" then return end
    local ok3,t=pcall(function() return game:GetService("HttpService"):JSONDecode(raw) end)
    if not ok3 or type(t)~="table" or type(t.Offsets)~="table" then return end
    local o=t.Offsets
    local r={
        p1=o.FakeDataModel and o.FakeDataModel.Pointer,
        p2=o.FakeDataModel and o.FakeDataModel.RealDataModel,
        ws=o.DataModel    and o.DataModel.Workspace,
        cm=o.Workspace    and o.Workspace.CurrentCamera,
        cr=o.Camera       and o.Camera.Rotation,
        pos=o.Camera      and o.Camera.Position,
    }
    if r.p1 and r.p2 and r.ws and r.cm and r.cr then
        if not r.pos then r.pos=284 end
        cam.od=r; cam.ok=true
        log("[cam] offsets loaded (rot=0x"..string.format("%x",r.cr).." pos=0x"..string.format("%x",r.pos)..")")
    end
end
pcall(load_cam_od)
if mem.w then log("[cam] memory_write available") else log("[cam] no memory_write, mouse fallback for aim") end

local cam_res_at=0
function resolve_cam(force)
    local now=tick()
    if not force and cam.cPtr~=0 and now-cam_res_at<0.1 then return cam.cPtr end
    cam.cPtr=0; if not cam.ok or not mem.on then return 0 end
    if type(getbase)=="function" then cam.BASE=getbase() or cam.BASE end
    if cam.BASE==0 then return 0 end
    local a=mem.r_ptr(cam.BASE+cam.od.p1); if a==0 then return 0 end
    local b=mem.r_ptr(a+cam.od.p2);       if b==0 then return 0 end
    local c=mem.r_ptr(b+cam.od.ws);       if c==0 then return 0 end
    cam.cPtr=mem.r_ptr(c+cam.od.cm)
    cam_res_at=now
    return cam.cPtr
end

function get_look()
    if cam.cPtr==0 and resolve_cam()==0 then return nil end
    local base=cam.cPtr+cam.od.cr
    local x,y,z=mem.r_float(base+8),mem.r_float(base+20),mem.r_float(base+32)
    local m=sq(x*x+y*y+z*z); if m<1e-6 then return nil end
    return Vector3.new(-x/m,-y/m,-z/m)
end

function cam_pos()
    if cam.cPtr==0 and resolve_cam()==0 then return nil end
    local b=cam.cPtr+cam.od.pos
    return Vector3.new(mem.r_float(b),mem.r_float(b+4),mem.r_float(b+8))
end

function vang(a,b)
    if not a or not b then return 180 end
    local d=a.X*b.X+a.Y*b.Y+a.Z*b.Z
    local m1=sq(a.X^2+a.Y^2+a.Z^2); local m2=sq(b.X^2+b.Y^2+b.Z^2)
    if m1==0 or m2==0 then return 180 end
    return dg(ac(cl(d/(m1*m2),-1,1)))
end

function look_basis(lx,ly,lz)
    local m=sq(lx*lx+ly*ly+lz*lz); if m<1e-8 then return end
    lx,ly,lz=lx/m,ly/m,lz/m
    local ux,uy,uz=0,1,0
    local bx,by,bz=-lx,-ly,-lz
    local rx,ry,rz=uy*bz-uz*by,uz*bx-ux*bz,ux*by-uy*bx
    local rm=sq(rx*rx+ry*ry+rz*rz)
    if rm<1e-8 then ux,uy,uz=0,0,1; bx,by,bz=-lx,-ly,-lz; rx,ry,rz=uy*bz-uz*by,uz*bx-ux*bz,ux*by-uy*bx; rm=sq(rx*rx+ry*ry+rz*rz); if rm<1e-8 then return end end
    rx,ry,rz=rx/rm,ry/rm,rz/rm
    local ux2,uy2,uz2=ry*lz-rz*ly,rz*lx-rx*lz,rx*ly-ry*lx
    local um=sq(ux2*ux2+uy2*uy2+uz2*uz2); if um<1e-8 then return end
    ux2,uy2,uz2=ux2/um,uy2/um,uz2/um
    return rx,ry,rz, ux2,uy2,uz2, bx,by,bz
end

function slerp3(ax,ay,az,bx,by,bz,t)
    t=cl(t or 1,0,1)
    local dot=cl(ax*bx+ay*by+az*bz,-1,1)
    local ang=ac(dot)
    if ang<1e-5 then return bx,by,bz end
    local s=sin(ang)
    local w1,w2=sin((1-t)*ang)/s,sin(t*ang)/s
    return w1*ax+w2*bx,w1*ay+w2*by,w1*az+w2*bz
end

function cam_w_rot(lx,ly,lz)
    if not mem.w or cam.w_fail then return false end
    if cam.cPtr==0 and resolve_cam()==0 then return false end
    local c0x,c0y,c0z,c1x,c1y,c1z,c2x,c2y,c2z=look_basis(lx,ly,lz)
    if not c0x then return false end
    local base=cam.cPtr+cam.od.cr
    local ok=mem.w_float(base,c0x) and mem.w_float(base+12,c0y) and mem.w_float(base+24,c0z)
        and mem.w_float(base+4,c1x) and mem.w_float(base+16,c1y) and mem.w_float(base+28,c1z)
        and mem.w_float(base+8,c2x) and mem.w_float(base+20,c2y) and mem.w_float(base+32,c2z)
    if not ok then cam.w_fail=true; log("[cam] write failed, falling back to mouse aim") end
    return ok
end

function aim_mem_ready()
    return cfg.sl_mem~=false and mem.on and cam.ok and mem.w and not cam.w_fail
end

function aim_smooth_blend(dt, hz)
    local d=cl(dt or 0.016, 0.001, 0.05)
    local t=1-math.exp(-(hz or 24)*d)
    return t*t*(3-2*t)
end

function aim_smooth_hz()
    return mx(14, (cfg.sl_str or 42)*0.62)
end

function clear_aim_smooth()
    st.aim_sx=nil; st.aim_sy=nil
end

function aim_alpha(rate, dt, ang)
    local d=cl(dt or 0.016, 0.001, 0.05)
    local base=1-math.exp(-rate*d)
    local t=base
    if ang and ang>0.02 then
        local n=cl(ang/75, 0, 1)
        n=n*n*(3-2*n)
        t=base*(0.88+0.22*n)
    end
    return cl(t, 0.008, 0.68)
end

function aim_cap_alpha(alpha, max_dps, ang, dt)
    if not max_dps or max_dps<=0 or not ang or ang<1e-3 then return alpha end
    local cap=(max_dps*cl(dt or 0.016, 0.001, 0.05))/ang
    local c=cap<alpha and cap or alpha
    return cl(c, 0.008, 0.68)
end

function cam_mem_aim(tx,ty,tz, rate, max_dps, dt)
    if not aim_mem_ready() then return false end
    local ok,res=pcall(function()
        if cam.cPtr==0 and resolve_cam()==0 then return false end
        local cp=cam_pos(); if not cp then return false end
        local dx,dy,dz=tx-cp.X,ty-cp.Y,tz-cp.Z
        local dm=sq(dx*dx+dy*dy+dz*dz); if dm<1e-6 then return false end
        dx,dy,dz=dx/dm,dy/dm,dz/dm
        local d=cl(dt or 0.016, 0.001, 0.05)
        local lk0=st.aim_lk or get_look()
        local ang0=lk0 and vang(lk0, Vector3.new(dx,dy,dz)) or 90
        local steps=3
        if ang0>30 then steps=8 elseif ang0>15 then steps=6 elseif ang0>6 then steps=4 end
        local sd=d/steps
        for _=1,steps do
            local lk=st.aim_lk or get_look(); if not lk then return false end
            local ang=vang(lk, Vector3.new(dx,dy,dz))
            local alpha=aim_alpha(rate or 16, sd, ang)
            local t=aim_cap_alpha(alpha, max_dps, ang, sd)
            local lx,ly,lz=slerp3(lk.X,lk.Y,lk.Z,dx,dy,dz,t)
            if not cam_w_rot(lx,ly,lz) then return false end
            st.aim_lk=Vector3.new(lx,ly,lz)
        end
        return true
    end)
    if not ok then
        if cfg.debug then dlog("[cam] aim err: "..tostring(res)) end
        return false
    end
    return res
end

function dsq(a,b)
    if not a or not b then return math.huge end
    local x=b.X-a.X; local y=b.Y-a.Y; local z=b.Z-a.Z; return x*x+y*y+z*z
end
function hdsq(a,b)
    if not a or not b then return math.huge end
    local x=b.X-a.X; local z=b.Z-a.Z; return x*x+z*z
end

place_cache={lobby={},twov2={}}

function rebuild_place_cache()
    place_cache.lobby={}; place_cache.twov2={}
    for _,id in ipairs(cfg.lobby_places or {}) do
        local n=tonumber(id); if n then place_cache.lobby[n]=true end
    end
    for _,id in ipairs(cfg.twov2_places or {}) do
        local n=tonumber(id); if n then place_cache.twov2[n]=true end
    end
end

function cur_place_id()
    return try(function() return game.PlaceId end)
end

function in_lobby()
    local pid=cur_place_id()
    if not pid then return false end
    return place_cache.lobby[pid]==true
end

function in_twov2()
    local pid=cur_place_id()
    if not pid then return false end
    return place_cache.twov2[pid]==true
end

function team_check_active()
    return cfg.team==true and in_twov2()
end

function log_place_id(tag)
    local pid=cur_place_id()
    local msg="[place] PlaceId = "..tostring(pid)..(tag and (" ("..tag..")") or "")
    log(msg)
    return pid
end

function place_list_add(list_key)
    local pid=cur_place_id()
    if not pid then return false end
    local list=cfg[list_key]
    if type(list)~="table" then list={}; cfg[list_key]=list end
    for _,v in ipairs(list) do
        if tonumber(v)==pid then return false end
    end
    list[#list+1]=pid
    rebuild_place_cache()
    mark_chg()
    log("[place] added "..tostring(pid).." -> "..list_key)
    return true
end

function place_list_str(list)
    if type(list)~="table" or #list==0 then return "(empty)" end
    local parts={}
    for _,v in ipairs(list) do parts[#parts+1]=tostring(v) end
    return table.concat(parts, ", ")
end

rebuild_place_cache()

function is_self(p)
    if not lp then return false end; if p==lp then return true end
    local ok,n=pcall(function() return p.Name end); return ok and n==lp.Name
end
function is_enemy(p)
    if not team_check_active() then return true end; if not lp then return true end
    local ok1,t1=pcall(function() return lp.Team end)
    local ok2,t2=pcall(function() return p.Team end)
    if not(ok1 and ok2) then return true end
    if t1==nil or t2==nil then return true end
    return t1~=t2
end

function team_name_ffa(name)
    if not name then return false end
    local s=tostring(name):lower()
    return s:find("ffa") or s:find("free") or s:find("none")
end
function is_ffa_mode()
    for _,k in ipairs({"Gamemode","GameMode","Mode","gamemode"}) do
        local v=try(function() return workspace:GetAttribute(k) end)
        if v and team_name_ffa(tostring(v)) then return true end
    end
    local all=try(function() return plrs:GetPlayers() end) or {}
    local n=#all
    if n<2 then return false end
    local nil_n, teams = 0, {}
    for _,p in ipairs(all) do
        local ok,t=pcall(function() return p.Team end)
        if ok and t then
            if team_name_ffa(try(function() return t.Name end)) then return true end
            teams[t]=true
        else
            nil_n=nil_n+1
        end
    end
    if nil_n>=n then return true end
    local tc=0; for _ in pairs(teams) do tc=tc+1 end
    return tc<=1
end

function plr_ok(p)
    if not p then return false end
    local char=try(function() return p.Character end)
    if not char then return false end
    if not try(function() return char.Parent end) then return false end
    if not try(function() return char:FindFirstChild("HumanoidRootPart") end) then return false end
    local ro=try(function() return p:FindFirstChild("ReadOnly") end)
    if ro then
        local hv=try(function() return ro:FindFirstChild("health") end)
        local hp=hv and try(function() return hv.Value end)
        if hp and hp<=0 then return false end
    end
    return true
end

function tgt_ok(t)
    if not t then return false end
    if t.player and t.ent then
        if not plr_ok(t.ent) then return false end
    end
    local char=t.char
    if not char or not try(function() return char.Parent end) then return false end
    local root=t.root or try(function() return char:FindFirstChild("HumanoidRootPart") end)
    if not root then return false end
    local rpos=try(function() return root.Position end)
    if not rpos then return false end
    t.root=root; t.pos=rpos
    local hd=try(function() return char:FindFirstChild("Head") end)
    t.hpos=(hd and try(function() return hd.Position end)) or rpos
    return true
end

function head_pos(e)
    if not e then return nil end
    local src=e
    local ok,ch=pcall(function() return e.Character end); if ok and ch then src=ch end
    local h=try(function() return src:FindFirstChild("Head") end)
    if h then return try(function() return h.Position end) end
    local r=try(function() return src:FindFirstChild("HumanoidRootPart") end)
    if r then return try(function() return r.Position end) end
    return nil
end

function body_pos(e)
    if not e then return nil end
    local src=e
    local ok,ch=pcall(function() return e.Character end); if ok and ch then src=ch end
    local h=try(function() return src:FindFirstChild("Head") end)
    if h then
        local p=try(function() return h.Position end)
        if p then return p+Vector3.new(0,-0.35,0) end
    end
    local ut=try(function() return src:FindFirstChild("UpperTorso") end)
        or try(function() return src:FindFirstChild("Torso") end)
    if ut then return try(function() return ut.Position end) end
    return head_pos(e)
end

function si_stale(epos, cand)
    if st.s2_arm and ms()<st.s2_arm then return false end
    if ms()<st.post_parry_until then return false end
    if not shot or not shot.claimed then return false end
    if not epos or not cand then return false end
    local my=get_pos()
    if my then
        local dx,dy,dz=epos.X-my.X,epos.Y-my.Y,epos.Z-my.Z
        if (dx*dx+dy*dy+dz*dz)<=SI_STALE_DSQ then return false end
    end
    local rp=body_pos(cand) or head_pos(cand)
    if rp and dsq(epos,rp)<=SI_STALE_DSQ then return false end
    local gt=att_gun_t[cand] or 0
    if att_gun[cand] and (ms()-gt)<2500 then return false end
    if st.att==cand and shot.claimed then
        local age=ms()-(shot.t0 or shot.t or 0)
        local cycle=gun_w2f(shot.gun or st.last_gun or "castigate")+250
        if shot.gun=="siege" and st.s2_arm and ms()<st.s2_arm then return false end
        if age<cycle then return false end
    end
    return true
end

local ray_exclude=nil
pcall(function() ray_exclude=Enum.RaycastFilterType.Exclude end)

function char_of(ent)
    if not ent then return nil end
    local ok,ch=pcall(function() return ent.Character end)
    if ok and ch then return ch end
    return ent
end

function hit_is_target(hit, target)
    if not hit or not target then return false end
    local inst=hit.Instance; if not inst then return false end
    local tchar=char_of(target)
    while inst do
        if inst==tchar or inst==target then return true end
        inst=inst.Parent
    end
    return false
end

function in_view(pos)
    if not pos then return false end
    local ok,sp,on=pcall(WorldToScreen,pos)
    if not ok or not sp or type(sp)=="boolean" then return false end
    if on==false then return false end
    local cam_obj=workspace.CurrentCamera
    if cam_obj then
        local vp=try(function() return cam_obj.ViewportSize end)
        if vp and (sp.X<0 or sp.Y<0 or sp.X>vp.X or sp.Y>vp.Y) then return false end
    end
    return true
end

function can_see(from, to, target)
    if not from or not to then return false end
    local dx,dy,dz=to.X-from.X,to.Y-from.Y,to.Z-from.Z
    local dist=sq(dx*dx+dy*dy+dz*dz)
    if dist<0.25 then return true end
    local dir=Vector3.new(dx/dist,dy/dist,dz/dist)
    local ch=get_char()
    local len=dist-0.5
    if len<=0 then return true end
    local hit=nil
    if ray_exclude and RaycastParams then
        local ok,r=pcall(function()
            local p=RaycastParams.new()
            p.FilterType=ray_exclude
            p.FilterDescendantsInstances=ch and {ch} or {}
            return workspace:Raycast(from, dir*len, p)
        end)
        if ok then hit=r end
    end
    if not hit then
        pcall(function()
            local part=workspace:FindPartOnRayWithIgnoreList(Ray.new(from, dir*len), ch and {ch} or {}, false, true)
            if part then hit={Instance=part} end
        end)
    end
    if not hit then return true end
    return hit_is_target(hit, target)
end

function aiming_at_player(att, epos)
    if not att then return false end
    local my=get_pos(); if not my then return false end
    local ok_s,ch=pcall(function() return att.Character end)
    local src_e=(ok_s and ch) or att
    local hd=try(function() return src_e:FindFirstChild("Head") end)
        or try(function() return src_e:FindFirstChild("HumanoidRootPart") end)
    local look=hd and try(function() return hd.CFrame.LookVector end)
    local ap=head_pos(att) or epos
    if not look or not ap then return false end
    return vang(look,Vector3.new(my.X-ap.X,my.Y-ap.Y,my.Z-ap.Z))<=(cfg.warn_ang or 60)
end

function gp_los_ok(att, pos)
    if cfg.gp_los==false then return false end
    if not in_view(pos) then return false end
    if not aiming_at_player(att, pos) then return false end
    local my=get_pos(); if not my then return false end
    local eye=cam_pos() or Vector3.new(my.X,my.Y+1.5,my.Z)
    if can_see(eye, pos, att) then return true end
    local hp=head_pos(att)
    if hp and can_see(eye, hp, att) then return true end
    return false
end

function los_blocked(from, to, ignore)
    if not from or not to then return true end
    local dx,dy,dz=to.X-from.X,to.Y-from.Y,to.Z-from.Z
    local dist=sq(dx*dx+dy*dy+dz*dz)
    if dist<0.25 then return false end
    local dir=Vector3.new(dx/dist,dy/dist,dz/dist)
    if ray_exclude and RaycastParams then
        local ok,r=pcall(function()
            local p=RaycastParams.new()
            p.FilterType=ray_exclude
            p.FilterDescendantsInstances=ignore or {}
            return workspace:Raycast(from, dir*dist, p)
        end)
        if ok then return r~=nil end
    end
    local hit=nil
    pcall(function()
        local part=workspace:FindPartOnRayWithIgnoreList(Ray.new(from, dir*dist), ignore or {}, false, true)
        if part then hit=part end
    end)
    return hit~=nil
end

function parry_los_ok(att, hint_pos)
    if cfg.parry_los==false then return true end
    if not att then return false end
    local my=get_pos()
    local eye=cam_pos() or (my and Vector3.new(my.X,my.Y+1.5,my.Z))
    if not eye then return false end
    local ignore={}
    local ch=get_char()
    if ch then ignore[#ignore+1]=ch end
    local tc=char_of(att)
    if tc then ignore[#ignore+1]=tc end
    if att~=tc then ignore[#ignore+1]=att end
    local hp=head_pos(att)
    if hp and not los_blocked(eye, hp, ignore) then return true end
    local bp=body_pos(att)
    if bp and not los_blocked(eye, bp, ignore) then return true end
    return false
end

function max_detect_dist()
    return cfg.gp_dist or 610
end

function ent_valid(att)
    if not att then return false end
    if not (head_pos(att) or body_pos(att)) then return false end
    local ok,ch=pcall(function() return att.Character end)
    local src=(ok and ch) or att
    return try(function() return src.Parent end)~=nil
end

function ent_dist(att)
    local my=get_pos()
    local ap=head_pos(att) or body_pos(att)
    if not my or not ap then return math.huge end
    return sq(dsq(my,ap))
end

function att_in_range(att, max_d)
    if not ent_valid(att) then return false end
    max_d=max_d or max_detect_dist()
    return ent_dist(att)<=max_d
end

function att_in_detect_range(att, hint_pos)
    if not ent_valid(att) then return false end
    if att_in_range(att) then return true end
    if hint_pos and cfg.gp_los~=false and gp_los_ok(att, hint_pos) then
        return ent_dist(att)<=max_detect_dist()*1.5
    end
    return false
end

function foreach_ent(fn)
    local ch=get_char()
    local ef=try(function() return workspace:FindFirstChild(cfg.ents) end)
    if ef then
        for _,e in ipairs(try(function() return ef:GetChildren() end) or {}) do
            if ch and e==ch then continue end
            if try(function() return e.Name end)==lp.Name then continue end
            local r=try(function() return e:FindFirstChild("HumanoidRootPart") end) or try(function() return e:FindFirstChild("Head") end)
            if r then fn(e, r) end
        end
    end
    for _,p in ipairs(try(function() return plrs:GetPlayers() end) or {}) do
        if is_self(p) then continue end
        if not is_enemy(p) then continue end
        local char=try(function() return p.Character end); if not char then continue end
        local r=try(function() return char:FindFirstChild("HumanoidRootPart") end)
        if r then fn(p, r) end
    end
    for _,obj in ipairs(try(function() return workspace:GetChildren() end) or {}) do
        if ch and obj==ch then continue end
        if not obj:IsA("Model") then continue end
        if try(function() return obj.Name end)==lp.Name then continue end
        local hum=try(function() return obj:FindFirstChildOfClass("Humanoid") end); if not hum then continue end
        local r=try(function() return obj:FindFirstChild("HumanoidRootPart") end) or try(function() return obj:FindFirstChild("Head") end)
        if r then fn(obj, r) end
    end
end

function near_ent(pos)
    if not pos then return nil end
    local best,bd=nil,math.huge
    foreach_ent(function(ref, r)
        local p=try(function() return r.Position end); if not p then return end
        local d=dsq(pos,p); if d<bd then bd=d; best=ref end
    end)
    return best
end

function cam_aims_at(ref)
    local cp=cam_pos() or get_pos()
    local hp=head_pos(ref)
    if not cp or not hp then return false end
    local lk=get_look(); if not lk then return false end
    local dx,dy,dz=hp.X-cp.X,hp.Y-cp.Y,hp.Z-cp.Z
    local dm=sq(dx*dx+dy*dy+dz*dz); if dm<1 then return true end
    return vang(lk,Vector3.new(dx/dm,dy/dm,dz/dm))<=(cfg.warn_ang or 60)
end

function att_stale(cached, gun_hint)
    if not cached then return true end
    if not att_in_range(cached) then return true end
    if not aiming_at_player(cached) then return true end
    if gun_hint then
        local g=gun_from_id(cached)
        if g and g~=gun_hint then return true end
        local cg=att_gun[cached]; local gt=att_gun_t[cached] or 0
        if cg and cg~=gun_hint and (ms()-gt)<att_gun_ttl then return true end
    end
    return false
end

function pick_firer(pos, gun_hint, opts)
    if not pos then return nil end
    opts=opts or {}
    local require_aim=opts.require_aim~=false
    local require_los=opts.require_los~=false and cfg.parry_los~=false
    local my=get_pos()
    local near_me=my and dsq(my,pos)<2500
    local maxd=max_detect_dist()
    local maxd_sq=maxd*maxd
    local best,best_sc=nil,-math.huge
    foreach_ent(function(ref, r)
        local p=try(function() return r.Position end); if not p then return end
        if my then
            local dx,dy,dz=my.X-p.X,my.Y-p.Y,my.Z-p.Z
            if (dx*dx+dy*dy+dz*dz)>maxd_sq then return end
        end
        local aiming=aiming_at_player(ref, pos)
        if require_aim and not aiming then return end
        if require_los and not parry_los_ok(ref, pos) then return end
        local sc=0
        if aiming then sc=sc+2000 end
        if gun_hint then
            local gid=gun_from_id(ref)
            if gid==gun_hint then sc=sc+1500
            elseif gid then sc=sc-800 end
            local cg=att_gun[ref]; local gt=att_gun_t[ref] or 0
            if cg==gun_hint and (ms()-gt)<att_gun_ttl then sc=sc+1200 end
        end
        if near_me then
            if cam_aims_at(ref) then sc=sc+800 end
            if my then
                local dx,dy,dz=my.X-p.X,my.Y-p.Y,my.Z-p.Z
                local dm=sq(dx*dx+dy*dy+dz*dz)
                if dm>1 then
                    local to_ind=Vector3.new(pos.X-my.X,pos.Y-my.Y,pos.Z-my.Z)
                    sc=sc-vang(Vector3.new(dx/dm,dy/dm,dz/dm),to_ind)*2
                end
            end
        else
            sc=sc-dsq(pos,p)*0.01
        end
        if sc>best_sc then best_sc=sc; best=ref end
    end)
    if require_aim and (not best or best_sc<2000) then return nil end
    if gun_hint and best then
        local gid=gun_from_id(best)
        if gid and gid~=gun_hint then return nil end
    end
    return best
end

function pick_firer_gun(gun, opts)
    if not gun then return nil end
    opts=opts or {}
    local require_aim=opts.require_aim~=false
    local best,bd=nil,math.huge
    foreach_ent(function(ref, p)
        if gun_from_id(ref)~=gun then return end
        if not att_in_range(ref) then return end
        if cfg.parry_los~=false and not parry_los_ok(ref, p) then return end
        if require_aim and not aiming_at_player(ref, p) then return end
        local d=ent_dist(ref)
        if d<bd then bd=d; best=ref end
    end)
    return best
end

function resolve_att(att, hint_pos, gun_hint)
    if att then
        if att_in_detect_range(att, hint_pos) and not att_stale(att, gun_hint) then
            if cfg.parry_los~=false and not parry_los_ok(att, hint_pos) then return nil end
            return att
        end
        return nil
    end
    if hint_pos then
        local picked=pick_firer(hint_pos, gun_hint, {require_aim=true})
        if picked then st.att=picked; return picked end
    end
    if st.att and not att_stale(st.att, gun_hint) and att_in_detect_range(st.att, hint_pos) then
        if cfg.parry_los~=false and not parry_los_ok(st.att, hint_pos) then return nil end
        return st.att
    end
    if st.att and not att_in_range(st.att) then st.att=nil end
    return nil
end

function resolve_att_for_parry(att_ref, hint_pos, gun_hint)
    if att_ref and ent_valid(att_ref) and att_in_detect_range(att_ref, hint_pos) then
        local ok=att_ref
        if gun_hint then
            local g=gun_from_id(att_ref)
            if g and g~=gun_hint then ok=nil
            else
                local cg=att_gun[att_ref]; local gt=att_gun_t[att_ref] or 0
                if cg and cg~=gun_hint and (ms()-gt)<att_gun_ttl then ok=nil end
            end
        end
        if ok and (cfg.parry_los==false or parry_los_ok(ok, hint_pos)) then return ok end
    end
    if hint_pos then
        local att=pick_firer(hint_pos, gun_hint, {require_aim=false, require_los=cfg.parry_los~=false})
        if att then st.att=att; return att end
        att=near_ent(hint_pos)
        if att and att_in_detect_range(att, hint_pos) then
            if not gun_hint or gun_from_id(att)==gun_hint or not gun_from_id(att) then
                st.att=att; return att
            end
        end
    end
    if st.att and ent_valid(st.att) and att_in_detect_range(st.att, hint_pos) then
        local ok=st.att
        if gun_hint then
            local g=gun_from_id(st.att)
            if g and g~=gun_hint then ok=nil
            else
                local cg=att_gun[st.att]; local gt=att_gun_t[st.att] or 0
                if cg and cg~=gun_hint and (ms()-gt)<att_gun_ttl then ok=nil end
            end
        end
        if ok and (cfg.parry_los==false or parry_los_ok(ok, hint_pos)) then return ok end
    end
    if gun_hint then
        local att=pick_firer_gun(gun_hint, {require_aim=false})
        if att then st.att=att; return att end
        att=pick_firer_gun(gun_hint)
        if att then st.att=att; return att end
    end
    if st.att and not att_in_range(st.att) then st.att=nil end
    return nil
end

function clear_stale_shot()
    if not shot or not shot.claimed then return false end
    if parry_confirmed_since(shot.t0 or shot.t or 0) then return false end
    if not shot.pq_fired and not (shot.entry and shot.entry.fired) then return false end
    local stale_after=mx(700, gun_w2f(shot.gun or "castigate")*0.55)
    if ms()-st.last_gp<stale_after then return false end
    clear_gp_aim()
    if shot.entry then shot.entry.done=true end
    cycle_fired=false
    cycle_fired_t=0
    new_shot()
    dlog("[gp] stale shot cleared")
    return true
end

function get_tgts(bots)
    local out={}; if not lp then return out end
    local inc=(bots==nil) and cfg.training or bots
    for _,p in ipairs(try(function() return plrs:GetPlayers() end) or {}) do
        if is_self(p) or not is_enemy(p) or not plr_ok(p) then continue end
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

local tgt_cache, tgt_cache_t = {}, 0
function tgts_cached()
    local now=ms()
    if now-tgt_cache_t>60 then tgt_cache=get_tgts(true); tgt_cache_t=now end
    return tgt_cache
end

function press_f()
    ktap(gb("parry"))
end

function gun_press(force, sync)
    local now=ms()
    if not force and now<st.gp_lock then dlog("[gp] press blocked (locked)"); return false end
    if not force and cycle_fired and ms()-cycle_fired_t<120 then
        dlog("[gp] press blocked (cycle fired)"); return false
    end
    st.gp_lock=now+140
    st.last_gp=now
    pg_last_press=now
    if not force then cycle_fired=true; cycle_fired_t=now end
    local key=gb("parry")
    local vk=khex(key)
    pcall(keyrelease, vk)
    local hold=mx(32, hum_on() and human_hold_ms() or 45)
    local function tap()
        pcall(keypress, vk)
        task.wait(hold/1000)
        pcall(keyrelease, vk)
    end
    if sync then
        tap()
        st.last_gp=ms()
        st.gp_lock=st.last_gp+140
        return true
    end
    task.spawn(tap)
    return true
end

local cfg_file="redline_config.txt"
local cfg_changed=false
local chg_t=0
local cfg_syncing=false

function mark_chg()
    if cfg_syncing then return end
    if not cfg_changed then chg_t=oc() end
    cfg_changed=true
end

function cfg_force_parry_timings()
    local refresh={
        "pg_cast","pg_mon","pg_siege","pg_phx",
        "gp_dist","glare_d","s2_w2f","cas_spd","s2",
    }
    for _,k in ipairs(refresh) do
        if cfg_defaults[k]~=nil then cfg[k]=cfg_defaults[k] end
    end
    if type(cfg.mg)~="table" then cfg.mg={} end
    for k,v in pairs(cfg_defaults.mg) do cfg.mg[k]=v end
end

function cfg_ser()
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

function cfg_apply(str)
    if not str or str=="" then return false end
    for line in (str.."\n"):gmatch("([^\n]*)\n") do
        local key,val=line:match("^([^=]+)=(.*)$")
        if key and val then
            local parts={}; for p in key:gmatch("[^%.]+") do parts[#parts+1]=p end
            local tbl=cfg
            for i=1,#parts-1 do
                local p=parts[i]
                if type(tbl)~="table" then tbl=nil; break end
                if type(tbl[p])~="table" then tbl[p]={} end
                tbl=tbl[p]
            end
            if type(tbl)=="table" and #parts>=1 then
                local last=parts[#parts]
                local valn=tonumber(val)
                if val=="true" or val=="false" then tbl[last]=(val=="true")
                elseif valn~=nil then tbl[last]=valn
                else tbl[last]=val end
            end
        end
    end
    return true
end

function cfg_write(data)
    if type(writefile)~="function" then return false, "no writefile" end
    if type(makefolder)=="function" then
        pcall(makefolder, "")
        pcall(makefolder, "redline")
    end
    local wok, werr=pcall(writefile, cfg_file, data)
    if not wok then return false, tostring(werr) end
    if type(isfile)=="function" and type(readfile)=="function" then
        for _=1,4 do
            local iok, ex=pcall(isfile, cfg_file)
            if iok and ex then
                local rok, back=pcall(readfile, cfg_file)
                if rok and back and #back>0 then return true end
            end
            task.wait(0.05)
        end
    end
    return true
end

function cfg_save()
    if cfg_ui_sync then pcall(function() cfg_ui_sync(true) end) end
    local data=cfg_ser()
    if type(writefile)~="function" then
        pcall(setclipboard, data)
        rn("config copied (no writefile)","Redline",3)
        log("[cfg] no writefile, copied to clipboard")
        return false
    end
    local ok, err=cfg_write(data)
    if ok then
        cfg_changed=false
        chg_t=0
        rn("config saved","Redline",2)
        log("[cfg] saved")
        return true
    end
    pcall(setclipboard, data)
    rn("save failed, copied","Redline",4)
    log("[cfg] save failed: "..tostring(err))
    mark_chg()
    return false
end

function cfg_merge_defaults()
    local function merge(src, dst)
        for k,v in pairs(src) do
            if type(v)=="table" then
                if type(dst[k])~="table" then dst[k]={} end
                merge(v, dst[k])
            elseif dst[k]==nil then
                dst[k]=v
            end
        end
    end
    merge(cfg_defaults, cfg)
end

function cfg_migrate()
    local ver=tonumber(cfg.cfg_ver) or 0
    local migrated=ver<CFG_VER

    local function migrate_parry_if_stale()
        local stale={
            pg_cast={450,185},
            pg_mon={1500},
            pg_siege={900,400},
            gp_dist={1000},
            glare_d={30},
        }
        local touched=false
        for k, olds in pairs(stale) do
            local cur=cfg[k]
            local target=cfg_defaults[k]
            if target~=nil then
                if cur==nil then
                    cfg[k]=target; touched=true
                else
                    for _, old in ipairs(olds) do
                        if cur==old and cur~=target then
                            cfg[k]=target; touched=true; break
                        end
                    end
                end
            end
        end
        if type(cfg.mg)~="table" then cfg.mg={}; touched=true end
        for k,v in pairs(cfg_defaults.mg) do
            if cfg.mg[k]==nil then cfg.mg[k]=v; touched=true end
        end
        return touched
    end

    if cfg.mac and not cfg.bdg then cfg.bdg=true; migrated=true end
    cfg.mac=nil; cfg.mac_key=nil; cfg.bhop=nil; cfg.brace=nil; cfg.brace_key=nil

    if ver<3 then
        local refresh={
            "pg_cast","pg_mon","pg_siege","pg_phx","gp_dist","glare_d",
            "menu_key","show_keybinds","s2_w2f","cas_spd",
        }
        for _,k in ipairs(refresh) do
            if cfg_defaults[k]~=nil then cfg[k]=cfg_defaults[k] end
        end
        cfg.mg={}; deep_copy(cfg_defaults.mg, cfg.mg)
        cfg.bdg_t={}; deep_copy(cfg_defaults.bdg_t, cfg.bdg_t)
        cfg.game={}; deep_copy(cfg_defaults.game, cfg.game)
    end

    if ver<4 then
        if cfg.auto_save~=true then cfg.auto_save=true; migrated=true end
    end

    if ver<8 then
        if cfg.pg_siege==400 then cfg.pg_siege=380; migrated=true end
    end

    if ver<9 then
        cfg.bdg_t={}; deep_copy(cfg_defaults.bdg_t, cfg.bdg_t)
    end

    if ver<10 then
        if type(cfg.lobby_places)~="table" then cfg.lobby_places={}; migrated=true end
        if type(cfg.twov2_places)~="table" then cfg.twov2_places={}; migrated=true end
        if cfg.esp_box==nil then cfg.esp_box=cfg_defaults.esp_box; migrated=true end
        if cfg.esp_chams==nil then cfg.esp_chams=cfg_defaults.esp_chams; migrated=true end
        if cfg.esp_draw_iv==nil then cfg.esp_draw_iv=cfg_defaults.esp_draw_iv; migrated=true end
        if cfg.esp_sync_iv==nil then cfg.esp_sync_iv=cfg_defaults.esp_sync_iv; migrated=true end
    end

    if ver<11 then
        local function merge_places(key)
            if type(cfg[key])~="table" then cfg[key]={}; migrated=true end
            if #cfg[key]==0 then
                for _,id in ipairs(cfg_defaults[key]) do cfg[key][#cfg[key]+1]=id end
                migrated=true
            end
        end
        merge_places("lobby_places")
        merge_places("twov2_places")
        if cfg.esp_sync_iv==nil or cfg.esp_sync_iv==0.1 then cfg.esp_sync_iv=cfg_defaults.esp_sync_iv; migrated=true end
        if cfg.esp_draw_iv==nil or cfg.esp_draw_iv==0.04 then cfg.esp_draw_iv=cfg_defaults.esp_draw_iv; migrated=true end
    end

    if ver<12 then
        if cfg.parry_los==nil then cfg.parry_los=cfg_defaults.parry_los; migrated=true end
    end

    if ver<13 then
        local bt=cfg.bdg_t
        if type(bt)=="table" then
            if bt.mid_rel_min and not bt.after_dash_rel_min then
                bt.after_dash_rel_min=bt.mid_rel_min
                bt.after_dash_rel_max=bt.mid_rel_max or bt.mid_rel_min
            end
            if bt.mid_rel_min and not bt.before_aug_rel_min then
                bt.before_aug_rel_min=bt.mid_rel_min
                bt.before_aug_rel_max=bt.mid_rel_max or bt.mid_rel_min
            end
        end
        migrated=true
    end

    if ver<14 then
        if type(cfg.game)~="table" then cfg.game={}; migrated=true end
        for k,v in pairs(cfg_defaults.game) do
            if cfg.game[k]==nil then cfg.game[k]=v; migrated=true end
        end
        if cfg.as==nil then cfg.as=cfg_defaults.as; migrated=true end
        if cfg.as_hold==nil then cfg.as_hold=cfg_defaults.as_hold; migrated=true end
        if cfg.as_air==nil then cfg.as_air=cfg_defaults.as_air; migrated=true end
        if cfg.as_surf==nil then cfg.as_surf=cfg_defaults.as_surf; migrated=true end
        if cfg.as_yaw_min==nil then cfg.as_yaw_min=cfg_defaults.as_yaw_min; migrated=true end
        if cfg.as_respect==nil then cfg.as_respect=cfg_defaults.as_respect; migrated=true end
        cfg.as_bhop=nil; cfg.as_bhop_cd=nil; cfg.as_bhop_ms=nil
    end

    if ver<15 then
        if cfg.streamer==nil then cfg.streamer=true; migrated=true end
    end

    if ver<16 then
        if cfg.as_mouse_sens==nil then cfg.as_mouse_sens=cfg_defaults.as_mouse_sens; migrated=true end
        local bt=cfg.bdg_t
        if type(bt)=="table" and tonumber(bt.dash_jump_max) and bt.dash_jump_max<=15 then
            cfg.bdg_t={}; deep_copy(cfg_defaults.bdg_t, cfg.bdg_t)
            migrated=true
        end
    end

    if ver<17 then
        if cfg.as_jit==nil then cfg.as_jit=cfg_defaults.as_jit; migrated=true end
        if cfg.as_jit_key==nil then cfg.as_jit_key=cfg_defaults.as_jit_key; migrated=true end
        if cfg.as_jit_dist==nil then cfg.as_jit_dist=cfg_defaults.as_jit_dist; migrated=true end
        if cfg.as_jit_spd==nil then cfg.as_jit_spd=cfg_defaults.as_jit_spd; migrated=true end
    end

    if ver<18 then
        cfg.as_mode=nil; cfg.as_flip=nil; cfg.as_yaw_min=nil; cfg.as_mouse_sens=nil
        if cfg.as_jit_dist and cfg.as_jit_dist<8 then cfg.as_jit_dist=cfg_defaults.as_jit_dist; migrated=true end
        if cfg.as_jit_spd and cfg.as_jit_spd>60 then cfg.as_jit_spd=cfg_defaults.as_jit_spd; migrated=true end
    end

    if ver<19 then
        if cfg.as_jit_dist and cfg.as_jit_dist<16 then cfg.as_jit_dist=cfg_defaults.as_jit_dist; migrated=true end
    end

    if ver<20 then
        cfg.ui_font=cfg_defaults.ui_font
        migrated=true
    end

    if ver<21 then
        cfg.ui_w=cfg_defaults.ui_w
        cfg.ui_h=cfg_defaults.ui_h
        cfg.ui_font=cfg_defaults.ui_font
        migrated=true
    end

    if ver<22 then
        cfg.phx_lead=cfg_defaults.phx_lead
        cfg.phx_radius=cfg_defaults.phx_radius
        if cfg.phx_rocket==nil then cfg.phx_rocket=cfg_defaults.phx_rocket end
        migrated=true
    end

    if ver<23 then
        cfg.as=nil; cfg.as_hold=nil; cfg.as_air=nil; cfg.as_surf=nil; cfg.as_respect=nil
        cfg.as_jit=nil; cfg.as_jit_key=nil; cfg.as_jit_dist=nil; cfg.as_jit_spd=nil
        cfg.as_bhop=nil; cfg.as_bhop_cd=nil; cfg.as_bhop_ms=nil
        cfg.as_mode=nil; cfg.as_flip=nil; cfg.as_yaw_min=nil; cfg.as_mouse_sens=nil
        migrated=true
    end

    if ver<24 then
        cfg.bdg_t={}; deep_copy(cfg_defaults.bdg_t, cfg.bdg_t)
        migrated=true
    end

    if ver<25 then
        cfg.bdg_t={}; deep_copy(cfg_defaults.bdg_t, cfg.bdg_t)
        migrated=true
    end

    if ver<26 then
        cfg.bdg_t={}; deep_copy(cfg_defaults.bdg_t, cfg.bdg_t)
        migrated=true
    end

    if ver<7 and migrate_parry_if_stale() then
        migrated=true
    end

    if theme_legacy[cfg.theme] then cfg.theme=theme_legacy[cfg.theme]; migrated=true end

    if ver<27 then
        cfg.slam=nil; cfg.slam_key=nil; cfg.slam_t=nil
        migrated=true
    end

    if ver<28 then
        if cfg.aura_key==nil then cfg.aura_key="none"; migrated=true end
        if cfg.hb_key==nil then cfg.hb_key="h"; migrated=true end
    end

    if ver<29 then
        if cfg.bdg_key=="x" then cfg.bdg_key="r"; migrated=true end
    end

    cfg_merge_defaults()
    cfg.cfg_ver=CFG_VER
    rebuild_place_cache()

    if migrated then
        cfg_changed=true; chg_t=oc()
    end
end

function cfg_load()
    if type(readfile)~="function" then return false end
    if type(isfile)=="function" then
        local ok, ex=pcall(isfile, cfg_file)
        if not ok or not ex then return false end
    end
    local ok, data=pcall(readfile, cfg_file)
    if ok and data and data~="" then
        deep_copy(cfg_defaults, cfg)
        cfg_apply(data)
        cfg_changed=false
        chg_t=0
        cfg_migrate()
        cfg.menu_key=norm_menu_key(cfg.menu_key)
        local f=ui_scalar(cfg.ui_font)
        if type(f)=="string" and f~="" then cfg.ui_font=f end
        local t=ui_scalar(cfg.theme)
        if type(t)=="string" and t~="" then cfg.theme=t end
        log("[cfg] loaded")
        return true
    end
    return false
end

function set_warn_style(s)
    s=s or 'fade'
    cfg.warn_corner = s:find('corner')~=nil
    cfg.warn_blink  = s:find('blink')~=nil
    cfg.warn_bar    = s:find('bar')~=nil
    cfg.warn_fade   = not s:find('solid') and not s:find('blink')
end

function clear_gp_aim()
    st.gp_aim=nil
    if not cfg.sl or not st.sl_tgt then st.aim_lk=nil end
    st.aim_mx=0; st.aim_my=0
    clear_aim_smooth()
end

function trim_gp_aim_after_press()
    if st.gp_aim then st.gp_aim.til=tick()+0.15 end
end

local pq={q={}, min_gap=28, late=280}

function pq_recovery_until()
    return mx(st.post_parry_until or 0, (st.last_parry or 0)+160)
end

function pq_clamp_fire_at(entry, fire_at, skip_gap)
    local now=ms()
    if not entry.s2 then
        fire_at=mx(fire_at, pq_recovery_until())
        if not skip_gap then fire_at=mx(fire_at, st.pq_last+pq.min_gap) end
    end
    if fire_at<=now then fire_at=now+mx(25, fl((entry.sched_ms or 80)*0.2)) end
    return fire_at
end

function pq_drop_at(entry)
    if entry.pressing then return math.huge end
    local drop=entry.fire_at+pq.late
    if not entry.s2 then drop=mx(drop, pq_recovery_until()+pq.min_gap+40) end
    return drop
end

function pq_pending_fire_ms(att, gun)
    local best=0
    local now=ms()
    for _,e in ipairs(pq.q) do
        if not e.fired then
            local rem=e.fire_at-now
            if rem>best and (not gun or e.gun==gun) then
                if not att or e.att==att or not e.att then best=rem end
            end
        end
    end
    return best
end

function gp_aim_dur(gun, fire_at)
    gun=gun or (shot and shot.gun) or st.last_gun or "castigate"
    local remain_ms=150
    if fire_at and fire_at>ms() then
        remain_ms=(fire_at-ms())+150
    elseif shot and shot.entry and not shot.entry.fired then
        remain_ms=mx(0, shot.entry.fire_at-ms())+150
    elseif shot and shot.pq_fired then
        remain_ms=150
    else
        local pq_rem=pq_pending_fire_ms(nil, gun)
        if pq_rem>0 then remain_ms=pq_rem+150
        else remain_ms=mx(120, fl(gun_w2f(gun)*0.08)) end
    end
    return cl(remain_ms/1000, 0.12, 1.0)
end

function gp_snap(att, hint_pos, gun, fire_at)
    if not cfg.gp_aim then return end
    local plr=resolve_att(att, hint_pos, gun)
    if not plr or not att_in_detect_range(plr, hint_pos) then return end
    local sp=head_pos(plr) or body_pos(plr)
    if not sp then return end
    local til=tick()+gp_aim_dur(gun, fire_at)
    if st.gp_aim and st.gp_aim.att==plr then
        st.gp_aim.til=til
        st.gp_aim.x,st.gp_aim.y,st.gp_aim.z=sp.X,sp.Y,sp.Z
    else
        st.gp_aim={att=plr, x=sp.X, y=sp.Y, z=sp.Z, til=til, rate=mx(12,(cfg.sl_str or 42)*0.48)}
    end
end

function warn_dur_sec(sched_ms)
    sched_ms=sched_ms or 200
    return mx(0.85, (sched_ms/1000)+0.5)
end

function fire_warn(gun, sched_ms, att, epos, opts)
    opts=opts or {}
    if in_lobby() then return end
    if not cfg.warn or not gun then return end
    if not opts.certain then
        if not att or not att_in_detect_range(att, epos) then return end
        if not aiming_at_player(att, epos) then return end
        if cfg.parry_los~=false and not parry_los_ok(att, epos) then return end
    end
    local til=tick()+warn_dur_sec(sched_ms)
    local now=tick()
    if gun~=warn_gun or now>=warn_til then
        warn_gun=gun
        warn_blink_t=now
        warn_til=til
    else
        warn_til=mx(warn_til, til)
    end
end

function detect_aim(att, pos, gun, fire_at, sched_ms, opts)
    if not gun then return end
    opts=opts or {}
    local att_r=resolve_att(att, pos, gun)
    local fa=fire_at
    if not fa and sched_ms then fa=ms()+sched_ms end
    local sm=sched_ms
    if not sm and fa then sm=mx(0, fa-ms()) end
    if att_r and att_in_detect_range(att_r, pos) then
        if cfg.gp_aim then gp_snap(att_r, pos, gun, fa) end
        fire_warn(gun, sm, att_r, pos, opts)
    elseif opts.certain then
        fire_warn(gun, sm, nil, nil, {certain=true})
    else
        if cfg.debug then stale_log_once("aim_ghost", "[gp] aim skip no firer in range") end
    end
end

function pq_resort()
    table.sort(pq.q,function(a,b) return a.fire_at<b.fire_at end)
end

function pq_set_fire_at(entry, fire_at, skip_gap)
    if not entry then return end
    entry.fire_at=pq_clamp_fire_at(entry, fire_at, skip_gap)
    pq_resort()
end

function pq_set_sched(entry, sched_ms, skip_gap)
    if not entry then return end
    local adj=apply_gp_lead(sched_ms, entry.s2)
    local now=ms()
    local fire_at=now+mx(0, adj-20)
    entry.sched_ms=adj
    pq_set_fire_at(entry, fire_at, skip_gap)
end

function pq_set_sched_at(entry, t0, sched_ms, skip_gap)
    if not entry then return end
    local adj=apply_gp_lead(sched_ms, entry.s2)
    local now=ms()
    local base=mx(t0 or now, entry.created or now)
    local fire_at=base+mx(0, adj-20)
    entry.sched_ms=adj
    pq_set_fire_at(entry, fire_at, skip_gap)
end

function pq_has(gun, att, skip_s2)
    for _,e in ipairs(pq.q) do
        if not e.fired and e.gun==gun then
            if skip_s2 and e.s2 then continue end
            if not att or e.att==att or not e.att then return true end
        end
    end
    return false
end

function pq_has_s2()
    for _,e in ipairs(pq.q) do
        if not e.fired and e.s2 then return true end
    end
    return false
end

function pq_pending_non_s2()
    for _,e in ipairs(pq.q) do
        if not e.fired and not e.s2 then return e end
    end
    return nil
end

function adopt_pq_shot(entry)
    if not entry then return end
    if not shot then new_shot() end
    shot.claimed=true
    shot.entry=entry
    shot.gun=entry.gun
    shot.t0=entry.created
    shot.t=entry.created
    shot.pq_fired=false
    if entry.att then st.att=entry.att end
end

function enqueue_parry(sched_ms, att_ref, gun, snap_pos, opts)
    opts=opts or {}
    if in_lobby() then return nil end
    if not cfg.gp then return nil end
    gun=gun or st.last_gun or "castigate"
    if not opts.s2 then
        if parry_blocks_enqueue(gun) then
            dlog("[pq] skip enqueue (cycle parried/fired) "..tostring(gun))
            return nil
        end
        if pq_has(gun, att_ref, true) then
            dlog("[pq] skip enqueue (pq busy) "..tostring(gun))
            return nil
        end
    end
    local att=resolve_att_for_parry(att_ref, snap_pos, gun)
    if not att or not att_in_detect_range(att, snap_pos) then
        if cfg.debug then stale_log_once("pq_ghost", "[gp] pq skip no firer in range "..tostring(gun)) end
        return nil
    end
    if cfg.parry_los~=false and not parry_los_ok(att, snap_pos) then
        dlog("[pq] skip enqueue (no los)")
        return nil
    end
    st.att=att
    if sched_ms<50 then dlog("[pq] short sched "..fl(sched_ms).."ms gun="..tostring(gun)) end
    if not opts.skip_jit then sched_ms=parry_jitter(sched_ms, gun, opts.s2 or false) end
    if not opts.skip_lead then sched_ms=apply_gp_lead(sched_ms, opts.s2 or false) end
    local now=ms()
    local press_lead=20
    local fire_at=now+math.max(0,sched_ms-press_lead)
    if not opts.s2 then
        fire_at=pq_clamp_fire_at({s2=false, sched_ms=sched_ms, created=now}, fire_at, false)
    end
    local entry={
        fire_at=fire_at, created=now, sched_ms=sched_ms,
        gun=gun, att=att, snap=snap_pos, done=false,
        s2=opts.s2 or false,
    }
    table.insert(pq.q,entry)
    pq_resort()
    dlog("[pq] queued "..tostring(gun).." +"..fl(sched_ms).."ms fire@"..fl(fire_at-now).."ms")
    if att and cfg.gp_aim then gp_snap(att, snap_pos, gun, fire_at) end
    return entry
end

function maybe_siege_s2(att, snap)
    if not cfg.s2 or not cfg.gp then return end
    if pq_has_s2() or (shot and shot.siege_s2_queued) then return end
    local base_gap=cfg.s2_w2f or 1000
    local now=ms()
    if now-st.siege_s2_t<base_gap then return end
    local gap=parry_jitter(base_gap, "siege", true)
    st.siege_s2_t=now
    st.s2_arm=now+gap+400
    if shot then shot.siege_s2_queued=true end
    enqueue_parry(gap, att, "siege", snap, {s2=true, skip_jit=true})
    dlog("[gp] siege s2 +"..fl(gap).."ms")
end

task.spawn(function()
    while loops_active do
        if in_lobby() then
            for _,e in ipairs(pq.q) do e.done=true end
            clear_gp_aim()
            task.wait(0.15)
            continue
        end
        local now=ms()
        for _,entry in ipairs(pq.q) do
            if entry.done or entry.fired then continue end
            local till=entry.fire_at-now
            if till>0 and till<=130 and cfg.gp_aim and not entry.aimed then
                entry.aimed=true
                gp_snap(entry.att, entry.snap, entry.gun, entry.fire_at)
            end
            if now<entry.fire_at then break end
            if now>pq_drop_at(entry) then
                entry.done=true
                entry.dropped=true
                dlog("[pq] late drop "..tostring(entry.gun))
                if shot and shot.entry==entry and not shot.pq_fired and not entry.pressing then
                    local next_e=pq_pending_non_s2()
                    if next_e and next_e~=entry then
                        adopt_pq_shot(next_e)
                    elseif not next_e then
                        shot.entry=nil
                        shot.claimed=false
                        shot.gun=nil
                        shot.si_key=nil
                        shot.pq_fired=false
                    end
                end
                continue
            end
            if not cfg.gp then
                entry.done=true
            elseif not entry.s2 and st.parry_t>0 and entry.created<=st.parry_t and parry_confirmed_since(entry.created) then
                entry.done=true
                dlog("[pq] dup skip (parry confirmed)")
            elseif entry.s2 or now-st.pq_last>=pq.min_gap then
                if not entry.s2 and ms()<(st.post_parry_until or 0) then break end
                if entry.pressing then break end
                if cfg.gp_aim and not entry.s2 then gp_snap(entry.att, entry.snap, entry.gun, entry.fire_at) end
                local e=entry
                if not shot or not shot.claimed or shot.entry~=e then adopt_pq_shot(e) end
                local waited=now-e.created
                local sched=e.sched_ms or (e.fire_at-e.created)
                e.pressing=true
                st.pq_last=now
                task.spawn(function()
                    if e.gun=="phoenix" then st.phx_log.press_t=ms() end
                    if gun_press(true, true) then
                        e.fired=true
                        e.done=true
                        e.pressing=false
                        st.last_gp=ms()
                        dlog("[pq] F -> "..tostring(e.gun).." waited "..fl(waited).."ms (sched "..fl(sched).."ms)")
                        if not e.s2 then
                            extend_shot_block(e.gun, shot and shot.si_key, e.att)
                            trim_gp_aim_after_press()
                            if e.gun=="siege" and shot and shot.gun=="siege" then maybe_siege_s2(e.att, e.snap) end
                        end
                        if shot and shot.entry==e then shot.pq_fired=true end
                        local t0=shot and shot.t0 or e.created
                        task.spawn(function()
                            task.wait(0.42)
                            if parry_confirmed_since(t0) or e.retried then return end
                            if shot and shot.entry~=e then return end
                            if ms()-t0>gun_w2f(e.gun) then return end
                            e.retried=true
                            if gun_press(true, true) then
                                st.last_gp=ms()
                                dlog("[pq] F retry -> "..tostring(e.gun))
                            end
                        end)
                    else
                        e.pressing=false
                        dlog("[pq] press failed "..tostring(e.gun).." retry")
                    end
                end)
                break
            else
                break
            end
        end
        local now2=ms()
        local clean={}
        for _,e in ipairs(pq.q) do
            if e.fired or (e.done and not e.pressing) then continue end
            if (now2-e.created)<8000 then table.insert(clean,e) end
        end
        pq.q=clean
        local sleep=0.01
        for _,e in ipairs(pq.q) do
            if not e.fired and e.fire_at-ms()<=35 then sleep=0.002; break end
        end
        task.wait(sleep)
    end
end)


function si_arc_trim(sched)
    local pgui=lp and try(function() return lp:FindFirstChild("PlayerGui") end)
    if not pgui then return sched end
    local gui=try(function() return pgui:FindFirstChild("GameplayUI") end)
        or try(function() return pgui:FindFirstChild("GameplayUI", true) end)
    local si=gui and try(function() return gui:FindFirstChild("ShooterIndicator") end)
    local grad=si and try(function() return si:FindFirstChildOfClass("UIGradient") end)
    local rot=grad and try(function() return grad.Rotation end)
    if rot and rot>110 then
        return mx(0, sched-fl((rot-110)*0.35))
    end
    return sched
end

function calc_sched(gun, dist)
    local ping=cfg.ping or 47
    local mg_tbl=(type(cfg.mg)=="table") and cfg.mg or {}
    local mg=(mg_tbl[gun]) or 0
    local pg=parry_base_ms(gun)
    local mg_use=math.min(mg, fl(pg*0.5))
    local sched=mx(50, pg-ping-mg_use)
    if gun=="phoenix" then
        local travel=0
        if dist then
            local spd=cfg.phx_spd or 80
            if (cfg.phx_pct or 0)>0 then spd=spd*(1+(dist/100)*((cfg.phx_pct or 0)/100)) end
            travel=(dist/spd)*1000
        end
        sched=mx(50, pg+travel-ping-mg_use)
        st.phx_flight=true
        if not st.phx_log.active then st.phx_log.t0=ms(); st.phx_log.active=true; st.phx_log.press_t=0 end
        if dist then st.phx_log.dist=dist end
        st.phx_log.sched=sched
    elseif gun=="castigate" and dist then
        local spd=cfg.cas_spd or 360
        local travel=(dist/spd)*1000
        sched=mx(50, pg+travel-ping-mg_use)
    end
    return si_arc_trim(sched)
end

function sched_fire_at(gun, dist, t0)
    return (t0 or ms())+apply_gp_lead(calc_sched(gun, dist))
end

function maybe_reset_shot()
    if shot and shot.claimed and shot.t then
        local timeout=gun_w2f(shot.gun)+600
        if shot.entry and not shot.entry.fired then
            timeout=mx(timeout, mx(0, shot.entry.fire_at-ms())+900)
        end
        if (ms()-shot.t)>timeout then
            dlog("[gp] shot cycle timed out, reset")
            clear_gp_aim()
            if shot.entry then shot.entry.done=true end
            cycle_fired=false
            cycle_fired_t=0
            new_shot()
        end
    end
end

on_window=function(gun_guess,epos,src,certain)
    if not cfg.gp then return end
    clear_stale_shot()
    local me0=get_pos()
    if me0 and epos and sq(dsq(me0,epos))<SELF_R then dlog("[gp] self effect, skip"); return end
    local my=get_pos()
    local att=nil
    if epos then
        local cand=pick_firer(epos, gun_guess, {require_aim=false})
        if cand then
            if si_stale(epos,cand) then
                local key=epos and zk(epos) or "?"
                stale_log_once(key, "[gp] stale SI")
                zone_win[key]=oc()+flash_cd; active_z[key]=nil
                return
            end
            att=cand; st.att=att
        end
    end
    local si_key=att or (epos and zk(epos)) or "g"
    if ms()-st.last_parry<120 and si_done[si_key] then
        dlog("[gp] duplicate SI after parry")
        return
    end
    local gun, gun_src=resolve_gun(att, gun_guess, certain)
    if not gun then
        local pg=pgui_gun_now()
        if pg then gun, gun_src=pg, "pgui"
        elseif st.last_gun and st.gun_t and (ms()-st.gun_t)<3000 then gun, gun_src=st.last_gun, "recent"
        elseif att then
            local cached=att_gun[att]; local gt=att_gun_t[att] or 0
            if cached and (ms()-gt)<att_gun_ttl then gun, gun_src=cached, "cache" end
        end
    end
    if not gun then
        dlog("[gp] SI no gun id, warn")
        local guess="castigate"
        if st.last_gun and st.gun_t and (ms()-st.gun_t)<3000 then guess=st.last_gun end
        local sched=calc_sched(guess, dist)
        detect_aim(att, epos, guess, ms()+sched, sched)
        return
    end
    if gun_src=="id" or gun_src=="certain" then
        st.last_gun=gun; st.gun_t=ms()
        if att then att_gun[att]=gun; att_gun_t[att]=ms() end
    end
    if not certain and gun_guess and gun_guess~=gun then
        dlog("[gp] SI gun fallback -> "..tostring(gun))
    end
    local dist=nil
    if my and att then local hp=head_pos(att); if hp then dist=sq(dsq(my,hp)) end end
    local sched_est=calc_sched(gun,dist)
    detect_aim(att, epos, gun, ms()+sched_est, sched_est, certain and {certain=true} or nil)
    if st.flash_t>0 then
        local flash_g=st.flash_gun or st.last_gun
        local since=ms()-st.flash_t
        local block=mx(1200, gun_w2f(flash_g or gun)+300)
        if since<block and (not flash_g or gun==flash_g or gun==st.last_gun) then
            dlog("[gp] post-flash SI skip"); return
        end
    end
    if not shot then new_shot() end
    maybe_reset_shot()
    local si_key=att or (epos and zk(epos)) or "g"
    if shot.claimed and shot.gun==gun and shot.si_key==si_key then
        if shot.entry and not shot.entry.fired then
            stale_log_once("si_dup_"..tostring(si_key), "[gp] duplicate SI same cycle")
            return
        end
        if shot_pq_fired() or shot.pq_fired or parry_confirmed_since(shot.t0 or 0) then
            if not clear_stale_shot() then
                stale_log_once("si_done_"..tostring(si_key), "[gp] SI skip (cycle done)")
                return
            end
        end
    end
    if shot.claimed and not shot.si_key and not shot_pq_fired() and not shot.pq_fired then
        local sched=calc_sched(gun,dist)
        if shot.entry and not shot.entry.fired then
            dlog("[gp] SI override pgui queue | sched "..fl(sched).."ms")
            shot.t0=ms(); shot.t=ms(); shot.si_key=si_key
            shot.gun=gun; shot.gun_src=gun_src; shot.entry.gun=gun
            pq_set_sched(shot.entry, sched, false)
            local fire_at=shot.entry.fire_at
            shot.entry.att=att; shot.entry.snap=epos
            detect_aim(att, epos, gun, fire_at, fire_at-ms())
            if certain then shot.certain=true end
            win_last[si_key]=ms()+math.max(300,sched)+350
            return
        elseif pgui_only_claim() and st.parry_t<(shot.t0 or 0) then
            dlog("[gp] SI override pgui-only claim")
            shot.claimed=false; shot.gun=nil; shot.certain=false; shot.t=nil; shot.t0=nil
        end
    end
    if certain then shot.certain=true; if not shot.gun_src or gun_src=="id" or gun_src=="certain" then shot.gun_src=gun_src end end
    if shot.claimed then
        if shot.entry and shot.entry.fired then
            stale_log_once("pq_done_"..tostring(att or gun), "[gp] pq done, skip reaim")
            return
        end
        if shot.pq_fired or shot_pq_fired() then
            if not clear_stale_shot() then
                stale_log_once("pq_fired_"..tostring(att or gun), "[gp] pq fired, skip reaim")
                return
            end
        end
        if gun~=shot.gun and not shot.si_key and (certain or not shot.certain) then
            local nsched=calc_sched(gun,dist)
            local fire_at=sched_fire_at(gun,dist,shot.t0)
            if shot.entry and not shot.entry.fired then
                shot.entry.gun=gun; pq_set_sched_at(shot.entry, shot.t0, nsched, false)
                fire_at=shot.entry.fire_at
                dlog("[gp] reaim shot -> "..tostring(gun).." | sched "..fl(nsched).."ms")
                shot.gun=gun
                detect_aim(att, epos, gun, fire_at, nsched)
                if certain then shot.certain=true end
            elseif certain and fire_at>ms()+20 then
                shot.entry=enqueue_parry(fire_at-ms(),att,gun,epos,{skip_lead=true})
                detect_aim(att, epos, gun, fire_at, nsched)
                dlog("[gp] requeue shot -> "..tostring(gun).." | sched "..fl(nsched).."ms")
                shot.gun=gun; shot.certain=true
            else
                dlog("[gp] reaim too late / uncertain -> keep "..tostring(shot.gun))
            end
        elseif gun~=shot.gun and shot.si_key then
            stale_log_once("si_lock_"..tostring(shot.gun), "[gp] SI locked -> keep "..tostring(shot.gun))
        else
            stale_log_once("claim_"..tostring(att or gun), "[gp] already claimed this shot -> "..tostring(gun))
        end
        return
    end
    if win_last[si_key] and ms()<win_last[si_key] then dlog("[gp] same shooter busy, skip"); return end
    if pq_has(gun, att) then dlog("[gp] pq busy, skip SI"); return end
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
    if gun=="phoenix" and cfg.phx_rocket~=false then
        dlog("[gp] phoenix track | "..(dist and fl(dist) or "?").."st")
        t_win=ms()
        win_last[si_key]=ms()+math.max(400,sched)+350
        cycle_fired=false; cycle_fired_t=0
        att=resolve_att_for_parry(att, epos, gun)
        if not att then
            att=near_ent(epos)
            if att and gun then
                local g=gun_from_id(att)
                if g and g~=gun then att=nil end
            end
        end
        if not att then
            if cfg.debug then stale_log_once("si_ghost", "[gp] phx SI skip no valid firer in range") end
            return
        end
        shot.claimed=true; shot.gun=gun; shot.gun_src=gun_src; shot.t=ms(); shot.t0=ms(); shot.si_key=si_key
        shot.entry=nil
        st.phx_flight=true
        if not st.phx_log.active then st.phx_log.t0=ms(); st.phx_log.active=true; st.phx_log.press_t=0 end
        if dist then st.phx_log.dist=dist end
        st.phx_log.sched=sched
        return
    end
    if gun=="phoenix" then
        dlog("[gp] phoenix | sched "..fl(sched).."ms")
    end
    t_win=ms()
    win_last[si_key]=ms()+math.max(300,sched)+350
    cycle_fired=false; cycle_fired_t=0
    att=resolve_att_for_parry(att, epos, gun)
    if not att then
        att=near_ent(epos)
        if att and gun then
            local g=gun_from_id(att)
            if g and g~=gun then att=nil end
        end
    end
    if not att then
        att=pick_firer_gun(gun, {require_aim=false})
    end
    if not att or not att_in_detect_range(att, epos) then
        if cfg.debug then stale_log_once("si_ghost", "[gp] SI skip no valid firer in range") end
        return
    end
    if gun~="phoenix" then
        dlog("[gp] "..tostring(gun).." | sched "..fl(sched).."ms | "..(dist and fl(dist) or "?").."st")
    end
    shot.claimed=true; shot.gun=gun; shot.gun_src=gun_src; shot.t=ms(); shot.t0=ms(); shot.si_key=si_key
    si_done[si_key]=ms()
    shot.entry=enqueue_parry(sched,att,gun,epos)
end


on_flash=function(gun,fpos,from_map)
    from_map=from_map~=false
    local flash_gun=gun
    local firer=fpos and pick_firer(fpos, gun, {require_aim=false})
    local id_gun=firer and gun_from_id(firer)
    if id_gun then
        if flash_gun~=id_gun then dlog("[gp] gun id -> "..id_gun) end
        flash_gun=id_gun
    elseif firer and not from_map then
        flash_gun=gun_from_att(firer, flash_gun)
    end
    gun=flash_gun
    local my=get_pos()
    local dist=nil
    if my and firer then local hp=head_pos(firer); if hp then dist=sq(dsq(my,hp)) end end
    local t0=shot and shot.t0 or 0
    local already=parry_confirmed_since(t0)
    local orphan=(not shot or not shot.claimed) and pq_pending_non_s2()
    if orphan and orphan.gun==gun then adopt_pq_shot(orphan) end
    if shot and shot.claimed and shot.gun==gun then
        local pressed=shot.pq_fired or (shot.entry and shot.entry.fired)
        if already then
            st.last_gun=gun; st.gun_t=ms()
            if firer then att_gun[firer]=gun; att_gun_t[firer]=ms() end
            mark_linger(gun)
            st.flash_gun=gun; st.flash_t=ms()
            dlog("[gp] flash skip (cycle handled)")
            return
        end
        if pressed then
            st.last_gun=gun; st.gun_t=ms()
            if firer then att_gun[firer]=gun; att_gun_t[firer]=ms() end
            mark_linger(gun)
            st.flash_gun=gun; st.flash_t=ms()
            dlog("[gp] flash skip (pq fired)")
            local miss_t0=t0
            task.spawn(function()
                task.wait(0.45)
                if parry_confirmed_since(miss_t0) then return end
                clear_stale_shot()
            end)
            return
        end
        if shot and shot.entry and not shot.entry.fired then
            st.last_gun=gun; st.gun_t=ms()
            if firer then att_gun[firer]=gun; att_gun_t[firer]=ms() end
            shot.flashed=true; shot.certain=true
            if firer and cfg.gp_aim then gp_snap(firer, fpos, gun, shot.entry.fire_at) end
            mark_linger(gun)
            st.flash_gun=gun; st.flash_t=ms()
            dlog("[gp] flash confirm pending queue")
            return
        end
    end
    if shot and shot.claimed and shot.gun and gun~=shot.gun then
        if id_gun then
            local fire_at=sched_fire_at(gun,dist,shot.t0)
            if shot.entry and not shot.entry.fired and not already and fire_at>ms()+15 then
                dlog("[gp] flash reaim "..tostring(shot.gun).." -> "..tostring(gun))
                shot.entry.gun=gun; pq_set_sched_at(shot.entry, shot.t0, calc_sched(gun,dist), false)
                shot.gun=gun; shot.gun_src="id"; shot.certain=true
            elseif not already then
                dlog("[gp] flash id late -> keep queue, cache "..tostring(gun))
            else
                gun=shot.gun
            end
        elseif shot.si_key or shot.certain or already or shot.pq_fired then
            dlog("[gp] flash fix "..tostring(gun).." -> "..tostring(shot.gun))
            gun=shot.gun
        elseif shot.entry and not shot.entry.fired and not already then
            local fire_at=sched_fire_at(gun,dist,shot.t0)
            if fire_at>ms()+15 then
                dlog("[gp] flash reaim "..tostring(shot.gun).." -> "..tostring(gun))
                shot.entry.gun=gun; pq_set_sched_at(shot.entry, shot.t0, calc_sched(gun,dist), false)
                shot.gun=gun
                if from_map then shot.certain=true end
            else
                dlog("[gp] flash reaim late -> keep "..tostring(shot.gun))
                gun=shot.gun
            end
        else
            gun=shot.gun
        end
    end
    st.last_gun=gun; st.gun_t=ms()
    if firer then att_gun[firer]=gun; att_gun_t[firer]=ms() end
    for k in next,active_z do zone_win[k]=oc()+mx(flash_cd,0.35) end; active_z={}
    dlog("[detect] flash "..tostring(gun))
    t_win=nil
    local flash_sched=calc_sched(gun, dist)
    detect_aim(firer, fpos, gun, nil, flash_sched, from_map and {certain=true} or nil)
    local flash_handled=false
    if gun=="phoenix" and st.phx_log.active and st.phx_log.t0>0 then
        local flight=ms()-st.phx_log.t0
        local dist=st.phx_log.dist or 0
        local spd=(flight>0 and dist>0) and (dist/(flight/1000)) or 0
        local lead=(st.phx_log.press_t>0) and (ms()-st.phx_log.press_t) or -1
        log(string.format("[phx] IMPACT | dist %dst | flight %dms | real_spd %.1f st/s | pressed %dms early | cfg_spd %d",
            fl(dist),fl(flight),spd,fl(lead),cfg.phx_spd or 80))
        local t_impact=ms()
        local t0=st.phx_log.t0
        if cfg.phx_rocket~=false then
            flash_handled=phx_rocket_seen or pq_has("phoenix", firer, true) or shot_pq_fired()
        else
            st.phx_log.active=false
            st.phx_flight=false
            local missed=(st.parry_t<(t0 or 0) or (st.phx_log.press_t or 0)==0) and not parry_this_cycle(gun)
            if missed and cfg.gp and not pq_has("phoenix", firer, true) then
                local mg_tbl=(type(cfg.mg)=="table") and cfg.mg or {}
                local fb=mx(15, fl((mg_tbl.phoenix or 200)*0.12))
                dlog("[phx] impact parry +"..fl(fb).."ms")
                if firer and cfg.gp_aim then gp_snap(firer, fpos, gun, ms()+fb) end
                if not shot then new_shot() end
                shot.claimed=true; shot.gun=gun; shot.certain=from_map
                shot.t=ms(); shot.t0=ms(); shot.flashed=true
                shot.entry=enqueue_parry(fb,firer,gun,fpos)
                flash_handled=true
            end
            task.spawn(function()
                task.wait(0.5)
                if st.parry_t>=t_impact-200 then log("[phx] parried")
                else log("[phx] missed") end
            end)
        end
    end
    local pending=shot and shot.claimed and shot.entry and not shot.entry.fired
    if pending and shot.entry.fire_at>ms()+40 then
        dlog("[gp] flash confirm pending queue")
        shot.flashed=true
        if shot.gun==gun then shot.certain=true end
        if firer and cfg.gp_aim then gp_snap(firer, fpos, gun, shot.entry.fire_at) end
        flash_handled=true
    elseif pending and shot.entry.fire_at<=ms()+100 then
        dlog("[gp] flash keep pending queue")
        shot.flashed=true
        if firer and cfg.gp_aim then gp_snap(firer, fpos, gun, shot.entry.fire_at) end
        flash_handled=true
    elseif gun=="phoenix" and shot and (shot.pq_fired or flash_handled) then
        dlog("[gp] flash skip phx requeue")
        flash_handled=true
    elseif already then
        dlog("[gp] flash skip (parry confirmed)")
        flash_handled=shot and shot.claimed
    elseif pgui_only_claim() and st.parry_t<(shot.t0 or 0) and cfg.gp and flash_fallback_ok(gun, firer) then
        local fb=mx(80, fl(calc_sched(gun, dist)*0.12))
        dlog("[gp] flash override pgui claim +"..fl(fb).."ms")
        if firer and cfg.gp_aim then gp_snap(firer, fpos, gun, ms()+fb) end
        shot.gun=gun; shot.certain=from_map; shot.flashed=true
        shot.entry=enqueue_parry(fb,firer,gun,fpos)
        flash_handled=true
    elseif cfg.gp and flash_fallback_ok(gun, firer) and not (gun=="phoenix" and cfg.phx_rocket~=false) then
        local fb=mx(80, fl(calc_sched(gun, dist)*0.12))
        dlog("[gp] flash fallback +"..fl(fb).."ms (no SI)")
        if firer and cfg.gp_aim then gp_snap(firer, fpos, gun, ms()+fb) end
        if not shot then new_shot() end
        shot.claimed=true; shot.gun=gun; shot.certain=from_map; shot.flashed=true; shot.t=ms(); shot.t0=ms()
        shot.entry=enqueue_parry(fb,firer,gun,fpos)
        flash_handled=true
    end
    local t_flash=ms()
    local press_t=st.last_gp
    local miss_t0=shot and shot.t0 or t_flash
    if flash_handled then
        task.spawn(function()
            task.wait(2.5)
            if parry_confirmed_since(miss_t0) or st.parry_t>=t_flash-250
                or (press_t>0 and press_t>=t_flash-1400 and press_t<=t_flash+120) then
                st.miss_n=0
                return
            end
            st.miss_n=st.miss_n+1; dlog("[gp] miss #"..st.miss_n)
            clear_gp_aim()
            cycle_fired=false; cycle_fired_t=0
            if st.miss_n>=st.miss_max then
                st.miss_n=0; log("[gp] miss reset"); rn("AP reset","Redline",1)
            end
        end)
    end
    if flash_handled then
        mark_linger(gun)
        st.flash_gun=gun; st.flash_t=t_flash
        local block=mx(gun_w2f(gun)+400, 1200)
        if shot and shot.si_key then win_last[shot.si_key]=ms()+block end
        if firer then win_last[firer]=ms()+block end
        if fpos then win_last[zk(fpos)]=ms()+block end
    end
    local pq_pending=pq_pending_non_s2()
    if not pq_pending then new_shot() end
    dlog("[gp] flash -> "..tostring(gun))
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
        if ms()-st.last_parry<350 then return end
        local pgun=shot and shot.gun or st.last_gun
        local patt=shot and shot.entry and shot.entry.att or st.att
        local psnap=shot and shot.entry and shot.entry.snap
        local now=ms()
        st.last_parry=now
        st.parry_t=now; st.miss_n=0
        st.gp_lock=now+180
        st.post_parry_until=now+220
        st.await_cassette=false
        st.linger_until=now+280
        st.flash_t=0; st.flash_gun=nil
        cycle_fired=false
        clear_gp_aim()
        win_last={}
        mark_pgui_parried()
        if shot and shot.entry and not shot.entry.done then
            shot.entry.done=true
            if shot.pq_fired or shot.entry.fired then shot.entry.fired=true end
        end
        for _,e in ipairs(pq.q) do
            if not e.s2 and not e.fired and shot and shot.entry==e then
                e.done=true
                if shot.pq_fired or e.fired then e.fired=true end
            end
        end
        for _,e in ipairs(pq.q) do
            if not e.fired and not e.s2 and not e.done then
                e.fire_at=mx(e.fire_at, st.post_parry_until)
            end
        end
        if st.phx_flight then st.phx_flight=false end
        if cfg.aura_cancel then st.aura_pending=false end
        local next_pq=pq_pending_non_s2()
        if next_pq then
            adopt_pq_shot(next_pq)
        else
            new_shot()
        end
        log("[gp] PARRY confirmed")
    else
        if cfg.aura and cfg.aura_cancel then st.aura_pending=false; dlog("[aura] cancel: opp parry") end
        dlog("[gp] parry (enemy?)")
    end
end

try_melee=function()
    if in_lobby() then return end
    if not cfg.mp or st.mp_busy then return end
    local now=ms(); if now-st.mp_t<cfg.mp_cd then return end
    st.mp_busy=true; st.mp_t=now; dlog("[mp] F")
    task.spawn(function() press_f(); task.wait(0.32); st.mp_busy=false end)
end

function mp_face_ok(att,kpos,my)
    if not att then return true end
    local src=att
    local ok,ch=pcall(function() return att.Character end); if ok and ch then src=ch end
    local hd=try(function() return src:FindFirstChild("Head") end) or try(function() return src:FindFirstChild("HumanoidRootPart") end)
    local cf=hd and try(function() return hd.CFrame end)
    local look=cf and try(function() return cf.LookVector end)
    if not look then return true end
    return vang(look,Vector3.new(my.X-kpos.X,my.Y-kpos.Y,my.Z-kpos.Z))<=(cfg.mp_ang or 90)
end

function att_root(att)
    if not att then return nil end
    local ok,ch=pcall(function() return att.Character end)
    return ((ok and ch) or att):FindFirstChild("HumanoidRootPart")
end

local melee_anims={
    ["rbxassetid://71188211641772"]=true,
    ["rbxassetid://87457990259233"]=true,
    ["rbxassetid://105441036119013"]=true,
}
function animator_of(char)
    if not char then return nil end
    local hum=try(function() return char:FindFirstChildOfClass("Humanoid") end)
    local anr=hum and try(function() return hum:FindFirstChildOfClass("Animator") end)
    if not anr then anr=try(function() return char:FindFirstChildOfClass("AnimationController") end) end
    return anr
end
function active_anim_ids(animator)
    local out={}
    local base=inst_addr(animator); if not base then return out end
    local s=mem.r_ptr(base+OFF.anim_active)
    local e=mem.r_ptr(base+OFF.anim_active+0x8)
    if s==0 or e==0 or e<s or (e-s)>0x8000 then return out end
    local n=0
    for a=s, e-0x8, 0x10 do
        local track=mem.r_ptr(a)
        if track~=0 then
            local anim=mem.r_ptr(track+OFF.track_anim)
            if anim~=0 then
                local id=mem.r_rbxstr(anim+OFF.anim_id)
                if id~="" then out[#out+1]=id end
            end
        end
        n=n+1; if n>=24 then break end
    end
    return out
end

function dump_attrs(obj,label)
    local base=inst_addr(obj); if not base then log("[attr] "..(label or "?").." no address"); return end
    local cont=mem.r_ptr(base+OFF.attr_cont)
    log("[attr] ==== "..(label or "?").." ==== inst="..string.format("0x%x",base).." cont="..string.format("0x%x",cont))
    if cont==0 then log("[attr] no attribute container (no attributes set)"); return end
    local node=mem.r_ptr(cont+OFF.attr_list)
    local guard=0
    while node~=0 and guard<24 do
        guard=guard+1
        local row={}
        for o=0,0x78,0x8 do row[#row+1]=string.format("+%02x=0x%x",o,mem.r_ptr(node+o)) end
        log("[attr] node"..guard.." @0x"..string.format("%x",node))
        log("[attr]   "..table.concat(row," "))
        local nm=mem.r_rbxstr(node)
        local val=mem.r_ptr(node+OFF.attr_val)
        log("[attr]   name?='"..tostring(nm).."' valPtr=0x"..string.format("%x",val).." valAt+0xd0="..mem.r_int((val~=0 and val or node)+OFF.val))
        node=mem.r_ptr(node+OFF.attr_next)
    end
    log("[attr] ==== done, paste this back ====")
end

on_melee=function(ev,src)
    if not cfg.mp then return end
    local my=get_pos(); if not my then return end
    local ok,kpos=pcall(function() return ev.Position end)
    local att
    local zero_pos=not(ok and kpos and (kpos.X~=0 or kpos.Y~=0 or kpos.Z~=0))
    if zero_pos then
        local best,bd
        local maxd=(cfg.mp_maxd or 20)+2
        for _,t in ipairs(tgts_cached()) do
            local d=sq(dsq(my,t.pos))
            if d<=maxd and (not bd or d<bd) then bd=d; best=t end
        end
        if not best then return end
        kpos=best.pos; att=best.ent or best.char
        dlog("[mp] "..tostring(src).." swing (zero-pos) -> nearest enemy "..fl(bd).."st")
    end
    local dist=sq(dsq(my,kpos))
    if dist>(cfg.mp_detect or 32) then dlog("[mp] "..tostring(src).." too far "..fl(dist).."st (detect "..(cfg.mp_detect or 32)..")"); return end
    if not att then att=near_ent(kpos) end
    if att and not att_in_range(att, (cfg.mp_detect or 32)+4) then att=nil end
    dlog("[mp] "..tostring(src).." swing @ "..fl(dist).."st | att "..(att and (try(function() return att.Name end) or "?") or "none"))
    if not mp_face_ok(att,kpos,my) then dlog("[mp] facing away"); return end
    if dist<=(cfg.mp_maxd or 20) then dlog("[mp] in range -> parry"); try_melee(); return end
    local root=att_root(att)
    local vel=root and (try(function() return root.Velocity end) or try(function() return root.AssemblyLinearVelocity end))
    local apos=root and try(function() return root.Position end)
    if not(vel and apos) then
        if dist<=(cfg.mp_detect or 32) then dlog("[mp] no vel, close enough -> parry"); try_melee() end
        return
    end
    local dx=my.X-apos.X; local dy=my.Y-apos.Y; local dz=my.Z-apos.Z
    local m=sq(dx*dx+dy*dy+dz*dz); if m<=0 then return end
    local closing=vel.X*(dx/m)+vel.Y*(dy/m)+vel.Z*(dz/m)
    if closing<=1 then
        if dist<=(cfg.mp_maxd or 20)+4 then try_melee() end
        dlog("[mp] not closing in ("..fl(closing).." st/s)"); return
    end
    local gap=sq(dsq(my,apos))-(cfg.mp_maxd or 20)
    local t_in=gap/closing
    local win=(cfg.mp_window or 220)/1000
    if t_in<=0 or t_in>=win then dlog("[mp] timing off, t_in "..fl(t_in*1000).."ms (win "..(cfg.mp_window or 220)..")"); return end
    dlog("[mp] closing, parry in "..fl(t_in*1000).."ms")
    local fire=ms()
    task.spawn(function()
        local wait_t=cl(t_in-0.04,0,win)
        if wait_t>0 then task.wait(wait_t) end
        if ms()-fire>(cfg.mp_window or 220)+50 then dlog("[mp] swing went stale"); return end
        local mp2=get_pos(); local ap2=att_root(att) and try(function() return att_root(att).Position end)
        if mp2 and ap2 and sq(dsq(mp2,ap2))<=(cfg.mp_maxd or 20)+5 then try_melee()
        else dlog("[mp] didnt close enough by fire time") end
    end)
end

is_own=function(ev)
    local my=get_pos(); if not my then return false end
    local ok,ep=pcall(function() return ev.Position end)
    if not ok or not ep then return false end
    return dsq(my,ep)<9
end

on_cassette=function()
    st.linger_until=0; st.flash_t=0; st.flash_gun=nil
    st.await_cassette=false; st.post_parry_until=0
    pg_seen={}; pg_parried={}
    win_last={}
    cycle_fired=false
    clear_gp_aim()
    new_shot()
    dlog("[gp] cassette -> new shot")
end

function scan_folder(folder,seen,vfx)
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
            local gun=maps.glare and maps.glare[nm]
            if not gun then continue end
            seen[addr]=oc()
            local dist=pos and my and sq(dsq(my,pos)) or math.huge
            if dist<SELF_R then continue end
            if dist<=(cfg.glare_d or 150) then dlog("[gp] glare "..nm); on_window(gun,pos,nm,true)
            elseif dist<=(cfg.gp_dist or 610) then
                st.last_gun=gun; st.gun_t=ms()
                if shot and shot.claimed and shot.gun~=gun and not shot_pq_fired() then
                    if shot_gun_locked() then
                        stale_log_once("glare_lock_"..tostring(shot.gun), "[gp] glare skip reaim (locked "..tostring(shot.gun)..")")
                    elseif shot.entry and not shot.entry.fired then
                        local fire_at=sched_fire_at(gun,nil,shot.t0)
                        shot.entry.gun=gun; pq_set_sched_at(shot.entry, shot.t0, calc_sched(gun,nil), false)
                        fire_at=shot.entry.fire_at
                        shot.gun=gun; shot.certain=true
                        local att=pos and pick_firer(pos, gun, {require_aim=true})
                        detect_aim(att, pos, gun, fire_at, calc_sched(gun,nil))
                        dlog("[gp] glare id reaim -> "..gun)
                    elseif sched_fire_at(gun,nil,shot.t0)>ms()+40 then
                        local fire_at=sched_fire_at(gun,nil,shot.t0)
                        local att=pos and pick_firer(pos, gun, {require_aim=true})
                        local gs=calc_sched(gun,nil)
                        detect_aim(att, pos, gun, fire_at, gs)
                        shot.entry=enqueue_parry(fire_at-ms(),nil,gun,nil,{skip_lead=true}); shot.gun=gun; shot.certain=true
                        dlog("[gp] glare id requeue -> "..gun)
                    end
                end
            else
                local att=pos and pick_firer(pos, gun, {require_aim=true})
                if gp_los_ok(att,pos) then
                    dlog("[gp] los bypass glare "..nm.." "..fl(dist).."st")
                    on_window(gun,pos,nm,true)
                end
            end
        else
            if maps.win and maps.win[nm] then
                if not pos then continue end
                if seen_win[e] then continue end
                if parry_block_active(st.flash_gun or st.last_gun, true) then continue end
                local dist=pos and my and sq(dsq(my,pos)) or math.huge
                if dist<SELF_R then continue end
                if dist>(cfg.gp_dist or 610) then
                    local att=pos and pick_firer(pos, st.last_gun, {require_aim=true})
                    if not gp_los_ok(att,pos) then continue end
                    dlog("[gp] los bypass "..fl(dist).."st")
                end
                local key=zk(pos)
                if si_done[addr] and ms()<si_done[addr] then continue end
                if st.flash_t>0 and (ms()-st.flash_t)<mx(1200, gun_w2f(st.flash_gun or st.last_gun or "castigate")+300) then continue end
                clear_stale_shot()
                if shot and shot.claimed and shot.si_key then
                    local near=pick_firer(pos, shot.gun or st.last_gun, {require_aim=false})
                    if (near and near==st.att) or key==shot.si_key then
                        si_done[addr]=ms()+mx(1200, gun_w2f(shot.gun or st.last_gun or "castigate")+400)
                        seen_win[e]=true
                        continue
                    end
                end
                local exp=zone_win[key]
                if exp and oc()<exp then continue end
                seen_win[e]=true; zone_win[key]=oc()+zone_cd; active_z[key]=true
                si_done[addr]=ms()+mx(1200, gun_w2f(st.last_gun or "castigate")+400)
                if shot and shot.claimed and shot.si_key and not shot_pq_fired() and not clear_stale_shot() then continue end
                dlog("[gp] WINDOW "..nm.." | "..fl(dist).."st")
                on_window(nil,pos,nm,false)
            elseif maps.flash and maps.flash[nm] then
                local dist=pos and my and sq(dsq(my,pos)) or math.huge
                if dist<SELF_R then seen[addr]=oc(); continue end
                seen[addr]=oc()
                on_flash(maps.flash[nm],pos,true)
            elseif nm=="defaultParry" or nm=="defaultParryOutsider" then
                seen[addr]=oc(); on_parry(e)
            elseif nm=="SlashAcross" or nm=="GlitchAura" then
                local dist=pos and my and sq(dsq(my,pos)) or math.huge
                if dist<3 and dist~=math.huge then seen[addr]=oc(); continue end
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
                if mp_skip[nm] then continue end
                local dist=pos and my and sq(dsq(my,pos)) or math.huge
                if dist<=(cfg.mp_detect or 32) and dist>=2 then
                    local last=mp_unk[nm] or 0
                    if oc()-last>2 then mp_unk[nm]=oc(); dlog("[mp scan] '"..nm.."' @ "..fl(dist).."st") end
                end
            end
        end
    end
end

function pgui_skip_stale(eff_nm, ve)
    if eff_nm~="Cross" then return false end
    for _,nm in ipairs({"MonarchGlare","SiegeGlare","PhoenixGlare"}) do
        if try(function() return ve:FindFirstChild(nm) end) then return true end
    end
    return false
end

function scan_pgui()
    if in_lobby() then return end
    if not cfg.gp then return end
    scan_pg_n=(scan_pg_n+1)%2
    if scan_pg_n~=0 then return end
    local pgui=lp and lp:FindFirstChild("PlayerGui"); if not pgui then return end
    local ve=pgui:FindFirstChild("VisualEffects") or try(function() return pgui:FindFirstChild("VisualEffects",true) end)
    if not ve then return end
    local now=oc()
    for _,eff_nm in ipairs(pgui_order) do
        local gun=maps.pgui[eff_nm]
        if not gun then continue end
        if pgui_skip_stale(eff_nm, ve) then continue end
        local eff=ve:FindFirstChild(eff_nm); if not eff then continue end
        local ok_a,addr=pcall(function() return tostring(eff.Address) end); if not ok_a then continue end
        if pg_parried[addr] then continue end
        if not pg_seen[addr] then
            local t0=ms()
            pg_seen[addr]=now; st.last_gun=gun; st.gun_t=t0
            if shot and shot.claimed and not shot_pq_fired() then
                local att=st.att or (shot.entry and shot.entry.att)
                local id_g=att and gun_from_id(att)
                if id_g then gun=id_g end
                if shot.gun~=gun then
                    if shot_gun_locked() then
                        stale_log_once("pgui_lock_"..tostring(shot.gun), "[gp] pgui skip reaim (locked "..tostring(shot.gun)..")")
                    elseif gun=="castigate" and shot.gun and shot.gun~="castigate" then
                        stale_log_once("pgui_cross_"..tostring(shot.gun), "[gp] pgui skip stale Cross, keep "..tostring(shot.gun))
                    elseif shot.entry and not shot.entry.fired then
                        local fire_at=sched_fire_at(gun,nil,shot.t0)
                        shot.entry.gun=gun; pq_set_sched_at(shot.entry, shot.t0, calc_sched(gun,nil), false)
                        fire_at=shot.entry.fire_at
                        shot.gun=gun; shot.gun_src=id_g and "id" or "pgui"
                        local ra=resolve_att(st.att or shot.entry.att, shot.entry.snap, gun) or pick_firer_gun(gun)
                        if ra then st.att=ra; shot.entry.att=ra end
                        detect_aim(ra, shot.entry.snap, gun, fire_at, calc_sched(gun,nil))
                        dlog("[gp] pgui glare reaim -> "..gun)
                    elseif sched_fire_at(gun,nil,shot.t0)>ms()+40 then
                        local fire_at=sched_fire_at(gun,nil,shot.t0)
                        local gs=calc_sched(gun,nil)
                        local ra=resolve_att(st.att, nil, gun) or pick_firer_gun(gun)
                        if ra then st.att=ra end
                        detect_aim(ra, nil, gun, fire_at, gs)
                        shot.entry=enqueue_parry(fire_at-ms(),ra,gun,nil,{skip_lead=true})
                        shot.gun=gun; shot.gun_src=id_g and "id" or "pgui"
                        dlog("[gp] pgui glare requeue -> "..gun)
                    end
                end
                if not shot_gun_locked() or shot.gun==gun then
                    shot.certain=true
                    if shot.gun==gun and shot.entry and not shot.entry.fired and not shot_pq_fired() then
                        local att=resolve_att(st.att, shot.entry.snap, gun) or pick_firer_gun(gun)
                        if att then st.att=att; shot.entry.att=att end
                        local gs=shot.entry.sched_ms or calc_sched(gun, nil)
                        detect_aim(att, shot.entry.snap, gun, shot.entry.fire_at, gs)
                    end
                end
            elseif not (shot and shot.claimed) then
                maybe_reset_shot()
                if not shot then new_shot() end
                if ms()<st.post_parry_until then continue end
                if parry_cooldown_active() then continue end
                if parry_block_active(gun, true) then continue end
                local sched=calc_sched(gun, nil)
                local att=resolve_att_for_parry(st.att, nil, gun)
                if not att then
                    if cfg.debug then stale_log_once("pgui_ghost", "[gp] pgui skip no firer in range") end
                    continue
                end
                st.att=att
                pg_parried[addr]=true
                detect_aim(att, nil, gun, ms()+sched, sched)
                shot.claimed=true; shot.gun=gun; shot.gun_src="pgui"; shot.certain=true
                shot.t=t0; shot.t0=t0
                shot.entry=enqueue_parry(sched, att, gun, nil)
                dlog("[gp] pgui queue -> "..gun.." | sched "..fl(sched).."ms")
            end
        end
    end
    for addr,t in pairs(pg_seen) do
        if now-t>5 then pg_seen[addr]=nil; pg_parried[addr]=nil end
    end
end

phx_nearest=nil
phx_scan_t=0
phx_rocket_seen=false

local function phx_part_pos(inst)
    if not inst then return nil end
    local ok,p=pcall(function()
        if inst:IsA("BasePart") then return inst.Position end
        if inst.PrimaryPart then return inst.PrimaryPart.Position end
        local bp=inst:FindFirstChildWhichIsA("BasePart", true)
        if bp then return bp.Position end
        return inst:GetPivot().Position
    end)
    return ok and p or nil
end

local function phx_is_rocket(nm)
    nm=tostring(nm or ""):lower()
    return nm:find("rocket", 1, true)~=nil
end

local function phx_queue_impact(att, pos, sched, force_now)
    if pq_has("phoenix", att, true) or parry_this_cycle("phoenix") then return end
    sched=mx(8, fl(sched or 0))
    st.phx_flight=true
    if not st.phx_log.active then st.phx_log.t0=ms(); st.phx_log.active=true; st.phx_log.press_t=0 end
    if pos and get_pos() then st.phx_log.dist=sq(dsq(get_pos(), pos)) end
    detect_aim(att, pos, "phoenix", ms()+sched, sched, {certain=true})
    if force_now and sched<=12 then
        if gun_press(true) then
            st.phx_log.press_t=ms()
            extend_shot_block("phoenix", shot and shot.si_key, att)
            if shot then shot.pq_fired=true end
        end
        return
    end
    if shot and shot.claimed and shot.gun=="phoenix" and shot.entry and not shot.entry.fired then
        pq_set_sched(shot.entry, sched, false)
        shot.entry.att=att; shot.entry.snap=pos; shot.entry.gun="phoenix"
        detect_aim(att, pos, "phoenix", shot.entry.fire_at, sched, {certain=true})
    else
        if not shot then new_shot() end
        shot.claimed=true; shot.gun="phoenix"; shot.certain=true
        shot.t=ms(); shot.t0=ms(); shot.flashed=true
        shot.entry=enqueue_parry(sched, att, "phoenix", pos)
    end
end

function scan_phx_rocket(folder)
    if in_lobby() then return end
    if not cfg.gp or cfg.phx_rocket==false then phx_nearest=nil; phx_rocket_seen=false; return end
    local my=get_pos(); if not my then return end
    local now=ms()
    local dt=mx(0.001, (now-(phx_scan_t or now))/1000)
    phx_scan_t=now
    local max_rng=cfg.gp_dist or 610
    local nearest_dist, nearest_pos, nearest_att=nil, nil, nil
    local function scan_child(e)
        local nm=try(function() return e.Name end) or ""
        if not phx_is_rocket(nm) then return end
        local pos=phx_part_pos(e)
        if not pos then return end
        local dist=sq(dsq(my, pos))
        if dist<SELF_R or dist>max_rng then return end
        if not nearest_dist or dist<nearest_dist then
            nearest_dist, nearest_pos=dist, pos
        end
    end
    if folder then
        local kids=try(function() return folder:GetChildren() end)
        if kids then for _,e in ipairs(kids) do scan_child(e) end end
    end
    local prev=phx_nearest
    phx_nearest=nearest_dist
    if not nearest_dist then phx_rocket_seen=false; return end
    local closing=0
    if prev and dt>0 then
        local delta=prev-nearest_dist
        if abs(delta)<40 then closing=delta/dt end
    end
    if closing<=5 then phx_rocket_seen=false; return end
    phx_rocket_seen=true
    nearest_att=pick_firer(nearest_pos, "phoenix", {require_aim=true})
    local tti_ms=(closing>1) and (nearest_dist/closing)*1000 or 9999
    local lead=cfg.phx_lead or 60
    local radius=cfg.phx_radius or 30
    if pq_has("phoenix", nearest_att, true) or parry_this_cycle("phoenix") then return end
    if nearest_dist<=radius or tti_ms<=lead then
        dlog("[phx] impact dist "..fl(nearest_dist).." tti "..fl(tti_ms).."ms")
        phx_queue_impact(nearest_att, nearest_pos, mx(8, tti_ms-lead*0.5), nearest_dist<=radius)
    elseif tti_ms<850 then
        local mg_tbl=(type(cfg.mg)=="table") and cfg.mg or {}
        local sched=mx(15, tti_ms-(mg_tbl.phoenix or 200)-(cfg.ping or 47))
        dlog("[phx] rocket tti "..fl(tti_ms).."ms sched "..fl(sched))
        phx_queue_impact(nearest_att, nearest_pos, sched, false)
    end
end

function scan_effects()
    if in_lobby() then return end
    local eff=try(function() return workspace:FindFirstChild("Effects") end)
    if eff then
        scan_folder(eff,seen_eff,false)
        scan_phx_rocket(eff)
    end
    scan_vfx_n=(scan_vfx_n+1)%2
    if scan_vfx_n~=0 then return end
    for _,fn in ipairs({"VisualEffects","LocalEffects","VFX","ClientEffects"}) do
        local f=try(function() return workspace:FindFirstChild(fn) end)
        if f then scan_folder(f,seen_vfx,true) end
    end
end

task.spawn(function()
    while loops_active do
        task.wait(5); local t=oc()
        for addr,at in next,seen_pt do if t-at>7 then seen_part[addr]=nil; seen_pt[addr]=nil end end
        for addr,t in pairs(si_done) do if ms()-t>3000 then si_done[addr]=nil end end
        for k,exp in next,zone_win do if type(exp)=="number" and t-exp>5 then zone_win[k]=nil end end
        local now_ms=ms()
        for k,_ in next,att_gun do
            if now_ms-(att_gun_t[k] or 0)>att_gun_ttl then att_gun[k]=nil; att_gun_t[k]=nil end
        end
        if now_ms-(phx_scan_t or 0)>500 then phx_nearest=nil; phx_rocket_seen=false end
    end
end)

task.spawn(function()
    local last_pid
    while loops_active do
        local pid=cur_place_id()
        if pid and pid~=last_pid then
            last_pid=pid
            log_place_id("changed")
        end
        task.wait(2)
    end
end)

draw_font=resolve_draw_font() or Drawing.Fonts.Plex or Drawing.Fonts.System or Drawing.Fonts.UI
draw_font_cute=draw_font
draw_font_out=Color3.fromRGB(16, 14, 24)

function style_text(t, size, col)
    t.Font=draw_font_cute; t.Size=size; t.Outline=true
    pcall(function() t.OutlineColor=draw_font_out end)
    if col then t.Color=col end
    return t
end
esp_obj={}; esp_sp={}

function mk_box_ln(col)
    local ln=Drawing.new("Line"); ln.Visible=false; ln.Thickness=1.5; ln.ZIndex=2
    if col then ln.Color=col end
    return ln
end

function hide_esp_draw(d)
    if not d then return end
    d.nm.Visible=false; d.hp.Visible=false; d.ps.Visible=false
    if d.box then for _,ln in ipairs(d.box) do ln.Visible=false end end
end

function rm_esp_chams(d)
    if not d then return end
    if d.hl then pcall(function() d.hl:Destroy() end); d.hl=nil; d.hl_char=nil; d.hl_rgb=nil end
end

function hide_esp_chams(d)
    if d and d.hl then pcall(function() d.hl.Enabled=false end) end
end

function sync_esp_chams(d, char, on)
    if not on or not cfg.esp_chams or not char then hide_esp_chams(d); return end
    local r,g,b=cfg.esp_r or 220, cfg.esp_g or 170, cfg.esp_b or 255
    local ck=r*65536+g*256+b
    if d.hl_char~=char then
        rm_esp_chams(d)
        d.hl=try(function()
            local h=Instance.new("Highlight")
            h.FillColor=Color3.fromRGB(r,g,b)
            h.OutlineColor=Color3.fromRGB(r,g,b)
            h.FillTransparency=0.55
            h.OutlineTransparency=0.35
            h.DepthMode=Enum.DepthMode.AlwaysOnTop
            h.Adornee=char
            h.Parent=char
            return h
        end)
        d.hl_char=char; d.hl_rgb=ck
    elseif d.hl then
        pcall(function()
            if d.hl_rgb~=ck then
                d.hl_rgb=ck
                local c=Color3.fromRGB(r,g,b)
                d.hl.FillColor=c; d.hl.OutlineColor=c
            end
            d.hl.Enabled=true
        end)
    end
end

function set_box_line(ln, a, b, col)
    if not ln then return end
    ln.From=a; ln.To=b; ln.Color=col; ln.Visible=true
end

function draw_esp_box(d, top, bot, col)
    if not cfg.esp_box or not d.box then
        if d.box then for _,ln in ipairs(d.box) do ln.Visible=false end end
        return false
    end
    if not top or not bot then
        for _,ln in ipairs(d.box) do ln.Visible=false end
        return false
    end
    local ok1,s1=pcall(function() local sp,_=WorldToScreen(top); return sp end)
    local ok2,s2=pcall(function() local sp,_=WorldToScreen(bot); return sp end)
    if not ok1 or not s1 or not ok2 or not s2 then
        for _,ln in ipairs(d.box) do ln.Visible=false end
        return false
    end
    local h=abs(s2.Y-s1.Y)
    if h<4 then
        for _,ln in ipairs(d.box) do ln.Visible=false end
        return false
    end
    local w=h*0.42
    local cx=(s1.X+s2.X)*0.5
    local ty,my=s1.Y,s2.Y
    local tl=Vector2.new(cx-w*0.5,ty); local tr=Vector2.new(cx+w*0.5,ty)
    local bl=Vector2.new(cx-w*0.5,my); local br=Vector2.new(cx+w*0.5,my)
    set_box_line(d.box[1],tl,tr,col)
    set_box_line(d.box[2],tr,br,col)
    set_box_line(d.box[3],br,bl,col)
    set_box_line(d.box[4],bl,tl,col)
    return true
end

function rm_esp(p)
    local d=esp_obj[p]; if not d then return end
    for _,k in ipairs({"nm","hp","ps"}) do pcall(function() d[k]:Remove() end) end
    if d.box then for _,ln in ipairs(d.box) do pcall(function() ln:Remove() end) end end
    rm_esp_chams(d)
    esp_obj[p]=nil; esp_sp[p]=nil
end

function mk_esp(p)
    if esp_obj[p] then return end
    local ecol=Color3.fromRGB(cfg.esp_r,cfg.esp_g,cfg.esp_b)
    local function mk(col)
        local t=Drawing.new("Text"); t.Visible=false; t.Center=true
        t.ZIndex=3; return style_text(t, 16, col)
    end
    local box={}
    for i=1,4 do box[i]=mk_box_ln(ecol) end
    esp_obj[p]={
        nm=mk(ecol),
        hp=mk(Color3.fromRGB(80,255,120)),
        ps=mk(Color3.fromRGB(160,130,255)),
        box=box,
        hl=nil, hl_char=nil, hl_rgb=nil,
        root_char=nil, root=nil, head=nil, mhp=nil, skip=true,
        nm_t=nil, hp_t=nil, ps_t=nil, hp_c=nil,
        draw_sz=nil, draw_col=nil,
    }
end

task.spawn(function()
    while loops_active do
        if lp then
            local all=try(function() return plrs:GetPlayers() end) or {}; local set={}
            for _,p in ipairs(all) do
                set[p]=true
                if is_self(p) then continue end
                if team_check_active() and not is_enemy(p) then
                    rm_esp(p)
                elseif plr_ok(p) then
                    mk_esp(p)
                else
                    rm_esp(p)
                end
            end
            for p in next,esp_obj do if not set[p] or is_self(p) then rm_esp(p) end end
        end
        task.wait(0.5)
    end
end)

hud_obj=nil
function mk_hud()
    if hud_obj then return end
    local function mk(col)
        local t=Drawing.new("Text"); t.Visible=false; t.Center=true
        t.ZIndex=3; return style_text(t, 15, col)
    end
    hud_obj={name=mk(Color3.fromRGB(100,200,255)),hp=mk(Color3.fromRGB(80,255,120)),ps=mk(Color3.fromRGB(255,210,60)),mhp=nil}
end
function rm_hud()
    if not hud_obj then return end
    for _,k in ipairs({"name","hp","ps"}) do pcall(function() hud_obj[k]:Remove() end) end; hud_obj=nil
end

fov_obj=nil
function mk_fov()
    if fov_obj then return end
    fov_obj=Drawing.new("Circle"); fov_obj.Visible=false; fov_obj.Filled=false
    pcall(function() fov_obj.NumSides=96 end)
    local fr,fg,fb=cfg.fov_r or 255, cfg.fov_g or 255, cfg.fov_b or 255
    local acc=theme_accent[theme_preset(cfg.theme)]
    if acc then fr,fg,fb=acc.fov[1], acc.fov[2], acc.fov[3] end
    fov_obj.Color=Color3.fromRGB(fr,fg,fb); fov_obj.Thickness=1.5; fov_obj.ZIndex=10
end
function rm_fov()
    if fov_obj then pcall(function() fov_obj:Remove() end); fov_obj=nil end
end

warn_edges={}; warn_brk={}; warn_txt=nil
warn_bar=nil; warn_scrim=nil; warn_sub=nil; warn_tag=nil
warn_gun_lbl={monarch="Monarch",phoenix="Phoenix",siege="Siege",castigate="Castigate"}

function warn_rgb(acc, key, fb)
    local t=acc and acc[key] or fb
    return Color3.fromRGB(t[1], t[2], t[3])
end

function mk_warn_edges()
    if #warn_edges>=4 then return end
    for _=1,4 do
        local s=Drawing.new("Square"); s.Visible=false; s.Filled=true; s.ZIndex=19
        warn_edges[#warn_edges+1]=s
    end
end

function mk_warn_brk()
    if #warn_brk>=8 then return end
    for _=1,8 do
        local l=Drawing.new("Line"); l.Visible=false; l.Thickness=2; l.ZIndex=21
        warn_brk[#warn_brk+1]=l
    end
end

function mk_warn_txt()
    if warn_txt then return end
    warn_txt=Drawing.new("Text"); warn_txt.Visible=false; warn_txt.Center=true
    style_text(warn_txt, 34, Color3.fromRGB(255,255,255)); warn_txt.ZIndex=23
end
function mk_warn_tag()
    if warn_tag then return end
    warn_tag=Drawing.new("Text"); warn_tag.Visible=false; warn_tag.Center=true
    style_text(warn_tag, 15, Color3.fromRGB(210,210,220)); warn_tag.ZIndex=23
end
function mk_warn_sub()
    if warn_sub then return end
    warn_sub=Drawing.new("Text"); warn_sub.Visible=false; warn_sub.Center=true
    style_text(warn_sub, 18, Color3.fromRGB(255,220,220)); warn_sub.ZIndex=23
end
function mk_warn_scrim()
    if warn_scrim then return end
    warn_scrim=Drawing.new("Square"); warn_scrim.Visible=false; warn_scrim.Filled=true
    warn_scrim.Color=Color3.fromRGB(8,8,12); warn_scrim.ZIndex=20
end
function mk_warn_bar()
    if warn_bar then return end
    warn_bar=Drawing.new("Square"); warn_bar.Visible=false; warn_bar.Filled=true; warn_bar.ZIndex=21
end

function rm_warn_draw()
    for _,s in ipairs(warn_edges) do pcall(function() s:Remove() end) end; warn_edges={}
    for _,l in ipairs(warn_brk) do pcall(function() l:Remove() end) end; warn_brk={}
    if warn_txt then pcall(function() warn_txt:Remove() end); warn_txt=nil end
    if warn_tag then pcall(function() warn_tag:Remove() end); warn_tag=nil end
    if warn_sub then pcall(function() warn_sub:Remove() end); warn_sub=nil end
    if warn_scrim then pcall(function() warn_scrim:Remove() end); warn_scrim=nil end
    if warn_bar then pcall(function() warn_bar:Remove() end); warn_bar=nil end
end

task.spawn(function()
    while loops_active do
        if cfg.hud then mk_hud() else rm_hud() end
        if cfg.sl and cfg.sl_fovs then mk_fov() end
        mk_warn_edges(); mk_warn_brk(); mk_warn_txt(); mk_warn_tag(); mk_warn_sub(); mk_warn_scrim(); mk_warn_bar()
        task.wait(0.5)
    end
end)

function hcol(pct)
    if pct>0.6 then return Color3.fromRGB(80,255,120)
    elseif pct>0.3 then return Color3.fromRGB(255,210,60)
    else return Color3.fromRGB(255,75,75) end
end


function draw_ov()
    if not lp then return end

    if cfg.warn and not in_lobby() and tick()<warn_til then
        mk_warn_edges(); mk_warn_txt(); mk_warn_bar()
        local acc=theme_accent[theme_preset(cfg.theme)] or theme_accent.Grape
        local pri=Color3.fromRGB(cfg.warn_r or acc.warn_primary[1], cfg.warn_g or acc.warn_primary[2], cfg.warn_b or acc.warn_primary[3])
        local cam=workspace.CurrentCamera
        local vp=cam and try(function() return cam.ViewportSize end) or Vector2.new(1920,1080)
        local cx=vp.X/2
        local remain=mx(0, warn_til-tick())
        local dur=mx(0.5, warn_til-warn_blink_t)
        local frac=cl(remain/dur, 0, 1)
        local elapsed=tick()-warn_blink_t
        local fade_in=cl(elapsed/0.12, 0, 1)
        local fade_out=frac>0.12 and 1 or cl(frac/0.12, 0, 1)
        local alpha=cl((cfg.warn_a or 0.42)*fade_in*fade_out, 0.18, 0.55)
        local edge_h=mx(3, vp.Y*0.006)
        local bar_w=vp.X*frac

        for i,s in ipairs(warn_edges) do
            if s then
                s.Color=pri
                s.Transparency=cl(1-alpha, 0.55, 0.92)
                if i==1 then
                    s.Position=Vector2.new(0, 0)
                    s.Size=Vector2.new(vp.X, edge_h)
                    s.Visible=true
                elseif i==2 then
                    s.Position=Vector2.new(0, vp.Y-edge_h)
                    s.Size=Vector2.new(vp.X, edge_h)
                    s.Visible=true
                else
                    s.Visible=false
                end
            end
        end

        if warn_bar then
            warn_bar.Color=pri
            warn_bar.Transparency=cl(1-alpha*0.85, 0.35, 0.9)
            warn_bar.Position=Vector2.new(cx-bar_w/2, edge_h+2)
            warn_bar.Size=Vector2.new(bar_w, mx(2, vp.Y*0.0025))
            warn_bar.Visible=true
        end

        if warn_gun and warn_txt then
            local gun_key=tostring(warn_gun):lower()
            local gun_title=warn_gun_lbl[gun_key] or (gun_key:sub(1,1):upper()..gun_key:sub(2))
            warn_txt.Text=gun_title:upper()
            warn_txt.Color=pri
            warn_txt.Size=20
            warn_txt.Position=Vector2.new(cx, mx(18, vp.Y*0.028))
            warn_txt.Transparency=cl(1-alpha*0.25, 0.15, 1)
            warn_txt.Visible=true
        elseif warn_txt then
            warn_txt.Visible=false
        end

        if warn_tag then warn_tag.Visible=false end
        if warn_sub then warn_sub.Visible=false end
        if warn_scrim then warn_scrim.Visible=false end
        for _,l in ipairs(warn_brk) do if l then l.Visible=false end end
    else
        for _,s in ipairs(warn_edges) do if s then s.Visible=false end end
        for _,l in ipairs(warn_brk) do if l then l.Visible=false end end
        if warn_bar then warn_bar.Visible=false end
        if warn_scrim then warn_scrim.Visible=false end
        if warn_txt then warn_txt.Visible=false end
        if warn_tag then warn_tag.Visible=false end
        if warn_sub then warn_sub.Visible=false end
        if tick()>=warn_til then warn_gun=nil end
    end

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

    if fov_obj then
        if cfg.sl and cfg.sl_fovs and cfg.sl_fovf and not in_lobby() then
            local cam=workspace.CurrentCamera; local vp=cam and try(function() return cam.ViewportSize end)
            if vp and (cfg.sl_fov or 0)>0 then
                local acc=theme_accent[theme_preset(cfg.theme)]
                local fr,fg,fb=cfg.fov_r or 255, cfg.fov_g or 255, cfg.fov_b or 255
                if acc then fr,fg,fb=acc.fov[1], acc.fov[2], acc.fov[3] end
                fov_obj.Color=Color3.fromRGB(fr,fg,fb)
                fov_obj.Position=Vector2.new(vp.X/2,vp.Y/2); fov_obj.Radius=cfg.sl_fov; fov_obj.Visible=true
            else fov_obj.Visible=false end
        else fov_obj.Visible=false end
    end
end

function draw_esp(dt)
    if not lp or not cfg.esp then
        for _,d in next,esp_obj do hide_esp_draw(d) end
        return
    end
    local smooth=cl((dt or 0.016)*18, 0.2, 0.85)
    local er, eg, eb=cfg.esp_r, cfg.esp_g, cfg.esp_b
    local ecol=Color3.fromRGB(er, eg, eb)
    local sz=cfg.esp_sz or 16
    for p,d in next,esp_obj do
        if d.skip then hide_esp_draw(d); continue end
        local root=d.root
        if not root then hide_esp_draw(d); continue end
        local rpos=try(function() return root.Position end)
        if not rpos then hide_esp_draw(d); continue end
        local ws_sp; local ws_ok=pcall(function() ws_sp,_=WorldToScreen(rpos+Vector3.new(0,2.5,0)) end)
        if not ws_ok or not ws_sp then hide_esp_draw(d); continue end
        local raw=Vector2.new(ws_sp.X,ws_sp.Y)
        local prev=esp_sp[p]
        local sp=raw
        if prev then
            local ddx=raw.X-prev.X; local ddy=raw.Y-prev.Y
            if ddx*ddx+ddy*ddy>900 then sp=raw
            else sp=Vector2.new(prev.X+ddx*smooth,prev.Y+ddy*smooth) end
        end
        esp_sp[p]=sp
        local sx,sy=sp.X,sp.Y-30
        if d.draw_sz~=sz then
            d.draw_sz=sz
            d.nm.Size=sz; d.hp.Size=sz-1; d.ps.Size=sz-1
        end
        if d.draw_col~=ecol then
            d.draw_col=ecol
            d.nm.Color=ecol
        end
        if cfg.esp_name then
            d.nm.Text=d.nm_t or "?"
            d.nm.Position=Vector2.new(sx,sy); d.nm.Visible=true
        else d.nm.Visible=false end
        if cfg.esp_hp and d.hp_t then
            d.hp.Text=d.hp_t
            if d.hp_c then d.hp.Color=d.hp_c end
            d.hp.Position=Vector2.new(sx,sy+sz+2); d.hp.Visible=true
        else d.hp.Visible=false end
        if cfg.esp_pos and d.ps_t then
            d.ps.Text=d.ps_t
            d.ps.Position=Vector2.new(sx,sy+(sz+2)*2); d.ps.Visible=true
        else d.ps.Visible=false end
        if cfg.esp_box then
            local hp=d.head and try(function() return d.head.Position end)
            local top=hp and (hp+Vector3.new(0,0.6,0)) or (rpos+Vector3.new(0,2.8,0))
            local bot=rpos-Vector3.new(0,3.2,0)
            draw_esp_box(d, top, bot, ecol)
        elseif d.box then for _,ln in ipairs(d.box) do ln.Visible=false end end
    end
end

function sync_esp()
    if not lp or not cfg.esp then
        for _,d in next,esp_obj do
            d.skip=true; hide_esp_draw(d); hide_esp_chams(d)
        end
        return
    end
    local my_pos=get_pos()
    local rng=cfg.esp_rng or 500
    local rng_sq=rng>0 and rng*rng or nil
    for p,d in next,esp_obj do
        if is_self(p) or not plr_ok(p) or (team_check_active() and not is_enemy(p)) then
            d.skip=true; hide_esp_chams(d); continue
        end
        local char=try(function() return p.Character end)
        if char~=d.root_char then
            d.root_char=char
            d.root=char and try(function() return char:FindFirstChild("HumanoidRootPart") end)
            d.head=char and try(function() return char:FindFirstChild("Head") end)
            d.mhp=nil; d.hl_rgb=nil
            rm_esp_chams(d)
        end
        if not d.root then
            d.skip=true; hide_esp_chams(d); continue
        end
        if rng_sq and my_pos then
            local rpos=try(function() return d.root.Position end)
            if rpos and dsq(my_pos,rpos)>rng_sq then
                d.skip=true; hide_esp_chams(d); continue
            end
        end
        d.skip=false
        d.nm_t=tostring(p.Name)
        local ro=try(function() return p:FindFirstChild("ReadOnly") end)
        local hv=ro and try(function() return ro:FindFirstChild("health") end)
        local hp=hv and try(function() return hv.Value end)
        if d.mhp==nil then
            local mhv=ro and (try(function() return ro:FindFirstChild("maxhealth") end) or try(function() return ro:FindFirstChild("MaxHealth") end))
            local v=mhv and try(function() return mhv.Value end)
            d.mhp=(v and v>0 and v) or 100
        end
        if cfg.esp_hp and hp and hp>0 then
            local mhp=d.mhp or 100
            d.hp_t=fl(hp).." / "..fl(mhp)
            if cfg.esp_dist and my_pos then
                local rpos=try(function() return d.root.Position end)
                if rpos then d.hp_t=d.hp_t.."  "..fl(sq(dsq(my_pos,rpos))).."st" end
            end
            d.hp_c=hcol(cl(hp/mhp,0,1))
        else d.hp_t=nil end
        local iv=ro and try(function() return ro:FindFirstChild("impact") end)
        local imp=iv and try(function() return iv.Value end)
        d.ps_t=(cfg.esp_pos and imp~=nil) and ("p "..string.format("%.1f",imp)) or nil
        sync_esp_chams(d, char, true)
    end
end

hb_seen={}; hb_last_scan=0; hb_char={}
hb_orig=setmetatable({},{__mode="k"})
hb_cache=setmetatable({},{__mode="k"})

function is_hurtbox(nm)
    if not nm then return false end
    local s=tostring(nm)
    if s=="Torso_Hurtbox" or s=="Head_Hurtbox" or s=="Hurtbox" then return true end
    return s:find("Hurtbox",1,true)~=nil
end

function find_hurtboxes(char, force)
    if not char then return {} end
    local c=hb_cache[char]
    if c and not force and tick()-c.t<3 then return c.parts end
    local parts={}
    local function add(obj)
        if obj:IsA("BasePart") and is_hurtbox(obj.Name) then parts[#parts+1]=obj end
    end
    for _,obj in ipairs(try(function() return char:GetChildren() end) or {}) do add(obj) end
    if #parts==0 then
        for _,obj in ipairs(try(function() return char:GetDescendants() end) or {}) do add(obj) end
    end
    hb_cache[char]={parts=parts,t=tick()}
    return parts
end

function restore_hurtboxes()
    for obj,sz in pairs(hb_orig) do
        pcall(function()
            if obj.Parent and typeof(sz)=="Vector3" then obj.Size=sz end
        end)
    end
    for obj in pairs(hb_orig) do hb_orig[obj]=nil end
    hb_seen={}; hb_cache=setmetatable({},{__mode="k"}); st.hb_n=0
end

function scan_hurtboxes(force, aura_sz)
    if in_lobby() then return end
    if (not cfg.hb or not st.hb_on) and not force then return end
    local now=tick()
    if not force and now-hb_last_scan<5 then return end
    hb_last_scan=now
    local sz=(aura_sz and aura_sz>0 and aura_sz) or cfg.hb_size or 8
    local tgt=Vector3.new(sz,sz,sz); local n=0
    local my=get_pos(); local me=get_char()
    local rng=force and 0 or (cfg.hb_rng or 0); local rsq=rng>0 and rng*rng or nil
    for _,p in ipairs(try(function() return plrs:GetPlayers() end) or {}) do
        if is_self(p) or not is_enemy(p) or not plr_ok(p) then continue end
        local char=try(function() return p.Character end); if not char or char==me then continue end
        local chg=hb_char[p]~=char
        if chg then hb_char[p]=char; hb_cache[char]=nil end
        if rsq and my then
            local root=try(function() return char:FindFirstChild("HumanoidRootPart") end)
            local rpos=root and try(function() return root.Position end)
            if not rpos or hdsq(my,rpos)>rsq then continue end
        end
        for _,obj in ipairs(find_hurtboxes(char, force or chg)) do
            if hb_seen[obj] and not force then continue end
            hb_seen[obj]=true
            if not hb_orig[obj] then hb_orig[obj]=try(function() return obj.Size end) end
            pcall(function() obj.Size=tgt end)
            n=n+1
        end
    end
    local tc=0; for _ in pairs(hb_seen) do tc=tc+1 end; st.hb_n=tc
    if n>0 and not aura_sz then dlog("[hb] "..n.." hurtboxes sz="..sz) end
end

function aura_pick(my, rsq)
    if not my then return nil end
    local me=get_char()
    local best,bd=nil,math.huge
    for _,t in ipairs(get_tgts(cfg.training)) do
        if not tgt_ok(t) then continue end
        if t.char==me then continue end
        if t.player and t.ent then
            if not plr_ok(t.ent) or not is_enemy(t.ent) then continue end
        elseif not cfg.training then continue end
        local hum=try(function() return t.char:FindFirstChildOfClass("Humanoid") end)
        local hp=hum and try(function() return hum.Health end)
        if hp~=nil and hp<=0 then continue end
        local d=dsq(my,t.pos)
        if d>rsq then continue end
        if d<bd then bd=d; best=t end
    end
    return best
end

function try_aura()
    if in_lobby() then st.aura_pending=false; return end
    if not cfg.aura then st.aura_pending=false; return end
    local now=tick(); if now-st.aura_t<(cfg.aura_cd or 15)/100 then return end
    local my=get_pos(); if not my then return end
    local rsq=(cfg.aura_rng or 23)^2
    local best=aura_pick(my, rsq)
    if not best then
        if cfg.aura_hb then restore_hurtboxes(); if cfg.hb then hb_last_scan=0 end end
        return
    end
    st.aura_t=now; st.aura_pending=true
    task.spawn(function()
        if cfg.aura_hb then scan_hurtboxes(true, cfg.aura_rng) end
        if not st.aura_pending then return end
        local swing=aura_pick(get_pos() or my, rsq)
        if not swing then
            st.aura_pending=false
            if cfg.aura_hb and not cfg.hb then restore_hurtboxes() end
            return
        end
        ktap(gb("melee"))
        st.aura_pending=false
        dlog("[aura] -> "..(swing.name or "?"))
        if cfg.aura_hb and not cfg.hb then task.wait(0.15); restore_hurtboxes() end
    end)
end

function sl_fov_ok(sp)
    if not cfg.sl_fovf then return true end
    local cam=workspace.CurrentCamera; if not cam then return true end
    local vp=try(function() return cam.ViewportSize end); if not vp then return true end
    local dx=sp.X-vp.X/2; local dy=sp.Y-vp.Y/2
    local fov=cfg.sl_fov or 130
    return (dx*dx+dy*dy)<=(fov*fov)
end

function sl_part(char)
    if not char then return nil end
    if cfg.sl_part=="body" then
        return try(function() return char:FindFirstChild("UpperTorso") end)
            or try(function() return char:FindFirstChild("Torso") end)
            or try(function() return char:FindFirstChild("LowerTorso") end)
            or try(function() return char:FindFirstChild("HumanoidRootPart") end)
    end
    return try(function() return char:FindFirstChild("Head") end)
        or try(function() return char:FindFirstChild("HumanoidRootPart") end)
end

function sl_apos(t)
    if not tgt_ok(t) then return nil end
    local part=sl_part(t.char) or t.root
    if not part then return t.hpos or t.pos end
    local p=try(function() return part.Position end)
    if not p then return t.hpos or t.pos end
    local nm=try(function() return part.Name end) or ""
    if nm~="Head" and nm~="UpperTorso" and nm~="Torso" and nm~="LowerTorso" then
        p=p+Vector3.new(0,(cfg.sl_part=="body") and 1.5 or 2.6,0)
    end
    return p
end

function sl_in_range(t)
    if not t or not tgt_ok(t) then return false end
    local my=get_pos(); if not my then return false end
    local dv=cfg.sl_dist or 500
    if dv>0 and sq(dsq(my,t.pos))>dv then return false end
    return true
end

function sl_pick(fov_gate)
    local my=get_pos(); if not my then return nil end
    local best,bd=nil,math.huge
    local gate=fov_gate~=false and cfg.sl_fovf
    for _,t in ipairs(tgts_cached()) do
        if not tgt_ok(t) then continue end
        local dv=cfg.sl_dist or 500
        if dv>0 and sq(dsq(my,t.pos))>dv then continue end
        local ap=sl_apos(t); if not ap then continue end
        if gate then
            local ok_sp,scr=pcall(WorldToScreen,ap)
            if ok_sp and scr and type(scr)~="boolean" then if not sl_fov_ok(scr) then continue end end
        end
        local d=dsq(my,t.pos); if d<bd then bd=d; best=t end
    end
    return best
end

function aim_ang_to(tx,ty,tz)
    local lk=st.aim_lk or get_look()
    if not lk then return 180 end
    local cp=cam_pos() or get_pos(); if not cp then return 180 end
    local dx,dy,dz=tx-cp.X,ty-cp.Y,tz-cp.Z
    local dm=sq(dx*dx+dy*dy+dz*dz); if dm<1e-6 then return 0 end
    return vang(lk, Vector3.new(dx/dm,dy/dm,dz/dm))
end

function aim_at(tx,ty,tz, rate, dt, mem_only)
    local d=cl(dt or 0.016, 0.001, 0.05)
    local ang=aim_ang_to(tx,ty,tz)
    local alpha=aim_alpha(rate, d, ang)
    if aim_mem_ready() then
        cam_mem_aim(tx,ty,tz, rate, nil, d)
        return
    end
    if mem_only then return end
    local max_dps=cfg.sl_spd or 0
    if max_dps<=0 then max_dps=nil end
    aim_mouse(Vector3.new(tx,ty,tz), alpha, max_dps, d)
end

function aim_mouse(ap, alpha, max_dps, dt)
    if type(mousemoverel)~="function" then return false end
    local cam=workspace.CurrentCamera; if not cam then return false end
    local vp=try(function() return cam.ViewportSize end); if not vp then return false end
    local ok_sp,sp,on=pcall(WorldToScreen,ap)
    if not ok_sp or not sp or type(sp)=="boolean" or on==false then return false end
    local sx,sy=sp.X,sp.Y
    if not sx or not sy then return false end
    local d=cl(dt or 0.016, 0.001, 0.05)
    local blend=aim_smooth_blend(d, aim_smooth_hz())
    local stx=st.aim_sx or sx
    local sty=st.aim_sy or sy
    stx=stx+(sx-stx)*blend
    sty=sty+(sy-sty)*blend
    st.aim_sx,st.aim_sy=stx,sty
    local err_x=stx-vp.X/2
    local err_y=sty-vp.Y/2
    local dist=sq(err_x*err_x+err_y*err_y)
    if dist<0.35 then return true end
    local far=cl(dist/90, 0, 1)
    far=far*far*(3-2*far)
    local move_a=alpha*(0.55+0.45*far)
    local dx=err_x*move_a
    local dy=err_y*move_a
    if max_dps and max_dps>0 then
        local spd=sq(dx*dx+dy*dy)
        if spd>0 then
            local cap=max_dps*d*(vp.X/70)
            if cap>0 and spd>cap then local s=cap/spd; dx,dy=dx*s,dy*s end
        end
    end
    st.aim_mx=(st.aim_mx or 0)+dx
    st.aim_my=(st.aim_my or 0)+dy
    local mx,my=fl(st.aim_mx),fl(st.aim_my)
    st.aim_mx,st.aim_my=st.aim_mx-mx,st.aim_my-my
    if mx~=0 or my~=0 then pcall(mousemoverel, mx, my) end
    return true
end

function gp_aim_tick(dt)
    if in_lobby() then clear_gp_aim(); return false end
    local ga=st.gp_aim
    if not ga then return false end
    if tick()>ga.til then
        clear_gp_aim()
        return false
    end
    if ga.att then
        local sp=head_pos(ga.att) or body_pos(ga.att)
        if sp then ga.x,ga.y,ga.z=sp.X,sp.Y,sp.Z end
    end
    local d=cl(dt or 0.016, 0.001, 0.033)
    aim_at(ga.x,ga.y,ga.z, ga.rate or mx(12,(cfg.sl_str or 42)*0.48), d, false)
    return true
end

function sl_tick(dt)
    if in_lobby() then st.sl_tgt=nil; st.aim_lk=nil; st.aim_mx=0; st.aim_my=0; clear_aim_smooth(); return end
    if gp_aim_tick(dt) then return end
    if not cfg.sl then st.sl_tgt=nil; st.aim_lk=nil; return end
    local now=tick()
    local grace=(cfg.sl_dur or 14)/10
    local held=hotkey_on(cfg.sl_key) and key_name_dn(cfg.sl_key)
    if held then
        if not st.sl_tgt or not tgt_ok(st.sl_tgt) or not sl_in_range(st.sl_tgt) then
            st.sl_tgt=sl_pick(true)
            st.aim_lk=nil
            clear_aim_smooth()
        end
        if st.sl_tgt then st.sl_til=now+grace end
    elseif now>st.sl_til then
        st.sl_tgt=nil; st.aim_lk=nil; st.aim_mx=0; st.aim_my=0; clear_aim_smooth(); return
    end
    local t=st.sl_tgt; if not t then return end
    if not tgt_ok(t) or not sl_in_range(t) then st.sl_tgt=nil; st.aim_lk=nil; clear_aim_smooth(); return end
    local ap=sl_apos(t); if not ap then return end
    local rate=(cfg.sl_str or 42)*0.48
    aim_at(ap.X,ap.Y,ap.Z, rate, dt, true)
end

function soft_reset(tag)
    shot=nil; pq.q={}; st.miss_n=0; st.gp_lock=0; st.siege_s2_t=0; st.s2_arm=0
    cycle_fired=false; cycle_fired_t=0
    st.linger_until=0; st.flash_t=0; st.flash_gun=nil; st.await_cassette=false; st.post_parry_until=0
    st.phx_log.active=false; st.last_gun="castigate"; st.aura_pending=false
    phx_nearest=nil; phx_rocket_seen=false; phx_scan_t=0
    st.sl_tgt=nil; st.sl_til=0; clear_gp_aim()
    seen_eff={}; seen_vfx={}; seen_part={}; seen_pt={}
    zone_win={}; active_z={}; win_last={}; pg_seen={}; pg_parried={}; stale_log={}; si_done={}
    att_gun={}; att_gun_t={}
    cam.cPtr=0
    if cfg.hb or cfg.aura_hb then restore_hurtboxes(); hb_last_scan=0 end
    log("[rlt] ======== "..(tag or "reload").." ======== state cleared")
end

task.spawn(function()
    local last_p
    while loops_active do
        local p=get_pos()
        if p and last_p and sq(dsq(p,last_p))>450 then soft_reset("teleport") end
        last_p=p
        task.wait(0.2)
    end
end)

function safe_connect(sig, fn)
    if not sig or type(fn)~="function" then return false end
    local ok=pcall(function() sig:Connect(fn) end)
    return ok
end

task.spawn(function()
    local function watch(p)
        if is_self(p) then return end
        hb_char[p]=try(function() return p.Character end)
        safe_connect(try(function() return p.CharacterAdded end), function(c)
            hb_char[p]=c; hb_cache[c]=nil; hb_last_scan=0
            if (cfg.hb and st.hb_on) or cfg.aura_hb then task.defer(function() scan_hurtboxes(true) end) end
        end)
    end
    for _,p in ipairs(try(function() return plrs:GetPlayers() end) or {}) do watch(p) end
    safe_connect(try(function() return plrs.PlayerAdded end), watch)
end)

function on_frame(dt)
    if not loops_active then return end
    local d=dt or 0
    st.ov_t=st.ov_t+d
    if st.ov_t>=0.016 then st.ov_t=0; draw_ov() end
    if not in_lobby() then sl_tick(d) end
end

function esp_on_draw(dt)
    if not loops_active then return end
    if not cfg.esp then
        for _,d in next,esp_obj do hide_esp_draw(d); hide_esp_chams(d) end
        return
    end
    local iv=cfg.esp_draw_iv or 0
    if iv>0 then
        st.esp_draw_t=st.esp_draw_t+(dt or 0)
        if st.esp_draw_t<iv then return end
        st.esp_draw_t=0
    end
    draw_esp(dt)
end

if not safe_connect(try(function() return run.RenderStepped end), esp_on_draw) then
    task.spawn(function()
        while loops_active do
            esp_on_draw(0.016)
            task.wait(1/get_fps())
        end
    end)
end

task.spawn(function()
    while loops_active do
        sync_esp()
        task.wait(cfg.esp_sync_iv or 0.15)
    end
end)

if not safe_connect(try(function() return run.RenderStepped end), on_frame) then
    task.spawn(function()
        while loops_active do
            on_frame(0.016)
            task.wait(1/get_fps())
        end
    end)
end

task.spawn(function()
    while loops_active do
        scan_effects()
        scan_pgui()
        task.wait(1/get_fps())
    end
end)

task.spawn(function()
    while loops_active do
        if in_lobby() then task.wait(0.1); continue end
        scan_hurtboxes()
        try_aura()
        task.wait(0.033)
    end
end)

task.spawn(function()
    while loops_active do
        if in_lobby() then task.wait(0.1); continue end
        if cfg.mp and (cfg.mp_anim or cfg.mp_anim_dbg) and mem.on then
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

task.spawn(function()
    while loops_active do
        apply_auto_ping()
        task.wait(2)
    end
end)

task.spawn(function()
    while loops_active do
        if cfg.auto_save and cfg_changed and (oc()-chg_t)>=2 then cfg_save() end
        task.wait(1)
    end
end)

task.spawn(function()
    local t0=oc()
    while loops_active do
        task.wait()
        local now=oc(); local dt=math.min(now-t0,0.1); t0=now
        local rt=get_root()
        local spd_on=cfg.spd and rt and not in_lobby()
        if spd_on and cfg.spd_hold then
            spd_on=hotkey_on(cfg.spd_key) and key_name_dn(cfg.spd_key)
        end
        if not spd_on then st.spd_vacc=nil; continue end
        local look=get_look(); if not look then continue end
        local flat=Vector3.new(look.X,0,look.Z)
        if flat.Magnitude<1e-3 then continue end; flat=flat.Unit
        local rv=rt.AssemblyLinearVelocity
        if st.spd_vacc==nil then st.spd_vacc=Vector3.new(rv.X,0,rv.Z).Magnitude end
        local step=cfg.spd_rmp*dt
        st.spd_vacc=st.spd_vacc+cl(cfg.spd_top-st.spd_vacc,-step,step)
        rt.AssemblyLinearVelocity=Vector3.new(flat.X*st.spd_vacc,rv.Y,flat.Z*st.spd_vacc)
    end
end)

mod={
    mac_key={
        q=0x51,w=0x57,e=0x45,r=0x52,t=0x54,y=0x59,
        a=0x41,s=0x53,d=0x44,f=0x46,g=0x47,h=0x48,
        z=0x5A,x=0x58,c=0x43,v=0x56,b=0x42,n=0x4E,
    },
    in_lobby=in_lobby,
    in_twov2=in_twov2,
    team_check_active=team_check_active,
}
function mod.mhex(n) return mod.mac_key[n] or 0x58 end
function mod.macro_rel(k, held, force)
    if not k or not held or not held[k] then return end
    if force or not key_name_dn(k) then krel(k) end
    held[k]=nil
end
function mod.macro_cleanup(held)
    if not held then return end
    for k in pairs(held) do mod.macro_rel(k, held) end
end
function mod.tcfg(sec, min_k, max_k)
    local s=cfg[sec] or cfg_defaults[sec]
    local d=cfg_defaults[sec] or {}
    local lo=tonumber(s[min_k] or d[min_k]) or 20
    local hi=tonumber(s[max_k] or d[max_k]) or lo
    mod.hw(lo, hi)
end
function mod.bdg_key(action, down)
    local b=gb(action)
    if not b then return end
    b=tostring(b):lower()
    if down then
        if b=="rmb" or b=="mouse2" then pcall(mouse2press)
        elseif b=="lmb" or b=="mouse1" then pcall(mouse1press)
        else pcall(keypress, khex(b)) end
    else
        if b=="rmb" or b=="mouse2" then pcall(mouse2release)
        elseif b=="lmb" or b=="mouse1" then pcall(mouse1release)
        else pcall(keyrelease, khex(b)) end
    end
end
function mod.bdg_wait(min_k, max_k)
    local s=cfg.bdg_t or cfg_defaults.bdg_t
    local d=cfg_defaults.bdg_t or {}
    local lo=tonumber(s[min_k] or d[min_k]) or 50
    local hi=tonumber(s[max_k] or d[max_k]) or lo
    if hi<lo then lo,hi=hi,lo end
    local wait_ms=math.random(lo, hi)
    if hum_on() then
        local jit=math.max(1, math.floor(wait_ms*0.04))
        wait_ms=wait_ms+math.random(-jit, jit)
    end
    task.wait(mx(0, wait_ms)/1000)
end
function mod.bdg_stash_all(stashed)
    local any=false
    if mod.bind_dn("forward") then
        stashed.forward=true
        mod.bdg_key("forward", false)
        any=true
    end
    for _,a in ipairs({"slide","back","dash","augment","jump"}) do
        if mod.bind_dn(a) then
            mod.bdg_key(a, false)
            stashed[a]=true
            any=true
        end
    end
    if any then task.wait(0.006) end
end
function mod.bdg_suppress_start(gen, rules)
    st.bdg_suppress={gen=gen, rules=rules}
    task.spawn(function()
        while st.bdg_suppress and st.bdg_suppress.gen==gen do
            for action,on in pairs(st.bdg_suppress.rules) do
                if on then mod.bdg_key(action, false) end
            end
            task.wait(0)
        end
    end)
end
function mod.bdg_suppress_stop()
    if st.bdg_suppress then st.bdg_suppress.gen=-1 end
    st.bdg_suppress=nil
    task.wait(0.012)
end
function mod.bdg_macro_key(action, down, macro_held)
    local b=mod.bdg_bind_name(action)
    if st.bdg_suppress and st.bdg_suppress.rules and down then
        st.bdg_suppress.rules[action]=false
    end
    mod.bdg_key(action, down)
    if macro_held and b then
        if down then macro_held[b]=true else macro_held[b]=nil end
    end
end
function mod.bdg_bind_name(action)
    local b=gb(action)
    return b and tostring(b):lower() or nil
end
function mod.bdg_finish(macro_held, user_w)
    macro_held=macro_held or {}
    mod.bdg_suppress_stop()
    st.bdg_w_handoff=nil
    for _,a in ipairs({"back","dash","augment","slide"}) do
        mod.bdg_key(a, false)
        local b=mod.bdg_bind_name(a)
        if b then macro_held[b]=nil end
    end
    local fwd_k=mod.bdg_bind_name("forward")
    if fwd_k and macro_held[fwd_k] then
        mod.macro_rel(fwd_k, macro_held, not user_w)
    end
    if fwd_k and not user_w then krel(fwd_k) end
    for k in pairs(macro_held) do mod.macro_rel(k, macro_held, true) end
    st.bdg_stash=nil
    st.bdg_busy=false
    if not user_w or not fwd_k or not key_name_dn(fwd_k) then return end
    st.bdg_w_handoff=true
    task.spawn(function()
        while loops_active and st.bdg_w_handoff do
            if key_name_dn(fwd_k) then
                kpress(fwd_k)
            else
                krel(fwd_k)
                st.bdg_w_handoff=nil
                break
            end
            task.wait(0)
        end
    end)
end
function mod.bdg_abort()
    st.bdg_gen=(st.bdg_gen or 0)+1
    st.bdg_w_handoff=nil
    mod.bdg_suppress_stop()
    mod.bdg_key("back", false)
    mod.bdg_key("dash", false)
    mod.bdg_key("augment", false)
    mod.bdg_key("forward", false)
    mod.bdg_key("slide", false)
    st.bdg_stash=nil
    st.bdg_busy=false
end
function mod.ms_wait(ms)
    task.wait((ms or 0)/1000)
end
function mod.hw(min_ms, max_ms)
    min_ms=tonumber(min_ms) or 20
    max_ms=tonumber(max_ms) or min_ms
    if max_ms<min_ms then min_ms,max_ms=max_ms,min_ms end
    local wait_ms=math.random(min_ms, max_ms)
    if hum_on() then
        local jit=math.max(1, math.floor(wait_ms*0.07))
        wait_ms=mx(12, wait_ms+math.random(-jit, jit))
    end
    task.wait(wait_ms/1000)
end
function mod.bind_dn(action)
    local b=gb(action)
    if not b then return false end
    b=tostring(b):lower()
    local dn=false
    if b=="lmb" or b=="mouse1" then pcall(function() dn=iskeypressed(0x01) end)
    elseif b=="rmb" or b=="mouse2" then pcall(function() dn=iskeypressed(0x02) end)
    else pcall(function() dn=iskeypressed(khex(b)) end) end
    return dn
end
function mod.do_bdg()
    if not cfg.bdg or st.bdg_busy then return end
    st.bdg_busy=true
    st.bdg_w_handoff=nil
    local gen=(st.bdg_gen or 0)+1
    st.bdg_gen=gen
    local macro_held={}
    local stashed={}
    local user_w=mod.bind_dn("forward")
    st.bdg_stash=stashed
    mod.bdg_stash_all(stashed)
    local suppress={}
    if stashed.forward then suppress.forward=true end
    for a,_ in pairs(stashed) do
        if a~="forward" then suppress[a]=true end
    end
    mod.bdg_suppress_start(gen, suppress)
    local function alive()
        return loops_active and cfg.bdg and st.bdg_gen==gen
    end
    local function finish()
        mod.bdg_finish(macro_held, user_w)
    end
    local function wait_t(min_k, max_k)
        if not alive() then return false end
        mod.bdg_wait(min_k, max_k)
        return alive()
    end
    mod.bdg_macro_key("back", true, macro_held)
    if not wait_t("s_hold_min", "s_hold_max") then return finish() end
    mod.bdg_macro_key("dash", true, macro_held)
    if not wait_t("dash_grapple_min", "dash_grapple_max") then return finish() end
    mod.bdg_macro_key("augment", true, macro_held)
    mod.bdg_macro_key("back", false, macro_held)
    mod.bdg_macro_key("dash", false, macro_held)
    mod.bdg_suppress_stop()
    if user_w and mod.bind_dn("forward") then
        -- physical W still down — don't synthetic press or release
    else
        mod.bdg_macro_key("forward", true, macro_held)
    end
    if not wait_t("w_slide_min", "w_slide_max") then return finish() end
    mod.bdg_macro_key("slide", true, macro_held)
    if not wait_t("slide_hold_min", "slide_hold_max") then return finish() end
    finish()
end

task.spawn(function()
    while loops_active do
        if cfg.bdg and hotkey_on(cfg.bdg_key) and not in_lobby() then
            bind_edge("bdg", function() return mod.mhex(cfg.bdg_key) end, function()
                if cfg.bdg and not st.bdg_busy then task.spawn(mod.do_bdg) end
            end, 0.08)
        else
            bind_st.bdg=nil
            if not cfg.bdg and st.bdg_busy then mod.bdg_abort() end
        end
        task.wait(0.02)
    end
end)

_G.rl_cleanup=function()
    loops_active=false
    rm_hud(); rm_fov(); rm_warn_draw()
    for _,d in next,esp_obj do
        for _,k in ipairs({"nm","hp","ps"}) do pcall(function() d[k]:Remove() end) end
        if d.box then for _,ln in ipairs(d.box) do pcall(function() ln:Remove() end) end end
        rm_esp_chams(d)
    end
    esp_obj={}; esp_sp={}; att_gun={}; att_gun_t={}
    seen_eff={}; seen_vfx={}; seen_part={}; seen_pt={}; zone_win={}
    pq.q={}; restore_hurtboxes(); hb_char={}; hb_last_scan=0
end

task.spawn(function()
    repeat task.wait(0.1) until lp
    pcall(function() if not game:IsLoaded() then game.Loaded:Wait() end end)
    repeat task.wait(0.1) until get_char() and get_root()
    task.wait(0.5)

    local cam=workspace.CurrentCamera
    local vp=cam and try(function() return cam.ViewportSize end)
    if vp then cfg.hud_x=fl(vp.X/2); cfg.hud_y=fl(vp.Y*0.90) end

    if not cfg_load() then
        cfg_migrate()
        mark_chg()
    end
    rebuild_place_cache()
    local pid=log_place_id("load")
    rn("PlaceId: "..tostring(pid),"Redline",6)
    apply_theme_colors(cfg.theme)
    set_warn_style(cfg.warn_style)

    local ui_src=try(function() return game:HttpGet("https://raw.githubusercontent.com/neaxusxgod-png/INS-ui/main/uilib.min.lua") end)
    if type(ui_src)~="string" or #ui_src<500 then rn("UI loader fetch failed","Redline",8); return end
    local ui_fn=loadstring(ui_src)
    if not ui_fn then rn("UI loader compile failed","Redline",8); return end
    pcall(ui_fn)
    local UiLib=ui_fn() or INSui
    if type(UiLib)~="table" then rn("UI load failed","Redline",8); return end

    local win=UiLib:CreateWindow({
        title="Redline",
        subtitle="koji_xyz",
        size=Vector2.new(cfg.ui_w or UI_W_DEFAULT, cfg.ui_h or UI_H_DEFAULT),
        position=Vector2.new(70, 50),
        menuKey=(function()
            local mk=norm_menu_key(cfg.menu_key)
            return (mk~=HOTKEY_NONE and mk) or "rctrl"
        end)(),
        hotkeyEnabled=(cfg.show_keybinds==true) and cfg.streamer==false,
        autoSave=false,
        startOpen=true,
        gameInput=true,
        font=ui_scalar(cfg.ui_font) or UI_FONT_DEFAULT,
        sidebarCollapsed=false,
        collapseSidebar=false,
    })
    pcall(function() UiLib:SetGameInput(true) end)
    pcall(function() UiLib:SetAutoSave(false) end)

    local function settings_tab()
        local st=win.GetSettingsTab and win:GetSettingsTab()
        return st and st._tab
    end

    local function settings_hide(name)
        local tab=settings_tab()
        if not tab or type(tab.sections)~="table" then return end
        for i=#tab.sections,1,-1 do
            if tab.sections[i].name==name then table.remove(tab.sections,i) end
        end
    end

    local function settings_reorder(name, pos)
        local tab=settings_tab()
        if not tab or type(tab.sections)~="table" then return end
        local secs,idx=tab.sections,nil
        for i,s in ipairs(secs) do if s.name==name then idx=i; break end end
        if idx then
            local sec=table.remove(secs,idx)
            table.insert(secs,pos or 1,sec)
        end
    end

    local function uinot(t, m, d, typ)
        if cfg.notify==false or cfg.streamer~=false then return end
        pcall(function() UiLib:Notify(t, m, d or 3, typ or "info") end)
    end

    local function apply_streamer_mode()
        local on=cfg.streamer~=false
        pcall(function()
            if win.SetHotkeyEnabled then
                win:SetHotkeyEnabled(not on and cfg.show_keybinds==true)
            end
        end)
    end

    local apply_ui_font
    local apply_ui_interface
    local bind_menu_hotkey
    local ui_set_menu_key

    local function ui_val_str(v)
        return ui_scalar(v)
    end

    local function get_ui_state()
        local ps
        if type(debug)=="table" and debug.getupvalue then
            local fn=UiLib.Tab or win.Tab or UiLib.CreateWindow
            if type(fn)=="function" then
                for i=1,96 do
                    local n,v=debug.getupvalue(fn,i)
                    if not n then break end
                    if n=="ProjectState" and type(v)=="table" then ps=v; break end
                end
            end
        end
        return ps
    end

    local function apply_theme(name)
        local preset=ui_scalar(theme_legacy[name] or name) or "Grape"
        cfg.theme=preset
        pcall(function() UiLib:ApplyThemePreset(preset) end)
        apply_theme_colors(preset)
        if apply_ui_interface then apply_ui_interface() end
        if apply_ui_font then
            apply_ui_font()
            task.defer(function()
                if apply_ui_interface then apply_ui_interface() end
                if apply_ui_font then apply_ui_font() end
            end)
        end
    end

    cfg_ui_sync=function(silent)
        local ot, mk, ko=cfg.theme, cfg.menu_key, cfg.show_keybinds
        local of=cfg.ui_font
        local function gv(p)
            local ok,v=pcall(function() return UiLib:GetValue(p) end)
            return ok and v or nil
        end
        local tp=gv("Settings.Theme.Preset")
        if type(tp)=="table" and tp[1] and tp[1]~="Default" and tp[1]~="Custom" then
            cfg.theme=tp[1]
        elseif type(tp)=="string" and tp~="" and tp~="Default" and tp~="Custom" then
            cfg.theme=tp
        end
        local fv=gv("Settings.Interface.Font")
        if fv~=nil then
            local f=ui_val_str(fv)
            if type(f)=="string" and f~="" then cfg.ui_font=f end
        end
        local mkv=gv("Settings.Interface.Menu key")
        if mkv~=nil then cfg.menu_key=norm_menu_key(ui_val_str(mkv)) end
        local kov=gv("Settings.Interface.Keybind overlay")
        if kov~=nil then cfg.show_keybinds=kov==true end
        apply_streamer_mode()
        apply_theme_colors(cfg.theme)
        if apply_ui_interface then apply_ui_interface() end
        if apply_ui_font then apply_ui_font(cfg.ui_font) end
        if bind_menu_hotkey then bind_menu_hotkey() end
        if not silent and (cfg.theme~=ot or cfg.menu_key~=mk or cfg.show_keybinds~=ko or cfg.ui_font~=of) then mark_chg() end
    end

    local sl_keys=hotkey_sl
    local warn_opts={"fade","solid","blink","corner_fade","corner_solid","corner_blink","bar_fade","bar_solid","bar_blink"}
    local mac_keys=hotkey_mac

    local function tip(h, txt)
        if h and txt then pcall(function() h:Tooltip(txt) end) end
        return h
    end

    local function ui_set(path, val)
        pcall(function()
            local ok, cur=pcall(function() return UiLib:GetValue(path) end)
            if ok then
                if type(cur)=="table" and type(val)=="table" then
                    if #cur==#val then
                        local same=true
                        for i=1,#cur do if cur[i]~=val[i] then same=false; break end end
                        if same then return end
                    end
                elseif cur==val then return end
            end
            UiLib:SetValue(path, val)
        end)
    end

    local function ui_set_dropdown(path, val)
        val=ui_scalar(val)
        if val==nil then return end
        ui_set(path, {val})
    end

    ui_set_menu_key = function(path, key)
        key=menu_key_pick(norm_menu_key(key))
        pcall(function()
            local ok,cur=pcall(function() return UiLib:GetValue(path) end)
            if ok and norm_menu_key(ui_scalar(cur))==key then return end
            UiLib:SetValue(path, key)
        end)
    end

    bind_menu_hotkey = function()
        cfg.menu_key=norm_menu_key(cfg.menu_key)
        if hotkey_on(cfg.menu_key) then
            pcall(function() win:SetMenuKey(cfg.menu_key) end)
        else
            pcall(function() win:SetMenuKey("") end)
        end
    end

    apply_ui_interface = function()
        local w,h=cfg.ui_w or UI_W_DEFAULT, cfg.ui_h or UI_H_DEFAULT
        ui_set("Settings.Interface.Collapse sidebar", false)
        ui_set_dropdown("Settings.Interface.Tab layout", "Sidebar")
        pcall(function()
            if win.SetSize then win:SetSize(Vector2.new(w,h)) end
            if win.SetSidebarCollapsed then win:SetSidebarCollapsed(false) end
            if win.SetCollapsed then win:SetCollapsed(false) end
        end)
        pcall(function()
            local ps=get_ui_state()
            if not ps then return end
            if ps.sidebarCollapsed~=nil then ps.sidebarCollapsed=false end
            if ps.collapseSidebar~=nil then ps.collapseSidebar=false end
            if ps.sidebarExpanded~=nil then ps.sidebarExpanded=true end
            if ps.collapsed~=nil then ps.collapsed=false end
        end)
    end

    apply_ui_font = function(font)
        font=ui_scalar(font) or ui_scalar(cfg.ui_font) or UI_FONT_DEFAULT
        cfg.ui_font=font
        ui_set_dropdown("Settings.Interface.Font", font)
        pcall(function()
            if UiLib.SetFont then UiLib:SetFont(font)
            elseif win and win.SetFont then win:SetFont(font) end
        end)
        pcall(function()
            local ps=get_ui_state()
            if not ps then return end
            if ps.font~=nil then ps.font=font end
            if ps.uiFont~=nil then ps.uiFont=font end
            if type(ps.settings)=="table" and ps.settings.font~=nil then ps.settings.font=font end
        end)
        refresh_draw_font()
    end

    local gp_tab

    local function select_tab(tab_api, name_or_idx)
        local target = name_or_idx or "Gun Parry"
        return pcall(function()
            if type(win.SelectTab)=="function" then win:SelectTab(target); return end
            if type(win.SetTab)=="function" then win:SetTab(target); return end
            if type(win.SwitchTab)=="function" then win:SwitchTab(target); return end
            if type(win.SetActiveTab)=="function" then win:SetActiveTab(target); return end
            if type(UiLib.SelectTab)=="function" then UiLib:SelectTab(target); return end
            if type(UiLib.SetTab)=="function" then UiLib:SetTab(target); return end
            if type(UiLib.SetActiveTab)=="function" then UiLib:SetActiveTab(target); return end
            if tab_api and type(tab_api.Select)=="function" then tab_api:Select(); return end
            local tab = tab_api and tab_api._tab
            local ps
            if type(debug)=="table" and debug.getupvalue then
                local fn = UiLib.Tab or win.Tab
                if type(fn)=="function" then
                    for i=1,64 do
                        local n,v=debug.getupvalue(fn,i)
                        if not n then break end
                        if n=="ProjectState" and type(v)=="table" then ps=v; break end
                    end
                end
            end
            if ps and type(ps.tabs)=="table" then
                local idx=tonumber(target)
                if not tab then
                    if type(target)=="string" then
                        for i,t in ipairs(ps.tabs) do if t.name==target then tab=t; idx=i; break end end
                    elseif idx then tab=ps.tabs[idx] end
                end
                if tab then
                    if not idx then for i,t in ipairs(ps.tabs) do if t==tab then idx=i; break end end end
                    if idx then ps.activeIndex=idx; ps.activeTab=tab; ps.contentFade=0 end
                end
            end
        end)
    end

    local function sync_ui_from_cfg()
        cfg_syncing=true
        local ok, err=pcall(function()
        local s=ui_set
        local function sd(p, v) s(p, {v}) end
        local bt=cfg.bdg_t or cfg_defaults.bdg_t
        local mg=cfg.mg or cfg_defaults.mg

        s("Gun Parry.Gun Parry.Enable", cfg.gp)
        s("Gun Parry.Gun Parry.Training mode", cfg.training)
        s("Gun Parry.Gun Parry.Glint aim", cfg.gp_aim)
        s("Gun Parry.Gun Parry.LOS bypass", cfg.gp_los)
        s("Gun Parry.Gun Parry.Parry LOS", cfg.parry_los)
        s("Gun Parry.Gun Parry.Incoming warn", cfg.warn)
        s("Gun Parry.Gun Parry.Debug logs", cfg.debug)
        s("Gun Parry.Gun Parry.Castigate delay", cfg.pg_cast)
        s("Gun Parry.Gun Parry.Monarch delay", cfg.pg_mon)
        s("Gun Parry.Gun Parry.Siege delay", cfg.pg_siege)
        s("Gun Parry.Gun Parry.Phoenix delay", cfg.pg_phx)
        s("Gun Parry.Gun Parry.Siege 2nd parry", cfg.s2)
        s("Gun Parry.Gun Parry.Siege gap", cfg.s2_w2f)

        s("Melee Parry.Melee Parry.Enable", cfg.mp)
        s("Melee Parry.Melee Parry.Cooldown ms", cfg.mp_cd)
        s("Melee Parry.Melee Parry.Facing angle", cfg.mp_ang)
        s("Melee Parry.Melee Parry.Parry range", cfg.mp_maxd)
        s("Melee Parry.Melee Parry.Early detect", cfg.mp_detect)
        s("Melee Parry.Melee Parry.Valid window ms", cfg.mp_window)
        s("Melee Parry.Melee Parry.Swing name scan", cfg.mp_scan)
        s("Melee Parry.Memory Animation Melee.Anim melee (memory)", cfg.mp_anim)
        s("Melee Parry.Memory Animation Melee.Anim debug (log ids)", cfg.mp_anim_dbg)

        s("Tuning.Parry Tuning.Max detect", cfg.gp_dist)
        s("Tuning.Parry Tuning.Glare range", cfg.glare_d)
        s("Tuning.Parry Tuning.Castigate margin", mg.castigate)
        s("Tuning.Parry Tuning.Monarch margin", mg.monarch)
        s("Tuning.Parry Tuning.Siege margin", mg.siege)
        s("Tuning.Parry Tuning.Phoenix margin", mg.phoenix)
        s("Tuning.Parry Tuning.Castigate speed", cfg.cas_spd)

        s("Aim.Soft Aim.Enable", cfg.sl)
        s("Aim.Soft Aim.Memory aim", cfg.sl_mem)
        sd("Aim.Soft Aim.Aim part", cfg.sl_part)
        s("Aim.Soft Aim.FOV filter", cfg.sl_fovf)
        s("Aim.Soft Aim.Show FOV circle", cfg.sl_fovs)
        s("Aim.Soft Aim.Strength", cfg.sl_str)
        s("Aim.Soft Aim.Max speed", cfg.sl_spd)
        s("Aim.Soft Aim.Hold time", cfg.sl_dur)
        s("Aim.Soft Aim.FOV radius", cfg.sl_fov)
        s("Aim.Soft Aim.Max dist", cfg.sl_dist)
        sd("Aim.Soft Aim.SA hold key", cfg.sl_key)

        s("Combat.Aura.Enable", cfg.aura)
        s("Combat.Aura.Cancel on opp parry", cfg.aura_cancel)
        s("Combat.Aura.Hitbox mode", cfg.aura_hb)
        s("Combat.Aura.Range", cfg.aura_rng)
        s("Combat.Aura.Cooldown x10ms", cfg.aura_cd)
        sd("Combat.Aura.Toggle key", cfg.aura_key)
        s("Combat.Hitbox Expander.Enable hitbox", cfg.hb)
        sd("Combat.Hitbox Expander.Toggle key", cfg.hb_key)
        s("Combat.Hitbox Expander.Hitbox size", cfg.hb_size)
        s("Combat.Hitbox Expander.Scan range", cfg.hb_rng)

        sd("Game Settings.In-game binds (KEYBINDS.config).Melee", gb("melee"))
        sd("Game Settings.In-game binds (KEYBINDS.config).Parry", gb("parry"))
        sd("Game Settings.In-game binds (KEYBINDS.config).Gun", gb("gun"))
        sd("Game Settings.In-game binds (KEYBINDS.config).Augment", gb("augment"))
        sd("Game Settings.In-game binds (KEYBINDS.config).Interact", gb("interact"))
        sd("Game Settings.In-game binds (KEYBINDS.config).Dash", gb("dash"))
        sd("Game Settings.In-game binds (KEYBINDS.config).Slide", gb("slide"))
        sd("Game Settings.In-game binds (KEYBINDS.config).Jump", gb("jump"))
        sd("Game Settings.In-game binds (KEYBINDS.config).Forward", gb("forward"))
        sd("Game Settings.In-game binds (KEYBINDS.config).Back", gb("back"))
        sd("Game Settings.In-game binds (KEYBINDS.config).Left", gb("left"))
        sd("Game Settings.In-game binds (KEYBINDS.config).Right", gb("right"))

        s("Movement.Speed.Velocity speed", cfg.spd)
        s("Movement.Speed.Hold to activate", cfg.spd_hold)
        sd("Movement.Speed.Hold key", cfg.spd_key)
        s("Movement.Speed.Target studs/s", cfg.spd_top)
        s("Movement.Speed.Ramp rate", cfg.spd_rmp)
        s("Movement.Macros.Streamer mode", cfg.streamer)
        s("Movement.Macros.BDG", cfg.bdg)
        sd("Movement.Macros.BDG key", cfg.bdg_key)
        s("Settings.Redline.Streamer mode", cfg.streamer)
        ui_set_dropdown("Settings.Redline.Menu key", menu_key_pick(cfg.menu_key))
        s("Settings.Redline.Humanization", cfg.hum)
        s("Settings.Redline.Hum min ms", cfg.hum_min)
        s("Settings.Redline.Hum max ms", cfg.hum_max)
        s("Settings.Redline.Hold min ms", cfg.hum_hold_min)
        s("Settings.Redline.Hold max ms", cfg.hum_hold_max)
        s("Settings.Redline.Parry jit lo", cfg.hum_jit_min)
        s("Settings.Redline.Parry jit hi", cfg.hum_jit_max)
        s("Settings.Redline.Siege s2 jit", cfg.hum_jit_s2)

        s("BDG Tune.BDG macro.S hold lo", bt.s_hold_min)
        s("BDG Tune.BDG macro.S hold hi", bt.s_hold_max)
        s("BDG Tune.BDG macro.Dash grapple lo", bt.dash_grapple_min)
        s("BDG Tune.BDG macro.Dash grapple hi", bt.dash_grapple_max)
        s("BDG Tune.BDG macro.W slide lo", bt.w_slide_min)
        s("BDG Tune.BDG macro.W slide hi", bt.w_slide_max)
        s("BDG Tune.BDG macro.Slide hold lo", bt.slide_hold_min)
        s("BDG Tune.BDG macro.Slide hold hi", bt.slide_hold_max)

        s("ESP.Enemy ESP.Enable", cfg.esp)
        s("ESP.Enemy ESP.Name", cfg.esp_name)
        s("ESP.Enemy ESP.Health", cfg.esp_hp)
        s("ESP.Enemy ESP.Posture", cfg.esp_pos)
        s("ESP.Enemy ESP.Distance", cfg.esp_dist)
        s("ESP.Enemy ESP.Box", cfg.esp_box)
        s("ESP.Enemy ESP.Chams", cfg.esp_chams)
        s("ESP.Enemy ESP.Team check (2v2)", cfg.team)
        s("ESP.Enemy ESP.Range", cfg.esp_rng)
        s("ESP.Enemy ESP.Font size", cfg.esp_sz)
        s("ESP.Self HUD.Enable", cfg.hud)
        s("ESP.Self HUD.Font size", cfg.hud_sz)
        s("ESP.Self HUD.X center", cfg.hud_x)
        s("ESP.Self HUD.Y pos", cfg.hud_y)

        s("Warn.Incoming Flash.Enable", cfg.warn)
        sd("Warn.Incoming Flash.Style", cfg.warn_style)
        s("Warn.Incoming Flash.Transparency %", fl((cfg.warn_a or 0.3)*100))
        s("Warn.Incoming Flash.Aim cone angle", cfg.warn_ang)

        sd("Settings.Theme.Preset", cfg.theme)
        ui_set_menu_key("Settings.Interface.Menu key", cfg.menu_key)
        s("Settings.Interface.Keybind overlay", cfg.show_keybinds ~= false)
        s("Settings.Interface.Collapse sidebar", false)
        sd("Settings.Interface.Tab layout", "Sidebar")
        sd("Settings.Interface.Font", cfg.ui_font or UI_FONT_DEFAULT)
        s("Settings.Redline.Notifications", cfg.notify)
        s("Settings.Redline.Auto save (2s)", cfg.auto_save)
        s("Settings.Redline.Auto ping", cfg.auto_ping)
        s("Settings.Redline.Ping ms", cfg.ping)
        end)
        cfg_syncing=false
        if not ok then return end
        bind_menu_hotkey()
    end

    local function reset_cfg()
        cfg_replace(cfg)
        cfg_force_parry_timings()
        set_warn_style(cfg.warn_style)
        apply_theme(cfg.theme)
        sync_ui_from_cfg()
        mark_chg()
        if cfg_save() then
            uinot("Redline","config reset to defaults",3,"success")
        else
            uinot("Redline","reset ok, save failed",4,"warning")
        end
    end

    pcall(function()
        UiLib.SaveConfig=function()
            if cfg_save() then
                uinot("Redline","saved "..cfg_file,3,"success")
            else
                uinot("Redline","save failed",4,"error")
            end
            return UiLib
        end
        UiLib.LoadConfig=function()
            if cfg_load() then
                apply_theme(cfg.theme)
                sync_ui_from_cfg()
                uinot("Redline","loaded "..cfg_file,3,"success")
            else
                uinot("Redline","no config file",3,"warning")
            end
            return UiLib
        end
        UiLib.DeleteConfig=function() return UiLib end
    end)

    pcall(function()
        gp_tab=win:Tab("Gun Parry","shield")
        local tab=gp_tab
        local sec=tab:Section("Gun Parry","Left")
        sec:Toggle("Enable",cfg.gp,function(s) cfg.gp=s; mark_chg() end)
        tip(sec:Toggle("Training mode",cfg.training,function(s) cfg.training=s; mark_chg() end),"also target training dummies and bots, not just real players")
        tip(sec:Toggle("Glint aim",cfg.gp_aim,function(s) cfg.gp_aim=s; mark_chg() end),"snap your crosshair toward the shooter when it parries a gun")
        tip(sec:Toggle("LOS bypass",cfg.gp_los,function(s) cfg.gp_los=s; mark_chg() end),"detect far shots when glint is visible and shooter is aiming at you")
        tip(sec:Toggle("Parry LOS",cfg.parry_los,function(s) cfg.parry_los=s; mark_chg() end),"require clear line of sight to shooter before attributing or parrying")
        sec:Toggle("Incoming warn",cfg.warn,function(s) cfg.warn=s; mark_chg() end)
        tip(sec:Toggle("Debug logs",cfg.debug,function(s) cfg.debug=s; mark_chg() end),"log detects and internals in the console. still parries normally")
        tip(sec:Slider("Castigate delay",cfg.pg_cast,1,50,1500,"ms",function(v) cfg.pg_cast=fl(v); mark_chg() end),"ms to wait after a castigate shot is seen before parrying")
        sec:Slider("Monarch delay",cfg.pg_mon,1,200,3000,"ms",function(v) cfg.pg_mon=fl(v); mark_chg() end)
        sec:Slider("Siege delay",cfg.pg_siege,1,50,2500,"ms",function(v) cfg.pg_siege=fl(v); mark_chg() end)
        sec:Slider("Phoenix delay",cfg.pg_phx,1,50,2000,"ms",function(v) cfg.pg_phx=fl(v); mark_chg() end)
        sec:Toggle("Phoenix rocket parry",cfg.phx_rocket~=false,function(s) cfg.phx_rocket=s; mark_chg() end)
        sec:Slider("Phoenix impact lead",cfg.phx_lead or 60,1,10,200,"ms",function(v) cfg.phx_lead=fl(v); mark_chg() end)
        sec:Slider("Phoenix impact radius",cfg.phx_radius or 30,1,5,80,"st",function(v) cfg.phx_radius=fl(v); mark_chg() end)
        tip(sec:Toggle("Siege 2nd parry",cfg.s2,function(s) cfg.s2=s; mark_chg() end),"siege fires twice. this handles the follow-up parry")
        tip(sec:Slider("Siege gap",cfg.s2_w2f,1,200,2500,"ms",function(v) cfg.s2_w2f=fl(v); mark_chg() end),"time between siege's first and second shot")
    end)

    pcall(function()
        local tab=win:Tab("Melee Parry","swords")
        local sec=tab:Section("Melee Parry","Left")
        sec:Toggle("Enable",cfg.mp,function(s) cfg.mp=s; mark_chg() end)
        sec:Slider("Cooldown ms",cfg.mp_cd,1,50,1000,"ms",function(v) cfg.mp_cd=fl(v); mark_chg() end)
        tip(sec:Slider("Facing angle",cfg.mp_ang,1,5,180,"deg",function(v) cfg.mp_ang=fl(v); mark_chg() end),"only parry swings from attackers facing you within this angle")
        sec:Slider("Parry range",cfg.mp_maxd,1,1,60,"st",function(v) cfg.mp_maxd=fl(v); mark_chg() end)
        tip(sec:Slider("Early detect",cfg.mp_detect,1,5,80,"st",function(v) cfg.mp_detect=fl(v); mark_chg() end),"start watching for a melee swing from this far away")
        tip(sec:Slider("Valid window ms",cfg.mp_window,1,80,600,"ms",function(v) cfg.mp_window=fl(v); mark_chg() end),"how long a detected swing stays parryable")
        tip(sec:Toggle("Swing name scan",cfg.mp_scan,function(s) cfg.mp_scan=s; mark_chg() end),"debug: logs any unknown effect near you. swing a melee at the bot and read the name to wire it up")
        local anim=tab:Section("Memory Animation Melee","Right")
        tip(anim:Toggle("Anim melee (memory)",cfg.mp_anim,function(s) cfg.mp_anim=s; mark_chg() end),"reads enemy animation ids from memory (theo offsets) and parries known melee swings. needs unsafe execution enabled")
        tip(anim:Toggle("Anim debug (log ids)",cfg.mp_anim_dbg,function(s) cfg.mp_anim_dbg=s; mark_chg() end),"logs every animation id read off nearby enemies. swing at the bot to capture the real melee ids, then add them")
        tip(anim:Toggle("Dump attributes (debug)",false,function(s)
            if not s then return end
            local ch=get_char()
            local tool=ch and try(function() return ch:FindFirstChildOfClass("Tool") end)
            if tool then dump_attrs(tool,"tool:"..(try(function() return tool.Name end) or "?")) end
            if ch then dump_attrs(ch,"character") end
            if lp then dump_attrs(lp,"player") end
        end),"equip your gun, flip this on, then paste the [attr] output so the value layout can be decoded")
    end)

    pcall(function()
        local tab=win:Tab("Tuning","sliders")
        local sec=tab:Section("Parry Tuning","Full")
        tip(sec:Slider("Max detect",cfg.gp_dist,1,10,2500,"st",function(v) cfg.gp_dist=fl(v); mark_chg() end),"max distance a gun shot is detected from. raise this for far shots")
        tip(sec:Slider("Glare range",cfg.glare_d,1,1,250,"st",function(v) cfg.glare_d=fl(v); mark_chg() end),"max distance a gun's glare wind-up effect counts")
        tip(sec:Slider("Castigate margin",cfg.mg.castigate,1,0,600,"ms",function(v) cfg.mg.castigate=fl(v); mark_chg() end),"press F this many ms earlier than calculated (lag comp)")
        sec:Slider("Monarch margin",cfg.mg.monarch,1,0,600,"ms",function(v) cfg.mg.monarch=fl(v); mark_chg() end)
        sec:Slider("Siege margin",cfg.mg.siege,1,0,600,"ms",function(v) cfg.mg.siege=fl(v); mark_chg() end)
        sec:Slider("Phoenix margin",cfg.mg.phoenix,1,0,600,"ms",function(v) cfg.mg.phoenix=fl(v); mark_chg() end)
        tip(sec:Slider("Castigate speed",cfg.cas_spd,1,80,800,"st/s",function(v) cfg.cas_spd=fl(v); mark_chg() end),"projectile studs/s for castigate travel at range")
    end)

    pcall(function()
        local tab=win:Tab("Aim","target")
        local sec=tab:Section("Soft Aim","Left")
        sec:Toggle("Enable",cfg.sl,function(s) cfg.sl=s; if not s then rm_fov(); st.sl_tgt=nil; st.sl_til=0 end; mark_chg() end)
        tip(sec:Toggle("Memory aim",cfg.sl_mem,function(s) cfg.sl_mem=s; mark_chg() end),"writes camera rotation via memory. sensitivity-independent. falls back to mouse if write unavailable")
        tip(sec:Dropdown("Aim part",{cfg.sl_part},{"head","body"},false,function(v) cfg.sl_part=v[1]; mark_chg() end),"aim at the head or the torso")
        tip(sec:Toggle("FOV filter",cfg.sl_fovf,function(s) cfg.sl_fovf=s; if not s then rm_fov() end; mark_chg() end),"only target enemies inside the FOV circle")
        sec:Toggle("Show FOV circle",cfg.sl_fovs,function(s) cfg.sl_fovs=s; if not s then rm_fov() end; mark_chg() end)
        tip(sec:Slider("Strength",cfg.sl_str,1,1,100,"",function(v) cfg.sl_str=fl(v); mark_chg() end),"how hard it pulls your aim each tick. higher = snappier")
        tip(sec:Slider("Max speed",cfg.sl_spd,1,0,100,"",function(v) cfg.sl_spd=fl(v); mark_chg() end),"caps how fast the aim moves. lower = smoother, 0 = uncapped")
        tip(sec:Slider("Hold time",cfg.sl_dur,1,1,50,"x100ms",function(v) cfg.sl_dur=fl(v); mark_chg() end),"how long aim stays locked after you release the key (x100ms)")
        sec:Slider("FOV radius",cfg.sl_fov,1,10,600,"px",function(v) cfg.sl_fov=fl(v); mark_chg() end)
        sec:Slider("Max dist",cfg.sl_dist,1,10,1000,"st",function(v) cfg.sl_dist=fl(v); mark_chg() end)
        sec:Dropdown("SA hold key",{cfg.sl_key},sl_keys,false,function(v) cfg.sl_key=v[1]; mark_chg() end)
    end)

    pcall(function()
        local tab=win:Tab("Combat","crosshair")
        local aura=tab:Section("Aura","Left")
        aura:Toggle("Enable",cfg.aura,function(s) cfg.aura=s; if not s then st.aura_pending=false; if cfg.aura_hb then restore_hurtboxes() end end; mark_chg() end)
        tip(aura:Toggle("Cancel on opp parry",cfg.aura_cancel,function(s) cfg.aura_cancel=s; mark_chg() end),"stop your aura swing if the enemy parries first")
        tip(aura:Toggle("Hitbox mode",cfg.aura_hb,function(s) cfg.aura_hb=s; if not s then restore_hurtboxes() end; mark_chg() end),"expand enemy hitboxes right as aura swings so it lands easier. size matches aura range. auto-clears when off or no target")
        aura:Slider("Range",cfg.aura_rng,1,1,100,"st",function(v) cfg.aura_rng=fl(v); mark_chg() end)
        aura:Slider("Cooldown x10ms",cfg.aura_cd,1,1,200,"",function(v) cfg.aura_cd=fl(v); mark_chg() end)
        tip(aura:Dropdown("Toggle key",{cfg.aura_key or HOTKEY_NONE},hotkey_mac,false,function(v) cfg.aura_key=v[1]; mark_chg() end),"tap to toggle aura on/off. none = UI only")
        local hb=tab:Section("Hitbox Expander","Right")
        tip(hb:Toggle("Enable hitbox",cfg.hb,function(s) cfg.hb=s; if s then st.hb_on=true; hb_last_scan=0 else restore_hurtboxes() end; mark_chg() end),"master switch. when on, hitbox stays active until you tap the toggle key")
        tip(hb:Dropdown("Toggle key",{cfg.hb_key or "h"},hotkey_mac,false,function(v) cfg.hb_key=v[1]; mark_chg() end),"only works while Enable hitbox is on. taps hitbox off and back on. none = UI only")
        hb:Slider("Hitbox size",cfg.hb_size,1,1,50,"st",function(v) cfg.hb_size=fl(v); hb_last_scan=0; hb_seen={}; mark_chg() end)
        tip(hb:Slider("Scan range",cfg.hb_rng,1,0,500,"st",function(v) cfg.hb_rng=fl(v); hb_last_scan=0; mark_chg() end),"0 = all enemies. limits who gets expanded for performance")
    end)

    pcall(function()
        local tab=win:Tab("Game Settings","gamepad")
        local sec=tab:Section("In-game binds (KEYBINDS.config)","Full")
        local function gbind(key, label)
            sec:Dropdown(label,{gb(key)},bind_list,false,function(v)
                if not cfg.game then cfg.game={} end
                cfg.game[key]=v[1]; mark_chg()
            end)
        end
        gbind("melee","Melee")
        gbind("parry","Parry")
        gbind("gun","Gun")
        gbind("augment","Augment")
        gbind("interact","Interact")
        gbind("dash","Dash")
        gbind("slide","Slide")
        gbind("jump","Jump")
        gbind("forward","Forward")
        gbind("back","Back")
        gbind("left","Left")
        gbind("right","Right")
    end)

    pcall(function()
        local tab=win:Tab("Movement","gauge")
        local spd=tab:Section("Speed","Left")
        spd:Toggle("Velocity speed",cfg.spd,function(s) cfg.spd=s; if not s then st.spd_vacc=nil end; mark_chg() end)
        spd:Toggle("Hold to activate",cfg.spd_hold,function(s) cfg.spd_hold=s; mark_chg() end)
        spd:Dropdown("Hold key",{cfg.spd_key},hotkey_bind,false,function(v) cfg.spd_key=v[1]; mark_chg() end)
        spd:Slider("Target studs/s",cfg.spd_top,1,16,250,"st/s",function(v) cfg.spd_top=fl(v); mark_chg() end)
        spd:Slider("Ramp rate",cfg.spd_rmp,1,1,250,"",function(v) cfg.spd_rmp=fl(v); mark_chg() end)
        local sm=tab:Section("Macros","Right")
        tip(sm:Toggle("Streamer mode",cfg.streamer~=false,function(s) cfg.streamer=s; apply_streamer_mode(); mark_chg() end),"hides toasts and keybind overlay while streaming")
        tip(sm:Toggle("BDG",cfg.bdg,function(s) cfg.bdg=s; if not s then mod.bdg_abort() end; mark_chg() end),"see BDG Tune tab")
        sm:Dropdown("BDG key",{cfg.bdg_key},mac_keys,false,function(v) cfg.bdg_key=v[1]; mark_chg() end)
        apply_streamer_mode()
    end)

    pcall(function()
        if type(cfg.bdg_t)~="table" then cfg.bdg_t={}; deep_copy(cfg_defaults.bdg_t,cfg.bdg_t) end
        local bt=cfg.bdg_t

        local tab=win:Tab("BDG Tune","zap")
        local sec=tab:Section("BDG macro","Full")
        tip(sec:Slider("S hold lo",bt.s_hold_min,1,1,80,"ms",function(v) cfg.bdg_t.s_hold_min=fl(v); mark_chg() end),"S before backdash")
        tip(sec:Slider("S hold hi",bt.s_hold_max,1,1,80,"ms",function(v) cfg.bdg_t.s_hold_max=fl(v); mark_chg() end),"S before backdash")
        tip(sec:Slider("Dash grapple lo",bt.dash_grapple_min,1,1,60,"ms",function(v) cfg.bdg_t.dash_grapple_min=fl(v); mark_chg() end),"grapple mid-dash — too long = ~125 u/s")
        tip(sec:Slider("Dash grapple hi",bt.dash_grapple_max,1,1,60,"ms",function(v) cfg.bdg_t.dash_grapple_max=fl(v); mark_chg() end),"grapple mid-dash — aim ~140-150 u/s")
        tip(sec:Slider("W slide lo",bt.w_slide_min,1,0,40,"ms",function(v) cfg.bdg_t.w_slide_min=fl(v); mark_chg() end),"delay after W before slide")
        tip(sec:Slider("W slide hi",bt.w_slide_max,1,0,40,"ms",function(v) cfg.bdg_t.w_slide_max=fl(v); mark_chg() end),"delay after W before slide")
        tip(sec:Slider("Slide hold lo",bt.slide_hold_min,1,200,3000,"ms",function(v) cfg.bdg_t.slide_hold_min=fl(v); mark_chg() end),"hold slide after grapple")
        tip(sec:Slider("Slide hold hi",bt.slide_hold_max,1,200,3000,"ms",function(v) cfg.bdg_t.slide_hold_max=fl(v); mark_chg() end),"hold slide after grapple")
    end)

    pcall(function()
        local tab=win:Tab("ESP","eye")
        local esp=tab:Section("Enemy ESP","Left")
        esp:Toggle("Enable",cfg.esp,function(s) cfg.esp=s; mark_chg() end)
        esp:Toggle("Name",cfg.esp_name,function(s) cfg.esp_name=s; mark_chg() end)
        esp:Toggle("Health",cfg.esp_hp,function(s) cfg.esp_hp=s; mark_chg() end)
        esp:Toggle("Posture",cfg.esp_pos,function(s) cfg.esp_pos=s; mark_chg() end)
        esp:Toggle("Distance",cfg.esp_dist,function(s) cfg.esp_dist=s; mark_chg() end)
        tip(esp:Toggle("Box ESP",cfg.esp_box,function(s) cfg.esp_box=s; mark_chg() end),"2D bounding box around players")
        tip(esp:Toggle("Chams",cfg.esp_chams,function(s) cfg.esp_chams=s; mark_chg() end),"Highlight players through walls (2v2 team rules apply)")
        tip(esp:Toggle("Team check (2v2 only)",cfg.team,function(s) cfg.team=s; mark_chg() end),"hide teammates in 2v2 place IDs only; FFA/lobby ignore this")
        esp:Slider("Range",cfg.esp_rng,1,10,1500,"st",function(v) cfg.esp_rng=fl(v); mark_chg() end)
        esp:Slider("Font size",cfg.esp_sz,1,8,30,"px",function(v) cfg.esp_sz=fl(v); mark_chg() end)
        esp:Colorpicker("ESP color",Color3.fromRGB(cfg.esp_r,cfg.esp_g,cfg.esp_b),function(co)
            cfg.esp_r=fl(co.R*255); cfg.esp_g=fl(co.G*255); cfg.esp_b=fl(co.B*255); mark_chg()
        end)
        local places=tab:Section("Place IDs","Right")
        local place_lbl=places:Label("PlaceId: "..tostring(cur_place_id() or "?"))
        local lobby_lbl=places:Label("Lobby: "..place_list_str(cfg.lobby_places))
        local twov2_lbl=places:Label("2v2: "..place_list_str(cfg.twov2_places))
        local function refresh_place_labels()
            pcall(function() place_lbl:Set("PlaceId: "..tostring(cur_place_id() or "?")) end)
            pcall(function() lobby_lbl:Set("Lobby: "..place_list_str(cfg.lobby_places)) end)
            pcall(function() twov2_lbl:Set("2v2: "..place_list_str(cfg.twov2_places)) end)
        end
        tip(places:Button("Log PlaceId", function()
            local p=log_place_id("manual")
            rn("PlaceId: "..tostring(p),"Redline",5)
            refresh_place_labels()
        end),"print current PlaceId to console + notification")
        tip(places:Button("Copy PlaceId", function()
            local p=cur_place_id()
            if p and setclipboard then pcall(setclipboard, tostring(p)); rn("PlaceId copied","Redline",2) end
        end),"copy PlaceId to clipboard")
        tip(places:Button("Add -> lobby_places", function()
            if place_list_add("lobby_places") then
                refresh_place_labels()
                rn("added to lobby list","Redline",2)
            else
                rn("already in lobby list","Redline",2)
            end
        end),"disable all features except ESP in this place")
        tip(places:Button("Add -> twov2_places", function()
            if place_list_add("twov2_places") then
                refresh_place_labels()
                rn("added to 2v2 list","Redline",2)
            else
                rn("already in 2v2 list","Redline",2)
            end
        end),"team check only applies in these places")
        local hud=tab:Section("Self HUD","Full")
        hud:Toggle("Enable",cfg.hud,function(s) cfg.hud=s; if not s then rm_hud() end; mark_chg() end)
        hud:Slider("Font size",cfg.hud_sz,1,8,32,"px",function(v) cfg.hud_sz=fl(v); mark_chg() end)
        hud:Slider("X center",cfg.hud_x,1,0,3840,"px",function(v) cfg.hud_x=fl(v); mark_chg() end)
        hud:Slider("Y pos",cfg.hud_y,1,0,2160,"px",function(v) cfg.hud_y=fl(v); mark_chg() end)
    end)

    pcall(function()
        local tab=win:Tab("Warn","bell")
        local sec=tab:Section("Incoming Flash","Full")
        sec:Toggle("Enable",cfg.warn,function(s) cfg.warn=s; mark_chg() end)
        sec:Dropdown("Style",{cfg.warn_style},warn_opts,false,function(v) cfg.warn_style=v[1]; set_warn_style(v[1]); mark_chg() end)
        sec:Slider("Transparency %",fl((cfg.warn_a or 0.3)*100),1,0,95,"%",function(v) cfg.warn_a=fl(v)/100; mark_chg() end)
        tip(sec:Slider("Aim cone angle",cfg.warn_ang,1,20,180,"deg",function(v) cfg.warn_ang=fl(v); mark_chg() end),"only warn when the shooter is pointed at you within this angle")
        sec:Colorpicker("Flash color",Color3.fromRGB(cfg.warn_r,cfg.warn_g,cfg.warn_b),function(co)
            cfg.warn_r=fl(co.R*255); cfg.warn_g=fl(co.G*255); cfg.warn_b=fl(co.B*255); mark_chg()
        end)
    end)

    pcall(function()
        win:AddSettingsTab("cog")
        local rl=win:SettingsSection("Redline","Full")
        rl:Label("File: "..cfg_file)
        rl:Button("Save config", function()
            if cfg_save() then
                uinot("Redline","saved "..cfg_file,3,"success")
            else
                uinot("Redline","save failed",4,"error")
            end
        end):AddButton("Load config", function()
            if cfg_load() then
                apply_theme(cfg.theme)
                sync_ui_from_cfg()
                uinot("Redline","loaded "..cfg_file,3,"success")
            else
                uinot("Redline","no config file",3,"warning")
            end
        end)
        tip(rl:Button("Reset to defaults", function() reset_cfg() end),"reset every setting. reinject to refresh the menu sliders")
        rl:Divider("Options")
        tip(rl:Dropdown("Menu key",{menu_key_pick(cfg.menu_key)},hotkey_menu,false,function(v)
            cfg.menu_key=norm_menu_key(v); mark_chg()
            bind_menu_hotkey()
            ui_set_menu_key("Settings.Interface.Menu key", cfg.menu_key)
        end),"open/close this menu. none disables the hotkey")
        tip(rl:Toggle("Streamer mode", cfg.streamer~=false, function(s) cfg.streamer=s; apply_streamer_mode(); mark_chg() end),"hides toasts and keybind overlay")
        tip(rl:Toggle("Auto save (2s)", cfg.auto_save, function(s) cfg.auto_save=s; mark_chg() end),"saves your settings 2s after any change")
        tip(rl:Toggle("Notifications", cfg.notify, function(s) cfg.notify=s; mark_chg() end),"toast popups")
        rl:Divider("Humanization")
        rl:Toggle("Enable", cfg.hum, function(s) cfg.hum=s; mark_chg() end)
        rl:Slider("Hum min ms", cfg.hum_min, 1, 5, 50, "ms", function(v) cfg.hum_min=fl(v); mark_chg() end)
        rl:Slider("Hum max ms", cfg.hum_max, 1, 10, 150, "ms", function(v) cfg.hum_max=fl(v); mark_chg() end)
        rl:Slider("Hold min ms", cfg.hum_hold_min, 1, 15, 120, "ms", function(v) cfg.hum_hold_min=fl(v); mark_chg() end)
        rl:Slider("Hold max ms", cfg.hum_hold_max, 1, 25, 150, "ms", function(v) cfg.hum_hold_max=fl(v); mark_chg() end)
        rl:Slider("Parry jit lo", cfg.hum_jit_min, 1, 0, 50, "ms", function(v) cfg.hum_jit_min=fl(v); mark_chg() end)
        rl:Slider("Parry jit hi", cfg.hum_jit_max, 1, 5, 60, "ms", function(v) cfg.hum_jit_max=fl(v); mark_chg() end)
        rl:Slider("Siege s2 jit", cfg.hum_jit_s2, 1, 0, 25, "ms", function(v) cfg.hum_jit_s2=fl(v); mark_chg() end)
        ui_ping_sync=function(p) ui_set("Settings.Redline.Ping ms", p or cfg.ping) end
        local ping_now=read_ping() or cfg.ping or 47
        local ping_max=mx(400, ping_now+150)
        rl:Toggle("Auto ping", cfg.auto_ping, function(s)
            cfg.auto_ping=s; mark_chg()
            if s then apply_auto_ping() end
        end)
        rl:Slider("Ping ms", cl(cfg.ping,0,ping_max), 1, 0, ping_max, "ms", function(v)
            if cfg.auto_ping then return end
            cfg.ping=fl(v); mark_chg()
        end)
        if cfg.auto_ping then apply_auto_ping() end
        settings_hide("Configs")
        settings_reorder("Redline", 1)
    end)

    pcall(function() select_tab(gp_tab, "Gun Parry") end)
    task.defer(function() pcall(function() select_tab(gp_tab, 1) end) end)

    apply_theme(cfg.theme)
    sync_ui_from_cfg()
    apply_ui_interface()
    apply_ui_font()
    apply_streamer_mode()

    task.defer(function()
        task.wait(0.12)
        apply_ui_interface()
        bind_menu_hotkey()
        task.wait(0.35)
        apply_ui_interface()
        bind_menu_hotkey()
    end)

    task.spawn(function()
        local last_theme=cfg.theme
        local last_font=cfg.ui_font or UI_FONT_DEFAULT
        local last_menu=norm_menu_key(cfg.menu_key)
        while loops_active do
            task.wait(0.75)
            if cfg_syncing then continue end
            pcall(function()
                if not UiLib then return end
                local ok,tp=pcall(function() return UiLib:GetValue("Settings.Theme.Preset") end)
                if ok then
                    local name=ui_val_str(tp)
                    if type(name)=="string" and name~="" and name~="Default" and name~="Custom" and name~=last_theme then
                        last_theme=name
                        cfg.theme=name
                        apply_theme_colors(name)
                        mark_chg()
                    end
                end
                local okf,fv=pcall(function() return UiLib:GetValue("Settings.Interface.Font") end)
                if okf then
                    local ui_font=ui_val_str(fv)
                    if type(ui_font)=="string" and ui_font~="" and ui_font~=last_font then
                        last_font=ui_font
                        cfg.ui_font=ui_font
                        pcall(function()
                            if UiLib.SetFont then UiLib:SetFont(ui_font)
                            elseif win and win.SetFont then win:SetFont(ui_font) end
                        end)
                        refresh_draw_font()
                        mark_chg()
                    end
                end
                local okm,mkv=pcall(function() return UiLib:GetValue("Settings.Interface.Menu key") end)
                if okm then
                    local norm=norm_menu_key(ui_val_str(mkv))
                    if norm~=last_menu then
                        last_menu=norm
                        cfg.menu_key=norm
                        bind_menu_hotkey()
                        mark_chg()
                    end
                end
                local ok2,col=pcall(function() return UiLib:GetValue("Settings.Interface.Collapse sidebar") end)
                if ok2 and col==true then apply_ui_interface() end
            end)
        end
    end)

    task.spawn(function()
        while loops_active do
            local active=false
            pcall(function() active=isrbxactive() end)
            if active then
                if cfg.hb and hotkey_on(cfg.hb_key) then
                    bind_edge("hb", function() return hotkey_vk(cfg.hb_key) end, function()
                        st.hb_on=not st.hb_on
                        if st.hb_on then hb_last_scan=0 else restore_hurtboxes() end
                        uinot("Redline","hitbox "..(st.hb_on and "ON" or "OFF"),1)
                    end, 0.22)
                else bind_st.hb=nil end
                if hotkey_on(cfg.aura_key) then
                    bind_edge("aura", function() return hotkey_vk(cfg.aura_key) end, function()
                        cfg.aura=not cfg.aura
                        if not cfg.aura then
                            st.aura_pending=false
                            if cfg.aura_hb then restore_hurtboxes() end
                        end
                        mark_chg()
                        pcall(function() ui_set("Combat.Aura.Enable", cfg.aura) end)
                        uinot("Redline","aura "..(cfg.aura and "ON" or "OFF"),1)
                    end, 0.22)
                else bind_st.aura=nil end
            else
                bind_st.hb=nil
                bind_st.aura=nil
            end
            task.wait(0.03)
        end
    end)

    _G.rl_ui=UiLib
    local old_cleanup=_G.rl_cleanup
    _G.rl_cleanup=function()
        pcall(function() if UiLib then UiLib:Destroy() end end)
        if old_cleanup then old_cleanup() end
    end

    uinot("Redline","loaded",3,"success")
    log("[rl] v34 | INS-ui | fps "..get_fps())
end)

end
