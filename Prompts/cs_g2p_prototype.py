# Prototype of the Czech G2P + rhyme keys from RYMOMAT_PLAN.md, to verify the plan's test vectors.
VOW = set("aeiouAEIOUWYQ")
PAIRS = [("b","p"),("d","t"),("D","T"),("g","k"),("v","f"),("z","s"),("Z","S"),("h","x"),("3","c"),("4","C")]
VOICED = {a:b for a,b in PAIRS}; VOICELESS = {b:a for a,b in PAIRS}
OBS = set(VOICED) | set(VOICELESS)
LET = {"á":"A","é":"E","í":"I","ó":"O","ú":"U","ů":"U","y":"i","ý":"I","š":"S","ž":"Z","č":"C","ř":"R","ď":"D","ť":"T","ň":"N"}
SOFT = {"d":"D","t":"T","n":"N"}

def g2p(w, before_pause=True):
    w = "".join(ch for ch in w.lower() if ch.isalpha())
    out = []; i = 0
    while i < len(w):
        two = w[i:i+2]; c = w[i]
        if two == "ch": out.append("x"); i += 2; continue
        if two == "dž": out.append("4"); i += 2; continue
        if two == "dz": out.append("3"); i += 2; continue
        if two == "ou": out.append("W"); i += 2; continue
        if two == "au": out.append("Y"); i += 2; continue
        if two == "eu": out.append("Q"); i += 2; continue
        if c == "q": out += ["k","v"]; i += 1; continue
        if c == "w": out.append("v"); i += 1; continue
        if c == "x": out += ["k","s"]; i += 1; continue
        if c == "ě":
            p = out[-1] if out else ""
            if p in SOFT: out[-1] = SOFT[p]; out.append("e")
            elif p in "bpvf" and p: out += ["j","e"]
            elif p == "m": out += ["N","e"]
            else: out.append("e")
            i += 1; continue
        if c in "ií" and out and out[-1] in SOFT:      # written i/í only, never y/ý
            out[-1] = SOFT[out[-1]]
        out.append(LET.get(c, c))
        # hiatus glide: consonant + i/í + vowel -> ij (melodie -> meloDije)
        if c in "ií" and len(out) >= 2 and out[-2] not in VOW and i+1 < len(w) and w[i+1] in "aáeéěíoóuúů":
            out.append("j")
        i += 1
    # geminates
    ph = []
    for p in out:
        if ph and ph[-1] == p and p not in VOW: continue
        ph.append(p)
    # sh -> sx
    for k in range(len(ph)-1):
        if ph[k] == "s" and ph[k+1] == "h": ph[k+1] = "x"
    # final devoicing
    if before_pause and ph and ph[-1] in VOICED: ph[-1] = VOICED[ph[-1]]
    # regressive assimilation; v does not trigger voicing
    for k in range(len(ph)-2, -1, -1):
        a, b = ph[k], ph[k+1]
        if a in OBS and b in OBS:
            if b in VOICELESS:               # b is voiceless
                if a in VOICED: ph[k] = VOICED[a]
            elif b in VOICED and b != "v":   # b is voiced, triggers voicing
                if a in VOICELESS: ph[k] = VOICELESS[a]
    return "".join(ph)

def nuclei(p):
    n = []
    for i, c in enumerate(p):
        if c in VOW: n.append(i)
        elif c in "rl" and i > 0 and p[i-1] not in VOW and (i+1 == len(p) or p[i+1] not in VOW): n.append(i)
        elif c == "m" and i > 0 and i+1 == len(p) and p[i-1] not in VOW: n.append(i)
    return n

FOLD = str.maketrans("AEIOU", "aeiou")
def keys(p):
    n = nuclei(p)
    if not n: return None
    last = n[-1]; open_ = last == len(p)-1
    if open_ and last > 0 and (last-1) not in n: f1 = p[last-1:]
    else: f1 = p[last:]
    f2 = p[n[-2]:] if len(n) >= 2 else None
    as2 = (p[n[-2]] + p[n[-1]]).translate(FOLD) if len(n) >= 2 else None
    return dict(f1=f1, f2=f2, as2=as2, open=open_, syl=len(n))

def classify(a, b):
    pa, pb = g2p(a), g2p(b); ka, kb = keys(pa), keys(pb)
    if pa == pb: return "identical"
    if ka["f2"] and ka["f2"] == kb["f2"]: return "full"
    if ka["f1"] == kb["f1"]:
        if not ka["open"]: return "masc"
        return "masc" if ka["syl"] == 1 and kb["syl"] == 1 else "weak"
    if ka["f2"] and kb["f2"] and ka["f2"].translate(FOLD) == kb["f2"].translate(FOLD): return "looseFull"
    if ka["f1"].translate(FOLD) == kb["f1"].translate(FOLD) and ka["open"] == kb["open"]: return "loose"
    # open monosyllables, same vowel, different onset (dá/má) -> loose
    if ka["open"] and kb["open"] and ka["syl"] == 1 and kb["syl"] == 1 and ka["f1"][-1].translate(FOLD) == kb["f1"][-1].translate(FOLD): return "loose"
    if ka["as2"] and ka["as2"] == kb["as2"]: return "assonance"
    return "none"

vec = dict(led="let", hrad="hrat", hvozd="hvost", sníh="sNIx", hřích="hRIx", oběd="objet", město="mNesto",
  dítě="DITe", děti="DeTi", chata="xata", kdo="gdo", vstát="fstAt", sbor="zbor", shoda="sxoda", tužka="tuSka",
  zpěv="spjef", mouka="mWka", taxi="taksi", být="bIt", bít="bIt", vůz="vUs", krk="krk", dým="dIm", ticho="Tixo",
  tykev="tikef", lev="lef", svět="svjet", mráz="mrAs", melodie="meloDije", marie="marije", poesií="poesijI")
bad = [(w, g2p(w), e) for w, e in vec.items() if g2p(w) != e]
print("G2P vectors:", len(vec) - len(bad), "/", len(vec), "ok", bad)

syl = dict(vlk=1, krk=1, nesl=2, sedm=2, rty=1, lhát=1, mnoho=2, zrno=2, jablko=3, mlha=2, sklo=1, hrdlo=2, vítr=2, láska=2, svoboda=3)
bads = [(w, keys(g2p(w))["syl"], e) for w, e in syl.items() if keys(g2p(w))["syl"] != e]
print("syllables:", len(syl) - len(bads), "/", len(syl), "ok", bads)

cls = [("být","bít","identical"),("láska","páska","full"),("voda","svoboda","full"),("hrad","sad","masc"),
  ("hvozd","most","masc"),("voda","věda","weak"),("děti","letí","looseFull"),("mráz","hlas","loose"),
  ("láska","dáma","assonance"),("voda","ryba","none"),("sníh","hřích","masc"),("led","let","identical"),("oběd","hned","masc"),("dá","má","loose"),("jsou","svou","loose")]
badc = [(a, b, classify(a, b), e) for a, b, e in cls if classify(a, b) != e]
print("classification:", len(cls) - len(badc), "/", len(cls), "ok", badc)
for w in ["voda","láska","hrad","děti","krk"]:
    print(w, g2p(w), keys(g2p(w)))
