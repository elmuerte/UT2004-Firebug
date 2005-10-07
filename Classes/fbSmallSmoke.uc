/*******************************************************************************
    fbSmallSmoke

    Creation date: 07/10/2005 10:55
    Copyright (c) 2005, elmuerte
    <!-- $Id: fbSmallSmoke.uc,v 1.1 2005/10/07 09:58:14 elmuerte Exp $ -->
*******************************************************************************/

class fbSmallSmoke extends pclSmallSmoke;

function PostBeginPlay()
{
    SetTimer(2, false);
}

event Timer()
{
    mRegen=false;
}