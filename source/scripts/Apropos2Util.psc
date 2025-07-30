ScriptName Apropos2Util hidden
{Global Utility functions for Apropos}

Import ApUtil

Int Function GetVersion() Global
    Return 10013
    ; 1.0   -> 10000
    ; 1.1   -> 11000
    ; 1.1b  -> 11001
    ; 1.61  -> 16100
    ; 1.61b -> 16101 
EndFunction

String Function GetVersionString() Global
    Return "1.0013"
EndFunction

Apropos2Framework Function GetAPI() Global
    Apropos2Framework fx = GetFramework() As Apropos2Framework
    If !fx
        ULog("Error: unable to find Apropos2Framework for formId 0xAA02", "GetAPI", display="trace, notif, console")
    EndIf
    Return fx
EndFunction

Apropos2SystemConfig Function GetConfig() Global
    Apropos2SystemConfig config = GetFramework() As Apropos2SystemConfig
    If !config
        ULog("Error: unable to find AproposSystemConfig for formId 0x0701EE27", "GetConfig", display="trace, notif, console")
    EndIf
    Return config
EndFunction

Apropos2WidgetManager Function GetWidgetManager() Global
    Int aiFormId = 0x1A  ;Apropos2Widgets
    Form frm = Game.GetFormFromFile(aiFormId, "Apropos2.esp")
    If !frm
        ULog("Error: unable to find Apropos2.esp for formId " + aiFormId, "GetWidgetManager", display="trace, notif, console")
    EndIf
    Return frm As Apropos2WidgetManager
EndFunction

Apropos2Actors Function GetActorsLib() Global
    Int aiFormId = 0x1B  ;Apropos2Actors
    Form frm = Game.GetFormFromFile(aiFormId, "Apropos2.esp")
    If !frm
        ULog("Error: unable to find Apropos2.esp for formId " + aiFormId, "GetActorsLib", display="trace, notif, console")
    EndIf
    Return frm As Apropos2Actors
EndFunction

Form Function GetFramework() Global
    Int aiFormId = 0x26  ;Apropos2MainQuest
    Form frm = Game.GetFormFromFile(aiFormId, "Apropos2.esp")
    If !frm
        ULog("GetFramework: unable to find Apropos2.esp for formId " + aiFormId, source="Apropos2Util", display="trace, notif, console")
    EndIf
    Return frm
EndFunction



Function ULogActors(sslThreadController thread, String source="", Bool logActorStats = False, Bool consoleEnabled=True, String display = "trace, console") Global
    SexLabFramework sexLab = GetSexLab()
    Actor[] actorList = thread.Positions
    ULog("Actors [" + actorList.Length + "] >>", source, logActorStats, consoleEnabled, display)
    If thread.HasCreature
        ULog("Creatures: " + thread.Creatures + " " + thread.CreatureRef.GetName(), source, logActorStats, consoleEnabled, display)
    EndIf    
    Int i = 0
    While i < actorList.Length
        Actor anActor = actorList[i]
        String name = GetDetailedActorName(anActor)
        Int gender = sexLab.GetGender(anActor)
        String genderText = GetGenderName(gender)
        
        String isVictim = ""
        If thread.IsVictim(anActor)
            isVictim = "(Victim)"
        EndIf
        
        String debugText = "    [" + i + "]: " + name + ", " + genderText + " " + isVictim
        
        If logActorStats
            debugText += ActorStatsToString(thread, anActor)
        EndIf
        ULog(debugText, source, logActorStats, consoleEnabled, display)
        i += 1
    EndWhile
EndFunction

Function ULogAnimation(sslThreadController thread, String source="", Bool logActorStats=False, Bool consoleEnabled=True, string display="trace, console") Global
    sslBaseAnimation animation = thread.Animation
    String tags = GetTagsAsString(animation)
    ULog("Animation: '" + animation.name + "' ('" + animation.Registry +"') (" + tags + ")", source, logActorStats, consoleEnabled, display)
EndFunction

; Function ULogAnimationStage(String eventName, sslThreadController thread, String source="", bool logActorStats=False, Bool consoleEnabled=True, string display="trace, console") Global
;     ULog("---- " + eventName + " ---- Stage: " + thread.Stage, source, logActorStats, consoleEnabled, display)
;     If logActorStats
;         ULogActors(thread, source, logActorStats, consoleEnabled, display)
;     EndIf
; EndFunction

Function ULogEventInfo(String eventName, sslThreadController thread, String source="", Bool logActorStats=False, Bool consoleEnabled=True, String display="trace, console") Global
    SexLabFramework sexLab = GetSexLab()
    If eventName == "StageStart"
        ULog("---- " + eventName + " ---- Stage: " + thread.Stage, source, logActorStats, consoleEnabled, display)
    Else
        ULog("---- " + eventName + " ----", source, logActorStats, consoleEnabled, display)
    EndIf
    ULogActors(thread, source, logActorStats, consoleEnabled, display)
    ULogAnimation(thread, source, logActorStats, consoleEnabled, display)
EndFunction

Function ULogActor(Actor anActor, String msg, String source = "", bool logActorStats=False, Bool consoleEnabled=True, String display="trace") Global
    ULog(anActor.GetDisplayName() + " " + msg, source, logActorStats, consoleEnabled, display)
EndFunction

Function UDebugActor(Actor anActor, String msg, String source = "", Bool logActorStats=False, Bool consoleEnabled=True) Global
    UDebug(anActor.GetDisplayName() + " " + msg, source, logActorStats, consoleEnabled)
EndFunction

Function UDebug(String msg, String source = "", Bool logActorStats = False, Bool consoleEnabled=True) Global
    ULog(msg, source, logActorStats, consoleEnabled, "console,trace")
EndFunction

Function ULog(String msg, String source = "", Bool logActorStats=False, Bool consoleEnabled=True, String display="trace") Global
    If StringUtil.Find(display, "trace") != -1 || StringUtil.Find(display, "all") != -1
        TraceUser("-- " + source + ": " + msg)
    EndIf
    
    If StringUtil.Find(display, "box") != -1
        Debug.MessageBox(source + ": " + msg)
    EndIf
    
    If StringUtil.Find(display, "notif") != -1 || StringUtil.Find(display, "all") != -1
        Notification(msg)
    EndIf
    
    If StringUtil.Find(display, "stack") != -1
        Debug.TraceStack("-- Apropos2 -- " + source + " : " + msg)
    EndIf
    
    If StringUtil.Find(display, "console") != -1 || StringUtil.Find(display, "all") != -1 
        If consoleEnabled
            Console(source + ": " + msg)
        EndIf
    EndIf	
    
EndFunction

String Function ActorStatsToString(SslThreadController thread, Actor anActor) Global
    SexLabFramework sexLab = GetSexLab()
    SlaUtilScr sla = GetSLA()
    String result = ""
    If sexLab.IsLewd(anActor)
        result += " <lewd>"
    EndIf
    Int enjoyment = thread.GetEnjoyment(anActor)
    If enjoyment > 0
        result += " <enjoyment:" + enjoyment + ">"
    EndIf
    Int pain = thread.GetPain(anActor)
    If pain > 0
        result += " <pain:" + pain + ">"
    EndIf
    result += " <arousal:" + sla.GetActorArousal(anActor) + ">"
    Return result
EndFunction

Function Notification(String msg) Global
    Debug.Notification("[Apropos2] " + msg)
EndFunction

Function Console(String msg) Global
    MiscUtil.PrintConsole("[Apropos2] " + msg)
EndFunction

Function TraceStack(String msg) Global
    Debug.TraceStack("[Apropos2] " + msg, 0)
EndFunction

Function UVerbose(String msg, String source = "", Bool logActorStats=False, Bool consoleEnabled=True) Global
    ULog(msg, source, logActorStats, consoleEnabled, display="all")
EndFunction

Function TraceUser(String msg) Global
    Debug.TraceUser("Apropos2", msg)
EndFunction

; Creates a properly namespaced storage key for storing into JDB, given a regular key
String Function StoreKey(String aKey) Global
    String res = "apropos2_" + aKey
    Return res
EndFunction

; Creates a properly namespaced storage key for querying JDB, given a regular key, and a optional subkey
String Function QueryKey(String aKey, String bKey = "", String cKey = "") Global
    String res = ".apropos2_" + aKey
    If bKey != ""
        res += "."
        res += bKey
    EndIf

    If cKey != ""
        res += "."
        res += cKey
    EndIf    

    Return res
EndFunction

String Function GetKey(String aKey) Global
    Return "apropos2_" + aKey
EndFunction

Int Function GetIntValue(Form target, String storageKey) Global
    Int res = JFormDB.getInt(target, ".apropos2_actors." + storageKey)
    ;ToUserLog("GetIntValue(" + target + ",.apropos_actors." + storageKey + ") = " + res)
    Return res
EndFunction

Float Function GetFloatValue(Form target, String storageKey) Global
    Float res = JFormDB.getFlt(target, ".apropos2_actors." + storageKey)
    ;ToUserLog("GetFloatValue(" + target + ",.apropos_actors." + storageKey + ") = " + res)
    Return res
EndFunction

String Function GetStringValue(Form target, String storageKey) Global
    String res = JFormDB.getStr(target, ".apropos_actors." + storageKey)
    ;ToUserLog("GetStringValue(" + target + ",.apropos_actors." + storageKey + ") = " + res)
    Return res
EndFunction

Function SetIntValue(Form target, String storageKey, Int intValue) Global
    ;ToUserLog("SetIntValue(" + target + ",.apropos_actors." + storageKey + "," + intValue)
    JFormDB.setInt(target, ".apropos2_actors." + storageKey, intValue)
EndFunction

Function SetFloatValue(Form target, String storageKey, Float floatValue) Global
    JFormDB.setFlt(target, ".apropos2_actors." + storageKey, floatValue)
EndFunction

Function SetStringValue(Form target, String storageKey, String stringValue) Global
    JFormDB.setStr(target, ".apropos2_actors." + storageKey, stringValue)
EndFunction

Function ClearStringValue(Form target, String storageKey) Global
    SetStringValue(target, storageKey, "")
EndFunction

String Function CreateTestSentence(Int min = 5, Int max = 15) Global
    String[] words = CreateTestWords()
    Int numWords = Utility.RandomInt(min, max)
    String sentence = ""
    While numWords > 0
        numWords -= 1
        sentence = sentence + " " + words[Utility.RandomInt(1, words.Length - 1)]
    EndWhile
    Return sentence
EndFunction

; Creates a new JMap instance using initial key and value
Int Function InitialMapWithString(String initialKey, String initialValue)
    Int mapId = JMap.object()
    JMap.setStr(mapId, initialKey, initialValue)
    Return mapId
EndFunction

; Creates a new JMap instance using initial key and value
Int Function InitialMapWithInt(String initialKey, Int initialValue)
    Int mapId = JMap.object()
    JMap.setInt(mapId, initialKey, initialValue)
    Return mapId
EndFunction

; Creates a new JMap instance using initial key and value
Int Function InitialMapWithFloat(String initialKey, Float initialValue)
    Int mapId = JMap.object()
    JMap.setFlt(mapId, initialKey, initialValue)
    Return mapId
EndFunction

Bool Function StartsWith(String source, String test) Global
    Int len = StringUtil.GetLength(test)
    If len <= 0 || StringUtil.GetLength(source) < len
        Return False
    EndIf
    
    String subStr = StringUtil.Substring(source, 0, len)
    If subStr == test
        Return True
    EndIf
    Return False
EndFunction

String Function PrependIfNeeded(String source, String prefix) Global
    Bool present = StartsWith(source, prefix)
    If (!present)
        Return prefix + source
    EndIf
    Return source
EndFunction

String Function GetTagsAsString(SslBaseAnimation animation) Global
    String[] tags = animation.GetTags()
    Return StringArrayToString(tags)
EndFunction

Int Function JArrayFromStringArray(String[] array) Global
    Return JArray.objectWithStrings(array)
EndFunction

Bool Function CheckIsJArray(Int arrayId) Global
    If !JValue.isArray(arrayId)
        UDebug(arrayId + " is not a JArray")
        Return False
    EndIf
    Return True
EndFunction

Bool Function CheckIsJMap(Int mapId) Global
    If !JValue.isMap(mapId)
        UDebug(mapId  + " is not a JMap")
        Return False
    EndIf
    Return True
EndFunction

Bool Function LogJMapContents(Int mapId) Global 
    Bool isValidMap = CheckIsJMap(mapId)
    If isValidMap
        UDebug("LogJMapContents was called with valid map:")
        Int keysId = JMap.allKeys(mapId)
        Int i = JArray.Count(keysId)
        While i > 0
            i -= 1
            String k = JArray.getStr(keysId, i)
            UDebug("Key : " + k)
            UDebug("Value : " + JMap.getStr(mapId, k))
        EndWhile
        Return True
    Else
        UDebug("LogJMapContents was not called with a valid map.")
        Return False
    EndIf
EndFunction

String[] Function StringArrayFromJMapKeys(Int mapId) Global
    If !CheckIsJMap(mapId)
        Return DummyArray()
    EndIf   
    Int allKeysArrayId = JMap.allKeys(mapId)
    Return StringArrayFromJArray(allKeysArrayId)
EndFunction

Function DebugJC(Int obj, String label = "") Global
    If JValue.isArray(obj)
        Int cnt = JArray.count(obj)
        If cnt == 0
            UDebug(label + " obj is an EMPTY array!")
        Else
            UDebug(label + " obj is an array count " + cnt)
        EndIf
    ElseIf JValue.isMap(obj) 
        Int cnt = JMap.count(obj)
        If cnt == 0
            UDebug(label + " obj is an EMPTY map!")
        Else
            UDebug(label + " obj is an map count " + cnt)
        EndIf
    Else
        UDebug(label + " obj is not an array or a map!")
    EndIf
EndFunction

String[] Function StringArrayFromJArray(Int arrayId) Global
   ; DebugJC(arrayId)
    If arrayId == 0
        UDebug("StringArrayFromJArray for arrayId=0!!!")
        Return DummyArray()
    EndIf
    Int count = JArray.count(arrayId)
    String[] results = SslUtility.StringArray(count)
    Int index = 0
    While index < count
        results[index] = JArray.getStr(arrayId, index)
        index += 1
    EndWhile
    Return results
EndFunction

String Function GetGenderName(Int genderIndex) Global
    If genderIndex == 0
        Return "Male"
    ElseIf genderIndex == 1
        Return "Female"
    Else
        Return "Creature"
    EndIf
EndFunction

String Function GenerateSettingsExportPath() Global
    Return ModSpecificUserDirectory() + "ExportSettings.txt"
EndFunction

String Function ModSpecificUserDirectory() Global
    Return JContainers.userDirectory() + "Apropos2/"
EndFunction

Function DisplayMessage(String mess, Int maxSegmentLength = 70, Bool toConsole = False) Global
    ; Display to user log and Skyrim screen
    If (StringUtil.GetLength(mess) <= maxSegmentLength)
        If toConsole
            Console(mess)
        EndIf
        Debug.TraceUser("Apropos2", mess)
        Notification(mess)
    Else
        Int arrayId = JString.wrap(mess, maxSegmentLength)
        If arrayId == 0
            Error("---------------------------------------------")
            Error("Error calling JString.wrap on string: " + mess)
            Error("---------------------------------------------")
            Error("--- Only ASCII and UTF-8 strings work!    ---")
        Else
            Int i = JArray.count(arrayId)
            While (i > 0)
                i -= 1
                String part = JArray.getStr(arrayId, i)
                If toConsole
                    Console(part)
                EndIf   
                Debug.TraceUser("Apropos2", part)
                Notification(part)
                
            EndWhile    
        EndIf
    EndIf
    
    Utility.Wait(0.5)
EndFunction	

Function Assert(Bool test, String failureMessage) Global
    Debug.TraceConditional("[Apropos] Assert Failed: " + failureMessage, !test)
EndFunction

String Function GenerateFullPath(String filename, String subFolder = "", String theme = "") Global
    If !subFolder
        If !theme
            Return "Data/Apropos/db/" + filename + ".txt"
        Else
            Return "Data/Apropos/db/" + theme + "/" + filename + ".txt"
        EndIf
    Else
        If !theme
            Return "Data/Apropos/db/" + subFolder + "/" + filename + ".txt"
        Else
            Return "Data/Apropos/db/" + theme + "/" + subFolder + "/" + filename + ".txt"
        EndIf
    EndIf
EndFunction

Int Function LoadAndStoreJsonFile(String fileName, String storageKey, String theme = "") Global
    UDebug("Initializing " + fileName + " ... ")

    String fullPath = GenerateFullPath(fileName, theme)
    If !CheckFileExists(fullPath)
        
        If !theme
            Return 0
        EndIf

        Debug.TraceUser("Apropos2", "Could not load under " + theme + ". Falling back to default")
        fullPath = GenerateFullPath(fileName)
        If !CheckFileExists(fullPath)
            Return 0
        EndIf
    EndIf
    
    Int rootObjectId = JValue.readFromFile(fullPath)
    If (rootObjectId == 0)
        Error("Could not parse " + fileName + ".txt. Check Json validity at http://jsonlint.com")
        Return 0
    EndIf
    
    JDB.setObj(StoreKey(storageKey), rootObjectId)

    Return rootObjectId
EndFunction

Int Function LoadJsonFile(String fileName) Global
    UDebug("Loading " + fileName + " ... ")

    String fullPath = GenerateFullPath(fileName)
    If (!CheckFileExists(fullPath))
        Return 0
    EndIf
    
    Int rootObjectId = JValue.readFromFile(fullPath)
    If (rootObjectId == 0)
        Error("Could not parse " + fileName + ".txt. Check Json validity at http://jsonlint.com")
        Return 0
    EndIf
    
    Return rootObjectId
EndFunction

String Function GetCreatureFromAnimation(SslBaseAnimation animation, Actor firstActiveActor) Global
    If animation.HasTag("Canine")
        Return "Canine"
    ElseIf animation.HasTag("Bear")
        Return "Bear"
    ElseIf animation.HasTag("Chaurus")
        Return "Chaurus"
    ElseIf animation.HasTag("Daedra") || animation.HasTag("Seeker")
        Return "Daedra"
    ElseIf animation.HasTag("Wolf")
        Return "Wolf"
    ElseIf animation.HasTag("Dragon")
        Return "Dragon"
    ElseIf animation.HasTag("Draugr")
        Return "Draugr"
    ElseIf animation.HasTag("Falmer")
        Return "Falmer"
    ElseIf animation.HasTag("Gargoyle")
        Return "Gargoyle"
    ElseIf animation.HasTag("Giant")
        Return "Giant"
    ElseIf animation.HasTag("Horse")
        Return "Horse"
    ElseIf animation.HasTag("Cat") || animation.HasTag("SabreCat")
        Return "Cat"
    ElseIf animation.HasTag("LargeSpider")
        Return "LargeSpider"
    ElseIf animation.HasTag("GiantSpider")
        Return "GiantSpider"        
    ElseIf animation.HasTag("Boar")
        Return "Boar"
    ElseIf animation.HasTag("Spider")
        Return "Spider"
    ElseIf animation.HasTag("Troll")
        Return "Troll"
    ElseIf animation.HasTag("Vampire Lord") || animation.HasTag("Vampirlord")
        Return "VampireLord"
    ElseIf animation.HasTag("Werewolf")
        Return "Werewolf"
    ElseIf animation.HasTag("Riekling")
        Return "Riekling"
    ElseIf animation.HasTag("Lurker") || animation.HasTag("Benthiclurker")
        Return "Lurker"
    ElseIf animation.HasTag("Netch")
        Return "Netch"
    ElseIf animation.HasTag("Horker")
        Return "Horker"
    ElseIf animation.HasTag("skeever") || animation.HasTag("Skeever")
        Return "Skeever"
    ElseIf animation.HasTag("DwarvenSpider")
        Return "DwarvenSpider"
    ElseIf animation.HasTag("DwarvenSphere")
        Return "DwarvenSphere"
    ElseIf animation.HasTag("FrostAtronach")
        Return "FrostAtronach"
    ElseIf animation.HasTag("ChaurusHunter")
        Return "ChaurusHunter"
    ElseIf animation.HasTag("DragonPriest")
        Return "DragonPriest"
    ElseIf animation.HasTag("DwarvenBallista")
        Return "DwarvenBallista"
    ElseIf animation.HasTag("DwarvenCenturion")
        Return "DwarvenCenturion"        
    ElseIf animation.HasTag("StormAtronach")
        Return "StormAtronach"
    ElseIf animation.HasTag("Estrus")
        Return "Estrus"
    ElseIf animation.HasTag("IceWraith")
        Return "IceWraith"
    Else
        Return GetRaceName(firstActiveActor)
    EndIf
EndFunction

Int Function MapWearTearAmountToState(Int amount) Global
    Int result = 0
    If amount < 38
        result = 1
    ElseIf amount >= 38 && amount < 57
        result = 2    
    ElseIf amount >= 57 && amount < 86
        result = 3        
    ElseIf amount >= 86 && amount < 129
        result = 4        
    ElseIf amount >= 129 && amount < 194
        result = 5        
    ElseIf amount >= 194 && amount < 291
        result = 6
    ElseIf amount >= 291 && amount < 437
        result = 7        
    ElseIf amount >= 437 && amount < 800
        result = 8
    ElseIf amount >= 800
        result = 9
    EndIf
    Return result
EndFunction 

Int Function MapWearTearStateToAmount(Int wtState) Global
    Int result = 0
    If wtState == 0
        result = 0
    ElseIf wtState == 1
        result = 37
    ElseIf wtState == 2
        result = 56
    ElseIf wtState == 3
        result = 85
    ElseIf wtState == 4
        result = 128
    ElseIf wtState == 5
        result = 193
    ElseIf wtState == 6
        result = 290
    ElseIf wtState == 7
        result = 436
    ElseIf wtState == 8
        result = 799
    Else
        result = 800
    EndIf
    Return result
EndFunction

String Function GetSexPartAbbreviationString(String[] sexParts) Global
    String result = ""
    If sexParts.Find("Vaginal") >= 0
        result += "V"
    EndIf
    If sexParts.Find("Oral") >= 0
        result += "O"
    EndIf      
    If sexParts.Find("Anal") >= 0
        result += "A"
    EndIf   
    Return result
EndFunction

String Function GetDefaultSexPartTokenFromAnimation(SslBaseAnimation anim) Global
    If anim.HasTag("Vaginal")
        Return "{PUSSY}"
    ElseIf anim.HasTag("Anal")
        Return "{ASS}"
    ElseIf anim.HasTag("Oral")
        Return "{MOUTH}"
    ELseIf anim.HasTag("BoobJob")
        Return "{BOOBS}"
    Else 
        Return ""
    EndIf
EndFunction

String Function GetDefaultSexPartToken(String sexType) Global
    If sexType == "Vaginal"
        Return "{PUSSY}"
    ElseIf sexType == "Anal"
        Return "{ASS}"
    ElseIf sexType == "Oral"
        Return "{MOUTH}"
    ELseIf sexType == "BoobJob"
        Return "{BOOBS}"
    ElseIf sexType == "Gangbang"
        Return "{HOLES}"
    Else 
        Return ""
    EndIf
EndFunction

String[] Function BuildSexPartsFromAnimation(sslBaseAnimation animation) Global
    Bool isAnal = animation.HasTag("Anal")
    Bool isVaginal = animation.HasTag("Vaginal")
    Bool isOral = animation.HasTag("Oral")
    Bool isBoobJob = animation.HasTag("Boobjob")
    Bool isGangBang = animation.HasTag("Gangbang")
    Bool isHandJob = animation.HasTag("Handjob")
    Bool isFisting = animation.HasTag("Fisting")
    Bool isFootJob = animation.HasTag("Footjob")
    Bool isForeplay = animation.HasTag("Foreplay")    
    Bool isBlowjob = animation.HasTag("Blowjob" )

    Return BuildSexParts(isVaginal, isAnal, isOral, isBoobjob, isHandjob, isFisting, isFootjob, isForePlay, isGangbang)
EndFunction

String[] Function BuildSexParts(Bool isVaginal, Bool isAnal, Bool isOral, Bool isBoobjob, Bool isHandjob, Bool isFisting, Bool isFootjob, Bool isForeplay, Bool isGangBang) Global
    String[] result = DummyArray()

    If isVaginal && isAnal && isOral
        result = Strings("Vaginal", "Anal", "Oral")
    ElseIf isVaginal && isAnal
        result = Strings("Vaginal", "Anal")
    ElseIf isVaginal && isOral
        result = Strings("Vaginal", "Oral")
    ElseIf isAnal && isOral
        result = Strings("Anal", "Oral")
    ElseIf isVaginal && isBoobjob
        result = Strings("Vaginal", "Boobjob")
    ElseIf isAnal && isBoobjob
        result = Strings("Anal", "Boobjob")
    ElseIf isVaginal
        result = Strings("Vaginal")
    ElseIf isAnal
        result = Strings("Anal")
    ElseIf isOral
        result = Strings("Oral")
    ElseIf isGangBang
        result = Strings("Gangbang")
    EndIf

    If isBoobjob
        result = PapyrusUtil.PushString(result, "Boobjob")
    EndIf

    If isHandjob
        result = PapyrusUtil.PushString(result, "Handjob")
    EndIf

    If isFisting
        result = PapyrusUtil.PushString(result, "Fisting")
    EndIf

    If isHandjob
        result = PapyrusUtil.PushString(result, "Handjob")
    EndIf

    If isForeplay
        result = PapyrusUtil.PushString(result, "Foreplay")
    EndIf

    Return result 
EndFunction

Function SendApplyWearAndTearEvent(Actor anActor, String area, string damageClass, Bool isRapeOrAggressive, Bool isDaedricCreatureOrDremora, Bool isCreature) Global
    Int eid = ModEvent.Create("APRWT_ApplyWearAndTear")
    ModEvent.PushForm(eid, anActor)
    ModEvent.PushString(eid, area)
    ModEvent.PushString(eid, damageClass)
    ModEvent.PushBool(eid, isRapeOrAggressive)
    ModEvent.PushBool(eid, isDaedricCreatureOrDremora)
    ModEvent.PushBool(eid, isCreature)
    ModEvent.Send(eid)
EndFunction

Function SendOverrideWearAndTearEvent(Actor anActor, String area, Int new_amount, Bool updateAbuse, Bool updateCreatureAbuse, Bool updateDaedricAbuse) Global
    Int eid = ModEvent.Create("APRWT_OverrideWearAndTear")
    ModEvent.PushForm(eid, anActor)
    ModEvent.PushString(eid, area)
    ModEvent.PushInt(eid, new_amount)
    ModEvent.PushBool(eid, updateAbuse)
    ModEvent.PushBool(eid, updateCreatureAbuse)
    ModEvent.PushBool(eid, updateDaedricAbuse)
    ModEvent.Send(eid)
EndFunction

Function SendUpdateEffectsAndTatsEvent(Actor anActor, bool increasingAbuse) Global
    Int eid = ModEvent.Create("APRWT_UpdateEffectsAndTats")
    ModEvent.PushForm(eid, anActor)
    ModEvent.PushBool(eid, increasingAbuse)
    ModEvent.Send(eid)
EndFunction

Int Function GetFactoredArousalIndex(Actor targeActor, Bool isRapist) Global
    ; Flesh out later for other factors, right now add 20 for rape.

    Int arousalValue = GetSLA().GetActorArousal(targeActor)
    Int arousalIndex = GetArousalIndex(arousalValue)

    If isRapist
        Return arousalIndex + 20 ; boost during rape
    Else
        Return arousalIndex
    EndIf
EndFunction

Int Function GetArousalIndex(Int arousalValue) Global
    If arousalValue < 20
        Return 0
    ElseIf arousalValue >= 20 && arousalValue < 40
        Return 1
    ElseIf arousalValue >= 40 && arousalValue < 60
        Return 2
    ElseIf arousalValue >= 60 && arousalValue < 80
        Return 4
    ElseIf arousalValue >= 80
        Return 5
    EndIf
EndFunction

string Function GetLabel(sslBaseAnimation anim , int stage , String actorpos = "0" ) Global

string ActorPosition = ""
	
	if ActorPos == 0
		ActorPosition = "A"
	elseif ActorPos == 1
		ActorPosition = "B"
	elseif ActorPos == 2
		ActorPosition = "C"
	elseif ActorPos == 3
		ActorPosition = "D"
	elseif ActorPos == 4
		ActorPosition = "E"
	endif


	if anim.HasTag(stage+"LI") || anim.HasTag(stage+ActorPosition+"LDI")
		return "LI"
	elseif anim.HasTag(stage+"FA") || anim.HasTag(stage+ActorPosition+"FAP")
		return "FA"
	elseif anim.HasTag(stage+"SA") || anim.HasTag(stage+ActorPosition+"SAP")
		return "SA"
	elseif anim.HasTag(stage+"BA") 
		return "BA"
	elseif anim.HasTag(stage+"BV")
		return "BV"
	elseif anim.HasTag(stage+"FV") || anim.HasTag(stage+ActorPosition+"FVP")
		return "FV"	
	elseif anim.HasTag(stage+"SV") || anim.HasTag(stage+ActorPosition+"SVP")
		return "SV"	
	elseif anim.HasTag(stage+"DP") || anim.HasTag(stage+ActorPosition+"SDP") || anim.HasTag(stage+ActorPosition+"FDP")
		return "DP"
	elseif anim.HasTag(stage+"FB") || anim.HasTag(stage+ActorPosition+"FBJ")
		return "FB"	
	elseif anim.HasTag(stage+"SB") || anim.HasTag(stage+ActorPosition+"SBJ")
		return "SB"	
	elseif anim.HasTag(stage+"EN") || anim.HasTag(stage+ActorPosition+"ENO") || anim.HasTag(stage+ActorPosition+"ENI")
		return "EN"
	elseif anim.HasTag(stage+"TP") || ((anim.HasTag(stage+ActorPosition+"SDP") || anim.HasTag(stage+ActorPosition+"FDP")) && (anim.HasTag(stage+ActorPosition+"SBJ") || anim.HasTag(stage+ActorPosition+"FBJ")))
		return "TP"
	elseif anim.HasTag(stage+"SR") || (anim.HasTag(stage+ActorPosition+"SVP") && anim.HasTag(stage+ActorPosition+"SBJ")) || (anim.HasTag(stage+ActorPosition+"FVP") && anim.HasTag(stage+ActorPosition+"FBJ")) || (anim.HasTag(stage+ActorPosition+"FAP") && anim.HasTag(stage+ActorPosition+"FBJ"))  || (anim.HasTag(stage+ActorPosition+"SAP") && anim.HasTag(stage+ActorPosition+"SBJ"))   
		return "SR"
	else
		return "LI" ;default lead in if no stimulating actions
	endif

endfunction

string Function StimulationLabel(sslBaseAnimation anim , int stage , Int ActorPos) Global

		string ActorPosition = ""
	
	if ActorPos == 0
		ActorPosition = "A"
	elseif ActorPos == 1
		ActorPosition = "B"
	elseif ActorPos == 2
		ActorPosition = "C"
	elseif ActorPos == 3
		ActorPosition = "D"
	elseif ActorPos == 4
		ActorPosition = "E"
	endif
	
	if anim.HasTag(stage+ActorPosition + "SST")
		return "SST"	
	elseif anim.HasTag(stage+ActorPosition + "FST")
		returN "FST"	
	elseif anim.HasTag(stage+ActorPosition + "BST")
		return "BST"	
	else
		return "LDI" ;default lead in if no stimulating actions
	endif

endfunction

string Function PenetrationLabel(sslBaseAnimation anim , int stage , Int ActorPos) Global

	string ActorPosition = ""
	
	if ActorPos == 0
		ActorPosition = "A"
	elseif ActorPos == 1
		ActorPosition = "B"
	elseif ActorPos == 2
		ActorPosition = "C"
	elseif ActorPos == 3
		ActorPosition = "D"
	elseif ActorPos == 4
		ActorPosition = "E"
	endif
	
	if anim.HasTag(stage+ ActorPosition + "SVP")
		return "SVP"
	elseif anim.HasTag(stage+ActorPosition + "SAP")
		return "SAP"
	elseif anim.HasTag(stage+ActorPosition + "FVP")
		return "FVP"
	elseif anim.HasTag(stage+ActorPosition + "FAP")
		return "FAP"
	elseif anim.HasTag(stage+ActorPosition + "SCG")
		return "SCG"
	elseif anim.HasTag(stage+ActorPosition + "FCG")
		return "FCG"
	elseif anim.HasTag(stage+ActorPosition + "SAC")
		return "SAC"
	elseif anim.HasTag(stage+ActorPosition + "FAC")
		return "FAC"
	elseif anim.HasTag(stage+ActorPosition + "SDP")
		return "SDP"
	elseif anim.HasTag(stage+ActorPosition + "FDP")
		return "SDP"
	else
		return "LDI" ;Default lead in if no stimulating actions
	endif
endfunction

string Function PenisActionLabel(sslBaseAnimation anim , int stage , Int ActorPos) Global
	
	string ActorPosition = ""
	
	if ActorPos == 0
		ActorPosition = "A"
	elseif ActorPos == 1
		ActorPosition = "B"
	elseif ActorPos == 2
		ActorPosition = "C"
	elseif ActorPos == 3
		ActorPosition = "D"
	elseif ActorPos == 4
		ActorPosition = "E"
	endif
	
	if anim.HasTag(stage+ActorPosition + "SDV")
		return "SDV"
	elseif anim.HasTag(stage+ActorPosition + "FDV")
		return "FDV"	
	elseif anim.HasTag(stage+ActorPosition + "SDA")
		retuRN "SDA"
	elseif anim.HasTag(stage+ActorPosition + "FDA")
		return "FDA"
	elseif anim.HasTag(stage+ActorPosition + "SHJ")
		reTURN "SHJ"
	elseif anim.HasTag(stage+ActorPosition + "FHJ")
		return "FHJ"
	elseif anim.HasTag(stage+ActorPosition + "STF")
		reTURN "STF"
	elseif anim.HasTag(stage+ActorPosition + "FTF")
		return "FTF"
	elseif anim.HasTag(stage+ActorPosition + "SMF")
		RETURN "SMF"
	elseif anim.HasTag(stage+ActorPosition + "FMF")
		return "FMF"
	elseif anim.HasTag(stage+ActorPosition + "SFJ")
		reTURN "SFJ"
	elseif anim.HasTag(stage+ActorPosition + "SFJ")
		returN "FFJ"
	else
		reTURN "LDI" ;default lead in if no stimulating actions
	endif
endfunction


String Function OralLabel(sslBaseAnimation anim , int stage , Int ActorPos) Global
	
	string ActorPosition = ""
	
	if ActorPos == 0
		ActorPosition = "A"
	elseif ActorPos == 1
		ActorPosition = "B"
	elseif ActorPos == 2
		ActorPosition = "C"
	elseif ActorPos == 3
		ActorPosition = "D"
	elseif ActorPos == 4
		ActorPosition = "E"
	endif
	
	if anim.HasTag(stage+ ActorPosition + "KIS")
		return "KIS"
	elseif anim.HasTag(stage+ ActorPosition + "CUN")
		return "CUN"
	elseif anim.HasTag(stage+ ActorPosition + "FBJ")
		return "FBJ"
	elseif anim.HasTag(stage+ ActorPosition + "SBJ")
		returN "SBJ"
	else
		reTURN "LDI"
	endif

endfunction

String Function EndingLabel(sslBaseAnimation anim , int stage , Int ActorPos) Global
	;Labels that identify actions on partners
	
	string ActorPosition = ""
	
	if ActorPos == 0
		ActorPosition = "A"
	elseif ActorPos == 1
		ActorPosition = "B"
	elseif ActorPos == 2
		ActorPosition = "C"
	elseif ActorPos == 3
		ActorPosition = "D"
	elseif ActorPos == 4
		ActorPosition = "E"
	endif
	
	if anim.HasTag(stage+ ActorPosition + "ENO")
		return "ENO"
	elseif anim.HasTag(stage+ ActorPosition + "ENI")
		return "ENI"
	else
		Return "LDI"
	endif

endfunction

string Function GetSFX(sslBaseAnimation anim , int stage) Global
if anim.HasTag(stage+"SC")
		return "SC"
	elseif anim.HasTag(stage+"MC")
		return "MC"
	elseif anim.HasTag(stage+"FC")
		return "FC"
	elseif anim.HasTag(stage+"SS")
		return "SS"	
	elseif anim.HasTag(stage+"MS")
		return "MS"
	elseif anim.HasTag(stage+"FS")
		return "FS"	
	elseif anim.HasTag(stage+"RS")
		return "RS"	
	elseif anim.HasTag(stage+"NA")
		return "NA"
	endif

endfunction
