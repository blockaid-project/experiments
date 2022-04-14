#!/usr/bin/env Rscript
library(argparse)
library(tidyr)
library(dplyr)
library(ggplot2)

parser <- ArgumentParser(description="Plot the proportion of wins for each solver")
parser$add_argument("csv_path", help="Path to aggregate CSV produced by `aggregate_winners.py`")
args <- parser$parse_args()

all.data <- read.csv(args$csv_path, header = TRUE, sep = ",")
all.data$kind <- recode_factor(all.data$kind,
                               cold_cache = "Cache miss (template gen)",
                               no_cache = "No cache (checking)")
all.data$app_name <- recode_factor(all.data$app_name,
                                   autolab = "Autolab",
                                   spree = "Spree",
                                   diaspora = "diaspora*",
)
all.data$`Winning\nSolver` <- recode_factor(all.data$winner,
                                            cvc5 = "CVC5",
                                            vampire = "Vampire",
                                            z3 = "Z3")
ggplot(all.data, aes(fill=`Winning\nSolver`, x=app_name, y=count)) +
    geom_bar(position="fill", stat="identity") +
    scale_fill_grey() +
    facet_grid(cols = vars(kind)) +
    theme_bw(base_size = 8) +
    theme(
          axis.line = element_line(colour = "black"),
          axis.title.x=element_blank(),
          axis.title.y=element_blank(),
          panel.border = element_blank(),

          legend.key.height = unit(.4, "cm"),
          legend.key.width = unit(.4, "cm"),

          #legend.justification = c(0, 1),
          #legend.position = c(0, 1),
          #legend.direction = "horizontal",
          legend.position = "right",
          legend.margin=margin(t=0, r=0, b=-0.25, l=0, unit="cm"),
    )

ggsave("winners.pdf", width = 8.50, height = 5, units = "cm", device = cairo_pdf)
