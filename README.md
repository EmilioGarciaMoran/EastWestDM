# East-West Diabetes Story
## Divergent Allometric Adaptations in Glucose Homeostasis: From Atapuerca to the Americas

**Status:** Work in progress — Acto 1 complete, Acto 2 pilot complete  
**Author:** egarmo  
**Last updated:** April 2026

---

## La hipótesis central

La diabetes tipo 2 no es una enfermedad uniforme. Es el resultado de **dos soluciones evolutivas distintas** al mismo problema biológico: suministrar glucosa a un cerebro metabólicamente muy costoso bajo condiciones ambientales opuestas.

- **Western lineage** (Sima de los Huesos → Vindija → europeos modernos): optimización del umbral renal de glucosa. El riñón aprendió a retener azúcar eficientemente en un ambiente de escasez calórica y frío moderado. Gen clave: *SLC5A2* (SGLT2).

- **Eastern lineage** (Denisova → Ust'-Ishim → amerindios): resistencia periférica masiva a la insulina como estrategia anticongelante ártico. El músculo se cierra al azúcar para que el cerebro y los tejidos vitales mantengan perfusión caliente en temperaturas de -50°C. Gen clave: *SLC16A11*.

**La implicación clínica es directa:** tratamos una Eastern Diabetes con fármacos diseñados para el modelo Western. Esto explica la crisis metabólica desproporcionada en poblaciones nativas americanas expuestas a dieta occidental.

---

## Estructura del estudio

```
Acto 1 — ¿Es Homo sapiens un outlier alométrico único?
Acto 2 — ¿Qué genes están bajo selección positiva en nuestra rama?
Acto 3 — ¿Cómo se polariza esa señal entre linajes arcaicos y modernos?
         (Sima vs Vindija vs Denisova vs Ust'-Ishim → gnomAD v4)
```

---

## ACTO 1 — Análisis alométrico ✅ COMPLETADO

### Pregunta
¿Es *Homo sapiens* el único mamífero outlier simultáneo en **encefalización extrema** (EQ residual) y **adaptación al frío** (temperatura de hábitat)?

### Método
- 52 mamíferos, 4 variables: EQ residual (Jerison), BMR_z, longevidad_z, temperatura_hábitat
- Fuentes: Stephan et al. 1981, Isler & van Schaik 2006, Burger et al. 2019, PanTHERIA
- Distancia de Mahalanobis + FDR en dos modelos:
  - **Modelo 1** (EQ puro, N=28): incluye cetáceos
  - **Modelo 2** (terrestres, N=22): *Homo sapiens* asignado a -5°C (nicho glacial LGM)

### Resultados clave
| Métrica | Valor |
|---------|-------|
| Ranking *H. sapiens* M1 | **2/28** |
| Distancia Mahalanobis | D = 28.81 |
| p-valor (FDR corregido) | **p = 3.4 × 10⁻⁵** |
| Especies en cuadrante EQ>0 + T<5°C (M2) | *Vulpes lagopus*, *Canis lupus*, *Ursus americanus*, *Marmota marmota* |

**Conclusión Acto 1:** *Homo sapiens* es un outlier estadísticamente incontestable en encefalización. El cuadrante de alto EQ + temperatura fría está ocupado exclusivamente por mamíferos boreales — y nuestra especie. Esto justifica la búsqueda de señales de selección positiva en genes de metabolismo de glucosa y termogénesis.

### Figura principal
`act1/act1_figure1_combined_v7.pdf` — tres paneles: PCA, Mahalanobis M1, Mahalanobis M2

---

## ACTO 2 — Selección positiva y tasas evolutivas ⚠️ PILOTO COMPLETADO

### Pregunta
¿Qué genes candidatos muestran evidencia de selección positiva (ω > 1) en la rama humana comparada con 13 especies de mamíferos?

### Método A — PAML branch-site (piloto, N=39 genes)
- 14 taxa, árbol TimeTree, *homo_sapiens* como foreground (#1)
- Modelo alternativo (M2a) vs nulo (ω=1 fijado), LRT con χ² df=1
- **Limitación:** genes con CDS > 3000 bp causan no-convergencia. Solo 39 genes completaron con calidad suficiente.
- **Resultado:** 0 genes FDR < 0.05 (N insuficiente para potencia estadística)
- Candidatos destacados: CYP11B2 (LRT=2.28), IRS2 (LRT=1.37)

### Método B — yn00 pairwise dN/dS (N=79 genes, 13 especies) ✅
- yn00 (PAML 4.9j), alineamiento MAFFT, 890 pares válidos de 1027
- **Sin árbol filogenético** — comparación directa *homo_sapiens* vs cada especie
- Ventaja: robusto, sin problemas de convergencia, completa en ~13 minutos en local

### Resultados yn00 destacados

**Genes bajo selección positiva (ω_mean > 1.0):**

| Gen | ω medio | Eje biológico | Nota |
|-----|---------|---------------|------|
| PKM | 2.44 | Glucólisis | Piruvato kinasa M — isoforma muscular |
| SLC2A3 | 2.41 | Western/glucosa | GLUT3 — transporte cerebral |
| LDHA | 2.23 | Glucólisis | Lactato deshidrogenasa A |
| PFKM | 1.77 | Glucólisis | Fosfofructokinasa muscular |
| UGP2 | 1.81 | Glucosa/glucógeno | UDP-glucosa pirofosforilasa |
| ADIPOQ | 1.45 | Señalización | Adiponectina |
| PGM1 | 1.32 | Glucógeno | Fosfoglucomutasa |
| PPARGC1A | 1.24 | Frío/termogénesis | Coactivador maestro termogénesis |
| TRPA1 | 1.05 | Frío | Receptor canal de frío |
| ACACA | 1.29 | Lípidos | Acetil-CoA carboxilasa |

**Señales del eje frío:**
- TRPA1 vs *Ursus americanus*: ω = **3.63** — receptor de frío más divergente en oso
- PPARGC1A vs *Loxodonta africana*: ω = **5.09** — regulador maestro de termogénesis
- UCP1 ω_mean = 0.86 — casi en umbral positivo

**Señales del eje Western (glucosa/riñón):**
- SLC5A2 ω_mean = **0.39** — conservado bajo purificación (esencial, no negociable)
- LDHA vs *Tursiops truncatus*: ω = **4.18** — LDHA del delfín muy divergente (metabolismo anaeróbico de buceo)

---

## ACTO 3 — Polarización Este-Oeste (pendiente)

### Pregunta
¿Las firmas de selección del Acto 2 se polarizan entre los linajes arcaicos de forma consistente con la hipótesis East-West?

### Plan
1. Obtener VCFs de:
   - Sima de los Huesos (hg38, low-cov, ENA/MPI-EVA)
   - Vindija 33.19 (Neandertal europeo)
   - Altai Denisova
   - Ust'-Ishim (Siberia, ~45 kyr)
2. Polarizar variantes en los genes del top-10 Acto 2 (especialmente PKM, LDHA, PFKM, PPARGC1A)
3. Cruzar con gnomAD v4 (subpoblaciones AMR, EUR, EAS, AFR)
4. Test D-statistic (ABBA-BABA) para confirmar estructura poblacional

**Predicción:** Los alelos de alta ω en PKM y PFKM estarán presentes en la Sima/Vindija (Western) y ausentes o minoritarios en Denisova/Ust'-Ishim (Eastern), o viceversa para los genes del eje frío extremo ártico.

---

## Stack técnico

```
Alometría:      R (ape, MASS, ggplot2, ggrepel, patchwork)
Alineamiento:   MAFFT 7
dN/dS:          yn00 (PAML 4.9j, apt install paml)
PAML branch:    codeml (PAML 4.9j)
Infraestructura: AWS EC2 r6i.2xlarge (Acto 2 PAML), local Dell (yn00)
Orquestación:   Python 3.12, bash, nohup
Datos:          Ensembl REST API, PanTHERIA, UCSC
Versión:        git (este repositorio)
```

---

## Archivos clave

```
scripts/
├── act1_allometric_pca_v7.R         # Acto 1 completo
├── yn00_eastwest_final.py           # Acto 2 dN/dS pipeline (el que funciona)
├── fetch_dnds_eastwest.py           # Intento Ensembl API (dn_ds=null, no usar)
└── run_yn00_eastwest.py             # Versiones previas (deprecadas)

act1/
├── act1_figure1_combined_v7.pdf     # FIGURA PUBLICABLE
├── act1_model1_mahalanobis_v7.csv
├── act1_model2_mahalanobis_v7.csv
└── act1_results_v7.txt

act2/
├── paml_lrt_raw.csv                 # PAML branch-site (39 genes, piloto)
├── yn00_results/dnds_final.csv      # yn00 pairwise (79 genes, 890 pares) ✅
├── act2_final_genes.csv             # Análisis estadístico PAML
└── act2_volcano_v1.pdf              # Volcano plot PAML

data/
├── combined_mammal_pes.csv          # Dataset alométrico
└── species_tree_14taxa.nwk          # Árbol filogenético
```

---

## Reflexión sobre el Acto 2

El análisis yn00 no es equivalente al branch-site de PAML — no detecta selección específica de rama sino divergencia pairwise acumulada. Esto significa que un ω elevado en la comparación *homo_sapiens* vs *Ursus americanus* para TRPA1 puede reflejar divergencia en cualquiera de las dos ramas, no necesariamente aceleración humana.

**Para el paper, el Acto 2 necesita:**
1. PAML branch-site completo sobre los top-15 genes de yn00 (factible con timeout generoso)
2. O bien análisis de sitios específicos (BEB posterior probability) en los genes candidatos
3. Integración con datos de aceleración phyloP de Zoonomia como validación externa

**El Acto 2 actual es exploratorio y sirve para priorizar candidatos para el Acto 3.**

---

## Títulos candidatos para el paper

1. *"The East-West Diabetes Story: Divergent Allometric Adaptations in Glucose Homeostasis from the Middle Pleistocene to Modern Clinical Practice"*

2. *"Positive Selection in Human Glucose and Thermogenic Genes: Allometric Evidence for Two Distinct Metabolic Architectures"*

3. *"HotSaltySoup: Thermal Homeostasis as the Evolutionary Driver of Western Hypertension and Eastern Insulin Resistance"* (para el paper de hipertensión, spin-off)

---

## Revistas target

| Paper | Target | Justificación |
|-------|--------|---------------|
| Flagship (metodología completa) | *Genome Biology* / *Nature Communications* | Elegancia del pipeline, novedad Atapuerca |
| East-West Diabetes | *Diabetes* / *Cell Metabolism* | Impacto clínico directo |
| HotSaltySoup (HTA) | *Hypertension* / *JASN* | Farmacogenómica de poblaciones |

---

*"No estamos describiendo fósiles. Estamos diagnosticando a sus descendientes."*
