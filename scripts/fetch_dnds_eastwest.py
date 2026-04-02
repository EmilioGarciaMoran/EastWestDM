#!/usr/bin/python3
# -*- coding: utf-8 -*-
"""
fetch_dnds_eastwest.py
Obtiene dN/dS desde Ensembl Compara REST API para genes East-West Diabetes.
Sin dependencias externas — solo stdlib Python 3.
Con checkpoint para reanudar si se interrumpe.

USO:
    python3 fetch_dnds_eastwest.py          # todos los genes (~45 min)
    python3 fetch_dnds_eastwest.py --test   # test con SLC5A2
"""

import urllib.request
import urllib.error
import json
import csv
import time
import argparse
from pathlib import Path

# =============================================================================
# CONFIGURACION
# =============================================================================

API     = "https://rest.ensembl.org"
DELAY   = 0.15
RETRIES = 3

# 14 especies del estudio — mismas que en PAML
SPECIES = [
    "pan_troglodytes",
    "gorilla_gorilla",
    "pongo_abelii",
    "macaca_mulatta",
    "callithrix_jacchus",
    "mus_musculus",
    "rattus_norvegicus",
    "bos_taurus",
    "canis_lupus_familiaris",
    "loxodonta_africana",
    "tursiops_truncatus",
    "vulpes_vulpes",
    "ursus_americanus",
]

# 189 genes candidatos East-West Diabetes
GENES = [
    # Glucose metabolism
    "GCK","HK1","HK2","HK3","PFKL","PFKM","PFKP",
    "ALDOA","ALDOB","ALDOC","TPI1","GAPDH","PGK1","PGK2",
    "PGAM1","ENO1","ENO2","PKM","PKLR","LDHA","LDHB",
    "G6PC","G6PC2","FBP1","FBP2","PCK1","PCK2",
    "PGM1","PGM2","UGP2","PYGL","PYGM","PYGB",
    "SLC2A1","SLC2A2","SLC2A3","SLC2A4","SLC2A5",
    "SLC5A1","SLC5A2","SLC5A4",
    "INS","INSR","IRS1","IRS2","PIK3R1","AKT1","AKT2",
    "FOXO1","PPARGC1A","PPARG","ADIPOQ","LEP","LEPR",
    "G6PD","TALDO1","TKT",
    # Cold response / thermogenesis
    "UCP1","UCP2","UCP3","TRPM8","TRPA1",
    "CIRBP","RBM3","HSPA1A","HSPA5","HSPA8",
    "AGT","ACE","AGTR1","CYP11B2",
    "SLC12A1","SLC12A2","SLC12A3",
    "ADRB3","ADRB2","ADRB1",
    "DIO1","DIO2","THRA","THRB",
    "PPARA","PPARD","CPT1A","CPT1B","CPT2",
    "FASN","ACACA","DGAT1","DGAT2","PLIN1","LPL",
    # Gluconeogenesis
    "PC","GOT1","GOT2","MDH1","MDH2","ME1","ME2",
    "CREB1","HNF4A",
    # Insulin signaling
    "IGF1R","IGF1","IRS4",
    "PIK3CA","PTEN","PDPK1","AKT3",
    "TSC1","TSC2","MTOR","GSK3A","GSK3B",
    "FOXO3","SLC2A4","PTPN1","GRB2",
    # Lipid homeostasis
    "APOB","APOE","APOC1","APOC2","APOC3","APOA1","APOA5",
    "LDLR","PCSK9","HMGCR","SCD","ELOVL6",
    "DGAT1","MGLL","LIPE","PNPLA2",
    "ANGPTL3","ANGPTL4","MTTP","ABCA1","ABCG5","ABCG8",
]

# Eliminar duplicados manteniendo orden
seen = set()
GENES = [g for g in GENES if not (g in seen or seen.add(g))]

# =============================================================================
# HTTP
# =============================================================================

def get_json(url):
    req = urllib.request.Request(
        url,
        headers={"Content-Type": "application/json",
                 "Accept": "application/json"}
    )
    with urllib.request.urlopen(req, timeout=20) as resp:
        return json.loads(resp.read().decode("utf-8"))

# =============================================================================
# dN/dS
# =============================================================================

def get_dnds(gene, target_sp):
    url = (
        f"{API}/homology/symbol/human/{gene}"
        f"?target_species={target_sp}&type=orthologues&aligned=0&cigar_line=0"
    )
    empty = {"status": "error", "dn_ds": None, "dn": None, "ds": None,
             "tipo": "", "gen_target": "", "identidad": None}

    for intento in range(RETRIES):
        try:
            data       = get_json(url)
            time.sleep(DELAY)
            homologies = data.get("data", [{}])[0].get("homologies", [])

            if not homologies:
                return {**empty, "status": "sin_ortologo"}

            best  = next(
                (h for h in homologies if "one2one" in h.get("type", "")),
                homologies[0]
            )
            dn    = best.get("dn")
            ds    = best.get("ds")
            omega = best.get("dn_ds")
            if omega is None and dn is not None and ds is not None:
                try:
                    omega = float(dn) / float(ds) if float(ds) > 0 else None
                except (TypeError, ZeroDivisionError):
                    omega = None

            return {
                "status":     "ok",
                "dn_ds":      omega,
                "dn":         dn,
                "ds":         ds,
                "tipo":       best.get("type", ""),
                "gen_target": best.get("target", {}).get("gene_id", ""),
                "identidad":  best.get("target", {}).get("perc_id", None),
            }

        except urllib.error.HTTPError as e:
            if e.code == 429:
                espera = int(e.headers.get("Retry-After", 10))
                print(f"  [rate limit] esperando {espera}s...")
                time.sleep(espera)
            else:
                if intento == RETRIES - 1:
                    return {**empty, "status": f"HTTP_{e.code}"}
                time.sleep(2)
        except Exception as ex:
            if intento == RETRIES - 1:
                return {**empty, "status": f"error:{ex}"}
            time.sleep(2)

    return {**empty, "status": "max_retries"}

# =============================================================================
# PIPELINE
# =============================================================================

CAMPOS = ["gene","species","status","dn_ds","dn","ds",
          "tipo","gen_target","identidad"]

def run(genes, salida_dir):
    salida     = Path(salida_dir)
    salida.mkdir(exist_ok=True, parents=True)
    checkpoint = salida / "checkpoint_dnds.json"

    if checkpoint.exists():
        with open(checkpoint) as f:
            registros = json.load(f)
        genes_hechos = set(r["gene"] for r in registros)
        genes = [g for g in genes if g not in genes_hechos]
        print(f"Checkpoint: {len(genes_hechos)} genes ya hechos. Retomando...")
    else:
        registros = []

    total = len(genes) * len(SPECIES)
    eta   = total * DELAY / 60
    print(f"Genes a procesar : {len(genes)}")
    print(f"Especies         : {len(SPECIES)}")
    print(f"Requests totales : {total}  (~{eta:.0f} min)\n")

    for i, gene in enumerate(genes):
        print(f"[{i+1}/{len(genes)}] {gene}")
        for sp in SPECIES:
            res   = get_dnds(gene, sp)
            omega = res["dn_ds"]
            flag  = "OK" if omega is not None else "--"
            val   = f"{omega:.4f}" if omega is not None else "N/A"
            print(f"     {flag} {sp:<30} omega={val}  [{res['status']}]")
            registros.append({"gene": gene, "species": sp, **res})

        # Checkpoint cada 10 genes
        if (i + 1) % 10 == 0:
            with open(checkpoint, "w") as f:
                json.dump(registros, f)
            print(f"  [checkpoint saved — {len(registros)} registros]")

    with open(checkpoint, "w") as f:
        json.dump(registros, f)

    # CSV crudo
    crudo = salida / "dnds_eastwest_raw.csv"
    with open(crudo, "w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=CAMPOS)
        w.writeheader()
        w.writerows(registros)
    print(f"\nCSV crudo: {crudo}")
    return registros

# =============================================================================
# RESUMEN
# =============================================================================

def resumen(registros, salida_dir):
    salida  = Path(salida_dir)
    genes   = list(dict.fromkeys(r["gene"] for r in registros))

    # Categorias biologicas
    cold_genes = {
        "UCP1","UCP2","UCP3","TRPM8","TRPA1","CIRBP","RBM3",
        "AGT","ACE","AGTR1","CYP11B2","ADRB3","ADRB2","ADRB1",
        "DIO1","DIO2","THRA","THRB","PPARA","CPT1A","CPT1B"
    }
    glucose_genes = {
        "SLC5A2","SLC5A4","SLC2A1","SLC2A2","SLC2A3","SLC2A4","SLC2A5",
        "GCK","HK1","HK2","ALDOA","ALDOB","ENO1","PKM","LDHA","LDHB",
        "PCK1","PCK2","G6PC","FBP1","FBP2","PPARG","FOXO1",
        "IRS1","IRS2","INSR","AKT1","AKT2","PIK3R1"
    }

    filas = []
    for gene in genes:
        sub   = [r for r in registros if r["gene"] == gene]
        omegas = [r["dn_ds"] for r in sub
                  if r["dn_ds"] is not None and r["status"] == "ok"]

        chimp = next((r["dn_ds"] for r in sub
                      if r["species"] == "pan_troglodytes"
                      and r["dn_ds"] is not None), None)
        mouse = next((r["dn_ds"] for r in sub
                      if r["species"] == "mus_musculus"
                      and r["dn_ds"] is not None), None)

        axis = ("Both" if gene in cold_genes and gene in glucose_genes
                else "Cold/thermal" if gene in cold_genes
                else "Western/glucose" if gene in glucose_genes
                else "Other")

        filas.append({
            "gene":           gene,
            "axis":           axis,
            "omega_chimp":    chimp,
            "omega_mouse":    mouse,
            "omega_mean":     sum(omegas)/len(omegas) if omegas else None,
            "omega_max":      max(omegas) if omegas else None,
            "n_species_ok":   len(omegas),
        })

    out = salida / "dnds_eastwest_summary.csv"
    campos = ["gene","axis","omega_chimp","omega_mouse",
              "omega_mean","omega_max","n_species_ok"]
    with open(out, "w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=campos)
        w.writeheader()
        w.writerows(filas)

    print("\n" + "="*65)
    print("RESUMEN — omega por gen (ordenado por omega_mean desc)")
    print("="*65)
    filas_ord = sorted([f for f in filas if f["omega_mean"] is not None],
                       key=lambda x: -x["omega_mean"])
    print(f"{'gene':<15} {'axis':<18} {'w_chimp':>8} {'w_mouse':>8} {'w_mean':>8}")
    print("-"*60)
    for f in filas_ord[:30]:
        oc = f"{f['omega_chimp']:.4f}" if f["omega_chimp"] else "   N/A"
        om = f"{f['omega_mouse']:.4f}"  if f["omega_mouse"] else "   N/A"
        ow = f"{f['omega_mean']:.4f}"   if f["omega_mean"]  else "   N/A"
        print(f"{f['gene']:<15} {f['axis']:<18} {oc:>8} {om:>8} {ow:>8}")

    print(f"\nGuardado: {out}")

    # Genes con omega > 1 (seleccion positiva)
    pos_sel = [f for f in filas if f["omega_mean"] and f["omega_mean"] > 1.0]
    if pos_sel:
        print(f"\nGenes con omega_mean > 1 (seleccion positiva): {len(pos_sel)}")
        for f in sorted(pos_sel, key=lambda x: -x["omega_mean"]):
            print(f"  {f['gene']:<15} {f['axis']:<18} omega={f['omega_mean']:.4f}")

# =============================================================================
# TEST
# =============================================================================

def test():
    print("TEST: SLC5A2 vs pan_troglodytes...")
    res = get_dnds("SLC5A2", "pan_troglodytes")
    print(json.dumps(res, indent=2))
    if res["dn_ds"] is not None:
        print(f"\nOK — omega = {res['dn_ds']:.4f}")
    else:
        print(f"\nFALLO ({res['status']})")

# =============================================================================
# MAIN
# =============================================================================

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--test",   action="store_true",
                        help="Test con SLC5A2 (5 segundos)")
    parser.add_argument("--salida", default="act2/dnds_results",
                        help="Directorio de salida")
    args = parser.parse_args()

    if args.test:
        test()
    else:
        print(f"East-West Diabetes — dN/dS pipeline")
        print(f"Genes: {len(GENES)} | Especies: {len(SPECIES)}")
        print(f"ETA: ~{len(GENES)*len(SPECIES)*DELAY/60:.0f} min\n")
        regs = run(GENES, args.salida)
        resumen(regs, args.salida)
