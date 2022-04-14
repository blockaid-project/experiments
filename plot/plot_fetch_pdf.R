#!/usr/bin/env Rscript
library(argparse)
library(tidyr)
library(dplyr)
library(ggplot2)

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

ggplot(agg.data, aes(x = path_abbreviation, y = dur_ms_50, color = Configuration, shape = Configuration)) +
    #geom_boxplot() +
     geom_point(position = position_dodge(width = 0.5)) +
    facet_grid(.~app_name, scales = "free", switch = "x", space = "free_x") +
    theme_bw(base_size = 8) +
    scale_y_continuous(trans='log10', breaks=c(10, 100, 1000, 10000, 100000), labels = c("10 ms", "100 ms", "1 s", "10 s", "100 s")) +
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

ggsave("fetch.pdf", width = 17.846675, height = 5, units = "cm", device = cairo_pdf)
