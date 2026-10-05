ScriptName Apropos2SLPP Hidden
{Adapter for the SexLab P+ (sexlabpp) real-time interaction API, P+ 2.19 or newer.
 SexLab P+ replaces SexLabUtil.dll and exposes real-time, per-actor contact
 detection on its threads (SexLabThread, which sslThreadController extends).

 P+ 2.19 replaced its collision detector and with it the whole interaction API:
 GetCurrentInteractionFlags, GetPartnerByType and CTYPE_* are gone and the flag
 table was renumbered. This adapter therefore does not support P+ 2.17 - 2.18.
 There IsActive() is False and Apropos2 runs on Hentairim stage tags alone,
 exactly as it does on the original SexLab Framework.

 This script MUST be the only place Apropos2 calls the P+-only API, and every
 caller MUST gate on IsActive()/HasLiveData() first, so that none of the P+
 calls are ever dispatched elsewhere and a single build works on every framework.

 Stage tags stay the authority: they carry intensity and endings that contact
 detection cannot see. This adapter only fills in for stages that carry no tags.

 Compile the project against the SexLab P+ 2.19 sources (which contain the full
 legacy API surface as well).}

; P+ and the original SexLab both load an SKSE plugin called "SexLabUtil". P+
; packs its version as major<<24 | minor<<16 | patch<<4 (see P+
; SexLabUtil.GetVersionPack); the original reports a far lower number, or -1 when
; the plugin is missing. 0x02130000 = 2.19.0, the first version with the
; interaction API used below.
Bool Function IsActive() Global
    Return SKSE.GetPluginVersion("SexLabUtil") >= 0x02130000
EndFunction

String Function GetVersionString() Global
    Int v = SKSE.GetPluginVersion("SexLabUtil")
    If v == -1
        Return ""
    EndIf
    Int major = Math.LogicalAnd(Math.RightShift(v, 24), 0xFF)
    Int minor = Math.LogicalAnd(Math.RightShift(v, 16), 0xFF)
    Int patch = Math.LogicalAnd(Math.RightShift(v, 4), 0xFFF)
    Return major + "." + minor + "." + patch
EndFunction

; True when P+ 2.19+ is active AND its contact detection has data for this
; thread. Data can be unavailable even on P+ (feature off, scene not yet
; aligned), so a caller has to cope with never getting any.
Bool Function HasLiveData(sslThreadController thread) Global
    If !thread || !IsActive()
        Return False
    EndIf
    Return thread.IsInteractionRegistered()
EndFunction

; True while the thread is still playing the given stage of a scene the player
; is in. STATUS_INSCENE is 3 on SexLabThread; any other status means the scene is
; being set up, ending or gone.
Bool Function IsSceneLive(sslThreadController thread, Int aiStage) Global
    If !thread
        Return False
    EndIf
    Return thread.GetStatus() == 3 && thread.HasPlayer && thread.Stage == aiStage
EndFunction

; Contact speed from which a detected act counts as intense (the "F" labels).
; P+ 2.19 reports a signed speed (the sign is the direction of movement),
; low-pass filtered over about 0.25s; SpeedPrefix compares its magnitude.
; 18 is the estimate SLO VE uses for the same reading
; (director.physicsfastvelocity); it has NOT been calibrated in game.
Float Function IntenseSpeed() Global
    Return 18.0
EndFunction

; Of two sightings of an act in consecutive samples, keeps the later one at the
; faster of the two paces.
String Function ConfirmLabel(String first, String second) Global
    If StringUtil.GetNthChar(first, 0) == "F" && StringUtil.GetNthChar(second, 0) == "S"
        Return "F" + StringUtil.Substring(second, 1)
    EndIf
    Return second
EndFunction

; "F" when the actor's contact of aiOwnFlag runs at intense speed, else "S".
; The lookup is keyed by the actor's OWN flag; a None partner asks P+ for the
; fastest of the actor's partners in that contact.
String Function SpeedPrefix(sslThreadController thread, Actor act, Int aiOwnFlag) Global
    If Math.Abs(thread.GetInteractionVelocity(act, None, aiOwnFlag)) >= IntenseSpeed()
        Return "F"
    EndIf
    Return "S"
EndFunction

; Synthesize Hentairim stage-tag labels from P+ real-time contact data so the
; existing W&T logic can run unchanged on animations that carry no Hentairim
; tags. Returns [penetrationLabel, oralLabel, stimulationLabel]; "LDI" means
; nothing detected. Only call when HasLiveData() returned True.
; Intensity comes from the contact speed (see IntenseSpeed), except deepthroat,
; which is intense by nature.
String[] Function SynthLabels(sslThreadController thread, Actor act) Global
    String[] labels = New String[3]
    labels[0] = "LDI"
    labels[1] = "LDI"
    labels[2] = "LDI"

    Bool[] flags = thread.GetInteractionFlags(act)
    ; The flag positions are read from the thread, so a P+ release that renumbers
    ; the table again cannot make this read the wrong contacts.
    Int iVaginal = thread.pVaginal
    Int iAnal = thread.pAnal
    Int iDeepthroat = thread.aDeepthroat
    Int iShaft = thread.aLickingShaft
    Int iOral = thread.aOral
    Int iKissing = thread.bKissing
    ; Hand and foot are the exception: upstream's property names for them were
    ; swapped against the native table (SexLabpp PR 77), so those two stay literal
    ; positions of the 2.19 C++ InterType enum (8 = pFootJob, 10 = pHandJob).
    Int iFoot = 8
    Int iHand = 10
    If !flags || flags.Length < 27 || iAnal >= flags.Length || iVaginal >= flags.Length
        Return labels
    EndIf

    If flags[iVaginal] && flags[iAnal]
        ; the faster of the two contacts sets the pace
        If SpeedPrefix(thread, act, iVaginal) == "F" || SpeedPrefix(thread, act, iAnal) == "F"
            labels[0] = "FDP"
        Else
            labels[0] = "SDP"
        EndIf
    ElseIf flags[iVaginal]
        labels[0] = SpeedPrefix(thread, act, iVaginal) + "VP"
    ElseIf flags[iAnal]
        labels[0] = SpeedPrefix(thread, act, iAnal) + "AP"
    EndIf

    If flags[iDeepthroat]
        labels[1] = "FBJ"
    ElseIf flags[iShaft]
        labels[1] = SpeedPrefix(thread, act, iShaft) + "BJ"
    ElseIf flags[iOral]
        ; aOral is only "mouth on partner's genital" - split blowjob from
        ; cunnilingus by the partner's sex as P+ sees it
        ; (0 male, 1 female, 2 futa, 3 male creature, 4 female creature)
        Actor partner = thread.GetPartnerByInteractionType(act, iOral)
        Int partnerSex = 1
        If partner
            partnerSex = SexLabRegistry.GetSex(partner, False)
        EndIf
        If partnerSex != 1 && partnerSex != 4
            labels[1] = SpeedPrefix(thread, act, iOral) + "BJ"
        Else
            labels[1] = "CUN"
        EndIf
    ElseIf flags[iKissing]
        labels[1] = "KIS"
    EndIf

    ; P+ 2.19 has no flag for fingering, fisting or inserted toys (the 2.18
    ; pStimulation), so "BST" cannot be detected any more. A partner's hand or
    ; foot on the actor's genital is the nearest reading left for stimulation.
    If flags[iHand]
        labels[2] = SpeedPrefix(thread, act, iHand) + "ST"
    ElseIf flags[iFoot]
        labels[2] = SpeedPrefix(thread, act, iFoot) + "ST"
    EndIf

    Return labels
EndFunction
