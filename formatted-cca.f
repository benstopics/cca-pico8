C ADVENTURES
     IMPLICIT INTEGER(A-Z)
     REAL RAN
     COMMON RTEXT,LLINE
     DIMENSION IOBJ(300),ICHAIN(100),IPLACE(100)
     1 ,IFIXED(100),COND(300),PROP(100),ABB(300),LLINE(1000,22)
     2 ,LTEXT(300),STEXT(300),KEY(300),DEFAULT(300),TRAVEL(1000)
     3 ,TK(25),KTAB(1000),ATAB(1000),BTEXT(200),DSEEN(10)
     4 ,DLOC(10),ODLOC(10),DTRAV(20),RTEXT(100),JSPKT(100)
     5 ,IPLT(100),IFIXT(100)

C READ THE PARAMETERS

     IF(SETUP.NE.0) GOTO 1
     SETUP=1
     KEYS=1
     LAMP=2
     GRATE=3
     ROD=5
     BIRD=7
     NUGGET=10
     SNAKE=11
     FOOD=19
     WATER=20
     AXE=21
     DATA(JSPKT(I),I=1,16)/24,29,0,31,0,31,38,38,42,42,43,46,77,71
     1 ,73,75/
     DATA(IPLT(I),I=1,20)/3,3,8,10,11,14,13,9,15,18,19,17,27,28,29
     1 ,30,0,0,3,3/
     DATA(IFIXT(I),I=1,20)/0,0,1,0,0,1,0,1,1,0,1,1,0,0,0,0,0,0,0,0/
     DATA(DTRAV(I),I=1,15)/36,28,19,30,62,60,41,27,17,15,19,28,36
     1 ,300,300/
     DO 1001 I=1,300
     STEXT(I)=0
     IF(I.LE.200) BTEXT(I)=0
     IF(I.LE.100)RTEXT(I)=0
1001 LTEXT(I)=0
     I=1
     CALL IFILE(1,'TEXT')
1002 READ(1,1003) IKIND
1003 FORMAT(G)
     GOTO(1100,1004,1004,1013,1020,1004,1004)(IKIND+1)
1004 READ(1,1005)JKIND,(LLINE(I,J),J=3,22)
1005 FORMAT(1G,20A5)
     IF(JKIND.EQ.-1) GOTO 1002
     DO 1006 K=1,20
     KK=K
     IF(LLINE(I,21-K).NE.' ') GOTO 1007
1006 CONTINUE
     STOP
1007 LLINE(I,2)=20-KK+1
     LLINE(I,1)=0
     IF(IKIND.EQ.6)GOTO 1023
     IF(IKIND.EQ.5)GOTO 1011
     IF(IKIND.EQ.1) GOTO 1008
     IF(STEXT(JKIND).NE.0) GOTO 1009
     STEXT(JKIND)=I
     GOTO 1010

1008 IF(LTEXT(JKIND).NE.0) GOTO 1009
     LTEXT(JKIND)=I
     GOTO 1010
1009 LLINE(I-1,1)=I
1010 I=I+1
     IF(I.NE.1000)GOTO 1004
     PAUSE 'TOO MANY LINES'

1011 IF(JKIND.LT.200)GOTO 1012
     IF(BTEXT(JKIND-100).NE.0)GOTO 1009
     BTEXT(JKIND-100)=I
     BTEXT(JKIND-200)=I
     GOTO 1010
1012 IF(BTEXT(JKIND).NE.0)GOTO 1009
     BTEXT(JKIND)=I
     GOTO 1010

1023 IF(RTEXT(JKIND).NE.0) GOTO 1009
     RTEXT(JKIND)=I
     GOTO 1010

1013 I=1
1014 READ(1,1015)JKIND,LKIND,(TK(L),L=1,10)
1015 FORMAT(12G)
     IF(JKIND.EQ.-1) GOTO 1002
     IF(KEY(JKIND).NE.0) GOTO 1016
     KEY(JKIND)=I
     GOTO 1017
1016 TRAVEL(I-1)=-TRAVEL(I-1)
1017 DO 1018 L=1,10
     IF(TK(L).EQ.0) GOTO 1019
     TRAVEL(I)=LKIND*1024+TK(L)
     I=I+1
     IF(I.EQ.1000) STOP
1018 CONTINUE
1019 TRAVEL(I-1)=-TRAVEL(I-1)
     GOTO 1014

1020 DO 1022 IU=1,1000
     READ(1,1021) KTAB(IU),ATAB(IU)
1021 FORMAT(G,A5)
     IF(KTAB(IU).EQ.-1)GOTO 1002
1022 CONTINUE
     PAUSE 'TOO MANY WORDS'


C TRAVEL = NEG IF LAST THIS SOURCE + DEST*1024 + KEYWORD

C COND  = 1 IF LIGHT,  2 IF DON T ASK QUESTION





1100 DO 1101 I=1,100
     IPLACE(I)=IPLT(I)
     IFIXED(I)=IFIXT(I)
1101 ICHAIN(I)=0

     DO 1102 I=1,300
     COND(I)=0
     ABB(I)=0
1102 IOBJ(I)=0
     DO 1103 I=1,10
1103 COND(I)=1
     COND(16)=2
     COND(20)=2
     COND(21)=2
     COND(22)=2
     COND(23)=2
     COND(24)=2
     COND(25)=2
     COND(26)=2
     COND(31)=2
     COND(32)=2
     COND(79)=2

     DO 1107 I=1,100
     KTEM=IPLACE(I)
     IF(KTEM.EQ.0)GOTO 1107
     IF(IOBJ(KTEM).NE.0) GOTO 1104
     IOBJ(KTEM)=I
     GO TO 1107
1104 KTEM=IOBJ(KTEM)
1105 IF(ICHAIN(KTEM).NE.0) GOTO 1106
     ICHAIN(KTEM)=I
     GOTO 1107
1106 KTEM=ICHAIN(KTEM)
     GOTO 1105
1107 CONTINUE
     IDWARF=0
     IFIRST=1
     IWEST=0
     ILONG=1
     IDETAL=0
     PAUSE 'INIT DONE'



1    CALL YES(65,1,0,YEA)
     L=1
     LOC=1
2    DO 73 I=1,3
     IF(ODLOC(I).NE.L.OR.DSEEN(I).EQ.0)GOTO 73
     L=LOC
     CALL SPEAK(2)
     GOTO 74
73   CONTINUE
74   LOC=L

C DWARF STUFF

     IF(IDWARF.NE.0) GOTO 60
     IF(LOC.EQ.15) IDWARF=1
     GOTO 71
60   IF(IDWARF.NE.1)GOTO 63
     IF(RAN(QZ).GT.0.05) GOTO 71
     IDWARF=2
     DO 61 I=1,3
     DLOC(I)=0
     ODLOC(I)=0
61   DSEEN(I)=0
     CALL SPEAK(3)
     ICHAIN(AXE)=IOBJ(LOC)
     IOBJ(LOC)=AXE
     IPLACE(AXE)=LOC
     GOTO 71

63   IDWARF=IDWARF+1
     ATTACK=0
     DTOT=0
     STICK=0
     DO 66 I=1,3
     IF(2*I+IDWARF.LT.8)GOTO 66
     IF(2*I+IDWARF.GT.23.AND.DSEEN(I).EQ.0)GOTO 66
     ODLOC(I)=DLOC(I)
     IF(DSEEN(I).NE.0.AND.LOC.GT.14)GOTO 65
     DLOC(I)=DTRAV(I*2+IDWARF-8)
     DSEEN(I)=0
     IF(DLOC(I).NE.LOC.AND.ODLOC(I).NE.LOC) GOTO 66
65   DSEEN(I)=1
     DLOC(I)=LOC
     DTOT=DTOT+1
     IF(ODLOC(I).NE.DLOC(I)) GOTO 66
     ATTACK=ATTACK+1
     IF(RAN(QZ).LT.0.1) STICK=STICK+1
66   CONTINUE
     IF(DTOT.EQ.0) GOTO 71
     IF(DTOT.EQ.1)GOTO 75
     TYPE 67,DTOT
67   FORMAT(' THERE ARE ',I2,' THREATENING LITTLE DWARVES IN THE
     1  ROOM WITH YOU.',/)
     GOTO 77
75   CALL SPEAK(4)
77   IF(ATTACK.EQ.0)GOTO 71
     IF(ATTACK.EQ.1)GOTO 79
     TYPE 78,ATTACK
78   FORMAT(' ',I2,' OF THEM THROW KNIVES AT YOU!',/)
     GOTO 81
79   CALL SPEAK(5)
     CALL SPEAK(52+STICK)
     GOTO(71,83)(STICK+1)

81   IF(STICK.EQ.0) GOTO 69
     IF(STICK.EQ.1)GOTO 82
     TYPE 68,STICK
68   FORMAT(' ',I2,' OF THEM GET YOU.',/)
     GOTO 83
82   CALL SPEAK(6)
83   PAUSE 'GAMES OVER'
     GOTO 71
69   CALL SPEAK(7)

C PLACE DESCRIPTOR



71   KK=STEXT(L)
     IF(ABB(L).EQ.0.OR.KK.EQ.0)KK=LTEXT(L)
     IF(KK.EQ.0) GOTO 7
4    TYPE 5,(LLINE(KK,JJ),JJ=3,LLINE(KK,2))
5    FORMAT(20A5)
     KK=KK+1
     IF(LLINE(KK-1,1).NE.0) GOTO 4
     TYPE 6
6    FORMAT(/)
7    IF(COND(L).EQ.2)GOTO 8
     IF(LOC.EQ.33.AND.RAN(QZ).LT.0.25)CALL SPEAK(8)
     J=L
     GOTO 2000

C GO GET A NEW LOCATION

8    KK=KEY(LOC)
     IF(KK.EQ.0)GOTO 19
     IF(K.EQ.57)GOTO 32
     IF(K.EQ.67)GOTO 40
     IF(K.EQ.8)GOTO 12
     LOLD=L
9    LL=TRAVEL(KK)
     IF(LL.LT.0) LL=-LL
     IF(1.EQ.MOD(LL,1024))GOTO 10
     IF(K.EQ.MOD(LL,1024))GOTO 10
     IF(TRAVEL(KK).LT.0)GOTO 11
     KK=KK+1
     GOTO 9
12   TEMP=LOLD
     LOLD=L
     L=TEMP
     GOTO 21
10   L=LL/1024
     GOTO 21
11   JSPK=12
     IF(K.GE.43.AND.K.LE.46)JSPK=9
     IF(K.EQ.29.OR.K.EQ.30)JSPK=9
     IF(K.EQ.7.OR.K.EQ.8.OR.K.EQ.36.OR.K.EQ.37.OR.K.EQ.68)
     1 JSPK=10
     IF(K.EQ.11.OR.K.EQ.19)JSPK=11
     IF(JVERB.EQ.1)JSPK=59
     IF(K.EQ.48)JSPK=42
     IF(K.EQ.17)JSPK=80
     CALL SPEAK(JSPK)
     GOTO 2
19   CALL SPEAK(13)
     L=LOC
     IF(IFIRST.EQ.0) CALL SPEAK(14)
21   IF(L.LT.300)GOTO 2
     IL=L-300+1
     GOTO(22,23,24,25,26,31,27,28,29,30,33,34,36,37)IL
     GOTO 2

22   L=6
     IF(RAN(QZ).GT.0.5) L=5
     GOTO 2
23   L=23
     IF(PROP(GRATE).NE.0) L=9
     GOTO 2
24   L=9
     IF(PROP(GRATE).NE.0)L=8
     GOTO 2
25   L=20
     IF(IPLACE(NUGGET).NE.-1)L=15
     GOTO 2
26   L=22
     IF(IPLACE(NUGGET).NE.-1) L=14
     GOTO 2
27   L=27
     IF(PROP(12).EQ.0)L=31
     GOTO 2
28   L=28
     IF(PROP(SNAKE).EQ.0)L=32
     GOTO 2
29   L=29
     IF(PROP(SNAKE).EQ.0) L=32
     GOTO 2
30   L=30
     IF(PROP(SNAKE).EQ.0) L=32
     GOTO 2
31   PAUSE 'GAME IS OVER'
     GOTO 1100
32   IF(IDETAL.LT.3)CALL SPEAK(15)
     IDETAL=IDETAL+1
     L=LOC
     ABB(L)=0
     GOTO 2
33   L=8
     IF(PROP(GRATE).EQ.0) L=9
     GOTO 2
34   IF(RAN(QZ).GT.0.2)GOTO 35
     L=68
     GOTO 2
35   L=65
38   CALL SPEAK(56)
     GOTO 2
36   IF(RAN(QZ).GT.0.2)GOTO 35
     L=39
     IF(RAN(QZ).GT.0.5)L=70
     GOTO 2
37   L=66
     IF(RAN(QZ).GT.0.4)GOTO 38
     L=71
     IF(RAN(QZ).GT.0.25)L=72
     GOTO 2
39   L=66
     IF(RAN(QZ).GT.0.2)GOTO 38
     L=77
     GOTO 2
40   IF(LOC.LT.8)CALL SPEAK(57)
     IF(LOC.GE.8)CALL SPEAK(58)
     L=LOC
     GOTO 2



C DO NEXT INPUT


2000 LTRUBL=0
     LOC=J
     ABB(J)=MOD((ABB(J)+1),5)
     IDARK=0
     IF(MOD(COND(J),2).EQ.1) GOTO 2003
     IF((IPLACE(2).NE.J).AND.(IPLACE(2).NE.-1)) GOTO 2001
     IF(PROP(2).EQ.1)GOTO 2003
2001 CALL SPEAK(16)
     IDARK=1


2003 I=IOBJ(J)
2004 IF(I.EQ.0) GOTO 2011
     IF(((I.EQ.6).OR.(I.EQ.9)).AND.(IPLACE(10).EQ.-1))GOTO 2008
     ILK=I
     IF(PROP(I).NE.0) ILK=I+100
     KK=BTEXT(ILK)
     IF(KK.EQ.0) GOTO 2008
2005 TYPE 2006,(LLINE(KK,JJ),JJ=3,LLINE(KK,2))
2006 FORMAT(20A5)
     KK=KK+1
     IF(LLINE(KK-1,1).NE.0) GOTO 2005
     TYPE 2007
2007 FORMAT(/)
2008 I=ICHAIN(I)
     GOTO 2004



C K=1 MEANS ANY INPUT


2012 A=WD2
     B=' '
     TWOWDS=0
     GOTO 2021

2009 K=54
2010 JSPK=K
5200 CALL SPEAK(JSPK)

2011 JVERB=0
     JOBJ=0
     TWOWDS=0

2020 CALL GETIN(TWOWDS,A,WD2,B)
     K=70
     IF(A.EQ.'ENTER'.AND.(WD2.EQ.'STREA'.OR.WD2.EQ.'WATER'))GOTO 2010
     IF(A.EQ.'ENTER'.AND.TWOWDS.NE.0)GOTO 2012
2021 IF(A.NE.'WEST')GOTO 2023
     IWEST=IWEST+1
     IF(IWEST.NE.10)GOTO 2023
     CALL SPEAK(17)
2023 DO 2024 I=1,1000
     IF(KTAB(I).EQ.-1)GOTO 3000
     IF(ATAB(I).EQ.A)GOTO 2025
2024 CONTINUE
     PAUSE 'ERROR 6'
2025 K=MOD(KTAB(I),1000)
     KQ=KTAB(I)/1000+1
     GOTO (5014,5000,2026,2010)KQ
     PAUSE 'NO NO'
2026 JVERB=K
     JSPK=JSPKT(JVERB)
     IF(TWOWDS.NE.0)GOTO 2028
     IF(JOBJ.EQ.0)GOTO 2036
2027 GOTO(9000,5066,3000,5031,2009,5031,9404,9406,5081,5200,
     1 5200,5300,5506,5502,5504,5505)JVERB
     PAUSE 'ERROR 5'


2028 A=WD2
     B=' '
     TWOWDS=0
     GOTO 2023

3000 JSPK=60
     IF(RAN(QZ).GT.0.8)JSPK=61
     IF(RAN(QZ).GT.0.8)JSPK=13
     CALL SPEAK(JSPK)
     LTRUBL=LTRUBL+1
     IF(LTRUBL.NE.3)GOTO 2020
     IF(J.NE.13.OR.IPLACE(7).NE.13.OR.IPLACE(5).NE.-1)GOTO 2032
     CALL YES(18,19,54,YEA)
     GOTO 2033
2032 IF(J.NE.19.OR.PROP(11).NE.0.OR.IPLACE(7).EQ.-1)GOTO 2034
     CALL YES(20,21,54,YEA)
     GOTO 2033
2034 IF(J.NE.8.OR.PROP(GRATE).NE.0)GOTO 2035
     CALL YES(62,63,54,YEA)
2033 IF(YEA.EQ.0)GOTO 2011
     GOTO 2020
2035 IF(IPLACE(5).NE.J.AND.IPLACE(5).NE.-1)GOTO 2020
     IF(JOBJ.NE.5)GOTO 2020
     CALL SPEAK(22)
     GOTO 2020


2036 GOTO(2037,5062,5062,9403,2009,9403,9404,9406,5062,5062,
     1 5200,5300,5062,5062,5062,5062)JVERB
     PAUSE 'OOPS'
2037 IF((IOBJ(J).EQ.0).OR.(ICHAIN(IOBJ(J)).NE.0)) GOTO 5062
     DO 5312 I=1,3
     IF(DSEEN(I).NE.0)GOTO 5062
5312 CONTINUE
     JOBJ=IOBJ(J)
     GOTO 2027
5062 IF(B.NE.' ')GOTO 5333
     TYPE 5063,A
5063 FORMAT('  ',A5,' WHAT?',/)
     GOTO 2020

5333 TYPE 5334,A,B
5334 FORMAT(' ',2A5,' WHAT?',/)
     GOTO 2020
5014 IF(IDARK.EQ.0) GOTO 8

     IF(RAN(QZ).GT.0.25) GOTO 8
5017 CALL SPEAK(23)
     PAUSE 'GAME IS OVER'
     GOTO 2011



5000 JOBJ=K
     IF(TWOWDS.NE.0)GOTO 2028
     IF((J.EQ.IPLACE(K)).OR.(IPLACE(K).EQ.-1)) GOTO 5004
     IF(K.NE.GRATE)GOTO 502
     IF((J.EQ.1).OR.(J.EQ.4).OR.(J.EQ.7))GOTO 5098
     IF((J.GT.9).AND.(J.LT.15))GOTO 5097
502  IF(B.NE.' ')GOTO 5316
     TYPE 5005,A
5005 FORMAT(' I SEE NO ',A5,' HERE.',/)
     GOTO 2011
5316 TYPE 5317,A,B
5317 FORMAT(' I SEE NO ',2A5,' HERE.'/)
     GOTO 2011
5098 K=49
     GOTO 5014
5097 K=50
     GOTO 5014
5004 JOBJ=K
     IF(JVERB.NE.0)GOTO 2027


5064 IF(B.NE.' ')GOTO 5314
     TYPE 5001,A
5001 FORMAT(' WHAT DO YOU WANT TO DO WITH THE ',A5,'?',/)
     GOTO 2020
5314 TYPE 5315,A,B
5315 FORMAT(' WHAT DO YOU WANT TO DO WITH THE ',2A5,'?',/)
     GOTO 2020

C CARRY

9000 IF(JOBJ.EQ.18)GOTO 2009
     IF(IPLACE(JOBJ).NE.J) GOTO 5200
9001 IF(IFIXED(JOBJ).EQ.0)GOTO 9002
     CALL SPEAK(25)
     GOTO 2011
9002 IF(JOBJ.NE.BIRD)GOTO 9004
     IF(IPLACE(ROD).NE.-1)GOTO 9003
     CALL SPEAK(26)
     GOTO 2011
9003 IF((IPLACE(4).EQ.-1).OR.(IPLACE(4).EQ.J)) GOTO 9004
     CALL SPEAK(27)
     GOTO 2011
9004 IPLACE(JOBJ)=-1
9005 IF(IOBJ(J).NE.JOBJ) GOTO 9006
     IOBJ(J)=ICHAIN(JOBJ)
     GOTO 2009
9006 ITEMP=IOBJ(J)
9007 IF(ICHAIN(ITEMP).EQ.(JOBJ)) GOTO 9008
     ITEMP=ICHAIN(ITEMP)
     GOTO 9007
9008 ICHAIN(ITEMP)=ICHAIN(JOBJ)
     GOTO 2009


C LOCK, UNLOCK, NO OBJECT YET

9403 IF((J.EQ.8).OR.(J.EQ.9))GOTO 5105
5032 CALL SPEAK(28)
     GOTO 2011
5105 JOBJ=GRATE
     GOTO 2027

C DISCARD OBJECT

5066 IF(JOBJ.EQ.18)GOTO 2009
     IF(IPLACE(JOBJ).NE.-1) GOTO 5200
5012 IF((JOBJ.NE.BIRD).OR.(J.NE.19).OR.(PROP(11).EQ.1))GOTO 9401
     CALL SPEAK(30)
     PROP(11)=1
5160 ICHAIN(JOBJ)=IOBJ(J)
     IOBJ(J)=JOBJ
     IPLACE(JOBJ)=J
     GOTO 2011

9401 CALL SPEAK(54)
     GOTO 5160

C LOCK,UNLOCK OBJECT

5031 IF(IPLACE(KEYS).NE.-1.AND.IPLACE(KEYS).NE.J)GOTO 5200
     IF(JOBJ.NE.4)GOTO 5102
     CALL SPEAK(32)
     GOTO 2011
5102 IF(JOBJ.NE.KEYS)GOTO 5104
     CALL SPEAK(55)
     GOTO 2011
5104 IF(JOBJ.EQ.GRATE)GOTO 5107
     CALL SPEAK(33)
     GOTO 2011
5107 IF(JVERB.EQ.4) GOTO 5033
     IF(PROP(GRATE).NE.0)GOTO 5034
     CALL SPEAK(34)
     GOTO 2011
5034 CALL SPEAK(35)
     PROP(GRATE)=0
     PROP(8)=0
     GOTO 2011
5033 IF(PROP(GRATE).EQ.0)GOTO 5109
     CALL SPEAK(36)
     GOTO 2011
5109 CALL SPEAK(37)
     PROP(GRATE)=1
     PROP(8)=1
     GOTO 2011



C LIGHT LAMP

9404 IF((IPLACE(2).NE.J).AND.(IPLACE(2).NE.-1))GOTO 5200
     PROP(2)=1
     IDARK=0
     CALL SPEAK(39)
     GOTO 2011

C LAMP OFF

9406 IF((IPLACE(2).NE.J).AND.(IPLACE(2).NE.-1)) GOTO 5200
     PROP(2)=0
     CALL SPEAK(40)
     GOTO 2011

C STRIKE

5081 IF(JOBJ.NE.12)GOTO 5200
     PROP(12)=1
     GOTO 2003

C ATTACK

5300 DO 5313 ID=1,3
     IID=ID
     IF(DSEEN(ID).NE.0)GOTO 5307
5313 CONTINUE
     IF(JOBJ.EQ.0)GOTO 5062
     IF(JOBJ.EQ.SNAKE) GOTO 5200
     IF(JOBJ.EQ.BIRD) GOTO 5302
     CALL SPEAK(44)
     GOTO 2011
5302 CALL SPEAK(45)
     IPLACE(JOBJ)=300
     GOTO 9005

5307 IF(RAN(QZ).GT.0.4) GOTO 5309
     DSEEN(IID)=0
     ODLOC(IID)=0
     DLOC(IID)=0
     CALL SPEAK(47)
     GOTO 5311
5309 CALL SPEAK(48)
5311 K=21
     GOTO 5014

C EAT

5502 IF((IPLACE(FOOD).NE.J.AND.IPLACE(FOOD).NE.-1).OR.PROP(FOOD).NE.0
     1 .OR.JOBJ.NE.FOOD)GOTO 5200
     PROP(FOOD)=1
5501 JSPK=72
     GOTO 5200

C DRINK

5504 IF((IPLACE(WATER).NE.J.AND.IPLACE(WATER).NE.-1)
     1 .OR.PROP(WATER).NE.0.OR.JOBJ.NE.WATER) GOTO 5200
     PROP(WATER)=1
     JSPK=74
     GOTO 5200

C RUB

5505 IF(JOBJ.NE.LAMP)JSPK=76
     GOTO 5200

C POUR

5506 IF(JOBJ.NE.WATER)JSPK=78
     PROP(WATER)=1
     GOTO 5200



     END


     SUBROUTINE SPEAK(IT)
     IMPLICIT INTEGER(A-Z)
     COMMON RTEXT,LLINE
     DIMENSION RTEXT(100),LLINE(1000,22)

     KKT=RTEXT(IT)
     IF(KKT.EQ.0)RETURN
999  TYPE 998, (LLINE(KKT,JJT),JJT=3,LLINE(KKT,2))
998  FORMAT(20A5)
     KKT=KKT+1
     IF(LLINE(KKT-1,1).NE.0)GOTO 999
997  TYPE 996
996  FORMAT(/)
     RETURN
     END


     SUBROUTINE GETIN(TWOW,B,C,D)
     IMPLICIT INTEGER(A-Z)
     DIMENSION A(5),M2(6)
     DATA M2/"4000000000,"20000000,"100000,"400,"2,0/
6    ACCEPT 1,(A(I), I=1,4)
1    FORMAT(4A5)
     TWOW=0
     S=0
     B=A(1)
     DO 2 J=1,4
     DO 2 K=1,5
     MASK1="774000000000
     IF(K.NE.1) MASK1="177*M2(K)
     IF(((A(J).XOR."201004020100).AND.MASK1).EQ.0)GOTO 3
     IF(S.EQ.0) GOTO 2
     TWOW=1
     CALL SHIFT(A(J),7*(K-1),XX)
     CALL SHIFT(A(J+1),7*(K-6),YY)
     MASK=-M2(6-K)
     C=(XX.AND.MASK)+(YY.AND.(-2-MASK))
     GOTO 4
3    IF(S.EQ.1) GOTO 2
     S=1
     IF(J.EQ.1) B=(B.AND.-M2(K)).OR.("201004020100.AND.
     1 (-M2(K).XOR.-1))
2    CONTINUE
4    D=A(2)
     RETURN
     END

     SUBROUTINE YES(X,Y,Z,YEA)
     IMPLICIT INTEGER(A-Z)
     CALL SPEAK(X)
     CALL GETIN(JUNK,IA1,JUNK,IB1)
     IF(IA1.EQ.'NO'.OR.IA1.EQ.'N') GOTO 1
     YEA=1
     IF(Y.NE.0) CALL SPEAK(Y)
     RETURN
1    YEA=0
     IF(Z.NE.0)CALL SPEAK(Z)
     RETURN
     END



     SUBROUTINE SHIFT (VAL,DIST,RES)
     IMPLICIT INTEGER (A-Z)
     RES=VAL
     IF(DIST)10,20,30
10   IDIST=-DIST
     DO 11 I=1,IDIST
     J = 0
     IF (RES.LT.0) J="200000000000
11   RES = ((RES.AND."377777777777)/2) + J
20   RETURN
30   DO 31 I=1,DIST
     J = 0
     IF ((RES.AND."200000000000).NE.0) J="400000000000
31   RES = (RES.AND."177777777777)*2 + J
     RETURN
     END
