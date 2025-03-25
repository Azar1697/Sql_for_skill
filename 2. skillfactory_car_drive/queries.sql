-- задача 1
SELECT 
    Ca.name AS car_name,
    Ca.class AS car_class,
    AVG(R.position) AS average_position,
    COUNT(R.race) AS race_count
FROM Cars Ca
LEFT JOIN Results R ON R.car = Ca.name
GROUP BY Ca.name, Ca.class
HAVING (Ca.class, AVG(R.position)) IN (
    SELECT 
        class, 
        MIN(AVG_Position)
    FROM (
        SELECT 
            Ca3.class AS class, 
            AVG(R2.position) AS AVG_Position
        FROM Cars Ca3
        LEFT JOIN Results R2 ON R2.car = Ca3.name
        GROUP BY Ca3.class, Ca3.name
    ) SubQuery
    GROUP BY class
)
ORDER BY average_position;

-- задача 2
SELECT 
    Ca.name AS car_name,
    Ca.class AS car_class,
    Cl.country AS country,
    AVG(R.position) AS average_position,
    COUNT(R.race) AS race_count
FROM Cars Ca
JOIN Results R ON R.car = Ca.name
JOIN Classes Cl ON Cl.class = Ca.class
GROUP BY Ca.name, Ca.class, Cl.country
ORDER BY AVG(R.position) ASC, Ca.name ASC
LIMIT 1;

-- задача 3
WITH ClassStats AS (
    SELECT 
        Ca.class,
        AVG(R.position) AS class_avg_position,
        COUNT(R.race) AS total_races_in_class
    FROM Cars Ca
    JOIN Results R ON R.car = Ca.name
    GROUP BY Ca.class
),
MinClassPosition AS (
    SELECT 
        MIN(class_avg_position) AS min_class_avg_position
    FROM ClassStats
)
SELECT 
    Ca.name AS car_name,
    Ca.class AS car_class,
    Cl.country AS country,
    AVG(R.position) AS average_position,
    COUNT(R.race) AS race_count,
    CS.total_races_in_class AS total_class_races
FROM Cars Ca
JOIN Results R ON R.car = Ca.name
JOIN Classes Cl ON Cl.class = Ca.class
JOIN ClassStats CS ON CS.class = Ca.class
JOIN MinClassPosition MCP ON CS.class_avg_position = MCP.min_class_avg_position
GROUP BY Ca.name, Ca.class, Cl.country, CS.total_races_in_class
ORDER BY Ca.name;

-- задача 4
WITH ClassAverage AS (
    SELECT 
        Ca.class,
        AVG(R.position) AS class_avg_position,
        COUNT(DISTINCT Ca.name) AS car_count_in_class
    FROM Cars Ca
    JOIN Results R ON R.car = Ca.name
    GROUP BY Ca.class
    HAVING COUNT(DISTINCT Ca.name) >= 2
),
CarPerformance AS (
    SELECT 
        Ca.name AS car_name,
        Ca.class AS car_class,
        Cl.country AS country,
        AVG(R.position) AS car_avg_position,
        COUNT(R.race) AS race_count
    FROM Cars Ca
    JOIN Results R ON R.car = Ca.name
    JOIN Classes Cl ON Cl.class = Ca.class
    GROUP BY Ca.name, Ca.class, Cl.country
)
SELECT 
    CP.car_name,
    CP.car_class,
    CP.country,
    CP.car_avg_position,
    CP.race_count
FROM CarPerformance CP
JOIN ClassAverage CA ON CP.car_class = CA.class
WHERE CP.car_avg_position < CA.class_avg_position
ORDER BY CP.car_class, CP.car_avg_position;

-- задача 5
WITH CarStats AS (
    SELECT 
        Ca.name AS car_name,
        Ca.class AS car_class,
        Cl.country AS car_country,
        AVG(R.position) AS average_position,
        COUNT(R.race) AS race_count
    FROM Cars Ca
    JOIN Results R ON R.car = Ca.name
    JOIN Classes Cl ON Cl.class = Ca.class
    GROUP BY Ca.name, Ca.class, Cl.country
),
ClassLowPositionCount AS ( -- Переименовано для соответствия названию low_position_count
    SELECT 
        car_class,
        COUNT(CASE WHEN average_position > 3.0 THEN 1 END) AS low_position_count, -- Переименовано
        SUM(race_count) AS total_races
    FROM CarStats
    GROUP BY car_class
),
MaxLowPositionCount AS ( -- Переименовано
    SELECT MAX(low_position_count) AS max_low_position_count -- Переименовано
    FROM ClassLowPositionCount
)
SELECT 
    CS.car_name,
    CS.car_class,
    CS.average_position,
    CS.race_count,
    CS.car_country,
    CLPC.total_races,
    CLPC.low_position_count -- Выводим с новым именем
FROM CarStats CS
JOIN ClassLowPositionCount CLPC ON CS.car_class = CLPC.car_class
JOIN MaxLowPositionCount MLPC ON CLPC.low_position_count = MLPC.max_low_position_count
WHERE CS.average_position > 3.0 -- Фильтр для автомобилей с позицией > 3.0
ORDER BY CLPC.low_position_count DESC, CS.average_position ASC;
