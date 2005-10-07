/*******************************************************************************
    fbGasolineStain

    Creation date: 19/09/2005 13:55
    Copyright (c) 2005, elmuerte
    <!-- $Id: fbGasolineStain.uc,v 1.2 2005/10/07 09:57:49 elmuerte Exp $ -->
*******************************************************************************/

class fbGasolineStain extends DynamicProjector;

#exec TEXTURE IMPORT NAME=fbGasolineStain1 FILE=TEXTURES\fbGasolineStain1.tga LODSET=2 MODULATED=1 UCLAMPMODE=CLAMP VCLAMPMODE=CLAMP
#exec TEXTURE IMPORT NAME=fbGasolineStain2 FILE=TEXTURES\fbGasolineStain2.tga LODSET=2 MODULATED=1 UCLAMPMODE=CLAMP VCLAMPMODE=CLAMP

event PreBeginPlay()
{
    if ( Level.NetMode == NM_DedicatedServer )
    {
        Destroy();
        return;
    }
    if ( FRand() < 0.5 )
        ProjTexture = texture'fbGasolineStain2';
    super.PreBeginPlay();
}

function PostBeginPlay()
{
    local Vector RX, RY, RZ;
    local Rotator R;

    if ( PhysicsVolume.bNoDecals )
    {
        Destroy();
        return;
    }
    R.Yaw = 0;
    R.Pitch = 0;
    R.Roll = Rand(65535);
    GetAxes(R,RX,RY,RZ);
    RX = RX >> Rotation;
    RY = RY >> Rotation;
    RZ = RZ >> Rotation;
    R = OrthoRotation(RX,RY,RZ);
    SetRotation(R);
    SetLocation( Location - Vector(Rotation)*24 ); //24 = PushBack
    Super.PostBeginPlay();
}

function EndLife(float LifeTime)
{
    LifeSpan = LifeTime;
    //TODO: DO FADE!!!
}

defaultproperties
{
    LifeSpan=0
    DrawScale=1
    ProjTexture=texture'fbGasolineStain1'
    bClipStaticMesh=True

    bGameRelevant=true
    //PushBack=24
    FOV=1
    MaxTraceDistance=60
    bProjectBSP=true
    bProjectTerrain=true
    bProjectStaticMesh=true
    bProjectActor=false
    bClipBSP=true
    bNoDelete=false
    bStatic=false
    FadeInTime=0.125
    MaterialBlendingOp=PB_None
    FrameBufferBlendingOp=PB_Modulate
    GradientTexture=GRADIENT_Clip
}