library(readr)
library(dplyr)

# Download zip folder
download.file("https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip", 
              "./Dataset.zip", method = 'curl')


### Pulling out files from the zip folder ###
activityLabel <- read.table(unz("Dataset.zip", 
                                "UCI HAR Dataset/activity_labels.txt"), 
                            sep = " ")
names(activityLabel) <- c('Label','Activity')

features <- read.table(unz("Dataset.zip",
                           "UCI HAR Dataset/features.txt"),
                       sep = " ")[,2] # we dont need the indices

# Training set
subjectTrain <- read.table(unz("Dataset.zip",
                               "UCI HAR Dataset/train/subject_train.txt"),
                           sep = " ")
XTrain <- read.table(unz("Dataset.zip",
                         "UCI HAR Dataset/train/X_train.txt"))
yTrain <- read.table(unz("Dataset.zip",
                         "UCI HAR Dataset/train/y_train.txt"),
                     sep = " ")

# Testing Set
subjectTest <- read.table(unz("Dataset.zip",
                               "UCI HAR Dataset/test/subject_test.txt"),
                           sep = " ")
XTest <- read.table(unz("Dataset.zip",
                         "UCI HAR Dataset/test/X_test.txt"))
yTest <- read.table(unz("Dataset.zip",
                         "UCI HAR Dataset/test/y_test.txt"),
                     sep = " ")


### Cleaning & merging data ###
# Merging columns for each set
train <- cbind(subjectTrain, XTrain, yTrain)
test <- cbind(subjectTest, XTest, yTest)

# Setting column names for each set
names(train) <- c('Subject', features, 'Activity')
names(test) <- c('Subject', features, 'Activity')

# Merging training and testing sets
data <- rbind(train, test)

# Change the "Activity" column to show activity instead of label
#   To do this we will use gsub and reference the mapping from activityLabel 
for (i in 1:dim(activityLabel)[1]) {
  data$Activity <- gsub(activityLabel[i,"Label"], 
                        activityLabel[i,"Activity"],
                        data$Activity)
}

# Extract only measurements on mean and stdev
# Find feature names with mean() or std()
meanFeatures <- grepl("mean[(][)]", features)
stdFeatures <- grepl("std[(][)]", features)
relevantFeatures <- c('Subject', 
                      features[meanFeatures | stdFeatures], 
                      'Activity')
data <- data[relevantFeatures]

# Make column names descriptive, clear, & consistent
names(data) <- gsub('-mean[(][)]', ' -Mean ', names(data)) 
names(data) <- gsub('-std[(][)]', ' -StDev ', names(data))
names(data) <- gsub('^t', 'TimeSignal -', names(data))
names(data) <- gsub('^f', 'FrequencySignal -', names(data))
names(data)[grepl('[XYZ]$', names(data))] <- paste0(names(data)[grepl('[XYZ]$', names(data))], "Axis")
names(data) <- gsub("([[:upper:]])", " \\1", names(data))
names(data) <- gsub("Acc", "Acceleration", names(data))
# Remove leading/trailing spaces
names(data) <- gsub("^ ", "", names(data))
names(data) <- gsub(" $", "", names(data))


### Create Second Dataset for Grouped Averages ###
meanData <- data %>% group_by(Activity, Subject) %>% summarize_all('mean')
# Changing column labels
otherFeatures <- names(data)[! names(data) %in% c('Activity','Subject')]
names(meanData) <- c('Activity', 'Subject', paste('AVG -', otherFeatures))


### Save clean data ###
# Write cleaned datasets to file
write.table(data, file = "./tidy_dataset.txt", sep = " ")
write.table(meanData, file = "./tidy_mean_dataset.txt", sep = " ")
