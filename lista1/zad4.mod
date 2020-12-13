# Author: Piotr Berezowski, 236749

set Courses;  # Set of all courses
set Groups;  # Set of all course's groups
set Days;   # Set of all days
set TrainingGroups;   # Set of all trainings

# ========= Time-related params: =========
# In this model time splits into equal periods of time (in minutes)
param PeriodLen integer;   # Number of minutes in single period of time
check (24 * 60) mod PeriodLen = 0;   # check if day can be correctly split

param PeriodsInDay := 24 * 60 div PeriodLen;   # Number of periods per day

# Max number of periods, that can be spent on classes daily
param MaxPeriodsPerDay integer, >= 0;

# Lunch break - ensure at least BreakLen periods of free time between BreakStart (including) and BreakEnd (excluding)
param BreakStart integer, >= 0, <= PeriodsInDay;
param BreakEnd integer, >= 0, <= PeriodsInDay;
param BreakLen integer, >= 0;   # Min length of lunch break
check BreakEnd - BreakStart >= BreakLen;


# ========= Courses-related params: =========
param CourseTime{Courses, Groups} integer, >= 0, <= PeriodsInDay;   # When course starts (provided in number of periods from 00:00)
param CourseDay{Courses, Groups, Days} binary;   # What day is the course
param CourseDuration{Courses} integer;
check{c in Courses, g in Groups} sum{d in Days} CourseDay[c,g,d] <= 1;   # Can take place max once a week (0 if course excluded from schedule)

# Binary param - Determines when courses take place
# CourseTimetable[c,g,d,p] = 1 if group g of course c takes place during p period of day d, otherwise CourseTimetable[c,g,d,p] = 0
param CourseTimetable {c in Courses, g in Groups, d in Days, p in 0..PeriodsInDay} :=
    if CourseDay[c, g, d] = 1 and p >= CourseTime[c, g] and p < CourseTime[c, g] + CourseDuration[c] then 1 else 0;

param CourseScore{Courses, Groups};   # Score of each course and group
param MinCourseScore integer >= 0;   # Min score of course, needed to include course into student's schedule


# ========= Training-related params: =========
param MinNumberOfTrainings;   # Minimum number of trainings which have to be included into student's schedule

param TrainingTime{TrainingGroups} integer, >= 0, <= PeriodsInDay;   # When training starts - similar to CourseTime
param TrainingDay{TrainingGroups, Days} binary;   # On which day training occurs - similar to CourseDay
param TrainingDuration integer;   # Number of periods that each training lasts - similar to CourseDuration
check{t in TrainingGroups} sum{d in Days} TrainingDay[t,d] <= 1;

# Binary param - Determines when training take place
# similar to CourseTimetable
param TrainingTimetable{t in TrainingGroups, d in Days, p in 0..PeriodsInDay} :=
    if TrainingDay[t, d] = 1 and p >= TrainingTime[t] and p < TrainingTime[t] + TrainingDuration then 1 else 0;


# ========= Variables: =========
# courseSelected[c,g] = 1 if group g of course c is selected, otherwise 0 
var courseSelected{Courses, Groups} binary;
# trainingSelected[t] = 1 if training t is selected, otherwise 0 
var trainingSelected{TrainingGroups} binary;


maximize total_score: sum{c in Courses, g in Groups} courseSelected[c, g] * CourseScore[c,g];


s.t. one_group_per_course{c in Courses}: sum{g in Groups} courseSelected[c,g] = 1;

s.t. daily_time_limit{d in Days}: sum{c in Courses, g in Groups, p in 0..PeriodsInDay} courseSelected[c,g] * CourseTimetable[c, g, d, p] <= MaxPeriodsPerDay;

s.t. lunch_break{d in Days}: sum{c in Courses, g in Groups, p in BreakStart..(BreakEnd-1)} courseSelected[c,g] * CourseTimetable[c, g, d, p] <= BreakEnd - BreakStart - BreakLen;

s.t. one_thing_at_a_time{d in Days, p in 0..PeriodsInDay}: 
    sum{c in Courses, g in Groups} courseSelected[c, g] * CourseTimetable[c, g, d, p] +  sum{t in TrainingGroups} trainingSelected[t] * TrainingTimetable[t, d, p] <= 1;

s.t. min_number_of_trenings: sum{t in TrainingGroups} trainingSelected[t] >= MinNumberOfTrainings;

# works only with positive scores
s.t. min_course_score{c in Courses, g in Groups}: CourseScore[c, g] >= courseSelected[c, g] * MinCourseScore;

s.t. select_course_only_if_occurs{c in Courses, g in Groups}: courseSelected[c, g] <= sum{d in Days} CourseDay[c, g, d];

s.t. select_training_only_if_occurs{t in TrainingGroups}: trainingSelected[t] <= sum{d in Days} TrainingDay[t, d];


solve;


printf "Wybrane kursy:\n";
for {c in Courses, g in Groups: courseSelected[c, g] = 1} {
    printf "  %s grupa - %s   (%g pkt.)\n", g, c, CourseScore[c, g];
}
printf "\nCałkowita ilość punktów preferencyjnych: %g\n", total_score;
printf "\nWybrane grupy treningów: ";
for{t in TrainingGroups: trainingSelected[t] = 1} {
    printf " %s ", t;
}
printf "\n";


data;


set Courses := 'Algebra' 'Analiza' 'Fizyka' 'Chemia min.' 'Chemia org.';
set Groups := 'I' 'II' 'III' 'IV';
set Days := 'Pon' 'Wt' 'Sr' 'Czw' 'Pt';
set TrainingGroups := 'I' 'II' 'III';

# Time params
param PeriodLen := 30;
param MaxPeriodsPerDay := 8;

param BreakStart := 24;
param BreakEnd := 28;
param BreakLen := 2;


# Course params
param CourseTime : 'I'   'II'   'III'   'IV' :=
    'Algebra'     26    20     20      22
    'Analiza'     26    20     22      16
    'Fizyka'      16    20     30      34
    'Chemia min.' 16    16     26      26
    'Chemia org.' 18    20     22      26;

param CourseDay :=
    [*, *, 'Pon'] : 'I'   'II'   'III'   'IV' :=
    'Algebra'       1     0      0       0
    'Analiza'       1     0      0       0
    'Fizyka'        0     0      0       0
    'Chemia min.'   1     1      0       0
    'Chemia org.'   1     1      0       0
    [*, *, 'Wt'] : 'I'   'II'   'III'   'IV' :=
    'Algebra'       0     1      0       0
    'Analiza'       0     1      0       0
    'Fizyka'        1     1      0       0
    'Chemia min.'   0     0      0       0
    'Chemia org.'   0     0      0       0
    [*, *, 'Sr'] : 'I'   'II'   'III'   'IV' :=
    'Algebra'       0     0      1       1
    'Analiza'       0     0      1       0
    'Fizyka'        0     0      0       0
    'Chemia min.'   0     0      0       0
    'Chemia org.'   0     0      0       0
    [*, *, 'Czw'] : 'I'   'II'   'III'   'IV' :=
    'Algebra'       0     0      0       0
    'Analiza'       0     0      0       1
    'Fizyka'        0     0      1       1
    'Chemia min.'   0     0      1       0
    'Chemia org.'   0     0      0       0
    [*, *, 'Pt'] : 'I'   'II'   'III'   'IV' :=
    'Algebra'       0     0      0       0
    'Analiza'       0     0      0       0
    'Fizyka'        0     0      0       0
    'Chemia min.'   0     0      0       1
    'Chemia org.'   0     0      1       1;

param CourseDuration := 'Algebra' 4 'Analiza' 4 'Fizyka' 6 'Chemia min.' 4 'Chemia org.' 3;

param CourseScore : 'I'   'II'   'III'   'IV' :=
'Algebra'     5     4      10      5
'Analiza'     4     4      5       6
'Fizyka'      3     5      7       8
'Chemia min.' 10    10     7       5
'Chemia org.' 0     5      3       4;

param MinCourseScore := 0;


# Training params
param MinNumberOfTrainings := 1;

param TrainingDuration := 4;
param TrainingTime := 'I' 26 'II' 22 'III' 26;

param TrainingDay : 'Pon' 'Wt' 'Sr' 'Czw' 'Pt' :=
            'I'     1      0     0     0     0
            'II'    0      0     1     0     0
            'III'   0      0     1     0     0;

end;
