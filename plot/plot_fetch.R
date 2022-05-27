#!/usr/bin/env Rscript
library(argparse)
library(tidyr)
library(dplyr)
library(ggplot2)
library(tikzDevice)

applications <- c("diaspora", "spree", "autolab")

parser <- ArgumentParser(description="Plot median fetch latency for individual URLs")
parser$add_argument("data_directory", help="directory where experiment data is located")
args <- parser$parse_args()

all.data <- lapply(applications, function(app_name) {
                       df <- Sys.glob(file.path(args$data_directory, "fetch", app_name, "*", "data.csv")) %>%
                           lapply(read.csv, header = TRUE, sep = ",", comment.char = '#') %>% 
                           bind_rows 
                       df$app_name <- app_name
                       df
}) %>% bind_rows
all.data$Configuration <- recode_factor(all.data$tag,
                              `original` = "Original",
                              `modified` = "Modified",
                              `cached` = "Blockaid (cached)",
                              `cold-cache` = "Blockaid (cold cache)",
                              `no-cache` = "Blockaid (no cache)"
                              )

#print(all.data %>% distinct(path_abbreviation, path) %>% select(path_abbreviation, path))

agg.data <- all.data %>%
    group_by(app_name, path_abbreviation, tag, Configuration) %>%
    summarize(dur_ms_50 = median(dur_ms))
agg.data$app_name <- recode_factor(agg.data$app_name,
                                      diaspora = "diaspora*",
                                      spree = "Spree",
                                      autolab = "Autolab"
                                      )

options(tikzLatexPackages 
   =c(getOption( "tikzLatexPackages" ),"\\usepackage{siunitx}"))
tikz(file = "fetch.tex", width = 17.846675/2.54, height = 5/2.54)

ggplot(agg.data, aes(x = path_abbreviation, y = dur_ms_50, color = Configuration, shape = Configuration)) +
    #geom_boxplot() +
     geom_point(position = position_dodge(width = 0.5)) +
    facet_grid(.~app_name, scales = "free", switch = "x", space = "free_x") +
    theme_bw(base_size = 8) +
    scale_y_continuous(trans='log10', breaks=c(10, 100, 1000, 10000, 100000), labels = c("\\SI{10}{ms}", "\\SI{100}{ms}", "\\SI{1}{s}", "\\SI{10}{s}", "\\SI{100}{s}")) +
    scale_color_manual(values=c("#332288", "#CC6677", "#117733", "#AA4499", "#117733")) +
    xlab("URL") +
    ylab("Median fetch time (log scale)") +
    theme(
           strip.placement = "outside",
           panel.grid.minor.y = element_blank(),

           legend.title = element_blank(),
           #legend.justification = c(0, 1),
           #legend.position = c(0, 1),
           #legend.direction = "horizontal",
           legend.position = "top",
           legend.margin=margin(t=0, r=0, b=-0.25, l=0, unit="cm"),
      )

dev.off()
ggsave("fetch.pdf", width = 17.846675, height = 5, units = "cm", device = cairo_pdf)

df.overheads <- agg.data %>%
      pivot_wider(id_cols = c("path_abbreviation", "app_name"), names_from = "tag", values_from = "dur_ms_50") %>%
      transmute(path_abbreviation = path_abbreviation,
                app_name = app_name,
                cachedOverModified = (cached - modified) / modified,
                coldOverModified = (`cold-cache` - modified) / modified,
                noCacheOverModified = (`no-cache` - modified) / modified,
                modifiedOverOriginal = (modified - original) / original
      )

df.overheads.ds <- df.overheads %>% filter(app_name == "diaspora*" | app_name == "Spree")
df.overheads.a <- df.overheads %>% filter(app_name == "Autolab")

overheads <- list(
                  fetchCachedOverheadMedianPerc=median(df.overheads$cachedOverModified) * 100,
                  fetchCachedOverheadMaxPerc=max(df.overheads$cachedOverModified) * 100,
                  fetchColdOverheadMin=min(df.overheads$coldOverModified),
                  fetchColdOverheadMax=max(df.overheads$coldOverModified),
                  fetchNoCacheOverheadMin=min(df.overheads$noCacheOverModified),
                  fetchNoCacheOverheadMax=max(df.overheads$noCacheOverModified),

                  fetchDiasporaSpreeModifiedOverheadMedianPerc=median(df.overheads.ds$modifiedOverOriginal) * 100,
                  fetchDiasporaSpreeModifiedOverheadMaxPerc=max(df.overheads.ds$modifiedOverOriginal) * 100,
                  fetchAutolabModifiedOverheadMedianPerc=median(df.overheads.a$modifiedOverOriginal) * 100,
                  fetchAutolabModifiedOverheadMaxPerc=max(df.overheads.a$modifiedOverOriginal) * 100,

                  fetchSpreeTwoModifiedFasterPerc=(df.overheads %>% filter(path_abbreviation == "S2"))$modifiedOverOriginal * -100
                  )

cat(paste(names(overheads), ": ", overheads, "\n", sep=""))

decls <- paste("\\newcommand{\\", names(overheads), "}{", overheads, "}", sep="")
write(decls,file="fetch_data.tex")
