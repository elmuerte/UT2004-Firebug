/*******************************************************************************
    Firebug
    This mutator will add the firebug weapon to the game.

    A weapon mod. Use a gascan to create a trail of gasoline and set it on fire
    with your lighter (or other weapon).

    Model and idea by barnEbiss ...
    Code by Michiel "El Muerte" Hendriks

    <!-- $Id: mutFirebug.uc,v 1.4 2005/10/01 09:35:45 elmuerte Exp $ -->
*******************************************************************************/

class mutFirebug extends Mutator config;

var config bool bDebug;

/*

gasoline is like bioglob but with an invisible and flat mesh (used as hitactor)
    and fire emitter location
with a projector to show the real gasoline
make sure people can only dump gasoline where it is possible
no lifetime, always spawn
bullet weapon and rocket weapon can also light the fire

*/

function bool CheckReplacement( Actor Other, out byte bSuperRelevant )
{
    if (Other.class == class'BioRifle')
    {
        ReplaceWith(Other, string(class'FirebugWeapon'));
        return false;
    }
    else if (Other.class == class'BioriflePickup')
    {
        ReplaceWith(Other, string(class'FireBugPickup'));
        return false;
    }
    else if (Other.class == class'BioAmmoPickup')
    {
        ReplaceWith(Other, string(class'fbGasolinePickup'));
        return false;
    }
    return true;
}

function ModifyPlayer(Pawn Other)
{
	super.ModifyPlayer(Other);
	if (bDebug)
	{
	   Other.Controller.ConsoleCommand("rend collision");
	}
}

defaultproperties
{
    FriendlyName="Firebug"
    Description="ALPHA: currently replaces the biorifle"

    bDebug=true
}
