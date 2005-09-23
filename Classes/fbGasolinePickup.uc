/*******************************************************************************
    fbGasolinePickup

    Creation date: 23/09/2005 10:09
    Copyright (c) 2005, elmuerte
    <!-- $Id: fbGasolinePickup.uc,v 1.1 2005/09/23 09:24:21 elmuerte Exp $ -->
*******************************************************************************/

class fbGasolinePickup extends BioAmmoPickup;

defaultproperties
{
    InventoryType=class'fbGasolineAmmo'
    PickupMessage="You picked up some gasoline"
}