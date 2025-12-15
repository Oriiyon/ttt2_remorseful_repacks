local PAP_JOHN = CreateConVar("ttt_suicide_pap_john", 1, {FCVAR_ARCHIVE}, "Whether PaP bomb plays John Cena SFX", 0, 1)

local UPGRADE = {}
UPGRADE.id    = "suicide_pap"
UPGRADE.class = "weapon_ttt_suicide"
-- Note: this attempts to load before the OG suicide bomb's PAP but isn't guaranteed :/

function UPGRADE:Apply(SWEP)
    SWEP.Packed = true --way simpler to implement/read like this

    -- setting correct name/desc based on cvar setup
    UPGRADE.name = "Suicide Bomb" --if it grants no benefit (bad cvars)
    local DEFAULT_DESC = "No change (bad convars)"
    local desc = DEFAULT_DESC

    if PAP_JOHN:GetBool() then
        UPGRADE.name = "John Bomb"
        desc = "John Cena intro"
    end

    if GetConVar("ttt_suicide_pap_resist"):GetFloat() >= 40 then
        UPGRADE.name = "Survival Bomb" --overrides John Bomb, more important
        if desc == DEFAULT_DESC then
            desc = "Resist explosion damage"
        else
            desc = desc .. " + resist explosion damage"
        end
    end
    UPGRADE.desc = desc .. "!"

    -- og john cena sfx logic
    if PAP_JOHN:GetBool() then
        SWEP.PAPOldPrimaryAttack = SWEP.PrimaryAttack
        function SWEP:PrimaryAttack()
            self:PAPOldPrimaryAttack()
            local owner = self:GetOwner()

            if IsValid(owner) then
                owner:StopSound("weapons/weapon_ttt_suicide/bouta_blow.wav")
                owner:StopSound("weapons/weapon_ttt_suicide/bouta_blow2.wav")
                owner:EmitSound("ttt_pack_a_punch/john_bomb/johncena.mp3")
            end
        end
    end
end

TTTPAP:Register(UPGRADE)
