
function INIT_ARR1(size)
local a = {}
for i=1,size do
  a[i]=0
end
return a
end
function INIT_ARR2(size1, size2)
local a = {}
for i=1,size1 do
    a[i] = {}
    for j=1,size2 do
    a[i][j]=0
    end
end
return a
end
function READ_KEY()
end
function PAUSE(msg)
end
function FORTRAN_READ(type, units)
    return {}
end
function FORTRAN_WRITE(value)
end
function SPEAK(IT)
 RTEXT = INIT_ARR1(100)
 LLINE = INIT_ARR2(1000,22)
KKT=RTEXT[IT]
if ((KKT==0)) then
if true then return end
end
::l00999::
for JJT=3,LLINE[KKT][2],1 do
FORTRAN_WRITE(LLINE[KKT][JJT])
end
KKT=(KKT+1)
if ((LLINE[(KKT-1)][1]~=0)) then
goto l00999
end
::l00997::
FORTRAN_WRITE("\n")
if true then return end
end
function GETIN(TWOW,B,C,D)
 A = INIT_ARR1(5)
 M2 = INIT_ARR1(6)
 assign_values00001 = {536870912,4194304,32768,256,2,0}
for assign_i00002=1,6,1 do
M2=assign_values00001[assign_i00002]
end
::l00006::
READ_KEY()TWOW=0
S=0
B=A[1]
::c00003::
for J=1,4,1 do
::c00004::
for K=1,5,1 do
MASK1=68182605824
if ((K~=1)) then
MASK1=(127*M2[K])
end
if ((((A[J]~17315143744)&MASK1)==0)) then
goto l00003
end
if ((S==0)) then
goto l00002
end
TWOW=1
SHIFT(A[J],(7*(K-1)),XX)
SHIFT(A[(J+1)],(7*(K-6)),YY)
MASK=-M2[(6-K)]
C=((XX&MASK)+(YY&(-2-MASK)))
goto l00004
::l00003::
if ((S==1)) then
goto l00002
end
S=1
if ((J==1)) then
B=((B&-M2[K])|(17315143744&(-M2[K]~-1)))
end
::l00002::
goto c00004
end
end
::l00004::
D=A[2]
if true then return end
end
function YES(X,Y,Z,YEA)
SPEAK(X)
GETIN(JUNK,IA1,JUNK,IB1)
if (((IA1=="NO")|(IA1=="N"))) then
goto l00001
end
YEA=1
if ((Y~=0)) then
SPEAK(Y)
end
if true then return end
::l00001::
YEA=0
if ((Z~=0)) then
SPEAK(Z)
end
if true then return end
end
function SHIFT(VAL,DIST,RES)
RES=VAL
if (DIST<0) then
goto l00010
elseif (DIST==0) then
goto l00020
else
goto l00030
end
::l00010::
IDIST=-DIST
::c00005::
for I=1,IDIST,1 do
J=0
if ((RES<0)) then
J=17179869184
end
::l00011::
RES=(((RES&34359738367)/2)+J)
end
::l00020::
if true then return end
::l00030::
::c00006::
for I=1,DIST,1 do
J=0
if (((RES&17179869184)~=0)) then
J=34359738368
end
::l00031::
RES=((RES&17179869183)*(2+J))
end
if true then return end
end
 IOBJ = INIT_ARR1(300)
 ICHAIN = INIT_ARR1(100)
 IPLACE = INIT_ARR1(100)
 IFIXED = INIT_ARR1(100)
 COND = INIT_ARR1(300)
 PROP = INIT_ARR1(100)
 ABB = INIT_ARR1(300)
 LLINE = INIT_ARR2(1000,22)
 LTEXT = INIT_ARR1(300)
 STEXT = INIT_ARR1(300)
 KEY = INIT_ARR1(300)
 DEFAULT = INIT_ARR1(300)
 TRAVEL = INIT_ARR1(1000)
 TK = INIT_ARR1(25)
 KTAB = INIT_ARR1(1000)
 ATAB = INIT_ARR1(1000)
 BTEXT = INIT_ARR1(200)
 DSEEN = INIT_ARR1(10)
 DLOC = INIT_ARR1(10)
 ODLOC = INIT_ARR1(10)
 DTRAV = INIT_ARR1(20)
 RTEXT = INIT_ARR1(100)
 JSPKT = INIT_ARR1(100)
 IPLT = INIT_ARR1(100)
 IFIXT = INIT_ARR1(100)
if ((SETUP~=0)) then
goto l00001
end
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
 assign_values00007 = {24,29,0,31,0,31,38,38,42,42,43,46,77,71,73,75}
for I=1,16,1 do
JSPKT[I]=assign_values00007[I]
end
 assign_values00008 = {3,3,8,10,11,14,13,9,15,18,19,17,27,28,29,30,0,0,3,3}
for I=1,20,1 do
IPLT[I]=assign_values00008[I]
end
 assign_values00009 = {0,0,1,0,0,1,0,1,1,0,1,1,0,0,0,0,0,0,0,0}
for I=1,20,1 do
IFIXT[I]=assign_values00009[I]
end
 assign_values00010 = {36,28,19,30,62,60,41,27,17,15,19,28,36,300,300}
for I=1,15,1 do
DTRAV[I]=assign_values00010[I]
end
::c00011::
for I=1,300,1 do
STEXT[I]=0
if ((I<=200)) then
BTEXT[I]=0
end
if ((I<=100)) then
RTEXT[I]=0
end
::l01001::
LTEXT[I]=0
end
I=1
::l01002::
 read_values00012={FORTRAN_READ("G", 1)}
 write_i00013=1
IKIND=read_values00012[write_i00013]
write_i00013 = write_i00013 + 1
 plex00014 = (IKIND+1)
if (plex00014==1) then
goto l01100
elseif (plex00014==2) then
goto l01004
elseif (plex00014==3) then
goto l01004
elseif (plex00014==4) then
goto l01013
elseif (plex00014==5) then
goto l01020
elseif (plex00014==6) then
goto l01004
else
goto l01004
end
::l01004::
 read_values00015={FORTRAN_READ("G", 1),table.unpack(FORTRAN_READ("A5", 20))}
 write_i00016=1
JKIND=read_values00015[write_i00016]
write_i00016 = write_i00016 + 1
for J=3,22,1 do
LLINE[I][J]=read_values00015[J + write_i00016]
end
write_i00016 = write_i00016 + 1
if ((JKIND==-1)) then
goto l01002
end
::c00017::
for K=1,20,1 do
KK=K
if ((LLINE[I][(21-K)]~=" ")) then
goto l01007
end
::l01006::
goto c00017
end
os.exit()
::l01007::
LLINE[I][2]=((20-KK)+1)
LLINE[I][1]=0
if ((IKIND==6)) then
goto l01023
end
if ((IKIND==5)) then
goto l01011
end
if ((IKIND==1)) then
goto l01008
end
if ((STEXT[JKIND]~=0)) then
goto l01009
end
STEXT[JKIND]=I
goto l01010
::l01008::
if ((LTEXT[JKIND]~=0)) then
goto l01009
end
LTEXT[JKIND]=I
goto l01010
::l01009::
LLINE[(I-1)][1]=I
::l01010::
I=(I+1)
if ((I~=1000)) then
goto l01004
end
PAUSE("TOO MANY LINES")
::l01011::
if ((JKIND<200)) then
goto l01012
end
if ((BTEXT[(JKIND-100)]~=0)) then
goto l01009
end
BTEXT[(JKIND-100)]=I
BTEXT[(JKIND-200)]=I
goto l01010
::l01012::
if ((BTEXT[JKIND]~=0)) then
goto l01009
end
BTEXT[JKIND]=I
goto l01010
::l01023::
if ((RTEXT[JKIND]~=0)) then
goto l01009
end
RTEXT[JKIND]=I
goto l01010
::l01013::
I=1
::l01014::
 read_values00018={table.unpack(FORTRAN_READ("G", 12))}
 write_i00019=1
JKIND=read_values00018[write_i00019]
write_i00019 = write_i00019 + 1
LKIND=read_values00018[write_i00019]
write_i00019 = write_i00019 + 1
for L=1,10,1 do
TK[L]=read_values00018[L + write_i00019]
end
write_i00019 = write_i00019 + 1
if ((JKIND==-1)) then
goto l01002
end
if ((KEY[JKIND]~=0)) then
goto l01016
end
KEY[JKIND]=I
goto l01017
::l01016::
TRAVEL[(I-1)]=-TRAVEL[(I-1)]
::l01017::
::c00020::
for L=1,10,1 do
if ((TK[L]==0)) then
goto l01019
end
TRAVEL[I]=(LKIND*(1024+TK[L]))
I=(I+1)
if ((I==1000)) then
os.exit()
end
::l01018::
goto c00020
end
::l01019::
TRAVEL[(I-1)]=-TRAVEL[(I-1)]
goto l01014
::l01020::
::c00021::
for IU=1,1000,1 do
 read_values00022={FORTRAN_READ("G", 1),FORTRAN_READ("A5", 1)}
 write_i00023=1
KTAB[IU]=read_values00022[write_i00023]
write_i00023 = write_i00023 + 1
ATAB[IU]=read_values00022[write_i00023]
write_i00023 = write_i00023 + 1
if ((KTAB[IU]==-1)) then
goto l01002
end
::l01022::
goto c00021
end
PAUSE("TOO MANY WORDS")
::l01100::
::c00024::
for I=1,100,1 do
IPLACE[I]=IPLT[I]
IFIXED[I]=IFIXT[I]
::l01101::
ICHAIN[I]=0
end
::c00025::
for I=1,300,1 do
COND[I]=0
ABB[I]=0
::l01102::
IOBJ[I]=0
end
::c00026::
for I=1,10,1 do
::l01103::
COND[I]=1
end
COND[16]=2
COND[20]=2
COND[21]=2
COND[22]=2
COND[23]=2
COND[24]=2
COND[25]=2
COND[26]=2
COND[31]=2
COND[32]=2
COND[79]=2
::c00027::
for I=1,100,1 do
KTEM=IPLACE[I]
if ((KTEM==0)) then
goto l01107
end
if ((IOBJ[KTEM]~=0)) then
goto l01104
end
IOBJ[KTEM]=I
goto l01107
::l01104::
KTEM=IOBJ[KTEM]
::l01105::
if ((ICHAIN[KTEM]~=0)) then
goto l01106
end
ICHAIN[KTEM]=I
goto l01107
::l01106::
KTEM=ICHAIN[KTEM]
goto l01105
::l01107::
goto c00027
end
IDWARF=0
IFIRST=1
IWEST=0
ILONG=1
IDETAL=0
PAUSE("INIT DONE")
::l00001::
YES(65,1,0,YEA)
L=1
LOC=1
::l00002::
::c00028::
for I=1,3,1 do
if (((ODLOC[I]~=L)|(DSEEN[I]==0))) then
goto l00073
end
L=LOC
SPEAK(2)
goto l00074
::l00073::
goto c00028
end
::l00074::
LOC=L
if ((IDWARF~=0)) then
goto l00060
end
if ((LOC==15)) then
IDWARF=1
end
goto l00071
::l00060::
if ((IDWARF~=1)) then
goto l00063
end
if ((math.random()>0.05)) then
goto l00071
end
IDWARF=2
::c00029::
for I=1,3,1 do
DLOC[I]=0
ODLOC[I]=0
::l00061::
DSEEN[I]=0
end
SPEAK(3)
ICHAIN[AXE]=IOBJ[LOC]
IOBJ[LOC]=AXE
IPLACE[AXE]=LOC
goto l00071
::l00063::
IDWARF=(IDWARF+1)
ATTACK=0
DTOT=0
STICK=0
::c00030::
for I=1,3,1 do
if (((2*(I+IDWARF))<8)) then
goto l00066
end
if ((((2*(I+IDWARF))>23)&(DSEEN[I]==0))) then
goto l00066
end
ODLOC[I]=DLOC[I]
if (((DSEEN[I]~=0)&(LOC>14))) then
goto l00065
end
DLOC[I]=DTRAV[(I*((2+IDWARF)-8))]
DSEEN[I]=0
if (((DLOC[I]~=LOC)&(ODLOC[I]~=LOC))) then
goto l00066
end
::l00065::
DSEEN[I]=1
DLOC[I]=LOC
DTOT=(DTOT+1)
if ((ODLOC[I]~=DLOC[I])) then
goto l00066
end
ATTACK=(ATTACK+1)
if ((math.random()<0.1)) then
STICK=(STICK+1)
end
::l00066::
goto c00030
end
if ((DTOT==0)) then
goto l00071
end
if ((DTOT==1)) then
goto l00075
end
FORTRAN_WRITE(" THERE ARE ")
FORTRAN_WRITE(DTOT)
FORTRAN_WRITE(" THREATENING LITTLE DWARVES IN THE ROOM WITH YOU.")
FORTRAN_WRITE("\n")
goto l00077
::l00075::
SPEAK(4)
::l00077::
if ((ATTACK==0)) then
goto l00071
end
if ((ATTACK==1)) then
goto l00079
end
FORTRAN_WRITE(" ")
FORTRAN_WRITE(ATTACK)
FORTRAN_WRITE(" OF THEM THROW KNIVES AT YOU!")
FORTRAN_WRITE("\n")
goto l00081
::l00079::
SPEAK(5)
SPEAK((52+STICK))
 plex00031 = (STICK+1)
if (plex00031==1) then
goto l00071
else
goto l00083
end
::l00081::
if ((STICK==0)) then
goto l00069
end
if ((STICK==1)) then
goto l00082
end
FORTRAN_WRITE(" ")
FORTRAN_WRITE(STICK)
FORTRAN_WRITE(" OF THEM GET YOU.")
FORTRAN_WRITE("\n")
goto l00083
::l00082::
SPEAK(6)
::l00083::
PAUSE("GAMES OVER")
goto l00071
::l00069::
SPEAK(7)
::l00071::
KK=STEXT[L]
if (((ABB[L]==0)|(KK==0))) then
KK=LTEXT[L]
end
if ((KK==0)) then
goto l00007
end
::l00004::
for JJ=3,LLINE[KK][2],1 do
FORTRAN_WRITE(LLINE[KK][JJ])
end
KK=(KK+1)
if ((LLINE[(KK-1)][1]~=0)) then
goto l00004
end
FORTRAN_WRITE("\n")
::l00007::
if ((COND[L]==2)) then
goto l00008
end
if (((LOC==33)&(math.random()<0.25))) then
SPEAK(8)
end
J=L
goto l02000
::l00008::
KK=KEY[LOC]
if ((KK==0)) then
goto l00019
end
if ((K==57)) then
goto l00032
end
if ((K==67)) then
goto l00040
end
if ((K==8)) then
goto l00012
end
LOLD=L
::l00009::
LL=TRAVEL[KK]
if ((LL<0)) then
LL=-LL
end
if ((1==(LL%1024))) then
goto l00010
end
if ((K==(LL%1024))) then
goto l00010
end
if ((TRAVEL[KK]<0)) then
goto l00011
end
KK=(KK+1)
goto l00009
::l00012::
TEMP=LOLD
LOLD=L
L=TEMP
goto l00021
::l00010::
L=(LL/1024)
goto l00021
::l00011::
JSPK=12
if (((K>=43)&(K<=46))) then
JSPK=9
end
if (((K==29)|(K==30))) then
JSPK=9
end
if (((K==7)|((K==8)|((K==36)|((K==37)|(K==68)))))) then
JSPK=10
end
if (((K==11)|(K==19))) then
JSPK=11
end
if ((JVERB==1)) then
JSPK=59
end
if ((K==48)) then
JSPK=42
end
if ((K==17)) then
JSPK=80
end
SPEAK(JSPK)
goto l00002
::l00019::
SPEAK(13)
L=LOC
if ((IFIRST==0)) then
SPEAK(14)
end
::l00021::
if ((L<300)) then
goto l00002
end
IL=((L-300)+1)
 plex00032 = IL
if (plex00032==1) then
goto l00022
elseif (plex00032==2) then
goto l00023
elseif (plex00032==3) then
goto l00024
elseif (plex00032==4) then
goto l00025
elseif (plex00032==5) then
goto l00026
elseif (plex00032==6) then
goto l00031
elseif (plex00032==7) then
goto l00027
elseif (plex00032==8) then
goto l00028
elseif (plex00032==9) then
goto l00029
elseif (plex00032==10) then
goto l00030
elseif (plex00032==11) then
goto l00033
elseif (plex00032==12) then
goto l00034
elseif (plex00032==13) then
goto l00036
else
goto l00037
end
goto l00002
::l00022::
L=6
if ((math.random()>0.5)) then
L=5
end
goto l00002
::l00023::
L=23
if ((PROP[GRATE]~=0)) then
L=9
end
goto l00002
::l00024::
L=9
if ((PROP[GRATE]~=0)) then
L=8
end
goto l00002
::l00025::
L=20
if ((IPLACE[NUGGET]~=-1)) then
L=15
end
goto l00002
::l00026::
L=22
if ((IPLACE[NUGGET]~=-1)) then
L=14
end
goto l00002
::l00027::
L=27
if ((PROP[12]==0)) then
L=31
end
goto l00002
::l00028::
L=28
if ((PROP[SNAKE]==0)) then
L=32
end
goto l00002
::l00029::
L=29
if ((PROP[SNAKE]==0)) then
L=32
end
goto l00002
::l00030::
L=30
if ((PROP[SNAKE]==0)) then
L=32
end
goto l00002
::l00031::
PAUSE("GAME IS OVER")
goto l01100
::l00032::
if ((IDETAL<3)) then
SPEAK(15)
end
IDETAL=(IDETAL+1)
L=LOC
ABB[L]=0
goto l00002
::l00033::
L=8
if ((PROP[GRATE]==0)) then
L=9
end
goto l00002
::l00034::
if ((math.random()>0.2)) then
goto l00035
end
L=68
goto l00002
::l00035::
L=65
::l00038::
SPEAK(56)
goto l00002
::l00036::
if ((math.random()>0.2)) then
goto l00035
end
L=39
if ((math.random()>0.5)) then
L=70
end
goto l00002
::l00037::
L=66
if ((math.random()>0.4)) then
goto l00038
end
L=71
if ((math.random()>0.25)) then
L=72
end
goto l00002
::l00039::
L=66
if ((math.random()>0.2)) then
goto l00038
end
L=77
goto l00002
::l00040::
if ((LOC<8)) then
SPEAK(57)
end
if ((LOC>=8)) then
SPEAK(58)
end
L=LOC
goto l00002
::l02000::
LTRUBL=0
LOC=J
ABB[J]=((ABB[J]+1)%5)
IDARK=0
if (((COND[J]%2)==1)) then
goto l02003
end
if (((IPLACE[2]~=J)&(IPLACE[2]~=-1))) then
goto l02001
end
if ((PROP[2]==1)) then
goto l02003
end
::l02001::
SPEAK(16)
IDARK=1
::l02003::
I=IOBJ[J]
::l02004::
if ((I==0)) then
goto l02011
end
if ((((I==6)|(I==9))&(IPLACE[10]==-1))) then
goto l02008
end
ILK=I
if ((PROP[I]~=0)) then
ILK=(I+100)
end
KK=BTEXT[ILK]
if ((KK==0)) then
goto l02008
end
::l02005::
for JJ=3,LLINE[KK][2],1 do
FORTRAN_WRITE(LLINE[KK][JJ])
end
KK=(KK+1)
if ((LLINE[(KK-1)][1]~=0)) then
goto l02005
end
FORTRAN_WRITE("\n")
::l02008::
I=ICHAIN[I]
goto l02004
::l02012::
A=WD2
B=" "
TWOWDS=0
goto l02021
::l02009::
K=54
::l02010::
JSPK=K
::l05200::
SPEAK(JSPK)
::l02011::
JVERB=0
JOBJ=0
TWOWDS=0
::l02020::
GETIN(TWOWDS,A,WD2,B)
K=70
if (((A=="ENTER")&((WD2=="STREA")|(WD2=="WATER")))) then
goto l02010
end
if (((A=="ENTER")&(TWOWDS~=0))) then
goto l02012
end
::l02021::
if ((A~="WEST")) then
goto l02023
end
IWEST=(IWEST+1)
if ((IWEST~=10)) then
goto l02023
end
SPEAK(17)
::l02023::
::c00033::
for I=1,1000,1 do
if ((KTAB[I]==-1)) then
goto l03000
end
if ((ATAB[I]==A)) then
goto l02025
end
::l02024::
goto c00033
end
PAUSE("ERROR 6")
::l02025::
K=(KTAB[I]%1000)
KQ=(KTAB[I]/(1000+1))
 plex00034 = KQ
if (plex00034==1) then
goto l05014
elseif (plex00034==2) then
goto l05000
elseif (plex00034==3) then
goto l02026
else
goto l02010
end
PAUSE("NO NO")
::l02026::
JVERB=K
JSPK=JSPKT[JVERB]
if ((TWOWDS~=0)) then
goto l02028
end
if ((JOBJ==0)) then
goto l02036
end
::l02027::
 plex00035 = JVERB
if (plex00035==1) then
goto l09000
elseif (plex00035==2) then
goto l05066
elseif (plex00035==3) then
goto l03000
elseif (plex00035==4) then
goto l05031
elseif (plex00035==5) then
goto l02009
elseif (plex00035==6) then
goto l05031
elseif (plex00035==7) then
goto l09404
elseif (plex00035==8) then
goto l09406
elseif (plex00035==9) then
goto l05081
elseif (plex00035==10) then
goto l05200
elseif (plex00035==11) then
goto l05200
elseif (plex00035==12) then
goto l05300
elseif (plex00035==13) then
goto l05506
elseif (plex00035==14) then
goto l05502
elseif (plex00035==15) then
goto l05504
else
goto l05505
end
PAUSE("ERROR 5")
::l02028::
A=WD2
B=" "
TWOWDS=0
goto l02023
::l03000::
JSPK=60
if ((math.random()>0.8)) then
JSPK=61
end
if ((math.random()>0.8)) then
JSPK=13
end
SPEAK(JSPK)
LTRUBL=(LTRUBL+1)
if ((LTRUBL~=3)) then
goto l02020
end
if (((J~=13)|((IPLACE[7]~=13)|(IPLACE[5]~=-1)))) then
goto l02032
end
YES(18,19,54,YEA)
goto l02033
::l02032::
if (((J~=19)|((PROP[11]~=0)|(IPLACE[7]==-1)))) then
goto l02034
end
YES(20,21,54,YEA)
goto l02033
::l02034::
if (((J~=8)|(PROP[GRATE]~=0))) then
goto l02035
end
YES(62,63,54,YEA)
::l02033::
if ((YEA==0)) then
goto l02011
end
goto l02020
::l02035::
if (((IPLACE[5]~=J)&(IPLACE[5]~=-1))) then
goto l02020
end
if ((JOBJ~=5)) then
goto l02020
end
SPEAK(22)
goto l02020
::l02036::
 plex00036 = JVERB
if (plex00036==1) then
goto l02037
elseif (plex00036==2) then
goto l05062
elseif (plex00036==3) then
goto l05062
elseif (plex00036==4) then
goto l09403
elseif (plex00036==5) then
goto l02009
elseif (plex00036==6) then
goto l09403
elseif (plex00036==7) then
goto l09404
elseif (plex00036==8) then
goto l09406
elseif (plex00036==9) then
goto l05062
elseif (plex00036==10) then
goto l05062
elseif (plex00036==11) then
goto l05200
elseif (plex00036==12) then
goto l05300
elseif (plex00036==13) then
goto l05062
elseif (plex00036==14) then
goto l05062
elseif (plex00036==15) then
goto l05062
else
goto l05062
end
PAUSE("OOPS")
::l02037::
if (((IOBJ[J]==0)|(ICHAIN[IOBJ[J]]~=0))) then
goto l05062
end
::c00037::
for I=1,3,1 do
if ((DSEEN[I]~=0)) then
goto l05062
end
::l05312::
goto c00037
end
JOBJ=IOBJ[J]
goto l02027
::l05062::
if ((B~=" ")) then
goto l05333
end
FORTRAN_WRITE("  ")
FORTRAN_WRITE(A)
FORTRAN_WRITE(" WHAT?")
FORTRAN_WRITE("\n")
goto l02020
::l05333::
FORTRAN_WRITE(" ")
FORTRAN_WRITE(A)
FORTRAN_WRITE(" WHAT?")
FORTRAN_WRITE("\n")
goto l02020
::l05014::
if ((IDARK==0)) then
goto l00008
end
if ((math.random()>0.25)) then
goto l00008
end
::l05017::
SPEAK(23)
PAUSE("GAME IS OVER")
goto l02011
::l05000::
JOBJ=K
if ((TWOWDS~=0)) then
goto l02028
end
if (((J==IPLACE[K])|(IPLACE[K]==-1))) then
goto l05004
end
if ((K~=GRATE)) then
goto l00502
end
if (((J==1)|((J==4)|(J==7)))) then
goto l05098
end
if (((J>9)&(J<15))) then
goto l05097
end
::l00502::
if ((B~=" ")) then
goto l05316
end
FORTRAN_WRITE(" I SEE NO ")
FORTRAN_WRITE(A)
FORTRAN_WRITE(" HERE.")
FORTRAN_WRITE("\n")
goto l02011
::l05316::
FORTRAN_WRITE(" I SEE NO ")
FORTRAN_WRITE(A)
FORTRAN_WRITE(" HERE.\n")
goto l02011
::l05098::
K=49
goto l05014
::l05097::
K=50
goto l05014
::l05004::
JOBJ=K
if ((JVERB~=0)) then
goto l02027
end
::l05064::
if ((B~=" ")) then
goto l05314
end
FORTRAN_WRITE(" WHAT DO YOU WANT TO DO WITH THE ")
FORTRAN_WRITE(A)
FORTRAN_WRITE("?")
FORTRAN_WRITE("\n")
goto l02020
::l05314::
FORTRAN_WRITE(" WHAT DO YOU WANT TO DO WITH THE ")
FORTRAN_WRITE(A)
FORTRAN_WRITE("?")
FORTRAN_WRITE("\n")
goto l02020
::l09000::
if ((JOBJ==18)) then
goto l02009
end
if ((IPLACE[JOBJ]~=J)) then
goto l05200
end
::l09001::
if ((IFIXED[JOBJ]==0)) then
goto l09002
end
SPEAK(25)
goto l02011
::l09002::
if ((JOBJ~=BIRD)) then
goto l09004
end
if ((IPLACE[ROD]~=-1)) then
goto l09003
end
SPEAK(26)
goto l02011
::l09003::
if (((IPLACE[4]==-1)|(IPLACE[4]==J))) then
goto l09004
end
SPEAK(27)
goto l02011
::l09004::
IPLACE[JOBJ]=-1
::l09005::
if ((IOBJ[J]~=JOBJ)) then
goto l09006
end
IOBJ[J]=ICHAIN[JOBJ]
goto l02009
::l09006::
ITEMP=IOBJ[J]
::l09007::
if ((ICHAIN[ITEMP]==JOBJ)) then
goto l09008
end
ITEMP=ICHAIN[ITEMP]
goto l09007
::l09008::
ICHAIN[ITEMP]=ICHAIN[JOBJ]
goto l02009
::l09403::
if (((J==8)|(J==9))) then
goto l05105
end
::l05032::
SPEAK(28)
goto l02011
::l05105::
JOBJ=GRATE
goto l02027
::l05066::
if ((JOBJ==18)) then
goto l02009
end
if ((IPLACE[JOBJ]~=-1)) then
goto l05200
end
::l05012::
if (((JOBJ~=BIRD)|((J~=19)|(PROP[11]==1)))) then
goto l09401
end
SPEAK(30)
PROP[11]=1
::l05160::
ICHAIN[JOBJ]=IOBJ[J]
IOBJ[J]=JOBJ
IPLACE[JOBJ]=J
goto l02011
::l09401::
SPEAK(54)
goto l05160
::l05031::
if (((IPLACE[KEYS]~=-1)&(IPLACE[KEYS]~=J))) then
goto l05200
end
if ((JOBJ~=4)) then
goto l05102
end
SPEAK(32)
goto l02011
::l05102::
if ((JOBJ~=KEYS)) then
goto l05104
end
SPEAK(55)
goto l02011
::l05104::
if ((JOBJ==GRATE)) then
goto l05107
end
SPEAK(33)
goto l02011
::l05107::
if ((JVERB==4)) then
goto l05033
end
if ((PROP[GRATE]~=0)) then
goto l05034
end
SPEAK(34)
goto l02011
::l05034::
SPEAK(35)
PROP[GRATE]=0
PROP[8]=0
goto l02011
::l05033::
if ((PROP[GRATE]==0)) then
goto l05109
end
SPEAK(36)
goto l02011
::l05109::
SPEAK(37)
PROP[GRATE]=1
PROP[8]=1
goto l02011
::l09404::
if (((IPLACE[2]~=J)&(IPLACE[2]~=-1))) then
goto l05200
end
PROP[2]=1
IDARK=0
SPEAK(39)
goto l02011
::l09406::
if (((IPLACE[2]~=J)&(IPLACE[2]~=-1))) then
goto l05200
end
PROP[2]=0
SPEAK(40)
goto l02011
::l05081::
if ((JOBJ~=12)) then
goto l05200
end
PROP[12]=1
goto l02003
::l05300::
::c00038::
for ID=1,3,1 do
IID=ID
if ((DSEEN[ID]~=0)) then
goto l05307
end
::l05313::
goto c00038
end
if ((JOBJ==0)) then
goto l05062
end
if ((JOBJ==SNAKE)) then
goto l05200
end
if ((JOBJ==BIRD)) then
goto l05302
end
SPEAK(44)
goto l02011
::l05302::
SPEAK(45)
IPLACE[JOBJ]=300
goto l09005
::l05307::
if ((math.random()>0.4)) then
goto l05309
end
DSEEN[IID]=0
ODLOC[IID]=0
DLOC[IID]=0
SPEAK(47)
goto l05311
::l05309::
SPEAK(48)
::l05311::
K=21
goto l05014
::l05502::
if ((((IPLACE[FOOD]~=J)&(IPLACE[FOOD]~=-1))|((PROP[FOOD]~=0)|(JOBJ~=FOOD)))) then
goto l05200
end
PROP[FOOD]=1
::l05501::
JSPK=72
goto l05200
::l05504::
if ((((IPLACE[WATER]~=J)&(IPLACE[WATER]~=-1))|((PROP[WATER]~=0)|(JOBJ~=WATER)))) then
goto l05200
end
PROP[WATER]=1
JSPK=74
goto l05200
::l05505::
if ((JOBJ~=LAMP)) then
JSPK=76
end
goto l05200
::l05506::
if ((JOBJ~=WATER)) then
JSPK=78
end
PROP[WATER]=1
goto l05200
os.exit()
