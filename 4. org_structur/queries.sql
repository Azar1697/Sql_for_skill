-- задача 1
WITH RECURSIVE EmployeeHierarchy AS (
    -- Базовый случай: начальный сотрудник (Иван Иванов)
    SELECT 
        EmployeeID,
        Name,
        ManagerID,
        DepartmentID,
        RoleID
    FROM Employees
    WHERE EmployeeID = 1
    
    UNION ALL
    
    -- Рекурсивный случай: все подчиненные
    SELECT 
        e.EmployeeID,
        e.Name,
        e.ManagerID,
        e.DepartmentID,
        e.RoleID
    FROM Employees e
    JOIN EmployeeHierarchy eh ON e.ManagerID = eh.EmployeeID
)

SELECT 
    eh.EmployeeID,
    eh.Name,
    eh.ManagerID,
    d.DepartmentName,
    r.RoleName,
    GROUP_CONCAT(DISTINCT p.ProjectName ORDER BY p.ProjectName SEPARATOR ', ') AS Projects,
    GROUP_CONCAT(DISTINCT t.TaskName ORDER BY t.TaskName SEPARATOR ', ') AS Tasks
FROM 
    EmployeeHierarchy eh
LEFT JOIN Departments d ON eh.DepartmentID = d.DepartmentID
LEFT JOIN Roles r ON eh.RoleID = r.RoleID
LEFT JOIN Projects p ON d.DepartmentID = p.DepartmentID
LEFT JOIN Tasks t ON eh.EmployeeID = t.AssignedTo
GROUP BY 
    eh.EmployeeID, eh.Name, eh.ManagerID, d.DepartmentName, r.RoleName
ORDER BY 
    eh.Name;
    
-- задача 2
WITH RECURSIVE EmployeeHierarchy AS (
    -- Базовый случай: начальный сотрудник (Иван Иванов)
    SELECT 
        EmployeeID,
        Name,
        ManagerID,
        DepartmentID,
        RoleID
    FROM Employees
    WHERE EmployeeID = 1
    
    UNION ALL
    
    -- Рекурсивный случай: все подчиненные
    SELECT 
        e.EmployeeID,
        e.Name,
        e.ManagerID,
        e.DepartmentID,
        e.RoleID
    FROM Employees e
    JOIN EmployeeHierarchy eh ON e.ManagerID = eh.EmployeeID
),

-- Подсчет количества подчиненных для каждого сотрудника
DirectSubordinates AS (
    SELECT 
        ManagerID,
        COUNT(*) AS SubordinateCount
    FROM Employees
    GROUP BY ManagerID
),

-- Собираем информацию о проектах для сотрудников
EmployeeProjects AS (
    SELECT 
        e.EmployeeID,
        GROUP_CONCAT(DISTINCT p.ProjectName ORDER BY p.ProjectName SEPARATOR ', ') AS Projects
    FROM Employees e
    LEFT JOIN Departments d ON e.DepartmentID = d.DepartmentID
    LEFT JOIN Projects p ON d.DepartmentID = p.DepartmentID
    GROUP BY e.EmployeeID
),

-- Собираем информацию о задачах для сотрудников
EmployeeTasks AS (
    SELECT 
        t.AssignedTo AS EmployeeID,
        GROUP_CONCAT(DISTINCT t.TaskName ORDER BY t.TaskName SEPARATOR ', ') AS Tasks,
        COUNT(*) AS TaskCount
    FROM Tasks t
    GROUP BY t.AssignedTo
)

SELECT 
    eh.EmployeeID,
    eh.Name,
    eh.ManagerID,
    d.DepartmentName,
    r.RoleName,
    ep.Projects,
    et.Tasks,
    COALESCE(et.TaskCount, 0) AS TotalTasks,
    COALESCE(ds.SubordinateCount, 0) AS DirectSubordinatesCount
FROM 
    EmployeeHierarchy eh
LEFT JOIN Departments d ON eh.DepartmentID = d.DepartmentID
LEFT JOIN Roles r ON eh.RoleID = r.RoleID
LEFT JOIN EmployeeProjects ep ON eh.EmployeeID = ep.EmployeeID
LEFT JOIN EmployeeTasks et ON eh.EmployeeID = et.EmployeeID
LEFT JOIN DirectSubordinates ds ON eh.EmployeeID = ds.ManagerID
ORDER BY 
    eh.Name;
    
-- задача 3
WITH RECURSIVE ManagerHierarchy AS (
    -- Базовый случай: все менеджеры с подчиненными
    SELECT 
        e.EmployeeID,
        e.Name,
        e.ManagerID,
        e.DepartmentID,
        e.RoleID
    FROM Employees e
    WHERE e.RoleID = 1 -- Менеджеры
    AND EXISTS (
        SELECT 1 FROM Employees sub 
        WHERE sub.ManagerID = e.EmployeeID
    )
),

-- Все связи менеджер-подчиненный (включая косвенные)
ManagerSubordinate AS (
    -- Базовый случай: непосредственные подчиненные
    SELECT 
        m.EmployeeID AS ManagerID,
        e.EmployeeID AS SubordinateID,
        1 AS Level
    FROM ManagerHierarchy m
    JOIN Employees e ON e.ManagerID = m.EmployeeID
    
    UNION ALL
    
    -- Рекурсивный случай: подчиненные подчиненных
    SELECT 
        ms.ManagerID,
        e.EmployeeID AS SubordinateID,
        ms.Level + 1
    FROM ManagerSubordinate ms
    JOIN Employees e ON e.ManagerID = ms.SubordinateID
),

-- Подсчет общего количества подчиненных для каждого менеджера
SubordinateCount AS (
    SELECT 
        ManagerID AS EmployeeID,
        COUNT(DISTINCT SubordinateID) AS TotalSubordinatesCount
    FROM ManagerSubordinate
    GROUP BY ManagerID
),

-- Собираем информацию о проектах для менеджеров
ManagerProjects AS (
    SELECT 
        m.EmployeeID,
        GROUP_CONCAT(DISTINCT p.ProjectName ORDER BY p.ProjectName SEPARATOR ', ') AS Projects
    FROM ManagerHierarchy m
    LEFT JOIN Departments d ON m.DepartmentID = d.DepartmentID
    LEFT JOIN Projects p ON d.DepartmentID = p.DepartmentID
    GROUP BY m.EmployeeID
),

-- Собираем информацию о задачах для менеджеров
ManagerTasks AS (
    SELECT 
        t.AssignedTo AS EmployeeID,
        GROUP_CONCAT(DISTINCT t.TaskName ORDER BY t.TaskName SEPARATOR ', ') AS Tasks
    FROM Tasks t
    JOIN ManagerHierarchy m ON t.AssignedTo = m.EmployeeID
    GROUP BY t.AssignedTo
)

SELECT 
    m.EmployeeID,
    m.Name,
    m.ManagerID,
    d.DepartmentName,
    r.RoleName,
    mp.Projects,
    mt.Tasks,
    COALESCE(sc.TotalSubordinatesCount, 0) AS TotalSubordinatesCount
FROM 
    ManagerHierarchy m
LEFT JOIN Departments d ON m.DepartmentID = d.DepartmentID
LEFT JOIN Roles r ON m.RoleID = r.RoleID
LEFT JOIN ManagerProjects mp ON m.EmployeeID = mp.EmployeeID
LEFT JOIN ManagerTasks mt ON m.EmployeeID = mt.EmployeeID
LEFT JOIN SubordinateCount sc ON m.EmployeeID = sc.EmployeeID
ORDER BY 
    m.Name;
