#!/usr/bin/env python3
"""
yn00_eastwest_final.py
dN/dS pairwise con yn00. Rutas absolutas, sin os.chdir.
Ejecutar desde ~/EastWestDM/

USO:
    python3 scripts/yn00_eastwest_final.py --test
    nohup python3 scripts/yn00_eastwest_final.py > act2/yn00_results/run.log 2>&1 &
"""
import sys, os, subprocess, shutil, csv, json
from pathlib import Path

BASE    = Path(__file__).parent.parent.resolve()
CDS     = BASE / "act2/cds"
OUT     = BASE / "act2/yn00_results"
TMPDIR  = OUT / "tmp"
CSV_OUT = OUT / "dnds_final.csv"
CKPT    = OUT / "ckpt_final.json"

OUT.mkdir(parents=True, exist_ok=True)
TMPDIR.mkdir(exist_ok=True)

STOP = {"TAA","TAG","TGA"}

SPECIES = [
    "pan_troglodytes","gorilla_gorilla","pongo_abelii",
    "macaca_mulatta","callithrix_jacchus",
    "mus_musculus","rattus_norvegicus","bos_taurus",
    "canis_lupus_familiaris","loxodonta_africana",
    "tursiops_truncatus","vulpes_vulpes","ursus_americanus"
]

def readfa(p):
    s = ""
    for l in open(p):
        if not l.startswith(">"): s += l.strip().upper()
    s = s[:len(s)-len(s)%3]
    if len(s) >= 3 and s[-3:] in STOP: s = s[:-3]
    return s

def calc_pair(gene, sp):
    f1 = CDS / f"{gene}_homo_sapiens.fa"
    f2 = CDS / f"{gene}_{sp}.fa"
    if not f1.exists() or not f2.exists():
        return None

    s1 = readfa(f1)
    s2 = readfa(f2)
    if len(s1) < 150 or len(s2) < 150:
        return None

    wdir = TMPDIR / f"{gene}_{sp}"
    wdir.mkdir(exist_ok=True)

    # FASTA raw con rutas absolutas
    raw = wdir / "raw.fa"
    raw.write_text(f">hs\n{s1}\n>sp\n{s2}\n")

    # Alinear
    r = subprocess.run(
        ["mafft", "--auto", "--quiet", str(raw)],
        capture_output=True, text=True
    )
    if r.returncode != 0 or not r.stdout.strip():
        shutil.rmtree(wdir, ignore_errors=True)
        return None

    # Parsear alineamiento
    seqs = {}; cur = None
    for l in r.stdout.strip().split("\n"):
        if l.startswith(">"): cur = l[1:]; seqs[cur] = ""
        elif cur: seqs[cur] += l.strip().upper()
    if len(seqs) != 2:
        shutil.rmtree(wdir, ignore_errors=True)
        return None

    # Limpiar gaps y stop
    clean = {}
    for n, s in seqs.items():
        s = s.replace("-", "")
        s = s[:len(s) - len(s) % 3]
        if len(s) >= 3 and s[-3:] in STOP: s = s[:-3]
        clean[n] = s

    mlen = min(len(s) for s in clean.values())
    mlen = mlen - mlen % 3
    if mlen < 150:
        shutil.rmtree(wdir, ignore_errors=True)
        return None

    # Fichero PAML
    paml = wdir / "seq.paml"
    names = list(clean.keys())
    with open(paml, "w") as f:
        f.write(f" 2  {mlen}\n\n")
        for n in names:
            f.write(f"{n[:30]:<30}\n{clean[n][:mlen]}\n\n")

    # CTL con rutas absolutas — eliminar symlink del sistema
    ctl = wdir / "yn00.ctl"
    if ctl.is_symlink(): ctl.unlink()
    ctl.write_text(
        f"      seqfile = {paml}\n"
        f"      outfile = {wdir / 'yn_out'}\n"
        "      verbose = 0\n"
        "        icode = 0\n"
        "    weighting = 0\n"
        "   commonf3x4 = 0\n"
    )

    # Correr yn00 con cwd=wdir (escribe 2YN.dN aqui)
    try:
        subprocess.run(
            ["yn00", "yn00.ctl"],
            capture_output=True, text=True,
            timeout=60, cwd=str(wdir)
        )
    except subprocess.TimeoutExpired:
        shutil.rmtree(wdir, ignore_errors=True)
        return None

    # Leer 2YN.dN y 2YN.dS
    dn_f = wdir / "2YN.dN"
    ds_f = wdir / "2YN.dS"

    if not dn_f.exists() or not ds_f.exists():
        shutil.rmtree(wdir, ignore_errors=True)
        return None

    def read_val(p):
        for l in open(p):
            parts = l.strip().split()
            if len(parts) == 2:
                try: return float(parts[1])
                except: pass
        return None

    dn = read_val(dn_f)
    ds = read_val(ds_f)
    shutil.rmtree(wdir, ignore_errors=True)

    if dn is None or ds is None or ds <= 0: return None
    omega = dn / ds
    if omega > 99 or ds > 10: return None
    return round(omega, 6), round(dn, 6), round(ds, 6)

def main():
    test = "--test" in sys.argv
    genes = sorted(f.name.replace("_homo_sapiens.fa", "")
                   for f in CDS.glob("*_homo_sapiens.fa"))
    if test: genes = ["SLC5A2", "UCP1", "TRPA1"]

    # Checkpoint
    done = json.load(open(CKPT)) if (CKPT.exists() and not test) else []
    done_genes = {r["gene"] for r in done}
    genes = [g for g in genes if g not in done_genes]

    # CSV
    if not CSV_OUT.exists():
        with open(CSV_OUT, "w", newline="") as f:
            csv.writer(f).writerow(["gene","species","omega","dn","ds"])

    print(f"Genes: {len(genes)} | Especies: {len(SPECIES)}")
    print(f"Output: {CSV_OUT}")

    for i, gene in enumerate(genes):
        rows = []; oms = []

        for sp in SPECIES:
            res = calc_pair(gene, sp)
            if res:
                omega, dn, ds = res
                rows.append([gene, sp, omega, dn, ds])
                oms.append(omega)

        done += [{"gene": r[0], "species": r[1], "omega": r[2]}
                 for r in rows]

        om_str = f"omega_mean={sum(oms)/len(oms):.4f}" if oms else "no_omega"
        print(f"[{i+1}/{len(genes)}] {gene}: {len(oms)}/{len(SPECIES)} OK | {om_str}",
              flush=True)

        with open(CSV_OUT, "a", newline="") as f:
            csv.writer(f).writerows(rows)

        if (i + 1) % 10 == 0:
            json.dump(done, open(CKPT, "w"))
            print("  [checkpoint]", flush=True)

    json.dump(done, open(CKPT, "w"))
    print(f"\nCOMPLETADO — {CSV_OUT}")

    ok = [r for r in done if r.get("omega")]
    print(f"Pares OK: {len(ok)}")
    pos = [r for r in ok if r["omega"] > 1]
    print(f"omega>1: {len(pos)}")
    for r in sorted(pos, key=lambda x: -x["omega"])[:10]:
        print(f"  {r['gene']:<15} {r['species']:<30} {r['omega']:.4f}")

if __name__ == "__main__":
    main()
