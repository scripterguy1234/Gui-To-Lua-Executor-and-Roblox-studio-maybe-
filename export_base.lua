local Exporter = {}

local used = {}

local function indent(n)
    return string.rep("    ", n)
end

local function unique(name)
    local base = name:gsub("%W","")
    local i = 1
    local new = base.."_"..i

    while used[new] do
        i += 1
        new = base.."_"..i
    end

    used[new] = true
    return new
end

local function format(v)
    local t = typeof(v)

    if t == "string" then
        return string.format("%q", v:gsub("\n","\\n"))
    elseif t == "number" or t == "boolean" then
        return tostring(v)
    elseif t == "UDim2" then
        return string.format("UDim2.new(%s,%s,%s,%s)", v.X.Scale, v.X.Offset, v.Y.Scale, v.Y.Offset)
    elseif t == "UDim" then
        return string.format("UDim.new(%s,%s)", v.Scale, v.Offset)
    elseif t == "Color3" then
        return string.format("Color3.fromRGB(%d,%d,%d)", v.R*255, v.G*255, v.B*255)
    elseif t == "Vector2" then
        return string.format("Vector2.new(%s,%s)", v.X, v.Y)
    elseif t == "EnumItem" then
        return tostring(v)
    end

    return nil
end

-- UI children suportados
local uiChildren = {
    UICorner = true,
    UIStroke = true,
    UIGradient = true,
    UIPadding = true,
    UIListLayout = true,
    UIGridLayout = true,
    UIAspectRatioConstraint = true,
    UISizeConstraint = true,
    UITextSizeConstraint = true
}

-- propriedades genéricas (fallback simples)
local function getProps(obj)
    local props = {}

    local list = {
        "Size","Position","AnchorPoint","Rotation",
        "BackgroundColor3","BackgroundTransparency",
        "BorderSizePixel","Visible","ZIndex","ClipsDescendants",
        "Text","TextColor3","TextSize","TextScaled","Font",
        "Image","ImageColor3","ImageTransparency"
    }

    for _,p in ipairs(list) do
        local ok, v = pcall(function()
            return obj[p]
        end)

        if ok and v ~= nil then
            props[p] = v
        end
    end

    return props
end

local function convert(obj, lvl, parentVar)
    local var = unique(obj.ClassName)
    local code = ""

    code ..= indent(lvl).."local "..var.." = Instance.new(\""..obj.ClassName.."\")\n"
    code ..= indent(lvl)..var..".Name = "..string.format("%q", obj.Name).."\n"

    -- propriedades
    local props = getProps(obj)
    for prop, val in pairs(props) do
        local f = format(val)
        if f then
            code ..= indent(lvl)..var.."."..prop.." = "..f.."\n"
        end
    end

    -- parent
    if parentVar then
        code ..= indent(lvl)..var..".Parent = "..parentVar.."\n"
    end

    -- filhos
    for _,child in ipairs(obj:GetChildren()) do
        code ..= convert(child, lvl+1, var)
    end

    return code
end

-- API PRINCIPAL
function Exporter:Export(gui)
    used = {}

    local output = [[
local ExportedGUI = Instance.new("ScreenGui")
ExportedGUI.Name = "ExportedGUI"
ExportedGUI.Parent = game.Players.LocalPlayer.PlayerGui

]]

    for _,v in ipairs(gui:GetChildren()) do
        output ..= convert(v, 0, "ExportedGUI")
    end

    return output
end

return Exporter

-- use the function Exporter:Export(nameofscreengui)
