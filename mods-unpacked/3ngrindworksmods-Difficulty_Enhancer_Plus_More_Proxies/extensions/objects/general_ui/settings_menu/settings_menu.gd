extends "res://objects/general_ui/settings_menu/settings_menu.gd"

var ProxyMultButton : GeneralButton
var HealthMultButton : GeneralButton
var DamageMultButton : GeneralButton
var MinimumCogsButton : GeneralButton
var AllProxyButton : GeneralButton


var ProxyMultId : int
var HealthMultId : int
var DamageMultId : int
var MinimumCogsId : int
var AllProxyId: int

const AllProxySettings : Dictionary = {
	0 : "Off",
	1 : "On",
}

var ProxyMultSettings = [1.0, 1.25, 1.5, 1.75, 2.0, 2.5, 3.0, 4.0, 0.5]
var HealthMultSettings = [1.0, 1.20, 1.40, 1.60, 1.80, 2.0, 2.25, 2.5, 2.75, 3, 4, 5, 6, 7, 8, 0.8]
var DamageMultSettings = [1.0, 1.20, 1.40, 1.60, 1.80, 2.0, 2.25, 2.5, 2.75, 3, 4, 100, 0.8]
var MinimumCogsSettings = [1, 2, 3, 4, 5, 6, 10, 15]

func _ready() -> void:
	super()
	print(ModLoaderConfig.get_configs("3ngrindworksmods-Difficulty_Enhancer_Plus_More_Proxies"))
	var SettingsConfig = ModLoaderConfig.get_config("3ngrindworksmods-Difficulty_Enhancer_Plus_More_Proxies", "settings").data
	ProxyMultId = SettingsConfig["Proxy chance multiplier"]
	HealthMultId  = SettingsConfig["Health Modifier"]
	DamageMultId = SettingsConfig["Damage Multiplier"]
	MinimumCogsId = SettingsConfig["Minimum cog amount"]
	AllProxyId = SettingsConfig["All Proxies"]
	
	var DifficultyMenuResource = load("res://mods-unpacked/3ngrindworksmods-Difficulty_Enhancer_Plus_More_Proxies/Difficulty_settings.tscn")
	var DifficultyMenu = DifficultyMenuResource.instantiate()
	var SettingContainer = get_node("Panel/SettingScroller/MarginContainer/SettingContainer")
	add_child(DifficultyMenu)
	DifficultyMenu.reparent(SettingContainer)
	
	ProxyMultButton = DifficultyMenu.get_node("%ProxyMultButton")
	HealthMultButton = DifficultyMenu.get_node("%HealthMultButton")
	DamageMultButton = DifficultyMenu.get_node("%DamageMultButton")
	MinimumCogsButton = DifficultyMenu.get_node("%MinimumCogsButton")
	AllProxyButton = DifficultyMenu.get_node("%AllProxyButton")
	
	ProxyMultButton.text =  str(ProxyMultSettings[ProxyMultId])
	HealthMultButton.text = str(HealthMultSettings[HealthMultId])
	DamageMultButton.text = str(DamageMultSettings[DamageMultId])
	MinimumCogsButton.text = str(MinimumCogsSettings[MinimumCogsId])
	AllProxyButton.text = str(AllProxySettings[AllProxyId])

	ProxyMultButton.connect("pressed", ProxyMult)
	HealthMultButton.connect("pressed", HealthMult)
	DamageMultButton.connect("pressed", DamageMult)
	MinimumCogsButton.connect("pressed", MinimumCogs)
	AllProxyButton.connect("pressed", AllProxy)

func ProxyMult() -> void:
	ProxyMultId += 1
	if ProxyMultId >= len(ProxyMultSettings):
		ProxyMultId = 0
	ProxyMultButton.text = str(ProxyMultSettings[ProxyMultId])

func HealthMult() -> void:
	HealthMultId += 1
	if HealthMultId >= len(HealthMultSettings):
		HealthMultId = 0
	HealthMultButton.text = str(HealthMultSettings[HealthMultId])

func DamageMult() -> void:
	DamageMultId += 1
	if DamageMultId >= len(DamageMultSettings):
		DamageMultId = 0
	DamageMultButton.text =  str(DamageMultSettings[DamageMultId])
	
func MinimumCogs() -> void:
	MinimumCogsId += 1
	if MinimumCogsId >= len(MinimumCogsSettings):
		MinimumCogsId = 0
	MinimumCogsButton.text = str(MinimumCogsSettings[MinimumCogsId])
	
func AllProxy() -> void:
	AllProxyId += 1
	if AllProxyId >= len(AllProxySettings):
		AllProxyId = 0
	AllProxyButton.text = str(AllProxySettings[AllProxyId])

func close(save := false) -> void:
	super(save)
	var newConfig = ModLoaderConfig.get_current_config("3ngrindworksmods-Difficulty_Enhancer_Plus_More_Proxies")
	newConfig.data = {
			"Proxy chance multiplier": ProxyMultId,
			"Health Modifier": HealthMultId,
			"Damage Multiplier": DamageMultId,
			"Minimum cog amount":MinimumCogsId,
			"All Proxies": AllProxyId
	}
	ModLoaderConfig.update_config(newConfig)
	ModLoaderConfig.refresh_current_configs()
