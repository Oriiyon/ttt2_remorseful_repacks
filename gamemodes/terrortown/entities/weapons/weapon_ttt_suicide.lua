AddCSLuaFile()

local EXTRA_USER_DMG = CreateConVar("ttt_suicide_user_dmg", 200, {FCVAR_ARCHIVE}, "How much extra damage to deal to a user if they weren't killed by the blast",  0)
local FLUKE_CHANCE = CreateConVar("ttt_suicide_alt_sfx_chance", 3, {FCVAR_ARCHIVE}, "Chance to play the alternative blowing sound (%)", 0, 100)
local EXPLOSION_MAGNITUDE = CreateConVar("ttt_suicide_magnitude", 200, {FCVAR_ARCHIVE}, "Effective radius of the bomb", 0)
local EXPLOSION_DELAY = CreateConVar("ttt_suicide_delay", 1.72, {FCVAR_ARCHIVE}, "Delay before explosion in seconds", 0)
local PAP_RESIST_PERCENT = CreateConVar("ttt_suicide_pap_resist", 100, {FCVAR_ARCHIVE}, "Explosion damage resisted with PaP (%)", 0, 100)

if CLIENT then
    SWEP.PrintName = "Suicide Bomb"
    SWEP.Slot = 6
    SWEP.Icon = "vgui/ttt/icon_weapon_ttt_suicidebomb"
    SWEP.IconLetter = "I"
end

SWEP.Base = "weapon_tttbase"
SWEP.HoldType = "slam"

SWEP.Primary.Ammo = "none"
SWEP.Primary.Delay = 5
SWEP.Primary.ClipSize = -1
SWEP.Primary.ClipMax = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = false

SWEP.UseHands = true
SWEP.ViewModelFlip = false
SWEP.ViewModelFOV = 54
SWEP.ViewModel = Model("models/weapons/cstrike/c_c4.mdl")
SWEP.WorldModel = Model("models/weapons/w_c4.mdl")
SWEP.idleResetFix = true

SWEP.Kind = WEAPON_EQUIP1
SWEP.AutoSpawnable = false
SWEP.AmmoEnt = "none"
SWEP.CanBuy = { ROLE_TRAITOR }
SWEP.InLoadoutFor = { nil }
SWEP.LimitedStock = true
SWEP.AllowDrop = true
SWEP.IsSilent = false
SWEP.NoSights = true

function SWEP:SetupDataTables()
    self:NetworkVar("Bool", 0, "Fluke")
end


function SWEP:Precache()
    util.PrecacheSound("weapons/weapon_ttt_suicide/boom.wav")
    util.PrecacheSound("weapons/weapon_ttt_suicide/bouta_blow.wav")
end

function SWEP:Reload() end

function SWEP:Initialize()
    if SERVER then
        self:SetFluke(false)
    elseif CLIENT then
        self:AddTTT2HUDHelp("suicide_instruction")
    end
end

function SWEP:PrimaryAttack()
    self:SetNextPrimaryFire(CurTime() + 1.72)

    local effectdata = EffectData()
    effectdata:SetOrigin(self:GetOwner():GetPos())
    effectdata:SetNormal(self:GetOwner():GetPos())
    effectdata:SetMagnitude(8)
    effectdata:SetScale(1)
    effectdata:SetRadius(78)
    util.Effect("Sparks", effectdata)
    self.BaseClass.ShootEffects(self)
    if SERVER then
        self:SetFluke(math.random() < (FLUKE_CHANCE:GetFloat() / 100))
    end

    if SERVER then
        timer.Simple(EXPLOSION_DELAY:GetFloat(), function()
            self:Explode()
        end)
        self:GetOwner():EmitSound("weapons/weapon_ttt_suicide/bouta_blow" .. (self:GetFluke() and "2" or "") .. ".wav")
    end
end

function SWEP:Explode()
    local ply = self:GetOwner()
    if not IsValid(ply) then
        self:Remove()
        return
    end

    local papResistHook = "pap_suicide_resist" .. ply:Nick()
    if SERVER and self.Packed then
        -- prevent PaP'd suicide bomb from damaging user
        hook.Add("EntityTakeDamage", papResistHook, function(target, dmginfo)
            if target == ply then
                dmginfo:ScaleDamage(1 - (PAP_RESIST_PERCENT:GetFloat()/100))
                hook.Remove("EntityTakeDamage", papResistHook)
            end
        end)
    end

    local ent = ents.Create("env_explosion")
    ent:SetPos(ply:GetPos())
    ent:SetOwner(ply)
    ent:SetKeyValue("iMagnitude", EXPLOSION_MAGNITUDE:GetFloat())
    ent:Spawn()
    ent:Fire("Explode", 0, 0)
    ent:EmitSound("weapons/weapon_ttt_suicide/boom" .. (self:GetFluke() and "2" or "") .. ".wav")

    local extraDmg = EXTRA_USER_DMG:GetFloat()
    if self.Packed then
        -- ensure explosion resist gets removed from user if it somehow didn't proc
        timer.Simple(3, function()
            hook.Remove("EntityTakeDamage", papResistHook)
        end)

    elseif extraDmg > 0 then
        -- hurt/kill the user next think if the explosion didnt kill
        local displayCopy = ents.Create("weapon_ttt_suicide") --for body search; sucks but will be cleaned up

        timer.Simple(1/100, function()
            if IsValid(ply) and ply:Alive() then
                -- cannot set damage type to explosion via TakeDamage Info
                -- to get the right icon as that's what allow explosion
                -- immunity to catch it
                ply:TakeDamage(extraDmg, ply, displayCopy)
            end
            displayCopy:Remove()
        end)
    end

    self:Remove()
end

function SWEP:AddToSettingsMenu(parent)
    local formMain = vgui.CreateTTT2Form(parent, "label_suicide_main_form")

    formMain:MakeSlider({
        serverConvar = "ttt_suicide_user_dmg",
        label = "label_suicide_user_dmg",
        min = 0,
        max = 1000,
        decimal = 0
    })
    formMain:MakeSlider({
        serverConvar = "ttt_suicide_magnitude",
        label = "label_suicide_magnitude",
        min = 0,
        max = 1000,
        decimal = 0
    })
    formMain:MakeSlider({
        serverConvar = "ttt_suicide_delay",
        label = "label_suicide_delay",
        min = 0,
        max = 5,
        decimal = 2
    })
    formMain:MakeSlider({
        serverConvar = "ttt_suicide_alt_sfx_chance",
        label = "label_suicide_alt_sfx_chance",
        min = 0,
        max = 100,
        decimal = 0
    })

    local formPaP = vgui.CreateTTT2Form(parent, "label_suicide_pap_form")
    formPaP:MakeHelp({
        label = "label_suicide_pap_resist_desc"
    })
    formPaP:MakeSlider({
        serverConvar = "ttt_suicide_pap_resist",
        label = "label_suicide_pap_resist",
        min = 0,
        max = 100,
        decimal = 0
    })
    formPaP:MakeCheckBox({
        serverConvar = "ttt_suicide_pap_john",
        label = "label_suicide_pap_john"
    })
end

if CLIENT then
    local desc = "Blow away all your friends!\nBlows the user and surrounding terrorists."
    if EXTRA_USER_DMG:GetFloat() >= 100 then --note: must reload map to see change
        desc = desc .. "\n(Explosion immunity will not save you.)"
    end

    SWEP.EquipMenuData = {
        type = "Weapon",
        desc = desc,
    }
end
