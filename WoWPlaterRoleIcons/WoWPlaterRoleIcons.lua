-- CONSTRUCTOR
function (self, unitId, unitFrame, envTable)
    
    if (not _G.KnownPlayerSpecs) then
        _G.KnownPlayerSpecs = { } -- create cache
    end

    envTable.CreateRoleIcon = function (uf)

        if (not UnitIsPlayer(uf.unit)) then
            return
        end

        local role = UnitGroupRolesAssigned (uf.unit)

        if (role and role ~= "NONE") then
            _G.KnownPlayerSpecs[uf.namePlateUnitGUID] = role --  Display assigned role
            envTable.AddRoleIcon (et, uf, role)
            return
        end
            
        if (UnitIsUnit(uf.unit, "target")) then -- Display role from inspect specialization if player is targeting sth
            local f = CreateFrame("Frame")
            
            function InspectSpec()
                if CanInspect("target") then
                    _G.IsInspectInProgress = true
                    f:RegisterEvent("INSPECT_READY")
                    NotifyInspect("target")
                end
            end
    
            f:SetScript("OnEvent", function(self, event, ...)
                local lUf = uf
                if (not UnitIsUnit(lUf.unit, "target")) then
                    return
                end

                local spec = GetInspectSpecialization("target")
                f:UnregisterEvent("INSPECT_READY")
                ClearInspectPlayer()

                local id, name, description, icon, inspectedRole, class = GetSpecializationInfoByID (spec)
                
                _G.KnownPlayerSpecs[uf.namePlateUnitGUID] = inspectedRole

                envTable.AddRoleIcon (envTable, lUf, inspectedRole)                
            end)

            InspectSpec()

        elseif (Plater.ZoneInstanceType == "arena") then -- Display roles for arena opponeents
            local opponents = GetNumArenaOpponentSpecs()
            for i = 1, opponents do
                local unitGUID = UnitGUID ("arena" .. i)
                if (unitGUID == uf [MEMBER_GUID]) then
                    local spec = GetArenaOpponentSpec (i)
                    if (spec) then
                        local id, name, description, icon, arenaRole, class = GetSpecializationInfoByID (spec)
                        if (arenaRole and arenaRole ~= "NONE") then
                            _G.KnownPlayerSpecs[uf.namePlateUnitGUID] = arenaRole
                            envTable.AddRoleIcon (envTable, uf, arenaRole)
                        end
                    end
                end
            end
        elseif (Plater.ZoneInstanceType == "pvp") then -- Display role in pvp by using Details! addon API
            if (Details and Details.GetActor) then
                local actor = Details.GetActor ("current", DETAILS_ATTRIBUTE_DAMAGE, GetUnitName (uf.unit, true))
                if (actor) then
                    local spec = actor.spec
                    if (spec) then
                        local id, name, description, icon, pvpRole, class = GetSpecializationInfoByID (spec)
                        if (pvpRole and pvpRole ~= "NONE") then
                            _G.KnownPlayerSpecs[uf.namePlateUnitGUID] = pvpRole
                            envTable.AddRoleIcon (envTable, uf, pvpRole)
                        end
                    end
                end
            end
        end

    end
  
    envTable.AddRoleIcon = function (et, uf, role) -- create function for adding icon to the heaelthbar of the unitplate

        if (uf.RoleFrame) then
            uf.RoleFrame:Hide()
        end

        if (not UnitIsPlayer(uf.unit) or role == "NONE") then
            return
        end

        if (role == "HEALER") then
            texture = [[Interface\AddOns\Textures\ClassRoles\healer]]
        elseif (role == "TANK") then
            texture = [[Interface\AddOns\Textures\ClassRoles\tank]]
        elseif (role == "DAMAGER") then
            texture = [[Interface\AddOns\Textures\ClassRoles\damager]]
        end

        if (uf.RoleFrame and uf.RoleFrame.RoleIcon) then
            uf.RoleFrame:Show()
            uf.RoleFrame.RoleIcon:SetTexture(texture)
        else
            local roleFrame = CreateFrame("frame", nil, uf)
            roleFrame:SetFrameLevel (uf:GetFrameLevel() + 5)
            roleFrame:SetPoint ('topleft', uf, 'topleft', 0, 0)
            uf.RoleFrame = roleFrame
            
            local roleIcon = Plater:CreateImage (roleFrame, texture, 20, 20)
            roleFrame.RoleIcon = roleIcon

            uf.RoleFrame:Show()
        end

        local roleIcon = uf.RoleFrame.RoleIcon
        roleIcon:ClearAllPoints()

        if (uf.healthBar:IsVisible()) then
            roleIcon:SetPoint ('right', uf.healthBar, 'left', -28, 0)
        else
            roleIcon:SetPoint ('right', uf.ActorNameSpecial, 'left', -28, 0)
        end
    end
        
end

-- NAMEPLATE ADDED and TARGET CHANGED
function (self, unitId, unitFrame, envTable)

    local oldRole = _G.KnownPlayerSpecs[unitFrame.namePlateUnitGUID]
    if (oldRole and not UnitIsUnit(unitFrame.unit, "target")) then -- if cached and not targeting, we want to override for target in case the spec has changed
        envTable.AddRoleIcon (envTable, unitFrame, oldRole) 
    else
        envTable.CreateRoleIcon (unitFrame)
    end
    
end
    
-- NAMEPLATE REMOVED and DESTRUCTOR
function (self, unitId, unitFrame, envTable)
    
    if (unitFrame.RoleFrame) then
        unitFrame.RoleFrame:Hide()
    end
    
end