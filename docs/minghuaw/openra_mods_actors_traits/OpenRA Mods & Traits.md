# OpenRA Mods & Traits

# Mods, Actors and Traits

# Resources

1. OpenRA wiki modding guide: [https://github.com/OpenRA/OpenRA/wiki/Modding-Guide](https://github.com/OpenRA/OpenRA/wiki/Modding-Guide)
2. OpenRA Book: [https://www.openra.net/book/glossary.html](https://www.openra.net/book/glossary.html)
3. Delft Students On Software Architecture - OpenRA: [https://delftswa.github.io/chapters/openra/](https://delftswa.github.io/chapters/openra/)

# Mods

> Everything is a mod (including RA - which is loaded by default). [1]

## `OpenRA/mods`

```bash
./mods
├── all
├── cnc
├── common
├── d2k
├── modcontent
├── ra
└── ts
```

## Example `mods/ra`

> The only file which is ***absolutely required*** for a mod is `mod.yaml`

Contains manifest for the mod, which is used to load all the pieces.

- `rules` contains MiniYaml files describing how to assemble actors (units/buildings/etc)
- `maps` contains maps.
- `tilesets` contains MiniYaml files describing the various tilesets -- temperate, snow, etc.
- `chrome` contains MiniYaml files describing the UI chrome
- `uibits` contains various textures used by the chrome
- `bits` contains various loose in-game assets -- SHPs, etc.

```bash
./mods/ra
├── audio
├── bits
├── chrome
├── chrome.yaml
├── cursors.yaml
├── hotkeys.yaml
├── icon-2x.png
├── icon-3x.png
├── icon.png
├── installer
├── maps
├── metrics.yaml
├── missions.yaml
├── mod.yaml
├── rules
├── sequences
├── tilesets
├── uibits
├── weapons
└── ZoodRangmah.ttf
```

# Actors

## What are actors?

> An actor is the entity part of the *entity-component-system*. [2]

> All units/structures/most things in the map are Actors. Actors contain a collection of traits. [1]

Assembled based on `.yaml` files in `rules` directory for a mod

## Actor Example

```yaml
# mods/ra/rules/infantry.yaml
DOG:
  Inherits: ^Soldier
  # Some Traits ...
  AttackLeap:
    Voice: Attack
    PauseOnCondition: attacking || attack-cooldown
  # ...
```

> `Inherits` technically isn't a trait, it is a MiniYaml mechanism that is explained in the chapter 2 link above. [2]

## Loading Trait for Actor

```csharp
// OpenRA.Game/GameRules/ActorInfo.cs
namespace OpenRA {
	public class ActorInfo {
		public ActorInfo(ObjectCreator creator, string name, MiniYaml node) {
			// ...
		}

		static TraitInfo LoadTraitInfo(ObjectCreator creator, string traitName, MiniYaml my) {
			// ...
		}
	}
}
```

# Traits

> There is one instance of the *infoclass* shared across all actors of the same type. Each actor gets its own instance of the *trait class* itself. [1]

> *Infoclasses* are responsible for instantiating their corresponding trait class -- see `ITraitInfo`, and `TraitInfo` for the trivial implementation of this. [1]

> Traits consist of an info class and a class that does stuff. [1]

> Technically a *trait info* is the *component* part of the *entity-component-system* architecture. [2]

> Technically a *trait* is the *system* part of the *entity-component-system* architecture.

The ***info class*** seems like a builder which `Create` a trait class that actually does stuff

```csharp
public abstract class TraitInfo : ITraitInfoInterface {
	// Value is set using reflection during TraitInfo creation
	[FieldLoader.Ignore]
	public readonly string InstanceName = null;

	public abstract object Create(ActorInitializer init);
}
```

## Info Class Example: `AttackLeapInfo`

```csharp
// OpenRA.Mods.Cnc/Traits/Attack/AttackLeap.cs 
// namespace OpenRA.Mods.Cnc.Traits 
[Desc("Move onto the target then execute the attack.")]
public class AttackLeapInfo : AttackFrontalInfo, Requires<MobileInfo> { // inherits TraitInfo class
	// ...
	public override object Create(ActorInitializer init) { return new AttackLeap(init.Self, this); }
}
```

## Trait Class Example: `AttackLeap`

```csharp
// OpeOpenRA.Mods.Cnc/Traits/Attack/AttackLeap.cs 
// namespace OpenRA.Mods.Cnc.Traits 
public class AttackLeap : AttackFrontal { // inherits Actor class
	// ...
	public override Activity GetAttackActivity(
		Actor self, AttackSource source, in Target newTarget, 
		bool allowMove, bool forceAttack, Color? targetLineColor
	) {
		return new LeapAttack(self, newTarget, allowMove, forceAttack, this, info, targetLineColor);
	}
}
```

## Traits and Inheritance

The `TraitInfo` class is the base class of all info class.

The trait classes (both info class and impl class) inherits the `Actor` or `ActorInfo` class??

### Problem

1. The properties of the `Trait` class (eg. `AttackLeap`) are complicated through all the inheritance

## Example - Traits and Inheritance

[UML Example](https://www.notion.so/UML-Example-04b3da5650624bb78c79f7b293e87ad7)

### `AttackLeapInfo`

![OpenRA%20Mods%20&%20Traits%20985ae724f3974eeaab7a0804b70d18e4/Untitled.png](OpenRA%20Mods%20&%20Traits%20985ae724f3974eeaab7a0804b70d18e4/Untitled.png)

### `AttackLeap`

![OpenRA%20Mods%20&%20Traits%20985ae724f3974eeaab7a0804b70d18e4/Untitled%201.png](OpenRA%20Mods%20&%20Traits%20985ae724f3974eeaab7a0804b70d18e4/Untitled%201.png)

# Activity

> Things an actor can be doing are represented as Activity subclasses. Actor has a queue of these. [1]

Seems like actions between actors. Can probably think of it as `system`s that operate on two or more actors.

```csharp
OpenRA.Mods.Cnc/Activities
├── Infiltrate.cs
├── LayMines.cs
├── LeapAttack.cs
├── Leap.cs
├── Teleport.cs
└── VoxelHarvesterDockSequence.cs
```

This is not guaranteed to be true