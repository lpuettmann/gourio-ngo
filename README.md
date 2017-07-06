These codes accompany [this](http://lukaspuettmann.com/2017/07/06/gourio-ngo-inflation-stocks/) blog post.

For necessary packages:

```r
install.packages("tidyverse")
install.packages("zoo")
install.packages("devtools")
devtools::install_github("jcizel/FredR")
```

To get data from Fred, you'll need to [register](https://research.stlouisfed.org/docs/api/api_key.html) an API key and insert it at

```r
api_key <- "yourkeyhere"
```