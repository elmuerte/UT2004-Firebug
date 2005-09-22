/*******************************************************************************
    fbGasoline

    Creation date: 19/09/2005 13:38
    Copyright (c) 2005, elmuerte
    <!-- $Id: fbGasoline.uc,v 1.2 2005/09/22 09:06:49 elmuerte Exp $ -->
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

function bool isBurning()
{
    return IsInState('Burning');
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
    simulated function BeginState()
    {
        CheckSetOnFire();
    }

    function CheckSetOnFire()
    {
        local fbGasoline fb;
        foreach RadiusActors(class'fbGasoline', fb, CollisionRadius)
        {
            if (fb == self || !fb.isBurning()) continue;
            GotoState('Burning');
            return;
        }
    }

    // touch doesn't set it off
    simulated function ProcessTouch(Actor Other, Vector HitLocation);

    simulated function Timer();

    simulated function TakeDamage( int Damage, Pawn InstigatedBy, Vector HitLocation, Vector Momentum, class<DamageType> DamageType )
    {
        log("TakeDamage"@DamageType);
        if (DamageTypeSetsFire(DamageType))
        {
            GotoState('Burning');
        }
    }

    simulated function MergeWithGlob(int AdditionalGoopLevel)
    {
        local int NewGoopLevel;
        NewGoopLevel = AdditionalGoopLevel + GoopLevel;
        if (NewGoopLevel > MaxGoopLevel)
        {
            if (Role == ROLE_Authority)
                SplashGlobs(NewGoopLevel - MaxGoopLevel);
            NewGoopLevel = MaxGoopLevel;
        }
        SetGoopLevel(NewGoopLevel);
        Stain.SetDrawScale(GoopVolume*default.DrawScale);
        SetCollisionSize(GoopVolume*20.0, 5.0);
        CheckSetOnFire();
        PlaySound(ImpactSound, SLOT_Misc);
    }
}

state Burning
{
    simulated function BeginState()
    {
        local HitFlameHuge fire;

        log("Set on fire");

        bBlockZeroExtentTraces=false;
        SetDrawType(DT_None);
        SetCollisionSize(CollisionRadius+7, 70.0+(GoopVolume*5));
        fire = spawn(class'HitFlameHuge',,, Location);
        fire.LifeSpan = BurnTime+3; // 3seconds more because of the 3second reduce
        LifeSpan = BurnTime;
        SetTimer(0.5, false); //TODO: don't hardcode
    }

    simulated event timer()
    {
        local fbGasoline fb;
        foreach RadiusActors(class'fbGasoline', fb, CollisionRadius)
        {
            if (fb == self || fb.isBurning()) continue;
            fb.TakeDamage(1, Instigator, vect(0,0,0), vect(0,0,0), MyDamageType);
        }
    }

    simulated function ProcessTouch(Actor Other, Vector HitLocation)
    {
        log("Give damage to"@Other);
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