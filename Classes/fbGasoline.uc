/*******************************************************************************
    fbGasoline

    Creation date: 19/09/2005 13:38
    Copyright (c) 2005, elmuerte
    <!-- $Id: fbGasoline.uc,v 1.1 2005/09/19 14:02:29 elmuerte Exp $ -->
*******************************************************************************/

class fbGasoline extends BioGlob;

/** class to use to show the gasoline on the floor */
var class<fbGasolineStain> DecallClass;

/** */
var fbGasolineStain Stain;

var() float BurnTime;

simulated function Destroyed()
{
    if (Stain != none) Stain.Destroy();
    super.Destroyed();
}

auto state Flying
{
    simulated function Landed( Vector HitNormal )
    {
        local Rotator NewRot;
        local int CoreGoopLevel;

        if ( Level.NetMode != NM_DedicatedServer )
        {
            PlaySound(ImpactSound, SLOT_Misc);
            // explosion effects
        }

        SurfaceNormal = HitNormal;

        // spawn globlings
        CoreGoopLevel = Rand3 + MaxGoopLevel - 3;
        if (GoopLevel > CoreGoopLevel)
        {
            if (Role == ROLE_Authority)
                SplashGlobs(GoopLevel - CoreGoopLevel);
            SetGoopLevel(CoreGoopLevel);
        }
		Stain = spawn(DecallClass,,,, rotator(-HitNormal));

        bCollideWorld = false;
        SetCollisionSize(GoopVolume*15.0, 5.0);
        bProjTarget = true;

	    NewRot = Rotator(HitNormal);
	    NewRot.Roll += 32768;
        SetRotation(NewRot);
        SetPhysics(PHYS_None);
        bCheckedsurface = false;

        SetDrawScale3D(vect(2.5,2.5,0.01));

        Fear = Spawn(class'AvoidMarker');
        GotoState('OnGround');
    }
}

state OnGround
{
    simulated function BeginState();

    // touch doesn't set it off
    simulated function ProcessTouch(Actor Other, Vector HitLocation);

    simulated function Timer();

    function TakeDamage( int Damage, Pawn InstigatedBy, Vector HitLocation, Vector Momentum, class<DamageType> DamageType )
    {
        if (DamageTypeSetsFire(DamageType))
        {
            GotoState('Burning');
        }
    }

    simulated function MergeWithGlob(int AdditionalGoopLevel)
    {
        //TODO: improve
        super.MergeWithGlob(AdditionalGoopLevel);
        Stain.SetDrawScale(GoopVolume*default.DrawScale);
        SetCollisionSize(GoopVolume*20.0, 5.0);
    }

}

state Burning
{
    simulated function BeginState()
    {
        local HitFlameHuge fire;
        log("Set on fire");
        bBlockActors = false;
        bBlockPlayers = true;
        bBlockProjectiles = false;
        SetCollisionSize(CollisionRadius, 50.0+(GoopVolume*0.5));
        fire = spawn(class'HitFlameHuge',,, Location);
        fire.LifeSpan = BurnTime;
        LifeSpan = BurnTime;
    }

    simulated function ProcessTouch(Actor Other, Vector HitLocation)
    {
        log("Give damage");
        if (Role == ROLE_Authority)
        {
            DelayedHurtRadius(BaseDamage, DamageRadius * GoopVolume, MyDamageType, MomentumTransfer, HitLocation);
        }

    }
}


// do nothing right now
function BlowUp(Vector HitLocation);

// do nothing right now
//singular function SplashGlobs(int NumGloblings);

/** returns true if the damage sets the gasoline on fire */
function bool DamageTypeSetsFire(class<DamageType> DamageType)
{
    if (DamageType.default.bFlaming) return true;
    if (DamageType.default.bBulletHit) return true;
    return false;
}

defaultproperties
{
    DecallClass=class'fbGasolineStain'
    DrawScale=1
    LifeSpan=60
    BurnTime=90
    MyDamageType=class'DamFire'
    //DrawType=DT_None
}