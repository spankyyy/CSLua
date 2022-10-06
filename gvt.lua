require("gmdenoiser")
hook.Call("VisTraceInit")

local me = LocalPlayer()
local settings = {
	on = false,
	resx = 1920,
	resy = 1080,
	focalLength = 20,
	focalDistance = 0,
	sensorHeight = 35,
	samples = 8,
	maxDepth = 16,
	exposure = 1,
	denoise = true,
}
local drawAlbedoTab, drawNormalTab = true, true
local hToM_sqr = 0.0254^2
--[[
local function calcFovVector(fov)
	return Vector(0.5 / math.tan(math.rad(fov * 0.5)), 0, 0)
end

local function getDirection(x, y, fov, resx, resy, angles, fovVector)
	local aspect = resx / resy
	local dir = ((Vector(0, (0.5 - (x / resx)) * aspect, 0.5 - (y / resy))) + fovVector)
	dir:Rotate(angles)
	return dir:GetNormalized()
end
]]

local rt = GetRenderTargetEx(
	"VisTracer",                     -- Name of the render target
	1, 1, RT_SIZE_FULL_FRAME_BUFFER, -- Resize to screen res automatically
	MATERIAL_RT_DEPTH_SEPARATE,      -- Create a dedicated depth/stencil buffer
	bit.bor(1, 256),                 -- Texture flags for point sampling and no mips
	0,                               -- No RT flags
	IMAGE_FORMAT_RGBA8888            -- RGB image format with 8 bits per channel
)
local rtAlbedo = GetRenderTargetEx(
	"VisTracerAlbedo",                     -- Name of the render target
	1, 1, RT_SIZE_FULL_FRAME_BUFFER, -- Resize to screen res automatically
	MATERIAL_RT_DEPTH_SEPARATE,      -- Create a dedicated depth/stencil buffer
	bit.bor(1, 256),                 -- Texture flags for point sampling and no mips
	0,                               -- No RT flags
	IMAGE_FORMAT_RGBA8888            -- RGB image format with 8 bits per channel
)
local rtNormal = GetRenderTargetEx(
	"VisTracerNormal",                     -- Name of the render target
	1, 1, RT_SIZE_FULL_FRAME_BUFFER, -- Resize to screen res automatically
	MATERIAL_RT_DEPTH_SEPARATE,      -- Create a dedicated depth/stencil buffer
	bit.bor(1, 256),                 -- Texture flags for point sampling and no mips
	0,                               -- No RT flags
	IMAGE_FORMAT_RGBA8888            -- RGB image format with 8 bits per channel
)
local rtDepth = GetRenderTargetEx(
	"VisTracerDepth",                     -- Name of the render target
	1, 1, RT_SIZE_FULL_FRAME_BUFFER, -- Resize to screen res automatically
	MATERIAL_RT_DEPTH_SEPARATE,      -- Create a dedicated depth/stencil buffer
	bit.bor(1, 256),                 -- Texture flags for point sampling and no mips
	0,                               -- No RT flags
	IMAGE_FORMAT_RGBA8888            -- RGB image format with 8 bits per channel
)

local rtMat = CreateMaterial("VisTracer", "UnlitGeneric", {
	["$basetexture"] = rt:GetName(),
	["$translucent"] = "1" -- Enables transparency on the material
})
local rtMatAlbedo = CreateMaterial("VisTracerAlbedo", "UnlitGeneric", {
	["$basetexture"] = rtAlbedo:GetName(),
	["$translucent"] = "1" -- Enables transparency on the material
})
local rtMatNormal = CreateMaterial("VisTracerNormal", "UnlitGeneric", {
	["$basetexture"] = rtNormal:GetName(),
	["$translucent"] = "1" -- Enables transparency on the material
})
local rtMatDepth = CreateMaterial("VisTracerDepth", "UnlitGeneric", {
	["$basetexture"] = rtDepth:GetName(),
	["$translucent"] = "1" -- Enables transparency on the material
})

local startTime = os.clock()
local y = 0
local clear = true
local setup = false
function start(button)
	y = 0
	settings.on = true
	setup = true
	button:SetDisabled(true)
	startTime = os.clock()
end

local mainPanel = vgui.Create("DFrame")
mainPanel:MakePopup()
mainPanel:SetKeyBoardInputEnabled(false)
mainPanel:SetScreenLock(true)
mainPanel:SetTitle("gVistracer")
mainPanel:SetSize(512 + 26, 512 + 92 + 24)
mainPanel:Center()

local saveButton = mainPanel:Add("DButton")
saveButton:SetText("Save!")
saveButton:SetDoubleClickingEnabled(false)
saveButton:Dock(BOTTOM)
saveButton:SetDisabled(true)

local renderButton = mainPanel:Add("DButton")
renderButton:SetText("Render!")
renderButton:SetDoubleClickingEnabled(false)
renderButton:Dock(BOTTOM)

local tabs = mainPanel:Add("DPropertySheet")
tabs:Dock(FILL)
local offsetx, offsety = 256 / settings.resx, 256 / settings.resy
local outputTab = vgui.Create("DPanel")
function outputTab:Paint(w, h)
	surface.SetDrawColor(Color(0, 0, 0))
	surface.DrawRect(0, 0, w, h)

	surface.SetDrawColor(Color(255, 255, 255))
	surface.SetMaterial(rtMat)
	surface.DrawTexturedRect(-offsetx, -offsety, (1920 / settings.resx) * w, (1080 / settings.resy) * h)
end

local albedoTab = vgui.Create("DPanel")
function albedoTab:Paint(w, h)
	surface.SetDrawColor(Color(0, 0, 0))
	surface.DrawRect(0, 0, w, h)

	surface.SetDrawColor(Color(255, 255, 255))
	surface.SetMaterial(rtMatAlbedo)
	surface.DrawTexturedRect(-offsetx, -offsety, (1920 / settings.resx) * w, (1080 / settings.resy) * h)
end

local normalTab = vgui.Create("DPanel")
function normalTab:Paint(w, h)
	surface.SetDrawColor(Color(0, 0, 0))
	surface.DrawRect(0, 0, w, h)

	surface.SetDrawColor(Color(255, 255, 255))
	surface.SetMaterial(rtMatNormal)
	surface.DrawTexturedRect(-offsetx, -offsety, (1920 / settings.resx) * w, (1080 / settings.resy) * h)
end

local depthTab = vgui.Create("DPanel")
function depthTab:Paint(w, h)
	surface.SetDrawColor(Color(0, 0, 0))
	surface.DrawRect(0, 0, w, h)

	surface.SetDrawColor(Color(255, 255, 255))
	surface.SetMaterial(rtMatDepth)
	surface.DrawTexturedRect(-offsetx, -offsety, (1920 / settings.resx) * w, (1080 / settings.resy) * h)
end

local settingTab = vgui.Create("DPanel")



tabs:AddSheet("Output", outputTab, "icon16/camera.png", false, false, "tab1")
tabs:AddSheet("Albedo", albedoTab, "icon16/color_wheel.png", false, false, "tab2")
tabs:AddSheet("Normal", normalTab, "icon16/bricks.png", false, false, "tab3")
tabs:AddSheet("Depth", depthTab, "icon16/contrast_low.png", false, false, "tab4")
tabs:AddSheet("Render Settings - UNUSED", settingTab, "icon16/cog_edit.png", false, false, "tab5")
local entities = {}
for k,v in pairs(ents.GetAll()) do
	local class = v:GetClass()
	if v == me or not v:IsValid() or v:EntIndex() < 1 or v:GetBoneCount() < 1 then continue end

	local theMesh = util.GetModelMeshes(v:GetModel())
	if not theMesh then continue end

	local material = v:GetMaterials()
	if
		v:IsWeapon() or 
		string.find(material[1], "pac", 1, false) or 
		string.find(class, "viewmode", 1, false) or 
		string.find(class, "hand", 1, false)
	then continue end

	entities[#entities+1] = v
end
PrintTable(entities)

local analyticalLights = {}
-- point lights
local pl = {}

-- spotlights
local sl = {}
local sl_fov = 90
local sl_fade = 4

--square area light
local s_al = {}
local s_al_size = 64
local s_al_doublesided = true

local temp = {}
for k, v in pairs(entities) do
	if v:IsValid() and v:GetMaterial() == "lights/white" and v:GetModel() == "models/hunter/misc/sphere025x025.mdl" then
		-- point lights
		pl[#pl+1] = v
	elseif v:IsValid() and v:GetMaterial() == "lights/white" and v:GetModel() == "models/maxofs2d/lamp_flashlight.mdl" then
		-- spotlights
		sl[#sl+1] = v
	elseif v:IsValid() and v:GetMaterial() == "lights/white" and v:GetModel() == "models/hunter/plates/plate025x025.mdl" then
		-- square arealights
		s_al[#s_al+1] = v
	else
		temp[#temp+1] = v
	end
end

--entities = temp
local plLength = #pl
local slLength = #sl
local s_alLength = #s_al

local accel = vistrace.CreateAccel(entities, true)
local hdri = vistrace.LoadHDRI("flower_road_4k")
local sampler = vistrace.CreateSampler()

local hdr = vistrace.CreateRenderTarget(settings.resx, settings.resy, VisTraceRTFormat.RGBFFF)
local srgb = vistrace.CreateRenderTarget(settings.resx, settings.resy, VisTraceRTFormat.RGB888)
local albedo = vistrace.CreateRenderTarget(settings.resx, settings.resy, VisTraceRTFormat.Albedo)
local normal = vistrace.CreateRenderTarget(settings.resx, settings.resy, VisTraceRTFormat.Normal)
local depth = vistrace.CreateRenderTarget(settings.resx, settings.resy, VisTraceRTFormat.RF)


local DEFAULT_MATERIAL = vistrace.CreateMaterial()
DEFAULT_MATERIAL:Roughness(0.8)
DEFAULT_MATERIAL:IoR(1.2)


local WATER_MATERIAL = vistrace.CreateMaterial()
WATER_MATERIAL:IoR(1.33)
WATER_MATERIAL:Metalness(0)
WATER_MATERIAL:SpecularTransmission(1)
WATER_MATERIAL:Roughness(0)
WATER_MATERIAL:Colour(Vector(1, 1, 1))
WATER_MATERIAL:Thin(true)

local function RGBToHSV(rgb)
    local cMax = math.max(rgb[1], rgb[2], rgb[3])
    local cMin = math.min(rgb[1], rgb[2], rgb[3])
    local delta = cMax - cMin

    local hsv = Vector(0, 0, 0)

    if delta > 0 then
        if cMax == rgb[1] then
            hsv[1] = 60 * (((rgb[2] - rgb[3]) / delta) % 6)
        elseif cMax == rgb[2] then
            hsv[1] = 60 * (((rgb[3] - rgb[1]) / delta) + 2)
        elseif cMax == rgb[3] then
            hsv[1] = 60 * (((rgb[1] - rgb[2]) / delta) + 4)
        end

        if cMax > 0 then
            hsv[2] = delta / cMax
        else
            hsv[2] = 0
        end

        hsv[3] = cMax
    else
        hsv[1] = 0
        hsv[2] = 0
        hsv[3] = cMax
    end

    if hsv[1] < 0 then
        hsv[1] = 360 + hsv[1]
    end

    return hsv
end

local function HSVtoRGB(hsv)
    local c = hsv[3] * hsv[2]
    local fHPrime = (hsv[1] / 60) % 6
    local x = c * (1 - math.abs((fHPrime % 2) - 1))
    local m = hsv[3] - c

    local rgb = Vector(0, 0, 0)

    if 0 <= fHPrime and fHPrime < 1 then
        rgb[1] = c
        rgb[2] = x
        rgb[3] = 0
    elseif 1 <= fHPrime and fHPrime < 2 then
        rgb[1] = x
        rgb[2] = c
        rgb[3] = 0
    elseif 2 <= fHPrime and fHPrime < 3 then
        rgb[1] = 0
        rgb[2] = c
        rgb[3] = x
    elseif 3 <= fHPrime and fHPrime < 4 then
        rgb[1] = 0
        rgb[2] = x
        rgb[3] = c
    elseif 4 <= fHPrime and fHPrime < 5 then
        rgb[1] = x
        rgb[2] = 0
        rgb[3] = c
    elseif 5 <= fHPrime and fHPrime < 6 then
        rgb[1] = c
        rgb[2] = 0
        rgb[3] = x
    else
        rgb[1] = 0
        rgb[2] = 0
        rgb[3] = 0
    end

    rgb[1] = rgb[1] + m
    rgb[2] = rgb[2] + m
    rgb[3] = rgb[3] + m

    return rgb
end

local function vibrance(color, vib)
	local average = (color[1] + color[2] + color[3]) / 3
	local mx = math.max(color[1], math.max(color[2], color[3]))
	local amt = (mx - average) * (-vib * 3)
	local color = LerpVector(amt, color, Vector(mx, mx, mx))
	return color
end

local function luminance(v)
	return v:Dot(Vector(0.2126, 0.7152, 0.0722))
end

local function spotFade(liDir, forward)
	local dot = forward:Dot(-liDir)
	local sl_fov = math.cos(math.rad(sl_fov))
	if sl_fade > 0 then
		return math.Clamp((dot / sl_fade) - (sl_fov / sl_fade), 0, 1)
	end
	return (dot > sl_fov) and 1 or 0
end

local function Power2Heuristic(p0, p1)
	local p02 = p0 * p0
	return p02 / (p02 + p1 * p1)
end

local function MultiplyRT(rt, multiplier)
	if not rt then return end
	if not multiplier then return end

	for y = 0, rt:GetHeight() - 1 do
		for x = 0, rt:GetWidth() - 1 do
			local unMultiplied = rt:GetPixel(x, y)
			local multiplied = unMultiplied * multiplier
			rt:SetPixel(x, y, multiplied)
		end
	end
end
local function SaturateRT(rt, sat)
	if not rt then return end
	if not sat then return end

	for y = 0, rt:GetHeight() - 1 do
		for x = 0, rt:GetWidth() - 1 do
			local pixel = rt:GetPixel(x, y)
			pixel = vibrance(pixel, sat * 0.5)
			local output = RGBToHSV(pixel)
			output[2] = output[2] + sat * 0.05
			rt:SetPixel(x, y, HSVtoRGB(output))
		end
	end
end
local function GetRTLuminanceMean(rt, offsetx, offsety)
	if not rt then return 0 end
	if not offsetx then return 0 end
	if not offsety then return 0 end

	local luMean = 0
	local x_, y_, w, h = offsetx, offsety, rt:GetHeight() - (offsetx * 2), rt:GetWidth() - (offsety * 2)

	for y = y_, w - 1 do
		for x = x_, h - 1 do
			local rgb = rt:GetPixel(x, y)
			luMean = luMean + luminance(rgb)
		end
	end
	return luMean / (w * h)
end
local function filmGrainRT(rt, strength)
	if not rt then return end
	if not strength then return end

	for y = 0, rt:GetHeight() - 1 do
		for x = 0, rt:GetWidth() - 1 do
			local pre = rt:GetPixel(x, y)
			local post = pre + Vector(math.Rand(0, strength), math.Rand(0, strength), math.Rand(0, strength))
			rt:SetPixel(x, y, post)
		end
	end
end
local function blurKernel(rt, x, y, size)
	local size = math.Round(size)
	if size == 0 then return rt:GetPixel(x, y) end
	local averaged, i = Vector(0, 0, 0), 0
	local sx, sy = rt:GetWidth(), rt:GetHeight()
	for ky=-size, size do
		for kx=-size, size do
			local ox, oy = x - kx, y - ky
			if ox >= 0 and ox < sx and oy >= 0 and oy < sy then
				local distanceSquaredToCenter = math.DistanceSqr(x, y, ox, oy)
				if distanceSquaredToCenter <= size ^ 2 then
					averaged = averaged + rt:GetPixel(ox, oy)
					i = i + 1
				end
			end
		end
	end
	return averaged / i
end
local function blurDof(rt, rtDepth, strength, focalDistance)
	local sx, sy = rt:GetWidth(), rt:GetHeight()
	for y = 0, sy - 1 do
		for x = 0, sx - 1 do
			local size = math.abs(rtDepth:GetPixel(x, y)[1] - focalDistance) * strength
			local size = math.Clamp(size, 0, 8)
			rt:SetPixel(x, y, blurKernel(rt, x, y, size))
		end
	end
end

function saveButton:DoClick()
	local timestamp = math.Round(CurTime())
	srgb:Save("render" .. timestamp .. ".png")
end
function renderButton:DoClick()
	saveButton:SetDisabled(true)
	start(self)
end


local camScaleVertical = 0.5 * settings.sensorHeight / settings.focalLength
local camScaleHorizontal = settings.resx / settings.resy * camScaleVertical
local coneAngle = math.atan(2 * camScaleVertical / settings.resy) * 0.5

local function getCamDir(x, y, vertical, horizontal, angles)
	local camX = (1 - 2 * (x + 0.5) / settings.resx) * camScaleHorizontal
	local camY = (1 - 2 * (y + 0.5) / settings.resy) * camScaleVertical
	local camDir = Vector(1, camX, camY)
	camDir:Rotate(angles)
	camDir:Normalize()
	return camDir
end

local skycam = Vector(0, 0, 5112)
local bigcitySkyboxWorldSize = Vector(1655.94, 1655.94, 1519.94) * 0.5

local function WorldToSkyboxOrigin(origin)
	return skycam + (origin * 0.0625)
end
local function SkyboxToWorldOrigin(origin)
	return (origin - skycam) * 16
end

local accelMeta = debug.getmetatable(accel)
accelMeta._Traverse = accelMeta._Traverse or accelMeta.Traverse
local shouldTraverseSkybox = game.GetMap() ~= "gm_bigcity"
function accelMeta:Traverse(origin, direction, tMin, tMax, coneWidth, coneAngle)
	local trace = self:_Traverse(origin, direction, tMin, tMax, coneWidth, coneAngle)
	if trace and trace:Entity():IsValid() and trace:Alpha() < 0.5 and trace:MaterialFlags() ~= 0 then
		trace = self:Traverse(trace:Pos() + direction, direction, tMin, tMax, coneWidth, coneAngle)
	end

	if shouldTraverseSkybox then return trace end
	if trace then
		local skyboxToWorldIntersect = util.IntersectRayWithOBB(origin + direction * (tMin or 0), origin + direction * (tMax or 99999), skycam, Angle(), -bigcitySkyboxWorldSize, bigcitySkyboxWorldSize)
		if skyboxToWorldIntersect and skyboxToWorldIntersect:DistToSqr(origin) < trace:Pos():DistToSqr(origin) and trace:Pos()[3] > 3500 then
			--print("goes into world")
			local origin = SkyboxToWorldOrigin(origin)
			trace = self:_Traverse(origin, direction, tMin, tMax, coneWidth, coneAngle)
			if trace and trace:HitSky() and trace:Pos()[3] < 3500 then
				local origin = WorldToSkyboxOrigin(origin)
				trace = self:_Traverse(origin, direction, tMin, tMax, coneWidth, coneAngle)
				return trace
			end
		elseif trace:HitSky() and trace:Pos()[3] < 3500 then
			--print("goes into skybox")
			local origin = WorldToSkyboxOrigin(origin)
			trace = self:_Traverse(origin, direction, tMin, tMax, coneWidth, coneAngle)
			return trace
		end
	end
	return trace
end



local function tracePixel(camPos, camDir)
	local camRay = accel:Traverse(camPos, camDir, nil, nil, 0, coneAngle)
	if camRay and camRay:Entity():IsValid() and camRay:Entity():GetMaterial() == "lights/white" then
		return camRay:Entity():GetColor():ToVector() * 10
	end
	if camRay and not camRay:HitSky() then
		local color = Vector()
		local rayDir = camDir

		local validSamples = settings.samples
		for sample = 1, settings.samples do
			local result = camRay
			local throughput = Vector(1, 1, 1)
			
			for depth = 1, settings.maxDepth do
				local mat = result:Entity():IsValid() and result:Entity():GetBSDFMaterial() or vistrace.CreateMaterial()

				local invert = 1
				if result:HitWater() then
					mat = WATER_MATERIAL

					if result:GeometricNormal():Dot(Vector(0, 0, -1)) > 0 then
						invert = -1
						print("must invert")
					end
				end
				local sample
				if result:HitWater() then
					sample = vistrace.SampleBSDF(sampler, mat, result:Normal() * invert, result:Tangent(), result:Binormal(), -rayDir)
				else
					sample = result:SampleBSDF(sampler, mat)
				end
				if not sample then
					if depth == 1 then validSamples = validSamples - 1 end
					break
				end
				rayDir = sample.scattered

				local delta = bit.band(LobeType.Delta, sample.lobe) ~= 0
				local viewside = bit.band(LobeType.Transmission, sample.lobe) == 0
				local origin = vistrace.CalcRayOrigin(
					result:Pos(),
					(result:FrontFacing() == viewside) and result:GeometricNormal() or -result:GeometricNormal()
				)

				if not delta then
					local envValid, envDir, envCol, envPdf = hdri:Sample(sampler)
					if envValid then
						local shadowRay = accel:Traverse(origin, envDir)
						if not shadowRay or shadowRay:HitSky() then
							local misWeight = Power2Heuristic(envPdf, result:EvalPDF(mat, envDir))
							local bsdf = result:EvalBSDF(mat, envDir)
							color = color + throughput * bsdf * envCol / envPdf * misWeight
						end
					end
					//analytical lights

					-- point
					if plLength > 0 then
						local light = pl[math.random(1, plLength)]

						local liDirSqr = light:GetPos() - origin
						local liDistSqr = liDirSqr:LengthSqr()
						local liDist = math.sqrt(liDistSqr)

						local liDir = liDirSqr / liDist

						local liDistSqr = liDistSqr * hToM_sqr

						local shadowRay = accel:Traverse(origin, liDir, 0, liDist)
						if not shadowRay or shadowRay:Entity() == light then
							local liColor = light:GetColor():ToVector() * 10000
							local bsdf = result:EvalBSDF(mat, liDir)
							color = color + throughput * liColor * bsdf * plLength / (4 * math.pi * liDistSqr)
						end
					end

					-- spot
					if slLength > 0 then
						local light = sl[math.random(1, slLength)]

						local liDirSqr = light:GetPos() - origin
						local liDistSqr = liDirSqr:LengthSqr()
						local liDist = math.sqrt(liDistSqr)

						local liDir = liDirSqr / liDist

						local liDistSqr = liDistSqr * hToM_sqr

						local shadowRay = accel:Traverse(origin, liDir, 0.1, liDist)
						if not shadowRay or shadowRay:Entity() == light then
							local liColor = light:GetColor():ToVector() * 10000
							local bsdf = result:EvalBSDF(mat, liDir)
							local fade = spotFade(liDir, light:GetForward())
							color = color + throughput * liColor * bsdf * fade * slLength / (4 * math.pi * liDistSqr)
						end
					end

					-- square area light
					if s_alLength > 0 then
						local light = s_al[math.random(1, s_alLength)]
						local sampledPos = Vector(math.random() - 0.5, math.random() - 0.5, 0) * s_al_size

						local liDirSqr = light:LocalToWorld(sampledPos) - origin
						local liDistSqr = liDirSqr:LengthSqr()
						local liDist = math.sqrt(liDistSqr)

						local liDir = liDirSqr / liDist

						local liDistSqr = liDistSqr * hToM_sqr

						local shadowRay = accel:Traverse(origin, liDir, 0, liDist)
						if not shadowRay or shadowRay:Entity() == light then
							local liColor = light:GetColor():ToVector() * 0.1
							local bsdf = result:EvalBSDF(mat, liDir)
							
							local costheta = math.max(light:GetUp():Dot(-liDir), s_al_doublesided and -1 or 0)
							local surfaceArea = s_al_size * s_al_size

							color = color + throughput * s_alLength * bsdf * liColor / (liDistSqr / (math.abs(costheta) * surfaceArea))
						end
					end
				end

				throughput = throughput * sample.weight

				local rrProb = math.max(throughput[1], throughput[2], throughput[3])
				if sampler:GetFloat() >= rrProb then break end
				throughput = throughput / rrProb

				result = accel:Traverse(origin, sample.scattered, nil, nil, nil, nil)
				if not result or result:HitSky() then
					local misWeight = delta and 1 or Power2Heuristic(sample.pdf, hdri:EvalPDF(sample.scattered))
					color = color + throughput * hdri:GetPixel(sample.scattered) * misWeight
					break
				end
			end
		end

		return color / validSamples
	else
		return hdri:GetPixel(camDir)
	end
end

local wasOn = false
local postprocess = false
hook.Add("HUDPaint", "VisTracer", function()
	if not mainPanel:IsValid() then 
		print(tracePixel)
		rt, rtAlbedo, rtNormal, hdri = nil, nil, nil, nil
		settings.on = false
		hook.Remove("HUDPaint", "VisTracer")
	end
	if y < settings.resy then
		if setup or clear then
			render.PushRenderTarget(rt)
				render.Clear(0, 0, 0, 0, true, true)
			render.PopRenderTarget()

			render.PushRenderTarget(rtAlbedo)
				render.Clear(0, 0, 0, 0, true, true)
			render.PopRenderTarget()

			render.PushRenderTarget(rtNormal)
				render.Clear(0, 0, 0, 0, true, true)
			render.PopRenderTarget()
			setup = false
			clear = false
		end
		if settings.on then
			for x = 0, settings.resx - 1 do
				local rgb
				if postprocess then
					rgb = hdr:GetPixel(x, y)
	
					-- Perform custom per-pixel post processing
					local gamma = 1 / 1.5
					for i = 1, 3 do
						rgb[i] = math.pow(rgb[i], gamma)
					end

					srgb:SetPixel(x, y, rgb)
				else
					local rayDir = getCamDir(x, y, camScaleVertical, camScaleHorizontal, me:EyeAngles())
					local camRay = accel:Traverse(me:EyePos(), rayDir, nil, nil, 0, coneAngle)
					
					rgb = tracePixel(me:EyePos(), rayDir)
					if not rgb then rgb = Vector(0, 0, 0) end
					local rgb = (rgb[1] == rgb[1]) and rgb or Vector(0)
					hdr:SetPixel(x, y, rgb)

					if camRay and not camRay:HitSky() then
						albedo:SetPixel(x, y, camRay:Albedo())
						normal:SetPixel(x, y, camRay:Normal())
						depth:SetPixel(x, y, Vector(camRay:Distance(), 0, 0))
						if drawAlbedoTab then
							render.PushRenderTarget(rtAlbedo)
								local albedo = camRay:Albedo() or Vector(1, 0, 1)
								render.SetViewPort(x + 1, y + 1, 1, 1)
								render.Clear(
									math.Clamp(albedo[1] * 255, 0, 255), 
									math.Clamp(albedo[2] * 255, 0, 255), 
									math.Clamp(albedo[3] * 255, 0, 255), 
									255, true, true
								)
							render.PopRenderTarget()
						end
						if drawNormalTab then
							render.PushRenderTarget(rtNormal)
								local normal = (camRay:Normal() + Vector(1, 1, 1)) * 0.5
								render.SetViewPort(x + 1, y + 1, 1, 1)
								render.Clear(
									math.Clamp(normal[1] * 255, 0, 255), 
									math.Clamp(normal[2] * 255, 0, 255), 
									math.Clamp(normal[3] * 255, 0, 255), 
									255, true, true
								)
							render.PopRenderTarget()
						end
						if drawNormalTab then
							render.PushRenderTarget(rtDepth)
								local dist = camRay:Distance()

								local dist = math.abs(dist - settings.focalDistance)
								local depth = 1 - (1 / (1 + (dist * 0.001)))
								render.SetViewPort(x + 1, y + 1, 1, 1)
								render.Clear(
									math.Clamp(depth * 255, 0, 255), 
									math.Clamp(depth * 255, 0, 255), 
									math.Clamp(depth * 255, 0, 255), 
									255, true, true
								)
							render.PopRenderTarget()
						end
					else
						depth:SetPixel(x, y, Vector(2048, 0, 0))
						if drawNormalTab then
							render.PushRenderTarget(rtDepth)
								local dist = 2048

								local dist = math.abs(dist - settings.focalDistance)
								local depth = 1 - (1 / (1 + (dist * 0.05)))
								render.SetViewPort(x + 1, y + 1, 1, 1)
								render.Clear(
									math.Clamp(depth * 255, 0, 255), 
									math.Clamp(depth * 255, 0, 255), 
									math.Clamp(depth * 255, 0, 255), 
									255, true, true
								)
							render.PopRenderTarget()
						end
					end
				end
				render.PushRenderTarget(rt)
					render.SetViewPort(x + 1, y + 1, 1, 1)
					render.Clear(
						math.Clamp(rgb[1] * 255, 0, 255), 
						math.Clamp(rgb[2] * 255, 0, 255), 
						math.Clamp(rgb[3] * 255, 0, 255), 
						255, true, true
					)
				render.PopRenderTarget()
			end
			
			y = y + 1
		end
		if y >= settings.resy then
			if postprocess then
			else
				y = 0
				postprocess = true

				-- Pre HDR
				local lumMean = GetRTLuminanceMean(hdr, 0, 0)
				local lumMult = math.Clamp(0.75 / lumMean, 0, 32)
				MultiplyRT(hdr, 1)

				-- During HDR
				hdr:Tonemap(false, settings.exposure)
				if settings.denoise then hdr:Denoise({
					Albedo = albedo,
					Normal = normal,
					AlbedoNoisy = false,
					NormalNoisy = false,
					HDR = false,
					sRGB = true
				}) end

				-- Post HDR
				--blurDof(hdr, depth, 0.001, settings.focalDistance)
				--SaturateRT(hdr, 0.5)
				filmGrainRT(hdr, 0.005 * lumMult)

			end
		end
	else
		settings.on = false
		postprocess = false
	end
	if not settings.on and settings.on ~= wasOn then
		postprocess = true
		print("done")
		print("took " .. math.Round(os.clock() - startTime, 3) .. " seconds")
		surface.PlaySound("buttons/button15.wav")
		if renderButton:IsValid() then
			renderButton:SetDisabled(false)
		end
		if saveButton:IsValid() then
			saveButton:SetDisabled(false)
		end
	end

	wasOn = settings.on
end)
