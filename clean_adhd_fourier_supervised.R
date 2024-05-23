# Load required libraries
library(caret)
library(doParallel)
library(pROC)
library(xgboost)

# Read and preprocess the dataset
fourier_dataset <- read.csv("fourier_dataset.csv")
fourier_dataset <- na.omit(fourier_dataset)

# Split the dataset into training and testing sets with stratified sampling
set.seed(123)
train_indices <- createDataPartition(fourier_dataset$ADHD, p = 0.7, list = FALSE)
train_data <- fourier_dataset[train_indices, ]
test_data <- fourier_dataset[-train_indices, ]

# Convert ADHD to factor for Random Forest and numeric for XGBoost
ADHD_rf_train <- factor(train_data$ADHD, levels = c(0, 1), labels = c("Control", "Case"))
ADHD_rf_test <- factor(test_data$ADHD, levels = c(0, 1), labels = c("Control", "Case"))
ADHD_xgb_train <- as.numeric(train_data$ADHD)
ADHD_xgb_test <- as.numeric(test_data$ADHD)

# Remove the original ADHD column from the feature set
train_features_rf <- train_data[, -which(names(train_data) == "ADHD")]
test_features_rf <- test_data[, -which(names(test_data) == "ADHD")]
train_features_xgb <- train_data[, -which(names(train_data) == "ADHD")]
test_features_xgb <- test_data[, -which(names(test_data) == "ADHD")]

# Set up parallel processing
registerDoParallel(cores = detectCores() - 1)

##### Random Forest Model #####
set.seed(123)
trControl <- trainControl(
  method = "cv",
  number = 10,
  savePredictions = "final",
  classProbs = TRUE,
  summaryFunction = twoClassSummary
)
class_weights <- ifelse(ADHD_rf_train == "Case", 4, 1)

table(ADHD_rf_train)
table(class_weights)

model_rf <- train(
  x = train_features_rf,
  y = ADHD_rf_train,
  method = "rf",
  trControl = trControl,
  weights = class_weights,
  metric = "Kappa"
)
predictions_rf <- predict(model_rf, newdata = test_features_rf)
confusion_matrix_rf <- confusionMatrix(predictions_rf, ADHD_rf_test)
print(confusion_matrix_rf)

# XGBoost Model
dtrain <- xgb.DMatrix(data = as.matrix(train_features_xgb), label = ADHD_xgb_train)
dtest <- xgb.DMatrix(data = as.matrix(test_features_xgb), label = ADHD_xgb_test)

params_xgb <- list(
  booster = "gbtree",
  objective = "binary:logistic",
  eta = 0.01,
  max_depth = 6,
  eval_metric = "auc",
  scale_pos_weight = 3
)
xgb_model <- xgb.train(params = params_xgb, data = dtrain, nrounds = 500, nthread = 1, early_stopping_rounds = 10, watchlist = list(eval = dtest, train = dtrain))
predictions_xgb <- predict(xgb_model, newdata = dtest)
predictions_xgb <- factor(ifelse(predictions_xgb > 0.5, "Case", "Control"), levels = c("Control", "Case"))
confusion_matrix_xgb <- confusionMatrix(predictions_xgb, ADHD_rf_test)
print(confusion_matrix_xgb)


#### XGBoost Grid Seearch ####
# Prepare data for XGBoost
dtrain <- xgb.DMatrix(data = as.matrix(train_features_xgb), label = ADHD_xgb_train)
dtest <- xgb.DMatrix(data = as.matrix(test_features_xgb), label = ADHD_xgb_test)

# Define the parameter grid
params <- list(
  eta = c(0.01, 0.1, 0.3),
  max_depth = c(3, 6, 9),
  subsample = c(0.5, 0.7, 1.0),
  colsample_bytree = c(0.5, 0.7, 1.0)
)

# Perform grid search
xgb_grid <- expand.grid(params)
best_params <- list()
best_auc <- 0

for (i in 1:nrow(xgb_grid)) {
  current_params <- as.list(xgb_grid[i, ])
  xgb_model <- xgb.train(params = current_params, data = dtrain, nrounds = 100, nthread = 1, early_stopping_rounds = 10, watchlist = list(eval = dtest, train = dtrain), verbose = 0)

  predictions_xgb <- predict(xgb_model, newdata = dtest)
  current_auc <- auc(ADHD_xgb_test, predictions_xgb)

  if (current_auc > best_auc) {
    best_params <- current_params
    best_auc <- current_auc
  }
}

# Train the final model with the best parameters
xgb_model_best <- xgb.train(params = best_params, data = dtrain, nrounds = 500, nthread = 1, early_stopping_rounds = 20, watchlist = list(eval = dtest, train = dtrain))
predictions_xgb <- predict(xgb_model_best, newdata = dtest)
predictions_xgb <- factor(ifelse(predictions_xgb > 0.5, "Case", "Control"), levels = c("Control", "Case"))
confusion_matrix_xgb <- confusionMatrix(predictions_xgb, ADHD_rf_test)
print(confusion_matrix_xgb)

