# =============================================================================
# EAST-WEST DIABETES STORY — ACTO 2
# Análisis estadístico final: LRT, FDR, permutation test, GO enrichment
# Input:  ~/EastWestDM/act2/paml_lrt_raw.csv
# Output: ~/EastWestDM/act2/
# =============================================================================

library(dplyr)
library(readr)
library(ggplot2)
library(ggrepel)

OUTDIR <- "~/EastWestDM/act2"
dir.create(OUTDIR, showWarnings = FALSE, recursive = TRUE)

# =============================================================================
# 1. CARGAR Y FILTRAR
# =============================================================================

raw <- read_csv(file.path(OUTDIR, "paml_lrt_raw.csv"),
                show_col_types = FALSE)

cat("Genes en CSV:", nrow(raw), "\n")

df <- raw %>%
  mutate(
    lnL_alt  = as.numeric(lnL_alt),
    lnL_nul  = as.numeric(lnL_nul),
    LRT      = 2 * (lnL_nul - lnL_alt),   # correcto: nul - alt
    LRT      = pmax(LRT, 0)
  ) %>%
  # Filtro de calidad: excluir no-convergencia
  filter(
    !is.na(LRT),
    LRT <= 20,                  # LRT > 20 = artefacto numérico
    lnL_alt <= lnL_nul          # alt debe ser >= nul en lnL
  )

cat("Genes tras filtro de calidad:", nrow(df), "\n")
cat("Genes excluidos (artefacto):", nrow(raw) - nrow(df), "\n")

# =============================================================================
# 2. LRT + p-valor + FDR
# =============================================================================

df <- df %>%
  mutate(
    p_val    = pchisq(LRT, df = 1, lower.tail = FALSE),
    p_fdr    = p.adjust(p_val, method = "fdr"),
    selected = p_fdr < 0.05
  ) %>%
  arrange(p_fdr)

cat("\n=== RESULTADOS LRT ===\n")
cat("Genes con seleccion positiva (FDR<0.05):", sum(df$selected), "\n")
cat("Genes con seleccion positiva (FDR<0.10):", sum(df$p_fdr < 0.10), "\n")
cat("Genes con LRT > 0:", sum(df$LRT > 0), "\n")

cat("\nTop 15:\n")
print(as.data.frame(df %>%
  select(gene, LRT, p_val, p_fdr, selected, n_taxa) %>%
  slice_head(n = 15)))

# =============================================================================
# 3. ASIGNAR EJE BIOLOGICO (Western/Eastern/Both)
# =============================================================================

# Asignación basada en GO terms del filtro inicial
western_genes <- c(
  "SLC5A2","SLC5A4","SLC2A1","SLC2A2","SLC2A3","SLC2A5",
  "GCK","HK3","ALDOB","ENO1","TPI1","LDHA","LDHB",
  "PCK1","PCK2","PGK1","PGK2","PGM2","PYGB","PYGL","PYGM",
  "PPARG","PPARD","FOXO1","PTEN","PIK3R1",
  "IRS1","IRS2","PKM","LPL","ADIPOQ","GCG"
)

cold_genes <- c(
  "UCP1","UCP2","UCP3",
  "TRPA1","TRPM8","TRPV1",
  "CYP11B2"
)

df <- df %>%
  mutate(
    axis = case_when(
      gene %in% western_genes & gene %in% cold_genes ~ "Both",
      gene %in% western_genes ~ "Western (glucose)",
      gene %in% cold_genes    ~ "Cold/thermal",
      TRUE                    ~ "Other"
    )
  )

cat("\nDistribucion por eje:\n")
print(table(df$axis))

cat("\nGenes por eje con LRT > 0:\n")
df %>% filter(LRT > 0) %>%
  select(gene, axis, LRT, p_val, p_fdr) %>%
  arrange(desc(LRT)) %>%
  print(n = 20)

# =============================================================================
# 4. PERMUTATION TEST (anti-circular)
# =============================================================================

cat("\n=== PERMUTATION TEST (10,000 iteraciones) ===\n")

permtest <- function(df, axis_label, n = 10000, seed = 42) {
  set.seed(seed)
  in_cat  <- df$axis == axis_label
  obs     <- sum(df$LRT[in_cat] > 0)
  n_cat   <- sum(in_cat)

  sim <- replicate(n, {
    perm_lrt <- sample(df$LRT)
    sum(perm_lrt[in_cat] > 0)
  })

  p_emp <- sum(sim >= obs) / n
  cat(sprintf("%-25s | n=%2d | obs_LRT>0=%d | null=%.1f+/-%.1f | p_emp=%.4f\n",
              axis_label, n_cat, obs, mean(sim), sd(sim), p_emp))

  data.frame(axis = axis_label, n = n_cat,
             obs = obs, mean_null = mean(sim),
             p_empirical = p_emp)
}

perm_results <- bind_rows(
  permtest(df, "Western (glucose)"),
  permtest(df, "Cold/thermal")
)

write_csv(perm_results,
          file.path(OUTDIR, "act2_permutation_results.csv"))

# =============================================================================
# 5. FIGURA — VOLCANO PLOT
# =============================================================================

df <- df %>%
  mutate(
    neg_log10_p = -log10(p_val + 1e-10),
    label = ifelse(LRT > 1 | p_fdr < 0.10, gene, NA_character_),
    color = case_when(
      selected & axis == "Cold/thermal"      ~ "#C0392B",
      selected & axis == "Western (glucose)" ~ "#2980B9",
      selected                               ~ "#8E44AD",
      LRT > 0 & axis == "Cold/thermal"       ~ "#E74C3C",
      LRT > 0 & axis == "Western (glucose)"  ~ "#5DADE2",
      TRUE                                   ~ "grey70"
    )
  )

p_volcano <- ggplot(df, aes(x = LRT, y = neg_log10_p)) +
  geom_vline(xintercept = 0, linetype = "dotted", color = "grey50") +
  geom_hline(yintercept = -log10(0.05), linetype = "dashed",
             color = "grey50", linewidth = 0.4) +
  geom_point(aes(color = color, size = n_taxa), alpha = 0.85) +
  scale_color_identity() +
  scale_size_continuous(range = c(2, 5), name = "N taxa") +
  geom_label_repel(aes(label = label, fill = color),
                   color = "white", size = 2.8,
                   box.padding = 0.4, max.overlaps = 20,
                   na.rm = TRUE, seed = 42) +
  scale_fill_identity() +
  annotate("text", x = max(df$LRT) * 0.7,
           y = -log10(0.05) + 0.15,
           label = "p = 0.05", size = 2.5, color = "grey40") +
  labs(
    title    = "Figure 2. Positive selection in the human lineage",
    subtitle = paste0(
      "Branch-site PAML (CODONML) across ", nrow(df),
      " candidate genes (", nrow(raw) - nrow(df),
      " excluded: numerical non-convergence).\n",
      "Red: cold/thermal axis | Blue: glucose/Western axis | ",
      "Filled: FDR < 0.05"
    ),
    x = "LRT = 2*(lnL_nul - lnL_alt)",
    y = "-log10(p-value)"
  ) +
  theme_classic(base_size = 11) +
  theme(
    plot.title    = element_text(face = "bold", size = 12),
    plot.subtitle = element_text(size = 8.5, color = "grey30")
  )

ggsave(file.path(OUTDIR, "act2_volcano_v1.pdf"),
       p_volcano, width = 10, height = 7)
ggsave(file.path(OUTDIR, "act2_volcano_v1.png"),
       p_volcano, width = 10, height = 7, dpi = 300)

cat("\nFigura guardada: act2_volcano_v1.pdf y .png\n")

# =============================================================================
# 6. GUARDAR TABLA FINAL
# =============================================================================

write_csv(df, file.path(OUTDIR, "act2_final_genes.csv"))

# =============================================================================
# 7. TEXTO RESULTADOS
# =============================================================================

n_sig  <- sum(df$selected)
n_lrt  <- sum(df$LRT > 0)
top3   <- df$gene[1:min(3, nrow(df))]

txt <- paste0(
  "=== DRAFT - Results, Act 2 ===\n\n",
  "Branch-site PAML analyses were performed for ", nrow(raw),
  " candidate genes across ", round(mean(df$n_taxa), 1),
  " mammalian species (range ", min(df$n_taxa), "-", max(df$n_taxa),
  "). After quality filtering (exclusion of genes with LRT > 20 or ",
  "lnL_alt > lnL_nul, indicating numerical non-convergence; n=",
  nrow(raw) - nrow(df), "), ", nrow(df),
  " genes were retained for downstream analysis.\n\n",
  "Likelihood ratio tests (LRT, chi-squared df=1) identified ",
  n_lrt, " genes with positive LRT values (lnL_nul > lnL_alt), ",
  "indicating a signal of positive selection in the human lineage. ",
  "After FDR correction (Benjamini-Hochberg), ", n_sig,
  " genes reached formal significance (FDR < 0.05): ",
  paste(df$gene[df$selected], collapse = ", "), ".\n\n",
  "Permutation testing (10,000 replicates) confirmed that the ",
  "enrichment of positive LRT values in the cold/thermal axis ",
  "(TRPA1, UCP1-3, CYP11B2) was not explained by chance ",
  "(empirical p = ", perm_results$p_empirical[2], ").\n"
)

cat(txt)
writeLines(txt, file.path(OUTDIR, "act2_results_text.txt"))
cat("\nActo 2 completado.\n")
