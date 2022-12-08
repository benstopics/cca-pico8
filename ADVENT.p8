pico-8 cartridge // http://www.pico-8.com
version 38
__lua__

-- https://www.lexaloffle.com/bbs/?pid=101378
-- add 2 numeric strings
function stringadd(a, b)
    return tostr(tonum(a .. "", 2) + tonum(b .. "", 2), 2)
end
-- subtract 2 numeric strings
function stringsub(a, b)
    return tostr(tonum(a .. "", 2) - tonum(b .. "", 2), 2)
end
-- multiply 2 numeric strings
function stringmul(a, b)
    return tostr(tonum(a .. "", 2) * (tonum(b .. "", 2) << 16), 2)
end
-- divide 2 numeric strings
function stringdiv(a, b)
    return tostr(tonum(a .. "", 2) / (tonum(b .. "", 2) << 16), 2)
end
-- modulo 2 numeric strings
-- modulo 2 numeric strings
function stringmod(a, b)
    return stringsub(a,stringmul(b,stringdiv(a, b)))
end
-- negate numeric string
function stringneg(a)
    if sub(a,1,1) == "-" then return sub(a,2)
    else return "-" .. a end
end

-- https://www.lexaloffle.com/bbs/?pid=43636
-- converts anything to string, even nested tables
function tostring(any)
    if type(any)=="function" then 
        return "function" 
    end
    if any==nil then 
        return "nil" 
    end
    if type(any)=="string" then
        return any
    end
    if type(any)=="boolean" then
        if any then return "true" end
        return "false"
    end
    if type(any)=="table" then
        local str = "{ "
        for k,v in pairs(any) do
            str=str..tostring(k).."->"..tostring(v).." "
        end
        return str.."}"
    end
    if type(any)=="number" then
        return ""..any
    end
    return "unkown" -- should never show
end
cls()

poke(0x5f2d, 1) -- Enable keyboard/mouse

-- https://www.lexaloffle.com/bbs/?tid=41798
function cat(t)
    local s = ''
    for i = 1, #t, 1 do
        s = s .. t[i]
    end
    return s
end

local basedictcompress = {}
local basedictdecompress = {}
for i = 0, 255 do
    local ic, iic = chr(i), chr(i, 0)
    basedictcompress[ic] = iic
    basedictdecompress[iic] = ic
end

local function dictAddB(str, dict, a, b)
    if a >= 256 then
        a, b = 0, b + 1
        if b >= 256 then
            dict = {}
            b = 1
        end
    end
    dict[chr(a, b)] = str
    a = a + 1
    return dict, a, b
end

local function decompress(input)
    if type(input) ~= "string" then
        error("string expected, got " .. type(input))
    end

    if #input < 1 then
        error("invalid input - not a compressed string")
    end

    local control = sub(input, 1, 1)
    if control == "u" then
        return sub(input, 2)
    elseif control ~= "c" then
        error("invalid input - not a compressed string")
    end
    input = sub(input, 2)
    local len = #input

    if len < 2 then
        error("invalid input - not a compressed string")
    end

    local dict = {}
    local a, b = 0, 1

    local result = {}
    local n = 1
    local last = sub(input, 1, 2)
    result[n] = basedictdecompress[last] or dict[last]
    n = n + 1
    for i = 3, len, 2 do
        local code = sub(input, i, i + 1)
        local lastStr = basedictdecompress[last] or dict[last]
        if not lastStr then
            error("could not find last from dict. Invalid input?")
        end
        local toAdd = basedictdecompress[code] or dict[code]
        if toAdd then
            result[n] = toAdd
            n = n + 1
            dict, a, b = dictAddB(lastStr .. sub(toAdd, 1, 1), dict, a, b)
        else
            local tmp = lastStr .. sub(lastStr, 1, 1)
            result[n] = tmp
            n = n + 1
            dict, a, b = dictAddB(tmp, dict, a, b)
        end
        last = code
    end
    return cat(result)
end

-- https://stackoverflow.com/a/18694774
function utf8_from(t)
    local bytearr = {}
    for i = 1, #t, 1 do
        add(bytearr, chr(t[i]))
        --if i < 40 then print(chr(t[i]),1 + 4 * (i - 1),1) end
    end
    return cat(bytearr)
end

-- __gfx__ + __map__ --
READ_UTF8_DATA = {}
for i = 0, 0x2fff, 1 do
    add(READ_UTF8_DATA, peek(i))
end

-- __sfx__ --
for i = 0x3200, 0x3200 + 843 - 1, 1 do
    add(READ_UTF8_DATA, peek(i))
end
--print(tostr(#READ_UTF8_DATA),1,9)
COMPRESSED = utf8_from(READ_UTF8_DATA)
DECOMPRESSED = decompress(COMPRESSED)
--print(sub(DECOMPRESSED,#DECOMPRESSED - 20,#DECOMPRESSED),1,18)

READ_LINES = split(DECOMPRESSED, "|", false)

--cstore(0x3200, 0x0000, 4096)

function INIT_ARR1(size)
    local a = {}
    for i = 1, size do
        a[i] = "0"
    end
    return a
end

function INIT_ARR2(size1, size2)
    local a = {}
    for i = 1, size1 do
        a[i] = {}
        for j = 1, size2 do
            a[i][j] = "0"
        end
    end
    return a
end

READ_LINE_IDX = 1

function FORTRAN_READ(types, units)
    local line = READ_LINES[READ_LINE_IDX]
    local result = {}
    for i = 1, #types, 1 do
        local t = types[i]
        local u = units[i]
        for j = 1, u, 1 do
            if t == "G" then
                local v = tonum(sub(line, 1, 5))
                if v == nil or v == '' then
                    v = "0"
                else
                    v = tostr(v)
                end
                add(result, v)
                line = sub(line, 6, #line)
            elseif t == "A5" then
                local v = sub(line, 1, 5)
                if v == nil or v == '' then
                    v = ' '
                end
                add(result, v)
                line = sub(line, 6, #line)
            else
                error("Unsupported format type " .. t)
            end
        end
    end
    READ_LINE_IDX = READ_LINE_IDX + 1
    return result
end

SCREEN_TEXT = { '' }
MAX_SCREEN_WIDTH = 32
MAX_SCREEN_LINES = 20
function FORTRAN_WRITE(text)
    -- Add new text to buffer with wordwrap
    for c = 1, #text, 1 do
        if sub(text, c, c) == "\n" then
            add(SCREEN_TEXT, '')
        else
            if #SCREEN_TEXT[#SCREEN_TEXT] == MAX_SCREEN_WIDTH then
                add(SCREEN_TEXT, '')
            end
            SCREEN_TEXT[#SCREEN_TEXT] = SCREEN_TEXT[#SCREEN_TEXT] .. sub(text, c, c)
        end

        while #SCREEN_TEXT > MAX_SCREEN_LINES do
            st = {}
            for r = 2, #SCREEN_TEXT, 1 do
                add(st, SCREEN_TEXT[r])
            end
            SCREEN_TEXT = st
        end
    end
end
function DRAW_SCREEN()
    -- Clear screen
    cls()

    -- Draw game text
    for r = 1, #SCREEN_TEXT, 1 do
        for c = 1, #SCREEN_TEXT[r], 1 do
            print(SCREEN_TEXT[r], 0, (r - 1) * 6, 11)
        end
    end
end

function PAUSE(msg)
    FORTRAN_WRITE(msg .. "\n")
    DRAW_SCREEN()
    GETIN(_, _, _, _)
end
RTEXT = nil
LLINE = nil
function SPEAK(IT)
local KKT=RTEXT[tonum(IT)]
if (KKT=="0") then
if true then return {IT} end
end
::l00999::
for JJT=tonum("3"),tonum(LLINE[tonum(KKT)][tonum("2")]) do
FORTRAN_WRITE(LLINE[tonum(KKT)][tonum(JJT)])
end
KKT=stringadd(KKT,"1")
if (LLINE[tonum(stringsub(KKT,"1"))][tonum("1")]~="0") then
goto l00999
end
::l00997::
FORTRAN_WRITE("\n")
if true then return {IT} end
end
function GETIN(TWOW,B,C,D)

-- Render screen
    DRAW_SCREEN()

    kb_chars_alnum = "ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890"
    BACKSPACE_SCANCODE = 42
    SPACE_SCANCODE = 44
    ENTER_SCANCODE = 88

    t = ''
    key_states = {}
    enter_pressed = false
    while true do
        pressed_key = 0

        -- Update enter keypress
        local enter_was_pressed = enter_pressed
        local enter_pressed = stat(31) == "\r"
        if enter_pressed and not enter_was_pressed then
            pressed_key = 88
        else
            -- Update alphanum pressed statuses
            for scancode = 4, 256, 1 do
                local was_pressed = key_states[scancode]
                local pressed = stat(28, scancode)
                key_states[scancode] = pressed

                -- if pressed then print(scancode, 1, 1, 11) end

                -- Initial press only
                if pressed and not was_pressed then
                    pressed_key = scancode
                    break
                end
            end
        end

        -- Manage input line
        if pressed_key >= 4 and pressed_key <= 39 and #t < 20 then
            t = t .. sub(kb_chars_alnum, pressed_key - 3, pressed_key - 3)
        elseif pressed_key == SPACE_SCANCODE and sub(t, #t, #t) ~= " " then
            t = t .. " "
        elseif pressed_key == BACKSPACE_SCANCODE and #t > 0 then
            t = sub(t, 1, #t - 1)
        elseif pressed_key == ENTER_SCANCODE then
            break
        end

        -- Draw user input
        rectfill(0, 6 * (#SCREEN_TEXT), 127,6 * (#SCREEN_TEXT + 1), 0)
        local show_cursor = time() % 1 < 0.5
        local cursor = ""
        if show_cursor then cursor = "_" else show_cursor = " " end
        print(">" .. t .. cursor .. "                                      ", 0, 6 * (#SCREEN_TEXT), 11)
        flip()

        -- https://www.lexaloffle.com/bbs/?tid=41855
        poke(0x5f30, 1) -- prevents the p character or the enter key from calling the menu.
    end
    local input = sub(t, 1, 20)
    FORTRAN_WRITE(sub("\n>" .. input .. "                                      ",1,21) .. "\n\n")
    --print(input)
    local words = split(input, " ", false)
    local twow, firstw, secondw_ext, secondw
    if #words > 0 then
        firstw = sub(words[1], 1, 5)
        if #words > 1 then
            twow = 1
            secondw = sub(words[2], 1, 5)
            secondw_ext = sub(words[2], 6, 20)
            if #secondw_ext == 0 then secondw_ext = ' ' end
        else
            twow = "0"
            secondw = ' '
            secondw_ext = ' '
        end
    end
    return { twow, firstw, secondw, secondw_ext }

end

function YES(X,Y,Z,YEA)
X = unpack(SPEAK(X))
local JUNK="0"
local IA1="0"
local IB1="0"
JUNK, IA1, JUNK, IB1 = unpack(GETIN(JUNK,IA1,JUNK,IB1))
if (IA1=="NO" or IA1=="N") then
goto l00001
end
YEA="1"
if (Y~="0") then
Y = unpack(SPEAK(Y))
end
if true then return {X,Y,Z,YEA} end
::l00001::
YEA="0"
if (Z~="0") then
Z = unpack(SPEAK(Z))
end
if true then return {X,Y,Z,YEA} end
end
SETUP="0"
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
if (SETUP~="0") then
goto l00001
end
SETUP="1"
KEYS="1"
LAMP="2"
GRATE="3"
ROD="5"
BIRD="7"
NUGGET="10"
SNAKE="11"
FOOD="19"
WATER="20"
AXE="21"
ASSIGN_VALUES00001 = {"24","29","0","31","0","31","38","38","42","42","43","46","77","71","73","75"}
for I=tonum("1"),tonum("16") do
JSPKT[tonum(I)]=ASSIGN_VALUES00001[I]
end
ASSIGN_VALUES00002 = {"3","3","8","10","11","14","13","9","15","18","19","17","27","28","29","30","0","0","3","3"}
for I=tonum("1"),tonum("20") do
IPLT[tonum(I)]=ASSIGN_VALUES00002[I]
end
ASSIGN_VALUES00003 = {"0","0","1","0","0","1","0","1","1","0","1","1","0","0","0","0","0","0","0","0"}
for I=tonum("1"),tonum("20") do
IFIXT[tonum(I)]=ASSIGN_VALUES00003[I]
end
ASSIGN_VALUES00004 = {"36","28","19","30","62","60","41","27","17","15","19","28","36","300","300"}
for I=tonum("1"),tonum("15") do
DTRAV[tonum(I)]=ASSIGN_VALUES00004[I]
end
I=stringsub("1","1")
::c00005::
I = stringadd(I,"1")
if tonum(I) > tonum("300") then goto f00006 end
STEXT[tonum(I)]="0"
if (tonum(I, 2)<=tonum("200", 2)) then
BTEXT[tonum(I)]="0"
end
if (tonum(I, 2)<=tonum("100", 2)) then
RTEXT[tonum(I)]="0"
end
::l01001::
LTEXT[tonum(I)]="0"
goto c00005
::f00006::
I="1"
::l01002::
READ_VALUES00007=FORTRAN_READ({"G"},{1})
WRITE_I00008="1"
IKIND=READ_VALUES00007[tonum(WRITE_I00008)]
WRITE_I00008 = stringadd(WRITE_I00008,"1")
PLEX00009 = stringadd(IKIND,"1")
if (PLEX00009=="1") then
goto l01100
elseif (PLEX00009=="2") then
goto l01004
elseif (PLEX00009=="3") then
goto l01004
elseif (PLEX00009=="4") then
goto l01013
elseif (PLEX00009=="5") then
goto l01020
elseif (PLEX00009=="6") then
goto l01004
elseif (PLEX00009=="7") then
goto l01004
end
::l01004::
READ_VALUES00010=FORTRAN_READ({"G","A5"},{1,20})
WRITE_I00011="1"
JKIND=READ_VALUES00010[tonum(WRITE_I00011)]
WRITE_I00011 = stringadd(WRITE_I00011,"1")
for J=tonum("3"),tonum("22") do
if tonum(READ_VALUES00010[tonum(WRITE_I00011)]) == nil and #READ_VALUES00010[tonum(WRITE_I00011)] == "0" then READ_VALUES00010[tonum(WRITE_I00011)] = " " end
LLINE[tonum(I)][tonum(J)]=READ_VALUES00010[tonum(WRITE_I00011)]
WRITE_I00011 = stringadd(WRITE_I00011,"1")
end
if (JKIND==stringneg("1")) then
goto l01002
end
K=stringsub("1","1")
::c00012::
K = stringadd(K,"1")
if tonum(K) > tonum("20") then goto f00013 end
KK=K
if (LLINE[tonum(I)][tonum(stringsub("21",K))]~=" ") then
goto l01007
end
::l01006::
goto c00012
goto c00012
::f00013::
stop()
::l01007::
LLINE[tonum(I)][tonum("2")]=stringadd(stringsub("20",KK),"1")
LLINE[tonum(I)][tonum("1")]="0"
if (IKIND=="6") then
goto l01023
end
if (IKIND=="5") then
goto l01011
end
if (IKIND=="1") then
goto l01008
end
if (STEXT[tonum(JKIND)]~="0") then
goto l01009
end
STEXT[tonum(JKIND)]=I
goto l01010
::l01008::
if (LTEXT[tonum(JKIND)]~="0") then
goto l01009
end
LTEXT[tonum(JKIND)]=I
goto l01010
::l01009::
LLINE[tonum(stringsub(I,"1"))][tonum("1")]=I
::l01010::
I=stringadd(I,"1")
if (I~="1000") then
goto l01004
end
PAUSE("TOO MANY LINES")
::l01011::
if (tonum(JKIND, 2)<tonum("200", 2)) then
goto l01012
end
if (BTEXT[tonum(stringsub(JKIND,"100"))]~="0") then
goto l01009
end
BTEXT[tonum(stringsub(JKIND,"100"))]=I
BTEXT[tonum(stringsub(JKIND,"200"))]=I
goto l01010
::l01012::
if (BTEXT[tonum(JKIND)]~="0") then
goto l01009
end
BTEXT[tonum(JKIND)]=I
goto l01010
::l01023::
if (RTEXT[tonum(JKIND)]~="0") then
goto l01009
end
RTEXT[tonum(JKIND)]=I
goto l01010
::l01013::
I="1"
::l01014::
READ_VALUES00014=FORTRAN_READ({"G"},{12})
WRITE_I00015="1"
JKIND=READ_VALUES00014[tonum(WRITE_I00015)]
WRITE_I00015 = stringadd(WRITE_I00015,"1")
LKIND=READ_VALUES00014[tonum(WRITE_I00015)]
WRITE_I00015 = stringadd(WRITE_I00015,"1")
for L=tonum("1"),tonum("10") do
if tonum(READ_VALUES00014[tonum(WRITE_I00015)]) == nil and #READ_VALUES00014[tonum(WRITE_I00015)] == "0" then READ_VALUES00014[tonum(WRITE_I00015)] = " " end
TK[tonum(L)]=READ_VALUES00014[tonum(WRITE_I00015)]
WRITE_I00015 = stringadd(WRITE_I00015,"1")
end
if (JKIND==stringneg("1")) then
goto l01002
end
if (KEY[tonum(JKIND)]~="0") then
goto l01016
end
KEY[tonum(JKIND)]=I
goto l01017
::l01016::
TRAVEL[tonum(stringsub(I,"1"))]=stringneg(TRAVEL[tonum(stringsub(I,"1"))])
::l01017::
L=stringsub("1","1")
::c00016::
L = stringadd(L,"1")
if tonum(L) > tonum("10") then goto f00017 end
if (TK[tonum(L)]=="0") then
goto l01019
end
TRAVEL[tonum(I)]=stringadd(stringmul(LKIND,"1024"),TK[tonum(L)])
I=stringadd(I,"1")
if (I=="1000") then
stop()
end
::l01018::
goto c00016
goto c00016
::f00017::
::l01019::
TRAVEL[tonum(stringsub(I,"1"))]=stringneg(TRAVEL[tonum(stringsub(I,"1"))])
goto l01014
::l01020::
IU=stringsub("1","1")
::c00018::
IU = stringadd(IU,"1")
if tonum(IU) > tonum("1000") then goto f00019 end
READ_VALUES00020=FORTRAN_READ({"G","A5"},{1,1})
WRITE_I00021="1"
KTAB[tonum(IU)]=READ_VALUES00020[tonum(WRITE_I00021)]
WRITE_I00021 = stringadd(WRITE_I00021,"1")
ATAB[tonum(IU)]=READ_VALUES00020[tonum(WRITE_I00021)]
WRITE_I00021 = stringadd(WRITE_I00021,"1")
if (KTAB[tonum(IU)]==stringneg("1")) then
goto l01002
end
::l01022::
goto c00018
goto c00018
::f00019::
PAUSE("TOO MANY WORDS")
::l01100::
I=stringsub("1","1")
::c00022::
I = stringadd(I,"1")
if tonum(I) > tonum("100") then goto f00023 end
IPLACE[tonum(I)]=IPLT[tonum(I)]
IFIXED[tonum(I)]=IFIXT[tonum(I)]
::l01101::
ICHAIN[tonum(I)]="0"
goto c00022
::f00023::
I=stringsub("1","1")
::c00024::
I = stringadd(I,"1")
if tonum(I) > tonum("300") then goto f00025 end
COND[tonum(I)]="0"
ABB[tonum(I)]="0"
::l01102::
IOBJ[tonum(I)]="0"
goto c00024
::f00025::
I=stringsub("1","1")
::c00026::
I = stringadd(I,"1")
if tonum(I) > tonum("10") then goto f00027 end
::l01103::
COND[tonum(I)]="1"
goto c00026
::f00027::
COND[tonum("16")]="2"
COND[tonum("20")]="2"
COND[tonum("21")]="2"
COND[tonum("22")]="2"
COND[tonum("23")]="2"
COND[tonum("24")]="2"
COND[tonum("25")]="2"
COND[tonum("26")]="2"
COND[tonum("31")]="2"
COND[tonum("32")]="2"
COND[tonum("79")]="2"
I=stringsub("1","1")
::c00028::
I = stringadd(I,"1")
if tonum(I) > tonum("100") then goto f00029 end
KTEM=IPLACE[tonum(I)]
if (KTEM=="0") then
goto l01107
end
if (IOBJ[tonum(KTEM)]~="0") then
goto l01104
end
IOBJ[tonum(KTEM)]=I
goto l01107
::l01104::
KTEM=IOBJ[tonum(KTEM)]
::l01105::
if (ICHAIN[tonum(KTEM)]~="0") then
goto l01106
end
ICHAIN[tonum(KTEM)]=I
goto l01107
::l01106::
KTEM=ICHAIN[tonum(KTEM)]
goto l01105
::l01107::
goto c00028
goto c00028
::f00029::
IDWARF="0"
IFIRST="1"
IWEST="0"
ILONG="1"
IDETAL="0"
PAUSE("INIT DONE")
::l00001::
YEA="0"
_, _, _, YEA = unpack(YES("65","1","0",YEA))
L="1"
LOC="1"
::l00002::
I=stringsub("1","1")
::c00030::
I = stringadd(I,"1")
if tonum(I) > tonum("3") then goto f00031 end
if (ODLOC[tonum(I)]~=L or DSEEN[tonum(I)]=="0") then
goto l00073
end
L=LOC
_ = unpack(SPEAK("2"))
goto l00074
::l00073::
goto c00030
goto c00030
::f00031::
::l00074::
LOC=L
if (IDWARF~="0") then
goto l00060
end
if (LOC=="15") then
IDWARF="1"
end
goto l00071
::l00060::
if (IDWARF~="1") then
goto l00063
end
if (tonum(rnd(), 2)>tonum("0.05", 2)) then
goto l00071
end
IDWARF="2"
I=stringsub("1","1")
::c00032::
I = stringadd(I,"1")
if tonum(I) > tonum("3") then goto f00033 end
DLOC[tonum(I)]="0"
ODLOC[tonum(I)]="0"
::l00061::
DSEEN[tonum(I)]="0"
goto c00032
::f00033::
_ = unpack(SPEAK("3"))
ICHAIN[tonum(AXE)]=IOBJ[tonum(LOC)]
IOBJ[tonum(LOC)]=AXE
IPLACE[tonum(AXE)]=LOC
goto l00071
::l00063::
IDWARF=stringadd(IDWARF,"1")
ATTACK="0"
DTOT="0"
STICK="0"
I=stringsub("1","1")
::c00034::
I = stringadd(I,"1")
if tonum(I) > tonum("3") then goto f00035 end
if (tonum(stringadd(stringmul("2",I),IDWARF), 2)<tonum("8", 2)) then
goto l00066
end
if (tonum(stringadd(stringmul("2",I),IDWARF), 2)>tonum("23", 2) and DSEEN[tonum(I)]=="0") then
goto l00066
end
ODLOC[tonum(I)]=DLOC[tonum(I)]
if (DSEEN[tonum(I)]~="0" and tonum(LOC, 2)>tonum("14", 2)) then
goto l00065
end
DLOC[tonum(I)]=DTRAV[tonum(stringsub(stringadd(stringmul(I,"2"),IDWARF),"8"))]
DSEEN[tonum(I)]="0"
if (DLOC[tonum(I)]~=LOC and ODLOC[tonum(I)]~=LOC) then
goto l00066
end
::l00065::
DSEEN[tonum(I)]="1"
DLOC[tonum(I)]=LOC
DTOT=stringadd(DTOT,"1")
if (ODLOC[tonum(I)]~=DLOC[tonum(I)]) then
goto l00066
end
ATTACK=stringadd(ATTACK,"1")
if (tonum(rnd(), 2)<tonum("0.1", 2)) then
STICK=stringadd(STICK,"1")
end
::l00066::
goto c00034
goto c00034
::f00035::
if (DTOT=="0") then
goto l00071
end
if (DTOT=="1") then
goto l00075
end
FORTRAN_WRITE(" THERE ARE ")
FORTRAN_WRITE(DTOT)
FORTRAN_WRITE(" THREATENING LITTLE DWARVES IN THE ROOM WITH YOU.")
FORTRAN_WRITE("\n")
goto l00077
::l00075::
_ = unpack(SPEAK("4"))
::l00077::
if (ATTACK=="0") then
goto l00071
end
if (ATTACK=="1") then
goto l00079
end
FORTRAN_WRITE(" ")
FORTRAN_WRITE(ATTACK)
FORTRAN_WRITE(" OF THEM THROW KNIVES AT YOU!")
FORTRAN_WRITE("\n")
goto l00081
::l00079::
_ = unpack(SPEAK("5"))
_ = unpack(SPEAK(stringadd("52",STICK)))
PLEX00036 = stringadd(STICK,"1")
if (PLEX00036=="1") then
goto l00071
elseif (PLEX00036=="2") then
goto l00083
end
::l00081::
if (STICK=="0") then
goto l00069
end
if (STICK=="1") then
goto l00082
end
FORTRAN_WRITE(" ")
FORTRAN_WRITE(STICK)
FORTRAN_WRITE(" OF THEM GET YOU.")
FORTRAN_WRITE("\n")
goto l00083
::l00082::
_ = unpack(SPEAK("6"))
::l00083::
PAUSE("GAMES OVER")
goto l00071
::l00069::
_ = unpack(SPEAK("7"))
::l00071::
KK=STEXT[tonum(L)]
if (ABB[tonum(L)]=="0" or KK=="0") then
KK=LTEXT[tonum(L)]
end
if (KK=="0") then
goto l00007
end
::l00004::
for JJ=tonum("3"),tonum(LLINE[tonum(KK)][tonum("2")]) do
FORTRAN_WRITE(LLINE[tonum(KK)][tonum(JJ)])
end
KK=stringadd(KK,"1")
if (LLINE[tonum(stringsub(KK,"1"))][tonum("1")]~="0") then
goto l00004
end
FORTRAN_WRITE("\n")
::l00007::
if (COND[tonum(L)]=="2") then
goto l00008
end
if (LOC=="33" and tonum(rnd(), 2)<tonum("0.25", 2)) then
_ = unpack(SPEAK("8"))
end
J=L
goto l02000
::l00008::
KK=KEY[tonum(LOC)]
if (KK=="0") then
goto l00019
end
if (K=="57") then
goto l00032
end
if (K=="67") then
goto l00040
end
if (K=="8") then
goto l00012
end
LOLD=L
::l00009::
LL=TRAVEL[tonum(KK)]
if (tonum(LL, 2)<tonum("0", 2)) then
LL=stringneg(LL)
end
if ("1"==stringmod(LL,"1024")) then
goto l00010
end
if (K==stringmod(LL,"1024")) then
goto l00010
end
if (tonum(TRAVEL[tonum(KK)], 2)<tonum("0", 2)) then
goto l00011
end
KK=stringadd(KK,"1")
goto l00009
::l00012::
TEMP=LOLD
LOLD=L
L=TEMP
goto l00021
::l00010::
L=stringdiv(LL,"1024")
goto l00021
::l00011::
JSPK="12"
if (tonum(K, 2)>=tonum("43", 2) and tonum(K, 2)<=tonum("46", 2)) then
JSPK="9"
end
if (K=="29" or K=="30") then
JSPK="9"
end
if (K=="7" or K=="8" or K=="36" or K=="37" or K=="68") then
JSPK="10"
end
if (K=="11" or K=="19") then
JSPK="11"
end
if (JVERB=="1") then
JSPK="59"
end
if (K=="48") then
JSPK="42"
end
if (K=="17") then
JSPK="80"
end
JSPK = unpack(SPEAK(JSPK))
goto l00002
::l00019::
_ = unpack(SPEAK("13"))
L=LOC
if (IFIRST=="0") then
_ = unpack(SPEAK("14"))
end
::l00021::
if (tonum(L, 2)<tonum("300", 2)) then
goto l00002
end
IL=stringadd(stringsub(L,"300"),"1")
PLEX00037 = IL
if (PLEX00037=="1") then
goto l00022
elseif (PLEX00037=="2") then
goto l00023
elseif (PLEX00037=="3") then
goto l00024
elseif (PLEX00037=="4") then
goto l00025
elseif (PLEX00037=="5") then
goto l00026
elseif (PLEX00037=="6") then
goto l00031
elseif (PLEX00037=="7") then
goto l00027
elseif (PLEX00037=="8") then
goto l00028
elseif (PLEX00037=="9") then
goto l00029
elseif (PLEX00037=="10") then
goto l00030
elseif (PLEX00037=="11") then
goto l00033
elseif (PLEX00037=="12") then
goto l00034
elseif (PLEX00037=="13") then
goto l00036
elseif (PLEX00037=="14") then
goto l00037
end
goto l00002
::l00022::
L="6"
if (tonum(rnd(), 2)>tonum("0.5", 2)) then
L="5"
end
goto l00002
::l00023::
L="23"
if (PROP[tonum(GRATE)]~="0") then
L="9"
end
goto l00002
::l00024::
L="9"
if (PROP[tonum(GRATE)]~="0") then
L="8"
end
goto l00002
::l00025::
L="20"
if (IPLACE[tonum(NUGGET)]~=stringneg("1")) then
L="15"
end
goto l00002
::l00026::
L="22"
if (IPLACE[tonum(NUGGET)]~=stringneg("1")) then
L="14"
end
goto l00002
::l00027::
L="27"
if (PROP[tonum("12")]=="0") then
L="31"
end
goto l00002
::l00028::
L="28"
if (PROP[tonum(SNAKE)]=="0") then
L="32"
end
goto l00002
::l00029::
L="29"
if (PROP[tonum(SNAKE)]=="0") then
L="32"
end
goto l00002
::l00030::
L="30"
if (PROP[tonum(SNAKE)]=="0") then
L="32"
end
goto l00002
::l00031::
PAUSE("GAME IS OVER")
goto l01100
::l00032::
if (tonum(IDETAL, 2)<tonum("3", 2)) then
_ = unpack(SPEAK("15"))
end
IDETAL=stringadd(IDETAL,"1")
L=LOC
ABB[tonum(L)]="0"
goto l00002
::l00033::
L="8"
if (PROP[tonum(GRATE)]=="0") then
L="9"
end
goto l00002
::l00034::
if (tonum(rnd(), 2)>tonum("0.2", 2)) then
goto l00035
end
L="68"
goto l00002
::l00035::
L="65"
::l00038::
_ = unpack(SPEAK("56"))
goto l00002
::l00036::
if (tonum(rnd(), 2)>tonum("0.2", 2)) then
goto l00035
end
L="39"
if (tonum(rnd(), 2)>tonum("0.5", 2)) then
L="70"
end
goto l00002
::l00037::
L="66"
if (tonum(rnd(), 2)>tonum("0.4", 2)) then
goto l00038
end
L="71"
if (tonum(rnd(), 2)>tonum("0.25", 2)) then
L="72"
end
goto l00002
::l00039::
L="66"
if (tonum(rnd(), 2)>tonum("0.2", 2)) then
goto l00038
end
L="77"
goto l00002
::l00040::
if (tonum(LOC, 2)<tonum("8", 2)) then
_ = unpack(SPEAK("57"))
end
if (tonum(LOC, 2)>=tonum("8", 2)) then
_ = unpack(SPEAK("58"))
end
L=LOC
goto l00002
::l02000::
LTRUBL="0"
LOC=J
ABB[tonum(J)]=stringmod(stringadd(ABB[tonum(J)],"1"),"5")
IDARK="0"
if (stringmod(COND[tonum(J)],"2")=="1") then
goto l02003
end
if (IPLACE[tonum("2")]~=J and IPLACE[tonum("2")]~=stringneg("1")) then
goto l02001
end
if (PROP[tonum("2")]=="1") then
goto l02003
end
::l02001::
_ = unpack(SPEAK("16"))
IDARK="1"
::l02003::
I=IOBJ[tonum(J)]
::l02004::
if (I=="0") then
goto l02011
end
if ((I=="6" or I=="9") and IPLACE[tonum("10")]==stringneg("1")) then
goto l02008
end
ILK=I
if (PROP[tonum(I)]~="0") then
ILK=stringadd(I,"100")
end
KK=BTEXT[tonum(ILK)]
if (KK=="0") then
goto l02008
end
::l02005::
for JJ=tonum("3"),tonum(LLINE[tonum(KK)][tonum("2")]) do
FORTRAN_WRITE(LLINE[tonum(KK)][tonum(JJ)])
end
KK=stringadd(KK,"1")
if (LLINE[tonum(stringsub(KK,"1"))][tonum("1")]~="0") then
goto l02005
end
FORTRAN_WRITE("\n")
::l02008::
I=ICHAIN[tonum(I)]
goto l02004
::l02012::
A=WD2
B=" "
TWOWDS="0"
goto l02021
::l02009::
K="54"
::l02010::
JSPK=K
::l05200::
JSPK = unpack(SPEAK(JSPK))
::l02011::
JVERB="0"
JOBJ="0"
TWOWDS="0"
::l02020::
WD2="0"
TWOWDS, A, WD2, B = unpack(GETIN(TWOWDS,A,WD2,B))
K="70"
if (A=="ENTER" and (WD2=="STREA" or WD2=="WATER")) then
goto l02010
end
if (A=="ENTER" and TWOWDS~="0") then
goto l02012
end
::l02021::
if (A~="WEST") then
goto l02023
end
IWEST=stringadd(IWEST,"1")
if (IWEST~="10") then
goto l02023
end
_ = unpack(SPEAK("17"))
::l02023::
I=stringsub("1","1")
::c00038::
I = stringadd(I,"1")
if tonum(I) > tonum("1000") then goto f00039 end
if (KTAB[tonum(I)]==stringneg("1")) then
goto l03000
end
if (ATAB[tonum(I)]==A) then
goto l02025
end
::l02024::
goto c00038
goto c00038
::f00039::
PAUSE("ERROR 6")
::l02025::
K=stringmod(KTAB[tonum(I)],"1000")
KQ=stringadd(stringdiv(KTAB[tonum(I)],"1000"),"1")
PLEX00040 = KQ
if (PLEX00040=="1") then
goto l05014
elseif (PLEX00040=="2") then
goto l05000
elseif (PLEX00040=="3") then
goto l02026
elseif (PLEX00040=="4") then
goto l02010
end
PAUSE("NO NO")
::l02026::
JVERB=K
JSPK=JSPKT[tonum(JVERB)]
if (TWOWDS~="0") then
goto l02028
end
if (JOBJ=="0") then
goto l02036
end
::l02027::
PLEX00041 = JVERB
if (PLEX00041=="1") then
goto l09000
elseif (PLEX00041=="2") then
goto l05066
elseif (PLEX00041=="3") then
goto l03000
elseif (PLEX00041=="4") then
goto l05031
elseif (PLEX00041=="5") then
goto l02009
elseif (PLEX00041=="6") then
goto l05031
elseif (PLEX00041=="7") then
goto l09404
elseif (PLEX00041=="8") then
goto l09406
elseif (PLEX00041=="9") then
goto l05081
elseif (PLEX00041=="10") then
goto l05200
elseif (PLEX00041=="11") then
goto l05200
elseif (PLEX00041=="12") then
goto l05300
elseif (PLEX00041=="13") then
goto l05506
elseif (PLEX00041=="14") then
goto l05502
elseif (PLEX00041=="15") then
goto l05504
elseif (PLEX00041=="16") then
goto l05505
end
PAUSE("ERROR 5")
::l02028::
A=WD2
B=" "
TWOWDS="0"
goto l02023
::l03000::
JSPK="60"
if (tonum(rnd(), 2)>tonum("0.8", 2)) then
JSPK="61"
end
if (tonum(rnd(), 2)>tonum("0.8", 2)) then
JSPK="13"
end
JSPK = unpack(SPEAK(JSPK))
LTRUBL=stringadd(LTRUBL,"1")
if (LTRUBL~="3") then
goto l02020
end
if (J~="13" or IPLACE[tonum("7")]~="13" or IPLACE[tonum("5")]~=stringneg("1")) then
goto l02032
end
_, _, _, YEA = unpack(YES("18","19","54",YEA))
goto l02033
::l02032::
if (J~="19" or PROP[tonum("11")]~="0" or IPLACE[tonum("7")]==stringneg("1")) then
goto l02034
end
_, _, _, YEA = unpack(YES("20","21","54",YEA))
goto l02033
::l02034::
if (J~="8" or PROP[tonum(GRATE)]~="0") then
goto l02035
end
_, _, _, YEA = unpack(YES("62","63","54",YEA))
::l02033::
if (YEA=="0") then
goto l02011
end
goto l02020
::l02035::
if (IPLACE[tonum("5")]~=J and IPLACE[tonum("5")]~=stringneg("1")) then
goto l02020
end
if (JOBJ~="5") then
goto l02020
end
_ = unpack(SPEAK("22"))
goto l02020
::l02036::
PLEX00042 = JVERB
if (PLEX00042=="1") then
goto l02037
elseif (PLEX00042=="2") then
goto l05062
elseif (PLEX00042=="3") then
goto l05062
elseif (PLEX00042=="4") then
goto l09403
elseif (PLEX00042=="5") then
goto l02009
elseif (PLEX00042=="6") then
goto l09403
elseif (PLEX00042=="7") then
goto l09404
elseif (PLEX00042=="8") then
goto l09406
elseif (PLEX00042=="9") then
goto l05062
elseif (PLEX00042=="10") then
goto l05062
elseif (PLEX00042=="11") then
goto l05200
elseif (PLEX00042=="12") then
goto l05300
elseif (PLEX00042=="13") then
goto l05062
elseif (PLEX00042=="14") then
goto l05062
elseif (PLEX00042=="15") then
goto l05062
elseif (PLEX00042=="16") then
goto l05062
end
PAUSE("OOPS")
::l02037::
if (IOBJ[tonum(J)]=="0" or ICHAIN[tonum(IOBJ[tonum(J)])]~="0") then
goto l05062
end
I=stringsub("1","1")
::c00043::
I = stringadd(I,"1")
if tonum(I) > tonum("3") then goto f00044 end
if (DSEEN[tonum(I)]~="0") then
goto l05062
end
::l05312::
goto c00043
goto c00043
::f00044::
JOBJ=IOBJ[tonum(J)]
goto l02027
::l05062::
if (B~=" ") then
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
if (IDARK=="0") then
goto l00008
end
if (tonum(rnd(), 2)>tonum("0.25", 2)) then
goto l00008
end
::l05017::
_ = unpack(SPEAK("23"))
PAUSE("GAME IS OVER")
goto l02011
::l05000::
JOBJ=K
if (TWOWDS~="0") then
goto l02028
end
if (J==IPLACE[tonum(K)] or IPLACE[tonum(K)]==stringneg("1")) then
goto l05004
end
if (K~=GRATE) then
goto l00502
end
if (J=="1" or J=="4" or J=="7") then
goto l05098
end
if (tonum(J, 2)>tonum("9", 2) and tonum(J, 2)<tonum("15", 2)) then
goto l05097
end
::l00502::
if (B~=" ") then
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
K="49"
goto l05014
::l05097::
K="50"
goto l05014
::l05004::
JOBJ=K
if (JVERB~="0") then
goto l02027
end
::l05064::
if (B~=" ") then
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
if (JOBJ=="18") then
goto l02009
end
if (IPLACE[tonum(JOBJ)]~=J) then
goto l05200
end
::l09001::
if (IFIXED[tonum(JOBJ)]=="0") then
goto l09002
end
_ = unpack(SPEAK("25"))
goto l02011
::l09002::
if (JOBJ~=BIRD) then
goto l09004
end
if (IPLACE[tonum(ROD)]~=stringneg("1")) then
goto l09003
end
_ = unpack(SPEAK("26"))
goto l02011
::l09003::
if (IPLACE[tonum("4")]==stringneg("1") or IPLACE[tonum("4")]==J) then
goto l09004
end
_ = unpack(SPEAK("27"))
goto l02011
::l09004::
IPLACE[tonum(JOBJ)]=stringneg("1")
::l09005::
if (IOBJ[tonum(J)]~=JOBJ) then
goto l09006
end
IOBJ[tonum(J)]=ICHAIN[tonum(JOBJ)]
goto l02009
::l09006::
ITEMP=IOBJ[tonum(J)]
::l09007::
if (ICHAIN[tonum(ITEMP)]==JOBJ) then
goto l09008
end
ITEMP=ICHAIN[tonum(ITEMP)]
goto l09007
::l09008::
ICHAIN[tonum(ITEMP)]=ICHAIN[tonum(JOBJ)]
goto l02009
::l09403::
if (J=="8" or J=="9") then
goto l05105
end
::l05032::
_ = unpack(SPEAK("28"))
goto l02011
::l05105::
JOBJ=GRATE
goto l02027
::l05066::
if (JOBJ=="18") then
goto l02009
end
if (IPLACE[tonum(JOBJ)]~=stringneg("1")) then
goto l05200
end
::l05012::
if (JOBJ~=BIRD or J~="19" or PROP[tonum("11")]=="1") then
goto l09401
end
_ = unpack(SPEAK("30"))
PROP[tonum("11")]="1"
::l05160::
ICHAIN[tonum(JOBJ)]=IOBJ[tonum(J)]
IOBJ[tonum(J)]=JOBJ
IPLACE[tonum(JOBJ)]=J
goto l02011
::l09401::
_ = unpack(SPEAK("54"))
goto l05160
::l05031::
if (IPLACE[tonum(KEYS)]~=stringneg("1") and IPLACE[tonum(KEYS)]~=J) then
goto l05200
end
if (JOBJ~="4") then
goto l05102
end
_ = unpack(SPEAK("32"))
goto l02011
::l05102::
if (JOBJ~=KEYS) then
goto l05104
end
_ = unpack(SPEAK("55"))
goto l02011
::l05104::
if (JOBJ==GRATE) then
goto l05107
end
_ = unpack(SPEAK("33"))
goto l02011
::l05107::
if (JVERB=="4") then
goto l05033
end
if (PROP[tonum(GRATE)]~="0") then
goto l05034
end
_ = unpack(SPEAK("34"))
goto l02011
::l05034::
_ = unpack(SPEAK("35"))
PROP[tonum(GRATE)]="0"
PROP[tonum("8")]="0"
goto l02011
::l05033::
if (PROP[tonum(GRATE)]=="0") then
goto l05109
end
_ = unpack(SPEAK("36"))
goto l02011
::l05109::
_ = unpack(SPEAK("37"))
PROP[tonum(GRATE)]="1"
PROP[tonum("8")]="1"
goto l02011
::l09404::
if (IPLACE[tonum("2")]~=J and IPLACE[tonum("2")]~=stringneg("1")) then
goto l05200
end
PROP[tonum("2")]="1"
IDARK="0"
_ = unpack(SPEAK("39"))
goto l02011
::l09406::
if (IPLACE[tonum("2")]~=J and IPLACE[tonum("2")]~=stringneg("1")) then
goto l05200
end
PROP[tonum("2")]="0"
_ = unpack(SPEAK("40"))
goto l02011
::l05081::
if (JOBJ~="12") then
goto l05200
end
PROP[tonum("12")]="1"
goto l02003
::l05300::
ID=stringsub("1","1")
::c00045::
ID = stringadd(ID,"1")
if tonum(ID) > tonum("3") then goto f00046 end
IID=ID
if (DSEEN[tonum(ID)]~="0") then
goto l05307
end
::l05313::
goto c00045
goto c00045
::f00046::
if (JOBJ=="0") then
goto l05062
end
if (JOBJ==SNAKE) then
goto l05200
end
if (JOBJ==BIRD) then
goto l05302
end
_ = unpack(SPEAK("44"))
goto l02011
::l05302::
_ = unpack(SPEAK("45"))
IPLACE[tonum(JOBJ)]="300"
goto l09005
::l05307::
if (tonum(rnd(), 2)>tonum("0.4", 2)) then
goto l05309
end
DSEEN[tonum(IID)]="0"
ODLOC[tonum(IID)]="0"
DLOC[tonum(IID)]="0"
_ = unpack(SPEAK("47"))
goto l05311
::l05309::
_ = unpack(SPEAK("48"))
::l05311::
K="21"
goto l05014
::l05502::
if ((IPLACE[tonum(FOOD)]~=J and IPLACE[tonum(FOOD)]~=stringneg("1")) or PROP[tonum(FOOD)]~="0" or JOBJ~=FOOD) then
goto l05200
end
PROP[tonum(FOOD)]="1"
::l05501::
JSPK="72"
goto l05200
::l05504::
if ((IPLACE[tonum(WATER)]~=J and IPLACE[tonum(WATER)]~=stringneg("1")) or PROP[tonum(WATER)]~="0" or JOBJ~=WATER) then
goto l05200
end
PROP[tonum(WATER)]="1"
JSPK="74"
goto l05200
::l05505::
if (JOBJ~=LAMP) then
JSPK="76"
end
goto l05200
::l05506::
if (JOBJ~=WATER) then
JSPK="78"
end
PROP[tonum(WATER)]="1"
goto l05200
stop()

__gfx__
361300c70013000200301030109500f400550002001400250054000200350045001400e40044009400e400740090104500020045008400c010540011100200f4
006400901002002500f400140044000200240054006400f400b01012103500d4001400c400c4007210250094003400b400101040103010240055009400c40021
1041100200e200901032105500d11060108010940035001210a210b010e01024101400d010f210131083109310e010b0101400d40002006400c400f4007500a4
1070107110f1108110a1107210c310e31031105110011062104400d510e40012107400550013109500e200c70023009310020074100200840014006500c01075
000310b400540062105500050012108400d310c400c200d01045008810020031103610c010c4105400e010571077109110c010321052100200e400d510d010c5
10050039107210140063100200c6107500e6107910e11079102500d01094004400c01026109a1078101310471067109310ba10c01094101210b310d310f31051
10f8109a102110e0100110340054004710330077109710a0109b10e4003500ea10c0100510cb1076104110a8100510750054001310a710701035001910b21012
10c400a0107400c0103500050043104110471043009c1070103410cc10121065000310c40054009500e8108a1046102910e01072103910fc10d2104500751095
1045005500d4002400c4008610c7009e1093100310f40004100510321063103f108210440047105300ae108010bc104f10e1100a10e6107f104500a810750094
0091101210fa1054005810fe1013102f108110f400e110e4003e10fc10471063004120ce107120f4009120a510b21039107110b220a0107210f4000220051052
201f103f10a610121099101120c70073007710140071107410ca1064005400540071100f1009100200f71045005400ca101b104610651054008510d01005000e
103500a110a4103110450092201400642077106710311034008400e910f12071209a10d020b40024106a10dc10df10b520ff109520672085100120e810a41024
00612017204710830003206120f8100510230003005320c3205a103220d410ec10a020a510c51063206210e1200220f720c2102110250045002410cd10711036
20f400c70038207b1046109920e920a41005106510a0205110e010e4202310740025009420c010d4007010e40055206210f8103400a0203400b0105520f4105a
10250095001a207710a520b720281002001f10521026205b2092201c10d8203910f820e400471093004820c210682015101520b6205c20ca1082109320d32002
00330085008c10ca208d100200fa201b2082200910c7003d2055105500250064003a106c10fd10d910bb20140075002310f400d710ca109b20240030201a108c
204400ac20f71025006210462025207d10e410101098204010ac10c2104f206f208610e1109f200200bf20df20ac202f2075000200050014003500350014002e
1024108b10d72090109030931021109510402074008400052071109a10b5208f10c11062108520c010a130c130e1306c1010102010b030be105820e6100510fa
1024004310a4103210f400d400a810640088106c205920c620e010550064000210f71006206c20f81064003210d40083303a203e10de20fe205c10eb20c51081
30e120fa109130b130d1302e103520f120c62041301f10e72054009b20d400391075304010e520550074002e10492076300200d400550062102420f3301430a7
1065205400c200b3100520d3307500b40020306210340001106010e40007303010ff20a410481088309010d1107030b920e8301210c9105520a22060301520d1
309500a4107200f210740053103520b210621085009500a500a50095007200471013006b105010b3305d20d33058307830a01062103500f9100130e2304500f2
0069303130b830a020fa308c10a33051204b30d210e5200330ea103130b7102020652036109400a9203f10d420f420a7109400923002304610f7101310350010
105c30301061204530f400a500c110221094009f20f5100210b21001105630e010a0201f200110901068303930a830e400c8304930b730fd3093107400f400f4
00621043304630b1108500e6203e309510db309f3035207320da10fa10ae3025209d20fc302500fa3070201e30a4207010c420e4206a20d210251023100500e6
200430b52091100130df100f20e04075007810b930d4009410b920493010104140020080401040633003401110a410a110c210540085005c1005007110c410b1
408d200b204a10ff2001303c30101031206c3013209420a220b110d1102610e320b1307110b7109d10a5204500b6200130c41039300610e1106400644055108d
30a2308e209a106930ad30083013203320c1108610a4105030540076300d30ec10fa10241093202500240095005d106630fa10d5404010fe30b220b81014002d
30a830cd107c20b52000305a10d61088304640a7101520ab10743062206730911097403010e1204e10624082402b20b240d010f710950032405620d1103e3090
10c4003b208f10b130e810021003108e307330130074401e303130f400e3106630d1103020d510193058109a103c10f740b1301f201230ab10051023402e1009
406110252046205810e4405840e6309f10781064107010fa30f22040109a104f204a10b840a32046209220e2101520e34097105030a2101310d510fa30742084
4061200920d23005402a10e400b400b540b41094103500de203e1040203400013034008c20ca103a103210c1301010ed4030102b100f108840a2408f10ab1015
00c310b93022404a107340183090409a107430c130be40d7206f407b10ef307740c0105030a40010200500fa302a208f40781026207a207c20d91034309510a4
301210bb20a730c010a9300b105f10e710af4010106150e8107110f9301a3097107500a020720071102e10e920711048102520ca2005003500ea301010be202b
307c30de109f409d10233087304b20f010f810b4008610d1207730db40f6301300e350b540021068209d109920c630c810a02035005b10a030f3509440c23046
102400c320462095104450e1407110f1501d1032101810e610b22063105b109330c55021104400e4002350873014001810b25057101b302520c6106c40ab1054
100f40940020201400df2057100e308710be106f304750df30f6208400441092302f2063106c203e20ea200b20552012005710f2409710c6103750d340e62047
201210450003504f10b620ad101f1079502300aa407850801098503350cc20d8507010f8500510c51019509b3055204e206e20db2057107f40aa5066406250a0
408f10f6400b10021070509e40a0500c10461025407f200210cf40450095505710a250c030de102b50d910e400f200a410d4500c4005108400da4014506f1029
202140fc5085305a50c010df301a10f95050302f305400fb3026305330f130571005501d50c8503e100610b430bf10014082100e503300b550cb50c3306030b0
401c50dc30ad207e409c507e40d400711094507e10c700af508020ce502040ca405b20311055001a100c302420735040504710a060f65009105d20a410c91035
2014001420bb20f400c13025208050ae40b0107c10a7509710ca505e206d3047408350e40067505400a06068501f506d200e1025005630d150b450ed208d5050
305b404f50c2004360c060e360ea50e71073205d10d1106d10152026100430f400a6502210f4004a1046203460dc404610db304640c160fd101e10c010720095
0023007200c930c02025606e40f810d150a4105c105b2065207c1099503b302d500200215020201f107e401720c36086301440b400a41054009f209500724008
307c109a501f50a4406d1031106a102660a71037303330f120d12078104a505e503b409f30a0609a50f950a5402610ec109230c2400510b510ef30ca10ab1058
60b240a6204500c4003f10650094109400485033009a508f200d30530098205d3071108210e53037202d3065503a60812005003260f120c010ac10d1108a50a5
1091403f30026029608530a5608a201850d310a320e1201110cd40a060cc40c550df50e3302d304500f02096506e30d4500230646003403e40bb4031300b206f
207c10ec601640bd30b040cd60836056307d6090100650d710cb50cd60bd503760456033001e600110c3207340d06063307c10bb501f501e40f5506e106e404c
405d409d100f40b520e61008502850df209130f1208f60c060e03023100930fb50793033000d50e6602f50b320450026507e408a20c1408070665077302b50f1
202a60336011705510a72054303520d860c620c110552025007a20d1109340f120a640fa503730c620c8107f30d620dc507c100f5031707360c56015604430a5
101710ac505a105500e0103f1017209550b1609b107a20a060055024008d303e504170b960b21095600d10d0308760a760c760e760b01094604400b470446036
3033403440041085606020bf509710b710be60c0706c209110e850c620e32065203f10e530f0506f607e60a0100f108d104670d0509040c910a920c620445040
602610cc50ec504300a1602860e5507460f230d4400210f770bc50b24074703d50f5306f50ed60c4006020a1609b200160e4002160a4104160a460a9305f60f8
60b910b21091108d6083504f5022306620387093104020617037608d50f220fa6015505260fd508e10a260a370d33057505e307e401a50b2400770f170ca70f5
702e1035005d109d106a4018108e1053605b701210f2108b701b1029403d607c20db703330fb7039102c7023104c7073304300d660045071200510ac702c5081
10dc70cb70ba701d70de503d70f9405d7040205c70602018608c70cd701400bc703c500e70fc702e7037705e7015206d708e101e60fa10a91003306020bb50af
706210cf704300a250ff704340c57043009370ad706d20dd709b701f70aa7002704f701c706e70f94094009e70da60931063606b70b080cc70bb702f70f080d4
5011806f708e70733053004870ce707b70ed70ab704470d180eb704e7002803c70228021204b7090809180ee708280d0800d7001804d70318051807c7033809c
705380c080c180e080c2802040e2807e7041803280f2404080cf705300be70e380de70fe70fd7024808380f180a3807f70c70053009f703840508085809f6031
70bf60c01004303110ef605a401d303d30a820711056506630ed20f210c1307a40d5809310ce304110c0109b20c4001020e6104960c740cd30c4002410b26070
10ea405070240058407a10f730b010078040103830cb509b2017106210a930d2600b603a106e404810bf4004806970437099700c402240ed305300bb501f10d7
10c78085803080b580c4808080984086702970a67013701b500200c760b150097016308d50a1300b2062203970530005508e50d110b7700220e770c460c870e0
10ec50630056703170a4402e40887013305680da80c51004104060140005002b8092703a60c7001c809310a430a54000607f5065207470f36075603e40f87027
70c070e9100110dc502d80bf5039802e6032501a70d6701560541040302a50a210b820ee60ce402e80a4104720e2205280ad704c803e606c808170ca80f670b1
500410d4209420be40a6306340825063002380d55002504f403500ba60752056807810f8505d507d502d709040ed80ae5081300f30e2206850b48011102d809d
7090900510d630ac3085000760f75075501d207130984053409040b400b220f6306300f2408d5060402520ab80c620a400f4003110a15001905f60c070e19093
1033905c80c2309220f21077501210cd30806051108d50df3001306930e39065605640bb40c400c090b56093608910ef3095103850ba608840e740d9604f8085
1058107160e490ba407960e610f810a2404400c59058803e1002601a30a830be60ce800d30697065105500340072909f10c830c57003903a20ab108b60362024
105e102560e420b730161048801430272072002d80e4801320f8100120ff40d310c1202f2026700540fb30b0408d50f1501f807570f6709570733063009a50b6
408500e52063200c400b20bc609510cd101f1057900a70c770a810c09055009110a8104810a810ed105f802d801e60818034207590627032607250dd30221039
10540027603e1029408660a110fb90e2201e60f40024005a60bd1001805e2092206930c200db30c200b220b5705b909310e4007500f790a01016103c504610d1
50223025603400481094006c20f2602b50c3700120172072103b5027202d80e580e3809a101a503320e620d150884015702500ee90931040502230e0800830e8
4033708c4015604a10ab303850118072405310c62044909b1045009f904010e2303f105030d0409660403046105650ad80bf90cd60a1300220bf904740104050
206300bb509a1061a08e206970c65096802d70a41033908040242036408b10d0a01e30c21089902180d090a81098809a10a0206b60d47051100f300e90eb50b7
80f2a05a104b6057906b60d09025201340e620b990a8800110a8506d30503090702d802170f4807c20c3701770ee4025002e90836010601140ab9018407f906a
70d8306300a2501850e630dc102f802880fe206220a1205530f040c64040204110820040a02880d15092002410b2a0d19016a04d80b0401230ab207460c2106e
603e70548053a0ea9009101420c210c9108130c8401f109790a250f1500650c8809d80241017700070d14082a0ec90aa90d320d110da90fa906050a11005a055
105a70c3a0e890631093a00330a970b040a0104b2041a01680f780fa10b270e2205a800d60d010c630cb20b91086602c30d330ae600d1035a05590d370d40047
1073002c8025a0cd10bb206d3021901c307f3009209590be606c60a500385044807f6064207f80b890e6103ca04ba06f308f3038605290e40057909400092085
20b01047807ba01c701da093108210a01001305390ca9014609040cd1088405390b4406a70a6400f104ea040103a4073a0ba10fd709220d630d470b220542073
0080901ba0f7a0ea80dba02410c070a410ff20b910ca905050242035009d906420b1903a80d110c070fba0f190df505da06d307da0092070a04a50bf90250054
10a760fb302410e6202260c1301a10d0906420f240e6700c208110f540711091b0e6109a40fb60e2608d10cd404a40cb50b850f9509710f2101c207300f240e8
8082109e60fe60922043502a104a1048106420a89061209da0063033300e105c10bd70df80b2b0c8108960b9106d507ca0c830fba01e60ec407ba0a6909f10d6
301a10f360d2b08e20b8506400de208fa0a9a08400fba0fe903da00a501520719075b03c30929035b006400e80f9708c10fa606420bb50fea0c0b0e420d400a6
4092207640e61039806420a250b5b08ca0e610e1b0dc104f108e5057504260d460caa09d800200d200c820bf701110fba07b809720ef1019202b40e11038a0b6
700b50ae80a1302d307e402010fe80711021108510f420e64054007d108f9073000550e1400a10747084a0caa09f10901044005a60d13070705030347001504a
20c9604710d200f650cf70230045106c307200c210a440033047604210b7307400e7401d205910718070108cb00d101540d8106660dcb07c1041205db04f1000
602d10eb108e10cdb08c30f3202f1085803eb0de10b1202d808eb07120aeb0bb50aa50ddb0a440ab30e620f8104c20fc30c570a2500fb0c210061000608b5033
600550afb0168043b081309a10efb042307cb08c3096304780297089307410ddb0f810d730ab105f90bf3080c0de10d4703030a5a08f5031403db055001fb024
903c40021039a0b170fa30e480f0c0e610b8708730d870dd40c1c0ddb009208040f7205e407e406260be405150c2c08c30897047306d302610df30ea4031c0f4
5063c0de1082c06060020084907c10d380e1c087105cb09a6004c00c40ac60686009205650dc60c4c001c02d603f10d450d57051c0b9102470a280ae9031c08a
7095c0a4400c30bcb0261024c0a2c07880f35084c0268013c026105650e2201ca084c0804036c00210ac8051109c507c9035c04da03c90dc30e4201840d15004
a0e0c08c302f90a680e7c087a095c05fb00e1027a07590c7002cb0a0606cb00200a750a7508d70e8c0685068500b304010f3c0301043003300e8c0f240f2409a
5013000e30130041404300ec60af50e8c09a501e604300aa40a9c0e8c0a25070802db03010a160a250a75069c03010bb50a9c04010aac040106ac0a7508ac093
10abc099c06300a0609310a16059c0f65033001b3029c06cc09bc083003cc0bbc00e30d990ecc06bc0e350f9c0430060204cc0fbc0fbc053007dc04010ebc09b
c00e308d70401023009300cdc06bc093109a504ac0bbc003005ec00200eac04ec08ec0931005508bc030106ac09a50af50a0301e60bb50eac0bdc09a508ec03a
c02cc01e60a16019c0bdc09ac01fc0fbc00ec041406ac01e60edc01cc0762079c04cc05cb07bc09dc09bc0bdc0bb50c0d002003fc081d06dc0afc07ec04cc0aa
401300ec609ec04fc0bec0bb5023003ac07f402ac0aec02c20ddc093109ac080d09bc02cc0a250a1600b30b2d06ec09bc04cc00ec0bdc0a250af5093306850f9
c0e3506ac00550af506b101300f65043d005501300b550130082d0615089c0a1d0ae204cc090d0001084d0f650428070c0020045d02ec0b5502300f650cac094
d079c064d0e35023009cc0414065d0f5d01bc025d0e830330076d0fac054d079c0a4d0c4d02ec00e3062d0fdc0e8305bc0f8c0aa40af507440e4d03ec09bc06d
c0e6d04fc0fbc0dcc008d0020092d04fc0001077d0b6d0a030d6d01b3048d0b06099c00e3066d0d8d01ac026d0e35029c077d068d0fd2088d00e30a8d099c04e
c00ac006d0ddc0b9d079c01b30eb6032d07440e5d01ac041402300c9d0d5d0f7d025d0b8d0f9d0414048d066d03bd037d00ec0b9c099d0af505c30f8d0a9d0bb
c0fad079c05ac080d00940130061501f6003d04cd07f40bb50227099c0f7d0f1d0e35076d0fd20b550aac00940af507020d7d078d0fbd0bbc0aa40cad057d013
b04fc056d0bdc0fdd00200709040106300f9d0ec6099d088d082d0aa40b3d06150e5d07f40a7d06bc0c05032d0cc4043003dd0d5d046d079c004d0f9d0d4d097
d0d4d0f650bfc0d35079c0f1d0b5d069d09bd004d00300ed400cc0fd202cc0e4d0af502a2022d0fd20730030e032d0be201ec03fd0e4d0d3b06ed02cc088202e
c09ed05710f650230002e036d040e079c05850401023d089504010bb5000106ad085d04cc0ab5079c07f4023d07cc0dcc023007f407fd041d023e099c0ead01e
501bc004d000e08cd023006cd093d0f3e0d0e0aec0ddc05cb08dd058d014e01ad099c0bdc0dbd0f0e024e009d0a060b5505ed0dcd02ec04ec0b6d033e072e08c
c0bfd0e5e0c9d0d2d015e037d0fed02cc03300c9d03ac019d019d06dc086e0bdd0e7d0a06090d0c9d0bec033003bd0cdd0b5e097d08bd0ddc015e05ac093e01a
c041e07cd0301044e0a5e0a4e025c04fc069d0d6e01fd012d03bd008e01fd06cd0b550c5e030109580a0606cd07f409580a5e085c084e055e03300e350a79032
d0a4e0ddc0dcc0c9e06ed0aa400ca08770d3e072e0f5c081d09cc0ec60c4e0ddd029e02cc0aae083e057d0aae06b80b3e0aae03d8095e01bc041e043009cc0e3
e0dbe0fdc04be0afd0d0d091d00ce0dcd06020f2d04ce093d04be03ac09cc0bdc081e081d08bd060203ac0f8e03de0ddc03dd01be0bac064e0c0e021e0cac0cd
e093e01be012d0bac03bd00010430093e0bac0f1d05ee0fed0bad00dd05ee04dc009e03dd0b9c070802ad007e06180abe01de085803dd088e089e06fe0020053
00cae08580d5d088e010f00ae055e04280ddc00ec02cc0ffe07de0b3e0b0f029e0e3e0e0f0efe037d0fec01b30d48057d0530019d001f019d0ece08580c6e08c
d0530056d0a7e01bc0001061f029e046d08580aa4079e032d082f0ddc0e7e08580ec6052f0f8c0dee076c013f029c0c9801ae0f1f082d037e0ddc0a0f0615073
f07fe054d0858026d082d04e809bc0d5d031f054f030106300e3e09be04ed0ece0a2d0b4f06ed01fe006d02d801b30d4f029c085e04ed064e095f0dbd0cac095
f03ed04ac02d800dc0cae045f0e9e0fd2059d0c3f0ddc04ec066f0d99007e0d6f0a4f0a6e09890c1e0e6f0aa4058c04ed00010f6f0a9d0933016f097f0b6d06b
103ec06d9078d05c304dd06300ec6097f01c8018f04ed093e06dc058f0c2e07f408a5098f0b6d07020c7f07f40d8f055e002a0c2e065f0bec067f069f081d000
d061507ed089e01af0a4f05de03af00200b1e0d0d00ca0c2e0d5d051d07cc059d04fa04ed057f011d0f650aaf09af065f059f0b9c0ffa0c2e064e073000e30ab
f09af03bd070e082b06ed030f08af07af097d042d05ae012d02cc073005ae07ee06420ec60dcf0b3e07300acd0ade097b0c2e0bee07df0a4f02ee048b0e8f08c
d0fab0bbc013e0c8c06dc0a75044202dc04340a2707ef0c610b2107ef0fcb05520cec0481065107eb040104720ed301e607f10e0d0301085406620bb50698094
009ff0a220203053d054b07310a250cb20de203001cb20688005505eb075d06b408f9048d00610e830cfb0fff048d0e270c0a048d08c20d71010101b300eb0c1
018880e310f1013010bd50dbb041c05e2004701c2099d04c20094017201010ec6001204fd0dd605f2039705cd04010963051e04f102001e4d09390ea10830131
105710b5507260fe2012e0401089703510c5d05401d510d9a052e03010869025007310fae06f60b2e0f830d5105710aa4091b05710ec605f207b30fe50401029
30a010d501301074b0c4e0550016019e60ba6065e04ff09601d4016840b6013880d83019e0b170a0601b300610c61055602301631017e0a7405520a3503c60c6
01e63068e028406400c0a033007f404310896049e040109c5099e0176005007ae057504a3034004970401072b06ce0901042b08ce0e0a005409901301033600d
e0d490f901ae709401c7702a013010d83021e086b06020ec60ed306ee0a740aa70602061509a30ba301c203fe0d401ec209fe0e0a05b200b2040f06b01268085
801b301f80d1f04010f3a002f088805d60c2f050105cb0a2f031304020202076c029207310f3f0034085008510fff02d01462047908400fc01ef30b400662053
0061507f9024f0401048c0b550b2202d80f65017a07e01ea0138508f9095f0cd1026f0a740750026908d9027f030102730923098f071b0f2a0e690336067f000
__map__
025200600a3e05240bde03b50ff9014400ff040903300002018101a00309110b11e60b490d30007601e0014d008e10111176011a012501341030003000c801060c1111e9018a03be041111130223015c0711112f023905de0311114702170c27110a118902380c23113011ce092110490d6e0d5300310681010903960c330c3c
11c801a80bb3023c11e901ce014c001b103711e90197022b110a1113024a00ac0b770737112f02b90239093c1147024400020356005511a50102035c04371183022d0949004d023c115f114e006f085e11020a37016711d701cd08a00267118e0a36110a11d302ef082f113f0c9505dd0a09031e0e54025602781189026005ab
0778110201410058003306490d250e601162118511c8016b0237027811c801600558008d1118015701de0388020a1118013206401096118a035200c00299110f1123029e11080736016510951102011e047910a5110a046010a9118a035504da10a911ac023001a1118a033c04a4111c11a50b8506a1119b09a1113405991176
010b01c802be115a01e00ac211c2018a03c51123018e1095117601440013059911401101024d00c1029511e9014501b3059911e901810bd811cf078310991113029d07ff0f95111302ee065c0795112f02ec09991152115c01ef109511470228032a03991147020a029911830239043407f41151059911d3025601140840105f
0d8a03a004fe1189027f011b1088025f0d6002981106128902ce0114010212cc105b025911061202014709fe110201890b151292117c0133061212ce0918128009c5011812fe0f18123904a1091812fd0354061c12da045c01fe11760149020f01921006127601490547100a117601c30142002c125a012d0b39122804fe11c8
01b80608100612e9012104fe1113024400fd06fe112f021e0b38127a0d8902810bde037a0d02011a014c008e10511220003f00560e070f27044902560e7a097602210730008d0f120147005d122f023904ee045911fa05980f03029b106a128302eb1184106112d302cc05560ef30e9f0bf210fa05e00f650b79108c0cdb0c06
124f09c90b2c010c09c6040c115f01be05af02a90a6a095a05b103ba041a0560021301d4066303530a15119b015b0273047301e70f5202fe0bfc09640682010903e003050c9505490718021c015a0514048d123f04d9011e029105fa023304c611b803c602720474045a05aa0450016b074e026808eb0991085106ff09430243
07ce07c3015702b5030508cf07a101b212d3116112e310a00b8b013c0a2a1182049a01e705150a4f0aef0b2109c509ee0271012b086108d203b7024a01ce0116071003fb090c12a4030906490df704a8121e07f3072e11140722113703f90ba112e702ba01ec099e12490d1605ef129b03ba01810b5a053e056c07cc127c04ce
12080b3705c101440337035c0d5b05e712bb0aee03b2084b006e0a150132113a0c20013c0c260104059705840d86018906e502e00a1a02e409570ae3013a1161080a013007270559001413770d2109c002c3013201620844006503870a5d02100121133a1209052806210ea012fb09160241110a0284041313210ea71236132c
014a11e704451112033b135c0daa04a812e5016c03dd0a430770064f114c002b0b4413200d80125407b2028b03ac0439096a091413980b5009290afe0312137f064010c406a312d1016105730662017a11ac016109b0030613180a2c0730041511ce077e110f086109630d6f0507134308d00183116a098b0c780f8e0c0d0103
13490ac7122203750823061d033201fc108c066504f406910b6707dd01ec087d134c0100022b0216037a022706d0011d0111138a011901cb12f40b4203010293027d131901f20b0313ba09e80fd00316022b021203dc01e6031e03d00b4201a303a503ba011d033d101a06e80230054f10eb121a1242018e016603d901400b4b
0230045900a10142027b013504b3060b0175097d13c6041f056d032f012b0962010201de017601b6130003af0377012800560223012b07ac097303c007270911082209e00163027f0bdd065d01ab0129007d13280061118b017409e604d306a0017f0354123502ac0183120c01c804cd05e7137a05df01380857110a014f031d
0727014e0787116108ec094a01bf139904db0b0c0677135b11fd132509f8014709c602a80aec0820052b012b0252002c001d031803470199138d05ac0b9912e8120f088211d60bbc051b0b090ae90482018a01e2092b0727140904a409c10698122f044807a607630157015502651140010a14fc13ee021407df091f05470197
05a905f00a08125200850131062a080214220377123d03160455009705e1067f038f08051407019705ef0b9c017c04320359012804aa059705f90bda05ad047107560038094f0b2d0520002700f71048008809000ca8121e069904630bae054a045505dc0a4504d10dbb135c021f0b0a05db05191413075b0368014201bd0bac
04151192127d09b5025f011010fb058113c9094e117509ce051513490085049c05440c2d1353036b0a5a04170620007e1422098114380983141e01ac01310680101513f41322044001c705e4051c0156023001410ac71376092f05e2086d14af037a058d149b0574052d099d017814e802cd085e02100a7b016605a7038a1226
10bb13b21436051101d9080f011d01a113540014132f048d14300199049103c3142b07c514890344030104a9145605dd0acd01b209ac012b06f2039e148411290b95120a012f06a214150105031911140a610c2006240c9f0a9c11750465019e02090159018e08f0015d016a07430ba704450598024f027e047c08bb131e0253
01e30dbe09a001f9080c01740c8c025300bb0249003c04d714e704bf13b3054902d714cb0439019c13a00718036505a4056c126d05360b79011f12820923148d012208d10851130401680a32019f0221016d0c31101a15eb0148134d021614ad011511b606ee137e0122014902f506a1136e016304290508022c01d804c0029b
04c103ae1152022e1158124e0d4215db12220354032d0ba6142601871060042d134202db144e008e08ad11a4051f023810a00775051607d0035b124b1492117301190356027b013a05bc052a04540bfd017007b102e0051e0ef50a3c15eb0167153f152e12bb12de017c013809aa0a0d011e135812481048042c0633123201b5
041e13d914bf02f7146e02f502200681157415cc038b0644109410f204f703e314cf077705c714530732146c140503440b7404820a4b148b156c108f148c1334096c03cf020a01450793011704c5014203620b870ab5017a05d211a603180c3e0428043407ab0203138f151f057002ff0322032700fc1181013c055110bc054d
02d9012615bc048415b004d5063004ad0860057c048f01bf136005440023135310cf06c90b4e138304f3019b113e15a314c81456101c0cc70a7405400bdc013401db01a7055a0b5f05471550039614310654037e0494021a016e0179012907fe099915090151141502ce0899016b0259101215b0066c030313f4082b04ed027c
025015880510015315490255159703b30e7b15f2035415000ada120303f01551150316ec142b05b501850b6c13a0078f15fb0967051b053601a705b00a0b018f14d5159a04d7159705bd0d52020a14ea12711536013013af024e02d40a8015090486027010fb055004a90a5704760811164712a7043013391132062e14c701d2
0a9e151e0685122316b0145104a3041e06ec09460c12158e14b3142d13b6140503ec099c14e6155016ea04a405b612c80447006c06e2059b12e51530015701cd151a16810145024b0c4f091813f0121d069d01f2126216e215e405a2121f06a702d2152501f301d6119d126216210a64019b12ba012d137316b405c701510aa6
08e8087e13ed024f0b6201ef1110070808ac011411850179169d0145043a0ec60388165f0922032d131f014600e8011a06ba157e01bb1458129610161657168904ce081c01820786059b099b162f046a14f406e0126504e80516079108e8019e096401261647158b161803ff07220bcd053b025f16c201b81496128207f206ac
163601230459021e1315076c026c0193018f14b613e6044202ba01ad0868097308440182076b0b7d151014d9120b14ee02e8017e162816ca16d51639144600f015bf0b2b13260b830a44050714060250058d149e15fd0107010707b515db03bd143205af055700610628018a037e14511533145510b510ab048f15de017712d9
05d103e7011903c80281047e14471233025116da16de0b550225011202fb05fd03b7156715f015c7145f0a1e01ae04b6134e002d005a04af134300ad154502070f04018d14b414180920015e022504d5017114d8149c0a6904ae132306dc097803a406520683057101a215bc10b610071534012801d7054e0bc2131d017e05dc
0104034309ab06bc05b801a307b302eb06671535171d17070b4808f21348066501bd014a056f10f60b8a01ee152e15d2090f074917e90a81169b0ab1095116f508030121174f158e0a5002bf061803e4014913a81488145605e30a1f178f034c17d1014e0be6042611d7034400af016509be05fc10640481046a178a14c70af9
014917cd1309153317b6029614e212f00a4405a3017609d31330074a046117350b43075500f001f30149172f058d012e094017e502f7147e110b161e014200891484037b0328174a174917e9136e016c04f80aa70356022900f015a1148105a1018d14f603f4012d1552027c173d0455034917a901f902820809022b028804b5
170509eb06000629014d027d17930b4c0149173909c514c5011b145609b9039b11600be315030312021a06901792176015330273066707230444010707461710031205f801971761042b0b9a061d146d17f8147e01a7034707d5177201d717ca035e153f1581175000831796134917b5175d0555026f131003a1149e16280178
099001a30b2800de01d2112100e713e717b41183053d011f02e4092c07b9032410ae04671513143015aa0bb60612014e038003b50297116d05b817d404a001a908e405a90b4a0ad40ab315ae174a0146170415aa02410ac301db0a6f03e7171916e2127306d31342013e0439045f09f1018a012700e00b68016106ec17b60634
059b08d20adb0861086601be01c3113e078b03490aca0a6c168912671223026605eb1549177012500736024e019f040c098a01240563014a04fc10cd09ff103d0351183c025b075a1817011a10100363063e074218970ac5164f00c6128b02700175076a063306e7175517c1162305f61146187802f305ae09690bce09b71576
081b16bf10f815290c250b53003f1486056e023f185a1458082f044f06c8105c052c067b16ed13640185121202b609eb019e1569077b0344013d172318c6040a14320a2c0a8912470bcb10041014072f018f01d706670cc014310507062d13490a5b0beb064901df1680035909ae0967168b01fe01aa18b117890b9c03b5045a
03f002f213ff085816fd14b50b1118b50424071202620a9512c602b302f91447058a0a0a171e0b2817e3136c0163181202e7167e17380a100ad80132012f05bb14bc05aa13f11564154217b5180c0ab60ef50a1d01f217f41700174700b30bc70a8e085502d901de1865040b01b302010557169b085005cb016e0c4a16c11490
__sfx__
01ad026014c6101411170131885610c1410851164250f45315c53060761583515826144140b8350303215803184240004512033008300583712c1212c620806009020024570346101457010530980312c670ac50
01941862164670843001807100331001016c500242517456080221002617060110161840203c321344202c201280614c3112051090541600305860088730986413c540b8051086303015098620bc570907304c42
09b9041509c04048060a070044300502518005020770a06307457014100300305c33150220185416c4618c640843318414194360507601c060945103c35148421484012c56060660c4110180301c1713c2601027
01df154b1687009c760f0360fc5301076020160100709443064120143500c510a4770a4430a47704466070540600602460014151944604010174140741419425140110a023010250006304426014050307004c76
06da06531306009851024310a85301860018340401601c04130061004619c430bc32060501887407877040000584101433020230142709c260940402c4501c420105110c26070330a80302c71084141983119853
09de131100c17018561385105474024310441401c4012c2304016194740b01402847054520b45301c101907202c4205c3501064004750bc33148430b44207c56044020040200c0104c230b4470101208c0518027
0f20105019c470784503c161242101c2508c100a84202c5505c71080120303619c43014211140404860010001205300834158360343605c400f46001c15198260280009452160220607705074000021584112841
176104ae0400103450018700946401c2201445008711485306072020160a8120381618831074260b4731781618c0505c720a443018640582115c210486208066110721546318c1701436130500b8360300409872
15bf0ac11781508c3616020070511200011c130b0720b817030040b0520101114044180610ac100ac5004c761901106c230283306834064340040011407084260801202c2001056084060742101c3605c7409446
169d01c00a0410483503472194750347402c730a05106c321643116852164420240204c730a0570540204061014151441119421160710604316c26048740a4320505207873148340f01415026138750743613811
08bb16cd0906304841128150fc16104250086702427180030484209c6701c2203c40164051a4320a85102423014131701500833064500184003067140440b04002c3703c41040451884216016070530445018c54
064012ac014450b44301802010450a4440005001853138061100401424010221203505834020161544102874058250f0610cc55020741a012034151a8740701402c0212c401285301c3501c31034330007716062
0000000001811150340200505025024201645514c5705022144710644500045128600c00300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
