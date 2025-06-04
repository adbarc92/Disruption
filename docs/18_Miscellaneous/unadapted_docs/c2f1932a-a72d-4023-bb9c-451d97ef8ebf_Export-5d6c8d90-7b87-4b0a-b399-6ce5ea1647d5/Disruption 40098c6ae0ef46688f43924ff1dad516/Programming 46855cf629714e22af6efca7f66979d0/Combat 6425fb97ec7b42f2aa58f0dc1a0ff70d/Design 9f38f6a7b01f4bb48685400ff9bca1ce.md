# Design

=> : Includes, ~> : Inherits, *> : Variable. !> Clarification, ?> Questions

Combat
=> Battle
=> Team
=> Round
=> Turn
=> Field: 3 rows by

Battle
*> turnPriority (fixer function, turn management)

Stats
=> BaseStats
=> StatBlock
=> Resistances

Equipment:
!> Types include: head, chest, hands, legs, feet
!> Slots: Weapon (1), Head (2), Chest (3), Hands (4), Legs (5)

Device

Unit
*> ID
=> Technique
=> Stats
*> Position: std::pair<int x, int y>
~> Monster
~> Character
*> Apotheosis Meter
=> Equipment
~> Enemy
?> Would a battleprofile (including sprites, turnPriority, etc.) be helpful?

Status
*> Duration
*> Stat Affected
*> Type (e.g. DOT, buff, nerf)
?> Do statuses persist between encounters?
!> Includes: Sealed, Disrupted, Bleeding, Poison, Zombie/Atrophy/Decay

Technique
*> Damage Modifier
*> HP Modifier
*> Description: std::string
*> Status Modifier: std::pair<std::string, float rate>
*> TargetType
1. Self Square
2. Single Ally Square
3. Many Ally Squares (2-3)
4. All Ally Squares (9)
5. Single Enemy Square
6. Many Enemy Squares (2-8)
7. All Enemy Squares (9)
8. AOE ("+","X")
9. Single Ally Square and Single Enemy Square
10. Everyone
*> Movement Modifier (Self): std::pair<int direction, int degree>
1. N (Y+degree)
2. W (X-degree)
3. E (X+degree)
4. S (Y-degree)
5. NW (X-Degree, Y+Degree)
6. NE (X+Degree,Y+Degree)
7. SW (X-Degree, Y-Degree)
8. SE (X+Degree, Y-Degree)
Q: Degree Variance?
*> std::vector<int> user_ids
*> std::string damage_type:
1. Physical (Blunt, Slashing, Piercing?)
2. Flame
3. Water
4. Ice
5. Wind
6. Shadow/Corruption
7. Radiant/Lightning
8. ...

Encounter: Triggered by touching sprites with roaming enemies, random chance while camping, or by scripted encounters
=> Team
=> Members
=> Position

Party
=> Team
=> Members
=> Position
=> Inventory
=> Consumables
=> Equipment
=> Keys

Boss : Unit
* Concepts: Collective Agents, Disruption Legends (Creatures), Rival Scouts, Outsider Tribesmen
=> Technique
=> Inventory (Drops)
=> Equipment (Stealable)

Turn (1 big action, 1 small action per turn)
* Big Actions: consume 1 big action
* Strike (100% Accuracy, 100% Damage)
* Smite (80% Accuracy, 120% Damage, Init+1 for 1 Turn)
* Intercept
* Hold (IF: Vaughn in party)
* Defend
* Major Actions: Consume both actions
* Technique
* Device
* Magic
* Small Actions: consume 1 small action, consume 1 big action if taken again
* Item
* Move
* Apotheosis (IF: Bar=100%)
* Draw (IF: Lione)
* Channel (IF: Lione | Sophia): continue technique from previous action at decreased power
* Transform (IF: Chiranjivi)