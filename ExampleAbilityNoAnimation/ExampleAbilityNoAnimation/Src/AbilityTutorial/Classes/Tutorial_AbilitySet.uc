// Purpose: Tutorial AbilitySet is an open source example to aid with the development of xcom mods. In this example we are going to make the "Personal Shield" ability
// with out  the animation

//TODO: Add in section about custom effects, Animations

class Tutorial_AbilitySet extends X2Ability
	dependson (XComGameStateContext_Ability) config(GameData_SoldierSkills); //Find the related ini in the config section above

//Our config variables that we will pull from the config file
var config int SHIELD_CHARGES;
var config int SHIELD_DURATION;
var config int SHIELD_POWER;
var config int PASSIVE_SHIELD_POWER;

//The following function generates the templates for the abilities, in short templates are what game uses to generate abilities, units and everything else
//More reading is available in the SDK documentation

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;
	
	Templates.AddItem(AddPersonalShieldAbility()); //Each ability we create needs to be added to this array, it consists of function we will make to define the ability
	Templates.Additem(AddPassiveShieldAbility()); 

	return Templates;
}



static function X2AbilityTemplate AddPersonalShieldAbility() //This is the function that will add our ability to the template array
{
	local X2AbilityTemplate                 Template;
	local X2AbilityCost_ActionPoints        ActionPointCost;
	local X2AbilityCharges                  Charges;
	local X2Effect_ModifyStats              ShieldedEffect;
	local X2AbilityCost_Charges             ChargeCost;


	`CREATE_X2ABILITY_TEMPLATE(Template, 'PersonalShield'); //This adds the ability to the proper localization config files
	                          

	//Now we are going to create specific objects defining the behavior of this ability, and them add them to our template


	Charges = new class 'X2AbilityCharges'; 
	Charges.InitialCharges = default.SHIELD_CHARGES;  
	Template.AbilityCharges = Charges;

	ChargeCost = new class'X2AbilityCost_Charges';
	ChargeCost.NumCharges = 1;
	Template.AbilityCosts.AddItem(ChargeCost);

	Template.AbilitySourceName = 'eAbilitySource_Standard';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_AlwaysShow;
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_adventshieldbearer_energyshield"; //The Icon used in the tactitical as well as the promotion display
	Template.bHideOnClassUnlock = false;
	Template.Hostility = eHostility_Defensive; //Sets how enemies view your action and proritize you

	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.iNumPoints = 1;
	ActionPointCost.bConsumeAllPoints = false;  //Like firing a weapon this automatically ends the turn when to true
	Template.AbilityCosts.AddItem(ActionPointCost); 

	Template.AbilityTargetStyle = default.SelfTarget;	//For this tutorial this is only a personal shield, and only affects the caster
	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);	//This flags the ability as an activated ability, rather than a passive effect or automatic ability.


	ShieldedEffect = CreateShieldedEffect(Template.LocFriendlyName, Template.GetMyLongDescription()); //This creates our effect for the shield
	Template.AddShooterEffect(ShieldedEffect); //This identifies the shooter, useful for animations and other things 

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState; //This is very important, no skill will work with out effecting the game state
	                                                              //All the events need to look into something called the "History" or an over view of everything that
																  // has happened on the last few turns, with out this our effect managers won't be able to call anything
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
	Template.bSkipFireAction = true; // If true, ability will not exit cover/fire/enter cover when activated.
	Template.bShowActivation = true; // If true, ability will automatically show its name over the activating unit's head when used.

	return Template; 


}

//This defines our effect, some abilities in other sets will have them in seprate class files
static function X2Effect_PersistentStatChange CreateShieldedEffect(string FriendlyName, string LongDescription)
{
	local X2Effect_EnergyShield ShieldedEffect;

	//like before we are building a type "X2Effect_ModifyStats" with a persistant duration, looking at these base classes will help understand further what is going on
	ShieldedEffect = new class'X2Effect_EnergyShield';
	ShieldedEffect.BuildPersistentEffect(default.SHIELD_DURATION, false, true, , eGameRule_PlayerTurnEnd); //a persistanteffect calls for something to happen to stats over the course of a duration in turns
	ShieldedEffect.SetDisplayInfo(ePerkBuff_Bonus, FriendlyName, LongDescription, "img:///UILibrary_PerkIcons.UIPerk_adventshieldbearer_energyshield", true);
	ShieldedEffect.AddPersistentStatChange(eStat_ShieldHP, default.SHIELD_POWER);  //An eStat is an enum for all the stat types in the game, they are defined at X2TacticalGameRulesetDataStructures.uc

	return ShieldedEffect;

}

//Keeping with the personal shield for now, The next ability will be a passive that adds 2 shield to our hero as a passive. 
static function X2AbilityTemplate AddPassiveShieldAbility()
{
	local X2AbilityTemplate						Template;
	local X2AbilityTargetStyle                  TargetStyle;
	local X2AbilityTrigger						Trigger;
	local X2Effect_PersistentStatChange         ShieldEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'PassiveShield');

	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_body_shield"; 

	Template.AbilityToHitCalc = default.DeadEye; //Dead eye means the ability can't miss

	TargetStyle = new class'X2AbilityTarget_Self';
	Template.AbilityTargetStyle = TargetStyle;

	Trigger = new class'X2AbilityTrigger_UnitPostBeginPlay'; //This is the trigger, or when our ability fires, we can modify this to work on certain events
	Template.AbilityTriggers.AddItem(Trigger);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	//  NOTE: No visualization on purpose!

	Template.bCrossClassEligible = true; //this can be a bonus from the AWC

	ShieldEffect = new class 'X2Effect_PersistentStatChange';
	ShieldEffect.EffectName = 'PassiveShield';
	ShieldEffect.BuildPersistentEffect(1, true, true, false); //The first Parameter is askign the for the duration of the effect, never set this to 0, the second parameter is 
	                                                                         //for the the infinite duration, since it's a passive ability,  third parameter is to remove it when the unit dies, the fourth is watching for a rule change
	ShieldEffect.AddPersistentStatChange(eStat_ShieldHP, default.PASSIVE_SHIELD_POWER);
	Template.AddTargetEffect(ShieldEffect); 


	return Template;
}
