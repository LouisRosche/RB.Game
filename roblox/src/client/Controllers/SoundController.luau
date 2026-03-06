--[[
	SoundController.luau
	Client-side audio management for Potion Lab.

	Research finding: strong audio design yields ~30% retention improvement.
	All sounds are played locally (client authoritative for audio).

	SOUND IDs:
	  Replace placeholder IDs below with actual Roblox asset IDs once audio
	  assets are uploaded. Current values are Roblox free audio from the
	  Audio Marketplace — swap with game-specific audio once available.

	  To upload audio: Creator Hub → Create → Audio → Upload

	ARCHITECTURE:
	  - One looping ambient/music track plays continuously at low volume
	  - Short SFX play on game events (plant, harvest, brew, sell, discover)
	  - All sounds are pooled via a single SoundGroup for easy mute/volume control
	  - Volume levels are tuned conservatively (players can disable in Roblox settings)
]]

local SoundService = game:GetService("SoundService")

local SoundController = {}

---------------------------------------------------------------------------
-- Sound asset IDs
-- Replace these with real uploaded audio asset IDs before launch.
-- Format: "rbxassetid://XXXXXXXXX"
---------------------------------------------------------------------------
local SFX_IDS = {
	-- Ambient / background music (loop)
	Music          = "rbxassetid://1843673566",  -- gentle ambient loop placeholder

	-- Gameplay SFX
	PlantSeed      = "rbxassetid://9125416728",  -- soft soil drop
	Harvest        = "rbxassetid://9125416728",  -- plant pop / collect sound
	BrewStart      = "rbxassetid://9119713951",  -- cauldron bubble
	BrewComplete   = "rbxassetid://9119713951",  -- potion chime
	Sell           = "rbxassetid://9119713951",  -- coin clink
	Upgrade        = "rbxassetid://9119713951",  -- level-up chime
	Discovery      = "rbxassetid://9119713951",  -- discovery fanfare
	Notification   = "rbxassetid://9119713951",  -- soft notification ping

	-- Rarity reveal stings (play on harvest result)
	RarityCommon   = "rbxassetid://9119713951",
	RarityUncommon = "rbxassetid://9119713951",
	RarityRare     = "rbxassetid://9119713951",
	RarityEpic     = "rbxassetid://9119713951",
	RarityLegendary = "rbxassetid://9119713951", -- triumphant fanfare
}

local RARITY_SFX = {
	Common    = SFX_IDS.RarityCommon,
	Uncommon  = SFX_IDS.RarityUncommon,
	Rare      = SFX_IDS.RarityRare,
	Epic      = SFX_IDS.RarityEpic,
	Legendary = SFX_IDS.RarityLegendary,
}

---------------------------------------------------------------------------
-- Volume settings
---------------------------------------------------------------------------
local MUSIC_VOLUME = 0.18   -- subtle; never compete with SFX
local SFX_VOLUME   = 0.55

---------------------------------------------------------------------------
-- Internal state
---------------------------------------------------------------------------
local soundGroup: SoundGroup = nil
local musicSound: Sound = nil
local sfxPool: { [string]: Sound } = {}

---------------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------------

local function createSoundGroup(): SoundGroup
	local sg = Instance.new("SoundGroup")
	sg.Name = "PotionLabSounds"
	sg.Volume = 1
	sg.Parent = SoundService
	return sg
end

local function createSound(name: string, assetId: string, volume: number, looped: boolean): Sound
	local s = Instance.new("Sound")
	s.Name = name
	s.SoundId = assetId
	s.Volume = volume
	s.Looped = looped
	s.RollOffMaxDistance = 200
	s.Parent = soundGroup
	return s
end

--- Play a non-looping SFX by key. Safe to call even if sound doesn't exist.
local function playSFX(key: string)
	local sound = sfxPool[key]
	if sound then
		sound:Play()
	end
end

---------------------------------------------------------------------------
-- Public API
---------------------------------------------------------------------------

function SoundController.init()
	soundGroup = createSoundGroup()

	-- Background music (loops)
	musicSound = createSound("Music", SFX_IDS.Music, MUSIC_VOLUME, true)
	musicSound:Play()

	-- Build SFX pool (one Sound instance per effect, reused)
	for key, assetId in SFX_IDS do
		if key ~= "Music" then
			sfxPool[key] = createSound(key, assetId, SFX_VOLUME, false)
		end
	end
end

--- Play the seed-planting sound.
function SoundController.onPlant()
	playSFX("PlantSeed")
end

--- Play the harvest sound, with a rarity-specific sting.
--- @param rarity "Common" | "Uncommon" | "Rare" | "Epic" | "Legendary"
function SoundController.onHarvest(rarity: string)
	playSFX("Harvest")
	local rarityKey = RARITY_SFX[rarity]
	if rarityKey and sfxPool[rarityKey] then
		-- Small delay so rarity sting plays after the base harvest sound
		task.delay(0.4, function()
			if sfxPool[rarityKey] then sfxPool[rarityKey]:Play() end
		end)
	end
end

--- Play the brewing-start sound.
function SoundController.onBrewStart()
	playSFX("BrewStart")
end

--- Play the brew-complete sound.
function SoundController.onBrewComplete()
	playSFX("BrewComplete")
end

--- Play the sell sound.
function SoundController.onSell()
	playSFX("Sell")
end

--- Play the upgrade sound.
function SoundController.onUpgrade()
	playSFX("Upgrade")
end

--- Play the recipe discovery fanfare (celebratory, not alarming).
function SoundController.onDiscovery()
	playSFX("Discovery")
end

--- Play a soft notification ping.
function SoundController.onNotification()
	playSFX("Notification")
end

--- Mute / unmute all game audio.
function SoundController.setMuted(muted: boolean)
	soundGroup.Volume = if muted then 0 else 1
end

--- Set music volume (0–1).
function SoundController.setMusicVolume(volume: number)
	if musicSound then
		musicSound.Volume = math.clamp(volume, 0, 1)
	end
end

--- Set SFX volume (0–1).
function SoundController.setSFXVolume(volume: number)
	for _, sound in sfxPool do
		sound.Volume = math.clamp(volume, 0, 1)
	end
end

return SoundController
