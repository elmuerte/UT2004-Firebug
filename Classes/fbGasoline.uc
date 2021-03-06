/*******************************************************************************
    fbGasoline

    Creation date: 19/09/2005 13:38
    Copyright (c) 2005, elmuerte
    <!-- $Id: fbGasoline.uc,v 1.6 2005/10/22 12:42:37 elmuerte Exp $ -->
*******************************************************************************/

class fbGasoline extends BioGlob;

//TODO: not flamable in water

/** class to use to show the gasoline on the floor */
var class<fbGasolineStain> DecallClass;

/** */
var fbGasolineStain Stain;

var HitFlameHuge fire;

/** number of seconds it will burn */
var() float BurnTime;

/** number of seconds it takes forchain burning to work */
var() float DelayedBurn;

/**
    the collision radius multiplied with this is the radius checked to set other
    fbGasoline instances on fire.
*/
var() float FireRadiusMod;

/** start burning when landed */
var bool InstantBurn;

/** keeps track of number of touching actors to reduce timer usage */
var protected int TouchCount;

/**
    the baselocation of this actor, the location is changed when it reaches the
    burning state, this will be the original location
*/
var vector BaseLocation; //!TODO: replicate

replication
{
    reliable if (Role == ROLE_Authority)
        BaseLocation;
}

simulated function Destroyed()
{
    if ( IsInState('Burning') && !bNoFX && EffectIsRelevant(Location,false) )
    {
        Spawn(class'fbSmallSmoke',,,BaseLocation);
    }
    if ( Fear != None )
        Fear.Destroy();
    if (Trail != None)
        Trail.Destroy();
    if (Stain != none)
        Stain.Destroy();
    if (fire != none)
        fire.Destroy();
    super(Projectile).Destroyed();
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
        //TODO: fix
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
                    // could have got instant burn when going through the air
                    if (InstantBurn) Glob.TakeDamage(1, Instigator, vect(0,0,0), vect(0,0,0), MyDamageType);
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
            InstantBurn = true;
        }
    }
}

state OnGround
{
ignores
    ProcessTouch, Timer;

    simulated function BeginState()
    {
        BaseLocation = Location;
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
        foreach RadiusActors(class'fbGasoline', fb, CollisionRadius*FireRadiusMod, BaseLocation+vect(0,0,35))
        {
            if (fb == self || !fb.isBurning()) continue;
            GotoState('DelayedBurning');
            return;
        }
    }

    // touch doesn't set it off
    //simulated function ProcessTouch(Actor Other, Vector HitLocation);

    //simulated function Timer();

    simulated function TakeDamage( int Damage, Pawn InstigatedBy, Vector HitLocation, Vector Momentum, class<DamageType> DamageType )
    {
        if (DamageTypeSetsFire(DamageType))
        {
            if (DamageType == MyDamageType)
                GotoState('DelayedBurning');
            else
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

state DelayedBurning
{
ignores
    TakeDamage, MergeWithGlob, ProcessTouch;

Begin:
    sleep(DelayedBurn);
    GotoState('Burning');
}

state Burning
{
    simulated function BeginState()
    {
        local vector newloc;
        Fear = Spawn(class'AvoidMarker');
        bBlockZeroExtentTraces=false;
        SetDrawType(DT_None);
        fire = spawn(class'HitFlameHuge',,, Location);
        fire.LifeSpan = BurnTime+3; // 3seconds more because of the 3second reduce
        //TODO: set size
        LifeSpan = BurnTime;
        Stain.EndLife(BurnTime);

        SetCollisionSize(CollisionRadius+7, 35.0+(GoopVolume*5));
        newloc = Location;
        newloc.Z = newloc.Z+CollisionHeight;
        SetLocation(newloc);
    }

    function CheckSetOnFire()
    {
        local fbGasoline fb;
        // find nearby burning gasoline
        foreach RadiusActors(class'fbGasoline', fb, CollisionRadius*FireRadiusMod, BaseLocation)
        {
            if (fb == self || fb.isBurning()) continue;
            fb.TakeDamage(1, Instigator, vect(0,0,0), vect(0,0,0), MyDamageType);
        }
    }

    simulated event Timer()
    {
        if (Role == ROLE_Authority)
        {
            DelayedHurtRadius(BaseDamage, CollisionRadius, MyDamageType, MomentumTransfer, Location);
        }
    }

    simulated function ProcessTouch(Actor Other, Vector HitLocation)
    {
        if (Role == ROLE_Authority)
        {
            DelayedHurtRadius(BaseDamage, CollisionRadius, MyDamageType, MomentumTransfer, HitLocation);
        }
    }

    simulated function Touch(Actor Other)
    {
        super.Touch(Other);
        if (Role == ROLE_Authority)
        {
            if ( Pawn(Other) == None ) return;
            if (TouchCount == 0) SetTimer(1, true); //TODO: don't hardcode
            TouchCount++;
        }
    }

    simulated function UnTouch( Actor Other )
    {
        super.UnTouch(Other);
        if (Role == ROLE_Authority)
        {
            if ( Pawn(Other) == None ) return;
            TouchCount--;
            if (TouchCount == 0) SetTimer(0, false);
            if (TouchCount < 0) TouchCount = 0; //shouldn't happen
        }
    }

    simulated function TakeDamage( int Damage, Pawn InstigatedBy, Vector HitLocation, Vector Momentum, class<DamageType> DamageType )
    {
        log("TakeDamage"@DamageType@Damage);
        if ((Damage > 75) && DamageTypeKillsFire(DamageType)) //TODO: don't hardcode
        {
            Destroy();
        }
    }

Begin:
    sleep(DelayedBurn); //TODO: don't hardcode
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

/** return true if this damage can kill the fire */
function bool DamageTypeKillsFire(class<DamageType> DamageType)
{
    if (class<DamTypeRocket>(DamageType)!=none) return true;
    return false;
}

defaultproperties
{
    Speed=300.0
    DecallClass=class'fbGasolineStain'
    DrawScale=1
    LifeSpan=60
    BurnTime=30
    MyDamageType=class'DamFire'
    FireRadiusMod=1.25
    InstantBurn=false
    TouchCount=0
    DelayedBurn=0.25
    DrawType=DT_None
}