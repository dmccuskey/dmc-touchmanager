# dmc-touchmanager

try:
	if not gSTARTED: print( gSTARTED )
except:
	MODULE = "dmc-touchmanager"
	include: "../DMC-Corona-Library/snakemake/Snakefile"

module_config = {
	"name": "dmc-touchmanager",
	"module": {
		"dir": "dmc_corona",
		"files": [
			"dmc_touchmanager.lua",
		],
		"requires": [
			"dmc-corona-boot"
		]
	},
	"examples": {
		"base_dir": "examples",
		"apps": [
			{
				"exp_dir": "dmc-touchmanager-basic",
				"requires": []
			},
		]
	},
	"tests": {
		"files": [],
		"requires": []
	}
}


register( "dmc-touchmanager", module_config )

