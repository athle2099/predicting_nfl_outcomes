# **NOTE**: This code will not run, as the input data file is not provided (as it contains proprietary PFF data).

# Clear R environment, and write file directory for file imports.
rm(list = ls())
direc <- "../data/"

# Load in necessary libraries.
library(dplyr)
library(data.table)
library(caret)
library(glmnet)
library(ggplot2)
library(lmtest)
library(Metrics)
library(olsrr)
library(gridExtra)

# We begin with linear regression. 
# We found that using the years 2013-2020 as our training set and 2021-2022 as our testing set worked quite well. 
# This is a 80/20 train/test split. 
# Recall that we are regressing NormalizedMassey against the following positions: 
# DB, DL, K, 
# LB, OL, P, 
# QB, RB, WR.

data <- read.csv(file = paste0(direc, "regression_PFF.csv"), header = TRUE, stringsAsFactors = TRUE)

train <- data[data$Year <= 2020,]
test <- data[data$Year > 2020,]

res <- lm(NormalizedMassey ~ DB + DL + K + LB + OL + P + QB + RB + WR, data = train)
summary(res)

# We now determine the most important variables in our regression.

ols_step_both_p(res, details = FALSE)

# We now regress NormalizedMassey against the relevant variables.

newres <- lm(NormalizedMassey ~ QB + DB + DL + WR + LB + K + OL, data = train)
summary(newres)

# We now check for heteroscedasticity and normality of residuals.

newres.resids <- res$residuals
newres.fitted <- res$fitted.values
residual.graph <- ggplot() + geom_point(aes(x = newres.fitted, y = newres.resids), color = "red", pch = 20, lwd = 3) +
  labs(title = "Residuals vs. Fitted Values", x = "Fitted Values", y = "Residuals") + 
  theme(family="TT Arial") + theme_bw(base_size = 7) + theme(legend.position = "none") + 
  theme(text=element_text(size=12), axis.text=element_text(size=12), axis.title=element_text(size=12), plot.title=element_text(size=12)) + 
  geom_line(aes(x = seq(-0.1, 1, by = 0.1), y = 0), linetype = "dashed", color = "black") +
  theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank()) + 
  scale_x_continuous(breaks = scales::pretty_breaks(n = 15))
residual.graph

newres.standRes <- rstandard(res)
qqnorm(newres.standRes, main= "Normal Probability Plot", ylab = "Standardized Residuals", xlab = "Normal Scores", 
       col="red", pch=20, lwd = 3)
qqline(newres.standRes)

qqnorm <- ggplot(res, aes(sample = rstandard(res))) + geom_qq(color = "red") + stat_qq_line() + 
  labs(title = "Normal Probability Plot", x = "Normal Scores", y = "Standardized Residuals") + 
  theme(family="TT Arial") + theme_bw(base_size = 7) + theme(legend.position = "none") + 
  theme(text=element_text(size=12), axis.text=element_text(size=12), axis.title=element_text(size=12), plot.title=element_text(size=12)) + 
  theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank()) + 
  scale_x_continuous(breaks = scales::pretty_breaks(n = 15))
qqnorm

res <- grid.arrange(residual.graph, qqnorm)

png(paste0(direc, "linregression.jpg"), res = 1200, width = 10000, height = 10000)
plot(res)
dev.off

# A visual check of the residuals versus the fitted values seems to indicate that we have homoscedasticity, as desired. 
# Further, our QQ plot indicates our residuals are properly normalized. 
# To confirm we do not have heteroscedasticity, we use a Breusch-Pagan Test.

bptest(newres)

# As the p-value from the Breusch-Pagan Test >> 0.05, we fail to reject the null hypothesis. Thus, the homoscedasticity condition is fulfilled for linear regression.
# We now use the regression on our testing set to obtain the MSE.

SST.func <- function(actual) {
  ybar <- mean(actual)
  intermed <- (actual - ybar)^2
  return (sum(intermed))
}

SSE.func <- function(actual, predicted) {
  intermed <- (actual - predicted)^2
  return(sum(intermed))
}

RSQA.func <- function(rsquared, count, kparams) {
  top <- (1 - rsquared) * (count - 1)
  bottom <- count - kparams - 1
  return (1 - (top / bottom))
}

set.func <- function(actual, predicted, count, kparams) {
  MAE <- mae(actual, predicted)
  MSE <- mse(actual, predicted)
  RMSE <- rmse(actual, predicted)
  MAPE <- mape(actual, predicted)
  SST <- SST.func(actual)
  SSE <- SSE.func(actual, predicted)
  SSR <- SST-SSE
  RSQ <- 1-(SSE/SST)
  RSQA <- RSQA.func(RSQ, count, kparams)
  return (cbind(MAE,MSE,RMSE,MAPE,SST,SSE,SSR,RSQ, RSQA))
}

newres.pred <- predict(newres,test)
newres.pred <- as.numeric(newres.pred)
newres.ys <- as.numeric(test$NormalizedMassey)

newres.metrics <- set.func(actual = newres.ys, predicted = newres.pred, count = length(test$NormalizedMassey), kparams = 6)
newres.metrics

SST <- sum((newres.ys - mean(newres.ys))^2)
SSR <- sum((newres.pred - mean(newres.ys))^2)
SSE <- sum((newres.ys - newres.pred)^2)
c(SST, SSR, SSE)

# We now run elastic net regularization, with 80% training set and 20% testing set.

x <- data %>%
  select(DB, DL, K, LB, OL, P, QB, RB, WR)
y <- data$NormalizedMassey

x.train <- x[1:(8*32),]
y.train <- y[1:(8*32)]
x.test <- x[(8*32+1):320,]
y.test <- y[(8*32+1):320]

elastic.net <- train(y = y.train, x = x.train, method = 'glmnet')

get_best_result = function(caret_fit) {
  best = which(rownames(caret_fit$results) == rownames(caret_fit$bestTune))
  best_result = caret_fit$results[best,]
  rownames(best_result) = NULL
  best_result
}

get_best_result(elastic.net)
