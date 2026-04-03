#!/usr/bin/env python3
"""
redownload_hs_cds.py
Re-descarga CDS de homo_sapiens tomando el transcrito más largo (canónico).
Corrige el problema de múltiples transcritos donde se tomaba el más corto.
"""
import urllib.request
import urllib.error
import json
import time
from pathlib import Path

CDS_DIR = Path("act2/cds")
BASE    = "https://rest.ensembl.org"
DELAY   = 0.2

def get_longest_cds(ensg):
    """Obtiene el CDS más largo para un ENSG dado."""
    url = f"{BASE}/sequence/id/{ensg}?type=cds&multiple_sequences=1"
    req = urllib.request.Request(url, headers={"Accept": "text/x-fasta"})
    try:
        with urllib.request.urlopen(req, timeout=25) as r:
            content = r.read().decode()
    except Exception as e:
        return None, None

    # Parsear todos los transcritos
    seqs = {}
    current = None
    for line in content.strip().split("\n"):
        if line.startswith(">"):
            current = line[1:]
            seqs[current] = ""
        elif current:
            seqs[current] += line.strip()

    if not seqs:
        return None, None

    # Tomar el más largo con longitud múltiplo de 3
    best_name = None
    best_seq  = ""
    for name, seq in seqs.items():
        seq_clean = seq[:len(seq) - len(seq) % 3]
        if len(seq_clean) > len(best_seq):
            best_seq  = seq_clean
            best_name = name

    return best_name, best_seq

def get_ensg(symbol):
    """Obtiene ENSG para un símbolo génico."""
    url = f"{BASE}/xrefs/symbol/homo_sapiens/{symbol}"
    req = urllib.request.Request(url, headers={"Accept": "application/json"})
    try:
        with urllib.request.urlopen(req, timeout=15) as r:
            data = json.loads(r.read())
        return next((x["id"] for x in data if x.get("type") == "gene"), None)
    except:
        return None

def main():
    # Genes con CDS de homo_sapiens ya descargados
    genes = sorted([
        f.name.replace("_homo_sapiens.fa", "")
        for f in CDS_DIR.glob("*_homo_sapiens.fa")
    ])
    print(f"Genes a re-descargar: {len(genes)}")

    ok = err = fixed = 0
    for i, gene in enumerate(genes):
        outfile = CDS_DIR / f"{gene}_homo_sapiens.fa"

        # Ver longitud actual
        current_seq = ""
        for line in open(outfile):
            if not line.startswith(">"):
                current_seq += line.strip()

        # Obtener ENSG
        ensg = get_ensg(gene)
        time.sleep(DELAY)
        if not ensg:
            print(f"[{i+1}/{len(genes)}] {gene}: sin ENSG")
            err += 1
            continue

        # Obtener transcrito más largo
        name, seq = get_longest_cds(ensg)
        time.sleep(DELAY)

        if not seq or len(seq) < 150:
            print(f"[{i+1}/{len(genes)}] {gene}: sin CDS valido")
            err += 1
            continue

        # Comparar longitudes
        old_len = len(current_seq)
        new_len = len(seq)

        if new_len > old_len:
            # Actualizar fichero
            with open(outfile, "w") as f:
                f.write(f">{gene}_homo_sapiens\n{seq}\n")
            print(f"[{i+1}/{len(genes)}] {gene}: {old_len} -> {new_len} bp FIXED ({name})")
            fixed += 1
        else:
            print(f"[{i+1}/{len(genes)}] {gene}: {old_len} bp OK (no change)")
            ok += 1

    print(f"\nCompletado — OK:{ok} FIXED:{fixed} ERR:{err}")
    print(f"Genes corregidos: {fixed}/{len(genes)}")

if __name__ == "__main__":
    main()
