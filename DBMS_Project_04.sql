-- 1. Calculate total points scored by each team as home team
SELECT t.TeamName, SUM(g.Home_Score) AS TotalHomePoints
FROM Games g
JOIN Teams t ON g.Home_TeamID = t.TeamID
GROUP BY t.TeamName
ORDER BY TotalHomePoints DESC;

-- 2. Calculate total points scored by each team as away team
SELECT t.TeamName, SUM(g.Home_Score) AS TotalHomePoints
FROM Games g
JOIN Teams t ON g.Away_TeamID = t.TeamID
GROUP BY t.TeamName
ORDER BY TotalHomePoints DESC;

-- 3. Home vs. Away Performance
SELECT 
    t.TeamName,
    SUM(CASE WHEN g.Home_TeamID = t.TeamID THEN 1 ELSE 0 END) AS HomeGames,
    SUM(CASE WHEN g.Home_TeamID = t.TeamID AND g.Home_Score > g.Away_Score THEN 1 ELSE 0 END) AS HomeWins,
    SUM(CASE WHEN g.Away_TeamID = t.TeamID THEN 1 ELSE 0 END) AS AwayGames,
    SUM(CASE WHEN g.Away_TeamID = t.TeamID AND g.Away_Score > g.Home_Score THEN 1 ELSE 0 END) AS AwayWins
FROM Teams t
JOIN Games g ON t.TeamID = g.Home_TeamID OR t.TeamID = g.Away_TeamID
GROUP BY t.TeamName;

-- 4. Play Analysis by Downs for each Team
SELECT 
    t.TeamName,
    pc.Down,
    AVG(pc.Yards_Gained) AS AvgYards,
    COUNT(*) AS TotalPlays,
    SUM(CASE WHEN p.Type = 'PASS' THEN 1 ELSE 0 END) AS PassPlays,
    SUM(CASE WHEN p.Type = 'RUSH' THEN 1 ELSE 0 END) AS RushPlays
FROM PlayCalls pc
JOIN Teams t ON pc.Offense_TeamID = t.TeamID
JOIN Plays p ON pc.Play_ID = p.Play_ID
WHERE pc.Down BETWEEN 1 AND 4
GROUP BY t.TeamName, pc.Down
ORDER BY t.TeamName, pc.Down;

-- 5. Points Scored/Allowed Per Game
SELECT 
    t.TeamName,
    ROUND(SUM(CASE WHEN g.Home_TeamID = t.TeamID THEN g.Home_Score ELSE g.Away_Score END) / COUNT(*), 2) AS AvgPointsScored,
    ROUND(SUM(CASE WHEN g.Home_TeamID = t.TeamID THEN g.Away_Score ELSE g.Home_Score END) / COUNT(*), 2) AS AvgPointsAllowed,
    ROUND(SUM(CASE WHEN g.Home_TeamID = t.TeamID THEN g.Home_Score ELSE g.Away_Score END) - 
          SUM(CASE WHEN g.Home_TeamID = t.TeamID THEN g.Away_Score ELSE g.Home_Score END), 2) AS PointDifferential
FROM Teams t
JOIN Games g ON t.TeamID = g.Home_TeamID OR t.TeamID = g.Away_TeamID
GROUP BY t.TeamName
ORDER BY PointDifferential DESC;

-- 6. Rush Direction Effectiveness
SELECT 
    t.TeamName,
    p.Rush_Direction,
    COUNT(*) AS Attempts,
    AVG(pc.Yards_Gained) AS AvgYards,
    SUM(CASE WHEN pc.Yards_Gained >= 4 THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS SuccessRate
FROM PlayCalls pc
JOIN Teams t ON pc.Offense_TeamID = t.TeamID
JOIN Plays p ON pc.Play_ID = p.Play_ID
WHERE p.Type = 'RUSH' AND p.Rush_Direction IS NOT NULL
GROUP BY t.TeamName, p.Rush_Direction
ORDER BY t.TeamName, AvgYards DESC;

-- 7. Passing Game Analysis
SELECT 
    t.TeamName,
    p.Pass_Type,
    COUNT(*) AS Attempts,
    AVG(pc.Yards_Gained) AS AvgYards,
    SUM(CASE WHEN pc.Yards_Gained >= 15 THEN 1 ELSE 0 END) AS BigPlays
FROM PlayCalls pc
JOIN Teams t ON pc.Offense_TeamID = t.TeamID
JOIN Plays p ON pc.Play_ID = p.Play_ID
WHERE p.Type = 'PASS' AND p.Pass_Type IS NOT NULL
GROUP BY t.TeamName, p.Pass_Type
ORDER BY t.TeamName, AvgYards DESC;

-- 8. Team Performance by Quarter (Using Play Data)
SELECT 
    t.TeamName,
    pc.Quarter,
    AVG(pc.Yards_Gained) AS AvgYardsPerPlay,
    COUNT(*) AS TotalPlays,
    SUM(CASE WHEN p.Type = 'PASS' THEN 1 ELSE 0 END) AS PassAttempts,
    SUM(CASE WHEN p.Type = 'RUSH' THEN 1 ELSE 0 END) AS RushAttempts
FROM PlayCalls pc
JOIN Teams t ON pc.Offense_TeamID = t.TeamID
JOIN Plays p ON pc.Play_ID = p.Play_ID
GROUP BY t.TeamName, pc.Quarter
ORDER BY t.TeamName, pc.Quarter;

-- 9. Red Zone Efficiency
SELECT 
    t.TeamName,
    SUM(CASE WHEN pc.Yard_Line <= 20 AND pc.Yards_Gained >= pc.Yard_Line THEN 1 ELSE 0 END) AS RedZoneTDs,
    SUM(CASE WHEN pc.Yard_Line <= 20 THEN 1 ELSE 0 END) AS RedZoneAttempts,
    ROUND(SUM(CASE WHEN pc.Yard_Line <= 20 AND pc.Yards_Gained >= pc.Yard_Line THEN 1 ELSE 0 END) * 100.0 / 
          NULLIF(SUM(CASE WHEN pc.Yard_Line <= 20 THEN 1 ELSE 0 END), 0), 2) AS RedZoneEfficiency
FROM PlayCalls pc
JOIN Teams t ON pc.Offense_TeamID = t.TeamID
GROUP BY t.TeamName
ORDER BY RedZoneEfficiency DESC;

-- 10. Defensive Performance
SELECT 
    t.TeamName,
    AVG(g.Away_Score) AS AvgPointsAllowedHome,
    AVG(CASE WHEN g.Away_TeamID = t.TeamID THEN g.Home_Score ELSE NULL END) AS AvgPointsAllowedAway,
    COUNT(DISTINCT CASE WHEN g.Home_TeamID = t.TeamID AND g.Away_Score = 0 THEN g.Game_ID END) AS HomeShutouts,
    COUNT(DISTINCT CASE WHEN g.Away_TeamID = t.TeamID AND g.Home_Score = 0 THEN g.Game_ID END) AS AwayShutouts
FROM Teams t
JOIN Games g ON t.TeamID = g.Home_TeamID OR t.TeamID = g.Away_TeamID
GROUP BY t.TeamName;

-- 11. Turnover Analysis
SELECT 
    t.TeamName,
    SUM(CASE WHEN p.Type IN ('FUMBLES', 'INTERCEPTION') THEN 1 ELSE 0 END) AS TurnoversForced,
    SUM(CASE WHEN p.Type IN ('FUMBLES', 'INTERCEPTION') AND pc.Offense_TeamID = t.TeamID THEN 1 ELSE 0 END) AS TurnoversCommitted,
    SUM(CASE WHEN p.Type IN ('FUMBLES', 'INTERCEPTION') THEN 1 ELSE 0 END) - 
    SUM(CASE WHEN p.Type IN ('FUMBLES', 'INTERCEPTION') AND pc.Offense_TeamID = t.TeamID THEN 1 ELSE 0 END) AS TurnoverDifferential
FROM PlayCalls pc
JOIN Teams t ON pc.Defense_TeamID = t.TeamID OR pc.Offense_TeamID = t.TeamID
JOIN Plays p ON pc.Play_ID = p.Play_ID
WHERE p.Type IN ('FUMBLES', 'INTERCEPTION')
GROUP BY t.TeamName
ORDER BY TurnoverDifferential DESC;

-- 12. Formation Effectiveness
SELECT 
    t.TeamName,
    p.Formation,
    COUNT(*) AS Plays,
    AVG(pc.Yards_Gained) AS AvgYards,
    SUM(CASE WHEN pc.Yards_Gained >= 15 THEN 1 ELSE 0 END) AS ExplosivePlays,
    SUM(CASE WHEN p.Type = 'PASS' AND pc.Yards_Gained >= 20 THEN 1 
             WHEN p.Type = 'RUSH' AND pc.Yards_Gained >= 10 THEN 1
             ELSE 0 END) * 100.0 / COUNT(*) AS BigPlayRate
FROM PlayCalls pc
JOIN Teams t ON pc.Offense_TeamID = t.TeamID
JOIN Plays p ON pc.Play_ID = p.Play_ID
GROUP BY t.TeamName, p.Formation
HAVING COUNT(*) > 10
ORDER BY t.TeamName, BigPlayRate DESC;

-- 13. Red Zone Play Selection
SELECT 
    t.TeamName,
    p.Type,
    p.Formation,
    COUNT(*) AS Plays,
    SUM(CASE WHEN pc.Yards_Gained >= pc.Yard_Line THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS TouchdownRate
FROM PlayCalls pc
JOIN Teams t ON pc.Offense_TeamID = t.TeamID
JOIN Plays p ON pc.Play_ID = p.Play_ID
WHERE pc.Yard_Line <= 20
GROUP BY t.TeamName, p.Type, p.Formation
HAVING COUNT(*) > 3
ORDER BY t.TeamName, TouchdownRate DESC;

-- 14. Quarterback Pressure Analysis
SELECT 
    t.TeamName AS Defense,
    COUNT(*) AS TotalPressures,
    SUM(CASE WHEN p.Type = 'SACK' THEN 1 ELSE 0 END) AS Sacks,
    SUM(CASE WHEN p.Type = 'SACK' THEN -pc.Yards_Gained ELSE 0 END) AS SackYards,
    SUM(CASE WHEN p.Pass_Type LIKE 'Short%' THEN 1 ELSE 0 END) AS ForcedShortPasses,
    SUM(CASE WHEN p.Pass_Type LIKE 'Deep%' THEN 1 ELSE 0 END) AS DisruptedDeepPasses
FROM PlayCalls pc
JOIN Teams t ON pc.Defense_TeamID = t.TeamID
JOIN Plays p ON pc.Play_ID = p.Play_ID
WHERE p.Type IN ('SACK', 'PASS')
GROUP BY t.TeamName
ORDER BY TotalPressures DESC;

-- 15. Run-Pass Balance by Score Differential
SELECT 
    t.TeamName,
    CASE 
        WHEN g.Home_TeamID = t.TeamID AND (g.Home_Score - g.Away_Score) > 7 THEN 'Leading'
        WHEN g.Away_TeamID = t.TeamID AND (g.Away_Score - g.Home_Score) > 7 THEN 'Leading'
        WHEN g.Home_TeamID = t.TeamID AND (g.Home_Score - g.Away_Score) < -7 THEN 'Trailing'
        WHEN g.Away_TeamID = t.TeamID AND (g.Away_Score - g.Home_Score) < -7 THEN 'Trailing'
        ELSE 'Neutral'
    END AS GameState,
    SUM(CASE WHEN p.Type = 'PASS' THEN 1 ELSE 0 END) AS PassAttempts,
    SUM(CASE WHEN p.Type = 'RUSH' THEN 1 ELSE 0 END) AS RushAttempts,
    SUM(CASE WHEN p.Type = 'PASS' THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS PassPercentage
FROM PlayCalls pc
JOIN Teams t ON pc.Offense_TeamID = t.TeamID
JOIN Plays p ON pc.Play_ID = p.Play_ID
JOIN Games g ON pc.Game_ID = g.Game_ID
GROUP BY t.TeamName, GameState
ORDER BY t.TeamName, GameState;

-- 16. Defensive Coverage Breakdown
SELECT 
    t.TeamName AS Defense,
    p.Pass_Type,
    COUNT(*) AS Targets,
    AVG(pc.Yards_Gained) AS AvgYardsAllowed,
    SUM(CASE WHEN p.Type = 'INTERCEPTION' THEN 1 ELSE 0 END) AS Interceptions,
    SUM(CASE WHEN pc.Yards_Gained >= 20 THEN 1 ELSE 0 END) AS BigPlaysAllowed
FROM PlayCalls pc
JOIN Teams t ON pc.Defense_TeamID = t.TeamID
JOIN Plays p ON pc.Play_ID = p.Play_ID
WHERE p.Type = 'PASS'
GROUP BY t.TeamName, p.Pass_Type
ORDER BY t.TeamName, AvgYardsAllowed;

-- 17. Most Frequently Used Plays
SELECT Type, COUNT(*) as count
FROM Plays
GROUP BY Type
ORDER BY count DESC
LIMIT 5;

-- 18. Pass-Run Ratio by Teams
SELECT 
    t.TeamName AS OffensiveTeam,
    SUM(CASE WHEN p.Type = 'PASS' THEN 1 ELSE 0 END) AS PassAttempts,
    SUM(CASE WHEN p.Type = 'RUSH' THEN 1 ELSE 0 END) AS RushAttempts,
    ROUND(
        SUM(CASE WHEN p.Type = 'PASS' THEN 1 ELSE 0 END) * 1.0 / 
        NULLIF(SUM(CASE WHEN p.Type = 'RUSH' THEN 1 ELSE 0 END), 0), 
    2
    ) AS PassRunRatio
FROM PlayCalls pc
JOIN Teams t ON pc.Offense_TeamID = t.TeamID
JOIN Plays p ON pc.Play_ID = p.Play_ID
WHERE p.Type IN ('PASS', 'RUSH')
GROUP BY t.TeamName
ORDER BY PassRunRatio DESC;

-- 19. Formation-PlayType Analysis
SELECT 
    p.Formation,
    COUNT(*) AS TotalPlays,
    AVG(pc.Yards_Gained) AS AvgYards,
    SUM(CASE WHEN p.Type = 'PASS' THEN 1 ELSE 0 END) AS PassPlays,
    SUM(CASE WHEN p.Type = 'RUSH' THEN 1 ELSE 0 END) AS RushPlays,
    SUM(CASE WHEN pc.Yards_Gained >= 20 THEN 1 ELSE 0 END) AS BigPlays
FROM PlayCalls pc
JOIN Plays p ON pc.Play_ID = p.Play_ID
WHERE p.Formation IS NOT NULL
GROUP BY p.Formation
HAVING COUNT(*) > 50
ORDER BY AvgYards DESC;

-- Team Performane Summary
SELECT 
    t.TeamName,
    COUNT(DISTINCT g.Game_ID) AS GamesPlayed,
    SUM(CASE WHEN g.Home_TeamID = t.TeamID AND g.Home_Score > g.Away_Score 
             OR g.Away_TeamID = t.TeamID AND g.Away_Score > g.Home_Score THEN 1 ELSE 0 END) AS Wins,
    SUM(g.Home_Score + g.Away_Score) AS TotalPoints,
    ROUND(AVG(CASE WHEN g.Home_TeamID = t.TeamID THEN g.Home_Score ELSE g.Away_Score END), 1) AS AvgPointsScored,
    ROUND(AVG(CASE WHEN g.Home_TeamID = t.TeamID THEN g.Away_Score ELSE g.Home_Score END), 1) AS AvgPointsAllowed
FROM Teams t
LEFT JOIN Games g ON t.TeamID = g.Home_TeamID OR t.TeamID = g.Away_TeamID
GROUP BY t.TeamName
ORDER BY Wins DESC;























