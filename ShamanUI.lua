

local _, class = UnitClass("player")

if class ~= "SHAMAN" then
    return
end

_G["BINDING_NAME_CLICK ShamanUiMainhandWeapon:LeftButton"] = "Main hand weapon"
_G["BINDING_NAME_CLICK ShamanUiOffhandWeapon:LeftButton"] = "Off hand weapon"

ShamanUiMixin = {}
ShamanUiMixin.weaponImbueDuration = 30.0
ShamanUiMixin.weaponImbues = {
    --windfury
    [238] = 136018,
    [284] = 136018,
    [525] = 136018,
    [1669] = 136018,
    [2636] = 136018,
    [3785] = 136018,
    [3786] = 136018,
    [3787] = 136018,

    --flametongue
    [5] = 135814,
    [4] = 135814,
    [3] = 135814,
    [523] = 135814,
    [1665] = 135814,
    [1666] = 135814,
    [2634] = 135814,
    [3779] = 135814,
    [3780] = 135814,
    [3781] = 135814,
}

function ShamanUiMixin:OnLoad()

    self:RegisterEvent("ADDON_LOADED")

    self.shards = {}

    for i = 0, 4 do
        local t = self:CreateTexture(nil, "ARTWORK")
        t:SetSize(17, 22)
        t:SetPoint("LEFT", (i*25) + 8, 1)
        t:SetAtlas("Warlock-ReadyShard")
        t:Hide()
        self.shards[i+1] = t;
    end


    self.mainhandIcon = GetInventoryItemTexture('player', GetInventorySlotInfo("MAINHANDSLOT"))
    if self.mainhandIcon then
        self.mainhandWeapon:SetNormalTexture(self.mainhandIcon)
    end
    self.offhandIcon = GetInventoryItemTexture('player', GetInventorySlotInfo("SECONDARYHANDSLOT"))
    if self.offhandIcon then
        self.offhandWeapon:SetNormalTexture(self.offhandIcon)
    end

    self.mainhandWeapon:SetScript('OnReceiveDrag', function()
        local info, a, b, c = GetCursorInfo()
        if info == "spell" then
            local spellName = GetSpellInfo(c)
            self:SetWeaponImbueButton(self.mainhandWeapon, spellName, 16)
            ShamanUiAccount.imbues.mainhandWeapon = spellName;
        end
        ClearCursor()
    end)

    self.offhandWeapon:SetScript('OnReceiveDrag', function()
        local info, a, b, c = GetCursorInfo()
        if info == "spell" then
            local spellName = GetSpellInfo(c)
            self:SetWeaponImbueButton(self.offhandWeapon, spellName, 17)
            ShamanUiAccount.imbues.offhandWeapon = spellName;
        end
        ClearCursor()
    end)
end

function ShamanUiMixin:SetWeaponImbueButton(button, imbue, slot)
    button:SetAttribute("macrotext1", string.format([[
/cast [@none] %s
/use %s
/click StaticPopup1Button1
    ]], imbue, slot))
end

function ShamanUiMixin:OnMouseDown(button)

    if IsShiftKeyDown() and (button == "RightButton") then
        self:StartMoving()
    end
end

function ShamanUiMixin:OnMouseUp(button)

    if button == "RightButton" then
        self:StopMovingOrSizing()
    end
end

function ShamanUiMixin:Init()

    if ShamanUiAccount.imbues.mainhandWeapon then
        self:SetWeaponImbueButton(self.mainhandWeapon, ShamanUiAccount.imbues.mainhandWeapon, 16)
    end
    if ShamanUiAccount.imbues.offhandWeapon then
        self:SetWeaponImbueButton(self.offhandWeapon, ShamanUiAccount.imbues.offhandWeapon, 17)
    end


end


function ShamanUiMixin:OnEvent(event, ...)

    if event == "ADDON_LOADED" then

        if not ShamanUiAccount then
            ShamanUiAccount = {
                imbues = {
                    mainhandWeapon = nil,
                    offhandWeapon = nil,
                },
                config = {},
                minimapButton = {},
                shields = {},
                bars = {},
                shocks = {},
                priorityLists = {},
            }
        end


        self:Init()
    end

end

function ShamanUiMixin:OnUpdate()

    for i = 1, 5 do
        self.shards[i]:Hide()
    end
    self.maelstromWeaponDuration:SetValue(0)

    for i = 1, 40 do
        local name, icon, count, _, duration, expirationTime, _, _, _, spellID = UnitAura("player", i, "HELPFUL")

        --maelstrom weapon
        if (spellID == 53817) and (count > 0) then
            for i = 1, count do
                self.shards[i]:Show()
            end

            local remaining = duration - (expirationTime - GetTime())
            if remaining > 0 then
                self.maelstromWeaponDuration:SetValue(1 - (remaining / duration))
            end
        end

    end

    local hasMainHandEnchant, mainHandExpiration, mainHandCharges, mainHandEnchantID, hasOffHandEnchant, offHandExpiration, offHandCharges, offHandEnchantID = GetWeaponEnchantInfo()

    if hasMainHandEnchant then
        if self.weaponImbues[mainHandEnchantID] then
            self.mainhandWeapon:SetNormalTexture(self.weaponImbues[mainHandEnchantID])

            -- local elapsed = (30 * 60 * 1000) - mainHandExpiration
            -- local startTime = GetTime() - (elapsed / 1000)

            self.mainhandWeapon.cooldown:SetCooldown(GetTime() - (((30*60*1000) - mainHandExpiration) / 1000), 30*60)
        end
    else
        self.mainhandWeapon:SetNormalTexture(self.mainhandIcon)
        self.mainhandWeapon.cooldown:SetCooldown(0,0)
    end
    if hasOffHandEnchant then
        if self.weaponImbues[offHandEnchantID] then
            self.offhandWeapon:SetNormalTexture(self.weaponImbues[offHandEnchantID])

            self.offhandWeapon.cooldown:SetCooldown(GetTime() - (((30*60*1000) - offHandExpiration) / 1000), 30*60)
        end
    else
        self.offhandWeapon:SetNormalTexture(self.offhandIcon)
        self.offhandWeapon.cooldown:SetCooldown(0,0)
    end
end
