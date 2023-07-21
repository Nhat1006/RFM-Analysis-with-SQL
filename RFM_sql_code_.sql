-- Cleaning data, loại bỏ trùng lặp
WITH 
check_box AS
(
SELECT
	*,
	ROW_NUMBER() OVER(PARTITION BY Order_Line, Order_ID, Order_date, Product_ID ORDER BY Order_line ) AS Dup_check
FROM rfm_analysis.sales
),

pre AS
(
SELECT
	check_box.Order_Line,
    check_box.Order_ID,
    check_box.Order_Date,
    check_box.Ship_Date,
    check_box.Ship_Mode,
    check_box.Customer_ID,
    c.Customer_Name,
    check_box.Product_ID,
    check_box.Sales,
    check_box.Quantity,
    check_box.Discount,
    check_box.Profit
FROM check_box
INNER JOIN customer AS c
ON c.Customer_ID = check_box.Customer_ID
WHERE Dup_check = 1
),

-- Tính các giá trị Recency_value, Frequency_value, Monetary_value
table1 AS
( 
SELECT
	pre.Customer_ID, pre.Customer_Name,
    DATEDIFF(CURDATE(), MAX(CAST(Order_Date AS DATE))) AS Recency_value,
    COUNT(DISTINCT(Order_line)) AS Frequency_value,
    ROUND(SUM(Sales), 2) AS Monetary_value
FROM pre
GROUP BY pre.Customer_ID, pre.Customer_Name
),

-- Xác định điểm cho phân khúc bằng hành vi của người tiêu dùng
table2 AS
(
SELECT
	*,
    NTILE(5) OVER(ORDER BY Recency_value DESC) AS Recency_Score,
    NTILE(5) OVER(ORDER BY Frequency_value ASC) AS Frequency_Score,
    NTILE(5) OVER(ORDER BY Monetary_value ASC) AS Monetary_Score
FROM table1
),

-- Final result
Final_rfm AS
(
SELECT
	*,
	CONCAT(Recency_Score, Frequency_Score,Monetary_Score) AS Final_Score
FROM table2
)

SELECT
	Final_rfm.Customer_ID,
	Final_rfm.Customer_name,  
    Final_rfm.Recency_value, 
    Final_rfm.Frequency_value, 
    Final_rfm.Monetary_value,
	Final_rfm.Recency_Score, 
    Final_rfm.Frequency_Score, 
    Final_rfm.Monetary_Score,
    Final_Score,
    ss.Segment
FROM Final_rfm
INNER JOIN rfm_analysis.`segment scores` AS ss
ON Final_Score = ss.scores;



