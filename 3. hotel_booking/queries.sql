-- задача 1
SELECT 
    c.ID_customer,
    c.name,
    c.email,
    c.phone,
    COUNT(DISTINCT b.ID_booking) AS total_bookings,
    GROUP_CONCAT(DISTINCT h.name ORDER BY h.name SEPARATOR ', ') AS hotels_booked,
    AVG(DATEDIFF(b.check_out_date, b.check_in_date)) AS avg_stay_duration
FROM 
    Customer c
JOIN 
    Booking b ON c.ID_customer = b.ID_customer
JOIN 
    Room r ON b.ID_room = r.ID_room
JOIN 
    Hotel h ON r.ID_hotel = h.ID_hotel
GROUP BY 
    c.ID_customer, c.name, c.email, c.phone
HAVING 
    COUNT(DISTINCT h.ID_hotel) > 1 AND COUNT(DISTINCT b.ID_booking) > 2
ORDER BY 
    total_bookings DESC;

-- задача 2 
WITH multi_hotel_customers AS (
    SELECT 
        c.ID_customer,
        c.name,
        COUNT(DISTINCT b.ID_booking) AS total_bookings,
        COUNT(DISTINCT h.ID_hotel) AS unique_hotels,
        SUM(r.price * DATEDIFF(b.check_out_date, b.check_in_date)) AS total_spent
    FROM 
        Customer c
    JOIN 
        Booking b ON c.ID_customer = b.ID_customer
    JOIN 
        Room r ON b.ID_room = r.ID_room
    JOIN 
        Hotel h ON r.ID_hotel = h.ID_hotel
    GROUP BY 
        c.ID_customer, c.name
    HAVING 
        COUNT(DISTINCT h.ID_hotel) > 1 AND COUNT(DISTINCT b.ID_booking) > 2
),
high_spending_customers AS (
    SELECT 
        c.ID_customer,
        c.name,
        SUM(r.price * DATEDIFF(b.check_out_date, b.check_in_date)) AS total_spent,
        COUNT(DISTINCT b.ID_booking) AS total_bookings
    FROM 
        Customer c
    JOIN 
        Booking b ON c.ID_customer = b.ID_customer
    JOIN 
        Room r ON b.ID_room = r.ID_room
    GROUP BY 
        c.ID_customer, c.name
    HAVING 
        SUM(r.price * DATEDIFF(b.check_out_date, b.check_in_date)) > 500
)
SELECT 
    m.ID_customer,
    m.name,
    m.total_bookings,
    m.total_spent,
    m.unique_hotels
FROM 
    multi_hotel_customers m
JOIN 
    high_spending_customers h ON m.ID_customer = h.ID_customer
ORDER BY 
    m.total_spent ASC;
    
-- задача 3
WITH HotelCategories AS (
    -- Категоризация отелей по средней стоимости номера
    SELECT 
        h.ID_hotel,
        h.name AS hotel_name,
        CASE 
            WHEN AVG(r.price) < 175 THEN 'Дешевый'
            WHEN AVG(r.price) BETWEEN 175 AND 300 THEN 'Средний'
            ELSE 'Дорогой'
        END AS hotel_category
    FROM 
        Hotel h
    JOIN 
        Room r ON h.ID_hotel = r.ID_hotel
    GROUP BY 
        h.ID_hotel, h.name
),

CustomerHotelVisits AS (
    -- Определение отелей, которые посещал каждый клиент
    SELECT 
        c.ID_customer,
        c.name,
        hc.hotel_category,
        hc.hotel_name
    FROM 
        Customer c
    JOIN 
        Booking b ON c.ID_customer = b.ID_customer
    JOIN 
        Room r ON b.ID_room = r.ID_room
    JOIN 
        HotelCategories hc ON r.ID_hotel = hc.ID_hotel
    GROUP BY 
        c.ID_customer, c.name, hc.hotel_category, hc.hotel_name
),

CustomerPreferences AS (
    -- Определение предпочитаемого типа отеля для каждого клиента
    SELECT 
        ID_customer,
        name,
        CASE 
            WHEN MAX(CASE WHEN hotel_category = 'Дорогой' THEN 3 
                         WHEN hotel_category = 'Средний' THEN 2
                         ELSE 1 END) = 3 THEN 'Дорогой'
            WHEN MAX(CASE WHEN hotel_category = 'Средний' THEN 2
                         ELSE 1 END) = 2 THEN 'Средний'
            ELSE 'Дешевый'
        END AS preferred_hotel_type,
        GROUP_CONCAT(DISTINCT hotel_name ORDER BY hotel_name SEPARATOR ', ') AS visited_hotels
    FROM 
        CustomerHotelVisits
    GROUP BY 
        ID_customer, name
)

-- Финальный результат с сортировкой
SELECT 
    ID_customer,
    name,
    preferred_hotel_type,
    visited_hotels
FROM 
    CustomerPreferences
ORDER BY 
    CASE preferred_hotel_type
        WHEN 'Дешевый' THEN 1
        WHEN 'Средний' THEN 2
        WHEN 'Дорогой' THEN 3
    END,
    name;
