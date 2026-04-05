# Figure 3: East-West Paleogenomic Polarization
library(ggplot2)
library(tidyverse)
library(pheatmap)
library(gridExtra)

# SNP counts por gen y espécimen
snp_data <- data.frame(
  Gene = rep(c("PKM","LDHA","PFKM","PPARGC1A","TRPA1",
               "SLC2A3","ADIPOQ","PGM1","UGP2","ACACA"), 4),
  Specimen = rep(c("D17\nEastern Neandertal\n~110ka",
                   "Ust-Ishim\nSiberian Sapiens\n~65ka",
                   "Vindija\nWestern Neandertal\n~49ka",
                   "Otzi\nNeolithic Farmer\n~5.3ka"), each=10),
  SNPs = c(
    26,40,75,124,55,25,39,17,17,123,
    17,33,90,56,52,5,36,33,13,25,
    3,7,8,26,8,5,3,3,2,26,
    9,12,10,27,14,3,14,1,6,8
  )
)

gene_order <- c("PFKM","PPARGC1A","ADIPOQ","TRPA1",
                "LDHA","PKM","PGM1","UGP2","ACACA","SLC2A3")

# === FIGURA 3D: HEATMAP ===
heatmap_matrix <- snp_data %>%
  select(Gene, Specimen, SNPs) %>%
  pivot_wider(names_from=Specimen, values_from=SNPs) %>%
  column_to_rownames("Gene")
heatmap_matrix <- heatmap_matrix[gene_order,]

gene_function <- data.frame(
  Function=c("Glycolysis","Thermogenesis","Adipose storage",
             "Cold sensing","Glycolysis","Glycolysis",
             "Glycogen","Glycogen","Lipogenesis","Brain glucose"),
  row.names=gene_order
)

pdf("act3/figure3D_heatmap.pdf", width=10, height=8)
pheatmap(heatmap_matrix,
  color=colorRampPalette(c("white","#FFF3CD","#FF8C00","#8B0000"))(50),
  cluster_rows=FALSE, cluster_cols=FALSE,
  annotation_row=gene_function,
  fontsize=12, fontsize_row=13, fontsize_col=10,
  main="SNP Counts by Gene x Specimen\n(damage-filtered, QUAL>30)",
  border_color="grey80",
  display_numbers=TRUE, number_format="%d", number_color="black")
dev.off()
cat("Fig 3D saved\n")

# === FIGURA 3A: EAST vs WEST BARPLOT ===
east_west <- data.frame(
  Gene=c("PKM","LDHA","PFKM","PPARGC1A","TRPA1",
         "SLC2A3","ADIPOQ","PGM1","UGP2","ACACA"),
  Eastern=c(13,14,42,26,21,0,23,12,6,11),
  Western=c(2,4,0,8,2,4,0,1,0,20)
) %>%
  pivot_longer(cols=c(Eastern,Western),
               names_to="Lineage", values_to="SNPs")

east_west$Gene <- factor(east_west$Gene, levels=gene_order)

p3a <- ggplot(east_west, aes(x=Gene, y=SNPs, fill=Lineage)) +
  geom_bar(stat="identity", position="dodge", width=0.7) +
  scale_fill_manual(values=c("Eastern"="#E74C3C","Western"="#3498DB")) +
  labs(title="Fig 3A: Eastern vs Western Specific Variants",
       subtitle="D17+Ust (Eastern) or D17+Vindija (Western), absent in the other",
       x="Gene", y="SNP count (damage-filtered)", fill="Lineage") +
  theme_minimal(base_size=13) +
  theme(axis.text.x=element_text(angle=45, hjust=1),
        plot.title=element_text(face="bold"),
        legend.position="top") +
  annotate("text", x=10, y=2,
           label="SLC2A3\n0 Eastern\nbrain wins",
           size=3.5, color="#1ABC9C", fontface="bold")

ggsave("act3/figure3A_eastwest_barplot.pdf", p3a, width=10, height=6)
cat("Fig 3A saved\n")

# === FIGURA 3E: gnomAD EASTERN ===
gnomad_east <- read.csv("act3/gnomad_eastern.csv")
gnomad_east <- gnomad_east %>%
  filter(af_amr > 0 | af_eas > 0 | af_nfe > 0) %>%
  mutate(Eastern = af_amr > af_nfe | af_eas > af_nfe) %>%
  pivot_longer(cols=c(af_amr, af_eas, af_nfe, af_afr),
               names_to="Population", values_to="AF") %>%
  mutate(Population=recode(Population,
    "af_amr"="AMR","af_eas"="EAS",
    "af_nfe"="NFE","af_afr"="AFR"))

p3e <- ggplot(gnomad_east %>% filter(Population %in% c("AMR","EAS","NFE")),
              aes(x=reorder(variant_id, -AF), y=AF, fill=Population)) +
  geom_bar(stat="identity", position="dodge") +
  scale_fill_manual(values=c("AMR"="#E74C3C","EAS"="#E67E22","NFE"="#3498DB")) +
  labs(title="Fig 3E: Eastern Variant Frequencies in gnomAD v4",
       subtitle="86% (12/14) more frequent in AMR/EAS than NFE (binomial p=0.006)",
       x="Variant", y="Allele Frequency", fill="Population") +
  theme_minimal(base_size=11) +
  theme(axis.text.x=element_text(angle=45, hjust=1, size=7),
        plot.title=element_text(face="bold"))

ggsave("act3/figure3E_gnomad_eastern.pdf", p3e, width=12, height=6)
cat("Fig 3E saved\n")

# === FIGURA 3F: gnomAD WESTERN ===
gnomad_west <- read.csv("act3/gnomad_western.csv")
gnomad_west_long <- gnomad_west %>%
  pivot_longer(cols=c(af_amr, af_eas, af_nfe, af_afr),
               names_to="Population", values_to="AF") %>%
  mutate(Population=recode(Population,
    "af_amr"="AMR","af_eas"="EAS",
    "af_nfe"="NFE","af_afr"="AFR"))

p3f <- ggplot(gnomad_west_long %>% filter(Population %in% c("AMR","EAS","NFE")),
              aes(x=reorder(variant_id, -AF), y=AF, fill=Population)) +
  geom_bar(stat="identity", position="dodge") +
  scale_fill_manual(values=c("AMR"="#E74C3C","EAS"="#E67E22","NFE"="#3498DB")) +
  labs(title="Fig 3F: Western Variant Frequencies in gnomAD v4",
       subtitle="86% (6/7) more frequent in NFE than AMR/EAS",
       x="Variant", y="Allele Frequency", fill="Population") +
  theme_minimal(base_size=11) +
  theme(axis.text.x=element_text(angle=45, hjust=1, size=7),
        plot.title=element_text(face="bold"))

ggsave("act3/figure3F_gnomad_western.pdf", p3f, width=10, height=6)
cat("Fig 3F saved\n")

# === FIGURA 4A: SLC2A3 INVARIANT ===
slc2a3_comp <- data.frame(
  Gene=c("PFKM","PPARGC1A","ADIPOQ","TRPA1","LDHA",
         "PKM","PGM1","UGP2","ACACA","SLC2A3"),
  Total=c(183,233,92,129,92,55,54,38,182,38),
  Brain=c(FALSE,FALSE,FALSE,FALSE,FALSE,
          FALSE,FALSE,FALSE,FALSE,TRUE)
)

p4a <- ggplot(slc2a3_comp,
              aes(x=reorder(Gene,-Total), y=Total, fill=Brain)) +
  geom_bar(stat="identity") +
  scale_fill_manual(values=c("FALSE"="#95A5A6","TRUE"="#1ABC9C"),
                    labels=c("Other genes","SLC2A3")) +
  labs(title="Fig 4A: SLC2A3 — Brain Glucose Invariant",
       subtitle="Total SNPs across D17+Ust+Vindija+Otzi (damage-filtered)",
       x="Gene", y="Total SNP count", fill="") +
  theme_minimal(base_size=13) +
  theme(axis.text.x=element_text(angle=45, hjust=1),
        plot.title=element_text(face="bold"),
        legend.position="top") +
  annotate("text", x=10, y=60,
           label="Brain wins\n430,000 years\nno negotiation",
           size=4, color="#1ABC9C", fontface="bold")

ggsave("act3/figure4A_slc2a3_invariant.pdf", p4a, width=10, height=6)
cat("Fig 4A saved\n")

cat("\n=== All figures saved to act3/ ===\n")
