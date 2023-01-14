# Video properties and balancing

Part of the project involved analyzing visual regions that processed low-level visual features. To reduce the possibility of having a visual property covariating with one of the categories, I decided to create sets of videos for each category that were balanced

After collecting videos that included cats, dogs, humans or cars. I cut the videos into short fragments that lasted between 3.5 and 5.5 s. To reduce the possibility of having a category unbalanced in some low-level visual property, I measured the hue, saturation, brightness, contrast and motion of every video. This is the code to do that (/calculateVideoValues.m).