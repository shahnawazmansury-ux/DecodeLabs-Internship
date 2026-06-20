
/*
DECODE LAB — ADDITIONAL SQL QUESTIONS & SOLUTIONS
Dataset  : customerTable
Columns  : OrderID, Date, CustomerID, Product, Quantity, UnitPrice, ShippingAddress,
           PaymentMethod, OrderStatus, TrackingNumber, ItemsInCart, CouponCode,
           ReferralSource, TotalPrice
Date Range: 2023-01-01  to  2025-06-30
Products  : Monitor, Phone, Tablet, Chair, Printer, Laptop, Desk
Statuses  : Shipped, Cancelled, Returned, Delivered, Pending
*/



-- Q1. Find the total number of returned orders per product and
--     rank them from highest to lowest.

SELECT
    Product,
    COUNT(*)                                          AS ReturnedOrders,
    RANK() OVER (ORDER BY COUNT(*) DESC)              AS Rnk
FROM customerTable
WHERE OrderStatus = 'Returned'
GROUP BY Product;

/*
WHY: Returned orders signal quality or expectation mismatches.
     Ranking them helps prioritise which products need investigation.
*/


-- Q2. Find the average unit price per product and flag products
--     whose average unit price is above the overall average unit price.
SELECT
    Product,
    ROUND(AVG(UnitPrice), 2)                          AS AvgUnitPrice,
    CASE
        WHEN AVG(UnitPrice) > (SELECT AVG(UnitPrice) FROM customerTable)
             THEN 'Above Average'
        ELSE 'Below or Equal'
    END                                               AS PriceSegment
FROM customerTable
GROUP BY Product
ORDER BY AvgUnitPrice DESC;

/*
WHY: Helps in pricing strategy — knowing which products sit above the
     portfolio average guides discounting or bundling decisions.
*/


-- Q3. For each payment method, show the count of orders by order status
--     (a pivot-style summary).
SELECT
    PaymentMethod,
    COUNT(CASE WHEN OrderStatus = 'Delivered'  THEN 1 END) AS Delivered,
    COUNT(CASE WHEN OrderStatus = 'Shipped'    THEN 1 END) AS Shipped,
    COUNT(CASE WHEN OrderStatus = 'Cancelled'  THEN 1 END) AS Cancelled,
    COUNT(CASE WHEN OrderStatus = 'Returned'   THEN 1 END) AS Returned,
    COUNT(CASE WHEN OrderStatus = 'Pending'    THEN 1 END) AS Pending,
    COUNT(*)                                               AS TotalOrders
FROM customerTable
GROUP BY PaymentMethod
ORDER BY TotalOrders DESC;

/*
WHY: Reveals whether certain payment methods correlate with higher
     cancellation or return rates — useful for payment-risk analysis.
*/


-- Q4. Find the top 3 products by total quantity sold in each year.
WITH YearlyProductSales AS (
    SELECT
        YEAR(Date)                                        AS SalesYear,
        Product,
        SUM(Quantity)                                     AS TotalQtySold,
        RANK() OVER (
            PARTITION BY YEAR(Date)
            ORDER BY SUM(Quantity) DESC
        )                                                 AS Rnk
    FROM customerTable
    GROUP BY YEAR(Date), Product
)
SELECT
    SalesYear,
    Product,
    TotalQtySold,
    Rnk
FROM YearlyProductSales
WHERE Rnk <= 3
ORDER BY SalesYear, Rnk;

/*
WHY: Year-over-year product volume trends show which items are growing
     or losing popularity — vital for inventory planning.
*/


-- Q5. Calculate the cancellation rate (%) for each referral source.
SELECT
    ReferralSource,
    COUNT(*)                                           AS TotalOrders,
    COUNT(CASE WHEN OrderStatus = 'Cancelled' THEN 1 END) AS CancelledOrders,
    ROUND(
        100.0 * COUNT(CASE WHEN OrderStatus = 'Cancelled' THEN 1 END)
              / COUNT(*),
        2
    )                                                  AS CancellationRate_Pct
FROM customerTable
GROUP BY ReferralSource
ORDER BY CancellationRate_Pct DESC;

/*
WHY: A high cancellation rate from a specific channel (e.g. Instagram)
     suggests poor lead quality or misleading ad creatives.
*/


-- Q6. Find all customers who have ONLY ever placed cancelled orders
--     (every single order is cancelled).
SELECT CustomerID,
       COUNT(*) AS TotalOrders
FROM customerTable
GROUP BY CustomerID
HAVING COUNT(*) = COUNT(CASE WHEN OrderStatus = 'Cancelled' THEN 1 END);

/*
WHY: These customers are loss-only accounts — useful for churn analysis
     or to decide whether re-engagement is worthwhile.
*/


-- Q7. Identify the coupon code that attracted the most NEW customers
--     (customers whose very first order used that coupon).
WITH FirstOrders AS (
    SELECT
        CustomerID,
        MIN(Date)  AS FirstOrderDate
    FROM customerTable
    GROUP BY CustomerID
),
FirstOrderDetails AS (
    SELECT
        ct.CustomerID,
        ct.CouponCode
    FROM customerTable ct
    JOIN FirstOrders fo
        ON ct.CustomerID = fo.CustomerID
       AND ct.Date       = fo.FirstOrderDate
)
SELECT
    CouponCode,
    COUNT(DISTINCT CustomerID) AS NewCustomers
FROM FirstOrderDetails
GROUP BY CouponCode
ORDER BY NewCustomers DESC;

/*
WHY: Distinguishes acquisition coupons from retention coupons —
     important for marketing budget allocation.
*/


-- Q8. Show the revenue contribution of each referral source,
--     broken down by product (a cross-tab / matrix view).
SELECT
    ReferralSource,
    ROUND(SUM(CASE WHEN Product = 'Laptop'  THEN TotalPrice ELSE 0 END), 2) AS Laptop,
    ROUND(SUM(CASE WHEN Product = 'Monitor' THEN TotalPrice ELSE 0 END), 2) AS Monitor,
    ROUND(SUM(CASE WHEN Product = 'Phone'   THEN TotalPrice ELSE 0 END), 2) AS Phone,
    ROUND(SUM(CASE WHEN Product = 'Tablet'  THEN TotalPrice ELSE 0 END), 2) AS Tablet,
    ROUND(SUM(CASE WHEN Product = 'Chair'   THEN TotalPrice ELSE 0 END), 2) AS Chair,
    ROUND(SUM(CASE WHEN Product = 'Printer' THEN TotalPrice ELSE 0 END), 2) AS Printer,
    ROUND(SUM(CASE WHEN Product = 'Desk'    THEN TotalPrice ELSE 0 END), 2) AS Desk,
    ROUND(SUM(TotalPrice), 2)                                                AS GrandTotal
FROM customerTable
GROUP BY ReferralSource
ORDER BY GrandTotal DESC;

/*
WHY: Shows which channel drives which product category — useful for
     channel-specific product promotions.
*/


-- Q9. Find customers who placed orders in all three years (2023, 2024, 2025).
SELECT
    CustomerID,
    COUNT(DISTINCT YEAR(Date)) AS ActiveYears
FROM customerTable
GROUP BY CustomerID
HAVING COUNT(DISTINCT YEAR(Date)) = 3;

/*
WHY: Multi-year customers are the most loyal segment — prime targets
     for VIP programmes or upsell campaigns.
*/


-- Q10. Calculate the average items in cart (ItemsInCart) for
--      delivered vs cancelled orders.
SELECT
    OrderStatus,
    ROUND(AVG(CAST(ItemsInCart AS FLOAT)), 2) AS AvgItemsInCart,
    COUNT(*)                                  AS OrderCount
FROM customerTable
WHERE OrderStatus IN ('Delivered', 'Cancelled')
GROUP BY OrderStatus;

/*
WHY: If cancelled orders consistently show more items in cart, cart
     abandonment at checkout may need UX attention.
*/


-- Q11. Find the day of the week that generates the highest total revenue.
SELECT
    DATENAME(WEEKDAY, Date)            AS DayOfWeek,
    DATEPART(WEEKDAY,  Date)           AS DayNumber,       -- for ordering
    ROUND(SUM(TotalPrice), 2)          AS TotalRevenue,
    COUNT(*)                           AS OrderCount
FROM customerTable
GROUP BY DATENAME(WEEKDAY, Date), DATEPART(WEEKDAY, Date)
ORDER BY TotalRevenue DESC;

/*
WHY: Knowing the peak day allows marketing teams to schedule flash
     sales or email campaigns for maximum impact.
*/


-- Q12. Compute a running total of revenue ordered by date
--      (cumulative revenue over the entire period).
SELECT
    CAST(Date AS DATE)                   AS OrderDate,
    ROUND(SUM(TotalPrice), 2)            AS DailyRevenue,
    ROUND(
        SUM(SUM(TotalPrice)) OVER (
            ORDER BY CAST(Date AS DATE)
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ),
        2
    )                                    AS CumulativeRevenue
FROM customerTable
GROUP BY CAST(Date AS DATE)
ORDER BY OrderDate;

/*
WHY: Cumulative revenue is a standard KPI chart for executive dashboards
     — it shows acceleration or plateau in business growth.
*/


-- Q13. For each product, find the month in which it generated
--      the LEAST revenue (worst month per product).
WITH ProductMonthlyRevenue AS (
    SELECT
        Product,
        YEAR(Date)                                AS SalesYear,
        MONTH(Date)                               AS SalesMonth,
        ROUND(SUM(TotalPrice), 2)                 AS MonthRevenue,
        RANK() OVER (
            PARTITION BY Product
            ORDER BY SUM(TotalPrice) ASC
        )                                         AS Rnk
    FROM customerTable
    GROUP BY Product, YEAR(Date), MONTH(Date)
)
SELECT
    Product,
    SalesYear,
    SalesMonth,
    MonthRevenue
FROM ProductMonthlyRevenue
WHERE Rnk = 1
ORDER BY Product;

/*
WHY: Identifies seasonal troughs for each product so targeted
     promotions can be planned for slow months.
*/


-- Q14. Find customers who switched their payment method at least once
--      (used two or more distinct payment methods across their orders).
SELECT
    CustomerID,
    COUNT(DISTINCT PaymentMethod)   AS DistinctPaymentMethods,
    STRING_AGG(DISTINCT PaymentMethod, ', ')
        WITHIN GROUP (ORDER BY PaymentMethod) AS MethodsUsed
FROM customerTable
GROUP BY CustomerID
HAVING COUNT(DISTINCT PaymentMethod) >= 2
ORDER BY DistinctPaymentMethods DESC;

/*
WHY: Payment method switching can indicate card issues, fraud testing,
     or flexibility — each has different operational implications.
*/


-- Q15. Calculate the return rate (%) per product and identify
--      products with a return rate above 20%.
WITH ProductStats AS (
    SELECT
        Product,
        COUNT(*)                                              AS TotalOrders,
        COUNT(CASE WHEN OrderStatus = 'Returned' THEN 1 END) AS ReturnedOrders
    FROM customerTable
    GROUP BY Product
)
SELECT
    Product,
    TotalOrders,
    ReturnedOrders,
    ROUND(100.0 * ReturnedOrders / TotalOrders, 2) AS ReturnRate_Pct,
    CASE
        WHEN 100.0 * ReturnedOrders / TotalOrders > 20
             THEN 'High Return Risk'
        ELSE 'Acceptable'
    END                                            AS ReturnFlag
FROM ProductStats
ORDER BY ReturnRate_Pct DESC;

/*
WHY: Products with return rates above 20% may have description issues,
     quality problems, or sizing/compatibility mismatches.
*/


-- Q16. Identify the "best quarter" (Q1–Q4) by total revenue
--      across all years combined.
SELECT
    DATEPART(QUARTER, Date)       AS Quarter,
    CONCAT('Q', DATEPART(QUARTER, Date)) AS QuarterLabel,
    ROUND(SUM(TotalPrice), 2)     AS TotalRevenue,
    COUNT(*)                      AS OrderCount
FROM customerTable
GROUP BY DATEPART(QUARTER, Date)
ORDER BY TotalRevenue DESC;

/*
WHY: Quarterly seasonality analysis helps with inventory stocking,
     staffing decisions, and annual planning cycles.
*/


-- Q17. Find the percentage of orders that used a coupon code
--      vs those that did not, for each product.
SELECT
    Product,
    COUNT(*)                                                           AS TotalOrders,
    COUNT(CASE WHEN CouponCode != 'NO-COUPON' THEN 1 END)             AS CouponOrders,
    COUNT(CASE WHEN CouponCode  = 'NO-COUPON' THEN 1 END)             AS NoCouponOrders,
    ROUND(
        100.0 * COUNT(CASE WHEN CouponCode != 'NO-COUPON' THEN 1 END)
              / COUNT(*),
        2
    )                                                                  AS CouponUsage_Pct
FROM customerTable
GROUP BY Product
ORDER BY CouponUsage_Pct DESC;

/*
WHY: Reveals which products rely most on discounts to drive purchases —
     high coupon dependency may indicate weak organic demand.
*/


-- Q18. Using a window function, show each order's revenue share
--      within its own product category (% of that product's total revenue).
SELECT
    OrderID,
    CustomerID,
    Product,
    ROUND(TotalPrice, 2)                                AS OrderRevenue,
    ROUND(SUM(TotalPrice) OVER (PARTITION BY Product), 2) AS ProductTotalRevenue,
    ROUND(
        100.0 * TotalPrice
              / SUM(TotalPrice) OVER (PARTITION BY Product),
        4
    )                                                   AS ShareWithinProduct_Pct
FROM customerTable
ORDER BY Product, ShareWithinProduct_Pct DESC;

/*
WHY: Shows which individual orders are "heavyweight" within a product —
     useful for identifying large B2B-style purchases.
*/


-- Q19. Find the average number of days between consecutive orders
--      for each customer (inter-order gap analysis).
WITH OrderedDates AS (
    SELECT
        CustomerID,
        CAST(Date AS DATE)                              AS OrderDate,
        LAG(CAST(Date AS DATE)) OVER (
            PARTITION BY CustomerID
            ORDER BY Date
        )                                               AS PrevOrderDate
    FROM customerTable
),
Gaps AS (
    SELECT
        CustomerID,
        DATEDIFF(DAY, PrevOrderDate, OrderDate) AS DaysBetweenOrders
    FROM OrderedDates
    WHERE PrevOrderDate IS NOT NULL
)
SELECT
    CustomerID,
    COUNT(*)                              AS GapCount,
    ROUND(AVG(CAST(DaysBetweenOrders AS FLOAT)), 1) AS AvgDaysBetweenOrders,
    MIN(DaysBetweenOrders)                AS MinGap,
    MAX(DaysBetweenOrders)                AS MaxGap
FROM Gaps
GROUP BY CustomerID
ORDER BY AvgDaysBetweenOrders ASC;

/*
WHY: Customers with short average gaps are highly engaged. This metric
     feeds directly into replenishment reminder campaigns.
*/


-- Q20. Identify orders where the customer's spend was in the
--      TOP 10% of all orders (high-value order detection).
WITH Percentiles AS (
    SELECT
        OrderID,
        CustomerID,
        Product,
        TotalPrice,
        PERCENTILE_CONT(0.90) WITHIN GROUP (ORDER BY TotalPrice)
            OVER () AS P90_Threshold
    FROM customerTable
)
SELECT
    OrderID,
    CustomerID,
    Product,
    ROUND(TotalPrice,   2) AS OrderValue,
    ROUND(P90_Threshold, 2) AS Top10Pct_Threshold
FROM Percentiles
WHERE TotalPrice >= P90_Threshold
ORDER BY TotalPrice DESC;

/*
WHY: High-value orders deserve special handling — priority shipping,
     personalised thank-you notes, or upsell follow-ups.
*/
