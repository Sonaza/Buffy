## 2.1.0
* Added support for Legion consumable food, flasks and feasts.
* Added option to enter a custom food that will be prioritised over any other.
* Attempted fix for the error that causes Buffy keybind to sometimes recast the previous spell.
* Disabled Paladin Retribution blessing alerts while in combat since they can only be cast while out of combat anyway.
* Added option to self cast Paladin blessings even while in group.
* Fixed eating alert for new foods.

## 2.0.7
* Added support for Inquisitor's Menacing Eye.

## 2.0.6
* Fixed data error on Demon Hunters.

## 2.0.5
* Paladin blessing reprioritization. It didn't really work before.

## 2.0.4
* Fixed incorrect font path. Oops.

## 2.0.3
* Added support for Paladin blessings. The addon attempts to give buffs with priority on player and grouped tanks. If you wish only to be reminded instead you can enable that in the Paladin options.
* Added font support for non-latin alphabet.
* Fixed bug with food alerts.
* Removed announce from slash commands.

## 2.0.2
* Disabled Pepe alert in PVP. You'll have to use the whiste by yourself if you want to continue battling with him.
* Added support for Arcane Mage talent Arcane Familiar.

## 2.0.1
* Fix to rogue poison alert error.

## 2.0.0 
* Legion update.
	* With the Legion removal of raid buffs all of the notifications were removed. It's a sad, sad day.
	* Removed raid buff announce feature.
	* Removed all class specific notifications that were removed from the game.
	* Removed all references to multistrike.
	* DataBroker module still exists but is only handle for options menu now.
	
	* Buffy will still continue to remind about the following:
		* Some class buffs e.g. Assassination Rogue poisons and Warlock grimoire.
		* Some class specific toggles e.g. Druid forms.
		* Consumables like flasks, runes and food.
		* Pepe \o/
	* Added support for the new Agonizing Poison for Assassination Rogues. Currently it is prioritised over Deadly Poison by default (option to change priority will be added later).
	
Currently the addon will still only remind about Draenor consumables. Legion consumables will be added in a later update soon.