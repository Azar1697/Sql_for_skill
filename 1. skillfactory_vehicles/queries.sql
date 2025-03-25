- задача 1
SELECT v.maker, m.model
FROM Motorcycle m
JOIN Vehicle v ON m.model = v.model
WHERE m.horsepower > 150
  AND m.price < 20000
  AND m.type = 'Sport'
ORDER BY m.horsepower DESC;

-- задача 2
select v.maker as maker,
	   c.model as model,
       c.horsepower as horsepower,
       c.engine_capacity as engine_capacity, 
       'Car' as type
from Car c
join Vehicle v on c.model = v.model
where c.horsepower > 150
  and c.engine_capacity < 3.0
  and c.price < 35000

union

select v.maker as maker,
       m.model as model,
       m.horsepower as horsepower,
       m.engine_capacity as engine_capacity, 
       'Motorcycle' as type
from Motorcycle m
join Vehicle v on m.model = v.model
where m.horsepower > 150
  and m.engine_capacity < 1.5
  and m.price < 20000 
  
union

select v.maker as maker,
       b.model as model,
       null as horsepower,
       null as engine_capacity,
       'Bicycle' as type
from Bicycle b
join Vehicle v on b.model = v.model
where b.gear_count > 18
  and b.price < 4000

ORDER BY CASE WHEN horsepower IS NOT NULL THEN -horsepower ELSE 1 END;
