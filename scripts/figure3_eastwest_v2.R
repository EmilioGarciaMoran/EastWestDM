# ============================================================
# EastWest Diabetes Story — Figures 3A, 3D, 3E, 3F, 4A
# Nature Medicine unified style
# April 2026
# ============================================================

library(ggplot2)
library(tidyverse)
library(pheatmap)
library(gridExtra)

# ============================================================
# UNIFIED THEME & PALETTE
# ============================================================

# Colores unificados
COL_EASTERN  <- "#C0392B"   # rojo oscuro
COL_WESTERN  <- "#2471A3"   # azul oscuro
COL_AMR      <- "#E67E22"   # naranja
COL_EAS      <- "#8E44AD"   # morado
COL_NFE      <- "#27AE60"   # verde
COL_SLC2A3   <- "#1ABC9C"   # teal invariante
COL_OTHER    <- "#85929E"   # gris neutro
COL_ANNOT    <- "#566573"   # gris anotaciones

# Tema unificado
theme_eastwest <- function() {
  theme_minimal(base_size=13) +
  theme(
    plot.title      = element_text(face="bold", size=14, color="grey10"),
    plot.subtitle   = element_text(color="grey40", size=11),
    axis.text       = element_text(color="grey20", size=11),
    axis.title      = element_text(face="bold", size=12),
    axis.text.x     = element_text(angle=45, hjust=1),
    panel.grid.major = element_line(color="grey92", linewidth=0.5),
    panel.grid.minor = element_blank(),
    legend.position  = "top",
    legend.title     = element_text(face="bold", size=11),
    legend.text      = element_text(size=10),
    plot.background  = element_rect(fill="white", color=NA),
    panel.background = element_rect(fill="white", color=NA),
    plot.margin      = margin(15,15,15,15)
  )
}

# Gene order biologico
gene_order <- c("PFKM","PPARGC1A","ADIPOQ","TRPA1",
                "LDHA","PKM","PGM1","UGP2","ACACA","SLC2A3")

cat("=== EastWest Figures — Nature Medicine style ===\n")

# ============================================================
# FIGURA 3A: Eastern vs Western barplot
# ============================================================
cat("Generating Fig 3A...\n")

east_west <- data.frame(
  Gene    = c("PKM","LDHA","PFKM","PPARGC1A","TRPA1",
              "SLC2A3","ADIPOQ","PGM1","UGP2","ACACA"),
  Eastern = c(13,14,42,26,21,0,23,12,6,11),
  Western = c(2,4,0,8,2,4,0,1,0,20)
) %>%
  pivot_longer(cols=c(Eastern,Western),
               names_to="Lineage", values_to="SNPs")

east_west$Gene <- factor(east_west$Gene, levels=gene_order)

p3a <- ggplot(east_west, aes(x=Gene, y=SNPs, fill=Lineage)) +
  geom_bar(stat="identity", position="dodge", width=0.65) +
  geom_segment(aes(x=9.75, xend=9.95, y=6, yend=1.5),
               arrow=arrow(length=unit(0.2,"cm"), type="closed"),
               color=COL_SLC2A3, linewidth=0.8,
               inherit.aes=FALSE) +
  annotate("text", x=9.5, y=8,
           label="SLC2A3\n0 Eastern\nbrain invariant",
           size=3.2, color=COL_SLC2A3, fontface="bold", hjust=0.5) +
  scale_fill_manual(values=c("Eastern"=COL_EASTERN,
                              "Western"=COL_WESTERN)) +
  labs(title="Fig 3A: Eastern vs Western Specific Variants",
       subtitle="D17+Ust'-Ishim (Eastern) or D17+Vindija (Western), absent in the other lineage",
       x="Gene", y="SNP count (damage-filtered)",
       fill="Lineage") +
  theme_eastwest()

ggsave("act3/figure3A_eastwest_barplot.pdf", p3a,
       width=10, height=6, bg="white")
cat("  Fig 3A saved\n")

# ============================================================
# FIGURA 3D: Heatmap SNPs por gen x especimen
# ============================================================
cat("Generating Fig 3D...\n")

snp_data <- data.frame(
  Gene = rep(c("PKM","LDHA","PFKM","PPARGC1A","TRPA1",
               "SLC2A3","ADIPOQ","PGM1","UGP2","ACACA"), 4),
  Specimen = rep(c("D17\nEastern Neandertal\n~110 ka",
                   "Ust'-Ishim\nSiberian Sapiens\n~65 ka",
                   "Vindija\nWestern Neandertal\n~49 ka",
                   "Otzi\nNeolithic Farmer\n~5.3 ka"), each=10),
  SNPs = c(
    26,40,75,124,55,25,39,17,17,123,
    17,33,90,56,52,5,36,33,13,25,
    3,7,8,26,8,5,3,3,2,26,
    9,12,10,27,14,3,14,1,6,8
  )
)

heatmap_matrix <- snp_data %>%
  select(Gene, Specimen, SNPs) %>%
  pivot_wider(names_from=Specimen, values_from=SNPs) %>%
  column_to_rownames("Gene")
heatmap_matrix <- heatmap_matrix[gene_order,]

gene_function <- data.frame(
  Function = c("Glycolysis","Thermogenesis","Adipose storage",
               "Cold sensing","Glycolysis","Glycolysis",
               "Glycogen","Glycogen","Lipogenesis","Brain glucose"),
  row.names = gene_order
)

func_colors <- list(
  Function = c(
    "Glycolysis"      = COL_EASTERN,
    "Thermogenesis"   = "#E67E22",
    "Adipose storage" = "#8E44AD",
    "Cold sensing"    = "#2471A3",
    "Glycogen"        = "#27AE60",
    "Lipogenesis"     = "#F39C12",
    "Brain glucose"   = COL_SLC2A3
  )
)

# Separar columnas East vs West visualmente
col_order <- c("D17\nEastern Neandertal\n~110 ka",
               "Ust'-Ishim\nSiberian Sapiens\n~65 ka",
               "Vindija\nWestern Neandertal\n~49 ka",
               "Otzi\nNeolithic Farmer\n~5.3 ka")
heatmap_matrix <- heatmap_matrix[, col_order]

pdf("act3/figure3D_heatmap.pdf", width=11, height=8)
pheatmap(
  heatmap_matrix,
  color = colorRampPalette(c("white","#FDEBD0","#E59866","#922B21"))(60),
  cluster_rows  = FALSE,
  cluster_cols  = FALSE,
  annotation_row = gene_function,
  annotation_colors = func_colors,
  fontsize       = 12,
  fontsize_row   = 12,
  fontsize_col   = 9,
  angle_col      = 315,
  main           = "SNP Counts by Gene × Specimen  (damage-filtered, QUAL>30)",
  border_color   = "grey85",
  display_numbers = TRUE,
  number_format  = "%d",
  number_color   = "grey20",
  gaps_col       = 2    # separacion visual East | West
)
dev.off()
cat("  Fig 3D saved\n")

# ============================================================
# FIGURA 3E: gnomAD Eastern polarization
# ============================================================
cat("Generating Fig 3E...\n")

gnomad_east <- read.csv("act3/gnomad_eastern.csv")

gnomad_east_long <- gnomad_east %>%
  filter(af_amr > 0.001 | af_eas > 0.001 | af_nfe > 0.001) %>%
  pivot_longer(cols=c(af_amr, af_eas, af_nfe),
               names_to="Population", values_to="AF") %>%
  mutate(Population = recode(Population,
    "af_amr" = "AMR", "af_eas" = "EAS", "af_nfe" = "NFE"))

# Ordenar por AF Eastern (AMR+EAS media) descendente
var_order_east <- gnomad_east %>%
  mutate(east_mean = (af_amr + af_eas)/2) %>%
  arrange(desc(east_mean)) %>%
  pull(variant_id)

gnomad_east_long$variant_id <- factor(gnomad_east_long$variant_id,
                                       levels=var_order_east)

p3e <- ggplot(gnomad_east_long,
              aes(x=variant_id, y=AF, fill=Population)) +
  geom_bar(stat="identity", position="dodge", width=0.65) +
  scale_fill_manual(values=c("AMR"=COL_AMR,
                              "EAS"=COL_EAS,
                              "NFE"=COL_NFE)) +
  scale_y_continuous(labels=scales::percent_format(accuracy=1),
                     limits=c(0,1.05)) +
  labs(title="Fig 3E: Eastern Variant Frequencies in gnomAD v4",
       subtitle="86% (12/14) more frequent in AMR/EAS than NFE  |  binomial p = 0.006",
       x="Variant", y="Allele Frequency", fill="Population") +
  theme_eastwest()

ggsave("act3/figure3E_gnomad_eastern.pdf", p3e,
       width=12, height=6, bg="white")
cat("  Fig 3E saved\n")

# ============================================================
# FIGURA 3F: gnomAD Western polarization
# ============================================================
cat("Generating Fig 3F...\n")

gnomad_west <- read.csv("act3/gnomad_western.csv")

gnomad_west_long <- gnomad_west %>%
  pivot_longer(cols=c(af_amr, af_eas, af_nfe),
               names_to="Population", values_to="AF") %>%
  mutate(Population = recode(Population,
    "af_amr" = "AMR", "af_eas" = "EAS", "af_nfe" = "NFE"))

var_order_west <- gnomad_west %>%
  arrange(desc(af_nfe)) %>%
  pull(variant_id)

gnomad_west_long$variant_id <- factor(gnomad_west_long$variant_id,
                                       levels=var_order_west)

p3f <- ggplot(gnomad_west_long,
              aes(x=variant_id, y=AF, fill=Population)) +
  geom_bar(stat="identity", position="dodge", width=0.65) +
  scale_fill_manual(values=c("AMR"=COL_AMR,
                              "EAS"=COL_EAS,
                              "NFE"=COL_NFE)) +
  scale_y_continuous(labels=scales::percent_format(accuracy=1)) +
  labs(title="Fig 3F: Western Variant Frequencies in gnomAD v4",
       subtitle="86% (6/7) more frequent in NFE than AMR/EAS",
       x="Variant", y="Allele Frequency", fill="Population") +
  theme_eastwest()

ggsave("act3/figure3F_gnomad_western.pdf", p3f,
       width=10, height=6, bg="white")
cat("  Fig 3F saved\n")

# ============================================================
# FIGURA 4A: SLC2A3 brain glucose invariant
# ============================================================
cat("Generating Fig 4A...\n")

slc2a3_comp <- data.frame(
  Gene  = c("PPARGC1A","PFKM","ACACA","TRPA1","ADIPOQ",
            "LDHA","PKM","PGM1","UGP2","SLC2A3"),
  Total = c(233,183,182,129,92,92,55,54,38,38),
  Brain = c(FALSE,FALSE,FALSE,FALSE,FALSE,
            FALSE,FALSE,FALSE,FALSE,TRUE)
)

slc2a3_comp$Gene <- factor(slc2a3_comp$Gene,
  levels=slc2a3_comp$Gene[order(slc2a3_comp$Total, decreasing=TRUE)])

p4a <- ggplot(slc2a3_comp,
              aes(x=Gene, y=Total,
                  fill=Brain, color=Brain)) +
  geom_bar(stat="identity", width=0.7) +
  geom_segment(aes(x=9.6, xend=9.9, y=65, yend=42),
               arrow=arrow(length=unit(0.25,"cm"), type="closed"),
               color=COL_SLC2A3, linewidth=1,
               inherit.aes=FALSE) +
  annotate("text", x=8.9, y=78,
           label="Brain wins\n430,000 years\nno negotiation",
           size=3.5, color=COL_SLC2A3, fontface="bold", hjust=0.5) +
  scale_fill_manual(values  = c("FALSE"=COL_OTHER, "TRUE"=COL_SLC2A3),
                    labels  = c("Other genes","SLC2A3"),
                    name    = "") +
  scale_color_manual(values = c("FALSE"=COL_OTHER, "TRUE"=COL_SLC2A3),
                     guide  = "none") +
  labs(title="Fig 4A: SLC2A3 — The Brain Glucose Invariant",
       subtitle="Total SNPs across D17 + Ust'-Ishim + Vindija + Otzi  (damage-filtered)",
       x="Gene", y="Total SNP count") +
  theme_eastwest()

ggsave("act3/figure4A_slc2a3_invariant.pdf", p4a,
       width=10, height=6, bg="white")
cat("  Fig 4A saved\n")

# ============================================================
# SUMMARY
# ============================================================
cat("\n=== All figures saved (Nature Medicine unified style) ===\n")
cat("act3/figure3A_eastwest_barplot.pdf\n")
cat("act3/figure3D_heatmap.pdf\n")
cat("act3/figure3E_gnomad_eastern.pdf\n")
cat("act3/figure3F_gnomad_western.pdf\n")
cat("act3/figure4A_slc2a3_invariant.pdf\n")
