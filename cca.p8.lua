
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

run_tests = true
unit_test = {}
if run_tests then
    srand(12345)

    unit_test = {
        -- STARTING THE GAME
        'CONTINUE',
        'N',
        -- GETTING INTO THE CAVE
        'BUILDING',
        'TAKE KEYS',
        'TAKE LAMP',
        'EXIT',
        'S', 'SOUTH', 'DOWN',
        'OPEN GRATE',
        'DOWN',
        'WEST',
        'TAKE CAGE',
        'W',
        'LAMP ON',
        'TAKE ROD',
        'XYZZY',
        'XYZZY',
        'W',
        'DROP ROD',
        'W',
        'TAKE BIRD',
        'EAST',
        'TAKE ROD',
        'WEST',
        'WEST',
        'D',
        'D',
        -- LEVEL 1 - SNAKES AND PLUGHS
        'DROP BIRD',
        'DROP ROD',
        'TAKE BIRD',
        'TAKE ROD',
        'W', 'TAKE COINS',
        'BACK',
        'S', 'TAKE JEWELS',
        'BACK',
        'N', 'TAKE SILVER',
        'N', 'PLUGH',
        'DROP COINS',
        'DROP JEWELS',
        'DROP SILVER',
        'DROP KEYS',
        'PLUGH',
        'S', 'D', 'W', 'D',
        'W', 'SLAB', 'S', 'E',
    }
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

    local input = ''
    if #unit_test > 0 then
        input = unit_test[1]
        deli(unit_test, 1)
        FORTRAN_WRITE(input .. "\n")
    else
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
        input = sub(t, 1, 20)
    end
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
IOBJ = INIT_ARR1(1000)
ICHAIN = INIT_ARR1(1000)
IPLACE = INIT_ARR1(1000)
IFIXED = INIT_ARR1(1000)
COND = INIT_ARR1(1000)
PROP = INIT_ARR1(1000)
ABB = INIT_ARR1(1000)
LLINE = INIT_ARR2(1000,22)
LTEXT = INIT_ARR1(1000)
STEXT = INIT_ARR1(1000)
KEY = INIT_ARR1(1000)
DEFAULT = INIT_ARR1(1000)
TRAVEL = INIT_ARR1(1000)
TK = INIT_ARR1(1000)
KTAB = INIT_ARR1(1000)
ATAB = INIT_ARR1(1000)
BTEXT = INIT_ARR1(1000)
DSEEN = INIT_ARR1(1000)
DLOC = INIT_ARR1(1000)
ODLOC = INIT_ARR1(1000)
DTRAV = INIT_ARR1(1000)
RTEXT = INIT_ARR1(1000)
JSPKT = INIT_ARR1(1000)
IPLT = INIT_ARR1(1000)
IFIXT = INIT_ARR1(1000)
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
