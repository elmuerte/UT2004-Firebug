/*******************************************************************************
    Firebug
    This mutator will add the firebug weapon to the game.

    A weapon mod. Use a gascan to create a trail of gasoline and set it on fire
    with your lighter (or other weapon).

    Model and idea by barnEbiss ...
    Code by Michiel "El Muerte" Hendriks

    <!-- $Id: mutFirebug.uc,v 1.2 2005/09/19 14:02:29 elmuerte Exp $ -->
*******************************************************************************/

class mutFirebug extends Mutator;

/*

gasoline is like bioglob but with an invisible and flat mesh (used as hitactor)
    and fire emitter location
with a projector to show the real gasoline
make sure people can only dump gasoline where it is possible
no lifetime, always spawn
bullet weapon and rocket weapon can also light the fire

*/

defaultproperties
{
    FriendlyName="Firebug"
    Description="..."
}
