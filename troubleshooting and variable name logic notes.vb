What would have to happen for KK to equal 362?
    l00004
    l02005
SPEAK LLINE index starts at 371, so it would not be calling SPEAK to generate the text
J==17 which is the room we're in
When I enter the Hall of Mists, LOC is 15, lookup in KEY makes KK==143
    LOLD=L (15, previous room)
    Look through until KK==147 making LL==17452, goto l00010
    L=17, Hall of Mists, goto l00021
    L<300 so goto l00002
    goes to l00074, LOC=L (LOC must be current location)
    KK=165
    l00007, COND(17)==2 (False keep going)
    J=L (17)
    goto l02000
    ABB(17)=4
    LAMP still working, so goto l02003
    I=IOBJ[17] ==12
    ILK=I
    KK=BTEXT[12] == "0"
    I=ICHAIN[12] =="0", goto l02004
    Goto l02011

Known bugs: Magic wand is not working
    I suspect the NIL FOrtranWrite errors are related that what Verb found
        Error occurs at line 707 near label l00004
        The issue is that KK is sometimes nil. How could this possibly happen?
        There are 5 places where KK is set:
            TRAVEL[I]=LKIND*1024+TK[L]
                Where I is a shared key to KEY,
                    LKIND is the room you want to go to,
                    And TK[L] is the command ID to get there from the room you're in
                But sometimes LKIND is greater than 300 meaning it doesn't match a LONG room description ID.
                    In this case, we set COND[1 through 10] = 1 and then various indexes to 2.
                        What do these special indexes mean? Look like room IDs
                    IPLACE, IFIXED, and ICHAIN share lookup index I init to IPLT and IFIXT, ICHAIN init to 0
                        IPLACE are room IDs
                        IFIXED is boolean values
                        ICHAIN is all 0s initially
                    COND, ABB, and IOBJ linked by shared index
                        all init to 0
                        first 10 rooms COND=1, then certain rooms COND=2
                    Setup IPLACE value is IOBJ key and IOBJ value is IPLACE key (link the two tables)
                        Link ICHAIN in the same way to IPLACE but also create a chain
                    Then, we check all the items in IPLACE to see if any are 1 (in our possession)
                So what happens when we unlock the grate?
                    Words can either be:
                        Location/Direction (<1000)
                        Object/Person/Thing (>=1000,<2000)
                        Action (>=2000)
                    JOBJ==K equals 3, which is GRATE
                    J is the current room I'm in, 8
                    IPLACE[OBJID] is where the object is. If it's in my possession (-1) or in the same room as me (J==IPLACE[K]), I can use it
                    JVERB==4, which is OPEN or UNLOCK
                    KEYS==OBJID that could unlock, if in inventory or on ground...
                    PROP[GRATE] = 1 and PROP[Current Room ID (8)] = 1
                What happens if I use WAVE ROD?
                    So apparently, it is programmed in some things literally say "Does nothing" no matter what.
                    So I think it's safe to say, that it is impossible to 

            KK=K
            KK=STEXT[tonum(L)]
                L would have to be outside STEXT range
                STEXT index is the SHORT room description ID, and is equal to the line number it is on in the DAT file minus 1
            KK=LTEXT[tonum(L)]
                L would have to be outside LTEXT range
                LTEXT index is the LONG room descriptions ID, and is equal to the line number it is on in the DAT file minus 1
            KK=KEY[tonum(LOC)]
                LOC would have to be outside KEY range
                Mysterious KEY[4] position...
                KEY is room you're coming from, equal to shared key to TRAVEL to look up based on the command where you're trying to go
                    Using COND to determine whether you can go there
            KK=BTEXT[tonum(ILK)]
                ILK would have to be outside BTEXT range
            What do all these TEXTs mean?

            So if I want to get from room 17 to 27 (east to west side of fissure)

This is all good work and I am interested in what the variables mean, but, what if the solution is to change the encoding?
    So basically, eliminate the big int stuff, and instead we need to just comma separate the values.
    So, when we detect %1024, we just get the second value
    When we detect /1024, we get the first value
    So I undid it all, and WAVE ROD is still broken...