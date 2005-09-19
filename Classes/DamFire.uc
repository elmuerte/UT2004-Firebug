/*******************************************************************************
    DamFire

    Creation date: 19/09/2005 15:08
    Copyright (c) 2005, elmuerte
    <!-- $Id: DamFire.uc,v 1.1 2005/09/19 14:02:29 elmuerte Exp $ -->
*******************************************************************************/

class DamFire extends DamageType;

static function GetHitEffects(out class<xEmitter> HitEffects[4], int VictimHealth)
{
    HitEffects[0] = class'HitSmoke';

    if( VictimHealth <= 0 )
        HitEffects[1] = class'HitFlameBig';
    else
        HitEffects[1] = class'HitFlame';
}

defaultproperties
{
    DeathString="%o got burned alive."
    //DamageEffect=...
    bFlaming=true
    bArmorStops=false
}