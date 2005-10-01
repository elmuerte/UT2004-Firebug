/*******************************************************************************
    fbGasoline

    Creation date: 19/09/2005 13:38
    Copyright (c) 2005, elmuerte
    <!-- $Id: fbGasoline.uc,v 1.3 2005/10/01 09:35:45 elmuerte Exp $ -->
*******************************************************************************/

class fbGasoline extends BioGlob;

/** class to use to show the gasoline on the floor */
var class<fbGasolineStain> DecallClass;

/** */
var fbGasolineStain Stain;

/** number of seconds it will burn */
var() float BurnTime;

/**
    the collision radius multiplied with this is the radius checked to set other
    fbGasoline instances on fire.
*/
var() float FireRadiusMod;

/** start burning when landed */
var bool InstantBurn;

var protected int TouchCount;

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

    simulated function ProcessTouch(Actor Other, Vector HitLocation)
    {
        local fbGasoline Glob;

        Glob = fbGasoline(Other);

        if ( Glob != None )
        {
            if (Glob.Owner == None || (Glob.Owner != Owner && Glob.Owner != self))
            {
                if (Glob.isBurning())
                {
                    InstantBurn = true;
                }
                else if (bMergeGlobs)
                {
                    Glob.MergeWithGlob(GoopLevel); // balancing on the brink of infinite recursion
                    bNoFX = true;
                    Destroy();
                }
                else {
                    BlowUp( HitLocation );
                }
            }
        }
        else if (Other != Instigator && (Other.IsA('Pawn') || Other.IsA('DestroyableObjective') || Other.bProjTarget))
            BlowUp( HitLocation );
		else if ( Other != Instigator && Other.bBlockActors )
			HitWall( Normal(HitLocation-Location), Other );
    }

    simulated function TakeDamage( int Damage, Pawn InstigatedBy, Vector HitLocation, Vector Momentum, class<DamageType> DamageType )
    {
        if (DamageTypeSetsFire(DamageType))
        {
            GotoState('Burning');
        }
    }
}

state OnGround
{
    simulated function BeginState()
    {
        if (InstantBurn)
        {
            GotoState('Burning');
            return;
        }
        CheckSetOnFire();
    }

    function CheckSetOnFire()
    {
        local fbGasoline fb;
        // find nearby burning gasoline
        foreach RadiusActors(class'fbGasoline', fb, CollisionRadius*FireRadiusMod)
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
    }

    function CheckSetOnFire()
    {
        local fbGasoline fb;
        // find nearby burning gasoline
        foreach RadiusActors(class'fbGasoline', fb, CollisionRadius*FireRadiusMod)
        {
            if (fb == self || fb.isBurning()) continue;
            fb.TakeDamage(1, Instigator, vect(0,0,0), vect(0,0,0), MyDamageType);
        }
    }

    simulated event timer()
    {
        if (Role == ROLE_Authority)
        {
            DelayedHurtRadius(BaseDamage, DamageRadius * GoopVolume, MyDamageType, MomentumTransfer, Location);
        }
    }

    simulated function ProcessTouch(Actor Other, Vector HitLocation)
    {
        log("Give damage to"@Other@self);
        if (Role == ROLE_Authority)
        {
            DelayedHurtRadius(BaseDamage, DamageRadius * GoopVolume, MyDamageType, MomentumTransfer, HitLocation);
        }
    }

    simulated function Touch(Actor Other)
    {
        super.Touch(Other);
        if ( Other == None ) return;
        if (TouchCount == 0) SetTimer(1, true); //TODO: don't hardcode
        TouchCount++;
    }

    simulated function UnTouch( Actor Other )
    {
        super.UnTouch(Other);
        if ( Other == None ) return;
        TouchCount--;
        if (TouchCount == 0) SetTimer(0, false);
        if (TouchCount < 0) TouchCount = 0; //shouldn't happen
    }

Begin:
    log("CheckFire");
    sleep(0.5); //TODO: don't hardcode
    CheckSetOnFire();
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
    FireRadiusMod=1.25
    InstantBurn=false
    TouchCount=0
    //DrawType=DT_None
}