/*******************************************************************************
    FirebugWeapon

    Creation date: 19/09/2005 13:35
    Copyright (c) 2005, elmuerte
    <!-- $Id: FirebugWeapon.uc,v 1.1 2005/09/19 14:02:29 elmuerte Exp $ -->
*******************************************************************************/

class FirebugWeapon extends BioRifle;

defaultproperties
{
    ItemName="Firebug"
    Description="TODO: ..."

    FireModeClass(0)=fbGasCan
    //FireModeClass(1)=fbLighter

    PickupClass=class'FirebugPickup'
}