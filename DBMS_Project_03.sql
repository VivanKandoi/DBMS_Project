-- Cleaning of PlayCalls imported from Excel

RENAME TABLE playcalls to PlayCalls;

ALTER TABLE PlayCalls
RENAME COLUMN PlayCallID TO PlayCall_ID,
RENAME COLUMN GameId TO Game_ID,
RENAME COLUMN OffenseTeam TO Offense_TeamID,
RENAME COLUMN DefenseTeam TO Defense_TeamID,
RENAME COLUMN Yards TO Yards_Gained,
RENAME COLUMN YardLine TO Yard_Line,
RENAME COLUMN YardLineDirection TO Yard_Line_Direction,
RENAME COLUMN PenaltyType TO Penalty_Type,
RENAME COLUMN PenaltyYards TO Penalty_Yards;

-- No 1NF Normalisation

-- 2NF Normalisation

ALTER TABLE PlayCalls
DROP COLUMN GameDate,
DROP COLUMN Formation, 
DROP COLUMN PlayType, 
DROP COLUMN PassType, 
DROP COLUMN RushDirection;

-- 3NF Normalisation 

ALTER TABLE PlayCalls
DROP COLUMN IsRush,
DROP COLUMN IsPass,
DROP COLUMN IsSack,
DROP COLUMN YardLineFixed;







